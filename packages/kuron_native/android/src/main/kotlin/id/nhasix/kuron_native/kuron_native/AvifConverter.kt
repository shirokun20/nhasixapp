package id.nhasix.kuron_native.kuron_native

import android.util.Log
import com.antonkarpenko.ffmpegkit.FFmpegKit
import com.antonkarpenko.ffmpegkit.ReturnCode
import java.io.File

class AvifConverter {
    companion object {
        private const val TAG = "AvifConverter"
    }

    fun convert(inputPath: String, quality: Int, outputPath: String): String? {
        val inputFile = File(inputPath)
        if (!inputFile.exists() || !inputFile.isFile || inputFile.length() <= 0L) {
            Log.w(TAG, "Invalid AVIF input: $inputPath")
            return null
        }

        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()

        if (outputFile.exists() && outputFile.isFile && outputFile.length() > 0L) {
            return outputFile.absolutePath
        }

        val clampedQuality = quality.coerceIn(0, 100)
        val primaryCommand = buildCommand(
            inputPath = inputPath,
            quality = clampedQuality,
            outputPath = outputPath,
            includeAnimatedStreamMap = true,
        )

        if (executeCommand(primaryCommand, outputFile)) {
            return outputFile.absolutePath
        }

        // Retry without explicit stream map when AVIF does not expose stream #1.
        outputFile.delete()
        val fallbackCommand = buildCommand(
            inputPath = inputPath,
            quality = clampedQuality,
            outputPath = outputPath,
            includeAnimatedStreamMap = false,
        )

        return if (executeCommand(fallbackCommand, outputFile)) {
            outputFile.absolutePath
        } else {
            null
        }
    }

    private fun buildCommand(
        inputPath: String,
        quality: Int,
        outputPath: String,
        includeAnimatedStreamMap: Boolean,
    ): String {
        val mapArg = if (includeAnimatedStreamMap) "-map 0:v:1 " else ""
        return "-y -i ${quotePath(inputPath)} " +
            "${mapArg}-r 15 -c:v libwebp -quality $quality -loop 0 " +
            "-pix_fmt yuv420p ${quotePath(outputPath)}"
    }

    private fun executeCommand(command: String, outputFile: File): Boolean {
        val session = FFmpegKit.execute(command)
        val returnCode = session.returnCode
        if (!ReturnCode.isSuccess(returnCode)) {
            Log.w(TAG, "FFmpeg command failed (rc=$returnCode): $command")
            return false
        }
        if (!outputFile.exists() || outputFile.length() <= 0L) {
            Log.w(TAG, "FFmpeg succeeded but output file is empty: ${outputFile.path}")
            return false
        }
        return true
    }

    private fun quotePath(path: String): String {
        return "\"${path.replace("\\", "\\\\").replace("\"", "\\\"")}\""
    }
}
