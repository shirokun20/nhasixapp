import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:image/image.dart' as img;

import '../../../core/utils/webtoon_detector.dart';
import '../../../data/repositories/ai/ai_provider_factory.dart';
import '../../../data/repositories/ai/fallback_image_handler.dart';
import '../../../data/repositories/ai/mosaic_builder.dart';
import '../../../domain/entities/ai_translation.dart';
import '../../../domain/entities/reader_settings_entity.dart';
import '../../../domain/repositories/ai_translation_repositories.dart';
import '../base/base_cubit.dart';

part 'reader_translation_state.dart';

/// Orchestrates the AI translation pipeline for the active reader page:
/// webtoon detection → ONNX bubble detection → mosaic/fallback → provider →
/// cache → translated state.
///
/// Guard: disabled in `ReadingMode.continuousScroll`.
class ReaderTranslationCubit extends BaseCubit<ReaderTranslationState> {
  ReaderTranslationCubit({
    required AiProviderRepository providerRepository,
    required AiProviderFactory providerFactory,
    required AiPreferencesRepository preferencesRepository,
    required TranslationCacheRepository cacheRepository,
    required MosaicBuilder mosaicBuilder,
    required FallbackImageHandler fallbackHandler,
    required super.logger,
  })  : _providerRepository = providerRepository,
        _providerFactory = providerFactory,
        _preferencesRepository = preferencesRepository,
        _cacheRepository = cacheRepository,
        _mosaicBuilder = mosaicBuilder,
        _fallbackHandler = fallbackHandler,
        super(initialState: const ReaderTranslationIdle());

  final AiProviderRepository _providerRepository;
  final AiProviderFactory _providerFactory;
  final AiPreferencesRepository _preferencesRepository;
  final TranslationCacheRepository _cacheRepository;
  final MosaicBuilder _mosaicBuilder;
  final FallbackImageHandler _fallbackHandler;

  PageTranslation? _currentResult;
  bool _overlayVisible = false;
  final List<BubbleBox> _manualBubbles = [];

  /// ONNX-detected bubbles from the last detection (blue reference in
  /// draw mode). Set by [detectBubblesOnly] and after each translate.
  List<BubbleBox> _detectedBoxes = [];

  // Current page context (set via capturePage) for detect-only runs.
  Uint8List? _pageBytes;
  int _pageWidth = 0;
  int _pageHeight = 0;
  final Set<String> _userEditedKeys = {};
  bool _skipSfx = true;
  bool _drawMode = false;

  // Image/page context of the current translation (for coordinate scaling).
  int _currentImageWidth = 0;
  int _currentImageHeight = 0;
  int _currentPageIndex = -1;
  String _currentContentId = '';
  String _currentImageUrl = '';

  ReaderTranslationTranslated _translatedState() => ReaderTranslationTranslated(
        result: _currentResult!,
        imageWidth: _currentImageWidth,
        imageHeight: _currentImageHeight,
        pageIndex: _currentPageIndex,
        contentId: _currentContentId,
        imageUrl: _currentImageUrl,
        uiVersion: _uiVersion,
      );

  bool get drawMode => _drawMode;

  /// Notified whenever [drawMode] flips (including force-exit via
  /// [onReadingModeChanged]). Lets the reader chrome auto-hide while drawing.
  VoidCallback? onDrawModeChanged;

  void setDrawMode(bool value) {
    _setDrawMode(value);
    _bumpUi();
  }

  void _setDrawMode(bool value) {
    if (_drawMode == value) return;
    _drawMode = value;
    onDrawModeChanged?.call();
  }

  /// Called by the reader when navigation mode changes — exits draw mode in
  /// continue scroll (AI translate/drawing is disabled there).
  void onReadingModeChanged(ReadingMode mode) {
    if (mode == ReadingMode.continuousScroll &&
        (_drawMode || _overlayVisible)) {
      _overlayVisible = false;
      _setDrawMode(false);
      _bumpUi();
    }
  }

  PageTranslation? get currentResult => _currentResult;
  bool get overlayVisible => _overlayVisible;
  List<BubbleBox> get manualBubbles => List.unmodifiable(_manualBubbles);
  List<BubbleBox> get detectedBoxes => List.unmodifiable(_detectedBoxes);
  bool get skipSfx => _skipSfx; // default on; toggle from toolbar

  /// Captured page dimensions — the coordinate space detected bubbles live
  /// in. Used by draw mode to map image px → screen px (fitWidth), even
  /// before any translate happened.
  int get pageWidth => _pageWidth;
  int get pageHeight => _pageHeight;
  bool get hasPage => _pageBytes != null && _pageWidth > 0 && _pageHeight > 0;

  /// Cache the active page image so draw-mode "Detect" can run without a
  /// full translate. Call from the reader on the current page.
  void capturePage({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) {
    _pageBytes = imageBytes;
    _pageWidth = imageWidth;
    _pageHeight = imageHeight;
  }

  /// ONNX-only detection for draw mode — renders blue reference bubbles
  /// without calling any AI provider.
  Future<List<BubbleBox>> detectBubblesOnly() async {
    final bytes = _pageBytes;
    if (bytes == null || _pageWidth <= 0 || _pageHeight <= 0) {
      logWarning('detectBubblesOnly: page belum di-capture (bytes=${bytes != null}, ${_pageWidth}x$_pageHeight)');
      return const [];
    }
    emit(const ReaderTranslationDetecting());
    final raw = await _detect(bytes, _pageWidth, _pageHeight);
    logInfo('detectBubblesOnly: raw ${raw.length} → post ${postProcessBoxes(raw).length}');
    final boxes = postProcessBoxes(raw);
    _detectedBoxes = boxes;
    if (state is ReaderTranslationDetecting) {
      _bumpUi();
    }
    logInfo('detectBubblesOnly: ${boxes.length} detections');
    return boxes;
  }

  Future<void> setSkipSfx(bool value) async {
    _skipSfx = value;
    await _preferencesRepository.setSkipSfx(value);
    _bumpUi();
  }

  /// Load persisted skipSfx (e.g. toolbar init).
  Future<void> initPreferences() async {
    _skipSfx = await _preferencesRepository.getSkipSfx();
    _bumpUi();
  }

  int _uiVersion = 0;

  /// Re-emits with a bumped uiVersion so Equatable-based builders rebuild
  /// (identical states are otherwise skipped by the bloc).
  void _bumpUi() {
    _uiVersion++;
    if (state is ReaderTranslationTranslated) {
      emit((state as ReaderTranslationTranslated).copyWithUi(uiVersion: _uiVersion));
    } else {
      emit(ReaderTranslationIdle(uiVersion: _uiVersion));
    }
  }

  /// User-edited translation override (spec 9.2): stored in cache with
  /// `isUserEdited: true`, AI never overwrites it.
  void editBubbleTranslation(int index, String newText) {
    final result = _currentResult;
    if (result == null || index < 0 || index >= result.bubbles.length) return;
    final bubbles = List<BubbleTranslation>.from(result.bubbles);
    final b = bubbles[index];
    bubbles[index] = b.copyWith(
      translated: newText,
      isUserEdited: true,
    );
    _userEditedKeys.add(_bubbleKey(index, b));
    _currentResult = result.copyWith(bubbles: bubbles);
    emit(_translatedState());
  }

  String _bubbleKey(int index, BubbleTranslation b) =>
      '${b.rect.left}_${b.rect.top}_$index';

  /// Returns the cache key: `SHA256('$contentId:$pageIndex:$urlHash')` (16 hex).
  static String buildCacheKey(
      String contentId, int pageIndex, String imageUrl) {
    final digest = sha256.convert(
        utf8.encode('$contentId:$pageIndex:${imageUrl.hashCode}'));
    return digest.toString().substring(0, 16);
  }

  bool get isBusy =>
      state is ReaderTranslationDetecting ||
      state is ReaderTranslationBuildingMosaic ||
      state is ReaderTranslationTranslating ||
      state is ReaderTranslationTranslatingBubble;

  void toggleOverlay() {
    _overlayVisible = !_overlayVisible;
    _bumpUi();
  }

  /// Reset per-page state when the reader navigates to a new page.
  void resetPage() {
    _currentResult = null;
    _overlayVisible = false;
    _manualBubbles.clear();
    _detectedBoxes.clear();
    _currentImageWidth = 0;
    _currentImageHeight = 0;
    _currentPageIndex = -1;
    _currentContentId = '';
    _currentImageUrl = '';
    // Emit Idle DIRECTLY (not via _bumpUi which re-emits the old Translated
    // state) so the overlay layer clears immediately.
    _uiVersion++;
    emit(ReaderTranslationIdle(uiVersion: _uiVersion));
  }

  void addManualBubble(Rect rect) {
    _manualBubbles.add(BubbleBox(
      x: rect.left.round(),
      y: rect.top.round(),
      w: rect.width.round(),
      h: rect.height.round(),
      confidence: 1.0,
    ));
  }

  void undoLastManual() {
    if (_manualBubbles.isNotEmpty) _manualBubbles.removeLast();
  }

  void clearManualBubbles() {
    _manualBubbles.clear();
  }

  /// Tap on a detected (ONNX) bubble in draw mode removes it — mirrors the
  /// example app (tap bubble → delete).
  void removeDetectedBubble(int index) {
    if (index < 0 || index >= _detectedBoxes.length) return;
    _detectedBoxes.removeAt(index);
  }

  /// Tap on a manual bubble removes it.
  void removeManualBubble(int index) {
    if (index < 0 || index >= _manualBubbles.length) return;
    _manualBubbles.removeAt(index);
  }

  /// NMS (IoU 0.45) + false-positive filter — same post-processing as the
  /// example app. ONNX raw output has duplicate/oversized boxes; without
  /// this the blue bubbles look wrong (double boxes, giant false positives).
  List<BubbleBox> postProcessBoxes(List<BubbleBox> boxes) {
    if (boxes.isEmpty) return [];
    final sorted = List<BubbleBox>.from(boxes)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final keep = <BubbleBox>[];
    while (sorted.isNotEmpty) {
      final best = sorted.removeAt(0);
      keep.add(best);
      sorted.removeWhere((b) => _iou(best, b) > 0.45);
    }
    return _removeFalsePositives(keep);
  }

  double _iou(BubbleBox a, BubbleBox b) {
    final x1 = a.x > b.x ? a.x.toDouble() : b.x.toDouble();
    final y1 = a.y > b.y ? a.y.toDouble() : b.y.toDouble();
    final x2 = (a.x + a.w) < (b.x + b.w) ? (a.x + a.w).toDouble() : (b.x + b.w).toDouble();
    final y2 = (a.y + a.h) < (b.y + b.h) ? (a.y + a.h).toDouble() : (b.y + b.h).toDouble();
    final inter = (x2 - x1) < 0 ? 0.0 : (x2 - x1) * ((y2 - y1) < 0 ? 0.0 : (y2 - y1));
    if (inter <= 0) return 0;
    final areaA = a.w * a.h;
    final areaB = b.w * b.h;
    return inter / (areaA + areaB - inter);
  }

  bool _contains(BubbleBox outer, BubbleBox inner) {
    return outer.x <= inner.x &&
        outer.y <= inner.y &&
        outer.x + outer.w >= inner.x + inner.w &&
        outer.y + outer.h >= inner.y + inner.h;
  }

  /// Removes giant boxes that engulf a >2.5× smaller box (cypy PR#2 rule).
  List<BubbleBox> _removeFalsePositives(List<BubbleBox> boxes) {
    final toRemove = <int>{};
    for (var i = 0; i < boxes.length; i++) {
      for (var j = 0; j < boxes.length; j++) {
        if (i == j) continue;
        final areaI = boxes[i].w * boxes[i].h;
        final areaJ = boxes[j].w * boxes[j].h;
        if (areaJ * 2.5 < areaI && _contains(boxes[i], boxes[j])) {
          toRemove.add(i);
        }
      }
    }
    return [
      for (var i = 0; i < boxes.length; i++)
        if (!toRemove.contains(i)) boxes[i],
    ];
  }

  Future<void> translatePage({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required String contentId,
    required int pageIndex,
    required String imageUrl,
    required ReadingMode readingMode,
  }) async {
    if (readingMode == ReadingMode.continuousScroll) {
      emit(const ReaderTranslationError(
          message: 'AI translate tidak tersedia di continue scroll.'));
      return;
    }
    if (isBusy) return;

    final targetLang = await _preferencesRepository.getTargetLanguage();
    final style = await _preferencesRepository.getTranslationStyle();

    // Cache hit → skip pipeline
    final cacheKey = buildCacheKey(contentId, pageIndex, imageUrl);
    final cached = await _cacheRepository.get(cacheKey);
    if (cached != null) {
      _currentImageWidth = imageWidth;
      _currentImageHeight = imageHeight;
      _currentPageIndex = pageIndex;
      _currentContentId = contentId;
      _currentImageUrl = imageUrl;
      _currentResult = cached;
      _overlayVisible = true;
      emit(_translatedState());
      logInfo('translatePage: cache hit, ${cached.bubbles.length} bubbles');
      return;
    }

    // Active provider (must be vision-capable for image translation).
    // Text-only free models (deepseek-v4-flash-free) can't read the page
    // image — prefer any vision-capable provider, else guide to Settings.
    final providers = await _providerRepository.getProviders();
    final active = providers.where((p) => p.isDefault).firstOrNull ??
        (providers.isEmpty ? null : providers.first);
    if (active == null) {
      emit(const ReaderTranslationNoProvider());
      return;
    }
    if (!active.isVisionCapable) {
      final visionProvider = providers
          .where((p) => p.isVisionCapable)
          .firstOrNull;
      if (visionProvider != null) {
        await _providerRepository.setDefault(visionProvider.id);
        logInfo('Active provider ${active.model} text-only — switched to ${visionProvider.model}');
      } else {
        emit(ReaderTranslationNoProvider(modelName: active.model));
        return;
      }
    }

    try {
      // 1. Webtoon strip → chunk via ImageSplitter (1280px)
      if (WebtoonDetector.isWebtoon(
          Size(imageWidth.toDouble(), imageHeight.toDouble()))) {
        final chunks = _splitWebtoon(imageBytes, imageWidth, imageHeight);
        final allBoxes = <BubbleBox>[];
        var offsetY = 0;
        for (final chunk in chunks) {
          emit(const ReaderTranslationDetecting());
          final boxes =
              await _detect(chunk.bytes, chunk.width, chunk.height);
          for (final b in boxes) {
            allBoxes.add(BubbleBox(
              x: b.x,
              y: b.y + offsetY,
              w: b.w,
              h: b.h,
              confidence: b.confidence,
            ));
          }
          offsetY += chunk.height;
        }
        final result = await _translateWithBubbles(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          boxes: allBoxes,
          targetLang: targetLang,
          style: style,
          providers: providers,
        );
        _finish(result, cacheKey, contentId, pageIndex, imageWidth,
          imageHeight, imageUrl);
        logInfo(
            'translatePage done: ${result.bubbles.length} bubbles, usedFallback=${result.usedFallback}');
        return;
      }

      // 2. Normal page: ONNX detect — only if no manual re-run. A prior
      //    draw-mode Detect (or user deletes) already set _detectedBoxes;
      //    re-detecting here would resurrect bubbles the user unchecked.
      if (_detectedBoxes.isEmpty) {
        emit(const ReaderTranslationDetecting());
        _detectedBoxes =
            postProcessBoxes(await _detect(imageBytes, imageWidth, imageHeight));
      }
      var boxes = [..._manualBubbles, ..._detectedBoxes];

      // 3. Mosaic (≥1 bubble) or full-image fallback (0 bubbles)
      final result = await _translateWithBubbles(
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        boxes: boxes,
        targetLang: targetLang,
        style: style,
        providers: providers,
      );
      _finish(result, cacheKey, contentId, pageIndex, imageWidth,
          imageHeight, imageUrl);
    } on AiTranslationException catch (e) {
      if (e.isRateLimited) {
        emit(ReaderTranslationRateLimited(cooldownSeconds: 60));
      } else {
        emit(ReaderTranslationError(message: e.message));
      }
    } catch (e) {
      logWarning('translatePage failed: $e');
      emit(ReaderTranslationError(message: e.toString()));
    }
  }

  Future<List<BubbleBox>> _detect(
      Uint8List bytes, int width, int height) async {
    try {
      final result = await KuronNative.instance.detectBubbles(
        imageBytes: bytes,
        imageWidth: width,
        imageHeight: height,
      );
      return result ?? [];
    } catch (e) {
      logWarning('ONNX detectBubbles failed: $e');
      return [];
    }
  }

  Future<PageTranslation> _translateWithBubbles({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required List<BubbleBox> boxes,
    required String targetLang,
    required TranslationStyle style,
    required List<AiProviderConfig> providers,
  }) async {
    var provider = providers.where((p) => p.isDefault).firstOrNull ??
        (providers.isEmpty ? null : providers.first);
    if (provider == null) {
      emit(const ReaderTranslationNoProvider());
      throw const AiTranslationException('No provider');
    }
    if (!provider.isVisionCapable) {
      final vision = providers.where((p) => p.isVisionCapable).firstOrNull;
      if (vision == null) {
        emit(ReaderTranslationNoProvider(modelName: provider.model));
        throw const AiTranslationException('No vision provider');
      }
      provider = vision;
    }
    var current = provider;

    // Multi-key / multi-provider round robin on 429
    final usedIds = <String>{};
    while (true) {
      final impl = _providerFactory.create(current);
      try {
        final PageTranslation result;
        if (boxes.isEmpty) {
          emit(const ReaderTranslationBuildingMosaic());
          final compressed = _fallbackHandler.compressPage(imageBytes);
          result = await impl.translatePage(
            image: compressed,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            bubbles: const [],
            targetLang: targetLang,
            style: style,
            skipSfx: skipSfx,
          );
        } else {
          emit(const ReaderTranslationBuildingMosaic());
          final mosaic = _mosaicBuilder.buildMosaic(
              imageBytes, boxes.map(_toLike).toList());
          emit(ReaderTranslationTranslating(total: boxes.length));
          result = await impl.translatePage(
            image: mosaic,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            bubbles: boxes.map(_toLike).toList(),
            targetLang: targetLang,
            style: style,
            skipSfx: skipSfx,
          );
        }
        // 9.1 per-bubble partial progress: report parsed bubbles as they land
        if (result.bubbles.isNotEmpty) {
          emit(ReaderTranslationTranslatingBubble(
            current: result.bubbles.length,
            total: boxes.isEmpty ? result.bubbles.length : boxes.length,
          ));
        }
        return result;
      } on AiTranslationException catch (e) {
        if (!e.isRateLimited) rethrow;
        usedIds.add(current.id);
        final next = _fallbackProvider(current, providers, usedIds);
        if (next == null) {
          emit(ReaderTranslationRateLimited(
            cooldownSeconds: 60,
            fallbackName: null,
          ));
          throw const AiTranslationException('All providers rate limited',
              isRateLimited: true);
        }
        emit(ReaderTranslationRateLimited(
          cooldownSeconds: 60,
          fallbackName: next.displayName,
        ));
        current = next;
      }
    }
  }

  void _finish(PageTranslation result, String cacheKey, String contentId,
      int pageIndex, int imageWidth, int imageHeight, String imageUrl) {
    _currentImageWidth = imageWidth;
    _currentImageHeight = imageHeight;
    _currentPageIndex = pageIndex;
    _currentContentId = contentId;
    _currentImageUrl = imageUrl;
    _currentResult = result;
    _overlayVisible = true;
    unawaited(_cacheRepository.put(
      cacheKey,
      result,
      contentId: contentId,
      pageIndex: pageIndex,
    ));
    emit(_translatedState());
  }

  AiProviderConfig? _fallbackProvider(
    AiProviderConfig current,
    List<AiProviderConfig> providers,
    Set<String> usedIds,
  ) {
    final sameType = providers
        .where((p) =>
            p.type == current.type &&
            p.id != current.id &&
            !usedIds.contains(p.id))
        .toList();
    if (sameType.isNotEmpty) return sameType.first;
    final others = providers
        .where((p) => p.type != current.type && !usedIds.contains(p.id))
        .toList();
    return others.isEmpty ? null : others.first;
  }

  BubbleBoxLike _toLike(BubbleBox b) => BubbleBoxLike(b.x, b.y, b.w, b.h);

  /// Webtoon: slice into ≤1280px chunks.
  List<_ImageChunk> _splitWebtoon(Uint8List bytes, int width, int height) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return [_ImageChunk(bytes, width, height)];
    }
    const maxHeight = 1280;
    final chunks = <_ImageChunk>[];
    for (var y = 0; y < height; y += maxHeight) {
      final h = (height - y).clamp(0, maxHeight);
      final crop = img.copyCrop(decoded, x: 0, y: y, width: width, height: h);
      chunks.add(_ImageChunk(img.encodeJpg(crop, quality: 90), width, h));
    }
    return chunks;
  }
}

class _ImageChunk {
  const _ImageChunk(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}
