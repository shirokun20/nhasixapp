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
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Environment
import android.provider.Settings
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
import androidx.core.content.FileProvider
import android.webkit.CookieManager
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.ByteArrayOutputStream
import kotlin.math.min

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
    private lateinit var dnsResolver: id.nhasix.kuron_native.kuron_native.network.DnsResolver
    private val avifConverter = AvifConverter()

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

    private val executor = Executors.newSingleThreadExecutor() // Shared background work

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kuron_native")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Initialize download event channel and handler
        downloadEventChannel = io.flutter.plugin.common.EventChannel(flutterPluginBinding.binaryMessenger, "kuron_native/download_progress")
        downloadHandler = id.nhasix.kuron_native.kuron_native.download.DownloadHandler(context, downloadEventChannel)

        // Initialize DNS resolver
        val prefs = context.getSharedPreferences("kuron_dns", Context.MODE_PRIVATE)
        dnsResolver = id.nhasix.kuron_native.kuron_native.network.DnsResolver(context, prefs)

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
            "openAvif" -> {
                handleOpenAvif(call, result)
            }
            "convertAvifToWebP" -> {
                handleConvertAvifToWebP(call, result)
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
            "pickZipFiles" -> {
                handlePickZipFiles(result)
            }
            "readZipBytes" -> {
                handleReadZipBytes(call, result)
            }
            "getZipDisplayName" -> {
                handleGetZipDisplayName(call, result)
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
            "setDohProvider" -> {
                handleSetDohProvider(call, result)
            }
            "getDohProvider" -> {
                handleGetDohProvider(result)
            }
            "makeHttpRequest" -> {
                handleMakeHttpRequest(call, result)
            }
            "downloadBinary" -> {
                handleDownloadBinary(call, result)
            }
            "getDnsProviderState" -> {
                handleGetDnsProviderState(result)
            }
            "getPrivateDnsDiagnostics" -> {
                handleGetPrivateDnsDiagnostics(result)
            }
            "openDnsSettings" -> {
                handleOpenDnsSettings(result)
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

    private fun handleOpenAvif(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")

        if (filePath.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "File path is null", null)
            return
        }

        val file = File(filePath)
        if (!file.exists() || !file.isFile) {
            result.error("FILE_NOT_FOUND", "AVIF file not found", null)
            return
        }

        try {
            val authority = "${context.packageName}.kuron_native.fileprovider"
            val contentUri = FileProvider.getUriForFile(context, authority, file)

            val mimeCandidates = listOf("image/avif", "image/*", "*/*")
            var lastError: Exception? = null

            for (mimeType in mimeCandidates) {
                try {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(contentUri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    context.startActivity(Intent.createChooser(intent, null).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })
                    result.success(null)
                    return
                } catch (e: Exception) {
                    lastError = e
                }
            }

            result.error("OPEN_AVIF_FAILED", lastError?.message, null)
        } catch (e: Exception) {
            result.error("OPEN_AVIF_FAILED", e.message, null)
        }
    }

    private fun handleConvertAvifToWebP(call: MethodCall, result: Result) {
        val inputPath = call.argument<String>("inputPath")
        if (inputPath.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "inputPath is required", null)
            return
        }

        val quality = (call.argument<Int>("quality") ?: 45).coerceIn(0, 100)
        val outputPath = call.argument<String>("outputPath")
            ?.takeIf { it.isNotBlank() }
            ?: buildDefaultAvifWebPOutputPath(inputPath)

        executor.execute {
            try {
                val convertedPath = avifConverter.convert(
                    inputPath = inputPath,
                    quality = quality,
                    outputPath = outputPath,
                )
                mainThread {
                    result.success(mapOf("outputPath" to convertedPath))
                }
            } catch (t: Throwable) {
                android.util.Log.e(TAG, "convertAvifToWebP failed: ${t.message}", t)
                mainThread {
                    // Return soft failure so Flutter side can continue with reader fallback.
                    result.success(mapOf("outputPath" to null))
                }
            }
        }
    }

    private fun buildDefaultAvifWebPOutputPath(inputPath: String): String {
        val cacheDir = File(context.cacheDir, "avif_webp_cache")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }
        val hash = inputPath.hashCode().toUInt().toString(16)
        return File(cacheDir, "$hash.webp").absolutePath
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        downloadHandler.dispose()
        dnsResolver.clearCache()
        executor.shutdownNow()
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
        val captureRequestPatterns = call.argument<List<String>>("captureRequestPatterns")
        val allowRequestPatterns = call.argument<List<String>>("allowRequestPatterns")
        val pageFinishedScript = call.argument<String>("pageFinishedScript")
        val blockNetworkImages = call.argument<Boolean>("blockNetworkImages") ?: false
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
                captureRequestPatterns,
                allowRequestPatterns,
                pageFinishedScript,
                blockNetworkImages,
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
                    val capturedRequestUrl = data.getStringExtra(WebViewActivity.RESULT_CAPTURED_REQUEST_URL)
                    val pageHtml = data.getStringExtra(WebViewActivity.RESULT_PAGE_HTML)
                    val capturedImageUrls = data.getStringArrayListExtra(WebViewActivity.RESULT_CAPTURED_IMAGE_URLS)

                    val resultMap = HashMap<String, Any?>()
                    resultMap["cookies"] = cookies
                    resultMap["userAgent"] = userAgent
                    resultMap["currentUrl"] = currentUrl
                    resultMap["resolvedImageUrl"] = resolvedImageUrl
                    resultMap["capturedRequestUrl"] = capturedRequestUrl
                    resultMap["pageHtml"] = pageHtml
                    resultMap["capturedImageUrls"] = capturedImageUrls
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

    private fun handlePickZipFiles(result: Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available", null)
            return
        }

        if (zipImportHandler == null) {
            zipImportHandler = ZipImportHandler(activity)
        }

        zipImportHandler?.pickZipFiles(result)
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

    private fun handleGetZipDisplayName(call: MethodCall, result: Result) {
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

        zipImportHandler?.getZipDisplayName(contentUri, result)
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

    // ──────────────────────────────────────────────────
    // DNS over HTTPS
    // ──────────────────────────────────────────────────

    private fun handleSetDohProvider(call: MethodCall, result: Result) {
        val provider = call.argument<Int>("provider")
        if (provider == null) {
            result.error("INVALID_ARGS", "provider is required", null)
            return
        }

        try {
            dnsResolver.setDohProvider(provider)
            result.success(true)
        } catch (e: Exception) {
            result.error("SET_DOH_FAILED", e.message, null)
        }
    }

    private fun handleGetDohProvider(result: Result) {
        try {
            val provider = dnsResolver.getDohProvider()
            result.success(provider)
        } catch (e: Exception) {
            result.error("GET_DOH_FAILED", e.message, null)
        }
    }

    private fun handleGetDnsProviderState(result: Result) {
        try {
            result.success(dnsResolver.getDnsProviderState())
        } catch (e: Exception) {
            result.error("DNS_PROVIDER_STATE_FAILED", e.message, null)
        }
    }

    private fun handleGetPrivateDnsDiagnostics(result: Result) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.success(mapOf("isActive" to false, "serverName" to null, "reason" to "API_29_REQUIRED"))
                return
            }
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = cm.activeNetwork
            if (activeNetwork == null) {
                result.success(mapOf("isActive" to false, "serverName" to null, "reason" to "NO_ACTIVE_NETWORK"))
                return
            }
            val lp = cm.getLinkProperties(activeNetwork)
            if (lp == null) {
                result.success(mapOf("isActive" to false, "serverName" to null, "reason" to "NO_LINK_PROPERTIES"))
                return
            }
            result.success(mapOf(
                "isActive" to lp.isPrivateDnsActive,
                "serverName" to lp.privateDnsServerName
            ))
        } catch (e: Exception) {
            result.error("PRIVATE_DNS_DIAG_FAILED", e.message, null)
        }
    }

    private fun handleOpenDnsSettings(result: Result) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Intent("android.settings.PRIVATE_DNS_SETTINGS")
            } else Intent(Settings.ACTION_WIRELESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            try {
                context.startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(true)
            } catch (_: Exception) { result.success(false) }
        }
    }

    private fun handleMakeHttpRequest(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        val method = call.argument<String>("method") ?: "GET"
        @Suppress("UNCHECKED_CAST")
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        val body = call.argument<String>("body")

        if (url == null) {
            result.error("INVALID_ARGS", "url is required", null)
            return
        }

        executor.execute {
            try {
                val client = dnsResolver.getHttpClient()
                val requestBuilder = okhttp3.Request.Builder().url(url)

                headers.forEach { (key, value) ->
                    requestBuilder.addHeader(key, value)
                }

                when (method.uppercase()) {
                    "GET" -> requestBuilder.get()
                    "POST" -> {
                        val requestBody = (body ?: "").toRequestBody(
                            "application/json; charset=utf-8".toMediaType(),
                        )
                        requestBuilder.post(requestBody)
                    }
                    "PUT" -> {
                        val requestBody = (body ?: "").toRequestBody(
                            "application/json; charset=utf-8".toMediaType(),
                        )
                        requestBuilder.put(requestBody)
                    }
                    "DELETE" -> requestBuilder.delete()
                    else -> {
                        mainThread { result.error("INVALID_METHOD", "Unsupported HTTP method: $method", null) }
                        return@execute
                    }
                }

                val response = client.newCall(requestBuilder.build()).execute()
                val responseBody = response.body?.string()

                mainThread {
                    result.success(mapOf(
                        "statusCode" to response.code,
                        "body" to responseBody,
                        "headers" to response.headers.toMultimap()
                    ))
                }
            } catch (e: Exception) {
                mainThread {
                    result.error("HTTP_REQUEST_FAILED", e.message, null)
                }
            }
        }
    }

    private fun handleDownloadBinary(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        @Suppress("UNCHECKED_CAST")
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()

        if (url == null) {
            result.error("INVALID_ARGS", "url is required", null)
            return
        }

        executor.execute {
            try {
                val uri = Uri.parse(url)
                val fragment = uri.fragment
                val sanitizedUrl = buildString {
                    append(uri.scheme ?: "https")
                    append("://")
                    append(uri.encodedAuthority ?: "")
                    append(uri.encodedPath ?: "")
                    if (!uri.encodedQuery.isNullOrEmpty()) {
                        append('?')
                        append(uri.encodedQuery)
                    }
                }

                val client = dnsResolver.getHttpClient()
                val requestBuilder = okhttp3.Request.Builder().url(sanitizedUrl)

                headers.forEach { (key, value) ->
                    requestBuilder.addHeader(key, value)
                }

                val response = client.newCall(requestBuilder.build()).execute()
                val rawBytes = response.body?.bytes()
                val bytes = if (rawBytes != null && fragment?.contains("scrambled_") == true) {
                    descrambleIfNeeded(rawBytes, fragment)
                } else {
                    rawBytes
                }

                mainThread {
                    if (bytes != null) {
                        result.success(bytes)
                    } else {
                        result.error("DOWNLOAD_FAILED", "Empty response body", null)
                    }
                }
            } catch (e: Exception) {
                mainThread {
                    result.error("DOWNLOAD_FAILED", e.message, null)
                }
            }
        }
    }

    private fun descrambleIfNeeded(bytes: ByteArray, fragment: String): ByteArray {
        val offset = fragment.substringAfterLast('_').toIntOrNull() ?: return bytes
        return try {
            descrambleImage(bytes, offset)
        } catch (_: Exception) {
            bytes
        }
    }

    private fun descrambleImage(bytes: ByteArray, offset: Int): ByteArray {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return bytes
        val width = bitmap.width
        val height = bitmap.height
        val pieceWidth = min(200, ceilDiv(width, 5))
        val pieceHeight = min(200, ceilDiv(height, 5))
        val xMax = ceilDiv(width, pieceWidth) - 1
        val yMax = ceilDiv(height, pieceHeight) - 1

        val resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(resultBitmap)

        for (y in 0..yMax) {
            for (x in 0..xMax) {
                val xDst = pieceWidth * x
                val yDst = pieceHeight * y
                val w = min(pieceWidth, width - xDst)
                val h = min(pieceHeight, height - yDst)

                val xSrc = pieceWidth * if (x == xMax || xMax <= 0) {
                    x
                } else {
                    (xMax - x + offset) % xMax
                }
                val ySrc = pieceHeight * if (y == yMax || yMax <= 0) {
                    y
                } else {
                    (yMax - y + offset) % yMax
                }

                val srcRect = Rect(xSrc, ySrc, xSrc + w, ySrc + h)
                val dstRect = Rect(xDst, yDst, xDst + w, yDst + h)
                canvas.drawBitmap(bitmap, srcRect, dstRect, null)
            }
        }

        return ByteArrayOutputStream().use { output ->
            resultBitmap.compress(Bitmap.CompressFormat.JPEG, 90, output)
            output.toByteArray()
        }
    }

    private fun ceilDiv(value: Int, divisor: Int): Int {
        return (value + (divisor - 1)) / divisor
    }
}
