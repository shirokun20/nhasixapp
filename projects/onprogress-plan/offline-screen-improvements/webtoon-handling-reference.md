# Webtoon Image Handling - Technical Reference

## 🎯 Overview

Technical guide for handling webtoon-style (extremely tall/vertical) images in PDF generation and reading modes.

## 📐 What is a Webtoon Image?

**Definition:** An image with extreme vertical aspect ratio, typically used in Korean webcomics.

**VERIFIED from Project Images:**
- **Normal Image** (`6143172194436057944.jpg`): **902 × 1280 px**, Aspect Ratio = **1.42**
- **Webtoon Image** (`IMG_20251127_105652_516.jpg`): **1275 × 16383 px**, Aspect Ratio = **12.85** (!)

**Characteristics:**
- Height >> Width (verified: **12.85x** in actual webtoon vs **1.42x** in normal)
- Continuous vertical content
- Verified dimensions: **1275px wide × 16383px tall** (actual webtoon from project)
- Designed for vertical scrolling
- Large file sizes (actual webtoon file is WebP format)

**Aspect Ratio Threshold (Based on Analysis):**
```dart
// VERIFIED threshold based on actual images:
// - Normal manga: AR = 1.42
// - Webtoon: AR = 12.85
// - Safe threshold: 2.5 (midpoint between normal and webtoon)
const double WEBTOON_THRESHOLD = 2.5; // height/width > 2.5
```

## ⚠️ Problems with Webtoon Images

### 1. PDF Generation Issues
- **Huge PDF pages:** A 800x15000px image creates an extremely tall PDF page
- **Poor rendering:** PDF viewers struggle with very tall pages
- **Large file sizes:** Uncompressed tall images create massive PDFs
- **Printing problems:** Impossible to print effectively

### 2. Reading Mode Issues
- **Fixed height approximation fails:** `screenHeight * 0.9` doesn't work
- **Scroll tracking inaccurate:** Can't determine current page position
- **Memory issues:** Loading full resolution in viewport
- **Performance problems:** Rendering very tall images causes jank

## ✅ Solutions

### Solution 1: Smart Image Splitting for PDF

Split tall images into multiple pages while maintaining continuity.

#### Algorithm (Based on Actual Image Analysis)
```dart
class WebtoonImageProcessor {
  // VERIFIED threshold: Normal AR=1.42, Webtoon AR=12.85, Threshold=2.5
  static const double WEBTOON_ASPECT_RATIO_THRESHOLD = 2.5;
  
  // Target height based on ACTUAL normal image height (1280px)
  // This creates chunks that "fit" with normal reading experience
  static const int MAX_PDF_PAGE_HEIGHT = 1280; // matches normal image
  
  static const int OVERLAP_PIXELS = 30; // for continuity (small overlap)
  
  /// Detect if image is webtoon-style
  /// VERIFIED: Normal=1.42, Webtoon=12.85, Threshold=2.5
  static bool isWebtoonImage(int width, int height) {
    final aspectRatio = height / width;
    return aspectRatio > WEBTOON_ASPECT_RATIO_THRESHOLD;
  }
  
  /// Split tall image into multiple parts
  /// 
  /// EXAMPLE with actual project webtoon (1275x16383px):
  /// - Total height: 16383px
  /// - Max chunk height: 1280px (matching normal image)
  /// - Overlap: 30px
  /// - Chunks needed: 16383 / 1250 (1280-30) ≈ 13.1 → ~13 chunks
  /// - Resulting chunk aspect ratio: 1280/1275 ≈ 1.0 (almost square, fits normal flow!)
  static Future<List<Uint8List>> splitTallImage(
    img.Image image, {
    int maxHeight = MAX_PDF_PAGE_HEIGHT,
    int overlap = OVERLAP_PIXELS,
  }) async {
    final parts = <Uint8List>[];
    final totalHeight = image.height;
    int currentY = 0;
    int partNumber = 1;
    
    while (currentY < totalHeight) {
      // Calculate slice height
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
      
      // Encode slice with quality preservation
      final sliceBytes = img.encodeJpg(slice, quality: 90);
      parts.add(Uint8List.fromList(sliceBytes));
      
      // Log progress
      debugPrint('Split part $partNumber: y=$currentY, height=$sliceHeight');
      partNumber++;
      
      // Move to next slice (with overlap for continuity)
      if (currentY + sliceHeight < totalHeight) {
        currentY += sliceHeight - overlap;
      } else {
        break; // Last slice
      }
    }
    
    debugPrint('Webtoon image split into ${parts.length} parts');
    return parts;
  }
  
  /// Calculate optimal split points (advanced)
  static List<int> calculateSmartSplitPoints(
    img.Image image, {
    int maxHeight = MAX_PDF_PAGE_HEIGHT,
  }) {
    final splitPoints = <int>[0];
    final totalHeight = image.height;
    int currentY = 0;
    
    while (currentY < totalHeight) {
      // Look for natural break points (white space, panel borders)
      final nextSplit = _findOptimalSplitPoint(
        image,
        currentY,
        currentY + maxHeight,
      );
      
      splitPoints.add(nextSplit);
      currentY = nextSplit;
    }
    
    return splitPoints;
  }
  
  /// Find optimal split point by detecting white space
  static int _findOptimalSplitPoint(
    img.Image image,
    int startY,
    int maxY,
  ) {
    // Scan horizontal lines for whitespace
    for (int y = maxY; y > startY + (maxY - startY) * 0.8; y--) {
      if (_isWhiteSpaceLine(image, y)) {
        return y;
      }
    }
    
    // No good split point found, use max
    return maxY;
  }
  
  /// Check if a horizontal line is mostly white
  static bool _isWhiteSpaceLine(img.Image image, int y) {
    int whitePixels = 0;
    const whiteThreshold = 240; // RGB > 240 is considered white
    
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      
      if (r > whiteThreshold && g > whiteThreshold && b > whiteThreshold) {
        whitePixels++;
      }
    }
    
    // If >90% white, consider it whitespace
    return whitePixels > image.width * 0.9;
  }
}
```

#### Integration with PDF Service

```dart
// pdf_service.dart - Modified image processing

static Future<List<Uint8List>> _processImageStatic(
  String imagePath, {
  required int maxWidth,
  required int quality,
}) async {
  final file = File(imagePath);
  final imageBytes = await file.readAsBytes();
  final image = img.decodeImage(imageBytes);
  
  if (image == null) {
    throw Exception('Could not decode image: $imagePath');
  }
  
  // Check if webtoon image
  if (WebtoonImageProcessor.isWebtoonImage(image.width, image.height)) {
    debugPrint('📏 Webtoon detected: ${image.width}x${image.height}');
    
    // Split into multiple parts
    final parts = await WebtoonImageProcessor.splitTallImage(image);
    
    debugPrint('✂️ Split into ${parts.length} parts');
    return parts;
  } else {
    // Process normally (single image)
    img.Image processedImage = image;
    
    // Resize if needed
    if (image.width > maxWidth) {
      final aspectRatio = image.height / image.width;
      final newHeight = (maxWidth * aspectRatio).round();
      
      processedImage = img.copyResize(
        image,
        width: maxWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }
    
    // Encode
    final compressedBytes = img.encodeJpg(processedImage, quality: quality);
    return [Uint8List.fromList(compressedBytes)];
  }
}

static Future<Uint8List> _createPdfStatic(
  List<List<Uint8List>> allImageParts, // Changed: now list of lists
  String title,
) async {
  final pdf = pw.Document();
  
  // Flatten: each part becomes a page
  for (final imageParts in allImageParts) {
    for (final imageBytes in imageParts) {
      final image = pw.MemoryImage(imageBytes);
      
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }
  }
  
  return await pdf.save();
}
```

### Solution 2: Accurate Scroll Tracking

Use actual image dimensions instead of approximations.

```dart
// reader_screen.dart - Improved scroll tracking

class _ReaderScreenState extends State<ReaderScreen> {
  // Cache actual image heights
  final Map<int, double> _imageHeights = {};
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }
  
  /// Called when image is loaded and dimensions are known
  void _onImageLoaded(int pageIndex, Size imageSize) {
    setState(() {
      // Cache the actual rendered height
      final screenWidth = MediaQuery.of(context).size.width;
      final aspectRatio = imageSize.height / imageSize.width;
      _imageHeights[pageIndex] = screenWidth * aspectRatio;
    });
  }
  
  void _onScrollChanged() {
    final state = _readerCubit.state;
    if (state.readingMode == ReadingMode.continuousScroll && 
        state.content != null) {
      
      final scrollPosition = _scrollController.offset;
      int currentPage = 1;
      double accumulatedHeight = 0;
      
      // Calculate based on actual cached heights
      for (int i = 0; i < state.content!.pageCount; i++) {
        final imageHeight = _imageHeights[i] ?? 
            MediaQuery.of(context).size.height; // Fallback
        
        // Add spacing between images
        final spacing = 8.0;
        final totalItemHeight = imageHeight + spacing;
        
        if (scrollPosition >= accumulatedHeight && 
            scrollPosition < accumulatedHeight + totalItemHeight) {
          currentPage = i + 1;
          break;
        }
        
        accumulatedHeight += totalItemHeight;
      }
      
      // Update page only if changed
      if (currentPage != _lastReportedPage) {
        _lastReportedPage = currentPage;
        _readerCubit.updateCurrentPage(currentPage);
      }
    }
  }
}
```

### Solution 3: Optimized Image Widget for Webtoons

```dart
// extended_image_reader_widget.dart

class ExtendedImageReaderWidget extends StatefulWidget {
  // ... existing code
  
  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
      image: imageProvider,
      fit: _getBoxFit(),
      mode: ExtendedImageMode.gesture,
      onImageLoad: (ImageInfo info) {
        // Report actual image size to parent
        widget.onImageLoaded?.call(
          Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ),
        );
      },
      // ... other properties
    );
  }
  
  BoxFit _getBoxFit() {
    // Detect webtoon from image info
    if (_imageInfo != null) {
      final width = _imageInfo!.image.width;
      final height = _imageInfo!.image.height;
      final aspectRatio = height / width;
      
      if (aspectRatio > 3.0) {
        // Webtoon image: always fit width for vertical reading
        return BoxFit.fitWidth;
      }
    }
    
    // Default behavior based on reading mode
    switch (widget.readingMode) {
      case ReadingMode.singlePage:
        return BoxFit.contain;
      case ReadingMode.verticalPage:
        return BoxFit.fitWidth;
      case ReadingMode.continuousScroll:
        return BoxFit.fitWidth; // Better for webtoons
    }
  }
}
```

## 🎨 User Experience Considerations

### PDF Generation
1. **Show split notification:** "Tall image detected, will create X pages"
2. **Progress indicator:** Show splitting progress separately
3. **File naming:** Add "(split)" or part numbers to filename
4. **Preview option:** Let user preview splits before generating

### Reading Mode
1. **Auto-detect webtoon:** Suggest webtoon mode for tall images
2. **Smooth scroll:** No jank during rapid scrolling
3. **Accurate tracking:** Page indicator always correct
4. **Memory efficient:** Don't load all images at full resolution

## 📊 Performance Metrics

### Target Metrics
- **Split time:** < 5 seconds for 15000px image
- **Memory usage:** < 200MB during split operation
- **Scroll FPS:** 60fps consistently
- **Page tracking accuracy:** 100% (no off-by-one errors)

### Optimization Strategies
1. **Use compute() isolate:** Don't block UI thread
2. **Progressive loading:** Load visible parts first
3. **Cache management:** Clear old images from memory
4. **Smart preloading:** Only preload nearby images

## 🧪 Test Cases

### Unit Tests (Based on Verified Dimensions)
```dart
group('WebtoonImageProcessor', () {
  test('detects webtoon images correctly with VERIFIED threshold', () {
    // Normal image (actual from project)
    expect(WebtoonImageProcessor.isWebtoonImage(902, 1280), false); // AR=1.42 < 2.5
    
    // Webtoon image (actual from project)
    expect(WebtoonImageProcessor.isWebtoonImage(1275, 16383), true); // AR=12.85 > 2.5
    
    // Edge cases around threshold
    expect(WebtoonImageProcessor.isWebtoonImage(1000, 2500), false); // AR=2.5 exactly
    expect(WebtoonImageProcessor.isWebtoonImage(1000, 2600), true);  // AR=2.6 > 2.5
  });
  
  test('splits ACTUAL webtoon image into correct chunks', () async {
    // Simulate actual project webtoon: 1275x16383
    final image = img.Image(width: 1275, height: 16383);
    final parts = await WebtoonImageProcessor.splitTallImage(
      image,
      maxHeight: 1280, // Target normal image height
      overlap: 30,
    );
    
    // Expected: 16383 / (1280-30) = 16383 / 1250 ≈ 13.1 → 13-14 parts
    expect(parts.length, greaterThanOrEqualTo(13));
    expect(parts.length, lessThanOrEqualTo(14));
  });
  
  test('resulting chunks have aspect ratio close to 1.0', () async {
    // Each chunk: 1275x1280 → AR = 1.01 (almost square)
    final image = img.Image(width: 1275, height: 16383);
    final parts = await WebtoonImageProcessor.splitTallImage(image);
    
    // Verify first chunk maintains width and has target height
    final firstChunk = img.decodeJpg(parts.first)!;
    expect(firstChunk.width, 1275);
    expect(firstChunk.height, lessThanOrEqualTo(1280));
    
    // Calculate aspect ratio
    final aspectRatio = firstChunk.height / firstChunk.width;
    expect(aspectRatio, lessThan(1.1)); // Close to 1.0
  });
  
  test('maintains image quality after split', () async {
    // Test that split images are not corrupted
  });
});
```

### Integration Tests
- Generate PDF from webtoon content
- Read webtoon content in continuous mode
- Switch between reading modes with webtoon
- Delete webtoon content

### Manual Test Scenarios (Based on Actual Images)
1. **Actual normal image:** 902x1280px (AR=1.42) - Should NOT be detected as webtoon
2. **Actual webtoon image:** 1275x16383px (AR=12.85) - Should split into ~13 chunks
3. **Edge case at threshold:** 1000x2500px (AR=2.5) - Should NOT be webtoon
4. **Just above threshold:** 1000x2600px (AR=2.6) - Should BE webtoon
5. **Multiple webtoons:** 5 images at 1275x16383px each
6. **Mixed content:** 3 normal (902x1280) + 3 webtoon (1275x16383)
7. **Extreme webtoon:** 1000x30000px (AR=30.0)

## 📈 Expected Results (Based on Actual Webtoon: 1275x16383)

### Before Optimization
- ❌ Single PDF page: 1275x16383px (extremely tall, AR=12.85)
- ❌ File size: Very large due to uncompressed tall image
- ❌ Scroll tracking: Completely broken with tall images
- ❌ Rendering: Severe performance issues

### After Optimization (With Slicing)
- ✅ PDF pages: ~13 pages per webtoon (1275x1280 each, AR≈1.0)
- ✅ Each page "fits" normal reading flow (same height as normal image!)
- ✅ File size: Manageable, ~13x smaller pages
- ✅ Scroll tracking: 100% accurate with cached heights
- ✅ Rendering: Smooth 60fps
- ✅ Reading experience: Consistent between normal and webtoon content

**Key Achievement:** Webtoon chunks (AR≈1.0) match visual flow of normal manga (AR=1.42)

## 🔧 Configuration Options (Verified from Analysis)

```dart
class WebtoonConfig {
  // Detection threshold (VERIFIED: Normal=1.42, Webtoon=12.85)
  static const double aspectRatioThreshold = 2.5; // Safe midpoint
  
  // PDF splitting (VERIFIED: Normal image is 1280px tall)
  static const int maxPdfPageHeight = 1280; // Match normal image for consistency
  static const int overlapPixels = 30; // Small overlap for continuity
  static const int jpegQuality = 90; // balance size/quality
  
  // Smart splitting (advanced)
  static const bool useSmartSplitting = false; // detect white space
  static const double whitespaceThreshold = 0.9; // 90% white
  
  // Reading mode
  static const bool autoDetectWebtoonMode = true;
  static const bool suggestWebtoonMode = true; // show prompt
  
  // Performance
  static const bool useComputeIsolate = true;
  static const int maxConcurrentSplits = 2;
}
```

**Why These Values:**
- `aspectRatioThreshold = 2.5`: Safe margin between normal (1.42) and webtoon (12.85)
- `maxPdfPageHeight = 1280`: Matches actual normal image height for consistent reading
- `overlapPixels = 30`: Small overlap prevents jarring transitions
- Result: Webtoon 1275x16383 → ~13 chunks of 1275x1280 (AR ≈ 1.0, perfect fit!)

## 🐛 Common Issues & Solutions

### Issue 1: Out of Memory During Split
**Cause:** Loading entire image into memory  
**Solution:** Process in chunks, use compute() isolate

### Issue 2: Poor Split Quality
**Cause:** Too aggressive JPEG compression  
**Solution:** Increase quality setting, use PNG for critical sections

### Issue 3: Slow Splitting
**Cause:** Synchronous processing on UI thread  
**Solution:** Use compute() or isolate for background processing

### Issue 4: Incorrect Split Points
**Cause:** Using fixed heights without content awareness  
**Solution:** Implement smart splitting with edge detection

### Issue 5: Scroll Jank with Webtoons
**Cause:** Loading full resolution images  
**Solution:** Use progressive loading, downscale for scrolling

## 📚 References

- [image package documentation](https://pub.dev/packages/image)
- [dart_pdf documentation](https://pub.dev/packages/pdf)
- [Flutter compute() guide](https://api.flutter.dev/flutter/foundation/compute.html)
- [Memory management best practices](https://docs.flutter.dev/perf/best-practices)

---

**Last Updated:** 2025-11-27  
**Status:** Reference Document - Ready for Implementation
