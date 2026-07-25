package id.nhasix.kuron_native.kuron_native

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * ONNX-based manga speech bubble detector.
 * Uses yolo26n model (Kiuyha/Manga-Bubble-YOLO, Apache-2.0).
 *
 * Input:  1280×1280 RGB float32 CHW [0,1] — letterbox (not stretch)
 * Output: [1, 300, 6] — 300 detections, each [x, y, w, h, confidence, class_id]
 * No NMS needed (end-to-end head).
 */
class BubbleDetector(context: Context) : Closeable {

    private var session: ai.onnxruntime.OrtSession? = null
    private val env: ai.onnxruntime.OrtEnvironment
    private val inputName: String
    private val modelInputSize: Int = 1280

    // Letterbox state: padding offsets and scaling
    private var padLeft: Int = 0
    private var padTop: Int = 0
    private var letterScale: Float = 1f

    init {
        try {
            env = ai.onnxruntime.OrtEnvironment.getEnvironment()
            val modelBytes = context.assets.open("bubble_detector.onnx").use { it.readBytes() }
            val sessionOptions = ai.onnxruntime.OrtSession.SessionOptions()
            sessionOptions.addCPU(true)
            session = env.createSession(modelBytes, sessionOptions)
            val inputNames = session?.inputNames ?: throw RuntimeException("No input names")
            inputName = inputNames.iterator().next()
            android.util.Log.i(TAG, "BubbleDetector loaded. Input: $inputName")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to init BubbleDetector: ${e.message}")
            throw e
        }
    }

    /**
     * Detect bubbles with proper letterbox (no aspect-ratio distortion).
     */
    fun detect(imageBytes: ByteArray, origWidth: Int, origHeight: Int): List<Map<String, Any>> {
        val sess = session ?: return emptyList()

        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return emptyList()

        // 1. Letterbox resize — keep aspect ratio, add padding
        val scale = minOf(modelInputSize.toFloat() / bitmap.width, modelInputSize.toFloat() / bitmap.height)
        val newW = (bitmap.width * scale).toInt()
        val newH = (bitmap.height * scale).toInt()
        padLeft = (modelInputSize - newW) / 2
        padTop = (modelInputSize - newH) / 2
        letterScale = scale

        val resized = Bitmap.createScaledBitmap(bitmap, newW, newH, true)
        val letterbox = Bitmap.createBitmap(modelInputSize, modelInputSize, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(letterbox)
        canvas.drawBitmap(resized, padLeft.toFloat(), padTop.toFloat(), null)
        resized.recycle()

        val floatBuf = preprocessToBuffer(letterbox)
        letterbox.recycle()
        bitmap.recycle()

        // 2. Inference
        val shape = longArrayOf(1L, 3L, modelInputSize.toLong(), modelInputSize.toLong())
        val inputOnnx = ai.onnxruntime.OnnxTensor.createTensor(env, floatBuf, shape)
        val results = sess.run(mapOf(inputName to inputOnnx))
        inputOnnx.close()

        // 3. Parse output
        val output = results[0] as? ai.onnxruntime.OnnxTensor ?: return emptyList()
        val floatBuffer = output.floatBuffer
        val numDetections = 300
        val valuesPerDetection = 6

        val detections = mutableListOf<Map<String, Any>>()
        val confThreshold = 0.25f

        for (i in 0 until numDetections) {
            val base = i * valuesPerDetection
            val x = floatBuffer.get(base)       // center x in 1280-space
            val y = floatBuffer.get(base + 1)   // center y
            val w = floatBuffer.get(base + 2)   // width
            val h = floatBuffer.get(base + 3)   // height
            val conf = floatBuffer.get(base + 4)

            if (conf < confThreshold) continue

            // YOLO26 end-to-end outputs [x1, y1, x2, y2, conf, class_id]
            // x1,y1 = top-left, x2,y2 = bottom-right (in 1280 letterbox space)
            // Convert from 1280-letterbox space → original image coords
            val left = ((x - padLeft) / letterScale).toInt().coerceIn(0, origWidth - 1)
            val top = ((y - padTop) / letterScale).toInt().coerceIn(0, origHeight - 1)
            val right = ((w - padLeft) / letterScale).toInt().coerceIn(0, origWidth - 1)
            val bottom = ((h - padTop) / letterScale).toInt().coerceIn(0, origHeight - 1)
            val rw = (right - left).coerceAtLeast(1)
            val rh = (bottom - top).coerceAtLeast(1)

            detections.add(mapOf(
                "x" to left,
                "y" to top,
                "w" to rw,
                "h" to rh,
                "confidence" to conf.toDouble(),
            ))
        }

        results.close()
        return detections
    }

    /** ARGB → float32 CHW normalized [0,1], sequential put */
    private fun preprocessToBuffer(bitmap: Bitmap): FloatBuffer {
        val pixels = IntArray(modelInputSize * modelInputSize)
        bitmap.getPixels(pixels, 0, modelInputSize, 0, 0, modelInputSize, modelInputSize)
        val total = 3 * modelInputSize * modelInputSize

        val floatBuffer = ByteBuffer.allocateDirect(total * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        for (y in 0 until modelInputSize) {
            for (x in 0 until modelInputSize) {
                val pixel = pixels[y * modelInputSize + x]
                floatBuffer.put(((pixel shr 16) and 0xFF) / 255.0f) // R
            }
        }
        for (y in 0 until modelInputSize) {
            for (x in 0 until modelInputSize) {
                val pixel = pixels[y * modelInputSize + x]
                floatBuffer.put(((pixel shr 8) and 0xFF) / 255.0f)  // G
            }
        }
        for (y in 0 until modelInputSize) {
            for (x in 0 until modelInputSize) {
                val pixel = pixels[y * modelInputSize + x]
                floatBuffer.put((pixel and 0xFF) / 255.0f)           // B
            }
        }

        floatBuffer.flip()
        return floatBuffer
    }

    override fun close() {
        try { session?.close() } catch (_: Exception) {}
    }

    companion object {
        const val TAG = "BubbleDetector"
    }
}
