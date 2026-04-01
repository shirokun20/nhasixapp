package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipInputStream

/**
 * Handler for ZIP file import functionality
 *
 * Provides native Android file picker for selecting ZIP files,
 * reading ZIP content via content URIs, and extracting ZIP files
 * with progress notifications.
 */
class ZipImportHandler(private val activity: Activity) {
    companion object {
        const val REQUEST_CODE_PICK_ZIP = 2003
        const val NOTIFICATION_CHANNEL_ID = "zip_extraction"
        const val NOTIFICATION_ID = 3001
        private const val BUFFER_SIZE = 8192 // 8KB buffer for streaming
    }

    private var pendingResult: MethodChannel.Result? = null
    private val notificationManager: NotificationManager by lazy {
        activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    /**
     * Launches the native file picker for ZIP files
     */
    fun pickZipFile(result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/zip"
            // Also allow other archive types
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                "application/zip",
                "application/x-zip",
                "application/x-zip-compressed"
            ))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        try {
            pendingResult = result
            activity.startActivityForResult(intent, REQUEST_CODE_PICK_ZIP)
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICK_FAILED", "Failed to open file picker: ${e.message}", null)
        }
    }

    /**
     * Reads ZIP file bytes from content URI
     */
    fun readZipBytes(contentUri: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(contentUri)
            val inputStream = activity.contentResolver.openInputStream(uri)

            if (inputStream == null) {
                result.error("READ_FAILED", "Could not open input stream for URI: $contentUri", null)
                return
            }

            val buffer = ByteArrayOutputStream()
            val data = ByteArray(16384) // 16KB buffer
            var bytesRead: Int

            inputStream.use { input ->
                while (input.read(data, 0, data.size).also { bytesRead = it } != -1) {
                    buffer.write(data, 0, bytesRead)
                }
            }

            result.success(buffer.toByteArray())
        } catch (e: Exception) {
            result.error("READ_FAILED", "Failed to read ZIP file: ${e.message}", null)
        }
    }

    /**
     * Extracts ZIP file directly to destination directory with progress notifications
     * This is a native implementation that streams data directly to disk
     */
    fun extractZipFile(
        contentUri: String,
        destinationPath: String,
        methodChannel: MethodChannel,
        result: MethodChannel.Result
    ) {
        // Create notification channel for Android O and above
        createNotificationChannel()

        // Launch extraction in background coroutine
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val uri = Uri.parse(contentUri)
                val inputStream = activity.contentResolver.openInputStream(uri)

                if (inputStream == null) {
                    withContext(Dispatchers.Main) {
                        result.error("EXTRACTION_FAILED", "Could not open input stream for URI: $contentUri", null)
                    }
                    return@launch
                }

                // Show initial notification
                showNotification("Extracting ZIP file...", 0, -1)

                val zipStream = ZipInputStream(BufferedInputStream(inputStream))
                val destDir = File(destinationPath)
                if (!destDir.exists()) {
                    destDir.mkdirs()
                }

                val imageExtensions = setOf(".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".bmp")
                var imageCount = 0
                var totalEntries = 0
                var processedEntries = 0

                // First pass: count total entries
                try {
                    val countStream = activity.contentResolver.openInputStream(uri)
                    if (countStream != null) {
                        val countZip = ZipInputStream(BufferedInputStream(countStream))
                        while (countZip.nextEntry != null) {
                            totalEntries++
                            countZip.closeEntry()
                        }
                        countZip.close()
                    }
                } catch (e: Exception) {
                    // If counting fails, continue without total
                    totalEntries = -1
                }

                // Second pass: actual extraction
                var entry = zipStream.nextEntry
                while (entry != null) {
                    try {
                        if (!entry.isDirectory) {
                            val fileName = File(entry.name).name
                            val extension = fileName.substringAfterLast('.', "").lowercase()

                            // Only extract image files
                            if (imageExtensions.contains(".$extension")) {
                                val outputFile = File(destDir, fileName)

                                // Stream directly to file with buffering
                                BufferedOutputStream(FileOutputStream(outputFile), BUFFER_SIZE).use { output ->
                                    val buffer = ByteArray(BUFFER_SIZE)
                                    var bytesRead: Int
                                    while (zipStream.read(buffer).also { bytesRead = it } > 0) {
                                        output.write(buffer, 0, bytesRead)
                                    }
                                }

                                imageCount++

                                // Update progress
                                processedEntries++
                                val progress = if (totalEntries > 0) {
                                    (processedEntries * 100) / totalEntries
                                } else {
                                    -1 // Indeterminate
                                }

                                showNotification(
                                    "Extracting: $fileName",
                                    progress,
                                    totalEntries
                                )

                                // Send progress to Flutter
                                withContext(Dispatchers.Main) {
                                    methodChannel.invokeMethod("onZipExtractionProgress", mapOf(
                                        "processed" to processedEntries,
                                        "total" to totalEntries,
                                        "imageCount" to imageCount,
                                        "currentFile" to fileName
                                    ))
                                }
                            } else {
                                processedEntries++
                            }
                        }
                    } catch (e: Exception) {
                        // Log but continue with other files
                        android.util.Log.e("ZipImportHandler", "Failed to extract ${entry.name}: ${e.message}")
                    }

                    zipStream.closeEntry()
                    entry = zipStream.nextEntry
                }

                zipStream.close()

                if (imageCount == 0) {
                    cancelNotification()
                    withContext(Dispatchers.Main) {
                        result.error("NO_IMAGES", "No images found in ZIP file", null)
                    }
                    return@launch
                }

                // Show completion notification
                showNotification(
                    "Extraction complete! $imageCount images extracted",
                    100,
                    100
                )

                // Return success
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to true,
                        "imageCount" to imageCount,
                        "destinationPath" to destinationPath
                    ))
                }

                // Cancel notification after a delay
                kotlinx.coroutines.delay(2000)
                cancelNotification()

            } catch (e: Exception) {
                cancelNotification()
                withContext(Dispatchers.Main) {
                    result.error("EXTRACTION_FAILED", "Failed to extract ZIP: ${e.message}", e.toString())
                }
            }
        }
    }

    /**
     * Creates notification channel for ZIP extraction notifications (Android O+)
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ZIP File Extraction",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress of ZIP file extraction"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Shows or updates extraction progress notification
     */
    private fun showNotification(message: String, progress: Int, max: Int) {
        val builder = NotificationCompat.Builder(activity, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Importing ZIP")
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)

        if (progress >= 0 && max > 0) {
            builder.setProgress(max, progress, false)
        } else {
            builder.setProgress(100, 0, true) // Indeterminate
        }

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    /**
     * Cancels the extraction notification
     */
    private fun cancelNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    /**
     * Handles the activity result from file picker
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_ZIP) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Grant persistent read permission
                    try {
                        val takeFlags: Int = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        activity.contentResolver.takePersistableUriPermission(uri, takeFlags)
                    } catch (e: Exception) {
                        // Permission might not be persistable, that's okay
                    }

                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.error("NO_URI", "No URI returned from file picker", null)
                }
            } else {
                pendingResult?.success(null) // User cancelled
            }
            pendingResult = null
            return true
        }
        return false
    }
}
