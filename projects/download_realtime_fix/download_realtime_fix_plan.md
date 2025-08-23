# Download Real-Time Progress Fix Plan

## 🎯 Tujuan
Memperbaiki masalah download progress yang tidak real-time, pause yang tidak berfungsi, dan notification permission yang tidak ada.

## ✅ Checklist Task & Estimasi

- [ ] **Phase 1: Stream-Based Progress Updates (~3 hari)**
  - [ ] Create DownloadManager Service (0.5)
  - [ ] Modify DownloadBloc (1)
  - [ ] Update DownloadContentUseCase (1)
  - [ ] Test real-time progress (0.5)
- [ ] **Phase 2: Improve Cancel/Pause Mechanism (~3)**
  - [ ] Create DownloadTask Class (0.5)
  - [ ] Modify DownloadService (1)
  - [ ] Update DownloadBloc (1)
  - [ ] Test pause/cancel/resume (0.5)
- [ ] **Phase 3: Notification Permission (~1)**
  - [ ] Add permission handling (0.5)
  - [ ] Update NotificationService (0.5)
  - [ ] Test permission scenarios (0.5)
- [ ] **Phase 4: State Management Improvements (~1)**
  - [ ] Flexible state handling in DownloadBloc (0.5)
  - [ ] Test state transitions & error recovery (0.5)
- [ ] **Phase 5: Convert to PDF Feature (~3)**
  - [ ] Add PDF conversion event & handler (0.5)
  - [ ] Implement PdfConversionService (1)
  - [ ] UI actions & notifications (0.5)
  - [ ] Test PDF conversion & splitting (1)
- [ ] **Phase 6: Splash Screen Offline Enhancement (~2)**
  - [ ] Enhanced offline detection in SplashBloc (0.5)
  - [ ] Global offline mode management (0.5)
  - [ ] Offline UI indicators & options (0.5)
  - [ ] Test offline/online transitions (0.5)
- [ ] **Testing & Polish (~2, paralel)**
  - [ ] Unit & integration tests for all features
  - [ ] Manual testing checklist
  - [ ] Performance & edge case testing

**Total Estimasi:** ~13 hari kerja

> Tandai [x] jika sudah selesai, [ ] jika belum. Update estimasi sesuai realisasi.

## 🔍 Analisis Masalah

### 1. Progress Update Tidak Real-Time
**Masalah:**
- Progress hanya update ketika `RefreshIndicator` di-trigger
- Event `DownloadProgressUpdateEvent` tidak dipanggil secara otomatis
- Use case `DownloadContentUseCase` hanya menyimpan progress ke database, tidak emit ke bloc

**Root Cause:**
```dart
// Di DownloadContentUseCase - line 109
onProgress: (progress) async {
  // Hanya save ke database, tidak emit ke bloc
  currentStatus = currentStatus.copyWith(downloadedPages: progress.downloadedPages);
  await _userDataRepository.saveDownloadStatus(currentStatus);
},
```

### 2. Pause/Cancel Tidak Berfungsi
**Masalah:**
- Method `_cancelDownloadTask()` hanya cancel token di bloc
- Download service tetap jalan karena tidak ada mekanisme stop yang proper
- Cancel token tidak properly propagated ke download loop

**Root Cause:**
```dart
// Di DownloadBloc - line 395
void _cancelDownloadTask(String contentId) {
  final cancelToken = _activeCancelTokens[contentId];
  if (cancelToken != null && !cancelToken.isCancelled) {
    cancelToken.cancel('Download cancelled by user');
    _activeCancelTokens.remove(contentId);
  }
}
```

### 3. Notification Permission Tidak Ada
**Masalah:**
- Tidak ada request permission untuk notification
- Notification service initialize tanpa cek permission terlebih dahulu

### 4. State Management Issue
**Masalah:**
- Kondisi `if (state is! DownloadLoaded) return;` terlalu strict
- Bisa block progress update ketika state berubah sementara

## 🛠️ Solusi Arsitektur

### 1. Real-Time Progress dengan Stream
```dart
// Download Manager dengan StreamController
class DownloadManager {
  final StreamController<DownloadProgressUpdate> _progressController = 
      StreamController<DownloadProgressUpdate>.broadcast();
  
  Stream<DownloadProgressUpdate> get progressStream => _progressController.stream;
}
```

### 2. Improved Cancel/Pause Mechanism
```dart
// Download Task dengan proper cancellation
class DownloadTask {
  CancelToken? cancelToken;
  bool isPaused = false;
  bool isCancelled = false;
  
  void pause() => isPaused = true;
  void resume() => isPaused = false;
  void cancel() {
    isCancelled = true;
    cancelToken?.cancel();
  }
}
```

### 3. Notification Permission Handler
```dart
// Permission request sebelum initialize notification
Future<bool> requestNotificationPermission() async {
  final status = await Permission.notification.request();
  return status.isGranted;
}
```

### 4. Robust State Management
```dart
// State management yang lebih flexible
void _onProgressUpdate(event, emit) {
  final currentState = state;
  
  // Handle berbagai state types
  if (currentState is DownloadLoaded) {
    // Update loaded state
  } else if (currentState is DownloadProcessing) {
    // Update processing state
  }
  // Jangan return early, tetap process update
}
```

## 🆕 Convert to PDF Feature

### Requirements
User meminta fitur tambahan untuk convert downloaded images ke PDF dengan spesifikasi:
1. **Menu Convert to PDF** - Muncul di download actions untuk completed downloads
2. **Background Processing** - PDF conversion berjalan di service agar tidak berat  
3. **Custom PDF Folder** - PDF disimpan di `nhasix-generate/pdf/[id_judul_pendek].pdf`
4. **Special Notifications** - Notifikasi berbeda untuk PDF conversion
5. **Clean PDF Layout** - Tanpa nomor halaman, support portrait/landscape dinamis

### PDF Conversion Implementation

#### 1. New Event and Handler
```dart
// lib/presentation/blocs/download/download_event.dart
class DownloadConvertToPdfEvent extends DownloadEvent {
  const DownloadConvertToPdfEvent(this.contentId);
  
  final String contentId;
  
  @override
  List<Object?> get props => [contentId];
}
```

```dart
// lib/presentation/blocs/download/download_bloc.dart  
Future<void> _onConvertToPdf(
  DownloadConvertToPdfEvent event,
  Emitter<DownloadBlocState> emit,
) async {
  final currentState = state;
  if (currentState is! DownloadLoaded) return;

  try {
    final download = currentState.getDownload(event.contentId);
    if (download == null || !download.isCompleted) return;

    // Show start notification
    _notificationService.showPdfConversionStarted(
      contentId: event.contentId,
      title: download.contentId,
    );

    // Start PDF conversion in background
    _convertToPdfInBackground(event.contentId);
    
  } catch (e, stackTrace) {
    _logger.e('Error starting PDF conversion', error: e, stackTrace: stackTrace);
  }
}
```

#### 2. Background PDF Conversion
```dart
// lib/services/pdf_conversion_service.dart (NEW)
class PdfConversionService {
  Future<void> convertToPdfInBackground(String contentId) async {
    try {
      // Get downloaded images
      final imageFiles = await _downloadService.getDownloadedFiles(contentId);
      
      // Create PDF folder: nhasix-generate/pdf/
      final pdfFolder = await _createPdfFolder();
      
      // Get content details for title
      final content = await _getContentDetail(contentId);
      
      // Generate safe filename: [id]_[judul_pendek].pdf
      final fileName = _generatePdfFileName(contentId, content.title);
      final pdfPath = path.join(pdfFolder.path, fileName);
      
      // Convert with progress tracking
      final result = await _pdfService.convertToPdf(
        contentId: contentId,
        title: content.title,
        imagePaths: imageFiles,
        outputPath: pdfPath,
        onProgress: (progress) {
          _notificationService.updatePdfConversionProgress(
            contentId: contentId,
            progress: progress,
            title: content.title,
          );
        },
      );
      
      if (result.success) {
        _notificationService.showPdfConversionCompleted(
          contentId: contentId,
          title: content.title,
          pdfPaths: result.pdfPaths, // Updated to support multiple files
          partsCount: result.partsCount,
        );
      } else {
        _notificationService.showPdfConversionError(
          contentId: contentId,
          title: content.title,
          error: result.error,
        );
      }
    } catch (e) {
      _notificationService.showPdfConversionError(
        contentId: contentId,
        title: contentId,
        error: e.toString(),
      );
    }
  }
}
```

#### 3. UI Changes
```dart
// lib/presentation/widgets/download_item_widget.dart
// Add to _buildMoreActions()
if (download.isCompleted)
  _buildActionTile(
    context,
    icon: Icons.picture_as_pdf,
    title: 'Convert to PDF',
    action: 'convert_pdf',
  ),
```

```dart
// lib/presentation/pages/downloads/downloads_screen.dart
// Add to _handleDownloadAction()
case 'convert_pdf':
  downloadBloc.add(DownloadConvertToPdfEvent(download.contentId));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('PDF conversion started')),
  );
  break;
```

#### 4. Enhanced Notifications
```dart
// lib/services/notification_service.dart
Future<void> showPdfConversionStarted({
  required String contentId,
  required String title,
}) async {
  await _notificationsPlugin.show(
    _generateNotificationId('pdf_start', contentId),
    'Converting to PDF',
    'Converting $title to PDF...',
    _buildPdfNotificationDetails(),
  );
}

Future<void> updatePdfConversionProgress({
  required String contentId,
  required int progress,
  required String title,
}) async {
  await _notificationsPlugin.show(
    _generateNotificationId('pdf_progress', contentId),
    'Converting to PDF ($progress%)',
    'Converting $title to PDF...',
    _buildPdfProgressNotificationDetails(progress),
  );
}

Future<void> showPdfConversionCompleted({
  required String contentId,
  required String title,
  required List<String> pdfPaths, // Updated to support multiple files
  required int partsCount,
}) async {
  final message = partsCount > 1 
      ? '$title converted to $partsCount PDF files'
      : '$title converted to PDF';
      
  await _notificationsPlugin.show(
    _generateNotificationId('pdf_complete', contentId),
    'PDF Created Successfully',
    message,
    _buildPdfCompletedNotificationDetails(pdfPaths.first), // Use first file for action
  );
}
```

## 🌐 Splash Screen Offline Enhancement

### Requirements
User meminta perbaikan untuk splash screen agar tidak stuck saat offline dan memberikan akses ke offline content dengan spesifikasi:
1. **Smart Auto-Continue** - Detect offline content dan auto-continue ke main app
2. **Graceful Fallback** - Show options jika tidak ada offline content
3. **Offline Mode UI** - Clear indicators dan smooth transitions
4. **No User Stuck** - Selalu ada path forward untuk user
5. **Easy Recovery** - Simple way untuk balik online ketika network available

### Current Problem
```dart
// Current strict offline handling - User stuck di splash
if (connectivityResult == ConnectivityResult.none) {
  emit(SplashError(
    message: 'No internet connection. Please check your network and try again.',
    canRetry: true,
  ));
  return; // ❌ Hard stop, tidak ada option offline
}
```

### Enhanced Offline Flow
```
Splash → Check Network → Offline Detected:
├── Check Offline Content Available
├── ✅ HAS Content → Auto-continue to Main App (Offline Mode)
└── ❌ NO Content → Show Offline Options (Retry/Continue/Exit)
```

### Implementation

#### 1. Enhanced Splash States
```dart
// lib/presentation/blocs/splash/splash_state.dart - Add new states
class SplashOfflineDetected extends SplashState {
  const SplashOfflineDetected({required this.message});
  final String message;
}

class SplashOfflineReady extends SplashState {
  const SplashOfflineReady({
    required this.message,
    required this.offlineContentCount,
  });
  final String message;
  final int offlineContentCount;
}

class SplashOfflineEmpty extends SplashState {
  const SplashOfflineEmpty({required this.message});
  final String message;
}

class SplashOfflineMode extends SplashState {
  const SplashOfflineMode({
    required this.message,
    required this.canRetryOnline,
  });
  final String message;
  final bool canRetryOnline;
}
```

#### 2. Enhanced Splash Events
```dart
// lib/presentation/blocs/splash/splash_event.dart - Add new events
class SplashForceOfflineModeEvent extends SplashEvent {}

class SplashCheckOfflineContentEvent extends SplashEvent {}
```

#### 3. Smart Offline Handling Logic
```dart
// lib/presentation/blocs/splash/splash_bloc.dart - Enhanced offline logic
Future<void> _handleOfflineMode(Emitter<SplashState> emit) async {
  emit(SplashOfflineDetected(message: 'No internet connection. Checking offline content...'));
  
  try {
    // Check if offline content is available
    final offlineContentIds = await _offlineContentManager.getOfflineContentIds();
    final hasOfflineContent = offlineContentIds.isNotEmpty;
    
    if (hasOfflineContent) {
      // ✅ Auto-continue to main app with offline mode
      emit(SplashOfflineReady(
        message: 'Continuing with ${offlineContentIds.length} offline items',
        offlineContentCount: offlineContentIds.length,
      ));
      
      // Enable global offline mode
      AppStateManager().enableOfflineMode();
      
      // Auto-navigate to main after brief delay
      await Future.delayed(Duration(seconds: 1));
      emit(SplashSuccess(message: 'Ready (Offline Mode)'));
      
    } else {
      // ❌ No offline content - show options
      emit(SplashOfflineEmpty(message: 'No internet connection and no offline content available.'));
    }
    
  } catch (e, stackTrace) {
    _logger.e('Error checking offline content', error: e, stackTrace: stackTrace);
    emit(SplashOfflineEmpty(message: 'Unable to access offline content.'));
  }
}

Future<void> _onForceOfflineMode(
  SplashForceOfflineModeEvent event,
  Emitter<SplashState> emit,
) async {
  // Force continue to main app even without content
  AppStateManager().enableOfflineMode();
  emit(SplashSuccess(message: 'Offline Mode (Limited Features)'));
}
```

#### 4. Global Offline Mode Manager
```dart
// lib/core/utils/app_state_manager.dart (NEW)
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();
  
  bool _isOfflineMode = false;
  StreamController<bool> _offlineModeController = StreamController<bool>.broadcast();
  
  bool get isOfflineMode => _isOfflineMode;
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  
  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    _offlineModeController.add(offline);
  }
  
  void enableOfflineMode() => setOfflineMode(true);
  void enableOnlineMode() => setOfflineMode(false);
  
  void dispose() {
    _offlineModeController.close();
  }
}
```

#### 5. Enhanced Splash UI
```dart
// lib/presentation/pages/splash/splash_page.dart - Enhanced UI
Widget _buildOfflineOptions(SplashState state) {
  if (state is SplashOfflineReady) {
    return Column(
      children: [
        Icon(Icons.offline_bolt, size: 48, color: Colors.green),
        SizedBox(height: 16),
        Text('Offline Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(state.message, textAlign: TextAlign.center),
        SizedBox(height: 16),
        CircularProgressIndicator(),
      ],
    );
  }
  
  if (state is SplashOfflineEmpty) {
    return Column(
      children: [
        Icon(Icons.cloud_off, size: 48, color: Colors.orange),
        SizedBox(height: 16),
        Text('No Internet Connection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(state.message, textAlign: TextAlign.center),
        SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: () => _retrySplash(),
          icon: Icon(Icons.refresh),
          label: Text('Try Again'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _continueOfflineMode(),
          icon: Icon(Icons.offline_bolt),
          label: Text('Continue Anyway'),
        ),
        SizedBox(height: 12),
        TextButton(
          onPressed: () => _exitApp(),
          child: Text('Exit App'),
        ),
      ],
    );
  }
  
  return SizedBox.shrink();
}
```

#### 6. Main App Offline UI Indicators
```dart
// lib/presentation/widgets/app_scaffold_with_offline.dart (NEW)
class AppScaffoldWithOffline extends StatelessWidget {
  final Widget body;
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AppStateManager().offlineModeStream,
      initialData: AppStateManager().isOfflineMode,
      builder: (context, snapshot) {
        final isOfflineMode = snapshot.data ?? false;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: isOfflineMode ? Colors.orange[700] : null,
            actions: [
              if (isOfflineMode) _buildOfflineBadge(),
            ],
          ),
          body: Column(
            children: [
              if (isOfflineMode) _buildOfflineBanner(context),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOfflineBadge() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, size: 16, color: Colors.orange[700]),
          SizedBox(width: 4),
          Text('OFFLINE', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
        ],
      ),
    );
  }
  
  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Some features are limited.',
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
          TextButton(
            onPressed: () => _checkConnection(context),
            child: Text('Go Online'),
          ),
        ],
      ),
    );
  }
  
  void _checkConnection(BuildContext context) {
    context.read<NetworkCubit>().checkConnectivity();
    // Auto-switch back to online mode when network available
  }
}
```

### Features Availability in Offline Mode

#### ✅ Available Features:
- Browse downloaded/offline content  
- Read downloaded manga/images
- Manage favorites (changes sync later)
- App settings and preferences
- Convert downloaded content to PDF
- Search within offline content
- Offline content statistics

#### ❌ Disabled Features:
- Browse new content online
- Search online content
- Download new content  
- Cloudflare bypass operations
- Real-time sync operations
- Online user authentication

#### 🔄 Smart Features:
- Auto-detect when connection returns
- "Go Online" button for manual check
- Queue operations for when online
- Background sync when connection restored
- Seamless online/offline mode transitions

## 📋 Implementation Plan

### Phase 1: Stream-Based Progress Updates
1. **Create DownloadManager Service**
   - StreamController untuk progress updates
   - Global download state management
   - Integration dengan existing DownloadService

2. **Modify DownloadBloc**
   - Subscribe to progress stream
   - Auto-emit progress updates
   - Handle stream errors

3. **Update DownloadContentUseCase**
   - Emit progress ke stream instead of hanya save database
   - Maintain backward compatibility

### Phase 2: Improve Cancel/Pause Mechanism
1. **Create DownloadTask Class**
   - Track individual download state
   - Proper cancellation handling
   - Pause/resume capability

2. **Modify DownloadService**
   - Check pause state in download loop
   - Proper cancel token handling
   - Cleanup on cancellation

3. **Update DownloadBloc**
   - Proper task management
   - Better error handling

### Phase 3: Notification Permission
1. **Add Permission Handling**
   - Request notification permission
   - Handle permission denied scenarios
   - Graceful fallback

2. **Update NotificationService**
   - Check permission before showing notifications
   - Better error handling

### Phase 4: State Management Improvements
1. **Flexible State Handling**
   - Remove strict state checks
   - Better error recovery
   - Consistent state updates

## 📁 Files to Modify

### Core Files
1. **`lib/services/download_manager.dart`** *(NEW)*
   - Stream-based progress management
   - Global download coordination

2. **`lib/presentation/blocs/download/download_bloc.dart`**
   - Subscribe to progress stream
   - Add PDF conversion handler
   - Improved state management
   - Better error handling

3. **`lib/domain/usecases/downloads/download_content_usecase.dart`**
   - Emit progress to stream
   - Better cancellation handling

4. **`lib/services/download_service.dart`**
   - Proper pause/cancel checks
   - Improved error handling

5. **`lib/services/notification_service.dart`**
   - Permission handling
   - PDF conversion notifications
   - Better initialization

6. **`lib/services/pdf_service.dart`**
   - Custom output path support
   - Progress tracking for conversion
   - Optimized for background processing

### Supporting Files
7. **`lib/services/pdf_conversion_service.dart`** *(NEW)*
   - Background PDF conversion management
   - Progress tracking and notifications

8. **`lib/domain/entities/download_task.dart`** *(NEW)*
   - Download task model with state

9. **`lib/presentation/widgets/download_item_widget.dart`**
   - Add "Convert to PDF" action menu
   - Better UI state handling

10. **`lib/presentation/pages/downloads/downloads_screen.dart`**
    - Add PDF conversion action handler
    - Remove unnecessary RefreshIndicator dependency
    - Better UI state handling

### Event Files
11. **`lib/presentation/blocs/download/download_event.dart`**
    - Add `DownloadConvertToPdfEvent`

### Splash Screen Offline Enhancement Files
12. **`lib/core/utils/app_state_manager.dart`** *(NEW)*
    - Global offline mode state management
    - Stream-based offline mode tracking

13. **`lib/presentation/blocs/splash/splash_state.dart`**
    - Add offline-specific states
    - Enhanced state management for offline scenarios

14. **`lib/presentation/blocs/splash/splash_event.dart`**
    - Add offline mode events
    - Force offline mode event

15. **`lib/presentation/blocs/splash/splash_bloc.dart`**
    - Enhanced offline detection logic
    - Smart auto-continue functionality
    - Integration with OfflineContentManager

16. **`lib/presentation/pages/splash/splash_page.dart`**
    - Enhanced UI for offline options
    - User-friendly offline flow

17. **`lib/presentation/widgets/app_scaffold_with_offline.dart`** *(NEW)*
    - Reusable scaffold with offline indicators
    - Offline mode banner and badges
    - "Go Online" functionality

## 🔄 Implementation Steps

### Step 1: Create DownloadManager
```dart
// lib/services/download_manager.dart
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final StreamController<DownloadProgressUpdate> _progressController = 
      StreamController<DownloadProgressUpdate>.broadcast();
  
  Stream<DownloadProgressUpdate> get progressStream => _progressController.stream;
  
  void emitProgress(DownloadProgressUpdate update) {
    if (!_progressController.isClosed) {
      _progressController.add(update);
    }
  }
  
  void dispose() {
    _progressController.close();
  }
}
```

### Step 2: Modify DownloadBloc
```dart
// In DownloadBloc constructor
StreamSubscription<DownloadProgressUpdate>? _progressSubscription;

// Initialize subscription
void _initializeProgressStream() {
  _progressSubscription = DownloadManager().progressStream.listen(
    (update) {
      add(DownloadProgressUpdateEvent(
        contentId: update.contentId,
        downloadedPages: update.downloadedPages,
        totalPages: update.totalPages,
      ));
    },
    onError: (error) {
      _logger.e('Progress stream error: $error');
    },
  );
}

@override
Future<void> close() {
  _progressSubscription?.cancel();
  return super.close();
}
```

### Step 3: Update DownloadContentUseCase
```dart
// Replace progress callback
onProgress: (progress) async {
  // Save to database
  currentStatus = currentStatus.copyWith(downloadedPages: progress.downloadedPages);
  await _userDataRepository.saveDownloadStatus(currentStatus);
  
  // Emit to stream for real-time updates
  DownloadManager().emitProgress(DownloadProgressUpdate(
    contentId: content.id,
    downloadedPages: progress.downloadedPages,
    totalPages: progress.totalPages,
    progress: progress.progressPercentage,
  ));
},
```

### Step 4: Improve Cancel/Pause in DownloadService
```dart
// In download loop
for (int i = 0; i < content.imageUrls.length; i++) {
  // Check cancellation
  if (cancelToken?.isCancelled == true) {
    throw DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.cancel,
    );
  }
  
  // Check pause state (implement pause mechanism)
  while (_isPaused(content.id)) {
    await Future.delayed(Duration(seconds: 1));
    if (cancelToken?.isCancelled == true) break;
  }
  
  // Download image...
}
```

### Step 6: PDF Folder Management
```dart
// lib/services/pdf_conversion_service.dart
Future<Directory> _createPdfFolder() async {
  // Get app documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  
  // Create nhasix-generate/pdf/ folder
  final pdfFolder = Directory(path.join(appDocDir.path, 'nhasix-generate', 'pdf'));
  
  if (!await pdfFolder.exists()) {
    await pdfFolder.create(recursive: true);
  }
  
  return pdfFolder;
}

String _generatePdfFileName(String contentId, String title, {int? partNumber}) {
  // Create safe short title (max 30 chars)
  String shortTitle = title
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
  
  if (shortTitle.length > 30) {
    shortTitle = shortTitle.substring(0, 30);
  }
  
  // Add part number if specified (for PDFs > 50 pages)
  if (partNumber != null) {
    return '${contentId}_${shortTitle}_part$partNumber.pdf';
  }
  
  return '${contentId}_$shortTitle.pdf';
}
```

### Step 7: Enhanced PDF Service
```dart
// lib/services/pdf_service.dart - Modify existing
Future<PdfResult> convertToPdf({
  required String contentId,
  required String title,
  required List<String> imagePaths,
  String? outputPath, // NEW: Custom output path
  Function(int progress)? onProgress, // NEW: Progress callback
  int? maxWidth,
  int? quality,
  int maxPagesPerFile = 50, // NEW: Max pages per PDF file
}) async {
  try {
    final processedImages = <Uint8List>[];
    
    for (int i = 0; i < imagePaths.length; i++) {
      final imageBytes = await _processImage(
        imagePaths[i],
        maxWidth: maxWidth ?? 1200,
        quality: quality ?? 85,
      );
      
      if (imageBytes != null) {
        processedImages.add(imageBytes);
      }
      
      // Report progress for image processing (50% of total)
      onProgress?.call(((i + 1) / imagePaths.length * 50).round());
    }
    
    if (processedImages.isEmpty) {
      throw Exception('No images could be processed for PDF');
    }
    
    // Determine if we need to split into multiple files
    final totalPages = processedImages.length;
    final needsSplitting = totalPages > maxPagesPerFile;
    final pdfPaths = <String>[];
    
    if (needsSplitting) {
      // Split into multiple PDF files
      final totalParts = (totalPages / maxPagesPerFile).ceil();
      
      for (int part = 1; part <= totalParts; part++) {
        final startIndex = (part - 1) * maxPagesPerFile;
        final endIndex = (startIndex + maxPagesPerFile).clamp(0, totalPages);
        final partImages = processedImages.sublist(startIndex, endIndex);
        
        // Generate filename with part number
        final partFileName = _generatePdfFileName(contentId, title, partNumber: part);
        final partPath = outputPath != null 
            ? path.join(path.dirname(outputPath), partFileName)
            : partFileName;
        
        // Create PDF part
        await _createDynamicPdf(partImages, partPath, title: '$title (Part $part)');
        pdfPaths.add(partPath);
        
        // Report progress for PDF creation (50% + current part progress)
        final partProgress = 50 + ((part / totalParts) * 50).round();
        onProgress?.call(partProgress);
      }
    } else {
      // Single PDF file
      final singleFileName = _generatePdfFileName(contentId, title);
      final singlePath = outputPath ?? singleFileName;
      
      await _createDynamicPdf(processedImages, singlePath, title: title);
      pdfPaths.add(singlePath);
      
      // Report 100% completion
      onProgress?.call(100);
    }
    
    // Calculate total file size
    int totalFileSize = 0;
    for (final pdfPath in pdfPaths) {
      totalFileSize += await File(pdfPath).length();
    }
    
    return PdfResult(
      success: true,
      pdfPaths: pdfPaths, // Updated to support multiple files
      fileSize: totalFileSize,
      pageCount: processedImages.length,
      partsCount: pdfPaths.length, // NEW: Number of PDF parts created
    );
  } catch (e) {
    return PdfResult(
      success: false,
      error: e.toString(),
      pdfPaths: [],
      fileSize: 0,
      pageCount: 0,
      partsCount: 0,
    );
  }
}

// Enhanced PDF creation with dynamic sizing
Future<void> _createDynamicPdf(List<Uint8List> images, String outputPath,
    {required String title}) async {
  final pdf = pw.Document();

  for (final imageBytes in images) {
    // Decode image to get dimensions
    final img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) continue;
    
    final image = pw.MemoryImage(imageBytes);
    final isLandscape = decodedImage.width > decodedImage.height;
    
    pdf.addPage(
      pw.Page(
        pageFormat: isLandscape 
            ? PdfPageFormat.a4.landscape 
            : PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.all(0), // No margins for clean layout
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              image,
              fit: pw.BoxFit.contain, // Maintain aspect ratio
            ),
          );
        },
      ),
    );
  }

/// Result of PDF conversion
class PdfResult {
  const PdfResult({
    required this.success,
    required this.pageCount,
    required this.fileSize,
    required this.partsCount, // NEW: Number of PDF parts
    this.pdfPaths = const [], // Updated to support multiple files
    this.error,
  });

  final bool success;
  final List<String> pdfPaths; // Changed from single pdfPath to multiple pdfPaths
  final int pageCount;
  final int fileSize; // Total size of all PDF files
  final int partsCount; // Number of PDF parts created
  final String? error;
  
  // Convenience getter for single file scenarios
  String? get pdfPath => pdfPaths.isNotEmpty ? pdfPaths.first : null;
  
  // Check if PDF was split into multiple parts
  bool get isSplit => partsCount > 1;
}
```

### Step 8: Implement Splash Screen Offline Enhancement
```dart
// lib/core/utils/app_state_manager.dart - Global offline state
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();
  
  bool _isOfflineMode = false;
  StreamController<bool> _offlineModeController = StreamController<bool>.broadcast();
  
  bool get isOfflineMode => _isOfflineMode;
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  
  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    _offlineModeController.add(offline);
  }
  
  void enableOfflineMode() => setOfflineMode(true);
  void enableOnlineMode() => setOfflineMode(false);
}
```

```dart
// lib/presentation/blocs/splash/splash_bloc.dart - Enhanced offline handling
Future<void> _onSplashStarted(SplashStartedEvent event, Emitter<SplashState> emit) async {
  emit(SplashInitializing());
  
  try {
    await Future.delayed(_initialDelay);
    
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.none) {
      // Enhanced: Smart offline handling instead of hard error
      await _handleOfflineMode(emit);
      return;
    }
    
    // Continue normal online flow...
  } catch (e, stackTrace) {
    _logger.e('SplashBloc: Error during initialization', error: e, stackTrace: stackTrace);
    emit(SplashError(message: 'Initialization failed: ${e.toString()}', canRetry: true));
  }
}

Future<void> _handleOfflineMode(Emitter<SplashState> emit) async {
  emit(SplashOfflineDetected(message: 'Checking offline content...'));
  
  try {
    final offlineContentIds = await _offlineContentManager.getOfflineContentIds();
    
    if (offlineContentIds.isNotEmpty) {
      // Auto-continue with offline content
      emit(SplashOfflineReady(
        message: 'Found ${offlineContentIds.length} offline items',
        offlineContentCount: offlineContentIds.length,
      ));
      
      AppStateManager().enableOfflineMode();
      await Future.delayed(Duration(seconds: 1));
      emit(SplashSuccess(message: 'Ready (Offline Mode)'));
    } else {
      // Show offline options
      emit(SplashOfflineEmpty(message: 'No offline content available.'));
    }
  } catch (e) {
    emit(SplashOfflineEmpty(message: 'Unable to check offline content.'));
  }
}
```

## 🧪 Testing Strategy

### Unit Tests
1. **DownloadManager Tests**
   - Stream emission
   - Error handling
   - Memory leaks

2. **DownloadBloc Tests**
   - Progress stream subscription
   - State updates
   - Error recovery

3. **DownloadService Tests**
   - Pause/cancel functionality
   - Progress callbacks
   - Error scenarios

4. **Splash Screen Offline Tests**
   - Offline content detection
   - Auto-continue functionality
   - Offline mode state management
   - UI option handling

### Integration Tests
1. **End-to-End Download Flow**
   - Start download → Real-time progress → Completion
   - Pause → Resume functionality
   - Cancel → Cleanup verification

2. **Permission Flow**
   - Permission request → Notification display
   - Permission denied → Graceful fallback

3. **Offline Mode Flow**
   - Splash offline detection → Content check → Auto-continue
   - Offline UI indicators → Feature limitations → Online recovery
   - Network state transitions → Mode switching

### Step 5: Add Notification Permission
```dart
// In NotificationService.initialize()
Future<void> initialize() async {
  try {
    // Request notification permission first
    final permissionStatus = await Permission.notification.request();
    
    if (!permissionStatus.isGranted) {
      _logger.w('Notification permission denied');
      // Continue without notifications or show permission dialog
      return;
    }
    
    // Initialize notifications...
  } catch (e) {
    _logger.e('Failed to initialize NotificationService: $e');
  }
}
```

### Manual Testing Checklist

#### Real-Time Progress Tests
- [ ] Progress bar updates real-time tanpa refresh
- [ ] Pause button stops download immediately  
- [ ] Resume button continues from where it stopped
- [ ] Cancel button stops and cleans up properly
- [ ] Notification permission request appears
- [ ] Notifications work when permission granted
- [ ] App works gracefully when permission denied
- [ ] Multiple downloads work simultaneously
- [ ] App restart preserves download state

#### PDF Conversion Tests  
- [ ] "Convert to PDF" menu muncul untuk completed downloads
- [ ] PDF conversion starts with notification
- [ ] Progress notification updates during conversion
- [ ] PDF tersimpan di `nhasix-generate/pdf/[id_judul_pendek].pdf`
- [ ] **PDF splitting: Content > 50 halaman dibagi menjadi multiple files**
- [ ] **PDF part naming: `[id_judul_pendek]_part1.pdf`, `_part2.pdf`, dst.**
- [ ] **Notification shows correct parts count untuk split PDFs**
- [ ] PDF completion notification muncul
- [ ] PDF dapat dibuka dan tidak ada nomor halaman
- [ ] PDF support gambar portrait dan landscape
- [ ] PDF conversion berjalan di background
- [ ] Multiple PDF conversions dapat berjalan bersamaan
- [ ] Error handling untuk PDF conversion failure
- [ ] **Memory usage stabil untuk PDF dengan > 100 halaman**
- [ ] **File size optimization untuk multiple PDF parts**

#### Splash Screen Offline Tests
- [ ] **Offline detection:** Splash screen detects no internet correctly
- [ ] **Content check:** Quickly checks for offline content availability
- [ ] **Auto-continue:** Users with offline content auto-continue to main app
- [ ] **Offline options:** Users without content see clear options (Retry/Continue/Exit)
- [ ] **Offline UI:** Main app shows offline indicators and banner
- [ ] **Feature limitations:** Online-only features properly disabled
- [ ] **Go Online:** "Go Online" button works when connection restored
- [ ] **Mode switching:** Seamless transition between offline/online modes
- [ ] **State persistence:** Offline mode state maintained across app restarts
- [ ] **Edge cases:** Handle corrupt offline data, partial network, etc.
- [ ] **No user stuck:** User never stuck at splash regardless of network/content state

## 🚀 Migration Strategy

### Phase 1: Real-Time Progress (Backward Compatible)
- Add DownloadManager tanpa mengubah existing code
- Test stream functionality
- Update DownloadBloc untuk use stream
- Keep existing functionality as fallback

### Phase 2: PDF Conversion Feature
- Add PDF conversion event dan handler
- Implement background PDF service
- Add UI actions dan notifications
- Test PDF conversion functionality

### Phase 3: Splash Screen Offline Enhancement
- Add enhanced offline detection dan auto-continue
- Implement global offline mode management
- Add offline UI indicators dan user options
- Test offline flow scenarios

### Phase 4: Full Implementation
- Update all components
- Remove old code
- Comprehensive testing
- Performance optimization

## 📊 Expected Results

### Before Fix
- ❌ Progress hanya update saat refresh
- ❌ Pause tidak berfungsi  
- ❌ Tidak ada notification permission
- ❌ Sering error state management
- ❌ Tidak ada fitur convert to PDF
- ❌ **Splash screen stuck saat offline**
- ❌ **Tidak bisa akses offline content saat no internet**

### After Fix
- ✅ Real-time progress updates
- ✅ Pause/resume berfungsi dengan baik
- ✅ Proper notification permission handling
- ✅ Robust state management
- ✅ Better error handling dan recovery
- ✅ **Convert to PDF** untuk completed downloads
- ✅ **Background PDF conversion** dengan progress tracking
- ✅ **Custom PDF folder** `nhasix-generate/pdf/`
- ✅ **Clean PDF layout** tanpa nomor halaman
- ✅ **Dynamic PDF sizing** support portrait/landscape
- ✅ **Special PDF notifications** untuk conversion process
- ✅ **Smart offline mode** dengan auto-continue functionality
- ✅ **Seamless offline/online transitions** dengan clear UI indicators
- ✅ **No user stuck scenarios** - selalu ada path forward
- ✅ Improved user experience

## 🎯 Success Metrics
1. Progress bar bergerak smooth tanpa lag
2. Pause/resume response time < 1 detik
3. Zero crashes related to download state
4. 100% notification permission handling
5. Memory usage stabil selama download
6. Support multiple concurrent downloads
7. **PDF conversion completion time < 30 detik** untuk content 20-50 halaman
8. **PDF splitting efficiency: < 45 detik** untuk content 50-150 halaman  
9. **PDF file size optimization** maksimal 2x ukuran original images per part
10. **Background PDF processing** tidak mengganggu UI performance
11. **PDF folder management** konsisten dan terorganisir
12. **Memory usage < 200MB** selama PDF conversion untuk content > 100 halaman
13. **Splash screen offline flow** < 2 detik untuk detection dan auto-continue
14. **Offline mode transition** seamless tanpa app restart
15. **No stuck scenarios** - user selalu punya path forward dalam 3 detik

---

## 📝 Notes
- Implementasi harus maintain backward compatibility
- Testing harus cover edge cases (network loss, storage full, etc.)
- Performance harus tetap optimal untuk multiple downloads
- UI/UX harus responsive dan informative
