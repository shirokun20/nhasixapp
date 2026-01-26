package id.nhasix.app.pdf

import android.content.Context
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PdfMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "id.nhasix.app/pdf_conversion"
    }

    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generatePdf" -> handleGeneratePdf(call, result)
            "generatePdfNative" -> handleGeneratePdfNative(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleGeneratePdf(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        val imagePaths = call.argument<List<String>>("imagePaths")
        val maxPagesPerFile = call.argument<Int>("maxPagesPerFile") ?: 50

        if (contentId == null || imagePaths == null) {
            result.error("INVALID_ARGS", "contentId and imagePaths are required", null)
            return
        }

        val workRequest = OneTimeWorkRequestBuilder<PdfGeneratorWorker>()
            .setInputData(workDataOf(
                PdfGeneratorWorker.KEY_CONTENT_ID to contentId,
                PdfGeneratorWorker.KEY_IMAGE_PATHS to imagePaths.toTypedArray(),
                PdfGeneratorWorker.KEY_MAX_PAGES to maxPagesPerFile
            ))
            .addTag("pdf_gen_$contentId")
            .build()

        WorkManager.getInstance(context).enqueue(workRequest)
        
        // Return the Work ID so Flutter can track it using a generic WorkManager plugin or event channel if needed
        result.success(workRequest.id.toString())
    }

    /**
     * Handle native high-performance PDF generation
     * Uses NativePdfGenerator for 5x speedup on large webtoon sets
     */
    private fun handleGeneratePdfNative(call: MethodCall, result: MethodChannel.Result) {
        val imagePaths = call.argument<List<String>>("imagePaths")
        val outputPath = call.argument<String>("outputPath")
        val title = call.argument<String>("title") ?: "Untitled"

        if (imagePaths == null || outputPath == null) {
            result.error("INVALID_ARGS", "imagePaths and outputPath are required", null)
            return
        }

        // Run in background thread to avoid blocking Flutter UI
        Thread {
            try {
                val generator = NativePdfGenerator(context)
                
                generator.generatePdf(
                    imagePaths = imagePaths,
                    outputPath = outputPath,
                    title = title,
                    callback = object : NativePdfGenerator.ProgressCallback {
                        override fun onProgress(progress: Int, message: String) {
                            // Send progress updates to Flutter
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                methodChannel.invokeMethod("onProgress", mapOf(
                                    "progress" to progress,
                                    "message" to message
                                ))
                            }
                        }

                        override fun onComplete(pdfPath: String, pageCount: Int, fileSize: Long) {
                            // Return success to Flutter
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(mapOf(
                                    "success" to true,
                                    "pdfPath" to pdfPath,
                                    "pageCount" to pageCount,
                                    "fileSize" to fileSize
                                ))
                            }
                        }

                        override fun onError(error: String) {
                            // Return error to Flutter
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.error("PDF_ERROR", error, null)
                            }
                        }
                    }
                )
            } catch (e: Exception) {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.error("NATIVE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }.start()
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }
}
