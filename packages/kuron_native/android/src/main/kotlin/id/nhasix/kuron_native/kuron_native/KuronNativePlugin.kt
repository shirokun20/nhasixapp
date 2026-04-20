package id.nhasix.kuron_native.kuron_native

import android.app.DownloadManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.pdf.PdfDocument
import android.os.Build
import android.net.Uri
import android.os.Environment
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.app.Activity
import android.content.Intent
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import android.webkit.CookieManager
import android.webkit.MimeTypeMap

/** KuronNativePlugin */
class KuronNativePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
    
    private lateinit var channel: MethodChannel
    private lateinit var downloadEventChannel: io.flutter.plugin.common.EventChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null
    private var pendingPickFileMimeType: String? = null
    private var pendingPickFileMode: String? = null
    private var pendingCaptchaResult: Result? = null
    private lateinit var downloadHandler: id.nhasix.kuron_native.kuron_native.download.DownloadHandler
    private var zipImportHandler: ZipImportHandler? = null

    private val WEBVIEW_REQUEST_CODE = 1001
    private val PICK_DIRECTORY_REQUEST_CODE = 1002
    private val PICK_FILE_REQUEST_CODE = 1003
    private val CAPTCHA_WEBVIEW_REQUEST_CODE = 1004
    
    companion object {
        const val TAG = "KuronNativePlugin"
        
        // Webtoon detection threshold (matches Flutter's WebtoonDetector)
        private const val WEBTOON_ASPECT_RATIO_THRESHOLD = 2.5f

        // Maximum chunk height for splitting webtoons (matches Flutter's ImageSplitter)
        private const val MAX_CHUNK_HEIGHT = 3000
    }

    private val executor = Executors.newSingleThreadExecutor() // For background PDF work

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kuron_native")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Initialize download event channel and handler
        downloadEventChannel = io.flutter.plugin.common.EventChannel(flutterPluginBinding.binaryMessenger, "kuron_native/download_progress")
        downloadHandler = id.nhasix.kuron_native.kuron_native.download.DownloadHandler(context, downloadEventChannel)

        // Register native animated-WebP PlatformView.
        // AnimatedWebPView guards API level internally:
        //   ≥ API 28 → AnimatedImageDrawable (full animation, RenderThread)
        //   < API 28 → BitmapFactory first-frame fallback
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "kuron_animated_webp_view",
            AnimatedWebPViewFactory(),
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "startDownload" -> {
                handleStartDownload(call, result)
            }
            "convertImagesToPdf" -> {
                handleConvertToPdf(call, result)
            }
            "openWebView" -> {
                handleOpenWebView(call, result)
            }
            "openPdf" -> {
                handleOpenPdf(call, result)
            }
            "showLoginWebView" -> {
                handleShowLoginWebView(call, result)
            }
            "showCaptchaWebView" -> {
                handleShowCaptchaWebView(call, result)
            }
            "clearCookies" -> {
                handleClearCookies(result)
            }
            "getSystemInfo" -> {
                handleGetSystemInfo(call, result)
            }
            "pickDirectory" -> {
                handlePickDirectory(result)
            }
            "pickTextFile" -> {
                handlePickTextFile(call, result)
            }
            "pickBinaryFile" -> {
                handlePickBinaryFile(call, result)
            }
            "pickZipFile" -> {
                handlePickZipFile(result)
            }
            "readZipBytes" -> {
                handleReadZipBytes(call, result)
            }
            "extractZipFile" -> {
                handleExtractZipFile(call, result)
            }
            // Delegate native download methods to handler
            "kuronNativeStartDownload", 
            "kuronNativeCancelDownload",
            "kuronNativePauseDownload", 
            "kuronNativeGetDownloadStatus",
            "kuronNativeGetDownloadedFiles",
            "kuronNativeGetDownloadPath",
            "kuronNativeDeleteDownloadedContent",
            "kuronNativeCountDownloadedFiles" -> {
                downloadHandler.handleMethodCall(call, result)
            }
            "getThumbnailForWebP" -> {
                handleGetWebPThumbnail(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // ──────────────────────────────────────────────────
    // WebP Thumbnail
    // ──────────────────────────────────────────────────

    /**
     * Extracts the first frame of an animated WebP as a compressed JPEG and
     * caches it in [context.cacheDir]/webp_thumbnails/.
     *
     * Params (from MethodCall):
     *   filePath – absolute path to an already-cached WebP file (preferred).
     *   url      – fallback HTTP URL to download if filePath is absent.
     *
     * Returns a map: {"thumbnailPath": <JPEG path>, "webpPath": <raw WebP disk cache path>}
     * Both values are non-null on success; result.success(null) on failure.
     *
     * The raw WebP is cached so [AnimatedWebPView] can load from disk immediately on
     * first play — no second network download required.
     */
    private fun handleGetWebPThumbnail(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")
        val url = call.argument<String>("url")
        val requestId = call.argument<String>("requestId")

        @Suppress("UNCHECKED_CAST")
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()

        val cacheKey = filePath ?: url ?: run {
            result.success(null)
            return
        }

        val thumbDir = File(context.cacheDir, "webp_thumbnails").also { it.mkdirs() }
        val thumbFile = File(thumbDir, "${Math.abs(cacheKey.hashCode())}.jpg")

        val webpDir = File(context.cacheDir, "webp_cache").also { it.mkdirs() }
        val webpFile = File(webpDir, "${Math.abs(cacheKey.hashCode())}.webp")

        val localSourceFile = filePath
            ?.takeIf { it.isNotEmpty() }
            ?.let(::File)
            ?.takeIf { it.exists() && it.length() > 0L }
        val cachedSourceFile = webpFile.takeIf { it.exists() && it.length() > 0L }
        val preferredSourceFile = localSourceFile ?: cachedSourceFile

        // Fast-path: thumbnail already exists and we have a usable source file.
        if (thumbFile.exists() && thumbFile.length() > 0 && preferredSourceFile != null) {
            result.success(
                mapOf(
                    "thumbnailPath" to thumbFile.absolutePath,
                    "webpPath" to preferredSourceFile.absolutePath,
                ),
            )
            return
        }

        executor.execute {
            try {
                val sourceFile: File = when {
                    localSourceFile != null -> localSourceFile
                    cachedSourceFile != null -> cachedSourceFile
                    url != null -> {
                        val bytes = downloadBytesForThumbnail(url, headers, requestId)
                        if (!webpFile.exists() || webpFile.length() == 0L) {
                            webpFile.writeBytes(bytes)
                        }
                        webpFile
                    }
                    else -> {
                        mainThread { result.success(null) }
                        return@execute
                    }
                }

                // Decode first frame directly from file so large offline WebP files
                // do not need to be copied into a giant ByteArray just to build the preview.
                val bitmap = decodeWebPPreviewBitmap(sourceFile)
                if (bitmap == null) { mainThread { result.success(null) }; return@execute }

                FileOutputStream(thumbFile).use { fos ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 75, fos)
                }
                bitmap.recycle()

                mainThread {
                    result.success(
                        mapOf(
                            "thumbnailPath" to thumbFile.absolutePath,
                            "webpPath" to sourceFile.absolutePath,
                        ),
                    )
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "getThumbnailForWebP failed: ${e.message}")
                mainThread { result.success(null) }
            }
        }
    }

    private fun decodeWebPPreviewBitmap(file: File): Bitmap? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val source = ImageDecoder.createSource(file)
                ImageDecoder.decodeBitmap(source)
            } catch (_: Exception) {
                BitmapFactory.decodeFile(file.absolutePath)
            }
        } else {
            BitmapFactory.decodeFile(file.absolutePath)
        }
    }

    /** Runs [block] on the Android main thread (required by Flutter Result callbacks). */
    private fun mainThread(block: () -> Unit) =
        Handler(Looper.getMainLooper()).post(block)

    private fun emitWebPThumbnailProgress(
        requestId: String,
        receivedBytes: Long,
        totalBytes: Long?,
    ) {
        mainThread {
            channel.invokeMethod(
                "onWebPThumbnailProgress",
                mapOf(
                    "requestId" to requestId,
                    "receivedBytes" to receivedBytes,
                    "totalBytes" to totalBytes,
                ),
            )
        }
    }

    private fun downloadBytesForThumbnail(
        url: String,
        headers: Map<String, String>,
        requestId: String?,
    ): ByteArray {
        val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
        return try {
            conn.connectTimeout = 15_000
            conn.readTimeout = 90_000
            conn.requestMethod = "GET"
            headers.forEach { (key, value) ->
                conn.setRequestProperty(key, value)
            }
            conn.connect()

            val totalBytes = conn.contentLengthLong.takeIf { it > 0L }

            conn.inputStream.use { input ->
                val output = java.io.ByteArrayOutputStream()
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var receivedBytes = 0L
                var lastReportedBytes = 0L

                while (true) {
                    val read = input.read(buffer)
                    if (read == -1) break

                    output.write(buffer, 0, read)
                    receivedBytes += read

                    if (requestId != null &&
                        (receivedBytes - lastReportedBytes >= 128 * 1024 ||
                            (totalBytes != null && receivedBytes >= totalBytes))
                    ) {
                        emitWebPThumbnailProgress(requestId, receivedBytes, totalBytes)
                        lastReportedBytes = receivedBytes
                    }
                }

                if (requestId != null && receivedBytes > lastReportedBytes) {
                    emitWebPThumbnailProgress(requestId, receivedBytes, totalBytes)
                }

                output.toByteArray()
            }
        } finally {
            conn.disconnect()
        }
    }

    private fun handleStartDownload(call: MethodCall, result: Result) {
        try {
            val url = call.argument<String>("url")
            val fileName = call.argument<String>("fileName")
            val destinationDir = call.argument<String>("destinationDir")
            val title = call.argument<String>("title")
            val description = call.argument<String>("description")
            val mimeType = call.argument<String>("mimeType")
            val cookie = call.argument<String>("cookie")
            val userAgent = call.argument<String>("userAgent")

            if (url == null || fileName == null) {
                result.error("INVALID_ARGS", "Url and fileName are required", null)
                return
            }

            val request = DownloadManager.Request(Uri.parse(url))
            
            // Set Headers
            if (cookie != null) {
                request.addRequestHeader("Cookie", cookie)
            }
            if (userAgent != null) {
                request.addRequestHeader("User-Agent", userAgent)
            }

            // Set Details
            if (title != null) {
                request.setTitle(title)
            }
            if (description != null) {
                request.setDescription(description)
            }
            if (mimeType != null) {
                request.setMimeType(mimeType)
            }

            // Set Destination (scoped storage friendly)
            if (destinationDir != null) {
                 request.setDestinationInExternalProhibitedDir(
                    context, 
                    Environment.DIRECTORY_DOWNLOADS, 
                    "$destinationDir/$fileName"
                )
            } else {
                 request.setDestinationInExternalProhibitedDir(
                    context, 
                    Environment.DIRECTORY_DOWNLOADS, 
                     fileName
                )
            }
            
            // request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            
            val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val downloadId = manager.enqueue(request)
            
            result.success(downloadId.toString())

        } catch (e: Exception) {
            result.error("DOWNLOAD_FAILED", e.message, null)
        }
    }
    
    // Helper for older Android versions or robust path handling
    private fun DownloadManager.Request.setDestinationInExternalProhibitedDir(context: Context, dirType: String, subPath: String) {
        // Simple wrapper to use setDestinationInExternalFilesDir which is generally safe/scoped
        // Or setDestinationInExternalPublicDir if we want it visible to other apps
        // For 'Downloads', public is usually better for user visibility.
        this.setDestinationInExternalPublicDir(dirType, subPath)
    }

    private fun handleConvertToPdf(call: MethodCall, result: Result) {
        val imagePaths = call.argument<List<String>>("imagePaths")
        val outputPath = call.argument<String>("outputPath")

        if (imagePaths == null || outputPath == null) {
            result.error("INVALID_ARGS", "Image list and output path required", null)
            return
        }

        // Run on background thread to avoid blocking UI
        executor.execute {
            var totalPages = 0
            val document = PdfDocument()
            try {
                // Ensure parent exists
                val file = File(outputPath)
                file.parentFile?.mkdirs()

                val total = imagePaths.size
                for ((index, path) in imagePaths.withIndex()) {
                    // Load bitmap with error handling and optimization
                    val bitmap = loadBitmap(path)
                    
                    if (bitmap != null) {
                        // Check if webtoon (extreme aspect ratio)
                        val aspectRatio = bitmap.height.toFloat() / bitmap.width
                        val isWebtoon = aspectRatio > WEBTOON_ASPECT_RATIO_THRESHOLD

                        if (isWebtoon) {
                            // Split webtoon into chunks
                            val chunks = splitBitmap(bitmap, MAX_CHUNK_HEIGHT)
                            
                            chunks.forEach { chunk ->
                                if (addPageToPdf(document, chunk, totalPages)) {
                                    totalPages++
                                }
                                chunk.recycle() // Free memory immediately
                            }
                        } else {
                             // Normal image, add as single page
                             if (addPageToPdf(document, bitmap, totalPages)) {
                                 totalPages++
                             }
                        }
                        
                        bitmap.recycle() // Free memory for original bitmap

                    } else {
                         android.util.Log.w("KuronNative", "Failed to load bitmap: $path");
                    }
                    
                    // Report Progress (Always report, even if failed)
                    val progress = ((index + 1).toFloat() / total * 100).toInt()
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        try {
                            channel.invokeMethod("onProgress", mapOf(
                                "progress" to progress,
                                "message" to "Processing page $totalPages (Image ${index + 1}/$total)"
                            ))
                        } catch (e: Exception) {
                            // Ignore if channel closed or ui gone
                        }
                    }
                }

                // Write to file
                val outputStream = FileOutputStream(file)
                document.writeTo(outputStream)
                outputStream.close()
                document.close()
                
                // Switch back to main thread for result
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    val fileSize = file.length()
                    val resultMap = mapOf(
                        "success" to true,
                        "pdfPath" to outputPath,
                        "pageCount" to totalPages,
                        "fileSize" to fileSize
                    )
                    result.success(resultMap)
                }

            } catch (e: Exception) {
                try { document.close() } catch (ignored: Exception) {}
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                     result.error("PDF_CONVERSION_FAILED", e.message, null)
                }
            }
        }
    }

    /**
     * Load bitmap from file with proper error handling and optimization
     */
    private fun loadBitmap(imagePath: String): Bitmap? {
        return try {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(imagePath, options)

            // OPTIMIZATION 1: Calculate sample size to downscale huge images
            // Target width ~900px is usually enough for phones/tablets reading
            val targetWidth = 900
            var sampleSize = 1
            if (options.outWidth > targetWidth) {
                sampleSize = Math.round(options.outWidth.toFloat() / targetWidth.toFloat())
            }

            // Perform actual decode with optimizations
            val decodeOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = false
                inSampleSize = sampleSize
                // OPTIMIZATION 2: Use RGB_565 for 50% memory/size reduction (no alpha needed)
                inPreferredConfig = Bitmap.Config.RGB_565
            }

            var bitmap = BitmapFactory.decodeFile(imagePath, decodeOptions)

            if (bitmap != null) {
                // Ensure width consistency if sampleSize didn't get us exactly to target
                if (bitmap.width > targetWidth + 100) { // Tolerance +100px
                    val scaledHeight = (bitmap.height * targetWidth.toFloat() / bitmap.width).toInt()
                    val scaledBitmap = Bitmap.createScaledBitmap(bitmap, targetWidth, scaledHeight, true)
                    if (scaledBitmap != bitmap) {
                        bitmap.recycle()
                        bitmap = scaledBitmap
                    }
                }
            }
            bitmap
        } catch (e: OutOfMemoryError) {
            System.gc() // Suggest garbage collection
            null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Split a bitmap into vertical chunks
     */
    private fun splitBitmap(bitmap: Bitmap, maxHeight: Int): List<Bitmap> {
        val chunks = mutableListOf<Bitmap>()
        val width = bitmap.width
        val height = bitmap.height

        var y = 0
        while (y < height) {
            val chunkHeight = Integer.min(maxHeight, height - y)

            try {
                // Create chunk using Bitmap.createBitmap (memory-efficient)
                val chunk = Bitmap.createBitmap(bitmap, 0, y, width, chunkHeight)
                chunks.add(chunk)
            } catch (e: OutOfMemoryError) {
                System.gc()
                break
            }

            y += maxHeight
        }

        return chunks
    }

    /**
     * Add a bitmap as a page to the PDF document
     */
    private fun addPageToPdf(document: PdfDocument, bitmap: Bitmap, pageNumber: Int): Boolean {
        var page: PdfDocument.Page? = null
        return try {
            val pageInfo = PdfDocument.PageInfo.Builder(
                bitmap.width,
                bitmap.height,
                pageNumber
            ).create()

            page = document.startPage(pageInfo)
            val canvas: Canvas = page.canvas

            // Draw bitmap on canvas (no scaling, preserves quality)
            canvas.drawBitmap(bitmap, 0f, 0f, Paint())
            
            true
        } catch (e: Exception) {
            false
        } finally {
            // CRITICAL: Must always finish the page if it was started
            if (page != null) {
                try {
                    document.finishPage(page)
                } catch (e: Exception) {
                }
            }
        }
    }

    private fun handleOpenWebView(call: MethodCall, result: Result) {
        try {
            val url = call.argument<String>("url")
            val enableJs = call.argument<Boolean>("enableJavaScript") ?: true
            
            if (url == null) {
                result.error("INVALID_ARGS", "URL is required", null)
                return
            }

            val builder = CustomTabsIntent.Builder()
            
            // Optional: Customize colors (get from args if needed later)
            // builder.setToolbarColor(...) 

            val customTabsIntent = builder.build()
            // Ensure flag is set when launching from non-Activity context
            customTabsIntent.intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            customTabsIntent.launchUrl(context, Uri.parse(url))
            
            result.success(null)
        } catch (e: Exception) {
            result.error("WEBVIEW_ERROR", e.message, null)
        }
    }

    private fun handleOpenPdf(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")
        val title = call.argument<String>("title") ?: ""
        val startPage = call.argument<Int>("startPage") ?: 0

        if (filePath == null) {
            result.error("INVALID_ARGUMENT", "File path is null", null)
            return
        }

        try {
            // Launch Activity from context
            val intent = id.nhasix.kuron_native.kuron_native.pdf.PdfReaderActivity.createIntent(context, filePath, title, startPage)
            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("OPEN_PDF_FAILED", e.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        downloadHandler.dispose()
    }

    // ActivityAware Implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    private fun handleShowLoginWebView(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        val successFilters = call.argument<List<String>>("successUrlFilters")
        val userAgent = call.argument<String>("userAgent")
        val initialCookie = call.argument<String>("initialCookie")
        val autoCloseOnCookie = call.argument<String>("autoCloseOnCookie")
        val ssoRedirectUrl = call.argument<String>("ssoRedirectUrl")
        val domImageSelectors = call.argument<List<String>>("domImageSelectors")
        val domImageAttributes = call.argument<List<String>>("domImageAttributes")
        val domLinkSelectors = call.argument<List<String>>("domLinkSelectors")
        val enableAdBlock = call.argument<Boolean>("enableAdBlock") ?: false

        if (url == null) {
            result.error("INVALID_ARGS", "Url is required", null)
            return
        }

        if (pendingResult != null) {
            result.error("BUSY", "Another login operation is in progress", null)
            return
        }
        
        val activity = activityBinding?.activity
        if (activity == null) {
             result.error("NO_ACTIVITY", "Activity is not available", null)
             return
        }

        pendingResult = result
        
        try {
            val intent = id.nhasix.kuron_native.kuron_native.WebViewActivity.createIntent(
                context, 
                url, 
                userAgent, 
                successFilters, 
                initialCookie,
                autoCloseOnCookie,
                ssoRedirectUrl,
                domImageSelectors,
                domImageAttributes,
                domLinkSelectors,
                enableAdBlock,
                call.argument<Boolean>("clearCookies") ?: false
            )
            activity.startActivityForResult(intent, WEBVIEW_REQUEST_CODE)
        } catch (e: Exception) {
             pendingResult = null
             result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun handleShowCaptchaWebView(call: MethodCall, result: Result) {
        val provider = call.argument<String>("provider")?.trim()
        val siteKey = call.argument<String>("siteKey")?.trim()
        val baseUrl = call.argument<String>("baseUrl")

        if (provider.isNullOrEmpty() || siteKey.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "provider and siteKey are required", null)
            return
        }

        if (pendingCaptchaResult != null) {
            result.error("BUSY", "Another captcha operation is in progress", null)
            return
        }

        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        pendingCaptchaResult = result

        try {
            val intent = CaptchaWebViewActivity.createIntent(
                context = context,
                provider = provider,
                siteKey = siteKey,
                baseUrl = baseUrl,
            )
            activity.startActivityForResult(intent, CAPTCHA_WEBVIEW_REQUEST_CODE)
        } catch (e: Exception) {
            pendingCaptchaResult = null
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // Handle ZIP import first
        if (zipImportHandler?.onActivityResult(requestCode, resultCode, data) == true) {
            return true
        }

        if (requestCode == WEBVIEW_REQUEST_CODE) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val cookies = data.getStringArrayListExtra(WebViewActivity.RESULT_COOKIES)
                    val userAgent = data.getStringExtra(WebViewActivity.RESULT_USER_AGENT)
                    val currentUrl = data.getStringExtra(WebViewActivity.RESULT_CURRENT_URL)
                    val resolvedImageUrl = data.getStringExtra(WebViewActivity.RESULT_RESOLVED_IMAGE_URL)
                    
                    val resultMap = HashMap<String, Any?>()
                    resultMap["cookies"] = cookies
                    resultMap["userAgent"] = userAgent
                    resultMap["currentUrl"] = currentUrl
                    resultMap["resolvedImageUrl"] = resolvedImageUrl
                    resultMap["success"] = true
                    
                    pendingResult?.success(resultMap)
                } else {
                    // User cancelled or failed
                     val resultMap = HashMap<String, Any?>()
                    resultMap["success"] = false
                    pendingResult?.success(resultMap)
                }
                pendingResult = null
            }
            return true
        }

        if (requestCode == CAPTCHA_WEBVIEW_REQUEST_CODE) {
            if (pendingCaptchaResult != null) {
                val resultMap = HashMap<String, Any?>()
                if (data != null) {
                    resultMap["success"] = data.getBooleanExtra(CaptchaWebViewActivity.RESULT_SUCCESS, false)
                    resultMap["token"] = data.getStringExtra(CaptchaWebViewActivity.RESULT_TOKEN)
                    resultMap["errorCode"] = data.getStringExtra(CaptchaWebViewActivity.RESULT_ERROR_CODE)
                    resultMap["errorMessage"] = data.getStringExtra(CaptchaWebViewActivity.RESULT_ERROR_MESSAGE)
                } else {
                    resultMap["success"] = false
                }
                pendingCaptchaResult?.success(resultMap)
                pendingCaptchaResult = null
            }
            return true
        }
        
        if (requestCode == PICK_DIRECTORY_REQUEST_CODE) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        // Persist permissions (optional but good practice)
                        try {
                            val takeFlags: Int = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            context.contentResolver.takePersistableUriPermission(uri, takeFlags)
                        } catch (e: Exception) {
                            // Ignore
                        }

                        // Extract Absolute Path if possible (since we have MANAGE_EXTERNAL_STORAGE)
                        var path = uri.path
                        if (path != null && path.contains("primary:")) {
                            path = "/storage/emulated/0/" + path.substringAfter("primary:")
                        } else if (path != null && path.contains("tree/")) {
                             // Fallback attempts
                             if (path.contains("primary%3A")) {
                                  path = "/storage/emulated/0/" + path.substringAfter("primary%3A")
                             }
                        }
                        
                        // Clean up path if needed
                        if (path != null && path.startsWith("/tree/")) {
                             // Some devices return /tree/primary:Folder
                             if (path.contains("primary:")) {
                                  path = "/storage/emulated/0/" + path.substringAfter("primary:")
                             }
                        }

                        pendingResult?.success(path ?: uri.toString())
                    } else {
                         pendingResult?.error("NO_URI", "No directory selected", null)
                    }
                } else {
                     pendingResult?.success(null) // Cancelled
                }
                pendingResult = null
            }
            return true
        }

        if (requestCode == PICK_FILE_REQUEST_CODE) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        try {
                            val takeFlags: Int = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                            context.contentResolver.takePersistableUriPermission(uri, takeFlags)
                        } catch (e: Exception) {
                            // Ignore persist permission failures.
                        }

                        try {
                            val stream = context.contentResolver.openInputStream(uri)
                            if (stream == null) {
                                pendingResult?.error("READ_FILE_FAILED", "Unable to open selected file", null)
                            } else {
                                stream.use { input ->
                                    if (pendingPickFileMode == "binary") {
                                        val bytes = input.readBytes()
                                        pendingResult?.success(bytes)
                                    } else {
                                        val content = input.bufferedReader().use { it.readText() }
                                        pendingResult?.success(content)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            pendingResult?.error("READ_FILE_FAILED", e.message, null)
                        }
                    } else {
                        pendingResult?.error("NO_URI", "No file selected", null)
                    }
                } else {
                    pendingResult?.success(null) // Cancelled
                }

                pendingPickFileMimeType = null
                pendingPickFileMode = null
                pendingResult = null
            }
            return true
        }
        return false
    }

    private fun handleClearCookies(result: Result) {
        try {
            val cookieManager = android.webkit.CookieManager.getInstance()
            cookieManager.removeAllCookies { success ->
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.success(success)
                }
            }
        } catch (e: Exception) {

            result.error("CLEAR_COOKIES_FAILED", e.message, null)
        }
    }

    private fun handleGetSystemInfo(call: MethodCall, result: Result) {
        val type = call.argument<String>("type")
        try {
            val data = when (type) {
                "ram" -> SystemInfoUtils.getMemoryInfo(context)
                "storage" -> SystemInfoUtils.getStorageInfo()
                "battery" -> SystemInfoUtils.getBatteryInfo(context)
                else -> null
            }
            
            if (data != null) {
                result.success(data)
            } else {
                result.error("INVALID_TYPE", "Unknown info type: $type", null)
            }
        } catch (e: Exception) {
            result.error("SYSTEM_INFO_FAILED", e.message, null)
        }
    }

    private fun handlePickDirectory(result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
             result.error("NO_ACTIVITY", "Activity is not available", null)
             return
        }

        if (pendingResult != null) {
            result.error("BUSY", "Another operation is in progress", null)
            return
        }

        pendingResult = result

        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            activity.startActivityForResult(intent, PICK_DIRECTORY_REQUEST_CODE)
        } catch (e: Exception) {
            pendingResult = null
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun handlePickTextFile(call: MethodCall, result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        if (pendingResult != null) {
            result.error("BUSY", "Another operation is in progress", null)
            return
        }

        pendingResult = result
        pendingPickFileMimeType = call.argument<String>("mimeType")
        pendingPickFileMode = "text"

        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = pendingPickFileMimeType ?: "*/*"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            }
            activity.startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingPickFileMimeType = null
            pendingPickFileMode = null
            pendingResult = null
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun handlePickBinaryFile(call: MethodCall, result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        if (pendingResult != null) {
            result.error("BUSY", "Another operation is in progress", null)
            return
        }

        pendingResult = result
        pendingPickFileMimeType = call.argument<String>("mimeType")
        pendingPickFileMode = "binary"

        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = pendingPickFileMimeType ?: "*/*"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            }
            activity.startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingPickFileMimeType = null
            pendingPickFileMode = null
            pendingResult = null
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun handlePickZipFile(result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        if (zipImportHandler == null) {
            zipImportHandler = ZipImportHandler(activity)
        }

        zipImportHandler?.pickZipFile(result)
    }

    private fun handleReadZipBytes(call: MethodCall, result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        val contentUri = call.argument<String>("contentUri")
        if (contentUri == null) {
            result.error("INVALID_ARGUMENT", "contentUri is required", null)
            return
        }

        if (zipImportHandler == null) {
            zipImportHandler = ZipImportHandler(activity)
        }

        zipImportHandler?.readZipBytes(contentUri, result)
    }

    private fun handleExtractZipFile(call: MethodCall, result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        val contentUri = call.argument<String>("contentUri")
        val destinationPath = call.argument<String>("destinationPath")

        if (contentUri == null || destinationPath == null) {
            result.error("INVALID_ARGUMENT", "contentUri and destinationPath are required", null)
            return
        }

        if (zipImportHandler == null) {
            zipImportHandler = ZipImportHandler(activity)
        }

        zipImportHandler?.extractZipFile(contentUri, destinationPath, channel, result)
    }
}
