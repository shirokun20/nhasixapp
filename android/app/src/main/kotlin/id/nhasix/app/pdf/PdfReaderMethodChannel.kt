package id.nhasix.app.pdf

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel for PDF Reader communication between Flutter and Android
 * Channel: "id.nhasix.app/pdf_reader"
 */
class PdfReaderMethodChannel(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "id.nhasix.app/pdf_reader"
    }

    private val channel = MethodChannel(messenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openPdf" -> openPdf(call, result)
            "closePdf" -> closePdf(result)
            else -> result.notImplemented()
        }
    }

    private fun openPdf(call: MethodCall, result: MethodChannel.Result) {
        val pdfPath = call.argument<String>("filePath")
        val title = call.argument<String>("title") ?: ""
        val startPage = call.argument<Int>("startPage") ?: 0

        if (pdfPath == null) {
            result.error("INVALID_ARGS", "Missing filePath argument", null)
            return
        }

        try {
            val intent = PdfReaderActivity.createIntent(activity, pdfPath, title, startPage)
            activity.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("PDF_OPEN_FAILED", e.message, null)
        }
    }

    private fun closePdf(result: MethodChannel.Result) {
        // PDF reader closes itself when user presses back
        // This method is here for API completeness
        result.success(null)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
