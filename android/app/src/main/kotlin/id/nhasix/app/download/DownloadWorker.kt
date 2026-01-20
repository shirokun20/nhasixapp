package id.nhasix.app.download

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Environment
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import id.nhasix.app.R
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import timber.log.Timber
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit
import id.nhasix.app.network.DnsManager

class DownloadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val KEY_CONTENT_ID = "content_id"
        const val KEY_SOURCE_ID = "source_id"
        const val KEY_IMAGE_URLS = "image_urls"
        const val KEY_DESTINATION_PATH = "destination_path"
        const val KEY_COOKIES = "cookies"  // NEW: Cookies as JSON string
        const val KEY_PROGRESS = "progress"
        
        private const val TAG = "DownloadWorker"
        private const val CHANNEL_ID = "download_channel"
        private const val CHANNEL_NAME = "Downloads"
        private const val ALLOWED_COOKIE_DOMAIN = "crotpedia.com"  // NEW: Security - only allow crotpedia.com
    }
    
    private val notificationManager by lazy {
        applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }
    
    // NEW: Parse cookies from inputData and create HTTP client with authentication + DNS
    private val okHttpClient by lazy {
        val cookiesJson = inputData.getString(KEY_COOKIES)
        val cookies = parseCookies(cookiesJson)
        
        val builder = OkHttpClient.Builder()
            .dns(DnsManager.createDns())  // FIXED: Use imported DnsManager
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
        
        if (cookies != null && cookies.isNotEmpty()) {
            Timber.tag(TAG).d("Creating HTTP client with ${cookies.size} cookies for authentication")
            builder.cookieJar(createCookieJar(cookies))
        }
        
        builder.build()
    }

    init {
        createNotificationChannel()
    }

    override suspend fun doWork(): ListenableWorker.Result = withContext(Dispatchers.IO) {
        val contentId = inputData.getString(KEY_CONTENT_ID) ?: return@withContext Result.failure()
        val sourceId = inputData.getString(KEY_SOURCE_ID) ?: "unknown"
        val imageUrls = inputData.getStringArray(KEY_IMAGE_URLS) ?: return@withContext Result.failure()
        val destinationPath = inputData.getString(KEY_DESTINATION_PATH)
        
        Timber.tag(TAG).d("Starting download for $contentId from $sourceId with ${imageUrls.size} images")
        
        val notificationId = contentId.hashCode()
        
        try {
            // Initial notification
            updateNotification(notificationId, contentId, 0, imageUrls.size)
            
            downloadImages(contentId, sourceId, imageUrls.toList(), notificationId, destinationPath)
            
            // Completion notification
            updateNotification(notificationId, contentId, imageUrls.size, imageUrls.size, true)
            
            Result.success(workDataOf("downloadedCount" to imageUrls.size))
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            
            Timber.tag(TAG).e(e, "Download failed for $contentId")
            // Show failure notification
            showFailureNotification(notificationId, contentId)
            Result.retry()
        }
    }
    
    private suspend fun downloadImages(
        contentId: String, 
        sourceId: String, 
        imageUrls: List<String>, 
        notificationId: Int,
        destinationPath: String?
    ) {
        val downloadDir = getDownloadDirectory(sourceId, contentId, destinationPath)
        if (!downloadDir.exists() && !downloadDir.mkdirs()) {
            throw IOException("Failed to create directory: ${downloadDir.absolutePath}")
        }
        
        imageUrls.forEachIndexed { index, url ->
            if (isStopped) throw CancellationException("Work cancelled")
            
            val fileName = "${index + 1}.jpg"
            val destFile = File(downloadDir, fileName)
            
            // Skip if already exists (resume capability)
            if (!destFile.exists() || destFile.length() == 0L) {
                downloadImage(url, destFile)
            }
            
            val progress = ((index + 1).toFloat() / imageUrls.size * 100).toInt()
            setProgress(workDataOf(
                KEY_PROGRESS to progress,
                "downloadedCount" to (index + 1),
                "totalCount" to imageUrls.size,
                KEY_CONTENT_ID to contentId
            ))
            
            updateNotification(notificationId, contentId, index + 1, imageUrls.size)
        }
    }
    
    private fun getDownloadDirectory(sourceId: String, contentId: String, destinationPath: String?): File {
        // If destinationPath is provided by Flutter, use it
        if (!destinationPath.isNullOrEmpty()) {
            return File(destinationPath)
        }
        
        // Fallback: /storage/emulated/0/Download/nhasix/{source}/{contentId}
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        return File(downloadsDir, "nhasix${File.separator}$sourceId${File.separator}$contentId")
    }
    
    private fun downloadImage(url: String, destFile: File) {
        val request = Request.Builder().url(url).build()
        
        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IOException("HTTP ${response.code} for URL: $url")
            }
            
            response.body?.byteStream()?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW 
            ).apply {
                description = "Download progress notifications"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun updateNotification(
        notificationId: Int, 
        contentId: String, 
        current: Int, 
        total: Int,
        complete: Boolean = false
    ) {
        val title = if (complete) "Download Complete" else "Downloading $contentId"
        val text = "$current / $total pages"
        
        val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(!complete)
            .setAutoCancel(complete)
        
        if (!complete) {
            builder.setProgress(total, current, false)
        }
        
        notificationManager.notify(notificationId, builder.build())
    }
    
    private fun showFailureNotification(notificationId: Int, contentId: String) {
        val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle("Download Failed")
            .setContentText("Failed to download $contentId. Tap to retry.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            
        notificationManager.notify(notificationId, builder.build())
    }
    
    // ============ Cookie Handling Methods (NEW) ============
    
    /**
     * Parse cookies from JSON string to Map
     * Format: {"cookie1":"value1","cookie2":"value2"}
     */
    private fun parseCookies(cookiesJson: String?): Map<String, String>? {
        if (cookiesJson.isNullOrBlank()) return null
        
        return try {
            // Simple JSON parsing without external library
            val trimmed = cookiesJson.trim().removeSurrounding("{", "}")
            if (trimmed.isEmpty()) return null
            
            trimmed.split(",")
                .mapNotNull { entry ->
                    val parts = entry.split(":")
                    if (parts.size == 2) {
                        val key = parts[0].trim().removeSurrounding("\"")
                        val value = parts[1].trim().removeSurrounding("\"")
                        key to value
                    } else null
                }
                .toMap()
                .also { cookies ->
                    Timber.tag(TAG).d("Parsed ${cookies.size} cookies from JSON")
                }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to parse cookies JSON")
            null
        }
    }
    
    /**
     * Create OkHttpClient with CookieJar for authentication
     * Security: Only allows cookies for crotpedia.com domain
     */
    private fun createHttpClientWithCookies(cookies: Map<String, String>): OkHttpClient {
        val cookieJar = createCookieJar(cookies)
        
        return OkHttpClient.Builder()
            .cookieJar(cookieJar)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val request = chain.request()
                // Security check: Only send cookies to HTTPS crotpedia.com
                if (!isSecureRequest(request.url.toString())) {
                    Timber.tag(TAG).w("Blocking cookies for non-HTTPS or non-crotpedia request: ${request.url}")
                }
                chain.proceed(request)
            }
            .build()
    }
    
    /**
     * Create CookieJar from Map with domain validation
     * Security: Cookies only sent to crotpedia.com
     */
    private fun createCookieJar(cookiesMap: Map<String, String>): okhttp3.CookieJar {
        return object : okhttp3.CookieJar {
            override fun saveFromResponse(url: okhttp3.HttpUrl, cookies: List<okhttp3.Cookie>) {
                // No-op: we don't save cookies from responses
            }
            
            override fun loadForRequest(url: okhttp3.HttpUrl): List<okhttp3.Cookie> {
                // Security: Only return cookies for allowed domain
                if (!url.host.endsWith(ALLOWED_COOKIE_DOMAIN)) {
                    Timber.tag(TAG).d("No cookies for domain: ${url.host}")
                    return emptyList()
                }
                
                // Convert Map to OkHttp Cookie objects
                return cookiesMap.map { (name, value) ->
                    okhttp3.Cookie.Builder()
                        .name(name)
                        .value(value)
                        .domain(url.host)
                        .path("/")
                        .build()
                }.also { cookieList ->
                    Timber.tag(TAG).d("Loaded ${cookieList.size} cookies for ${url.host}")
                }
            }
        }
    }
    
    /**
     * Security check: Ensure request is HTTPS and to crotpedia.com
     */
    private fun isSecureRequest(url: String): Boolean {
        return url.startsWith("https://") && url.contains(ALLOWED_COOKIE_DOMAIN)
    }
}
