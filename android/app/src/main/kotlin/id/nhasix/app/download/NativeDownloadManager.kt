package id.nhasix.app.download

import android.content.Context
import androidx.work.Constraints
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.workDataOf
import kotlinx.coroutines.runBlocking
import java.util.concurrent.TimeUnit

class NativeDownloadManager(private val context: Context) {
    
    fun queueDownload(
        contentId: String,
        sourceId: String,
        imageUrls: List<String>,
        destinationPath: String,
        cookies: Map<String, String>? = null  // NEW: Optional cookies for authentication
    ): String {
        // NEW: Convert cookies Map to JSON string for WorkManager Data
        val cookiesJson = cookies?.let { map ->
            map.entries.joinToString(",", "{", "}") { (key, value) ->
                "\"$key\":\"$value\""
            }
        }
        
        val workRequest = OneTimeWorkRequestBuilder<DownloadWorker>()
            .setInputData(workDataOf(
                DownloadWorker.KEY_CONTENT_ID to contentId,
                DownloadWorker.KEY_SOURCE_ID to sourceId,
                DownloadWorker.KEY_IMAGE_URLS to imageUrls.toTypedArray(),
                DownloadWorker.KEY_DESTINATION_PATH to destinationPath,
                DownloadWorker.KEY_COOKIES to cookiesJson  // NEW: Pass cookies as JSON
            ))
            .setConstraints(Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build())
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .addTag("content_$contentId")
            .addTag("native_download")
            .build()
        
        WorkManager.getInstance(context).enqueue(workRequest)
        return workRequest.id.toString()
    }

    fun cancelDownload(contentId: String) {
        WorkManager.getInstance(context).cancelAllWorkByTag("content_$contentId")
    }

    fun pauseDownload(contentId: String) {
        // For WorkManager, pausing is effectively cancelling.
        // Resume will re-queue and the worker skips existing files.
        cancelDownload(contentId)
    }

    fun getDownloadStatus(contentId: String): Map<String, Any?>? {
        return try {
            // Use get() with timeout to avoid blocking indefinitely
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosByTag("content_$contentId")
                .get(1, TimeUnit.SECONDS)
            
            val workInfo = workInfos.firstOrNull() ?: return null
            
            val state = when (workInfo.state) {
                androidx.work.WorkInfo.State.RUNNING -> "RUNNING"
                androidx.work.WorkInfo.State.SUCCEEDED -> "COMPLETED"
                androidx.work.WorkInfo.State.FAILED -> "FAILED"
                androidx.work.WorkInfo.State.ENQUEUED -> "PENDING"
                androidx.work.WorkInfo.State.BLOCKED -> "PENDING"
                androidx.work.WorkInfo.State.CANCELLED -> "CANCELLED"
            }
            
            val progress = workInfo.progress
            val downloaded = progress.getInt("downloadedCount", 0)
            val total = progress.getInt("totalCount", 0)
            
            mapOf(
                "status" to state,
                "downloadedPages" to downloaded,
                "totalPages" to total,
                "contentId" to contentId
            )
        } catch (e: Exception) {
            null
        }
    }
}
