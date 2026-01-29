package id.nhasix.kuron_native.kuron_native.download

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.work.ForegroundInfo
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import android.content.pm.ServiceInfo
import id.nhasix.kuron_native.kuron_native.R
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import android.util.Log
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

class DownloadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val KEY_CONTENT_ID = "content_id"
        const val KEY_SOURCE_ID = "source_id"
        const val KEY_IMAGE_URLS = "image_urls"
        const val KEY_DESTINATION_PATH = "destination_path"
        const val KEY_COOKIES = "cookies"  // Cookies as JSON string
        // Metadata fields for v2.1
        const val KEY_TITLE = "title"
        const val KEY_URL = "url"
        const val KEY_COVER_URL = "cover_url"
        const val KEY_LANGUAGE = "language"
        const val KEY_PROGRESS = "progress"
        const val KEY_ENABLE_NOTIFICATIONS = "enableNotifications" // NEW (Ignored now)
        
        private const val TAG = "DownloadWorker"
        private const val ALLOWED_COOKIE_DOMAIN = "crotpedia.com"  // Security - only allow crotpedia.com
    }
    
    // Parse cookies from inputData and create HTTP client with authentication
    private val okHttpClient by lazy {
        val cookiesJson = inputData.getString(KEY_COOKIES)
        val cookies = parseCookies(cookiesJson)
        
        val builder = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
        
        if (cookies != null && cookies.isNotEmpty()) {
            Log.d(TAG, "Creating HTTP client with ${cookies.size} cookies for authentication")
            builder.cookieJar(createCookieJar(cookies))
        }
        
        builder.build()
    }

    override suspend fun doWork(): ListenableWorker.Result = withContext(Dispatchers.IO) {
        val contentId = inputData.getString(KEY_CONTENT_ID) ?: return@withContext Result.failure()
        val sourceId = inputData.getString(KEY_SOURCE_ID) ?: "unknown"
        val imageUrls = inputData.getStringArray(KEY_IMAGE_URLS) ?: return@withContext Result.failure()
        val destinationPath = inputData.getString(KEY_DESTINATION_PATH)
        
        Log.d(TAG, "Starting download for $contentId from $sourceId with ${imageUrls.size} images (Native Notifications Disabled)")
        
        try {
            val downloadDir = getDownloadDirectory(sourceId, contentId, destinationPath)
            downloadImages(contentId, sourceId, imageUrls.toList(), destinationPath)
            
            // Create metadata and .nomedia after successful download
            val title = inputData.getString(KEY_TITLE) ?: "Unknown"
            val url = inputData.getString(KEY_URL) ?: ""
            val coverUrl = inputData.getString(KEY_COVER_URL) ?: ""
            val language = inputData.getString(KEY_LANGUAGE) ?: "unknown"
            val downloadedFiles = imageUrls.toList()
            
            createMetadataFile(
                downloadDir, 
                contentId, 
                sourceId, 
                title,
                url,
                coverUrl,
                language,
                downloadedFiles
            )
            createNoMediaFile(downloadDir)
            
            Log.d(TAG, "Download complete for $contentId.")
            
            // Return success with complete data for EventChannel emission
            Result.success(workDataOf(
                "content_id" to contentId,
                "downloadedCount" to imageUrls.size,
                "totalCount" to imageUrls.size
            ))
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            
            Log.e(TAG, "Download failed for $contentId", e)
            Result.retry()
        }
    }
    
    private suspend fun downloadImages(
        contentId: String, 
        sourceId: String, 
        imageUrls: List<String>, 
        destinationPath: String?
    ) {
        val downloadDir = getDownloadDirectory(sourceId, contentId, destinationPath)
        // Create /images/ subfolder to match Flutter pattern
        val imagesDir = File(downloadDir, "images")
        
        Log.d(TAG, "Target Download Dir: ${downloadDir.absolutePath}")
        Log.d(TAG, "Target Images Dir: ${imagesDir.absolutePath}")
        
        if (!imagesDir.exists()) {
            val created = imagesDir.mkdirs()
            Log.d(TAG, "Created Images Dir: $created")
            if (!created) {
                // Try creating one by one for debugging
                Log.e(TAG, "Failed to create dir! Checking parent: ${downloadDir.exists()}")
                throw IOException("Failed to create directory: ${imagesDir.absolutePath}")
            }
        } else {
             Log.d(TAG, "Images Dir already exists")
        }
        
        imageUrls.forEachIndexed { index, url ->
            if (isStopped) throw CancellationException("Work cancelled")
            
            // Use page_001.jpg format to match Flutter pattern
            val pageNumber = index + 1
            val fileName = "page_${pageNumber.toString().padStart(3, '0')}.jpg"
            val destFile = File(imagesDir, fileName)
            
            // Skip if already exists (resume capability)
            if (!destFile.exists() || destFile.length() == 0L) {
                if (index == 0) Log.d(TAG, "Downloading first file to: ${destFile.absolutePath}")
                downloadImage(url, destFile)
                if (index == 0 && destFile.exists()) Log.d(TAG, "First file created successfully: size=${destFile.length()}")
            } else {
                 if (index == 0) Log.d(TAG, "Skipping first file (already exists): ${destFile.absolutePath}")
            }
            
            val progress = ((index + 1).toFloat() / imageUrls.size * 100).toInt()
            setProgress(workDataOf(
                KEY_PROGRESS to progress,
                "downloadedCount" to (index + 1),
                "totalCount" to imageUrls.size,
                KEY_CONTENT_ID to contentId
            ))
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
    
    // ============ Cookie Handling Methods ============
    
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
                    Log.d(TAG, "Parsed ${cookies.size} cookies from JSON")
                }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse cookies JSON", e)
            null
        }
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
                    Log.d(TAG, "No cookies for domain: ${url.host}")
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
                    Log.d(TAG, "Loaded ${cookieList.size} cookies for ${url.host}")
                }
            }
        }
    }

    // ============ Metadata & Privacy Methods ============

    /**
     * Create metadata.json file with download information
     * Schema v2.1 - Matches DownloadService format for full compatibility
     * Uses snake_case keys to match Dart implementation
     */
    private fun createMetadataFile(
        downloadDir: File,
        contentId: String,
        sourceId: String,
        title: String,
        url: String,
        coverUrl: String,
        language: String,
        imageFiles: List<String>
    ) {
        try {
            // Generate file list (basenames only)
            val files = imageFiles.mapIndexed { index, _ ->
                "page_${(index + 1).toString().padStart(3, '0')}.jpg"
            }
            
            val metadata = mapOf(
                "schemaVersion" to "2.1",
                "source" to sourceId,
                "content_id" to contentId,
                "title" to title,
                "url" to url,
                "download_date" to java.text.SimpleDateFormat(
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                    java.util.Locale.US
                ).apply {
                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                }.format(java.util.Date()),
                "total_pages" to imageFiles.size,
                "downloaded_files" to imageFiles.size,
                "files" to files,
                "language" to language,
                "cover_url" to coverUrl,
                "is_range_download" to false,
                "start_page" to 1,
                "end_page" to imageFiles.size,
                "pages_downloaded" to imageFiles.size
            )
            
            val metadataFile = File(downloadDir, "metadata.json")
            metadataFile.writeText(org.json.JSONObject(metadata).toString(2))
            Log.d(TAG, "Created v2.1 metadata file for $contentId")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to create metadata file", e)
            // Non-critical, don't fail download
        }
    }

    /**
     * Create .nomedia file to hide images from Android Gallery/Photos apps
     * Privacy protection - prevents downloaded content from appearing in media apps
     */
    private fun createNoMediaFile(directory: File) {
        try {
            val noMediaFile = File(directory, ".nomedia")
            if (!noMediaFile.exists()) {
                noMediaFile.createNewFile()
                Log.d(TAG, "Created .nomedia file in ${directory.name}")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to create .nomedia file", e)
            // Non-critical, don't fail download
        }
    }
}
