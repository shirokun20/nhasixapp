import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'lib/core/di/service_locator.dart';
import 'lib/domain/entities/entities.dart';
import 'lib/presentation/blocs/download/download_bloc.dart';
import 'lib/services/download_service.dart';
import 'lib/services/notification_service.dart';
import 'lib/services/pdf_service.dart';

/// Test app untuk menguji fitur download
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup service locator
  await setupLocator();

  runApp(const DownloadTestApp());
}

class DownloadTestApp extends StatelessWidget {
  const DownloadTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) =>
            getIt<DownloadBloc>()..add(const DownloadInitializeEvent()),
        child: const DownloadTestScreen(),
      ),
    );
  }
}

class DownloadTestScreen extends StatefulWidget {
  const DownloadTestScreen({super.key});

  @override
  State<DownloadTestScreen> createState() => _DownloadTestScreenState();
}

class _DownloadTestScreenState extends State<DownloadTestScreen> {
  final Logger _logger = Logger();

  // Test content dari https://nhentai.net/g/590111/
  final Content _testContent = Content(
    id: '590111',
    title: 'Test Content - Nhentai 590111',
    englishTitle: 'Test Content - Nhentai 590111',
    coverUrl: 'https://t.nhentai.net/galleries/590111/cover.jpg',
    tags: [
      const Tag(id: 1, name: 'test', type: 'tag', count: 1, url: ''),
    ],
    artists: ['Test Artist'],
    characters: ['Test Character'],
    parodies: ['Test Parody'],
    groups: ['Test Group'],
    language: 'english',
    pageCount: 5, // Untuk test, gunakan 5 halaman saja
    imageUrls: [
      'https://t.nhentai.net/galleries/590111/1t.jpg',
      'https://t.nhentai.net/galleries/590111/2t.jpg',
      'https://t.nhentai.net/galleries/590111/3t.jpg',
      'https://t.nhentai.net/galleries/590111/4t.jpg',
      'https://t.nhentai.net/galleries/590111/5t.jpg',
    ],
    uploadDate: DateTime.now(),
    favorites: 100,
    relatedContent: [],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocConsumer<DownloadBloc, DownloadBlocState>(
        listener: (context, state) {
          if (state is DownloadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Test Content Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Content Info',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('ID: ${_testContent.id}'),
                        Text('Title: ${_testContent.title}'),
                        Text('Pages: ${_testContent.pageCount}'),
                        Text('Images: ${_testContent.imageUrls.length}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Download Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download Actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),

                        // Download Images Button
                        ElevatedButton.icon(
                          onPressed: () => _downloadImages(context),
                          icon: const Icon(Icons.download),
                          label: const Text('Download Images Only'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Download as PDF Button
                        ElevatedButton.icon(
                          onPressed: () => _downloadAsPdf(context),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Download as PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Test Services Button
                        ElevatedButton.icon(
                          onPressed: () => _testServices(context),
                          icon: const Icon(Icons.build),
                          label: const Text('Test Services'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Download Status
                if (state is DownloadLoaded) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Status',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text('Total Downloads: ${state.downloads.length}'),
                          const SizedBox(height: 8),

                          // Find our test download
                          ...state.downloads
                              .where((d) => d.contentId == _testContent.id)
                              .map((download) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: ${download.statusText}'),
                                      Text(
                                          'Progress: ${download.progressPercentage}%'),
                                      if (download.downloadPath != null)
                                        Text('Path: ${download.downloadPath}'),
                                      if (download.error != null)
                                        Text('Error: ${download.error}',
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: download.progress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          download.isFailed
                                              ? Colors.red
                                              : download.isCompleted
                                                  ? Colors.green
                                                  : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  )),
                        ],
                      ),
                    ),
                  ),
                ],

                // Loading State
                if (state is DownloadInitializing)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Initializing download manager...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _downloadImages(BuildContext context) {
    _logger.i('Starting image download test');

    // Queue and start download
    context.read<DownloadBloc>().add(DownloadQueueEvent(content: _testContent));
    context.read<DownloadBloc>().add(DownloadStartEvent(_testContent.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download started! Check notifications for progress.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _downloadAsPdf(BuildContext context) {
    _logger.i('Starting PDF download test');

    // Create PDF download params
    final pdfContent = _testContent.copyWith(
      // Mark for PDF conversion
      title: '${_testContent.title} (PDF)',
    );

    // Queue and start download
    context.read<DownloadBloc>().add(DownloadQueueEvent(content: pdfContent));
    context.read<DownloadBloc>().add(DownloadStartEvent(pdfContent.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('PDF download started! Check notifications for progress.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testServices(BuildContext context) async {
    _logger.i('Testing services');

    try {
      // Test NotificationService
      final notificationService = getIt<NotificationService>();
      await notificationService.showDownloadStarted(
        contentId: 'test',
        title: 'Test Notification',
      );

      // Test DownloadService
      final downloadService = getIt<DownloadService>();
      final isDownloaded =
          await downloadService.isContentDownloaded(_testContent.id);
      _logger.i('Content downloaded: $isDownloaded');

      // Test PdfService
      final pdfService = getIt<PdfService>();
      final pdfExists = await pdfService.pdfExists(_testContent.id,
          '/storage/emulated/0/Download/nhasix/${_testContent.id}');
      _logger.i('PDF exists: $pdfExists');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Services test completed! Downloaded: $isDownloaded, PDF: $pdfExists'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _logger.e('Services test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Services test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
