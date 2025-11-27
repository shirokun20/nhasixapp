# Offline Screen & Download Improvements - Implementation Plan

## 📋 Overview
Comprehensive improvements to Offline Screen, Download notifications, PDF generation for webtoon images, and reading mode enhancements.

**Created:** 2025-11-27  
**Status:** In Progress  
**Priority:** High  
**Estimated Effort:** 5-7 days

---

## 🎯 Goals

### 1. Move PDF Generation to Offline Screen
- **Current:** PDF generation is only available in Downloads Screen
- **Target:** Make PDF generation accessible from Offline Screen for already downloaded content
- **Impact:** Better UX, users can generate PDFs from their offline library

### 2. Add Delete Item Feature to Offline Screen
- **Current:** No delete functionality in Offline Screen
- **Target:** Allow users to delete offline content with confirmation
- **Impact:** Storage management, better content control

### 3. Handle Webtoon/Long Images in PDF Generation
- **Current:** PDF generation doesn't handle extremely tall images (webtoon style)
- **Target:** Smart splitting or special handling for tall images in PDF
- **Impact:** Prevent PDF rendering issues, better file size management

### 4. Fix Notification Sound Issue
- **Current:** Download notifications play sound on every progress update
- **Target:** Sound only on start and completion
- **Impact:** Better UX, less annoying notifications

### 5. Improve Offline Screen UI
- **Current:** Basic UI, needs visual improvements
- **Target:** Modern, polished UI with better information display
- **Impact:** Better user experience, professional appearance

### 6. Fix Reading Mode for Webtoon Images
- **Current:** Reading mode doesn't handle tall/webtoon images well (see flutter_bug_01.png)
- **Target:** Proper scroll behavior for vertical continuous reading
- **Impact:** Better reading experience for webtoon-style content

---

## 🔍 Current Implementation Analysis

### Downloads Screen (`lib/presentation/pages/downloads/downloads_screen.dart`)
```dart
// Line 516-523: PDF conversion action
case 'convert_pdf':
  downloadBloc.add(DownloadConvertToPdfEvent(download.contentId));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!
        .pdfConversionStarted(download.contentId))),
  );
```

**Key findings:**
- PDF generation triggered via `DownloadConvertToPdfEvent`
- Only accessible through download item context menu
- No PDF generation for already-offline content

### Offline Screen (`lib/presentation/pages/offline/offline_content_screen.dart`)
```dart
// Line 430-440: Content card display - CURRENT IMPLEMENTATION
return ContentCard(
  content: content,
  onTap: () => context.push('/reader/${content.id}', extra: content),
  showOfflineIndicator: true,
  isHighlighted: false,
  // ❌ NOT USED: onLongPress parameter (exists but not implemented)
);
```

**Current Status (VERIFIED from code analysis):**
- ❌ **NO long press handler** - `onLongPress` parameter not used
- ❌ **NO bottom sheet** for actions (Delete/Read/Convert PDF)
- ❌ **NO delete functionality**
- ❌ **NO PDF generation** from offline screen
- ❌ **NO bulk delete** feature
- ❌ **NO selection mode** for multi-select
- ✅ Only has `onTap` to open reader

### ContentCard Widget (`lib/presentation/widgets/content_card_widget.dart`)
```dart
// Line 20-23: Widget parameters - ALREADY SUPPORTS onLongPress!
class ContentCard extends StatelessWidget {
  const ContentCard({
    ...
    this.onTap,
    this.onLongPress,  // ✅ ALREADY EXISTS (not used in offline screen yet)
    ...
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;  // ✅ READY TO USE
```

**Widget Capabilities (VERIFIED):**
- ✅ **ALREADY supports** `onLongPress` parameter (line 22)
- ✅ **ALREADY implements** InkWell with onLongPress (line 81)
- ✅ **READY** for bottom sheet implementation
- 🎯 Just needs to be **USED** in offline_content_screen.dart

**Planned Features (NOT YET IMPLEMENTED):**
Based on UI mockup in `screenshots/flutter_11.png`:
1. **Long Press Action** → Show bottom sheet with options:
   - 📖 Read (open in reader)
   - 🗑️ Delete (with confirmation)
   - 📄 Convert to PDF
2. **Bulk Delete**:
   - Selection mode toggle
   - Checkboxes on cards
   - Multi-select capability
   - Batch delete with confirmation

### Offline Content Path Structure (from `offline_content_manager.dart`)
```dart
// ACTUAL PATH STRUCTURE (analyzed from code):
// Primary: [basePath]/nhasix/[contentId]/images/page_001.jpg
//
// Path detection via _getDownloadsDirectory() tries:
// 1. Download folder
// 2. Downloads folder  
// 3. Unduhan folder (Indonesian)
//
// Fallbacks via _getPossibleDownloadPaths():
// 1. getExternalStorageDirectory() + /nhasix/
// 2. getApplicationDocumentsDirectory() + /nhasix/
//
// File structure:
// - Images: [basePath]/nhasix/[contentId]/images/page_XXX.jpg
// - Metadata: [basePath]/nhasix/[contentId]/metadata.json
// - Old structure: [basePath]/nhasix/[contentId]/page_XXX.jpg (fallback)
```

**Verified from code (lines 87-155, 780-850):**
- Smart path detection with multiple Download folder attempts
- Multiple fallback locations for robustness
- Structured folder organization: `nhasix/[contentId]/images/`
- Page numbering: `page_001.jpg`, `page_002.jpg`, etc.

### Notification Service (`lib/services/notification_service.dart`)
```dart
// Line 742: Download started - Importance.low (no sound)
importance: Importance.low,
priority: Priority.low,

// Line 793: Progress update - Importance.low (no sound)
importance: Importance.low,
priority: Priority.low,

// Line 867: Download completed - Importance.defaultImportance (with sound)
importance: Importance.defaultImportance,
priority: Priority.defaultPriority,
```

**Key findings (Android-only project):**
- **IMPORTANT:** This is an Android-only project, iOS code exists but is unused
- Download notifications use `Importance.low` = **NO SOUND** (start & progress)
- Completed notifications use `Importance.defaultImportance` = **WITH SOUND**
- Sound control is through `importance` level, NOT `playSound` parameter
- Current implementation is **ALREADY CORRECT** - sound only plays on completion!

### PDF Service (`lib/services/pdf_service.dart`)
```dart
// Line 88-96: Image processing
if (image.width > maxWidth) {
  final aspectRatio = image.height / image.width;
  final newHeight = (maxWidth * aspectRatio).round();
  processedImage = img.copyResize(image, width: maxWidth, height: newHeight);
}
```

**Key findings:**
- Only checks width for resizing
- No special handling for extremely tall images (webtoon style)
- Could create very large PDF pages for tall images
- No image splitting logic

### Reading Mode (`lib/presentation/pages/reader/reader_screen.dart`)
```dart
// Line 145-148: Continuous scroll listener
if (state.readingMode == ReadingMode.continuousScroll && state.content != null) {
  final screenHeight = MediaQuery.of(context).size.height;
  final approximateItemHeight = screenHeight * 0.9;
  // ... scroll calculation
}
```

**Key findings:**
- Uses fixed approximation for item height
- May not work well with varying height images (webtoon)
- Scroll calculation based on screen height multiplier

---

## 📝 Implementation Tasks

### Task 1: Move PDF Generation to Offline Screen
**Priority:** High  
**Complexity:** Medium  
**Files to modify:**
- `lib/presentation/pages/offline/offline_content_screen.dart`
- `lib/presentation/widgets/content_card_widget.dart` (possibly)
- `lib/presentation/cubits/offline_search/offline_search_cubit.dart`

#### Todo List:
- [ ] **Use existing** `onLongPress` handler in `ContentCard` (✅ already exists!)
  - [x] ContentCard already has `onLongPress` parameter (line 22)
  - [x] InkWell already implements onLongPress (line 81)
  - [ ] Add `onLongPress` callback in offline_content_screen.dart
  - [ ] Call `_showContentActions()` on long press
- [ ] Create bottom sheet with actions (Open, Generate PDF, Delete)
  - [ ] Use `showModalBottomSheet` from Material
  - [ ] Design with Material 3 components (ListTile for actions)
  - [ ] Add drag handle indicator at top
  - [ ] Show content thumbnail and title in header
  - [ ] Actions: 📖 Read, 📄 Convert to PDF, 🗑️ Delete
  - [ ] Style bottom sheet to match app theme
  - [ ] Add smooth animation (Curves.easeOutCubic)
- [ ] Integrate with `PdfConversionService`
  - [ ] Import and inject `PdfConversionService` via GetIt
  - [ ] Create `_generatePdf(Content content)` method
  - [ ] Handle PDF generation state (loading, success, error)
  - [ ] Show progress dialog during PDF generation
  - [ ] Navigate to reader or show success message
- [ ] Test bottom sheet from offline content
  - [ ] Test long press gesture on ContentCard
  - [ ] Test all bottom sheet actions
  - [ ] Test with various content sizes
  - [ ] Verify PDF file location and accessibility
  - [ ] Test notification integration
  - [ ] Test error handling (no storage, no permission)
  - [ ] Test accessibility (screen reader)

**Technical Considerations:**
- Reuse existing `PdfConversionService` logic from Downloads Screen
- Ensure offline content paths are correctly passed to PDF service
- Handle cases where images might be corrupted or missing
- Consider adding batch PDF generation for multiple items

**Code Example (Based on flutter_11.png mockup):**
```dart
// Offline Screen - Use existing onLongPress parameter
ContentCard(
  content: content,
  onTap: () => context.push('/reader/${content.id}', extra: content),
  onLongPress: () => _showContentActions(context, content), // ✅ Use existing parameter!
  showOfflineIndicator: true,
  isHighlighted: false,
)

// Show bottom sheet with actions (Material Design)
void _showContentActions(BuildContext context, Content content) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    content.thumbnailUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Text(
                    content.title,
                    style: TextStyleConst.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Actions
          ListTile(
            leading: Icon(Icons.menu_book, color: colorScheme.primary),
            title: Text(AppLocalizations.of(context)!.read),
            onTap: () {
              Navigator.pop(context);
              context.push('/reader/${content.id}', extra: content);
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
            title: Text(AppLocalizations.of(context)!.convertToPdf),
            subtitle: Text('${content.pageCount} pages'),
            onTap: () {
              Navigator.pop(context);
              _generatePdf(content);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, content);
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _generatePdf(Content content) async {
  final pdfService = getIt<PdfConversionService>();
  // Implementation from code-snippets.md
}
```

---

### Task 2: Add Delete Feature to Offline Screen
**Priority:** High  
**Complexity:** Medium  
**Files to modify:**
- `lib/presentation/pages/offline/offline_content_screen.dart`
- `lib/presentation/cubits/offline_search/offline_search_cubit.dart`
- `lib/core/utils/offline_content_manager.dart`

#### Todo List:
- [ ] Create delete confirmation dialog
  - [ ] Design Material 3 styled confirmation dialog
  - [ ] Show storage size being freed
  - [ ] Add "Don't ask again" checkbox option
  - [ ] Include warning about permanent deletion
- [ ] Implement delete logic in `OfflineContentManager`
  - [ ] Add `deleteOfflineContent(String contentId)` method
  - [ ] Delete all associated files (images, metadata, thumbnails)
  - [ ] Update database/storage tracking
  - [ ] Calculate and return freed storage space
- [ ] Add delete action to offline item context menu
  - [ ] Add delete option to bottom sheet actions
  - [ ] Show loading indicator during deletion
  - [ ] Update UI optimistically (remove from list immediately)
  - [ ] Handle deletion errors gracefully
- [ ] Add bulk delete functionality (**NEW FEATURE** - from flutter_11.png mockup)
  - [ ] Add selection mode toggle button in AppBar
  - [ ] Add `isSelectionMode` state in screen
  - [ ] Show checkboxes on ContentCard when in selection mode
  - [ ] Track selected items in `Set<String>` (contentIds)
  - [ ] Add "Select All" / "Deselect All" actions in AppBar
  - [ ] Show FloatingActionButton or BottomAppBar with:
    - Selected count (e.g., "5 selected")
    - Delete button (only enabled when items selected)
    - Cancel/Exit selection mode button
  - [ ] Bulk delete confirmation dialog:
    - Show total size to be freed
    - List selected items (scrollable if > 5)
    - Warning about permanent deletion
    - Confirm/Cancel buttons
  - [ ] Implement batch deletion:
    - Loop through selected items
    - Show progress indicator (e.g., "Deleting 3/5...")
    - Handle partial failures gracefully
    - Exit selection mode after completion
  - [ ] Test bulk delete:
    - Select multiple items (5, 10, 20+)
    - Test select all with 100+ items
    - Test canceling during deletion
    - Test with mixed success/failure scenarios
- [ ] Handle edge cases
  - [ ] Content currently being read
  - [ ] Content with active PDF generation
  - [ ] Corrupted/partial content
  - [ ] Permission denied scenarios
- [ ] Update storage stats after deletion
  - [ ] Refresh storage info in AppBar
  - [ ] Animate storage counter update
  - [ ] Show freed space notification

**Technical Considerations:**
- Check if content is currently open in reader before deleting
- Implement soft delete first (move to trash) for safety
- Consider adding "Recently Deleted" section
- Update search index after deletion
- Clear cache and temporary files

**Code Example:**
```dart
// OfflineContentManager - Delete method
Future<DeleteResult> deleteOfflineContent(String contentId) async {
  try {
    // Check if content exists
    final exists = await isContentAvailableOffline(contentId);
    if (!exists) {
      return DeleteResult.notFound();
    }

    // Calculate current size
    final sizeBefore = await getContentSize(contentId);

    // Delete images
    final imageDir = await getContentImageDirectory(contentId);
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }

    // Delete metadata
    await _metadataStorage.delete(contentId);

    // Delete thumbnails
    await _deleteThumbnails(contentId);

    return DeleteResult.success(freedSpace: sizeBefore);
  } catch (e) {
    return DeleteResult.error(e.toString());
  }
}
```

---

### Task 3: Handle Webtoon/Long Images in PDF
**Priority:** High  
**Complexity:** High  
**Files to modify:**
- `lib/services/pdf_service.dart`
- `lib/services/pdf_conversion_service.dart`
- `lib/services/pdf_isolate_worker.dart`

#### Todo List:
- [ ] Detect webtoon/long images
  - [ ] Add aspect ratio threshold (e.g., height/width > 3.0)
  - [ ] Create `isWebtoonImage(int width, int height)` helper
  - [ ] Log detected webtoon images for monitoring
- [ ] Implement smart image splitting
  - [ ] Split tall images into multiple pages
  - [ ] Calculate optimal split points (avoid cutting mid-content)
  - [ ] Maintain image quality during splits
  - [ ] Add overlap between splits for continuity
- [ ] Add configuration options
  - [ ] Max page height threshold (e.g., 5000px)
  - [ ] Split strategy: auto, fixed-height, smart-content
  - [ ] Quality vs file size preference
  - [ ] Option to skip webtoon splitting
- [ ] Update PDF page creation
  - [ ] Handle split images as separate pages
  - [ ] Maintain page order correctly
  - [ ] Add page markers for split images
  - [ ] Preserve metadata about split pages
- [ ] Test with various image types
  - [ ] Normal landscape/portrait images
  - [ ] Extremely tall webtoon images (10000+ px height)
  - [ ] Mixed content (normal + webtoon in same PDF)
  - [ ] Very wide panoramic images
- [ ] Optimize memory usage
  - [ ] Process splits in chunks
  - [ ] Release memory after each split
  - [ ] Monitor memory during large image processing

**Technical Considerations:**
- Use `image` package for splitting: `copyCrop()` method
- Consider edge detection for smart splitting
- Balance between file size and quality
- Handle very large images (>100MB) specially
- Update notification to show split progress

**Verified Image Analysis (from actual project images):**
- **Normal Image** (`6143172194436057944.jpg`): 902×1280px, AR=1.42 (portrait)
- **Webtoon Image** (`IMG_20251127_105652_516.jpg`): 1275×16383px, AR=12.85 (extreme vertical!)
- **Strategy:** Slice webtoon into ~13 chunks of 1260px height each → resulting AR≈1.0 per chunk
- **Detection threshold:** AR > 2.5 (normal=1.4, webtoon=12.8)

**Code Example:**
```dart
// PDF Service - Webtoon detection and splitting (ACCURATE based on real images)
class WebtoonImageProcessor {
  // Based on analysis: normal AR=1.42, webtoon AR=12.85
  static const double WEBTOON_ASPECT_RATIO_THRESHOLD = 2.5;
  
  // Target height based on normal image (1280px) for consistent reading
  static const int MAX_PDF_PAGE_HEIGHT = 1280;
  
  static bool isWebtoonImage(int width, int height) {
    final aspectRatio = height / width;
    return aspectRatio > WEBTOON_ASPECT_RATIO_THRESHOLD;
  }
  
  static Future<List<Uint8List>> splitTallImage(
    img.Image image, {
    int maxHeight = MAX_PDF_PAGE_HEIGHT,
    int overlap = 50, // px overlap for continuity
  }) async {
    final parts = <Uint8List>[];
    final totalHeight = image.height;
    int currentY = 0;
    
    while (currentY < totalHeight) {
      final remainingHeight = totalHeight - currentY;
      final sliceHeight = remainingHeight > maxHeight 
          ? maxHeight 
          : remainingHeight;
      
      // Crop image slice
      final slice = img.copyCrop(
        image,
        x: 0,
        y: currentY,
        width: image.width,
        height: sliceHeight,
      );
      
      // Encode slice
      final sliceBytes = img.encodeJpg(slice, quality: 85);
      parts.add(Uint8List.fromList(sliceBytes));
      
      // Move to next slice with overlap
      currentY += sliceHeight - overlap;
    }
    
    return parts;
  }
}

// Update _processImageStatic to use splitting
static Future<List<Uint8List>> _processImageStatic(
  String imagePath, {
  required int maxWidth,
  required int quality,
}) async {
  final imageBytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(imageBytes);
  
  if (image == null) throw Exception('Could not decode image');
  
  // Check if webtoon image
  if (WebtoonImageProcessor.isWebtoonImage(image.width, image.height)) {
    // Split into multiple parts
    return await WebtoonImageProcessor.splitTallImage(image);
  } else {
    // Process normally
    return [await _processSingleImage(image, maxWidth, quality)];
  }
}
```

---

### Task 4: Fix Notification Sound Issue
**Priority:** Low (Already Correct!)  
**Complexity:** Low  
**Files to modify:**
- ✅ `lib/services/notification_service.dart` - **ALREADY CORRECTLY IMPLEMENTED**

#### Status: VERIFIED CORRECT ✅
**IMPORTANT:** After code analysis, the notification sound implementation is **ALREADY CORRECT**!

**Current Implementation (Android-only project):**
- ✅ `showDownloadStarted()` (line 742): `Importance.low` = **NO SOUND**
- ✅ `updateDownloadProgress()` (line 793): `Importance.low` = **NO SOUND**  
- ✅ `showDownloadCompleted()` (line 867): `Importance.defaultImportance` = **WITH SOUND**
- ✅ `showDownloadError()` (line 917): `Importance.defaultImportance` = **WITH SOUND**

**Why it works:**
- Android notification sound is controlled by `Importance` level, NOT `playSound` parameter
- `Importance.low` = No sound, no vibration, appears minimized
- `Importance.defaultImportance` = Default sound notification
- iOS code exists (`presentSound: true/false`) but is **NOT USED** (Android-only project)

#### Todo List (Optional Enhancements):
- [ ] Remove unused iOS notification code to reduce confusion
  - [ ] Clean up `DarwinNotificationDetails` from Android-only project
  - [ ] Add comment explaining Android-only implementation
- [ ] Add user preference for notification sounds (future enhancement)
  - [ ] Settings option: "Download notification sounds" (On/Off)
  - [ ] Respect system notification settings
  - [ ] Save preference in shared preferences
- [ ] Test notification behavior
  - [ ] Verify NO sound on progress updates ✅ (already correct)
  - [ ] Verify sound on completion ✅ (already correct)
  - [ ] Test with Do Not Disturb mode
  - [ ] Test with app in background

**Technical Note (Android-only):**
- Sound controlled via `importance` parameter in `AndroidNotificationDetails`
- No `playSound` parameter needed - importance level handles it
- `Importance.low` = silent updates (perfect for progress)
- `Importance.defaultImportance` = audible notifications (perfect for completion)

**Current Implementation (ALREADY CORRECT for Android-only):**
```dart
// notification_service.dart - Current Android implementation

// ✅ Download started - NO sound (Importance.low)
Future<void> showDownloadStarted({
  required String contentId,
  required String title,
}) async {
  await _notificationsPlugin.show(
    notificationId,
    _getLocalized('downloadStarted', fallback: 'Download Started'),
    _getLocalized('downloadingWithTitle', args: {'title': _truncateTitle(title)}),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low, // ✅ NO SOUND - Already correct!
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
      ),
      iOS: const DarwinNotificationDetails(
        // This code exists but is NOT USED (Android-only project)
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    ),
    payload: contentId,
  );
}

// ✅ Download progress - NO sound (Importance.low)
Future<void> updateDownloadProgress({
  required String contentId,
  required int progress,
  required String title,
  bool isPaused = false,
}) async {
  await _notificationsPlugin.show(
    notificationId,
    statusText,
    _truncateTitle(title),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low, // ✅ NO SOUND - Already correct!
        priority: Priority.low,
        ongoing: !isPaused,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        // ... action buttons
      ),
      iOS: const DarwinNotificationDetails(
        // NOT USED (Android-only project)
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    ),
    payload: contentId,
  );
}

// ✅ Download completed - WITH sound (Importance.defaultImportance)
Future<void> showDownloadCompleted({
  required String contentId,
  required String title,
  required String downloadPath,
}) async {
  await _notificationsPlugin.show(
    notificationId,
    _getLocalized('downloadComplete', fallback: 'Download Complete'),
    _getLocalized('downloadedWithTitle', args: {'title': _truncateTitle(title)}),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.defaultImportance, // ✅ WITH SOUND - Already correct!
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
        actions: [
          AndroidNotificationAction('open', 'Open', showsUserInterface: true),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        // NOT USED (Android-only project)
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: contentId,
  );
}
```

**Why Current Implementation is Correct:**
1. Android notification sounds are controlled by `Importance` level
2. `Importance.low` = No sound or vibration (perfect for progress updates)
3. `Importance.defaultImportance` = System default notification sound (perfect for completion)
4. No need for `playSound` parameter - `importance` handles everything
5. iOS code exists but is never executed (Android-only project)

---

### Task 5: Improve Offline Screen UI
**Priority:** Medium  
**Complexity:** Medium  
**Files to modify:**
- `lib/presentation/pages/offline/offline_content_screen.dart`
- `lib/presentation/widgets/content_card_widget.dart`
- `lib/presentation/widgets/offline_content_shimmer.dart`

#### Todo List:
- [ ] Enhance ContentCard widget
  - [ ] Add overlay action buttons (PDF, Delete, Share)
  - [ ] Show download date and size
  - [ ] Add quality indicator badge
  - [ ] Improve thumbnail loading states
  - [ ] Add hero animation to reader transition
- [ ] Improve AppBar
  - [ ] Add filter/sort options
  - [ ] Show total storage used prominently
  - [ ] Add search functionality improvements
  - [ ] Settings/preferences quick access
- [ ] Add empty state illustration
  - [ ] Better empty state design
  - [ ] Helpful tips for first-time users
  - [ ] Quick action to go to downloads
- [ ] Add sorting and filtering
  - [ ] Sort by: Date, Name, Size, Pages
  - [ ] Filter by: Tags, Date range, Size range
  - [ ] Save sort/filter preferences
- [ ] Improve grid/list view
  - [ ] Add view mode toggle (grid/list)
  - [ ] Adaptive grid columns based on screen size
  - [ ] Better spacing and padding
  - [ ] Smooth animations
- [ ] Add batch operations UI
  - [ ] Selection mode with checkboxes
  - [ ] Floating action bar for batch actions
  - [ ] Select all / Deselect all
  - [ ] Batch PDF generation
- [ ] Performance optimizations
  - [ ] Implement lazy loading for large libraries
  - [ ] Image caching strategy
  - [ ] Smooth scroll performance
  - [ ] Reduce rebuild overhead

**Design Principles:**
- Follow Material 3 design guidelines
- Use app's existing color scheme and typography
- Maintain consistency with Downloads Screen
- Prioritize accessibility (screen readers, contrast)
- Smooth, polished animations

**UI Improvements:**
```dart
// Enhanced ContentCard with overlay actions
class EnhancedContentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Thumbnail
          Hero(
            tag: 'content-${content.id}',
            child: ContentThumbnail(content: content),
          ),
          
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content.title, style: TextStyle(color: Colors.white)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.photo, size: 14, color: Colors.white70),
                      Text('${content.pageCount} pages'),
                      SizedBox(width: 12),
                      Icon(Icons.storage, size: 14, color: Colors.white70),
                      Text(formatSize(content.size)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons overlay
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton.filled(
                  icon: Icon(Icons.picture_as_pdf),
                  onPressed: () => onGeneratePdf?.call(),
                  tooltip: 'Generate PDF',
                ),
                SizedBox(width: 4),
                IconButton.filled(
                  icon: Icon(Icons.delete),
                  onPressed: () => onDelete?.call(),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
          
          // Quality badge
          if (content.hasHighQuality)
            Positioned(
              top: 8,
              left: 8,
              child: Chip(
                label: Text('HQ'),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### Task 6: Revamp Reading Mode - Comprehensive Improvement
**Priority:** 🔥 High (User Priority!)  
**Complexity:** High  
**Estimated Time:** 2-3 days

**Files to modify:**
- `lib/presentation/pages/reader/reader_screen.dart`
- `lib/presentation/widgets/extended_image_reader_widget.dart`
- `lib/presentation/cubits/reader/reader_cubit.dart`
- `lib/core/utils/webtoon_detector.dart` (NEW)

#### 📌 User Feedback

> "Kayanya reading screen ini perlu di revamp atau di ubah agar jadi lebih nyaman lagi ketika baca. saya sendiri sukanya hanya ada di fitur scroll kebawah ajah seperti pada image `screenshots/flutter_12.png` cuman jadi kendala ketika bertemu dengan image webtoon saja."

**Current Issues Identified:**

1. **❌ Inaccurate Scroll Tracking** (Line 145-160)
   - Uses fixed approximation: `screenHeight * 0.9`
   - Doesn't account for variable image heights
   - Current page tracking often inaccurate

2. **❌ Poor Webtoon Image Handling**
   - Tall images (AR > 2.5) too long in continuous scroll
   - No special rendering for webtoon
   - Bad UX for Korean webtoons (1275×16383px)

3. **❌ No Variable Height Support**
   - Assumes all images same height
   - No caching of actual rendered heights
   - Performance issues with mixed content

4. **❌ Limited Preloading Strategy**
   - Basic prefetch with fixed count
   - Not adaptive based on scroll velocity
   - Memory not optimized

#### 🎯 4-Phase Improvement Strategy

**Phase 1: Variable Height Support** (Day 1-2)
- Add `_imageHeights` Map cache to track actual dimensions
- Implement `_onImageLoaded(int pageIndex, Size imageSize)` callback
- Calculate rendered height: `screenWidth * aspectRatio`
- Update `_onScrollChanged()` to use cached heights instead of approximation
- Add fallback for uncached heights
- Test with mixed content (normal + webtoon images)

**Phase 2: Webtoon Detection & Handling** (Day 3-4)
- Create `lib/core/utils/webtoon_detector.dart` utility
- Implement `isWebtoon(Size imageSize)` with AR > 2.5 threshold
- Update `ExtendedImageReaderWidget._getBoxFit()` logic
- Apply `BoxFit.fitWidth` for detected webtoons automatically
- Optional: Add visual webtoon badge
- Test with actual webtoon (1275×16383px verified from project)

**Phase 3: Adaptive Preloading** (Day 5)
- Track scroll velocity in `_onScrollChanged()`
- Implement velocity-based prefetch count calculation
  - Slow scroll (< 100 px/s): prefetch 2 pages
  - Normal scroll (100-500 px/s): prefetch 5 pages
  - Fast scroll (> 500 px/s): prefetch 8 pages
- Add `_cleanupPrefetchCache()` for memory management
- Smart cleanup: remove pages outside current ±10 range

**Phase 4: Performance Optimization** (Day 6-7)
- Add `RepaintBoundary` to isolate image repaints
- Implement scroll event debouncing (100ms)
- Use `AutomaticKeepAliveClientMixin` for recent pages (optional)
- Profile with DevTools to measure improvements
- Target: 60fps sustained, < 200MB for 100 pages

#### 📊 Success Metrics

**Performance Targets:**
- ✅ Scroll accuracy: 100% (no off-by-one errors)
- ✅ Frame rate: 60fps sustained during scroll
- ✅ Jank: < 5 frames dropped per scroll session
- ✅ Memory: < 200MB peak for 100 pages
- ✅ Cache hit rate: > 90% for prefetched images

**User Experience Goals:**
- ✅ Webtoon images fit screen width automatically
- ✅ No horizontal scrolling needed
- ✅ Smooth continuous scroll regardless of image sizes
- ✅ Accurate page tracking at all scroll speeds

#### 🧪 Testing Checklist
- [ ] Test with normal manga images (AR = 1.42)
- [ ] Test with actual webtoon (1275×16383px, AR = 12.85)
- [ ] Test with mixed content (3 normal + 3 webtoon)
- [ ] Test slow scrolling (page tracking accuracy)
- [ ] Test fast scrolling (preload effectiveness)
- [ ] Test memory usage with 100+ pages
- [ ] Test offline mode functionality
- [ ] Test on low-end Android devices
- [ ] Profile with DevTools Performance tab
- [ ] Profile with DevTools Memory tab

For detailed implementation roadmap, see CHECKLIST.md Task 6.

---

## 🧪 Testing Strategy

### Unit Tests
- [ ] `OfflineContentManager.deleteOfflineContent()` - all cases
- [ ] `WebtoonImageProcessor.isWebtoonImage()` - various aspect ratios
- [ ] `WebtoonImageProcessor.splitTallImage()` - edge cases
- [ ] Notification sound settings - all notification types

### Integration Tests
- [ ] PDF generation from offline content - end to end
- [ ] Delete offline content - with confirmation flow
- [ ] Webtoon PDF generation - tall image splitting
- [ ] Notification sounds - verify correct behavior
- [ ] Reading mode - scroll tracking accuracy

### Manual Testing
- [ ] Test on multiple devices (phone, tablet)
- [ ] Test on both iOS and Android
- [ ] Test with large offline libraries (100+ items)
- [ ] Test with very tall webtoon images (>15000px)
- [ ] Test notification behavior in various app states
- [ ] Test UI responsiveness and animations
- [ ] Test offline deletion during active reading
- [ ] Test PDF generation during low storage

### Performance Testing
- [ ] Memory usage during webtoon image splitting
- [ ] Scroll performance with 100+ cached images
- [ ] PDF generation speed for large libraries
- [ ] UI responsiveness during batch operations

---

## 📚 References & Documentation

### Flutter Local Notifications (Android)
- **Sound Control:** Controlled by `Importance` level, NOT `playSound` parameter
- **Importance.low:** No sound, no vibration, minimized notification (perfect for progress)
- **Importance.defaultImportance:** Default notification sound (perfect for start/completion)
- **Importance.high:** High priority with sound
- **Best Practice:** Use `Importance.low` for progress updates, `Importance.defaultImportance` or higher for completion
- **Note:** This project is Android-only, iOS code exists but is not used

### Dart PDF Package
- **Image Handling:** Use `pw.Image` with `pw.MemoryImage`
- **Page Layout:** Set `margin: EdgeInsets.all(0)` for full-page images
- **Fit:** Use `pw.BoxFit.contain` to maintain aspect ratio

### Image Package
- **Crop:** Use `img.copyCrop()` for image splitting
- **Resize:** Use `img.copyResize()` with `interpolation: img.Interpolation.linear`
- **Memory:** Release original image after processing to free memory

### Flutter Best Practices
- **State Management:** Use Cubit for local state, Bloc for complex logic
- **Dependency Injection:** Register all services in GetIt
- **Error Handling:** Use try-catch with specific exception types
- **Logging:** Use logger package with appropriate log levels

---

## 🚀 Implementation Order (Recommended)

1. **✅ Task 4 - Notification Sounds** (ALREADY CORRECT!)
   - Current implementation is correct: `Importance.low` for progress, `Importance.defaultImportance` for completion
   - Optional: Clean up unused iOS code
   - No action required unless adding user preferences

2. **Task 2 - Add Delete Feature** (High Priority, Medium Complexity)
   - Core functionality
   - Needed for storage management
   - Foundation for batch operations

3. **Task 1 - Move PDF to Offline Screen** (High Priority, Medium Complexity)
   - Key UX improvement
   - Reuses existing PDF logic
   - Depends on delete feature for context menu

4. **Task 3 - Webtoon PDF Handling** (High Priority, High Complexity)
   - Critical for proper PDF generation
   - More complex, needs careful testing
   - Can be developed in parallel
   - **VERIFIED:** Normal image 902×1280 (AR=1.42), Webtoon 1275×16383 (AR=12.85)
   - **STRATEGY:** Slice webtoon into ~13 chunks of 1260px each

5. **Task 6 - Fix Reading Mode** (High Priority, High Complexity)
   - Better reading experience
   - Complex scroll calculations
   - Needs webtoon detection logic

6. **Task 5 - Improve UI** (Medium Priority, Medium Complexity)
   - Polish and refinement
   - Can be iterative
   - Last for final touches

---

## ⚠️ Important Notes

### Storage Permissions
- Always check storage permissions before delete operations
- Handle permission denied gracefully
- Prompt user to grant permissions with clear explanation

### Background Processing
- Use isolates for heavy PDF processing
- Don't block UI thread during image splitting
- Show progress indicators for long operations

### Error Handling
- Always catch and log exceptions
- Show user-friendly error messages
- Provide retry mechanisms for failed operations
- Log errors with sufficient context for debugging

### Memory Management
- Release image resources after processing
- Use `compute()` for CPU-intensive operations
- Monitor memory usage during batch operations
- Implement pagination for large lists

### User Experience
- Show loading states for all async operations
- Provide undo option for destructive actions
- Use optimistic updates where appropriate
- Smooth animations and transitions

---

## 🔄 Progress Tracking

### Task 1: Move PDF to Offline Screen
- [ ] Todo 1: Add context menu
- [ ] Todo 2: Integrate PdfConversionService
- [ ] Todo 3: Add PDF button
- [ ] Todo 4: Test PDF generation

### Task 2: Add Delete Feature
- [ ] Todo 1: Create confirmation dialog
- [ ] Todo 2: Implement delete logic
- [ ] Todo 3: Add delete action
- [ ] Todo 4: Bulk delete
- [ ] Todo 5: Handle edge cases
- [ ] Todo 6: Update storage stats

### Task 3: Webtoon PDF Handling
- [ ] Todo 1: Detect webtoon images
- [ ] Todo 2: Implement splitting
- [ ] Todo 3: Add configuration
- [ ] Todo 4: Update PDF creation
- [ ] Todo 5: Test various types
- [ ] Todo 6: Optimize memory

### Task 4: Fix Notification Sounds
- [ ] Todo 1: Identify notification types
- [ ] Todo 2: Update notification methods
- [ ] Todo 3: Test on iOS and Android
- [ ] Todo 4: Add user preference

### Task 5: Improve UI
- [ ] Todo 1: Enhance ContentCard
- [ ] Todo 2: Improve AppBar
- [ ] Todo 3: Empty state
- [ ] Todo 4: Sorting/filtering
- [ ] Todo 5: Grid/list view
- [ ] Todo 6: Batch operations UI
- [ ] Todo 7: Performance optimization

### Task 6: Fix Reading Mode
- [ ] Todo 1: Analyze bug
- [ ] Todo 2: Fix scroll calculation
- [ ] Todo 3: Improve image widget
- [ ] Todo 4: Add webtoon mode
- [ ] Todo 5: Fix scroll tracking
- [ ] Todo 6: Performance optimization
- [ ] Todo 7: Test with real content

---

## 🎓 Learning Resources

### MCP Sequential Thinking
Use for complex problem-solving and debugging:
- Breaking down webtoon image splitting logic
- Analyzing scroll calculation issues
- Debugging notification sound behavior

### Context7 Documentation
Reference for API usage:
- flutter_local_notifications API
- dart_pdf package features
- image package methods

### Docfork Search
Search for specific implementation examples:
- Flutter notification sound control
- PDF image handling
- Image splitting techniques

---

## ✅ Definition of Done

A task is considered complete when:
- [ ] All code is implemented and follows project style guidelines
- [ ] Unit tests are written and passing
- [ ] Integration tests are passing
- [ ] Manual testing completed on iOS and Android
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] No regressions in existing functionality
- [ ] Performance is acceptable (no jank, smooth animations)
- [ ] Error handling is comprehensive
- [ ] Logging is adequate for debugging
- [ ] User experience is polished

---

## 📝 Notes & Observations

### Date: 2025-11-27
- Created comprehensive implementation plan
- Analyzed current codebase structure with actual code review
- Identified key issues and solutions
- Prioritized tasks based on impact and complexity
- Established testing strategy
- Set up progress tracking system
- **VERIFIED:** Notification implementation is ALREADY CORRECT (Android-only, uses Importance levels)
- **ANALYZED:** Actual webtoon image dimensions (12.85 aspect ratio vs normal 1.42)
- **DOCUMENTED:** Exact offline content path structure from `offline_content_manager.dart`

### Known Issues (VERIFIED from code analysis)
1. **flutter_bug_01.png** - Need to examine this file to understand specific reading mode bug
2. **✅ Notification Sound** - **ALREADY CORRECT!** Uses `Importance.low` (no sound) for progress
3. **Webtoon PDFs** - May create very large file sizes without splitting (16383px height!)
4. **Offline Delete** - No current implementation
5. **PDF from Offline** - Only available in Downloads Screen

### Path Structure (VERIFIED from offline_content_manager.dart)
- Primary path: `[basePath]/nhasix/[contentId]/images/page_XXX.jpg`
- Smart Download folder detection (Download/Downloads/Unduhan)
- Multiple fallback paths for robustness
- Old structure support: `[basePath]/nhasix/[contentId]/page_XXX.jpg`

### Webtoon Analysis (VERIFIED from actual images)
- Normal image: 902×1280px, aspect ratio = **1.42**
- Webtoon image: 1275×16383px, aspect ratio = **12.85** (EXTREME!)
- Detection threshold: AR > 2.5
- Slicing strategy: Target 1260px chunks → ~13 pages per webtoon

### Future Enhancements (Not in scope)
- Cloud sync for offline content
- Automatic PDF generation on download complete
- PDF compression options
- Reading statistics tracking
- Content recommendations based on reading history

---

**Last Updated:** 2025-11-27  
**Next Review:** After completing Task 4 (Quick Win)
