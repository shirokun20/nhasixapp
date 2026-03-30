---
name: native-integration
description: Panduan integrasi native Android (Kotlin) dengan Flutter untuk Kuron app, khusus untuk download, PDF, dan backup features
license: MIT
compatibility: opencode
metadata:
  audience: developers
  framework: flutter-android-hybrid
  project: kuron
---

# Native Integration Skill - Kuron App

## 🎯 Purpose

Skill ini memberikan panduan lengkap untuk mengintegrasikan kode native Android (Kotlin) dengan Flutter menggunakan Platform Channels untuk fitur download, PDF generation, dan backup.

## 📋 Prerequisites

- Kotlin knowledge (basic)
- Understanding of Android WorkManager
- Flutter MethodChannel basics
- Coroutines understanding

## 🏗️ Architecture Pattern

### Communication Flow

```
Flutter (Dart)          Platform Channel          Native (Kotlin)
     │                        │                          │
     │   invokeMethod()       │                          │
     ├───────────────────────►│                          │
     │                        │   Call native function   │
     │                        ├─────────────────────────►│
     │                        │                          │
     │                        │   Return result          │
     │                        │◄─────────────────────────┤
     │   Future completes     │                          │
     │◄───────────────────────┤                          │
     │                        │                          │
     │                        │   EventChannel           │
     │   Stream events        │   (for progress)         │
     │◄───────────────────────┼─────────────────────────►│
```

## 🔧 Implementation Steps

### Step 1: Create MethodChannel (Flutter Side)

```dart
// File: lib/services/native/base_native_service.dart
class BaseNativeService {
  final MethodChannel _channel;
  
  BaseNativeService(String channelName)
      : _channel = MethodChannel(channelName);
  
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      rethrow;
    }
  }
  
  void _handlePlatformException(PlatformException e) {
    // Log error, send to analytics
    Logger().e('Platform error: ${e.code} - ${e.message}');
  }
}

// File: lib/services/native/native_download_service.dart
class NativeDownloadService extends BaseNativeService {
  static const String _channelName = 'id.nhasix.app/download';
  
  NativeDownloadService() : super(_channelName);
  
  Future<String> startDownload({
    required String contentId,
    required List<String> imageUrls,
  }) async {
    final result = await invokeMethod<String>('startDownload', {
      'contentId': contentId,
      'imageUrls': imageUrls,
    });
    
    if (result == null) {
      throw NativeException('Failed to start download');
    }
    
    return result;
  }
}
```

### Step 2: Implement Native Handler (Kotlin Side)

```kotlin
// File: android/app/src/main/kotlin/id/nhasix/app/MainActivity.kt
class MainActivity: FlutterActivity() {
    private lateinit var downloadChannel: DownloadMethodChannel
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup download channel
        downloadChannel = DownloadMethodChannel(
            context = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger
        )
    }
    
    override fun onDestroy() {
        downloadChannel.dispose()
        super.onDestroy()
    }
}

// File: android/app/src/main/kotlin/id/nhasix/app/download/DownloadMethodChannel.kt
class DownloadMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger
) {
    companion object {
        private const val CHANNEL_NAME = "id.nhasix.app/download"
    }
    
    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
    private val downloadManager = NativeDownloadManager(context)
    
    init {
        methodChannel.setMethodCallHandler(::onMethodCall)
    }
    
    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDownload" -> handleStartDownload(call, result)
            "pauseDownload" -> handlePauseDownload(call, result)
            "cancelDownload" -> handleCancelDownload(call, result)
            else -> result.notImplemented()
        }
    }
    
    private fun handleStartDownload(call: MethodCall, result: MethodChannel.Result) {
        try {
            val contentId = call.argument<String>("contentId")
                ?: throw IllegalArgumentException("contentId is required")
            val imageUrls = call.argument<List<String>>("imageUrls")
                ?: throw IllegalArgumentException("imageUrls is required")
            
            val workId = downloadManager.queueDownload(contentId, imageUrls)
            result.success(workId)
        } catch (e: Exception) {
            result.error("DOWNLOAD_ERROR", e.message, e.stackTraceToString())
        }
    }
    
    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }
}
```

### Step 3: Implement WorkManager Worker

```kotlin
// File: android/app/src/main/kotlin/id/nhasix/app/download/DownloadWorker.kt
class DownloadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    companion object {
        private const val TAG = "DownloadWorker"
        const val KEY_CONTENT_ID = "contentId"
        const val KEY_IMAGE_URLS = "imageUrls"
        const val KEY_PROGRESS = "progress"
    }
    
    private val notificationManager = NotificationManagerCompat.from(context)
    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
    
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val contentId = inputData.getString(KEY_CONTENT_ID)
            ?: return@withContext Result.failure()
        val imageUrls = inputData.getStringArray(KEY_IMAGE_URLS)?.toList()
            ?: return@withContext Result.failure()
        
        Timber.tag(TAG).d("Starting download for $contentId with ${imageUrls.size} images")
        
        try {
            downloadImages(contentId, imageUrls)
            Result.success()
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Download failed for $contentId")
            Result.retry()
        }
    }
    
    private suspend fun downloadImages(contentId: String, imageUrls: List<String>) {
        val downloadDir = getDownloadDirectory(contentId)
        downloadDir.mkdirs()
        
        imageUrls.forEachIndexed { index, url ->
            if (isStopped) throw CancellationException("Work cancelled")
            
            downloadImage(url, File(downloadDir, "${index + 1}.jpg"))
            
            val progress = ((index + 1).toFloat() / imageUrls.size * 100).toInt()
            setProgress(workDataOf(KEY_PROGRESS to progress))
            updateNotification(contentId, progress)
        }
    }
    
    private suspend fun downloadImage(url: String, destFile: File) {
        val request = Request.Builder().url(url).build()
        
        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IOException("HTTP ${response.code}")
            }
            
            response.body?.byteStream()?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }
    }
    
    private fun updateNotification(contentId: String, progress: Int) {
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle("Downloading $contentId")
            .setProgress(100, progress, false)
            .setSmallIcon(R.drawable.ic_download)
            .build()
        
        notificationManager.notify(contentId.hashCode(), notification)
    }
}
```

### Step 4: Implement EventChannel for Progress Streaming

```dart
// Flutter side
class NativeDownloadService {
  static const EventChannel _progressChannel = 
      EventChannel('id.nhasix.app/download_progress');
  
  Stream<DownloadProgress>? _progressStream;
  
  Stream<DownloadProgress> observeProgress() {
    _progressStream ??= _progressChannel
        .receiveBroadcastStream()
        .map((data) => DownloadProgress.fromMap(data as Map));
    return _progressStream!;
  }
}
```

```kotlin
// Android side
class DownloadMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger
) {
    private val eventChannel = EventChannel(messenger, "id.nhasix.app/download_progress")
    private var eventSink: EventChannel.EventSink? = null
    
    init {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }
    
    fun sendProgress(contentId: String, progress: Int, total: Int) {
        eventSink?.success(mapOf(
            "contentId" to contentId,
            "progress" to progress,
            "total" to total
        ))
    }
}
```

## 🧪 Testing

### Unit Test (Kotlin)

```kotlin
@RunWith(AndroidJUnit4::class)
class DownloadWorkerTest {
    
    @Before
    fun setup() {
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
    }
    
    @Test
    fun testDownloadWorker_success() {
        val inputData = workDataOf(
            DownloadWorker.KEY_CONTENT_ID to "test123",
            DownloadWorker.KEY_IMAGE_URLS to arrayOf("https://test.com/1.jpg")
        )
        
        val request = OneTimeWorkRequestBuilder<DownloadWorker>()
            .setInputData(inputData)
            .build()
        
        val workManager = WorkManager.getInstance(context)
        workManager.enqueue(request).result.get()
        
        val workInfo = workManager.getWorkInfoById(request.id).get()
        assertThat(workInfo.state).isEqualTo(WorkInfo.State.SUCCEEDED)
    }
}
```

### Integration Test (Flutter)

```dart
testWidgets('Native download service starts download', (tester) async {
  final service = NativeDownloadService();
  
  const testContentId = 'test123';
  const testUrls = ['https://test.com/1.jpg', 'https://test.com/2.jpg'];
  
  final workId = await service.startDownload(
    contentId: testContentId,
    imageUrls: testUrls,
  );
  
  expect(workId, isNotEmpty);
  
  // Wait for progress updates
  await expectLater(
    service.observeProgress(),
    emitsInOrder([
      isA<DownloadProgress>().having((p) => p.progress, 'progress', 50),
      isA<DownloadProgress>().having((p) => p.progress, 'progress', 100),
    ]),
  );
});
```

## 🐛 Common Issues & Solutions

### Issue 1: MethodChannel returns null

**Problem**: Method call returns null instead of expected value

**Solution**:
```dart
// ❌ Bad
final result = await _channel.invokeMethod('method');
print(result.length); // Crashes if null

// ✅ Good
final result = await _channel.invokeMethod<String>('method');
if (result == null) {
  throw NativeException('Method returned null');
}
print(result.length); // Safe
```

### Issue 2: PlatformException not caught

**Problem**: Native errors crash the app

**Solution**:
```dart
try {
  await _channel.invokeMethod('riskyMethod');
} on PlatformException catch (e) {
  switch (e.code) {
    case 'PERMISSION_DENIED':
      // Handle permission issue
      break;
    case 'NETWORK_ERROR':
      // Handle network issue
      break;
    default:
      // Handle unknown error
      break;
  }
}
```

### Issue 3: WorkManager not executing

**Problem**: Worker never runs

**Solution**:
```kotlin
// Check constraints
val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.CONNECTED) // ⚠️ Might block execution
    .build()

// For immediate execution, use minimal constraints
val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
    .setRequiresBatteryNotLow(false)
    .build()

// And use expedited
val request = OneTimeWorkRequestBuilder<DownloadWorker>()
    .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
    .build()
```

## 📊 Performance Tips

### 1. Batch Operations

```dart
// ❌ Bad: Multiple channel calls
for (final url in urls) {
  await _channel.invokeMethod('download', url);
}

// ✅ Good: Single batch call
await _channel.invokeMethod('downloadBatch', urls);
```

### 2. Use Computed

```kotlin
// ❌ Bad: Blocking operation on main thread
override fun onMethodCall(call: MethodCall, result: Result) {
    val data = computeHeavyOperation() // Blocks UI thread
    result.success(data)
}

// ✅ Good: Offload to background
override fun onMethodCall(call: MethodCall, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val data = computeHeavyOperation()
            withContext(Dispatchers.Main) {
                result.success(data)
            }
        } catch (e: Exception) {
            withContext(Dispatchers.Main) {
                result.error("ERROR", e.message, null)
            }
        }
    }
}
```

### 3. Minimize Serialization

```dart
// ❌ Bad: Large data through channel
await _channel.invokeMethod('processImage', {
  'imageBytes': largeImageBytes, // 10MB+
});

// ✅ Good: Pass file path
await _channel.invokeMethod('processImage', {
  'imagePath': '/path/to/image.jpg',
});
```

## 🔐 Security Considerations

### 1. Validate Input

```kotlin
private fun handleDownload(call: MethodCall, result: Result) {
    val url = call.argument<String>("url")
    
    // Validate URL
    if (url.isNullOrEmpty() || !url.startsWith("https://")) {
        result.error("INVALID_URL", "URL must be HTTPS", null)
        return
    }
    
    // Proceed with download
}
```

### 2. Handle Permissions

```kotlin
private fun checkPermissions(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        // Android 13+: No storage permission needed for app-specific dirs
        return true
    } else {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }
}
```

## 📚 Reference

### Channels Used in Kuron App

| Channel Name | Type | Purpose |
|--------------|------|---------|
| `id.nhasix.app/download` | MethodChannel | Download control |
| `id.nhasix.app/download_progress` | EventChannel | Progress streaming |
| `id.nhasix.app/pdf` | MethodChannel | PDF generation |
| `id.nhasix.app/pdf_progress` | EventChannel | PDF progress |
| `id.nhasix.app/backup` | MethodChannel | Backup/restore |

### Method Names Convention

```
[verb][Noun]
startDownload, pauseDownload, cancelDownload
generatePdf, deletePdf
createBackup, restoreBackup
```

### Error Codes Convention

```
[CATEGORY]_[SPECIFIC_ERROR]
DOWNLOAD_NETWORK_ERROR
DOWNLOAD_DISK_FULL
PDF_OUT_OF_MEMORY
BACKUP_PERMISSION_DENIED
```

## 🎯 Checklist for New Native Feature

- [ ] Create MethodChannel handler in MainActivity
- [ ] Implement native logic (Manager class)
- [ ] Create WorkManager Worker (if background task)
- [ ] Add EventChannel for progress (if long-running)
- [ ] Create Flutter service wrapper
- [ ] Add error handling
- [ ] Write unit tests (Kotlin)
- [ ] Write integration tests (Flutter)
- [ ] Add logging/analytics
- [ ] Document in ADR
- [ ] Update this skill if needed

## 🔗 Resources

- [Platform Channels Documentation](https://docs.flutter.dev/platform-integration/platform-channels)
- [WorkManager Codelab](https://developer.android.com/codelabs/android-workmanager)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [OkHttp Recipes](https://square.github.io/okhttp/recipes/)
