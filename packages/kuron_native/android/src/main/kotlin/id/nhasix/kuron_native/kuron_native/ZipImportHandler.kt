package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
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
 * with progress callbacks to Flutter.
 */
class ZipImportHandler(private val activity: Activity) {
    companion object {
        const val REQUEST_CODE_PICK_ZIP = 2003
        const val REQUEST_CODE_PICK_ZIP_MULTIPLE = 2004
        private const val BUFFER_SIZE = 8192 // 8KB buffer for streaming
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingPickMultiple = false

    /**
     * Launches the native file picker for ZIP files
     */
    fun pickZipFile(result: MethodChannel.Result) {
        pendingPickMultiple = false
        launchZipPicker(result, false)
    }

    fun pickZipFiles(result: MethodChannel.Result) {
        pendingPickMultiple = true
        launchZipPicker(result, true)
    }

    private fun launchZipPicker(result: MethodChannel.Result, allowMultiple: Boolean) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/zip"
            // Also allow other archive types
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                "application/zip",
                "application/x-zip",
                "application/x-zip-compressed"
            ))
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        try {
            pendingResult = result
            activity.startActivityForResult(
                intent,
                if (allowMultiple) REQUEST_CODE_PICK_ZIP_MULTIPLE else REQUEST_CODE_PICK_ZIP,
            )
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICK_FAILED", "Failed to open file picker: ${e.message}", null)
        }
    }

    fun getZipDisplayName(contentUri: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(contentUri)
            var displayName: String? = null

            activity.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0 && cursor.moveToFirst()) {
                    displayName = cursor.getString(nameIndex)
                }
            }

            result.success(displayName)
        } catch (e: Exception) {
            result.error("READ_NAME_FAILED", "Failed to read ZIP display name: ${e.message}", null)
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
     * Extracts ZIP file directly to destination directory with progress callbacks
     * This is a native implementation that streams data directly to disk
     * Progress is reported to Flutter via method channel callbacks for UI display
     */
    fun extractZipFile(
        contentUri: String,
        destinationPath: String,
        methodChannel: MethodChannel,
        result: MethodChannel.Result
    ) {
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
                            val relativePath = entry.name.replace('\\', '/').trimStart('/')
                            val fileName = File(relativePath).name
                            val extension = fileName.substringAfterLast('.', "").lowercase()

                            // Only extract image files
                            if (imageExtensions.contains(".$extension")) {
                                if (relativePath.isBlank()) {
                                    zipStream.closeEntry()
                                    entry = zipStream.nextEntry
                                    continue
                                }

                                val outputFile = File(destDir, relativePath)
                                val destCanonical = destDir.canonicalFile
                                val outputParent = outputFile.parentFile?.canonicalFile
                                val destPath = destCanonical.path
                                val parentPath = outputParent?.path
                                if (parentPath == null ||
                                    (parentPath != destPath &&
                                        !parentPath.startsWith("$destPath${File.separator}"))
                                ) {
                                    android.util.Log.w(
                                        "ZipImportHandler",
                                        "Skipped unsafe ZIP entry path: ${entry.name}"
                                    )
                                    zipStream.closeEntry()
                                    entry = zipStream.nextEntry
                                    continue
                                }

                                outputFile.parentFile?.mkdirs()

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

                                // Send progress to Flutter for UI display
                                withContext(Dispatchers.Main) {
                                    methodChannel.invokeMethod("onZipExtractionProgress", mapOf(
                                        "processed" to processedEntries,
                                        "total" to totalEntries,
                                        "imageCount" to imageCount,
                                        "currentFile" to relativePath
                                    ))
                                }
                            } else {
                                // Skip non-image files but still count them
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
                    withContext(Dispatchers.Main) {
                        result.error("NO_IMAGES", "No images found in ZIP file", null)
                    }
                    return@launch
                }

                // Return success
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to true,
                        "imageCount" to imageCount,
                        "destinationPath" to destinationPath
                    ))
                }

            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("EXTRACTION_FAILED", "Failed to extract ZIP: ${e.message}", e.toString())
                }
            }
        }
    }

    /**
     * Handles the activity result from file picker
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_ZIP || requestCode == REQUEST_CODE_PICK_ZIP_MULTIPLE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uris = mutableListOf<Uri>()
                data.data?.let { uris.add(it) }
                data.clipData?.let { clipData ->
                    for (index in 0 until clipData.itemCount) {
                        clipData.getItemAt(index).uri?.let { uris.add(it) }
                    }
                }

                val uniqueUris = uris.distinctBy { it.toString() }
                if (uniqueUris.isNotEmpty()) {
                    try {
                        val takeFlags: Int = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        for (uri in uniqueUris) {
                            try {
                                activity.contentResolver.takePersistableUriPermission(uri, takeFlags)
                            } catch (e: Exception) {
                                // Permission might not be persistable, that's okay
                            }
                        }
                    } catch (e: Exception) {
                        // Ignore permission issues
                    }

                    if (pendingPickMultiple) {
                        pendingResult?.success(uniqueUris.map { it.toString() })
                    } else {
                        pendingResult?.success(uniqueUris.first().toString())
                    }
                } else {
                    pendingResult?.error("NO_URI", "No URI returned from file picker", null)
                }
            } else {
                if (pendingPickMultiple) {
                    pendingResult?.success(emptyList<String>())
                } else {
                    pendingResult?.success(null) // User cancelled
                }
            }
            pendingResult = null
            pendingPickMultiple = false
            return true
        }
        return false
    }
}
