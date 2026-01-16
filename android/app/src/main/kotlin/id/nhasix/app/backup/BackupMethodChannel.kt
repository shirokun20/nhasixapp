package id.nhasix.app.backup

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Environment
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.*
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

class BackupMethodChannel(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val CHANNEL = "id.nhasix.app/backup"
    private val methodChannel = MethodChannel(messenger, CHANNEL)
    private val PICK_BACKUP_FILE_REQUEST_CODE = 8888
    
    private var pendingResult: MethodChannel.Result? = null

    init {
        methodChannel.setMethodCallHandler(this)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createBackup" -> createBackup(call, result)
            "pickBackupFile" -> pickBackupFile(result)
            "extractBackupData" -> extractBackupData(call, result)
            else -> result.notImplemented()
        }
    }

    private fun createBackup(call: MethodCall, result: MethodChannel.Result) {
        val dbPath = call.argument<String>("dbPath")
        val settingsJson = call.argument<String>("settingsJson")

        if (dbPath == null || settingsJson == null) {
            result.error("INVALID_ARGS", "Missing dbPath or settingsJson", null)
            return
        }

        Thread {
            try {
                // Use Downloads/Kuron/settings/ for permanent backup storage
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                val kuronSettingsDir = File(downloadsDir, "Kuron${File.separator}settings")
                if (!kuronSettingsDir.exists()) {
                    kuronSettingsDir.mkdirs()
                }

                // 1. Create temp dir for backup preparation
                val backupDir = File(kuronSettingsDir, "backup_gen")
                if (backupDir.exists()) backupDir.deleteRecursively()
                backupDir.mkdirs()

                // 2. Write settings.json
                val settingsFile = File(backupDir, "settings.json")
                settingsFile.writeText(settingsJson)

                // 3. Copy DB
                val dbFile = File(dbPath)
                if (dbFile.exists()) {
                     dbFile.copyTo(File(backupDir, "nhasix_app.db"), overwrite = true)
                     // Try copying WAL/SHM just in case
                     val wal = File(dbPath + "-wal")
                     if (wal.exists()) wal.copyTo(File(backupDir, "nhasix_app.db-wal"), overwrite = true)
                     val shm = File(dbPath + "-shm")
                     if (shm.exists()) shm.copyTo(File(backupDir, "nhasix_app.db-shm"), overwrite = true)
                }

                // 4. Zip it to Downloads/Kuron/settings/
                val zipFile = File(kuronSettingsDir, "backup_${System.currentTimeMillis()}.zip")
                zip(backupDir, zipFile)

                // 5. Cleanup temp dir
                backupDir.deleteRecursively()

                activity.runOnUiThread {
                    result.success(zipFile.absolutePath)
                }

            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("BACKUP_FAILED", e.message, null)
                }
            }
        }.start()
    }

    private fun pickBackupFile(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Another picker is active", null)
            return
        }
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*" 
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/zip", "application/octet-stream"))
        }
        
        try {
            activity.startActivityForResult(intent, PICK_BACKUP_FILE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingResult = null
            result.error("ACTIVITY_ERROR", e.message, null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == PICK_BACKUP_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                pendingResult?.success(data.data.toString())
            } else {
                pendingResult?.success(null) // Cancelled
            }
            pendingResult = null
            return true
        }
        return false
    }

    private fun extractBackupData(call: MethodCall, result: MethodChannel.Result) {
        val contentUriString = call.argument<String>("contentUri")
        if (contentUriString == null) {
             result.error("INVALID_ARGS", "Missing contentUri", null)
             return
        }
        
        Thread {
            try {
                val uri = Uri.parse(contentUriString)
                val inputStream = activity.contentResolver.openInputStream(uri)
                    ?: throw IOException("Cannot open URI")

                val cacheDir = activity.cacheDir
                val extractDir = File(cacheDir, "restore_temp")
                if (extractDir.exists()) extractDir.deleteRecursively()
                extractDir.mkdirs()

                // Unzip
                unzip(inputStream, extractDir)

                // Read Data
                val settingsFile = File(extractDir, "settings.json")
                val dbFile = File(extractDir, "nhasix_app.db")
                
                if (!settingsFile.exists() || !dbFile.exists()) {
                     throw IOException("Invalid backup file: missing settings.json or database")
                }
                
                val settingsJson = settingsFile.readText()
                val dbPath = dbFile.absolutePath
                
                // Return map
                val response = mapOf(
                    "settingsJson" to settingsJson,
                    "dbPath" to dbPath
                )
                
                activity.runOnUiThread {
                    result.success(response)
                }

            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("RESTORE_FAILED", e.message, null)
                }
            }
        }.start()
    }
    
    private fun zip(sourceDir: File, zipFile: File) {
        ZipOutputStream(BufferedOutputStream(FileOutputStream(zipFile))).use { zos ->
            sourceDir.walkTopDown().forEach { file ->
                if (file.isFile) {
                    val entryName = file.relativeTo(sourceDir).path
                    zos.putNextEntry(ZipEntry(entryName))
                    file.inputStream().use { it.copyTo(zos) }
                    zos.closeEntry()
                }
            }
        }
    }

    private fun unzip(inputStream: InputStream, targetDir: File) {
        ZipInputStream(BufferedInputStream(inputStream)).use { zis ->
            var entry = zis.nextEntry
            while (entry != null) {
                val file = File(targetDir, entry.name)
                // Vulnerability fix: Zip Slip
                if (!file.canonicalPath.startsWith(targetDir.canonicalPath)) {
                    throw IOException("Zip entry is outside of the target dir: ${entry.name}")
                }
                
                if (entry.isDirectory) {
                    file.mkdirs()
                } else {
                    file.parentFile?.mkdirs()
                    FileOutputStream(file).use { fos ->
                         zis.copyTo(fos)
                    }
                }
                entry = zis.nextEntry
            }
        }
    }
}
