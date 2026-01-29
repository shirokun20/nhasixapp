package id.nhasix.kuron_native.kuron_native.download

import android.content.Context
import android.util.Log
import androidx.work.WorkInfo
import androidx.work.WorkManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.File

/**
 * Download Method Handler for kuron_native plugin
 * Handles WorkManager-based downloads with metadata v2.1 support
 */
class DownloadHandler(
    private val context: Context,
    private val eventChannel: EventChannel
) {
    private val downloadManager = NativeDownloadManager(context)
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var progressJob: Job? = null

    companion object {
        private const val TAG = "DownloadHandler"
    }

    init {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "EventChannel: Flutter started listening to download progress")
                eventSink = events
                startObservingProgress()
            }
            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "EventChannel: Flutter stopped listening to download progress")
                eventSink = null
                stopObservingProgress()
            }
        })
    }

    private fun startObservingProgress() {
        Log.d(TAG, "startObservingProgress: Starting to observe WorkManager flow for tag 'native_download'")
        progressJob?.cancel()
        progressJob = scope.launch {
            WorkManager.getInstance(context)
                .getWorkInfosByTagFlow("native_download")
                .collect { workInfos ->
                    Log.d(TAG, "WorkManager flow: Received ${workInfos.size} work items")
                    for (workInfo in workInfos) {
                        val progress = workInfo.progress
                        val contentId = progress.getString("content_id") ?: 
                                        workInfo.outputData.getString("content_id")
                        
                        if (contentId != null) {
                            val state = when (workInfo.state) {
                                WorkInfo.State.RUNNING -> "RUNNING"
                                WorkInfo.State.SUCCEEDED -> "COMPLETED"
                                WorkInfo.State.FAILED -> "FAILED"
                                else -> "PENDING"
                            }
                            
                            val src = if (workInfo.state == WorkInfo.State.SUCCEEDED) workInfo.outputData else progress
                            val downloaded = src.getInt("downloadedCount", 0)
                            val total = src.getInt("totalCount", 0)
                            
                            Log.d(TAG, "Processing: contentId=$contentId state=$state downloaded=$downloaded total=$total")
                            
                            if (total > 0 || state == "COMPLETED") {
                                val data = mapOf(
                                    "contentId" to contentId,
                                    "downloadedPages" to downloaded,
                                    "totalPages" to total,
                                    "status" to state
                                )
                                if (eventSink != null) {
                                    eventSink?.success(data)
                                    Log.d(TAG, "EventChannel: Sent progress to Flutter: $data")
                                } else {
                                    Log.w(TAG, "EventChannel: eventSink is null, cannot send progress data")
                                }
                            } else {
                                Log.d(TAG, "Skipping event emission: total=$total state=$state")
                            }
                        } else {
                            Log.w(TAG, "WorkInfo has no content_id, skipping")
                        }
                    }
                }
        }
    }

    private fun stopObservingProgress() {
        progressJob?.cancel()
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "kuronNativeStartDownload" -> handleStartDownload(call, result)
            "kuronNativeCancelDownload" -> handleCancelDownload(call, result)
            "kuronNativePauseDownload" -> handlePauseDownload(call, result)
            "kuronNativeGetDownloadStatus" -> handleGetDownloadStatus(call, result)
            "kuronNativeGetDownloadedFiles" -> handleGetDownloadedFiles(call, result)
            "kuronNativeGetDownloadPath" -> handleGetDownloadPath(call, result)
            "kuronNativeDeleteDownloadedContent" -> handleDeleteDownloadedContent(call, result)
            "kuronNativeCountDownloadedFiles" -> handleCountDownloadedFiles(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleStartDownload(call: MethodCall, result: MethodChannel.Result) {
        try {
            val contentId = call.argument<String>("contentId")
                ?: throw IllegalArgumentException("contentId is required")
            val sourceId = call.argument<String>("sourceId") ?: "unknown"
            val imageUrls = call.argument<List<String>>("imageUrls")
                ?: throw IllegalArgumentException("imageUrls is required")
            val destinationPath = call.argument<String>("destinationPath")
                ?: throw IllegalArgumentException("destinationPath is required")
            
            @Suppress("UNCHECKED_CAST")
            val cookies = call.argument<Map<String, String>>("cookies")
            
            // Extract metadata for v2.1
            val title = call.argument<String>("title") ?: "Unknown"
            val url = call.argument<String>("url") ?: ""
            val coverUrl = call.argument<String>("coverUrl") ?: ""
            val language = call.argument<String>("language") ?: "unknown"
            val enableNotifications = call.argument<Boolean>("enableNotifications") ?: true

            val workId = downloadManager.queueDownload(
                contentId, 
                sourceId, 
                imageUrls, 
                destinationPath,
                cookies,
                title,
                url,
                coverUrl,
                language,
                enableNotifications // NEW
            )
            result.success(workId)
        } catch (e: Exception) {
            result.error("DOWNLOAD_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun handleGetDownloadStatus(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }
        
        scope.launch(Dispatchers.IO) {
            val status = downloadManager.getDownloadStatus(contentId)
            launch(Dispatchers.Main) {
                result.success(status)
            }
        }
    }

    private fun handleCancelDownload(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }
        downloadManager.cancelDownload(contentId)
        result.success(null)
    }

    private fun handlePauseDownload(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }
        downloadManager.pauseDownload(contentId)
        result.success(null)
    }

    private fun handleGetDownloadedFiles(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }

        scope.launch(Dispatchers.IO) {
            try {
                val files = getDownloadedFilesList(contentId)
                launch(Dispatchers.Main) {
                    result.success(files)
                }
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    result.error("GET_FILES_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleGetDownloadPath(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }

        scope.launch(Dispatchers.IO) {
            try {
                val path = getDownloadPathForContent(contentId)
                launch(Dispatchers.Main) {
                    result.success(path)
                }
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    result.error("GET_PATH_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleDeleteDownloadedContent(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }

        scope.launch(Dispatchers.IO) {
            try {
                deleteContent(contentId)
                launch(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    result.error("DELETE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleCountDownloadedFiles(call: MethodCall, result: MethodChannel.Result) {
        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGUMENT", "contentId required", null)
            return
        }

        scope.launch(Dispatchers.IO) {
            try {
                val count = countFiles(contentId)
                launch(Dispatchers.Main) {
                    result.success(count)
                }
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    result.error("COUNT_ERROR", e.message, null)
                }
            }
        }
    }

    // Helper Methods
    private fun getDownloadedFilesList(contentId: String): List<String> {
        val dir = getDownloadPathForContent(contentId) ?: return emptyList()
        val imagesDir = File(dir, "images")
        if (!imagesDir.exists()) return emptyList()

        return imagesDir.listFiles()?.filter { it.isFile && it.extension == "jpg" }
            ?.sortedBy { it.name }
            ?.map { it.absolutePath }
            ?: emptyList()
    }

    private fun getDownloadPathForContent(contentId: String): String? {
        val candidates = mutableListOf<File>()

        // 1. Check Custom Storage Paths
        getCustomStoragePath()?.let { 
            candidates.add(File(it))
        }

        // 2. Check Public External Storage
        val publicDownloads = android.os.Environment.getExternalStoragePublicDirectory(
            android.os.Environment.DIRECTORY_DOWNLOADS
        )
        candidates.add(publicDownloads)

        Log.d(TAG, "Searching for contentId: $contentId in candidates: ${candidates.map { it.absolutePath }}")

        // Iterate candidates to find the content
        for (baseDir in candidates) {
            if (!baseDir.exists()) continue

            // Strategy A: Check "nhasix" subdirectory structure (Standard)
            // Structure: [Base]/nhasix/[SourceId]/[ContentId]
            val nhasixDir = File(baseDir, "nhasix")
            if (nhasixDir.exists()) {
                nhasixDir.listFiles()?.forEach { sourceDir ->
                    if (sourceDir.isDirectory) {
                        val contentDir = File(sourceDir, contentId)
                        if (contentDir.exists()) {
                            Log.d(TAG, "Found content at: ${contentDir.absolutePath}")
                            return contentDir.absolutePath
                        }
                    }
                }
                
                // Also check direct nhasix/[ContentId] (Legacy)
                val directNhasix = File(nhasixDir, contentId)
                if (directNhasix.exists()) {
                     Log.d(TAG, "Found content at (legacy nhasix): ${directNhasix.absolutePath}")
                     return directNhasix.absolutePath
                }
            }

            // Strategy B Check direct matches
            // Structure: [Base]/[ContentId] (Unlikely but possible legacy)
            val directFile = File(baseDir, contentId)
            if (directFile.exists()) {
                Log.d(TAG, "Found content at (direct): ${directFile.absolutePath}")
                return directFile.absolutePath
            }
        }
        
        Log.w(TAG, "ContentId $contentId NOT FOUND in any storage locations.")
        return null
    }

    private fun getCustomStoragePath(): String? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Key match: Dart uses 'custom_storage_root', which becomes 'flutter.custom_storage_root'
        val path = prefs.getString("flutter.custom_storage_root", null)
        Log.d(TAG, "getCustomStoragePath: $path")
        return path
    }

    private fun deleteContent(contentId: String) {
        val path = getDownloadPathForContent(contentId)
        if (path == null) {
            Log.e(TAG, "deleteContent: Path not found for $contentId")
            return
        }
        
        Log.d(TAG, "Deleting content at: $path")
        val dir = File(path)
        
        // Try deleting everything recursively
        try {
            val deleted = dir.deleteRecursively()
            Log.d(TAG, "deleteContent: result=$deleted for $path")
        } catch (e: Exception) {
             Log.e(TAG, "deleteContent: Exception deleting $path: ${e.message}")
        }
        
        // If dir still exists, try manual cleanup
        if (dir.exists()) {
             Log.w(TAG, "deleteContent: Directory still exists, trying manual cleanup")
             val imagesDir = File(dir, "images")
             if (imagesDir.exists()) imagesDir.deleteRecursively()
             File(dir, "metadata.json").delete()
             File(dir, ".nomedia").delete()
             dir.delete()
        }
    }

    private fun countFiles(contentId: String): Int {
        val files = getDownloadedFilesList(contentId)
        return files.size
    }

    fun dispose() {
        eventChannel.setStreamHandler(null)
        stopObservingProgress()
    }
}
