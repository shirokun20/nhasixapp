import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'lib/core/di/service_locator.dart';
import 'lib/domain/entities/entities.dart';
import 'lib/services/download_service.dart';
import 'lib/services/notification_service.dart';
import 'lib/services/pdf_service.dart';

/// Simple test untuk download tanpa UI kompleks
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup service locator
  await setupLocator();

  runApp(const SimpleDownloadTest());
}

class SimpleDownloadTest extends StatelessWidget {
  const SimpleDownloadTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Download Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final Logger _logger = Logger();
  String _status = 'Ready to test';
  bool _isLoading = false;

  // Test content dengan URL yang valid
  final Content _testContent = Content(
    id: '590111',
    title: 'Test Download Content',
    englishTitle: 'Test Download Content',
    coverUrl: 'https://t.nhentai.net/galleries/590111/cover.jpg',
    tags: [const Tag(id: 1, name: 'test', type: 'tag', count: 1, url: '')],
    artists: ['Test Artist'],
    characters: [],
    parodies: [],
    groups: [],
    language: 'english',
    pageCount: 3, // Hanya 3 halaman untuk test cepat
    imageUrls: [
      'https://t.nhentai.net/galleries/590111/1t.jpg',
      'https://t.nhentai.net/galleries/590111/2t.jpg',
      'https://t.nhentai.net/galleries/590111/3t.jpg',
    ],
    uploadDate: DateTime.now(),
    favorites: 0,
    relatedContent: [],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Download Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Content: ${_testContent.id}'),
                    Text('Title: ${_testContent.title}'),
                    Text('Pages: ${_testContent.pageCount}'),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _testNotification,
                child: const Text('Test Notification'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testDownload,
                child: const Text('Test Download'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testPdf,
                child: const Text('Test PDF Conversion'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkFiles,
                child: const Text('Check Downloaded Files'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing notification...';
    });

    try {
      final notificationService = getIt<NotificationService>();

      // Test simple notification tanpa action buttons
      await notificationService.showDownloadStarted(
        contentId: 'test',
        title: 'Test Notification',
      );

      setState(() {
        _status = 'Notification test completed!';
      });

      _logger.i('Notification test successful');
    } catch (e) {
      setState(() {
        _status = 'Notification test failed: $e';
      });
      _logger.e('Notification test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDownload() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing download...';
    });

    try {
      final downloadService = getIt<DownloadService>();

      // Convert thumbnail URLs to full URLs
      final fullImageUrls = _testContent.imageUrls
          .map((url) => _convertThumbnailToFull(url))
          .toList();
      final contentWithFullUrls =
          _testContent.copyWith(imageUrls: fullImageUrls);

      _logger.i('Starting download with URLs: $fullImageUrls');

      final result = await downloadService.downloadContent(
        content: contentWithFullUrls,
        onProgress: (progress) {
          setState(() {
            _status = 'Downloading... ${progress.progressPercentage.toInt()}%';
          });
          _logger.i('Download progress: ${progress.progressPercentage}%');
        },
      );

      if (result.success) {
        setState(() {
          _status = 'Download completed! Files: ${result.totalFiles}';
        });
        _logger.i('Download successful: ${result.downloadPath}');
      } else {
        setState(() {
          _status = 'Download failed: ${result.error}';
        });
        _logger.e('Download failed: ${result.error}');
      }
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
      });
      _logger.e('Download error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPdf() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing PDF conversion...';
    });

    try {
      final downloadService = getIt<DownloadService>();
      final pdfService = getIt<PdfService>();

      // Get downloaded files
      final imageFiles =
          await downloadService.getDownloadedFiles(_testContent.id);

      if (imageFiles.isEmpty) {
        setState(() {
          _status = 'No images found. Download first!';
        });
        return;
      }

      // Get download path
      final downloadPath =
          await downloadService.getDownloadPath(_testContent.id);
      if (downloadPath == null) {
        setState(() {
          _status = 'Download path not found!';
        });
        return;
      }

      // Convert to PDF
      final pdfResult = await pdfService.convertToPdf(
        contentId: _testContent.id,
        title: _testContent.title,
        imagePaths: imageFiles,
        outputDir: downloadPath,
      );

      if (pdfResult.success) {
        setState(() {
          _status = 'PDF created! Path: ${pdfResult.pdfPath}';
        });
        _logger.i('PDF created: ${pdfResult.pdfPath}');
      } else {
        setState(() {
          _status = 'PDF creation failed: ${pdfResult.error}';
        });
        _logger.e('PDF creation failed: ${pdfResult.error}');
      }
    } catch (e) {
      setState(() {
        _status = 'PDF error: $e';
      });
      _logger.e('PDF error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFiles() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking files...';
    });

    try {
      final downloadService = getIt<DownloadService>();

      final downloadPath =
          await downloadService.getDownloadPath(_testContent.id);
      final isDownloaded =
          await downloadService.isContentDownloaded(_testContent.id);
      final files = await downloadService.getDownloadedFiles(_testContent.id);

      setState(() {
        _status =
            'Downloaded: $isDownloaded\nPath: $downloadPath\nFiles: ${files.length}';
      });

      _logger
          .i('Files check - Downloaded: $isDownloaded, Files: ${files.length}');
      for (final file in files) {
        _logger.i('File: $file');
      }
    } catch (e) {
      setState(() {
        _status = 'File check error: $e';
      });
      _logger.e('File check error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Convert thumbnail URL to full image URL
  String _convertThumbnailToFull(String thumbUrl) {
    // Pastikan url mulai dari https
    String url = thumbUrl.replaceFirst('//', 'https://');

    // Ganti domain tX -> iX
    url = url.replaceFirstMapped(RegExp(r'//t(\d)\.nhentai\.net'), (match) {
      return '//i${match.group(1)}.nhentai.net';
    });

    // Hilangkan huruf 't' sebelum ekstensi gambar
    url = url.replaceFirstMapped(
      RegExp(r'(\d+)t\.(webp|jpg|png|gif|jpeg)'),
      (match) => '${match.group(1)}.${match.group(2)}',
    );

    // Hapus ekstensi ganda (misal .webp.webp -> .webp)
    url = url.replaceAllMapped(
      RegExp(r'\.(webp|jpg|png|gif|jpeg)\.(webp|jpg|png|gif|jpeg)'),
      (match) => '.${match.group(1)}',
    );

    return url;
  }
}
