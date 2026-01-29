package id.nhasix.kuron_native.kuron_native.download

import android.content.Context
import androidx.work.Constraints
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

class NativeDownloadManager(private val context: Context) {
    
    fun queueDownload(
        contentId: String,
        sourceId: String,
        imageUrls: List<String>,
        destinationPath: String,
        cookies: Map<String, String>? = null,  // Optional cookies for authentication
        // Metadata for v2.1
        title: String = "Unknown",
        url: String = "",
        coverUrl: String = "",
        language: String = "unknown"
    ): String {
        // Convert cookies Map to JSON string for WorkManager Data
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
                DownloadWorker.KEY_COOKIES to cookiesJson,
                // Pass metadata
                DownloadWorker.KEY_TITLE to title,
                DownloadWorker.KEY_URL to url,
                DownloadWorker.KEY_COVER_URL to coverUrl,
                DownloadWorker.KEY_LANGUAGE to language
            ))
            .setConstraints(Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build())
            .addTag("content_$contentId")
            .addTag("native_download")
            .build()
        
        // CRITICAL: Explicitly cancel any old work with this tag (including anonymous work from previous versions)
        // enqueueUniqueWork only handles work with the same UNIQUE NAME, not just the same tag.
        WorkManager.getInstance(context).cancelAllWorkByTag("content_$contentId")
        WorkManager.getInstance(context).pruneWork() // Clean up cancelled/finished work
        
        // Use enqueueUniqueWork with REPLACE policy to ensure new download starts fresh
        WorkManager.getInstance(context).enqueueUniqueWork(
            "content_$contentId",
            androidx.work.ExistingWorkPolicy.REPLACE,
            workRequest
        )
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
            
            // Priority: RUNNING > ENQUEUED > SUCCEEDED > FAILED > CANCELLED
            val workInfo = workInfos.firstOrNull { it.state == androidx.work.WorkInfo.State.RUNNING }
                ?: workInfos.firstOrNull { it.state == androidx.work.WorkInfo.State.ENQUEUED }
                ?: workInfos.firstOrNull { it.state == androidx.work.WorkInfo.State.SUCCEEDED }
                ?: workInfos.firstOrNull { it.state == androidx.work.WorkInfo.State.FAILED }
                ?: workInfos.firstOrNull() ?: return null
            
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
