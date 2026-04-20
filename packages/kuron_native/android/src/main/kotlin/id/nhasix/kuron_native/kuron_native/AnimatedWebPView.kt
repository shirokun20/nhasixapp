package id.nhasix.kuron_native.kuron_native

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.drawable.AnimatedImageDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.util.LruCache
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import kotlin.concurrent.thread

private const val TAG = "KuronNativeWebP"

/**
 * Native Android view that renders animated WebP using [AnimatedImageDrawable] (API 28+).
 *
 * Android's [AnimatedImageDrawable] runs on the RenderThread, completely decoupled from
 * Flutter's raster/UI threads. This eliminates the jank caused by libwebp decoding 45+
 * frames × 1416×1608 px on Flutter's CPU raster thread.
 *
 * ## Caching
 * Decoded [AnimatedImageDrawable] instances are stored in a static [LruCache] so that
 * scroll-back in a continuous-scroll ListView doesn't require re-decoding from disk.
 *
 * ## Loading strategy (fast-path first)
 * 1. LruCache hit → reuse decoded drawable instantly (no I/O, no decode).
 * 2. If `filePath` creation param is provided **and the file exists**, load from disk.
 * 3. Otherwise fall back to downloading from `url`.
 *
 * ## Target-size optimisation
 * When `targetWidth` creation param is provided, [ImageDecoder.setTargetSize] scales
 * the decode output to match the display viewport, cutting memory ~75% and decode time
 * ~3-4× for large originals (e.g. 1416×1608 → ~500×568).
 *
 * API < 28 fallback: decodes first frame only via [BitmapFactory].
 */
@SuppressLint("ViewConstructor")
class AnimatedWebPView(
    private val context: Context,
    id: Int,
    args: Any?,
) : PlatformView {

    companion object {
        /**
         * LRU cache for decoded [AnimatedImageDrawable] instances.
         * Max 3 entries — keeps the last 3 heavy animated WebPs decoded in memory
         * so scroll-back is instant (no re-decode of 10+ MB files).
         */
        private val drawableCache = LruCache<String, AnimatedImageDrawable>(3)
    }

    private val container = FrameLayout(context).also {
        it.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
    }

    private val imageView = FrameThrottledImageView(context).apply {
        scaleType = ImageView.ScaleType.FIT_CENTER
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )
    }

    @Volatile
    private var disposed = false
    private var animatedDrawable: AnimatedImageDrawable? = null

    /** Cache key: prefer URL (unique per image) over file path. */
    private val cacheKey: String?

    /** Target decode width in px (viewport × devicePixelRatio). null = full resolution. */
    private val targetWidth: Int?

    init {
        container.addView(imageView)

        val params = args as? Map<*, *>
        val url = params?.get("url") as? String
        val filePath = params?.get("filePath") as? String
        targetWidth = (params?.get("targetWidth") as? Number)?.toInt()

        @Suppress("UNCHECKED_CAST")
        val headers: Map<String, String> = (params?.get("headers") as? Map<*, *>)
            ?.entries
            ?.associate { (k, v) -> k.toString() to v.toString() }
            ?: emptyMap()

        cacheKey = url ?: filePath

        // 1️⃣ LruCache check — instant, no I/O, no decode
        val cached = cacheKey?.let { drawableCache.get(it) }
        if (cached != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Log.i(TAG, "Cache HIT: ${cacheKey?.takeLast(40)}")
            animatedDrawable = cached
            cached.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
            imageView.setImageDrawable(cached)
            cached.start()
        } else {
            // 2️⃣ Disk / network path
            when {
                !filePath.isNullOrEmpty() -> {
                    Log.i(TAG, "Loading from disk cache: $filePath")
                    loadFromFile(File(filePath), fallbackUrl = url, fallbackHeaders = headers)
                }
                url != null -> {
                    Log.i(TAG, "Downloading from network: $url")
                    loadAsync(url, headers)
                }
                else -> Log.w(TAG, "No url or filePath provided")
            }
        }
    }

    /** Loads from [file] (disk cache); falls back to network if file is missing/corrupt. */
    private fun loadFromFile(
        file: File,
        fallbackUrl: String? = null,
        fallbackHeaders: Map<String, String> = emptyMap(),
    ) {
        thread(name = "AnimatedWebP-FileLoader", isDaemon = true) {
            try {
                if (!file.exists()) {
                    Log.w(TAG, "Cache file not found: ${file.path}")
                    if (fallbackUrl != null) {
                        Log.i(TAG, "Falling back to network: $fallbackUrl")
                        loadAsync(fallbackUrl, fallbackHeaders)
                    }
                    return@thread
                }
                if (disposed) return@thread
                Log.i(
                    TAG,
                    "Decoding from disk source: ${file.path} (${file.length()} bytes)",
                )
                renderFile(file)
            } catch (e: Exception) {
                Log.e(TAG, "loadFromFile failed: ${e.message}")
                if (fallbackUrl != null) {
                    Log.i(TAG, "Falling back to network after error: $fallbackUrl")
                    loadAsync(fallbackUrl, fallbackHeaders)
                }
            }
        }
    }

    private fun loadAsync(url: String, headers: Map<String, String>) {
        thread(name = "AnimatedWebP-Loader", isDaemon = true) {
            try {
                val bytes = fetchBytes(url, headers)
                if (disposed) return@thread
                renderBytes(bytes)
            } catch (_: Exception) {
                // Silently swallow – Flutter's ExtendedImage error UI is shown on top
                // if this widget never renders.
            }
        }
    }

    /** Decodes directly from [file] to avoid copying very large offline WebP files into memory. */
    private fun renderFile(file: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val source = ImageDecoder.createSource(file)
            val drawable = ImageDecoder.decodeDrawable(source) { decoder, info, _ ->
                val tw = targetWidth
                if (tw != null && tw > 0 && tw < info.size.width) {
                    val scale = tw.toFloat() / info.size.width
                    decoder.setTargetSize(tw, (info.size.height * scale).toInt())
                    Log.i(
                        TAG,
                        "Decode targetSize: ${tw}×${(info.size.height * scale).toInt()} " +
                            "(original: ${info.size.width}×${info.size.height})",
                    )
                }
            }

            if (drawable is AnimatedImageDrawable) {
                cacheKey?.let { key ->
                    drawableCache.put(key, drawable)
                    Log.i(TAG, "Cached decoded drawable: ${key.takeLast(40)}")
                }
            }

            imageView.post {
                if (disposed) return@post
                if (drawable is AnimatedImageDrawable) {
                    drawable.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
                    animatedDrawable = drawable
                    Log.i(TAG, "AnimatedImageDrawable started (API ${Build.VERSION.SDK_INT})")
                } else {
                    Log.i(TAG, "Non-animated drawable rendered (API ${Build.VERSION.SDK_INT})")
                }
                imageView.setImageDrawable(drawable)
                (drawable as? AnimatedImageDrawable)?.start()
            }
        } else {
            val bitmap = BitmapFactory.decodeFile(file.absolutePath)
            imageView.post {
                if (disposed) return@post
                imageView.setImageBitmap(bitmap)
            }
        }
    }

    /** Decodes [bytes] and sets the image on the [ImageView] on the main thread. */
    private fun renderBytes(bytes: ByteArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // API 28+: full animated decode via ImageDecoder
            val source = ImageDecoder.createSource(ByteBuffer.wrap(bytes))
            val drawable = ImageDecoder.decodeDrawable(source) { decoder, info, _ ->
                // 🔥 Target-size optimisation: decode at viewport resolution
                // instead of full original (e.g. 1416×1608 → ~500×568).
                // Reduces per-frame RGBA memory ~75% and decode time ~3-4×.
                val tw = targetWidth
                if (tw != null && tw > 0 && tw < info.size.width) {
                    val scale = tw.toFloat() / info.size.width
                    decoder.setTargetSize(tw, (info.size.height * scale).toInt())
                    Log.i(TAG, "Decode targetSize: ${tw}×${(info.size.height * scale).toInt()} " +
                            "(original: ${info.size.width}×${info.size.height})")
                }
            }

            // Cache decoded drawable immediately (before posting to main thread)
            if (drawable is AnimatedImageDrawable) {
                cacheKey?.let { key ->
                    drawableCache.put(key, drawable)
                    Log.i(TAG, "Cached decoded drawable: ${key.takeLast(40)}")
                }
            }

            imageView.post {
                if (disposed) return@post
                if (drawable is AnimatedImageDrawable) {
                    drawable.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
                    animatedDrawable = drawable
                    Log.i(TAG, "AnimatedImageDrawable started (API ${Build.VERSION.SDK_INT})")
                } else {
                    Log.i(TAG, "Non-animated drawable rendered (API ${Build.VERSION.SDK_INT})")
                }
                imageView.setImageDrawable(drawable)
                (drawable as? AnimatedImageDrawable)?.start()
            }
        } else {
            // API < 28: static first-frame fallback via BitmapFactory
            Log.i(TAG, "API ${Build.VERSION.SDK_INT} < 28: static first-frame fallback")
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            imageView.post {
                if (disposed) return@post
                imageView.setImageBitmap(bitmap)
            }
        }
    }

    /** Downloads raw bytes from [url] respecting optional [headers]. */
    @Throws(Exception::class)
    private fun fetchBytes(url: String, headers: Map<String, String>): ByteArray {
        val conn = URL(url).openConnection() as HttpURLConnection
        return try {
            conn.connectTimeout = 15_000
            conn.readTimeout = 90_000
            conn.requestMethod = "GET"
            headers.forEach { (k, v) -> conn.setRequestProperty(k, v) }
            conn.inputStream.use { it.readBytes() }
        } finally {
            conn.disconnect()
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        disposed = true
        // Stop animation but do NOT destroy the drawable — it stays in LruCache
        // for instant reuse on scroll-back.
        animatedDrawable?.stop()
        imageView.setImageDrawable(null)
        animatedDrawable = null
    }
}

/**
 * [ImageView] subclass that throttles drawable-triggered invalidations to ~30 fps.
 *
 * [AnimatedImageDrawable] calls [invalidateDrawable] on every frame advance at the
 * animation's native frame rate. Inside a Flutter [PlatformView] (Hybrid Composition),
 * each invalidation forces the Flutter compositor to re-composite the entire window,
 * flooding the SurfaceView's [BLASTBufferQueue] with:
 *   `Can't acquire next buffer. Already acquired max frames 4`
 *
 * By capping drawable invalidations at ~30 fps, we keep animations smooth while
 * preventing buffer queue exhaustion. Non-drawable invalidations (layout, visibility)
 * are not throttled.
 */
private class FrameThrottledImageView(context: Context) : ImageView(context) {
    private var lastDrawableInvalidateMs = 0L

    override fun invalidateDrawable(dr: Drawable) {
        val now = SystemClock.uptimeMillis()
        if (now - lastDrawableInvalidateMs >= FRAME_INTERVAL_MS) {
            lastDrawableInvalidateMs = now
            super.invalidateDrawable(dr)
        }
        // Frames arriving faster than the cap are silently dropped.
        // AnimatedImageDrawable advances internally regardless, so the
        // next capped frame will show the latest decoded frame.
    }

    companion object {
        /** ~30 fps cap — smooth enough for animated WebP, gentle on buffer queue. */
        private const val FRAME_INTERVAL_MS = 33L
    }
}
