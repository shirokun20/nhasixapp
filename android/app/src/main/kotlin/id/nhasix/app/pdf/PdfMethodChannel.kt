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

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }
}
