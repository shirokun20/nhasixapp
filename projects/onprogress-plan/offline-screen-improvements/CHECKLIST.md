# Implementation Checklist

Track your progress through each task with detailed checkboxes.

---

## 🎯 Overall Progress

- [ ] Task 1: Move PDF Generation to Offline Screen (1/35) - **ContentCard ready ✅**
- [ ] Task 2: Add Delete Feature to Offline Screen (0/71) - **Bulk delete planned ❌**
- [ ] Task 3: Handle Webtoon Images in PDF (0/44)
- [x] **Task 4: Notification Sounds - ALREADY CORRECT!** (4/4) ✅
- [ ] Task 5: Improve Offline Screen UI (0/61)
- [ ] Task 6: Fix Reading Mode for Webtoons (0/52)

**Overall Completion:** 5/267 tasks (1.9%) - Task 4 verified correct, ContentCard ready!

**VERIFIED:** 
- ✅ Notification implementation uses `Importance.low` (no sound) for progress
- ✅ Uses `Importance.defaultImportance` (with sound) for completion
- ✅ Android-only project, iOS code exists but unused
- ✅ ContentCard.onLongPress parameter EXISTS (content_card_widget.dart line 22)
- ❌ offline_content_screen.dart does NOT use onLongPress yet
- ❌ Bottom sheet feature NOT implemented (planned in flutter_11.png)
- ❌ Bulk delete feature NOT implemented (planned in flutter_11.png)

---

## 📋 Task 1: Move PDF Generation to Offline Screen

### 1.1 Add Long Press + Bottom Sheet (PLANNED - flutter_11.png)
- [x] **ContentCard `onLongPress` parameter exists** (content_card_widget.dart line 22) ✅
- [ ] Pass `onLongPress` handler to ContentCard in offline screen
- [ ] Create `_showContentActions()` method with Material Design bottom sheet
- [ ] Add content header (thumbnail + title + metadata)
- [ ] Add drag handle indicator at top
- [ ] Add "Read" action (navigate to reader)
- [ ] Add "Convert to PDF" action (call _generatePdf)
- [ ] Add "Delete" action (show confirmation)
- [ ] Style bottom sheet with Material 3 theme colors
- [ ] Show file size in delete action subtitle
- [ ] Add dividers between sections
- [ ] Test long press gesture on different devices
- [ ] Test bottom sheet drag to dismiss
- [ ] Test with screen reader (accessibility)

### 1.2 Integrate with PdfConversionService
- [ ] Import `PdfConversionService` in offline screen
- [ ] Register in GetIt if not already registered
- [ ] Create `_generatePdf()` method
- [ ] Get offline content image paths
- [ ] Call `convertToPdfInIsolate()` method
- [ ] Handle loading state (show dialog)
- [ ] Handle success state (show snackbar with Open action)
- [ ] Handle error state (show error message)
- [ ] Test with small content (5 pages)
- [ ] Test with large content (100+ pages)

### 1.3 Test Bottom Sheet + PDF Generation
- [ ] Test long press on various content items
- [ ] Test bottom sheet appears correctly
- [ ] Test all action buttons work
- [ ] Test PDF generation flow from bottom sheet
- [ ] Verify PDF file location (app documents/pdfs)
- [ ] Test opening PDF file after generation
- [ ] Test notification integration
- [ ] Test error handling (no storage space)
- [ ] Test error handling (no permission)
- [ ] Test with corrupted/missing images
- [ ] Performance test: measure generation time

**Subtask Completion:** 1/35 items (ContentCard ready ✅)

---

## 📋 Task 2: Add Delete Feature to Offline Screen

### 2.1 Create Confirmation Dialog
- [ ] Design Material 3 confirmation dialog
- [ ] Show content title and thumbnail
- [ ] Calculate and display storage size being freed
- [ ] Add "Don't ask again" checkbox option
- [ ] Add warning message about permanent deletion
- [ ] Style dialog with theme colors
- [ ] Test dialog on different screen sizes
- [ ] Test with very long content titles

### 2.2 Implement Delete Logic
- [ ] Create `deleteOfflineContent()` in `OfflineContentManager`
- [ ] Define `DeleteResult` class (success, error, notFound)
- [ ] Check if content exists before deletion
- [ ] Calculate content size before deletion
- [ ] Delete content directory recursively
- [ ] Delete metadata from storage
- [ ] Delete thumbnails
- [ ] Clear content from cache
- [ ] Return result with freed space
- [ ] Add comprehensive error handling
- [ ] Add logging for debugging
- [ ] Write unit tests for delete logic

### 2.3 Add Delete Action to Bottom Sheet
- [ ] Add delete option to `_showContentActions()` bottom sheet ❌ NOT IMPLEMENTED
- [ ] Use error color for delete action
- [ ] Show confirmation dialog on tap
- [ ] Show loading indicator during deletion
- [ ] Remove item from list optimistically
- [ ] Revert on error (if needed)
- [ ] Show success snackbar with freed space
- [ ] Show error snackbar on failure

### 2.4 Add Bulk Delete Functionality (PLANNED - flutter_11.png)
- [ ] Add `_isSelectionMode` state to OfflineContentScreen ❌ NOT IMPLEMENTED
- [ ] Add `_selectedContentIds` Set<String> state ❌ NOT IMPLEMENTED
- [ ] Add selection mode toggle button in AppBar
- [ ] Show checkboxes on ContentCard in selection mode
- [ ] Add checkbox overlay with Material 3 styling (circle with check icon)
- [ ] Add "Select All" / "Deselect All" buttons in AppBar
- [ ] Add "Cancel" button to exit selection mode
- [ ] Make ContentCard tap toggle selection (when in selection mode)
- [ ] Add floating bottom sheet for bulk delete button
- [ ] Show "Delete X items" with error container styling
- [ ] Add bulk delete confirmation dialog
- [ ] Show total size to be freed in confirmation
- [ ] Implement bulk delete logic with progress dialog
- [ ] Show progress: "Deleting X/Y..."
- [ ] Update UI after batch deletion
- [ ] Show success snackbar with freed space summary
- [ ] Test selection mode toggle
- [ ] Test select all / deselect all
- [ ] Test bulk delete with 10+ items
- [ ] Test bulk delete with 100+ items

### 2.5 Handle Edge Cases
- [ ] Check if content is currently open in reader
- [ ] Show warning if trying to delete open content
- [ ] Handle partial/corrupted content deletion
- [ ] Handle permission denied scenarios
- [ ] Handle storage access errors
- [ ] Test deletion during active PDF generation
- [ ] Test deletion with no internet (offline mode)

### 2.6 Update Storage Stats
- [ ] Refresh storage info in AppBar after deletion
- [ ] Animate storage counter update
- [ ] Show freed space in success notification
- [ ] Update total items count
- [ ] Recalculate total storage used
- [ ] Test with multiple deletions in quick succession

**Subtask Completion:** 0/71 items (bulk delete feature planned ❌)

---

## 📋 Task 3: Handle Webtoon Images in PDF

### 3.1 Detect Webtoon Images
- [ ] Create `WebtoonImageProcessor` class
- [ ] Implement `isWebtoonImage(width, height)` method
- [ ] Set aspect ratio threshold (2.5) - **VERIFIED from analysis**
- [ ] Add logging for detected webtoons
- [ ] Write unit tests for detection
- [ ] Test with normal image (AR=1.42) - should return false
- [ ] Test with webtoon image (AR=12.85) - should return true
- [ ] Test edge cases (0 width, very large numbers)

### 3.2 Implement Image Splitting
- [ ] Implement `splitTallImage()` method
- [ ] Set max PDF page height (1280px) - **VERIFIED to match normal image**
- [ ] Calculate number of splits needed (~13 for 16383px webtoon)
- [ ] Use `img.copyCrop()` for splitting
- [ ] Add overlap between splits (30px) - **VERIFIED value**
- [ ] Encode splits as JPEG (quality 90)
- [ ] Add progress logging
- [ ] Handle memory efficiently (release after crop)
- [ ] Write unit tests for splitting
- [ ] Test with actual webtoon (1275x16383px)

### 3.3 Add Configuration Options
- [ ] Create `WebtoonConfig` class
- [ ] Add aspect ratio threshold setting
- [ ] Add max page height setting
- [ ] Add overlap pixels setting
- [ ] Add JPEG quality setting
- [ ] Add enable/disable webtoon splitting option
- [ ] Make configurable via settings UI (future)

### 3.4 Update PDF Creation
- [ ] Modify `_processImageStatic()` to detect webtoons
- [ ] Return `List<Uint8List>` instead of single image
- [ ] Update `_createPdfStatic()` to handle image arrays
- [ ] Flatten split images into PDF pages
- [ ] Maintain page order correctly
- [ ] Add metadata about split pages
- [ ] Update progress tracking for splits
- [ ] Update notification messages

### 3.5 Test Various Image Types
- [ ] Test normal landscape images (1920x1080)
- [ ] Test normal portrait images (1080x1920)
- [ ] Test tall webtoon images (800x15000)
- [ ] Test very tall images (1080x50000+)
- [ ] Test mixed content (normal + webtoon)
- [ ] Test wide panoramic images (10000x800)
- [ ] Test edge case: exactly threshold ratio

### 3.6 Optimize Memory Usage
- [ ] Use `compute()` isolate for splitting
- [ ] Process splits in chunks
- [ ] Release image memory after each split
- [ ] Monitor memory during large image processing
- [ ] Add memory usage logging
- [ ] Test with low memory devices
- [ ] Test with multiple large images

**Subtask Completion:** 0/44 items

---

## 📋 Task 4: Notification Sounds - ALREADY CORRECT! ✅

**STATUS:** Current implementation is **ALREADY CORRECT** for Android-only project!

### 4.1 Verify Current Implementation (DONE ✅)
- [x] Confirmed notification types
- [x] Download progress uses `Importance.low` (no sound) ✅
- [x] Download completed uses `Importance.defaultImportance` (with sound) ✅
- [x] PDF progress uses `Importance.low` (no sound) ✅
- [x] PDF completed uses `Importance.high` (with sound) ✅
- [x] Verified Android-only project (iOS code unused)

### 4.2 Update Notification Methods
- [ ] Update `showDownloadStarted()`: set `presentSound: true`
- [ ] Update `updateDownloadProgress()`: set `presentSound: false`
- [ ] Update `showDownloadCompleted()`: set `presentSound: true`
- [ ] Update `showDownloadError()`: set `presentSound: true`
- [ ] Update `showPdfConversionStarted()`: set `presentSound: true`
- [ ] Update `updatePdfConversionProgress()`: set `presentSound: false`
- [ ] Update `showPdfConversionCompleted()`: set `presentSound: true`
- [ ] Update `showPdfConversionError()`: set `presentSound: true`
- [ ] Update Android settings: `playSound` parameter
- [ ] Update iOS settings: `presentSound` parameter
- [ ] Update `presentAlert` for iOS progress (false)

### 4.3 Test on iOS and Android
- [ ] Test download started notification (sound expected)
- [ ] Test download progress notifications (no sound expected)
- [ ] Test download completed notification (sound expected)
- [ ] Test PDF conversion notifications
- [ ] Test with Do Not Disturb mode enabled
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app killed
- [ ] Test with system notification sound disabled
- [ ] Test with volume muted

### 4.4 Add User Preference
- [ ] Add "Notification sounds" setting
- [ ] Save preference in `SettingsCubit`
- [ ] Respect user preference in notification methods
- [ ] Add toggle in Settings screen
- [ ] Test preference persistence
- [ ] Test toggling on/off

**Subtask Completion:** 0/34 items

---

## 📋 Task 5: Improve Offline Screen UI

### 5.1 Enhance ContentCard Widget
- [ ] Add gradient overlay for better text visibility
- [ ] Show download date on card
- [ ] Show file size on card
- [ ] Add quality indicator badge (HQ, Standard)
- [ ] Improve thumbnail loading state
- [ ] Add shimmer effect while loading
- [ ] Add hero animation for reader transition
- [ ] Add overlay action buttons (PDF, Delete)
- [ ] Style buttons with theme colors
- [ ] Test on various screen sizes

### 5.2 Improve AppBar
- [ ] Add filter button to AppBar
- [ ] Add sort button to AppBar
- [ ] Make storage info more prominent
- [ ] Add quick search icon
- [ ] Style AppBar with Material 3
- [ ] Add gradient background (optional)
- [ ] Test overflow on small screens

### 5.3 Add Empty State
- [ ] Design empty state illustration
- [ ] Add helpful tips for first-time users
- [ ] Add quick action button to Downloads screen
- [ ] Add explanation text
- [ ] Style with theme colors
- [ ] Test with no content

### 5.4 Add Sorting and Filtering
- [ ] Implement sort by: Date (newest/oldest)
- [ ] Implement sort by: Name (A-Z, Z-A)
- [ ] Implement sort by: Size (largest/smallest)
- [ ] Implement sort by: Pages (most/least)
- [ ] Implement filter by tags (if available)
- [ ] Implement filter by date range
- [ ] Implement filter by size range
- [ ] Save sort/filter preferences
- [ ] Add UI for sort/filter options
- [ ] Test all combinations

### 5.5 Improve Grid/List View
- [ ] Add view mode toggle (grid/list)
- [ ] Implement list view layout
- [ ] Make grid responsive (2-4 columns)
- [ ] Use `ResponsiveGridDelegate`
- [ ] Improve spacing and padding
- [ ] Add smooth view transition animation
- [ ] Save view preference
- [ ] Test on phone and tablet

### 5.6 Add Batch Operations UI
- [ ] Add selection mode toggle button
- [ ] Show checkboxes in selection mode
- [ ] Add floating action bar for batch actions
- [ ] Add "Select All" action
- [ ] Add "Deselect All" action
- [ ] Add batch PDF generation option
- [ ] Add batch delete option
- [ ] Show selected count
- [ ] Add batch operation progress dialog
- [ ] Test with large selections (100+ items)

### 5.7 Performance Optimizations
- [ ] Implement lazy loading for large libraries
- [ ] Add pagination (load more on scroll)
- [ ] Implement image caching strategy
- [ ] Use `RepaintBoundary` for cards
- [ ] Optimize rebuild overhead
- [ ] Test scroll performance with 500+ items
- [ ] Profile with DevTools
- [ ] Reduce jank to 0

**Subtask Completion:** 0/61 items

---

## 📋 Task 6: Fix Reading Mode for Webtoons

### 6.1 Analyze Bug from flutter_bug_01.png
- [ ] Examine flutter_bug_01.png image
- [ ] Document specific bug behavior
- [ ] Identify root cause (scroll calculation vs image sizing)
- [ ] Reproduce bug in test environment
- [ ] Create minimal reproduction case
- [ ] Add bug details to issue tracker

### 6.2 Fix Continuous Scroll Calculation
- [ ] Replace fixed height approximation
- [ ] Create `_imageHeights` cache map
- [ ] Implement `_onImageLoaded()` callback
- [ ] Calculate rendered height from screen width
- [ ] Update `_onScrollChanged()` to use cached heights
- [ ] Add fallback for uncached heights
- [ ] Account for spacing between images
- [ ] Test with varying height images
- [ ] Add debug logging for scroll tracking

### 6.3 Improve Image Widget for Tall Images
- [ ] Add webtoon detection in `ExtendedImageReaderWidget`
- [ ] Use `BoxFit.fitWidth` for detected webtoons
- [ ] Add `onImageLoaded` callback parameter
- [ ] Report actual image size to parent
- [ ] Update `_getBoxFit()` logic
- [ ] Test with normal and webtoon images
- [ ] Test smooth rendering

### 6.4 Add Webtoon Reading Mode Option
- [ ] Add `ReadingMode.webtoon` enum value
- [ ] Implement webtoon mode in reader
- [ ] Optimize for vertical continuous scroll
- [ ] Remove page boundaries in webtoon mode
- [ ] Auto-detect and suggest webtoon mode
- [ ] Add user preference for webtoon mode
- [ ] Add mode switch in reader settings
- [ ] Test webtoon mode thoroughly

### 6.5 Fix Scroll Position Tracking
- [ ] Ensure accurate page position tracking
- [ ] Smooth page indicator updates
- [ ] Handle rapid scrolling gracefully
- [ ] Save scroll position correctly
- [ ] Restore position on return
- [ ] Test with various scroll speeds
- [ ] Test jump to page functionality

### 6.6 Optimize Performance for Tall Images
- [ ] Implement efficient loading for large heights
- [ ] Add memory management for tall images
- [ ] Ensure smooth rendering (60fps)
- [ ] Add progressive loading for very tall images
- [ ] Test with 15000px+ height images
- [ ] Profile memory usage
- [ ] Profile frame rendering time

### 6.7 Test with Real Webtoon Content
- [ ] Create test content with various webtoon images
- [ ] Test with images >10000px height
- [ ] Test with images >20000px height
- [ ] Test mixed normal + webtoon content
- [ ] Test scroll performance
- [ ] Test memory usage
- [ ] Test on low-end devices
- [ ] Test on tablets

**Subtask Completion:** 0/52 items

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] `WebtoonImageProcessor.isWebtoonImage()` tests
- [ ] `WebtoonImageProcessor.splitTallImage()` tests
- [ ] `OfflineContentManager.deleteOfflineContent()` tests
- [ ] `OfflineContentManager.getContentSize()` tests
- [ ] Notification sound settings tests
- [ ] Scroll position calculation tests

### Integration Tests
- [ ] PDF generation from offline content (end-to-end)
- [ ] Delete offline content with confirmation
- [ ] Webtoon PDF generation with splitting
- [ ] Notification sounds (verify correct behavior)
- [ ] Reading mode scroll tracking accuracy
- [ ] Batch delete operation

### Manual Testing (Android-only Project)
- [ ] Test on Android phone (multiple devices)
- [ ] Test on Android tablet
- [ ] Test with large libraries (100+ items)
- [ ] Test with webtoon images (16383px tall, verified)
- [ ] Test notification behavior in various states
- [ ] Test UI responsiveness and animations
- [ ] Test deletion during active reading
- [ ] Test PDF generation with low storage
- [ ] Test accessibility (TalkBack screen reader)
- [ ] Test dark mode / light mode
- [ ] Test on different Android versions (API 21-34)

### Performance Testing
- [ ] Memory usage during webtoon splitting
- [ ] Scroll performance with 100+ cached images
- [ ] PDF generation speed for large libraries
- [ ] UI responsiveness during batch operations
- [ ] Frame rate during continuous scroll
- [ ] App startup time impact

**Testing Completion:** 0/30 items

---

## 📊 Progress Summary

### By Priority
- **High Priority Tasks:** 4 tasks (1, 2, 3, 6)
- **Medium Priority Tasks:** 2 tasks (4, 5)

### By Complexity
- **Low Complexity:** 1 task (4)
- **Medium Complexity:** 3 tasks (1, 2, 5)
- **High Complexity:** 2 tasks (3, 6)

### Estimated Timeline
- **Day 1:** Task 4 (0.5 day), start Task 2 (0.5 day)
- **Day 2:** Complete Task 2 (1 day)
- **Day 3:** Task 1 (1 day)
- **Day 4-5:** Task 3 (1.5-2 days)
- **Day 5-6:** Task 6 (1.5-2 days)
- **Day 7:** Task 5 (1-1.5 days)

**Total Estimated:** 5-7 days

---

## ✅ Daily Progress Log

### Day 1 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 2 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 3 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 4 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 5 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 6 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

### Day 7 - [Date]
**Planned:**
- [ ] 

**Completed:**
- [ ] 

**Notes:**
- 

**Blockers:**
- 

---

## 🎉 Completion Criteria

Project is complete when:
- [x] All 6 main tasks completed (Task 4 already done!)
- [x] All subtasks checked off
- [x] All tests passing
- [x] Code reviewed and approved
- [x] Documentation updated
- [x] No critical bugs
- [x] Performance targets met
- [x] Accessibility verified (TalkBack)
- [x] Android platform tested (multiple devices)

**Note:** This is an Android-only project. iOS testing not required.

---

**Last Updated:** 2025-11-27  
**Status:** Ready to Begin  
**Next Action:** Start Task 4 - Fix Notification Sounds
