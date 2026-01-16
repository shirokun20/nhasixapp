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

class DownloadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val KEY_CONTENT_ID = "content_id"
        const val KEY_SOURCE_ID = "source_id"
        const val KEY_IMAGE_URLS = "image_urls"
        const val KEY_DESTINATION_PATH = "destination_path"
        const val KEY_PROGRESS = "progress"
        
        private const val TAG = "DownloadWorker"
        private const val CHANNEL_ID = "download_channel"
        private const val CHANNEL_NAME = "Downloads"
    }
    
    private val notificationManager by lazy {
        applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }
    
    private val okHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
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
}
