package id.nhasix.app.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.pdf.PdfDocument
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class PdfGeneratorWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val KEY_CONTENT_ID = "contentId"
        const val KEY_IMAGE_PATHS = "imagePaths"
        const val KEY_MAX_PAGES = "maxPagesPerFile"
        const val KEY_RESULT_PATHS = "pdfPaths"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val contentId = inputData.getString(KEY_CONTENT_ID) ?: return@withContext Result.failure()
        val imagePaths = inputData.getStringArray(KEY_IMAGE_PATHS) ?: return@withContext Result.failure()
        val maxPagesPerFile = inputData.getInt(KEY_MAX_PAGES, 50)

        // Progress update: 0%
        setProgress(workDataOf("progress" to 0))

        try {
            val pdfPaths = generatePdf(contentId, imagePaths.toList(), maxPagesPerFile)
            Result.success(workDataOf(KEY_RESULT_PATHS to pdfPaths.toTypedArray()))
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure(workDataOf("error" to e.message))
        }
    }

    private suspend fun generatePdf(
        contentId: String,
        imagePaths: List<String>,
        maxPagesPerFile: Int
    ): List<String> {
        val pdfPaths = mutableListOf<String>()
        val chunks = imagePaths.chunked(maxPagesPerFile)
        val totalChunks = chunks.size

        chunks.forEachIndexed { chunkIndex, chunk ->
            if (isStopped) throw IOException("Worker stopped")

            val pdfPath = createPdfFromImages(
                contentId = contentId,
                imagePaths = chunk,
                partNumber = chunkIndex + 1,
                totalParts = totalChunks
            )
            pdfPaths.add(pdfPath)

            // Report progress
            val progress = ((chunkIndex + 1).toFloat() / totalChunks * 100).toInt()
            setProgress(workDataOf("progress" to progress))
        }

        return pdfPaths
    }

    private fun createPdfFromImages(
        contentId: String,
        imagePaths: List<String>,
        partNumber: Int,
        totalParts: Int
    ): String {
        // Output directory: /files/pdf/{contentId}/
        val pdfDir = File(applicationContext.getExternalFilesDir(null), "pdf/$contentId")
        if (!pdfDir.exists()) {
            pdfDir.mkdirs()
        }

        val fileName = if (totalParts > 1) "${contentId}_part_$partNumber.pdf" else "$contentId.pdf"
        val pdfFile = File(pdfDir, fileName)
        
        // If file exists, delete it to ensure fresh write
        if (pdfFile.exists()) {
            pdfFile.delete()
        }

        val document = PdfDocument()

        try {
            imagePaths.forEachIndexed { index, imagePath ->
                // Decode bitmap with options to avoid OOM
                val options = BitmapFactory.Options().apply {
                    inPreferredConfig = Bitmap.Config.RGB_565 // Reduce memory usage
                }
                var bitmap = BitmapFactory.decodeFile(imagePath, options) ?: return@forEachIndexed

                // Create A4-ish page or dynamically sized based on image? 
                // Better to match image aspect ratio to avoid distortion/cropping
                val pageInfo = PdfDocument.PageInfo.Builder(
                    bitmap.width,
                    bitmap.height,
                    index + 1
                ).create()

                val page = document.startPage(pageInfo)
                val canvas = page.canvas

                // Draw bitmap
                canvas.drawBitmap(bitmap, 0f, 0f, null)

                document.finishPage(page)
                
                // Explicitly recycle bitmap
                bitmap.recycle()
            }

            FileOutputStream(pdfFile).use { output ->
                document.writeTo(output)
            }
        } finally {
            document.close()
        }

        return pdfFile.absolutePath
    }
}
