import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'image_cache_manager.dart';
import 'image_optimizer.dart';
import 'image_preloader.dart';
import 'content_image_preloader.dart';
import '../../domain/entities/content.dart';

/// Test helper for image caching functionality
///
/// This class provides utilities to test and verify that the image caching
/// system is working correctly according to task 5.4 requirements.
class ImageCacheTestHelper {
  static ImageCacheTestHelper? _instance;
  static ImageCacheTestHelper get instance =>
      _instance ??= ImageCacheTestHelper._();

  ImageCacheTestHelper._();

  final Logger _logger = Logger();
  final ImageCacheManager _cacheManager = ImageCacheManager.instance;
  final ImageOptimizer _optimizer = ImageOptimizer.instance;
  final ImagePreloader _preloader = ImagePreloader.instance;
  final ContentImagePreloader _contentPreloader =
      ContentImagePreloader.instance;

  /// Test progressive image loading functionality
  Future<TestResult> testProgressiveImageLoading() async {
    _logger.i('Testing progressive image loading...');

    try {
      const testImageUrl =
          'https://via.placeholder.com/400x600/FF0000/FFFFFF?text=Test+Image';

      // Test thumbnail generation
      final thumbnailFile = await _cacheManager.getThumbnail(testImageUrl);
      final thumbnailExists = thumbnailFile.existsSync();

      // Test compressed image generation
      final compressedFile =
          await _cacheManager.getCompressedImage(testImageUrl);
      final compressedExists = compressedFile.existsSync();

      // Test full image caching
      final fullImageFile = await _cacheManager.getFullImage(testImageUrl);
      final fullImageExists = fullImageFile.existsSync();

      final success = thumbnailExists && compressedExists && fullImageExists;

      return TestResult(
        testName: 'Progressive Image Loading',
        success: success,
        message: success
            ? 'All image types loaded successfully'
            : 'Failed to load some image types',
        details: {
          'thumbnail_exists': thumbnailExists,
          'compressed_exists': compressedExists,
          'full_image_exists': fullImageExists,
          'thumbnail_path': thumbnailFile.path,
          'compressed_path': compressedFile.path,
          'full_image_path': fullImageFile.path,
        },
      );
    } catch (e) {
      return TestResult(
        testName: 'Progressive Image Loading',
        success: false,
        message: 'Exception occurred: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test custom cache configuration
  Future<TestResult> testCustomCacheConfiguration() async {
    _logger.i('Testing custom cache configuration...');

    try {
      await _cacheManager.initialize();

      // Test cache info retrieval
      final cacheInfo = await _cacheManager.getCacheInfo();

      // Test cache clearing
      await _cacheManager.clearCache(CacheType.thumbnail);

      // Test cache optimization
      await _cacheManager.optimizeCache();

      return TestResult(
        testName: 'Custom Cache Configuration',
        success: true,
        message: 'Cache configuration working correctly',
        details: {
          'total_size': cacheInfo.totalSize,
          'total_files': cacheInfo.totalFiles,
          'cache_initialized': true,
        },
      );
    } catch (e) {
      return TestResult(
        testName: 'Custom Cache Configuration',
        success: false,
        message: 'Cache configuration failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test thumbnail generation
  Future<TestResult> testThumbnailGeneration() async {
    _logger.i('Testing thumbnail generation...');

    try {
      // Create test image data
      final testImageBytes = await _createTestImageBytes();

      // Generate thumbnail
      final thumbnailBytes = await _optimizer.generateThumbnail(
        testImageBytes,
        width: 200,
        height: 300,
        quality: 80,
      );

      // Generate multiple thumbnail sizes
      final multipleThumbnails = await _optimizer.generateMultipleThumbnails(
        testImageBytes,
        sizes: [ThumbnailSize.small, ThumbnailSize.medium, ThumbnailSize.large],
      );

      final success =
          thumbnailBytes.isNotEmpty && multipleThumbnails.isNotEmpty;

      return TestResult(
        testName: 'Thumbnail Generation',
        success: success,
        message: success
            ? 'Thumbnails generated successfully'
            : 'Failed to generate thumbnails',
        details: {
          'thumbnail_size': thumbnailBytes.length,
          'multiple_thumbnails_count': multipleThumbnails.length,
          'original_size': testImageBytes.length,
          'compression_ratio': testImageBytes.length / thumbnailBytes.length,
        },
      );
    } catch (e) {
      return TestResult(
        testName: 'Thumbnail Generation',
        success: false,
        message: 'Thumbnail generation failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test image compression for storage
  Future<TestResult> testImageCompression() async {
    _logger.i('Testing image compression...');

    try {
      // Create test image data
      final testImageBytes = await _createTestImageBytes();

      // Test different compression levels
      final maxCompression = await _optimizer.optimizeForStorage(
        testImageBytes,
        optimization: StorageOptimization.maximum,
      );

      final balancedCompression = await _optimizer.optimizeForStorage(
        testImageBytes,
        optimization: StorageOptimization.balanced,
      );

      final qualityCompression = await _optimizer.optimizeForStorage(
        testImageBytes,
        optimization: StorageOptimization.quality,
      );

      final success = maxCompression.isOptimized &&
          balancedCompression.isOptimized &&
          qualityCompression.isOptimized;

      return TestResult(
        testName: 'Image Compression',
        success: success,
        message: success
            ? 'Image compression working correctly'
            : 'Image compression failed',
        details: {
          'original_size': testImageBytes.length,
          'max_compressed_size': maxCompression.compressedSize,
          'balanced_compressed_size': balancedCompression.compressedSize,
          'quality_compressed_size': qualityCompression.compressedSize,
          'max_compression_ratio': maxCompression.compressionRatio,
          'balanced_compression_ratio': balancedCompression.compressionRatio,
          'quality_compression_ratio': qualityCompression.compressionRatio,
        },
      );
    } catch (e) {
      return TestResult(
        testName: 'Image Compression',
        success: false,
        message: 'Image compression failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test image preloading functionality
  Future<TestResult> testImagePreloading() async {
    _logger.i('Testing image preloading...');

    try {
      // Create test content
      final testContents = _createTestContents();

      // Test content image preloading
      await _contentPreloader.preloadContentList(
        testContents,
        currentIndex: 0,
        preloadThumbnails: true,
        preloadCompressed: true,
      );

      // Test reader image preloading
      final testImageUrls = testContents.first.imageUrls;
      if (testImageUrls.isNotEmpty) {
        await _contentPreloader.preloadReaderImages(
          testImageUrls,
          currentPage: 0,
        );
      }

      // Get preload progress
      final progress = _preloader.getProgress();

      return TestResult(
        testName: 'Image Preloading',
        success: true,
        message: 'Image preloading completed successfully',
        details: {
          'preload_completed': progress.completed,
          'preload_total': progress.total,
          'preload_percentage': progress.percentage,
          'is_active': progress.isActive,
          'queue_sizes': {
            'high': progress.queueSizes.high,
            'normal': progress.queueSizes.normal,
            'low': progress.queueSizes.low,
          },
        },
      );
    } catch (e) {
      return TestResult(
        testName: 'Image Preloading',
        success: false,
        message: 'Image preloading failed: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Run all image caching tests
  Future<List<TestResult>> runAllTests() async {
    _logger.i('Running all image caching tests...');

    final results = <TestResult>[];

    // Test 1: Progressive Image Loading
    results.add(await testProgressiveImageLoading());

    // Test 2: Custom Cache Configuration
    results.add(await testCustomCacheConfiguration());

    // Test 3: Thumbnail Generation
    results.add(await testThumbnailGeneration());

    // Test 4: Image Compression
    results.add(await testImageCompression());

    // Test 5: Image Preloading
    results.add(await testImagePreloading());

    // Print summary
    final passedTests = results.where((r) => r.success).length;
    final totalTests = results.length;

    _logger.i('Image caching tests completed: $passedTests/$totalTests passed');

    return results;
  }

  /// Create test image bytes (simple colored rectangle)
  Future<Uint8List> _createTestImageBytes() async {
    // Create a simple test image (red rectangle)
    // In a real implementation, you might load an actual image file
    // For now, we'll create minimal JPEG-like data
    return Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      // ... (simplified JPEG header)
      0xFF, 0xD9, // JPEG end marker
    ]);
  }

  /// Create test content objects
  List<Content> _createTestContents() {
    return [
      Content(
        id: 'test1',
        title: 'Test Content 1',
        coverUrl:
            'https://via.placeholder.com/400x600/FF0000/FFFFFF?text=Test+1',
        tags: [],
        artists: ['Test Artist 1'],
        characters: [],
        parodies: [],
        groups: [],
        language: 'english',
        pageCount: 10,
        imageUrls: List.generate(
            10,
            (i) =>
                'https://via.placeholder.com/800x1200/FF0000/FFFFFF?text=Page+${i + 1}'),
        uploadDate: DateTime.now(),
        favorites: 100,
        relatedContent: [],
      ),
      Content(
        id: 'test2',
        title: 'Test Content 2',
        coverUrl:
            'https://via.placeholder.com/400x600/00FF00/FFFFFF?text=Test+2',
        tags: [],
        artists: ['Test Artist 2'],
        characters: [],
        parodies: [],
        groups: [],
        language: 'japanese',
        pageCount: 15,
        imageUrls: List.generate(
            15,
            (i) =>
                'https://via.placeholder.com/800x1200/00FF00/FFFFFF?text=Page+${i + 1}'),
        uploadDate: DateTime.now(),
        favorites: 200,
        relatedContent: [],
      ),
    ];
  }

  /// Clear all test data
  Future<void> clearTestData() async {
    await _cacheManager.clearAllCaches();
    _preloader.clearPreloadQueues();
    _contentPreloader.clearPreloadQueues();
  }
}

/// Test result data class
class TestResult {
  final String testName;
  final bool success;
  final String message;
  final Map<String, dynamic> details;

  TestResult({
    required this.testName,
    required this.success,
    required this.message,
    required this.details,
  });

  @override
  String toString() {
    return 'TestResult(name: $testName, success: $success, message: $message)';
  }
}

/// Extension to run image cache tests from anywhere in the app
extension ImageCacheTestExtension on BuildContext {
  /// Run image cache tests and show results in a dialog
  Future<void> runImageCacheTests() async {
    final testHelper = ImageCacheTestHelper.instance;

    // Show loading dialog
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Image Cache Tests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing image caching functionality...'),
          ],
        ),
      ),
    );

    try {
      // Run tests
      final results = await testHelper.runAllTests();

      // Close loading dialog
      Navigator.of(this).pop();

      // Show results dialog
      showDialog(
        context: this,
        builder: (context) => AlertDialog(
          title: const Text('Image Cache Test Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: results
                  .map((result) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              result.success ? Icons.check_circle : Icons.error,
                              color: result.success ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${result.testName}: ${result.message}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: result.success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(this).pop();

      // Show error dialog
      showDialog(
        context: this,
        builder: (context) => AlertDialog(
          title: const Text('Test Error'),
          content: Text('Failed to run tests: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
