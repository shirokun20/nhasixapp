package id.nhasix.kuron_native.kuron_native

import android.app.DownloadManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.pdf.PdfDocument
import android.net.Uri
import android.os.Environment
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

/** KuronNativePlugin */
class KuronNativePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
    
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null
    
    private val WEBVIEW_REQUEST_CODE = 1001
    
    private val executor = Executors.newSingleThreadExecutor() // For background PDF work

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kuron_native")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
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
            "openWebView" -> {
                handleOpenWebView(call, result)
            }
            "openPdf" -> {
                handleOpenPdf(call, result)
            }
            "showLoginWebView" -> {
                handleShowLoginWebView(call, result)
            }
            "clearCookies" -> {
                handleClearCookies(result)
            }
            else -> {
                result.notImplemented()
            }
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
            
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            
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
            try {
                val pdfDocument = PdfDocument()

                val total = imagePaths.size
                for ((index, path) in imagePaths.withIndex()) {
                    val bitmap = BitmapFactory.decodeFile(path)
                    if (bitmap != null) {
                        // Create a page logic
                        val pageInfo = PdfDocument.PageInfo.Builder(bitmap.width, bitmap.height, index + 1).create()
                        val page = pdfDocument.startPage(pageInfo)
                        
                        val canvas = page.canvas
                        canvas.drawBitmap(bitmap, 0f, 0f, null)
                        
                        pdfDocument.finishPage(page)
                        bitmap.recycle() // Free memory immediately
                        
                        // Report Progress
                        val progress = ((index + 1).toFloat() / total * 100).toInt()
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            try {
                                channel.invokeMethod("onProgress", mapOf(
                                    "progress" to progress,
                                    "message" to "Processing page ${index + 1}/$total"
                                ))
                            } catch (e: Exception) {
                                // Ignore if channel closed or ui gone
                            }
                        }
                    }
                }

                val file = File(outputPath)
                // Ensure parent exists
                file.parentFile?.mkdirs()
                
                val outputStream = FileOutputStream(file)
                pdfDocument.writeTo(outputStream)
                
                outputStream.close()
                pdfDocument.close()
                
                // Switch back to main thread for result
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    val fileSize = file.length()
                    val resultMap = mapOf(
                        "success" to true,
                        "pdfPath" to outputPath,
                        "pageCount" to total,
                        "fileSize" to fileSize
                    )
                    result.success(resultMap)
                }

            } catch (e: Exception) {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                     result.error("PDF_CONVERSION_FAILED", e.message, null)
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
        val initialCookie = call.argument<String>("initialCookie") // New argument

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
            val intent = id.nhasix.kuron_native.kuron_native.WebViewActivity.createIntent(context, url, userAgent, successFilters, initialCookie)
            activity.startActivityForResult(intent, WEBVIEW_REQUEST_CODE)
        } catch (e: Exception) {
             pendingResult = null
             result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == WEBVIEW_REQUEST_CODE) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val cookies = data.getStringArrayListExtra(WebViewActivity.RESULT_COOKIES)
                    val userAgent = data.getStringExtra(WebViewActivity.RESULT_USER_AGENT)
                    
                    val resultMap = HashMap<String, Any?>()
                    resultMap["cookies"] = cookies
                    resultMap["userAgent"] = userAgent
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
}
        return false
    }
}
