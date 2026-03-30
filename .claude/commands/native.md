# Native Android Integration

Guide for integrating native Android (Kotlin) code with Flutter using Platform Channels.

Used for: download, PDF generation, backup features.

## Architecture

```
Flutter (Dart)          Platform Channel          Native (Kotlin)
  invokeMethod() ──────────────────────────────> Call native function
  Future completes <──────────────────────────── Return result
  Stream events <───── EventChannel ──────────── Progress updates
```

## Channels Used in Kuron

| Channel | Type | Purpose |
|---------|------|---------|
| `id.nhasix.app/download` | MethodChannel | Download control |
| `id.nhasix.app/download_progress` | EventChannel | Progress streaming |
| `id.nhasix.app/pdf` | MethodChannel | PDF generation |
| `id.nhasix.app/pdf_progress` | EventChannel | PDF progress |
| `id.nhasix.app/backup` | MethodChannel | Backup/restore |

## Flutter Side — BaseNativeService

```dart
class BaseNativeService {
  final MethodChannel _channel;
  BaseNativeService(String channelName) : _channel = MethodChannel(channelName);

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      Logger().e('Platform error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
```

## Kotlin Side — MethodChannel Handler

```kotlin
class DownloadMethodChannel(private val context: Context, messenger: BinaryMessenger) {
    private val methodChannel = MethodChannel(messenger, "id.nhasix.app/download")

    init { methodChannel.setMethodCallHandler(::onMethodCall) }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDownload" -> handleStartDownload(call, result)
            else -> result.notImplemented()
        }
    }
}
```

## WorkManager for Background Tasks

Use `CoroutineWorker` + `WorkManager` for downloads/heavy tasks.
Report progress via `setProgress()` + EventChannel.

## Performance Tips
- **Batch operations**: Single channel call for multiple items, not a loop
- **Background threads**: Use `Dispatchers.IO` for heavy work, return on `Dispatchers.Main`
- **Minimize serialization**: Pass file paths, not raw bytes

## Security
- Validate all URLs (HTTPS only)
- Handle permissions (Android 13+ vs older)

## Checklist for New Native Feature
- [ ] MethodChannel handler in MainActivity
- [ ] Native logic (Manager class)
- [ ] WorkManager Worker (if background)
- [ ] EventChannel for progress (if long-running)
- [ ] Flutter service wrapper
- [ ] Error handling
- [ ] Unit tests (Kotlin)
- [ ] Integration tests (Flutter)
- [ ] Logging/analytics
