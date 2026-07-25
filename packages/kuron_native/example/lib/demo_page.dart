import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuron_native/kuron_native.dart';
import 'models/ai_provider_config.dart';
import 'models/bubble_box.dart';
import 'models/page_translation.dart';
// import 'services/mosaic_builder.dart';
import 'widgets/translation_style_picker.dart';

enum PipelineState {
  welcome,
  imageLoaded,
  detecting,
  detected,
  buildingMosaic,
  translating,
  translated,
  error,
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  PipelineState _state = PipelineState.welcome;
  String? _error;
  String _style = 'natural';
  String _targetLang = 'Indonesia';
  bool _overlayVisible = false;
  bool _showDetection = false;
  bool _isManualMode = false;
  double _renderScaleX = 1.0, _renderScaleY = 1.0; // image→widget scale

  // Image data
  Uint8List? _pageBytes;
  ui.Image? _pageImage;
  int _imgW = 0, _imgH = 0;

  // AI Provider config (bisa diset lewat Test Provider sheet)
  String _providerBaseUrl = '';
  String _providerModel = '';
  String _providerKey = '';

  List<BubbleBox> _detectedBoxes = [];
  PageTranslation? _translation;
  final List<BubbleBox> _manualBoxes = [];

  // Drawing
  bool _isDrawing = false;
  Offset? _drawStart, _drawEnd;

  final List<String> _log = [];
  final _imageAreaKey = GlobalKey();

  /// Build mosaic in a background isolate so UI doesn't freeze.
  /// Accepts serializable data, returns JPEG bytes.
  Future<Uint8List?> _buildMosaicIsolate(
    Uint8List pageBytes,
    List<Map<String, dynamic>> boxMaps,
    int imgW,
    int imgH,
  ) async {
    return Isolate.run(() {
      final original = img.decodeImage(pageBytes);
      if (original == null) return null;

      final chips = <img.Image>[];
      for (final m in boxMaps) {
        final bx = (m['x'] as num).toInt(), by = (m['y'] as num).toInt();
        final bw = (m['w'] as num).toInt(), bh = (m['h'] as num).toInt();
        final padX = (bw * 0.4).round(), padY = (bh * 0.4).round();
        final cx = (bx - padX).clamp(0, original.width - 1);
        final cy = (by - padY).clamp(0, original.height - 1);
        final cw = (bw + padX * 2).clamp(1, original.width - cx);
        final ch = (bh + padY * 2).clamp(1, original.height - cy);
        var crop = img.copyCrop(original, x: cx, y: cy, width: cw, height: ch);
        crop = img.copyResize(crop, width: (cw * 2).clamp(1, 2000));
        // Label
        final font = img.arial24;
        final lblW = '${boxMaps.indexOf(m) + 1}'.length * 14 + 8;
        final lbl = img.Image(width: lblW, height: crop.height);
        img.fill(lbl, color: img.ColorRgba8(255, 255, 255, 255));
        img.drawString(
          lbl,
          '${boxMaps.indexOf(m) + 1}',
          font: font,
          x: 4,
          y: (crop.height ~/ 2) - 12,
          color: img.ColorRgba8(255, 0, 0, 255),
        );
        final combined = img.Image(
          width: lblW + crop.width,
          height: crop.height,
        );
        img.compositeImage(combined, lbl, dstX: 0, dstY: 0);
        img.compositeImage(combined, crop, dstX: lblW, dstY: 0);
        chips.add(combined);
      }

      final gap = 10;
      final mw = chips.map((c) => c.width).reduce((a, b) => a > b ? a : b);
      final mh =
          chips.fold(0, (sum, c) => sum + c.height) + gap * (chips.length - 1);
      final mosaic = img.Image(width: mw, height: mh);
      var yo = 0;
      for (final c in chips) {
        img.compositeImage(mosaic, c, dstX: 0, dstY: yo);
        yo += c.height + gap;
      }

      return img.encodeJpg(mosaic, quality: 85);
    });
  }

  @override
  void initState() {
    super.initState();
    _log.add('App ready. Tap "Load Test Image" to start.');
  }

  @override
  void dispose() {
    _pageImage?.dispose();
    super.dispose();
  }

  void _logm(String msg) => setState(() => _log.add('[${_log.length}] $msg'));

  // ── Load image ───────────────────────────────────────────

  Future<void> _loadTestImage() async {
    _logm('Loading test image...');
    try {
      final data = await rootBundle.load('assets/sample_manga.webp');
      _pageBytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(_pageBytes!);
      final frame = await codec.getNextFrame();
      _pageImage?.dispose();
      _pageImage = frame.image;
      _imgW = _pageImage!.width;
      _imgH = _pageImage!.height;
      codec.dispose();
      _resetPipeline();
      _logm('Image loaded: ${_imgW}x$_imgH px');
      setState(() => _state = PipelineState.imageLoaded);
    } catch (e) {
      _logm('FAILED to load image: $e');
      setState(() {
        _state = PipelineState.error;
        _error = 'Failed to load test image.';
      });
    }
  }

  void _resetPipeline() {
    _detectedBoxes = [];
    _translation = null;
    _manualBoxes.clear();
    _overlayVisible = false;
    _showDetection = false;

    _isDrawing = false;
    _error = null;
  }

  // ── Detection ────────────────────────────────────────────

  Future<void> _runDetection() async {
    if (_pageBytes == null) return;
    _logm('Running bubble detection...');
    setState(() => _state = PipelineState.detecting);
    await Future.delayed(const Duration(milliseconds: 800));

    _detectedBoxes = await _realDetect(_pageBytes!, _imgW, _imgH);
    _manualBoxes.clear();
    _showDetection = true;
    _overlayVisible = false;
    _logm('Detection done: ${_detectedBoxes.length} bubbles');
    setState(() => _state = PipelineState.detected);
  }

  // ── Translate (REAL AI) ───────────────────────────────────

  Future<void> _runTranslation() async {
    _logm('runTranslation called, state=$_state');
    final boxes = _activeBoxes;
    _logm(
      'boxes=${boxes.length}, pageBytes=${_pageBytes != null}, manual=$_isManualMode',
    );
    if (boxes.isEmpty || _pageBytes == null) {
      _logm('SKIP: no boxes or no image');
      return;
    }
    _logm('Building mosaic + sending to AI (style: $_style)...');
    setState(() => _state = PipelineState.translating);

    try {
      // 1. Build mosaic in isolate biar gak blokir UI
      _logm('Building mosaic...');
      final t0 = DateTime.now();
      final boxMaps = boxes.map((b) => b.toJson()).toList();
      final jpeg = await _buildMosaicIsolate(
        _pageBytes!,
        boxMaps,
        _imgW,
        _imgH,
      );
      if (jpeg == null) {
        _logm('FAILED: mosaic null');
        setState(() {
          _state = PipelineState.error;
          _error = 'Translate gagal';
        });
        return;
      }
      _logm(
        'Mosaic ready in ${DateTime.now().difference(t0).inMilliseconds}ms (${jpeg.length} bytes)',
      );
      final b64 = base64Encode(jpeg);

      // 3. Build prompt with style
      final styleInjection = _stylePrompt(_style);
      final prompt =
          'Translate manga image to $_targetLang.\n\n'
          'Each bubble has a RED NUMBER on its LEFT side.\n\n'
          'Format: <|1|>translation\\n<|2|>translation\\n<|3|>SKIP\\n...\n\n'
          'Example:\n'
          '<|1|>Dunia ini indah\n'
          '<|2|>Aku akan terus hidup\n'
          '<|3|>SKIP\n\n'
          'RULES:\n'
          '- SFX-only bubbles → SKIP\n'
          '- Keep honorifics (-san, -kun, -chan) as-is\n'
          '- Translate ALL visible bubbles\n'
          '$styleInjection\n'
          'Return ONLY the <|N|> lines. No markdown, no thinking.';

      // 4. Call AI (openai-compatible or gemini)
      final isGemini = _providerModel.startsWith('gemini-');
      _logm('Provider: $_providerModel @ $_providerBaseUrl (gemini=$isGemini)');
      final client = HttpClient();
      try {
        HttpClientRequest req;
        if (isGemini) {
          // Gemini API
          final url =
              '$_providerBaseUrl/v1beta/models/$_providerModel:generateContent?key=$_providerKey';
          req = await client.postUrl(Uri.parse(url));
          req.headers.contentType = ContentType.json;
          req.write(
            jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {'mime_type': 'image/jpeg', 'data': b64},
                    },
                  ],
                },
              ],
            }),
          );
        } else {
          // OpenAI-compatible
          req = await client.postUrl(Uri.parse(_providerBaseUrl));
          req.headers.contentType = ContentType.json;
          if (_providerKey.isNotEmpty) {
            req.headers.set('Authorization', 'Bearer $_providerKey');
          }
          req.write(
            jsonEncode({
              'model': _providerModel,
              'stream': false,
              'max_tokens': 1000,
              'thinking': {'type': 'disabled'},
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': prompt},
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                    },
                  ],
                },
              ],
            }),
          );
        }
        final resp = await req.close();
        final body = await resp.transform(utf8.decoder).join();

        if (resp.statusCode != 200) {
          _logm(
            'AI error HTTP ${resp.statusCode}: ${body.substring(0, body.length.clamp(0, 200))}',
          );
          setState(() {
            _state = PipelineState.error;
            _error = 'Translate gagal';
          });
          return;
        }

        final json = jsonDecode(body) as Map<String, dynamic>;
        String? content;
        if (isGemini) {
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = (candidates[0] as Map)['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              content = parts[0]['text'] as String?;
            }
          }
        } else {
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final msg = choices[0]['message'] as Map?;
            content = msg?['content'] as String?;
            // Reasoning models (kimi, glm, deepseek) put answer in reasoning_content
            if ((content == null || content.trim().isEmpty) &&
                msg?['reasoning_content'] != null) {
              content = msg?['reasoning_content'] as String?;
            }
          }
        }
        if (content == null || content.isEmpty) {
          _logm('FAILED: empty AI response');
          setState(() {
            _state = PipelineState.error;
            _error = 'Translate gagal';
          });
          return;
        }

        _logm('AI raw: ${content.substring(0, content.length.clamp(0, 200))}');

        // 5. Parse response — try JSON first, fallback to <|N|> format
        final translations = <String, String>{};
        bool parsed = false;

        // Try JSON
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}');
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          try {
            final jsonStr = content.substring(jsonStart, jsonEnd + 1);
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            for (final e in map.entries) {
              translations[e.key] = e.value?.toString() ?? '';
            }
            parsed = true;
          } catch (_) {}
        }

        // Fallback to <|N|> format
        if (!parsed) {
          final pipeRe = RegExp(r'<\|(\d+)\|>\s*(.+?)(?:\n|$)');
          for (final m in pipeRe.allMatches(content)) {
            translations[m.group(1)!] = m.group(2)!.trim();
          }
          if (translations.isNotEmpty) parsed = true;
        }

        if (!parsed) {
          _logm('FAILED: no translations in response');
          setState(() {
            _state = PipelineState.error;
            _error = 'Translate gagal';
          });
          return;
        }

        // 6. Build PageTranslation
        final bubbleTranslations = <BubbleTranslation>[];
        for (var i = 0; i < boxes.length; i++) {
          final idStr = '${i + 1}';
          final translated = translations[idStr] ?? '';
          bubbleTranslations.add(
            BubbleTranslation(
              id: i + 1,
              original: '',
              translated: translated,
              x: boxes[i].x,
              y: boxes[i].y,
              w: boxes[i].w,
              h: boxes[i].h,
            ),
          );
        }

        _translation = PageTranslation(bubbles: bubbleTranslations);
        _overlayVisible = true;

        _logm(
          'Done! ${bubbleTranslations.where((b) => !b.isSkipped).length} bubbles translated',
        );
        setState(() => _state = PipelineState.translated);
      } finally {
        client.close();
      }
    } catch (e) {
      _logm('FAILED: $e');
      setState(() {
        _state = PipelineState.error;
        _error = '$e';
      });
    }
  }

  String _stylePrompt(String style) {
    switch (style) {
      case 'literal':
        return 'Translate accurately and literally. Preserve exact tone.';
      case 'natural':
        return 'Use natural, fluent Indonesian as a native speaker.';
      case 'gaul':
        return 'Use informal Indonesian slang: gue/lo instead of saya/kamu.';
      case 'perwibuan':
        return 'Gunakan bahasa Indonesia keraton: hamba, paduka, berkenan.';
      case 'kasar':
        return 'Gunakan kata kasar ringan: anjir, bangsat, goblok.';
      case 'emakGosip':
        return 'Gaya emak gosip: Eh tau nggak sih!, Ya ampun!';
      case 'bapack':
        return 'Gaya bapak-bapak: ngab, suhu, kopi dulu, mantap jaya.';
      case 'betawi':
        return 'Gaya Betawi: aye, elu, kagak. Plus pantun pendek.';
      default:
        return '';
    }
  }

  // ── Manual bubbles ───────────────────────────────────────

  List<BubbleBox> get _activeBoxes {
    if (_manualBoxes.isNotEmpty) return _manualBoxes;
    return _detectedBoxes;
  }

  void _toggleManualMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      _isDrawing = false;
    });
    _logm('Manual bubble mode ${_isManualMode ? "ON" : "OFF"}');
  }

  void _onDrawStart(Offset p) {
    if (!_isManualMode) return;
    _drawStart = p;
    _drawEnd = p;
    _isDrawing = true;
  }

  void _onDrawMove(Offset p) {
    if (!_isManualMode || !_isDrawing) return;
    _drawEnd = p;
    setState(() {});
  }

  void _onDrawEnd(Offset p) {
    if (!_isManualMode || !_isDrawing || _drawStart == null) return;
    _isDrawing = false;
    _drawEnd = p;
    final r = Rect.fromPoints(
      Offset(_drawStart!.dx.clamp(0, 1e9), _drawStart!.dy.clamp(0, 1e9)),
      Offset(p.dx.clamp(0, 1e9), p.dy.clamp(0, 1e9)),
    );
    if (r.width < 20 || r.height < 20) {
      _logm('Area too small, skipped.');
      _drawStart = _drawEnd = null;
      return;
    }
    final renderBox =
        _imageAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final rs = renderBox.size;
    if (rs.width <= 0 || rs.height <= 0) return;
    final sx = _imgW / rs.width, sy = _imgH / rs.height;

    _manualBoxes.add(
      BubbleBox(
        x: (r.left * sx).round(),
        y: (r.top * sy).round(),
        w: (r.width * sx).round(),
        h: (r.height * sy).round(),
        confidence: 1.0,
      ),
    );
    _logm('Manual bubble added');
    _drawStart = _drawEnd = null;
    setState(() {});
  }

  void _removeDetected(int i) {
    if (i >= 0 && i < _detectedBoxes.length) {
      _detectedBoxes.removeAt(i);
      setState(() {});
    }
  }

  void _removeManual(int i) {
    if (i >= 0 && i < _manualBoxes.length) {
      _manualBoxes.removeAt(i);
      setState(() {});
    }
  }

  void _clearAll() {
    _resetPipeline();
    _logm('All reset');
    setState(() => _state = PipelineState.imageLoaded);
  }

  // ── Real ONNX detection ────────────────────────────────

  Future<List<BubbleBox>> _realDetect(
    Uint8List bytes,
    int imgW,
    int imgH,
  ) async {
    try {
      final result = await KuronNative.instance.detectBubbles(
        imageBytes: bytes,
        imageWidth: imgW,
        imageHeight: imgH,
      );
      if (result == null || result.isEmpty) {
        _logm('ONNX: no bubbles detected');
        return [];
      }
      _logm('ONNX: ${result.length} bubbles detected');
      return result
          .map(
            (m) => BubbleBox(
              x: (m['x'] as num).toInt(),
              y: (m['y'] as num).toInt(),
              w: (m['w'] as num).toInt(),
              h: (m['h'] as num).toInt(),
              confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();
    } catch (e) {
      _logm('ONNX detect failed: $e');
      return [];
    }
  }

  // ── Provider test ─────────────────────────────────────────

  void _showProviderTestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => _ProviderTestSheet(
        onSave: (url, model, key) {
          setState(() {
            _providerBaseUrl = url;
            _providerModel = model;
            _providerKey = key;
          });
          _logm('Provider saved: $model');
        },
      ),
    );
  }

  // ── Status ────────────────────────────────────────────────

  String _statusText() {
    switch (_state) {
      case PipelineState.welcome:
        return 'Tap "Load Test Image"';
      case PipelineState.imageLoaded:
        return 'Image loaded. Run detection.';
      case PipelineState.detecting:
        return 'Detecting bubbles...';
      case PipelineState.detected:
        final t = _detectedBoxes.length + _manualBoxes.length;
        return '$t bubbles (${_detectedBoxes.length} ONNX + ${_manualBoxes.length} manual)';
      case PipelineState.buildingMosaic:
        return 'Building mosaic...';
      case PipelineState.translating:
        return 'Translating...';
      case PipelineState.translated:
        return 'Done! ${_translation?.bubbles.where((b) => !b.isSkipped).length} translated';
      case PipelineState.error:
        return 'Error: $_error';
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Translate Demo - Kuron'),
        actions: _state == PipelineState.welcome
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset',
                  onPressed: _clearAll,
                ),
              ],
      ),
      body: _state == PipelineState.welcome ? _buildWelcome(t) : _buildMain(t),
    );
  }

  Widget _buildWelcome(ThemeData t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: t.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'AI Translation Pipeline',
            style: t.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detect → Mosaic → AI Translate → Overlay\n\n'
            '• ONNX bubble detection (simulated)\n'
            '• Mosaic builder with red labels\n'
            '• Multi-provider AI (Zen/Gemini/OpenAI)\n'
            '• 8 translation styles\n'
            '• Manual bubble add/remove',
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _loadTestImage,
            icon: const Icon(Icons.image),
            label: const Text('Load Test Image'),
          ),
        ],
      ),
    ),
  );

  Widget _buildMain(ThemeData t) {
    final boxes = _activeBoxes;
    // Top action bar
    final topBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: t.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _statusText(),
              style: t.textTheme.bodySmall?.copyWith(
                color: _state == PipelineState.error
                    ? t.colorScheme.error
                    : t.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_state == PipelineState.imageLoaded)
            FilledButton.tonalIcon(
              onPressed: _runDetection,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Detect'),
            ),
          if (_state == PipelineState.detected && boxes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: FilledButton.icon(
                onPressed: _runTranslation,
                icon: const Icon(Icons.translate, size: 18),
                label: const Text('Translate'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              onPressed: () => _showProviderTestSheet(context),
              child: Text(
                _providerModel.split('/').last,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );

    // Image area — uses LayoutBuilder to capture rendered size for scale factors
    Widget imgArea = Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Compute rendered image size (fitWidth)
          final availW = constraints.maxWidth;
          final availH = constraints.maxHeight;
          if (_pageImage == null || availW <= 0 || availH <= 0)
            return const SizedBox();

          final renderedW = availW;
          final renderedH = _imgH * (renderedW / _imgW);
          // Store scale factors as instance fields
          _renderScaleX = renderedW / _imgW;
          _renderScaleY = renderedH / _imgH;

          return SizedBox(
            key: _imageAreaKey,
            width: renderedW,
            height: renderedH.clamp(0, availH),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Raw image
                RawImage(
                  image: _pageImage,
                  width: renderedW,
                  height: renderedH,
                  fit: BoxFit.fill,
                ),

                // Drawing layer pointer listener
                if (_isManualMode)
                  Listener(
                    onPointerDown: (e) => _onDrawStart(e.localPosition),
                    onPointerMove: (e) => _onDrawMove(e.localPosition),
                    onPointerUp: (e) => _onDrawEnd(e.localPosition),
                    child: AbsorbPointer(
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // In-progress draw rect
                if (_isDrawing && _drawStart != null && _drawEnd != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RectPainter(
                          rect: Rect.fromPoints(_drawStart!, _drawEnd!),
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),

                // Detection overlay (blue)
                if (_showDetection && !_overlayVisible)
                  ...List.generate(_detectedBoxes.length, (i) {
                    final b = _detectedBoxes[i];
                    return Positioned(
                      left: b.x * _renderScaleX,
                      top: b.y * _renderScaleY,
                      width: b.w * _renderScaleX,
                      height: b.h * _renderScaleY,
                      child: GestureDetector(
                        onTap: () => _removeDetected(i),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 2,
                            ),
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // Manual overlay (green)
                if (_isManualMode)
                  ...List.generate(_manualBoxes.length, (i) {
                    final b = _manualBoxes[i];
                    return Positioned(
                      left: b.x * _renderScaleX,
                      top: b.y * _renderScaleY,
                      width: b.w * _renderScaleX,
                      height: b.h * _renderScaleY,
                      child: GestureDetector(
                        onTap: () => _removeManual(i),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              'M${i + 1}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // Translation overlay (amber) — text wrap ke bawah
                if (_overlayVisible && _translation != null)
                  ..._translation!.bubbles.where((b) => !b.isSkipped).map((b) {
                    final boxW = b.w * _renderScaleX;
                    final boxH = b.h * _renderScaleY;
                    final padding = 4.0;
                    final textAreaW = (boxW - padding * 2).clamp(10.0, 600.0);
                    final textAreaH = (boxH - padding * 2).clamp(10.0, 600.0);
                    // Auto-fit: cari font size terbesar yg muat
                    final textLen = b.translated.length;
                    var fontSize = 24.0;
                    if (textLen > 0) {
                      // Estimasi lebar teks: ~fontSize * 0.6 px per karakter
                      final estWidth = fontSize * 0.58 * textLen;
                      final estLines = (estWidth / textAreaW).ceil();
                      final neededH = estLines * fontSize * 1.3;
                      if (neededH > textAreaH || estWidth > textAreaW) {
                        // Turunin font biar muat
                        while (fontSize > 8) {
                          final ew = fontSize * 0.58 * textLen;
                          final el = (ew / textAreaW).ceil();
                          final nh = el * fontSize * 1.3;
                          if (nh <= textAreaH && ew <= textAreaW * 1.1) break;
                          fontSize -= 1;
                        }
                      }
                    }
                    fontSize = fontSize.clamp(10.0, 28.0);
                    return Positioned(
                      left: b.x * _renderScaleX,
                      top: b.y * _renderScaleY,
                      width: boxW,
                      height: boxH,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        padding: EdgeInsets.all(padding),
                        child: SingleChildScrollView(
                          child: Text(
                            b.translated,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    );
                  }),

                // Loading overlay
                if (_state == PipelineState.detecting ||
                    _state == PipelineState.buildingMosaic ||
                    _state == PipelineState.translating)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Bottom bar: style picker + controls + log
    final bottomBar = Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: t.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('→', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              SizedBox(
                width: 110,
                height: 32,
                child: DropdownButtonFormField<String>(
                  initialValue: _targetLang,
                  isDense: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items:
                      [
                            'Indonesia',
                            'English',
                            'Japanese',
                            'Korean',
                            'Chinese',
                            'Arabic',
                            'Thai',
                            'Russian',
                            'Spanish',
                            'Portuguese',
                            'French',
                          ]
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(
                                l,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _targetLang = v);
                    _logm('Target: $v');
                    if (_state == PipelineState.translated) _runTranslation();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TranslationStylePicker(
                  selectedStyle: _style,
                  onChanged: (s) {
                    setState(() => _style = s);
                    _logm('Style: $s');
                    if (_state == PipelineState.translated) _runTranslation();
                  },
                  compact: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_state == PipelineState.detected)
                TextButton.icon(
                  onPressed: _toggleManualMode,
                  icon: Icon(
                    Icons.edit,
                    size: 18,
                    color: _isManualMode ? Colors.green : null,
                  ),
                  label: Text(
                    _isManualMode ? 'Manual ON' : 'Manual',
                    style: TextStyle(
                      color: _isManualMode ? Colors.green : null,
                      fontWeight: _isManualMode ? FontWeight.bold : null,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showProviderTestSheet(context),
                icon: const Icon(Icons.api, size: 18),
                label: const Text('Test Provider'),
              ),
              const SizedBox(width: 4),
              if (_state == PipelineState.translated)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _overlayVisible = !_overlayVisible),
                  icon: Icon(
                    _overlayVisible ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  label: Text(_overlayVisible ? 'Hide' : 'Show'),
                ),
            ],
          ),
        ],
      ),
    );

    final logPanel = Container(
      height: 80,
      color: t.colorScheme.surfaceContainerHigh,
      child: ListView(
        padding: const EdgeInsets.all(6),
        children: _log.reversed
            .take(20)
            .map(
              (m) => Text(
                m,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: m.startsWith('FAIL')
                      ? t.colorScheme.error
                      : t.colorScheme.onSurfaceVariant,
                ),
              ),
            )
            .toList(),
      ),
    );

    return Column(children: [topBar, imgArea, bottomBar, logPanel]);
  }
}

// ── Drawing helper ──────────────────────────────────────

class _RectPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  _RectPainter({required this.rect, required this.color});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    c.drawRect(rect, p);
    p
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(rect, p);
  }

  @override
  bool shouldRepaint(_RectPainter old) => rect != old.rect;
}

// ── Provider test sheet ─────────────────────────────────

class _ProviderTestSheet extends StatefulWidget {
  final void Function(String baseUrl, String model, String apiKey)? onSave;
  const _ProviderTestSheet({this.onSave});
  @override
  State<_ProviderTestSheet> createState() => _ProviderTestSheetState();
}

class _ProviderTestSheetState extends State<_ProviderTestSheet> {
  AiProviderType _selectedType = AiProviderType.custom;
  final _apiKeyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  String _result = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl.text = AiProviderConfig.defaultBaseUrl(_selectedType);
    _modelCtrl.text =
        AiProviderConfig.defaultModels[_selectedType] ?? 'ocg/minimax-m3';
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final needsKey = _selectedType != AiProviderType.zen;
    final isCustom = _selectedType == AiProviderType.custom;
    final defaultBaseUrl = AiProviderConfig.defaultBaseUrl(_selectedType);
    final defaultModel = AiProviderConfig.defaultModels[_selectedType] ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test AI Provider',
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Uji koneksi provider dengan teks sample. Zen gratis tanpa key.',
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Provider type
            DropdownButtonFormField<AiProviderType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Provider Type',
                border: OutlineInputBorder(),
              ),
              items: AiProviderType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedType = v!;
                  _baseUrlCtrl.text = AiProviderConfig.defaultBaseUrl(v);
                  _modelCtrl.text = AiProviderConfig.defaultModels[v] ?? '';
                });
              },
            ),
            const SizedBox(height: 12),

            // API key (not needed for Zen)
            if (needsKey)
              TextField(
                controller: _apiKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            if (needsKey) const SizedBox(height: 12),

            // Base URL (custom only editable, others pre-filled)
            TextField(
              controller: _baseUrlCtrl..text = defaultBaseUrl,
              decoration: InputDecoration(
                labelText: 'Base URL',
                border: const OutlineInputBorder(),
                enabled: isCustom,
                helperText: isCustom
                    ? ''
                    : 'Pre-filled for ${_selectedType.name}',
              ),
            ),
            const SizedBox(height: 12),

            // Model
            TextField(
              controller: _modelCtrl..text = defaultModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Test text sample
            Text('Sample text to translate:', style: t.textTheme.bodySmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '「この世界は美しい。だから私は生き続ける。」',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // Test button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _testProvider,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: Text(_loading ? 'Testing...' : 'Test Connection'),
              ),
            ),
            const SizedBox(height: 12),

            // Result
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result.startsWith('✓')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _result,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _result.startsWith('✓')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (_result.startsWith('✓'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            widget.onSave?.call(
                              _baseUrlCtrl.text.trim(),
                              _modelCtrl.text.trim(),
                              _apiKeyCtrl.text.trim(),
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text('Use for Translate'),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _testProvider() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    final baseUrl = _baseUrlCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    try {
      if (_selectedType == AiProviderType.gemini) {
        _result = await _testGemini(baseUrl, apiKey, model);
      } else {
        _result = await _testOpenAICompatible(
          baseUrl,
          apiKey,
          model,
          _selectedType,
        );
      }
    } catch (e) {
      _result = '✗ Error: $e';
    }

    if (mounted) setState(() => _loading = false);

    // Auto-save + close sheet on success
    if (_result.startsWith('✓') && widget.onSave != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        widget.onSave!(baseUrl, model, apiKey);
        Navigator.of(context).pop();
      }
    }
  }

  Future<String> _testOpenAICompatible(
    String baseUrl,
    String apiKey,
    String model,
    AiProviderType type,
  ) async {
    final url = type == AiProviderType.gemini
        ? '$baseUrl/v1beta/models/$model:generateContent'
        : baseUrl;

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (type == AiProviderType.zen) {
      // Zen: free, no auth needed
    } else if (type == AiProviderType.custom && apiKey.isEmpty) {
      // Custom without key: no auth
    } else if (type == AiProviderType.openRouter) {
      headers['Authorization'] = 'Bearer $apiKey';
      headers['HTTP-Referer'] = 'https://github.com/nhasixapp';
    } else {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final sampleText = 'この世界は美しい。だから私は生き続ける。';
    Object body;
    if (type == AiProviderType.gemini) {
      body = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Translate the following Japanese text to Indonesian. Return ONLY the translation, no explanation:\n$sampleText',
              },
            ],
          },
        ],
      };
    } else {
      body = {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Translate the following Japanese text to Indonesian. Return ONLY the translation, no explanation:\n$sampleText',
              },
            ],
          },
        ],
        'max_tokens': 200,
        'temperature': 0.3,
      };
    }

    final requestBody = jsonEncode(body);

    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(url));
      headers.forEach((k, v) => req.headers.set(k, v));
      req.headers.contentType = ContentType.json;
      req.write(requestBody);

      final resp = await req.close();
      final sc = resp.statusCode;
      var respBody = await resp.transform(utf8.decoder).join();

      // Handle SSE streaming response — strip "data:" prefix lines
      if (respBody.trimLeft().startsWith('data:')) {
        final lines = respBody.split('\n');
        final jsonParts = <String>[];
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            jsonParts.add(trimmed.substring(5).trim());
          }
        }
        // Merge all JSON chunks — last non-empty delta['content'] wins
        String? mergedContent;
        for (final part in jsonParts) {
          if (part.isEmpty || part == '[DONE]') continue;
          try {
            final chunk = jsonDecode(part) as Map<String, dynamic>;
            final choices = chunk['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                mergedContent = (mergedContent ?? '') + content;
              }
            }
          } catch (_) {}
        }
        if (mergedContent != null) {
          return '✓ Success! Terjemahan: $mergedContent\n(Model: ocg/minimax-m3)';
        }
        return '✗ Response streaming tapi kosong.';
      }

      if (sc == 200) {
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        String? translation;

        if (type == AiProviderType.gemini) {
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0] as Map<String, dynamic>;
            final parts = content['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              translation = parts[0]['text'] as String?;
            }
          }
        } else {
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final msg = choices[0]['message'] as Map<String, dynamic>?;
            if (msg != null) translation = msg['content'] as String?;
          }
        }

        if (translation != null && translation.isNotEmpty) {
          return '✓ Success! Terjemahan: $translation\n(Provider: ${_selectedType.name}, Model: $model)';
        } else {
          return '✗ Response OK tapi tidak ada teks. Raw:\n${respBody.substring(0, respBody.length.clamp(0, 300))}';
        }
      } else if (sc == 429) {
        return '✗ Rate limited (429). Coba lagi nanti.';
      } else if (sc == 401 || sc == 403) {
        return '✗ Auth failed ($sc). Cek API key.';
      } else {
        return '✗ HTTP $sc: ${respBody.substring(0, respBody.length.clamp(0, 200))}';
      }
    } finally {
      client.close();
    }
  }

  Future<String> _testGemini(
    String baseUrl,
    String apiKey,
    String model,
  ) async {
    final url = '$baseUrl/v1beta/models/$model:generateContent?key=$apiKey';
    final headers = {'Content-Type': 'application/json'};
    final sampleText = 'この世界は美しい。だから私は生き続ける。';
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Translate the following Japanese text to Indonesian. Return ONLY the translation, no explanation:\n$sampleText',
            },
          ],
        },
      ],
    });

    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(url));
      headers.forEach((k, v) => req.headers.set(k, v));
      req.headers.contentType = ContentType.json;
      req.write(body);
      final resp = await req.close();
      final sc = resp.statusCode;
      final respBody = await resp.transform(utf8.decoder).join();

      if (sc == 200) {
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0] as Map<String, dynamic>;
          final parts = content['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return '✓ Gemini Success! Terjemahan: $text';
            }
          }
        }
        return '✗ Response OK tapi parsing gagal. Raw:\n${respBody.substring(0, 300)}';
      } else {
        return '✗ HTTP $sc: ${respBody.substring(0, 200)}';
      }
    } finally {
      client.close();
    }
  }
}
