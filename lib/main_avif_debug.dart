import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AvifDebugApp());
}

class AvifDebugApp extends StatelessWidget {
  const AvifDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVIF Debug Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AvifDebugPage(),
    );
  }
}

class AvifDebugPage extends StatefulWidget {
  const AvifDebugPage({super.key});

  @override
  State<AvifDebugPage> createState() => _AvifDebugPageState();
}

class _AvifDebugPageState extends State<AvifDebugPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController();
  final Dio _dio = Dio();

  late final TabController _tabController;

  String? _activeUrl;
  String? _activeFilePath;
  String? _webpOutputPath;
  bool _isBusy = false;
  bool _isConverting = false;
  String _status = 'Idle';
  AvifHeaderInfo? _headerInfo;
  int? _convertElapsedMs;
  int? _convertInputBytes;
  int? _convertOutputBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _filePathController.dispose();
    _tabController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _loadFromUrl() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      _setStatus('URL kosong. Isi URL dulu.');
      return;
    }

    setState(() {
      _isBusy = true;
      _status = 'Downloading...';
    });

    try {
      final uri = Uri.tryParse(raw);
      if (uri == null || (!uri.hasScheme)) {
        throw Exception('URL tidak valid: $raw');
      }

      final tmpDir = await getTemporaryDirectory();
      final fileName =
          'avif_debug_${DateTime.now().millisecondsSinceEpoch}.avif';
      final localPath = '${tmpDir.path}/$fileName';

      final response = await _dio.get<List<int>>(
        raw,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      final bytes = Uint8List.fromList(response.data ?? <int>[]);
      if (bytes.isEmpty) {
        throw Exception('Response kosong');
      }

      final file = File(localPath);
      await file.writeAsBytes(bytes, flush: true);

      final info = _parseAvifHeader(bytes);

      setState(() {
        _activeUrl = raw;
        _activeFilePath = localPath;
        _webpOutputPath = null;
        _convertElapsedMs = null;
        _convertInputBytes = null;
        _convertOutputBytes = null;
        _filePathController.text = localPath;
        _headerInfo = info;
        _status = 'Downloaded ${bytes.length} bytes';
      });
    } catch (e) {
      _setStatus('Download gagal: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _loadFromLocalPath() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _setStatus('Path file kosong.');
      return;
    }

    setState(() {
      _isBusy = true;
      _status = 'Reading local file...';
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan: $path');
      }

      final bytes = await file.readAsBytes();
      final info = _parseAvifHeader(bytes);

      setState(() {
        _activeUrl = null;
        _activeFilePath = file.path;
        _webpOutputPath = null;
        _convertElapsedMs = null;
        _convertInputBytes = null;
        _convertOutputBytes = null;
        _headerInfo = info;
        _status = 'Loaded local file (${bytes.length} bytes)';
      });
    } catch (e) {
      _setStatus('Load local gagal: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _openInBrowser() async {
    final url = _activeUrl ?? _urlController.text.trim();
    if (url.isEmpty) {
      _setStatus('URL belum ada untuk dibuka.');
      return;
    }

    try {
      await KuronNative.instance.openWebView(url: url);
      _setStatus('Opened in browser/webview: $url');
    } catch (e) {
      _setStatus('Open browser gagal: $e');
    }
  }

  Future<void> _convertToWebP() async {
    if (_isConverting) return;

    final activePath = _activeFilePath;
    if (activePath == null || activePath.isEmpty) {
      _setStatus('Belum ada file AVIF aktif.');
      return;
    }

    final inputFile = File(activePath);
    if (!await inputFile.exists()) {
      _setStatus('File input tidak ditemukan: $activePath');
      return;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final outputPath = _buildDefaultWebPOutputPath(activePath, docsDir.path);
    final startedAt = DateTime.now();

    setState(() {
      _isConverting = true;
      _status = 'Converting AVIF → WebP...';
    });

    try {
      final convertedPath = await KuronNative.instance.convertAvifToWebP(
        inputPath: activePath,
        quality: 45,
        outputPath: outputPath,
      );

      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final inputBytes = await inputFile.length();
      int? outputBytes;
      if (convertedPath != null) {
        final outputFile = File(convertedPath);
        if (await outputFile.exists()) {
          outputBytes = await outputFile.length();
        }
      }

      if (!mounted) return;
      setState(() {
        _convertElapsedMs = elapsedMs;
        _convertInputBytes = inputBytes;
        _convertOutputBytes = outputBytes;
        _webpOutputPath = convertedPath;
        _status = convertedPath == null
            ? 'Konversi gagal (native return null).'
            : 'Konversi sukses: $convertedPath';
      });
    } catch (e) {
      _setStatus('Konversi gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  String _buildDefaultWebPOutputPath(String inputPath, String docsDirPath) {
    final fileName = inputPath.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final baseName = dot > 0 ? fileName.substring(0, dot) : fileName;
    return '$docsDirPath/$baseName.webp';
  }

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() {
      _status = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canRender = _activeFilePath != null && _activeFilePath!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AVIF Debug Lab'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flutter Decode'),
            Tab(text: 'Native Decode'),
            Tab(text: 'Convert'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildControls(canRender),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlutterPane(canRender),
                _buildNativePane(canRender),
                _buildConvertPane(canRender),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool canRender) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlController,
            enabled: !_isBusy,
            decoration: const InputDecoration(
              labelText: 'Remote AVIF URL',
              hintText: 'https://.../26.avif',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _loadFromUrl,
                  icon: const Icon(Icons.download),
                  label: const Text('Download to Temp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _openInBrowser,
                  icon: const Icon(Icons.public),
                  label: const Text('Open Browser'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _filePathController,
            enabled: !_isBusy,
            decoration: const InputDecoration(
              labelText: 'Local File Path (.avif)',
              hintText: '/path/to/26.avif',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isBusy ? null : _loadFromLocalPath,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Load Local File'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetadata(canRender),
          const SizedBox(height: 6),
          Text(
            _status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(bool canRender) {
    final info = _headerInfo;
    if (!canRender) {
      return const Text(
        'Load URL atau file lokal dulu untuk mulai debug.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('file', _activeFilePath ?? '-'),
        _chip('url', _activeUrl ?? '-'),
        _chip('brand', info?.majorBrand ?? '-'),
        _chip('compatible',
            (info?.compatibleBrands ?? const <String>[]).join(',')),
        _chip('ispe',
            info == null ? '-' : '${info.width ?? '?'}x${info.height ?? '?'}'),
      ],
    );
  }

  Widget _chip(String key, String value) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$key: $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFlutterPane(bool canRender) {
    if (!canRender) {
      return const Center(child: Text('No file loaded'));
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Image.file(
        File(_activeFilePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Flutter decode error: $error',
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNativePane(bool canRender) {
    if (!canRender) {
      return const Center(child: Text('No file loaded'));
    }

    if (!AnimatedWebPView.isAvailable) {
      return const Center(
        child: Text('Native animated view only available on Android.'),
      );
    }

    final nativeView = AnimatedWebPView(
      key: ValueKey('native_${_activeFilePath}_${_activeUrl ?? 'local'}'),
      url: _activeUrl ?? _activeFilePath!,
      filePath: _activeFilePath,
      autoPlay: true,
      fallback: const Center(child: CircularProgressIndicator()),
      loadingBuilder: (context, received, total) {
        final totalStr = total == null ? '?' : '$total';
        return Center(
          child: Text('Preparing native preview $received/$totalStr'),
        );
      },
    );

    final width = _headerInfo?.width;
    final height = _headerInfo?.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return Center(
        child: AspectRatio(
          aspectRatio: width / height,
          child: nativeView,
        ),
      );
    }

    return nativeView;
  }

  Widget _buildConvertPane(bool canRender) {
    if (!canRender) {
      return const Center(
        child:
            Text('Load AVIF dulu. Tombol convert akan aktif setelah file ada.'),
      );
    }

    final canConvert = _activeFilePath != null && !_isConverting;
    final outputPath = _webpOutputPath;
    final resolvedOutputPath = outputPath ?? '';
    final outputReady = resolvedOutputPath.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: canConvert ? _convertToWebP : null,
            icon: _isConverting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.transform),
            label: Text(
              _isConverting ? 'Converting...' : 'Convert to WebP (q=45)',
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conversion Stats',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Input: ${_formatBytes(_convertInputBytes)}'),
                  Text('Output: ${_formatBytes(_convertOutputBytes)}'),
                  Text(
                    'Elapsed: ${_convertElapsedMs == null ? '-' : '$_convertElapsedMs ms'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Output: ${outputPath ?? '-'}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (!outputReady)
            const Center(child: Text('Belum ada output WebP.'))
          else if (!AnimatedWebPView.isAvailable)
            const Center(
              child: Text('Animated preview hanya tersedia di Android.'),
            )
          else
            AspectRatio(
              aspectRatio: 9 / 16,
              child: AnimatedWebPView(
                key: ValueKey('convert_$outputPath'),
                url: resolvedOutputPath,
                filePath: outputPath,
                autoPlay: true,
                fallback: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  AvifHeaderInfo _parseAvifHeader(Uint8List bytes) {
    String? majorBrand;
    final compatibleBrands = <String>[];
    int? width;
    int? height;

    if (bytes.length >= 12) {
      majorBrand = _readAscii(bytes, 8, 4);
      for (int i = 16; i + 4 <= bytes.length && i < 64; i += 4) {
        compatibleBrands.add(_readAscii(bytes, i, 4));
      }
    }

    const ispeSig = <int>[0x69, 0x73, 0x70, 0x65]; // ispe
    for (int i = 0; i <= bytes.length - 16; i++) {
      if (_matches(bytes, i, ispeSig)) {
        width = _readU32(bytes, i + 8);
        height = _readU32(bytes, i + 12);
        break;
      }
    }

    return AvifHeaderInfo(
      majorBrand: majorBrand,
      compatibleBrands: compatibleBrands,
      width: width,
      height: height,
    );
  }

  bool _matches(Uint8List bytes, int start, List<int> sig) {
    for (int i = 0; i < sig.length; i++) {
      if (bytes[start + i] != sig[i]) return false;
    }
    return true;
  }

  int _readU32(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) return 0;
    return ((bytes[offset] & 0xFF) << 24) |
        ((bytes[offset + 1] & 0xFF) << 16) |
        ((bytes[offset + 2] & 0xFF) << 8) |
        (bytes[offset + 3] & 0xFF);
  }

  String _readAscii(Uint8List bytes, int offset, int length) {
    if (offset + length > bytes.length) return '';
    return String.fromCharCodes(bytes.sublist(offset, offset + length));
  }
}

class AvifHeaderInfo {
  const AvifHeaderInfo({
    required this.majorBrand,
    required this.compatibleBrands,
    required this.width,
    required this.height,
  });

  final String? majorBrand;
  final List<String> compatibleBrands;
  final int? width;
  final int? height;
}
