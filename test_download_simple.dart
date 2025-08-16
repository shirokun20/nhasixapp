import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'lib/services/download_service.dart';
import 'lib/services/notification_service.dart';
import 'lib/services/pdf_service.dart';
import 'lib/domain/entities/entities.dart';
import 'lib/utils/permission_helper.dart';

/// Test download tanpa service locator - manual dependency injection
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleDownloadTestApp());
}

class SimpleDownloadTestApp extends StatelessWidget {
  const SimpleDownloadTestApp({super.key});

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
  late final NotificationService _notificationService;
  late final DownloadService _downloadService;
  late final PdfService _pdfService;

  String _status = 'Ready to test';
  bool _isLoading = false;

  // Test content dengan URL yang valid
  final Content _testContent = Content(
    id: '590111',
    title: 'Test Download Content',
    englishTitle: 'Test Download Content',
    coverUrl: '//t.nhentai.net/galleries/590111/cover.jpg',
    tags: [
      const Tag(id: 1, name: 'test', type: 'tag', count: 1, url: '/tag/test/')
    ],
    artists: ['Test Artist'],
    characters: [],
    parodies: [],
    groups: [],
    language: 'english',
    pageCount: 3, // Hanya 3 halaman untuk test cepat
    imageUrls: [
      '//t2.nhentai.net/galleries/3486485/1t.webp',
      '//t1.nhentai.net/galleries/3486485/2t.webp',
      '//t1.nhentai.net/galleries/3486485/3t.webp',
    ],
    uploadDate: DateTime.now(),
    favorites: 0,
    relatedContent: [],
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Manual dependency injection - tidak menggunakan GetIt
  void _initializeServices() {
    try {
      _logger.i('Initializing services manually...');

      // Create services manually
      final dio = Dio();
      _notificationService = NotificationService(logger: _logger);
      _pdfService = PdfService(logger: _logger);
      _downloadService = DownloadService(
        httpClient: dio,
        notificationService: _notificationService,
        logger: _logger,
      );

      // Initialize notification service
      _notificationService.initialize();

      _logger.i('Services initialized successfully');
      setState(() {
        _status = 'Services initialized - Ready to test';
      });
    } catch (e) {
      _logger.e('Failed to initialize services: $e');
      setState(() {
        _status = 'Service initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Download Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                    const SizedBox(height: 8),
                    Text('Content ID: ${_testContent.id}'),
                    Text('Title: ${_testContent.title}'),
                    Text('Pages: ${_testContent.pageCount}'),
                    Text(
                        'Expected Path: /storage/emulated/0/Download/nhasix/${_testContent.id}/'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _testNotification,
                icon: const Icon(Icons.notifications),
                label: const Text('1. Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _requestPermissionAndDownload,
                icon: const Icon(Icons.download),
                label: const Text('2. Request Permission & Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _checkFiles,
                icon: const Icon(Icons.folder),
                label: const Text('3. Check Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _testPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('4. Test PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '1. Test Notification - Should show notification without error'),
                    const Text(
                        '2. Request Permission & Download - Will ask for storage permission first'),
                    const Text('3. Check Files - Should show downloaded files'),
                    const Text('4. Test PDF - Should create PDF from images'),
                    const SizedBox(height: 8),
                    const Text(
                      'Expected: Files in /storage/emulated/0/Download/nhasix/590111/',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
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
      _logger.i('Testing notification...');

      // Test simple notification
      await _notificationService.showDownloadStarted(
        contentId: 'test',
        title: 'Test Notification',
      );

      // Wait a bit then show progress
      await Future.delayed(const Duration(seconds: 1));
      await _notificationService.updateDownloadProgress(
        contentId: 'test',
        progress: 50,
        title: 'Test Notification',
      );

      // Wait a bit then show completion
      await Future.delayed(const Duration(seconds: 1));
      await _notificationService.showDownloadCompleted(
        contentId: 'test',
        title: 'Test Notification',
        downloadPath: '/test/path',
      );

      setState(() {
        _status = '✅ Notification test completed successfully!';
      });

      _logger.i('Notification test successful');
    } catch (e) {
      setState(() {
        _status = '❌ Notification test failed: $e';
      });
      _logger.e('Notification test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissionAndDownload() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting storage permission...';
    });

    try {
      // Request permission first
      final hasPermission =
          await PermissionHelper.requestStoragePermission(context);

      if (!hasPermission) {
        setState(() {
          _status = '❌ Storage permission denied. Cannot download files.';
        });
        return;
      }

      // Test if we can actually write to storage
      final canWrite = await PermissionHelper.canWriteToStorage();
      if (!canWrite) {
        setState(() {
          _status =
              '❌ Cannot write to storage. Please check permissions in settings.';
        });
        return;
      }

      setState(() {
        _status = '✅ Permission granted. Starting download...';
      });

      // Now proceed with download
      await _testDownload();
    } catch (e) {
      setState(() {
        _status = '❌ Permission error: $e';
      });
      _logger.e('Permission error: $e');
    } finally {
      if (_status.contains('Permission')) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testDownload() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing download...';
    });

    try {
      _logger.i('Testing download...');

      // Convert thumbnail URLs to full URLs
      final fullImageUrls = _testContent.imageUrls
          .map((url) => _convertThumbnailToFull(url))
          .toList();
      final contentWithFullUrls =
          _testContent.copyWith(imageUrls: fullImageUrls);

      _logger.i('Starting download with URLs: $fullImageUrls');

      final result = await _downloadService.downloadContent(
        content: contentWithFullUrls,
        onProgress: (progress) {
          setState(() {
            _status =
                'Downloading... ${progress.progressPercentage.toInt()}% (${progress.downloadedPages}/${progress.totalPages})';
          });
          _logger.i('Download progress: ${progress.progressPercentage}%');
        },
      );

      if (result.success) {
        setState(() {
          _status =
              '✅ Download completed! Files: ${result.totalFiles}\nPath: ${result.downloadPath}';
        });
        _logger.i('Download successful: ${result.downloadPath}');
      } else {
        setState(() {
          _status = '❌ Download failed: ${result.error}';
        });
        _logger.e('Download failed: ${result.error}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Download error: $e';
      });
      _logger.e('Download error: $e');
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
      _logger.i('Checking files...');

      final downloadPath =
          await _downloadService.getDownloadPath(_testContent.id);
      final isDownloaded =
          await _downloadService.isContentDownloaded(_testContent.id);
      final files = await _downloadService.getDownloadedFiles(_testContent.id);

      setState(() {
        _status = '📁 Check Results:\n'
            'Downloaded: $isDownloaded\n'
            'Path: $downloadPath\n'
            'Files: ${files.length}';
      });

      _logger
          .i('Files check - Downloaded: $isDownloaded, Files: ${files.length}');
      for (final file in files) {
        _logger.i('File: $file');
      }
    } catch (e) {
      setState(() {
        _status = '❌ File check error: $e';
      });
      _logger.e('File check error: $e');
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
      _logger.i('Testing PDF conversion...');

      // Get downloaded files
      final imageFiles =
          await _downloadService.getDownloadedFiles(_testContent.id);

      if (imageFiles.isEmpty) {
        setState(() {
          _status = '⚠️ No images found. Download first!';
        });
        return;
      }

      // Get download path
      final downloadPath =
          await _downloadService.getDownloadPath(_testContent.id);
      if (downloadPath == null) {
        setState(() {
          _status = '⚠️ Download path not found!';
        });
        return;
      }

      // Convert to PDF
      final pdfResult = await _pdfService.convertToPdf(
        contentId: _testContent.id,
        title: _testContent.title,
        imagePaths: imageFiles,
        outputDir: downloadPath,
      );

      if (pdfResult.success) {
        setState(() {
          _status = '✅ PDF created successfully!\n'
              'Path: ${pdfResult.pdfPath}\n'
              'Pages: ${pdfResult.pageCount}\n'
              'Size: ${_formatFileSize(pdfResult.fileSize)}';
        });
        _logger.i('PDF created: ${pdfResult.pdfPath}');
      } else {
        setState(() {
          _status = '❌ PDF creation failed: ${pdfResult.error}';
        });
        _logger.e('PDF creation failed: ${pdfResult.error}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ PDF error: $e';
      });
      _logger.e('PDF error: $e');
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

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
