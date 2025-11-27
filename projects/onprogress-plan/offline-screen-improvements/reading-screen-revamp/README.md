# Reading Screen Revamp - Comprehensive Plan

## 📌 Overview

**Objective:** Revamp reading screen untuk memberikan experience yang lebih nyaman, terutama untuk continuous scroll mode dengan proper handling untuk webtoon (tall) images.

**Current Branch:** `feature/reading-screen-revamp`  
**Created:** 2025-11-27  
**Status:** Planning Phase

---

## 🎯 Problem Statement

### User Feedback
> "Kayanya reading screen ini perlu di revamp atau di ubah agar jadi lebih nyaman lagi ketika baca. saya sendiri sukanya hanya ada di fitur scroll kebawah ajah seperti pada image `screenshots/flutter_12.png` cuman jadi kendala ketika bertemu dengan image webtoon saja."

### Current Issues

1. **❌ Inaccurate Scroll Tracking**
   - Uses fixed approximation: `screenHeight * 0.9`
   - Tidak memperhitungkan variabel image heights
   - Current page tracking sering tidak akurat

2. **❌ Poor Webtoon Image Handling**
   - Tall images (AR > 2.5) terlalu panjang di continuous scroll
   - Tidak ada special rendering untuk webtoon
   - User experience buruk untuk Korean webtoons

3. **❌ No Variable Height Support**
   - Assumes all images sama tinggi
   - Tidak cache actual rendered heights
   - Performance issues dengan mixed content

4. **❌ Limited Preloading Strategy**
   - Basic prefetch dengan fixed count
   - Tidak adaptive based on scroll velocity
   - Memory tidak optimal

---

## 🔍 Research: Popular Manga Readers

### 1. MangaDex (Web-based)
**URL:** https://mangadex.org

**Key Features:**
- ✅ Smooth continuous scroll dengan lazy loading
- ✅ Auto-fit images ke screen width
- ✅ Progressive image loading (blur → full quality)
- ✅ Infinite scroll dengan preload 3-5 pages ahead
- ✅ Keyboard shortcuts untuk quick navigation
- ✅ Reader settings: Fit width, Fit height, Original size

**UX Strengths:**
- Sangat smooth scrolling bahkan dengan network lambat
- Progressive loading memberikan instant feedback
- Automatic preloading membuat reading tanpa interruption

### 2. Tachiyomi (Android App)
**GitHub:** https://github.com/tachiyomiorg/tachiyomi

**Key Features:**
- ✅ Multiple reading modes: Continuous vertical, Paged (L-R), Paged (R-L), Webtoon
- ✅ **Webtoon Mode:** Specialized untuk tall images
  - Auto-detect berdasarkan aspect ratio
  - Split tall images jadi chunks
  - Smooth continuous scroll
- ✅ Image caching strategy dengan LRU
- ✅ Adaptive preloading based on reading speed
- ✅ Zoom controls dengan double-tap

**UX Strengths:**
- Mode switching smooth tanpa reload
- Webtoon mode sangat optimal untuk tall images
- Caching strategy membuat offline reading smooth
- Adaptive preloading hemat bandwidth

### 3. Webtoon (Official App)
**Website:** https://www.webtoons.com

**Key Features:**
- ✅ Pure vertical scroll optimized untuk webtoon
- ✅ Lazy loading dengan placeholder shimmer
- ✅ Gesture controls (swipe untuk prev/next chapter)
- ✅ Auto-save reading position
- ✅ Smooth transitions between episodes

**UX Strengths:**
- Specialized untuk vertical content
- Very smooth scrolling performance
- Instant page position restore
- Clean, distraction-free reading

### 4. Best Practices Summary

**From Research:**

1. **Variable Height Support** ✅
   - Track actual rendered heights
   - Cache height data per image
   - Use for accurate scroll position

2. **Webtoon Detection** ✅
   - Aspect Ratio > 2.5 = webtoon
   - Auto-switch rendering strategy
   - fitWidth untuk tall images

3. **Preloading Strategy** ✅
   - Adaptive: 3-5 pages ahead based on scroll velocity
   - Prefetch on idle using IntersectionObserver
   - Progressive: placeholder → thumbnail → full quality

4. **Smooth Scrolling** ✅
   - Use BouncingScrollPhysics (already ✅)
   - Debounce scroll events
   - Optimize rebuilds dengan RepaintBoundary

5. **Image Optimization** ✅
   - Cache decoded images
   - Use appropriate BoxFit per image type
   - Progressive loading untuk better UX

---

## 📊 Current Implementation Analysis

### File: `lib/presentation/pages/reader/reader_screen.dart`

**Current Reading Modes:**
```dart
enum ReadingMode {
  singlePage,      // Horizontal paged (manga)
  verticalPage,    // Vertical paged
  continuousScroll // Continuous vertical (preferred by user)
}
```

**Current Continuous Scroll Implementation:**
```dart
// Line 582-591
Widget _buildContinuousReader(ReaderState state) {
  return GestureDetector(
    onTapUp: (details) => _readerCubit.toggleUI(),
    child: ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(), // ✅ Good!
      itemCount: state.content?.imageUrls.length ?? 0,
      itemBuilder: (context, index) {
        final imageUrl = state.content?.imageUrls[index] ?? '';
        return _buildImageViewer(imageUrl, index + 1, isContinuous: true);
      },
    ),
  );
}
```

**Issues Identified:**

1. **Line 145-160: Scroll Tracking**
```dart
void _onScrollChanged() {
  final state = _readerCubit.state;
  if (state.readingMode == ReadingMode.continuousScroll && state.content != null) {
    final screenHeight = MediaQuery.of(context).size.height;
    final approximateItemHeight = screenHeight * 0.9; // ❌ FIXED VALUE!
    final currentScrollPage = (_scrollController.offset / approximateItemHeight).floor() + 1;
    
    if (currentScrollPage != _lastReportedPage) {
      _lastReportedPage = currentScrollPage;
      _readerCubit.updateCurrentPage(currentScrollPage);
    }
  }
}
```

**Problems:**
- ❌ Uses fixed approximation `screenHeight * 0.9`
- ❌ Doesn't work dengan variabel image heights
- ❌ Inaccurate untuk webtoon images (tall)
- ❌ No caching of actual heights

2. **Line 610-623: Image Rendering**
```dart
return isContinuous
  ? Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExtendedImageReaderWidget(
        imageUrl: imageUrl,
        contentId: widget.contentId,
        pageNumber: pageNumber,
        readingMode: ReadingMode.continuousScroll,
        enableZoom: enableZoom,
      ),
    )
  : ExtendedImageReaderWidget(...);
```

**Problems:**
- ❌ No height tracking callback
- ❌ Same rendering untuk normal dan webtoon images
- ❌ No special handling untuk tall images

---

## ✅ Improvement Strategy

### Phase 1: Accurate Scroll Tracking

**Goal:** Implement variable height support dengan actual dimension tracking

**Implementation:**

1. **Add Image Dimension Cache**
```dart
class _ReaderScreenState extends State<ReaderScreen> {
  // ✅ NEW: Cache actual image heights
  final Map<int, double> _imageHeights = {};
  
  /// Called when image is loaded with actual dimensions
  void _onImageLoaded(int pageIndex, Size imageSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = imageSize.height / imageSize.width;
    final renderedHeight = screenWidth * aspectRatio;
    
    setState(() {
      _imageHeights[pageIndex] = renderedHeight;
    });
  }
}
```

2. **Update Scroll Tracking**
```dart
void _onScrollChanged() {
  final state = _readerCubit.state;
  if (state.readingMode == ReadingMode.continuousScroll && state.content != null) {
    final scrollPosition = _scrollController.offset;
    int currentPage = 1;
    double accumulatedHeight = 0;
    
    // ✅ Use cached heights for accuracy
    for (int i = 0; i < state.content!.pageCount; i++) {
      final imageHeight = _imageHeights[i] ?? MediaQuery.of(context).size.height;
      const spacing = 8.0; // Container margin
      final totalItemHeight = imageHeight + spacing;
      
      if (scrollPosition >= accumulatedHeight && 
          scrollPosition < accumulatedHeight + totalItemHeight) {
        currentPage = i + 1;
        break;
      }
      
      accumulatedHeight += totalItemHeight;
    }
    
    if (currentPage != _lastReportedPage) {
      _lastReportedPage = currentPage;
      _readerCubit.updateCurrentPage(currentPage);
    }
  }
}
```

3. **Update ExtendedImageReaderWidget**
```dart
// Add callback parameter
ExtendedImageReaderWidget(
  imageUrl: imageUrl,
  contentId: widget.contentId,
  pageNumber: pageNumber,
  readingMode: ReadingMode.continuousScroll,
  enableZoom: enableZoom,
  onImageLoaded: (Size size) => _onImageLoaded(pageNumber - 1, size), // ✅ NEW
)
```

### Phase 2: Webtoon Detection & Handling

**Goal:** Auto-detect webtoon images dan apply special rendering

**Implementation:**

1. **Webtoon Detector Utility**
```dart
// lib/core/utils/webtoon_detector.dart
class WebtoonDetector {
  /// Threshold berdasarkan analysis: Normal=1.42, Webtoon=12.85
  static const double ASPECT_RATIO_THRESHOLD = 2.5;
  
  /// Detect if image is webtoon-style (extremely tall)
  static bool isWebtoon(Size imageSize) {
    if (imageSize.width == 0) return false;
    final aspectRatio = imageSize.height / imageSize.width;
    return aspectRatio > ASPECT_RATIO_THRESHOLD;
  }
}
```

2. **Update ExtendedImageReaderWidget BoxFit Logic**
```dart
BoxFit _getBoxFit(Size? imageSize) {
  // ✅ Auto-detect webtoon and use fitWidth
  if (imageSize != null && WebtoonDetector.isWebtoon(imageSize)) {
    return BoxFit.fitWidth; // Always fit width for webtoons
  }
  
  // Default behavior based on reading mode
  switch (widget.readingMode) {
    case ReadingMode.singlePage:
      return BoxFit.contain;
    case ReadingMode.verticalPage:
    case ReadingMode.continuousScroll:
      return BoxFit.fitWidth; // Better for continuous reading
  }
}
```

3. **Visual Indicator untuk Webtoon Mode** (Optional)
```dart
// Show webtoon badge when tall image detected
if (WebtoonDetector.isWebtoon(imageSize)) {
  return Stack(
    children: [
      // Image
      ExtendedImage(...),
      
      // Webtoon badge (optional)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('WEBTOON', style: TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ),
    ],
  );
}
```

### Phase 3: Advanced Preloading

**Goal:** Implement adaptive preloading strategy

**Implementation:**

1. **Velocity-Based Prefetch**
```dart
class _ReaderScreenState extends State<ReaderScreen> {
  // Track scroll velocity
  double _lastScrollOffset = 0;
  DateTime _lastScrollTime = DateTime.now();
  double _scrollVelocity = 0; // pixels per second
  
  void _onScrollChanged() {
    final now = DateTime.now();
    final offset = _scrollController.offset;
    final duration = now.difference(_lastScrollTime).inMilliseconds;
    
    if (duration > 0) {
      _scrollVelocity = (offset - _lastScrollOffset) / (duration / 1000);
    }
    
    _lastScrollOffset = offset;
    _lastScrollTime = now;
    
    // Adaptive prefetch count based on velocity
    final prefetchCount = _calculatePrefetchCount(_scrollVelocity);
    _prefetchImages(prefetchCount);
  }
  
  int _calculatePrefetchCount(double velocity) {
    // Slower scroll = less prefetch
    if (velocity.abs() < 100) return 2;
    // Normal scroll = normal prefetch
    if (velocity.abs() < 500) return 5;
    // Fast scroll = more prefetch
    return 8;
  }
}
```

2. **Smart Image Prefetching**
```dart
Future<void> _prefetchImages(int count) async {
  final state = _readerCubit.state;
  if (state.content == null) return;
  
  final currentPage = state.currentPage;
  final totalPages = state.content!.pageCount;
  
  // Prefetch ahead
  for (int i = 1; i <= count; i++) {
    final targetPage = currentPage + i;
    if (targetPage > totalPages) break;
    if (_prefetchedPages.contains(targetPage)) continue;
    
    final imageUrl = state.content!.imageUrls[targetPage - 1];
    _prefetchImage(imageUrl, targetPage);
  }
  
  // Cleanup old prefetched pages (memory management)
  _cleanupPrefetchCache(currentPage);
}

void _cleanupPrefetchCache(int currentPage) {
  _prefetchedPages.removeWhere((page) => 
    page < currentPage - 2 || page > currentPage + 10
  );
}
```

### Phase 4: Performance Optimization

**Goal:** Optimize rendering performance dan memory usage

**Implementation:**

1. **Use RepaintBoundary**
```dart
Widget _buildImageViewer(String imageUrl, int pageNumber, {bool isContinuous = false}) {
  return RepaintBoundary( // ✅ Isolate repaint
    child: BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        // ... existing code
      },
    ),
  );
}
```

2. **Debounce Scroll Events**
```dart
Timer? _scrollDebounceTimer;

void _onScrollChanged() {
  _scrollDebounceTimer?.cancel();
  _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
    _performScrollTracking();
  });
}
```

3. **Use AutomaticKeepAliveClientMixin** (Optional)
```dart
// For images that should stay in memory
class ImageViewerWidget extends StatefulWidget {
  // ...
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep recent pages alive
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Must call
    // ... build image
  }
}
```

---

## 📋 Implementation Roadmap

### Week 1: Core Improvements

**Day 1-2: Variable Height Support**
- [x] Create branch `feature/reading-screen-revamp`
- [ ] Add `_imageHeights` cache Map
- [ ] Implement `_onImageLoaded()` callback
- [ ] Update `_onScrollChanged()` to use cached heights
- [ ] Update `ExtendedImageReaderWidget` with callback
- [ ] Test dengan mixed content (normal + webtoon)

**Day 3-4: Webtoon Detection**
- [ ] Create `WebtoonDetector` utility class
- [ ] Implement auto-detection (AR > 2.5)
- [ ] Update BoxFit logic in ExtendedImageReaderWidget
- [ ] Add webtoon badge (optional)
- [ ] Test dengan webtoon images (1275×16383px)

**Day 5-7: Preloading Strategy**
- [ ] Implement velocity tracking
- [ ] Add adaptive prefetch count calculation
- [ ] Smart prefetch dengan cleanup
- [ ] Test dengan slow/fast scrolling
- [ ] Memory profiling

### Week 2: Polish & Testing

**Day 8-9: Performance Optimization**
- [ ] Add RepaintBoundary
- [ ] Implement scroll debouncing
- [ ] Optimize image caching
- [ ] Profile dengan DevTools
- [ ] Reduce jank to 0

**Day 10-12: Testing**
- [ ] Test normal manga (1.42 AR)
- [ ] Test webtoon (12.85 AR)
- [ ] Test mixed content
- [ ] Test offline mode
- [ ] Test low memory devices
- [ ] Performance benchmarks

**Day 13-14: Documentation & Cleanup**
- [ ] Update code documentation
- [ ] Write migration guide
- [ ] Update AGENTS.md if needed
- [ ] Clean up debug code
- [ ] Final code review

---

## 🎯 Success Metrics

### Performance Targets

1. **Scroll Accuracy** ✅
   - Current page tracking: 100% accurate
   - Measured by: Manual verification

2. **Smooth Scrolling** ✅
   - Frame rate: 60fps sustained
   - Jank: < 5 frames dropped per scroll
   - Measured by: Flutter DevTools Performance tab

3. **Memory Usage** ✅
   - Peak: < 200MB for 100 pages
   - Average: < 150MB
   - Measured by: DevTools Memory tab

4. **Preload Efficiency** ✅
   - Cache hit rate: > 90%
   - Network requests: Reduced by 50% vs no cache
   - Measured by: Network profiler

### User Experience Goals

1. **Webtoon Handling** ✅
   - Tall images fit screen width
   - No horizontal scrolling needed
   - Smooth reading experience

2. **Page Tracking** ✅
   - Accurate current page display
   - Reading progress saves correctly
   - Resume from exact position

3. **Loading Experience** ✅
   - Instant page changes (< 100ms)
   - Smooth transitions
   - No blank placeholders visible

---

## 🧪 Testing Plan

### Unit Tests

```dart
// test/utils/webtoon_detector_test.dart
void main() {
  group('WebtoonDetector', () {
    test('detects normal image correctly', () {
      final size = Size(902, 1280); // AR = 1.42
      expect(WebtoonDetector.isWebtoon(size), false);
    });
    
    test('detects webtoon image correctly', () {
      final size = Size(1275, 16383); // AR = 12.85
      expect(WebtoonDetector.isWebtoon(size), true);
    });
    
    test('handles edge cases', () {
      expect(WebtoonDetector.isWebtoon(Size(0, 100)), false);
      expect(WebtoonDetector.isWebtoon(Size(100, 250)), false); // AR = 2.5
      expect(WebtoonDetector.isWebtoon(Size(100, 251)), true); // AR = 2.51
    });
  });
}
```

### Integration Tests

```dart
// test/presentation/pages/reader/reader_screen_test.dart
void main() {
  testWidgets('scroll tracking with variable heights', (tester) async {
    // ... setup
    
    // Scroll to page 5
    await tester.drag(find.byType(ListView), Offset(0, -1000));
    await tester.pumpAndSettle();
    
    // Verify current page is accurate
    expect(find.text('Page 5'), findsOneWidget);
  });
  
  testWidgets('webtoon image renders with fitWidth', (tester) async {
    // ... setup with webtoon image
    
    // Verify BoxFit is fitWidth
    final extendedImage = tester.widget<ExtendedImage>(
      find.byType(ExtendedImage)
    );
    expect(extendedImage.fit, BoxFit.fitWidth);
  });
}
```

### Manual Testing Checklist

- [ ] Normal manga (902×1280px) - AR 1.42
- [ ] Webtoon (1275×16383px) - AR 12.85
- [ ] Mixed content (normal + webtoon in same chapter)
- [ ] Offline mode
- [ ] Slow network (3G)
- [ ] Fast network (WiFi)
- [ ] Slow scroll
- [ ] Fast scroll
- [ ] Jump to page
- [ ] Resume from saved position
- [ ] Zoom functionality
- [ ] UI overlay toggle
- [ ] Low memory devices
- [ ] Tablet screen sizes

---

## 📚 References

### Code Examples
- ✅ Flutter ScrollView Observer: `/fluttercandies/flutter_scrollview_observer`
- ✅ ExtendedImage: Already in use
- ✅ Better-scroll (web): UX inspiration

### Documentation
- ✅ [AGENTS.md](../../../AGENTS.md) - Project guidelines
- ✅ [Webtoon Handling Reference](../offline-screen-improvements/webtoon-handling-reference.md)
- ✅ Flutter DevTools Performance Guide

### Research
- ✅ MangaDex reader UX
- ✅ Tachiyomi source code
- ✅ Webtoon official app

---

## 🚀 Next Steps

1. **Immediate:**
   - [ ] Review plan dengan team
   - [ ] Get feedback on approach
   - [ ] Prioritize features

2. **This Week:**
   - [ ] Start Phase 1: Variable Height Support
   - [ ] Implement image dimension cache
   - [ ] Update scroll tracking logic
   - [ ] Test dengan real content

3. **Next Week:**
   - [ ] Phase 2: Webtoon Detection
   - [ ] Phase 3: Advanced Preloading
   - [ ] Phase 4: Performance Optimization

---

**Created:** 2025-11-27  
**Branch:** feature/reading-screen-revamp  
**Version:** 0.6.0 (target)  
**Status:** Ready for Implementation
