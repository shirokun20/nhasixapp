package id.nhasix.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Handler for ZIP file import functionality
 *
 * Provides native Android file picker for selecting ZIP files
 * and reading ZIP content via content URIs.
 */
class ZipImportHandler(private val activity: Activity) {
    companion object {
        const val CHANNEL_NAME = "id.nhasix.app/zip_import"
        const val METHOD_PICK_ZIP = "pickZipFile"
        const val METHOD_READ_ZIP = "readZipBytes"
    }

    private var pendingResult: MethodChannel.Result? = null

    /**
     * Sets up the MethodChannel and handles method calls
     */
    fun setupChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_PICK_ZIP -> {
                    pendingResult = result
                    pickZipFile()
                }
                METHOD_READ_ZIP -> {
                    val contentUri = call.argument<String>("contentUri")
                    if (contentUri != null) {
                        readZipBytes(contentUri, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "contentUri is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Launches the native file picker for ZIP files
     */
    private fun pickZipFile() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/zip"
            // Also allow other archive types
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                "application/zip",
                "application/x-zip",
                "application/x-zip-compressed"
            ))
        }

        try {
            activity.startActivityForResult(intent, REQUEST_CODE_PICK_ZIP)
        } catch (e: Exception) {
            pendingResult?.error("PICK_FAILED", "Failed to open file picker: ${e.message}", null)
            pendingResult = null
        }
    }

    /**
     * Reads ZIP file bytes from content URI
     */
    private fun readZipBytes(contentUri: String, result: MethodChannel.Result) {
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
     * Handles the activity result from file picker
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_ZIP) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Grant persistent read permission
                    try {
                        activity.contentResolver.takePersistableUriPermission(
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
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

    companion object {
        const val REQUEST_CODE_PICK_ZIP = 2003
    }
}
