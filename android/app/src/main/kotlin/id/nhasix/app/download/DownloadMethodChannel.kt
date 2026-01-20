package id.nhasix.app.download

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

import androidx.work.WorkInfo
import androidx.work.WorkManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class DownloadMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger
) {
    companion object {
        private const val CHANNEL_NAME = "id.nhasix.app/download"
        private const val EVENT_CHANNEL_NAME = "id.nhasix.app/download_progress"
    }

    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME)
    private val downloadManager = NativeDownloadManager(context)
    
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var progressJob: Job? = null

    init {
        methodChannel.setMethodCallHandler(::onMethodCall)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startObservingProgress()
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                stopObservingProgress()
            }
        })
    }

    private fun startObservingProgress() {
        progressJob?.cancel()
        progressJob = scope.launch {
            WorkManager.getInstance(context)
                .getWorkInfosByTagFlow("native_download")
                .collect { workInfos ->
                    for (workInfo in workInfos) {
                        val progress = workInfo.progress
                        val contentId = progress.getString("contentId") ?: 
                                        workInfo.outputData.getString("contentId") // Check output too
                        
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
                            
                            // Only emit if we have valid data or checks
                            if (total > 0 || state == "COMPLETED") {
                                val data = mapOf(
                                    "contentId" to contentId,
                                    "downloadedPages" to downloaded,
                                    "totalPages" to total,
                                    "status" to state
                                )
                                eventSink?.success(data)
                            }
                        }
                    }
                }
        }
    }

    private fun stopObservingProgress() {
        progressJob?.cancel()
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDownload" -> handleStartDownload(call, result)
            "cancelDownload" -> handleCancelDownload(call, result)
            "pauseDownload" -> handlePauseDownload(call, result)
            "getDownloadStatus" -> handleGetStatus(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetStatus(call: MethodCall, result: MethodChannel.Result) {
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

    private fun handleStartDownload(call: MethodCall, result: MethodChannel.Result) {
        try {
            val contentId = call.argument<String>("contentId")
                ?: throw IllegalArgumentException("contentId is required")
            val sourceId = call.argument<String>("sourceId") ?: "unknown"
            val imageUrls = call.argument<List<String>>("imageUrls")
                ?: throw IllegalArgumentException("imageUrls is required")
            val destinationPath = call.argument<String>("destinationPath")
                ?: throw IllegalArgumentException("destinationPath is required")
            
            // NEW: Extract cookies (optional, for authentication)
            @Suppress("UNCHECKED_CAST")
            val cookies = call.argument<Map<String, String>>("cookies")

            val workId = downloadManager.queueDownload(
                contentId, 
                sourceId, 
                imageUrls, 
                destinationPath,
                cookies  // NEW: Pass cookies to download manager
            )
            result.success(workId)
        } catch (e: Exception) {
            result.error("DOWNLOAD_ERROR", e.message, e.stackTraceToString())
        }
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
