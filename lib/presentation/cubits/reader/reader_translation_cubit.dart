import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
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

/// Executes a CPU-bound computation off the UI isolate (mosaic crop/encode,
/// full-page compress, webtoon chunking). Production default: [Isolate.run].
/// Tests inject a synchronous runner because fake-async `testWidgets` cannot
/// await real isolate replies (they are delivered via real ports, not the
/// fake event queue).
typedef HeavyRunner = Future<T> Function<T>(FutureOr<T> Function() computation);

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
    HeavyRunner? heavyRunner,
    required super.logger,
  })  : _providerRepository = providerRepository,
        _providerFactory = providerFactory,
        _preferencesRepository = preferencesRepository,
        _cacheRepository = cacheRepository,
        _mosaicBuilder = mosaicBuilder,
        _fallbackHandler = fallbackHandler,
        _heavyRunner = heavyRunner ?? Isolate.run,
        super(initialState: const ReaderTranslationIdle());

  final AiProviderRepository _providerRepository;
  final AiProviderFactory _providerFactory;
  final AiPreferencesRepository _preferencesRepository;
  final TranslationCacheRepository _cacheRepository;
  final MosaicBuilder _mosaicBuilder;
  final FallbackImageHandler _fallbackHandler;
  final HeavyRunner _heavyRunner;

  PageTranslation? _currentResult;
  bool _overlayVisible = false;
  final List<BubbleBox> _manualBubbles = [];
  final Map<int, String> _failedBubbles = {};

  /// ONNX-detected bubbles from the last detection (blue reference in
  /// draw mode). Set by [detectBubblesOnly] and after each translate.
  List<BubbleBox> _detectedBoxes = [];

  /// Same content as [_detectedBoxes] — kept as a separate field so future
  /// translate-specific post-processing (e.g. merging balloons, dropping SFX)
  /// can diverge from draw-mode without refactoring call-sites.
  List<BubbleBox> _translationDetectedBoxes = [];

  // Current page context (set via capturePage) for detect-only runs.
  Uint8List? _pageBytes;
  int _pageWidth = 0;
  int _pageHeight = 0;
  String _capturedPageSignature = '';
  final Set<String> _userEditedKeys = {};
  bool _skipSfx = true;
  bool _drawMode = false;
  bool _rtlReading = false; // manga: right-to-left
  TranslationStyle? _currentStyle;

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
        failedBubbles: Map.unmodifiable(_failedBubbles),
        uiVersion: _uiVersion,
      );

  bool get drawMode => _drawMode;

  /// Notified whenever [drawMode] flips. Lets the reader chrome auto-hide
  /// while drawing.
  VoidCallback? onDrawModeChanged;

  void setDrawMode(bool value) {
    _setDrawMode(value);
    _bumpUi();
  }

  void setReadingDirection(ReadingMode mode) {
    _rtlReading = mode == ReadingMode.singlePage;
  }

  void _setDrawMode(bool value) {
    if (_drawMode == value) return;
    _drawMode = value;
    onDrawModeChanged?.call();
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
    final newSignature =
        _buildCaptureSignature(imageBytes, imageWidth, imageHeight);
    final captureChanged = _capturedPageSignature != newSignature;

    _pageBytes = imageBytes;
    _pageWidth = imageWidth;
    _pageHeight = imageHeight;
    _capturedPageSignature = newSignature;

    // Continuous-scroll viewport crops reuse the same page index, so a new
    // capture must invalidate old box coordinates from previous captures.
    // Keeping stale boxes causes severe overlay drift on the new viewport.
    if (captureChanged) {
      _detectedBoxes.clear();
      _translationDetectedBoxes.clear();
      _manualBubbles.clear();
      logInfo(
          'capturePage: new capture ${imageWidth}x$imageHeight bytes=${imageBytes.length} -> clear stale boxes');
      if (_drawMode) {
        _bumpUi();
      }
    }
  }

  String _buildCaptureSignature(
      Uint8List bytes, int imageWidth, int imageHeight) {
    final headLen = bytes.length < 24 ? bytes.length : 24;
    final tailLen = bytes.length < 24 ? 0 : 24;
    final head = bytes.sublist(0, headLen);
    final tail =
        tailLen == 0 ? const <int>[] : bytes.sublist(bytes.length - tailLen);
    return '$imageWidth:$imageHeight:${bytes.length}:${head.join(',')}:${tail.join(',')}';
  }

  /// ONNX-only detection for draw mode — renders blue reference bubbles
  /// without calling any AI provider.
  Future<List<BubbleBox>> detectBubblesOnly() async {
    final bytes = _pageBytes;
    if (bytes == null || _pageWidth <= 0 || _pageHeight <= 0) {
      logWarning(
          'detectBubblesOnly: page belum di-capture (bytes=${bytes != null}, ${_pageWidth}x$_pageHeight)');
      return const [];
    }
    emit(const ReaderTranslationDetecting());
    final raw = await _detect(bytes, _pageWidth, _pageHeight);
    logInfo(
        'detectBubblesOnly: raw ${raw.length} → post ${postProcessBoxes(raw).length}');
    final boxes = postProcessBoxes(raw);
    _detectedBoxes = boxes;
    _translationDetectedBoxes = boxes;
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
      emit((state as ReaderTranslationTranslated)
          .copyWithUi(uiVersion: _uiVersion));
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

  /// Style → font family map (spec 6.3). Default: Komika/KosugiMaru.
  static const _styleFontMap = <TranslationStyle, String>{
    TranslationStyle.natural: 'Komika',
    TranslationStyle.genz: 'Komika',
    TranslationStyle.action: 'Komika',
    TranslationStyle.romantis: 'Komika',
    TranslationStyle.formal: 'Komika',
    TranslationStyle.kasar: 'Komika',
    TranslationStyle.literal: 'KosugiMaru',
  };

  /// Translation cache schema version. Bump to invalidate OLD cached results
  /// when the output shape changes (e.g. box-only → polygon: old entries lack
  /// `shape`, so re-translate to carry the polygon).
  static const int _cacheSchemaVersion = 2;

  /// Returns the cache key: `SHA256('$contentId:$pageIndex:$urlHash')` (16 hex).
  static String buildCacheKey(
      String contentId, int pageIndex, String imageUrl) {
    final digest = sha256.convert(utf8.encode(
        'v$_cacheSchemaVersion:$contentId:$pageIndex:${imageUrl.hashCode}'));
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
    _translationDetectedBoxes.clear();
    _failedBubbles.clear();
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

  /// Add a tail polygon to a manual bubble (spec 7.1).
  void addTailToBubble(int index, List<List<int>> tail) {
    if (index < 0 || index >= _manualBubbles.length) return;
    _manualBubbles[index] = _manualBubbles[index].copyWith(tail: tail);
    _bumpUi();
  }

  /// Remove the tail from a manual bubble (spec 7.3).
  void removeTail(int index) {
    if (index < 0 || index >= _manualBubbles.length) return;
    _manualBubbles[index] = _manualBubbles[index].copyWith(clearTail: true);
    _bumpUi();
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
  List<BubbleBox> postProcessBoxes(List<BubbleBox> boxes,
      {bool dropTextInBalloon = true}) {
    if (boxes.isEmpty) return [];
    final sorted = List<BubbleBox>.from(boxes)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    if (dropTextInBalloon) {
      // Balloon (cls 2) menang: text (cls 1) yang terserap di dalam balloon
      // adalah teks asli yang mau ditimpa terjemahan → buang, jangan render
      // terpisah. Text standalone (thought bubble) tetap. Kalau tak ada
      // balloon, tak ada yang dibuang (query aman).
      final balloons = sorted.where((b) => b.kind == 'balloon').toList();
      sorted.removeWhere(
          (b) => b.kind == 'text' && balloons.any((bb) => _contains(bb, b)));
    }
    // Frame (panel border) bukan bubble — buang dari hasil deteksi.
    sorted.removeWhere((b) => b.kind == 'frame');
    final merged = _mergeNearbyBoxes(sorted);
    final keep = <BubbleBox>[];
    final afterMerge = List<BubbleBox>.from(merged);
    while (afterMerge.isNotEmpty) {
      final best = afterMerge.removeAt(0);
      keep.add(best);
      afterMerge.removeWhere((b) => _iou(best, b) > 0.45);
    }
    return _removeFalsePositives(keep);
  }

  /// Merge nearby text boxes that belong to one balloon (spec 5.1).
  /// Two boxes merge if: vertical overlap ≥ 0.5×minH AND gap ≤ 0.5×minH.
  /// Only merges same-kind boxes ('text' or 'balloon').
  List<BubbleBox> _mergeNearbyBoxes(List<BubbleBox> boxes) {
    if (boxes.length < 2) return boxes;
    final sorted = List<BubbleBox>.from(boxes)
      ..sort((a, b) => a.y.compareTo(b.y));
    final merged = <BubbleBox>[];
    var i = 0;
    while (i < sorted.length) {
      var current = sorted[i];
      var j = i + 1;
      while (j < sorted.length) {
        final next = sorted[j];
        if (current.kind != next.kind) break;
        final minH = current.h < next.h ? current.h : next.h;
        if (minH <= 0) break;
        final curBottom = current.y + current.h;
        final vertOverlap = curBottom > next.y ? (curBottom - next.y) / minH : 0.0;
        final gap = next.y - curBottom;
        if (vertOverlap >= 0.5 && math.max(gap, 0) <= minH * 0.5) {
          final nx = current.x < next.x ? current.x : next.x;
          final ny = current.y < next.y ? current.y : next.y;
          final nr = (current.x + current.w) > (next.x + next.w)
              ? (current.x + current.w)
              : (next.x + next.w);
          final nb = (current.y + current.h) > (next.y + next.h)
              ? (current.y + current.h)
              : (next.y + next.h);
          current = BubbleBox(
            x: nx,
            y: ny,
            w: nr - nx,
            h: nb - ny,
            confidence: current.confidence > next.confidence ? current.confidence : next.confidence,
            shape: null, // merged = no shape
            kind: current.kind,
          );
          j++;
        } else {
          break;
        }
      }
      merged.add(current);
      i = j;
    }
    return merged;
  }

  double _iou(BubbleBox a, BubbleBox b) {
    final x1 = a.x > b.x ? a.x.toDouble() : b.x.toDouble();
    final y1 = a.y > b.y ? a.y.toDouble() : b.y.toDouble();
    final x2 = (a.x + a.w) < (b.x + b.w)
        ? (a.x + a.w).toDouble()
        : (b.x + b.w).toDouble();
    final y2 = (a.y + a.h) < (b.y + b.h)
        ? (a.y + a.h).toDouble()
        : (b.y + b.h).toDouble();
    final inter =
        (x2 - x1) < 0 ? 0.0 : (x2 - x1) * ((y2 - y1) < 0 ? 0.0 : (y2 - y1));
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
    // Total image URLs in the chapter. Kept for diagnostics/logging only — the
    // continue-scroll gate no longer uses it (the widget sends a WYSIWYG
    // viewport snapshot, so there is always a well-defined active region).
    required int imageUrlCount,
    // Original-image y of the cropped viewport sent here. Every distinct crop
    // produces its own translated result, so it must be part of the cache key —
    // otherwise scrolling to a new position and translating again returns the
    // stale bubbles from the previous crop (misaligned with the new viewport).
    int cropYTop = 0,
  }) async {
    // Keep page context for flat-bubble detection even when called without
    // capturePage (tests, direct callers).
    _pageBytes = imageBytes;
    _pageWidth = imageWidth;
    _pageHeight = imageHeight;
    logInfo(
        'translatePage input: mode=$readingMode page=$pageIndex size=${imageWidth}x$imageHeight cropYTop=$cropYTop urls=$imageUrlCount');
    // Continue-scroll is always allowed now: the widget sends a WYSIWYG
    // snapshot of the ACTUAL visible viewport, so there is always a well-defined
    // active region to translate (unlike the old offset-math path, where a
    // multi-image chapter had no reliable "active page").
    if (isBusy) return;

    final targetLang = await _preferencesRepository.getTargetLanguage();
    final style = await _preferencesRepository.getTranslationStyle();
    _currentStyle = style;
    setReadingDirection(readingMode);

    // Cache hit → skip pipeline
    final cacheKey = buildCacheKey(contentId, pageIndex, '$imageUrl#$cropYTop');
    final cached = await _cacheRepository.get(cacheKey);
    if (cached != null) {
      _currentImageWidth = imageWidth;
      _currentImageHeight = imageHeight;
      _currentPageIndex = pageIndex;
      _currentContentId = contentId;
      _currentImageUrl = imageUrl;
      // Re-attach shapes if cache was saved before shape detection existed
      // and _detectedBoxes is already populated (draw mode ran first).
      _currentResult = _attachShapes(cached);
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
      final visionProvider =
          providers.where((p) => p.isVisionCapable).firstOrNull;
      if (visionProvider != null) {
        await _providerRepository.setDefault(visionProvider.id);
        logInfo(
            'Active provider ${active.model} text-only — switched to ${visionProvider.model}');
      } else {
        emit(ReaderTranslationNoProvider(modelName: active.model));
        return;
      }
    }

    try {
      // 1. Webtoon strip → chunk via ImageSplitter (1280px). Decoding + crop
      // + encode per chunk is CPU-bound, so run it in a background isolate —
      // otherwise the Detecting spinner cannot render until chunking finishes.
      if (WebtoonDetector.isWebtoon(
          Size(imageWidth.toDouble(), imageHeight.toDouble()))) {
        final chunks = await _heavyRunner(
          () => _splitWebtoonIsolate(imageBytes, imageWidth, imageHeight),
        );
        final allBoxes = <BubbleBox>[];
        var offsetY = 0;
        for (final chunk in chunks) {
          emit(const ReaderTranslationDetecting());
          final boxes = await _detect(chunk.bytes, chunk.width, chunk.height);
          for (final b in boxes) {
            allBoxes.add(BubbleBox(
              x: b.x,
              y: b.y + offsetY,
              w: b.w,
              h: b.h,
              confidence: b.confidence,
              shape: b.shape,
              kind: b.kind,
            ));
          }
          offsetY += chunk.height;
        }
        _detectedBoxes = postProcessBoxes(allBoxes);
        _translationDetectedBoxes = _detectedBoxes;
        logInfo(
            'translatePage webtoon: rawBoxes=${allBoxes.length} → postProcess=${_detectedBoxes.length}');
        // Use POST-PROCESSED boxes (same as draw mode), NOT the raw detections:
        // raw output carries duplicate/oversized boxes that became duplicate
        // mosaic chips — the model then merged the duplicate-text chips into
        // one bubble ("translation digabung").
        final boxes = _translationBoxes();
        final result = await _translateWithBubbles(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          boxes: boxes,
          targetLang: targetLang,
          style: style,
          providers: providers,
        );
        _finish(result, cacheKey, contentId, pageIndex, imageWidth, imageHeight,
            imageUrl);
        logInfo(
            'translatePage done: ${result.bubbles.length} bubbles, usedFallback=${result.usedFallback}');
        return;
      }

      // 2. Normal page: ONNX detect — only if no manual re-run. A prior
      //    draw-mode Detect (or user deletes) already set _detectedBoxes;
      //    re-detecting here would resurrect bubbles the user unchecked.
      if (_detectedBoxes.isEmpty) {
        emit(const ReaderTranslationDetecting());
        final rawBoxes = await _detect(imageBytes, imageWidth, imageHeight);
        _detectedBoxes = postProcessBoxes(rawBoxes);
        _translationDetectedBoxes = _detectedBoxes;
        logInfo(
            'translatePage: detect ${rawBoxes.length} → ${_detectedBoxes.length} boxes');
        for (final b in _detectedBoxes) {
          logInfo(
              '  box kind=${b.kind} conf=${b.confidence.toStringAsFixed(2)} ${b.x},${b.y},${b.w}x${b.h} shape=${b.shape?.length}');
        }
      }
      // Manual bubbles are the user's authoritative correction: drop any
      // detected box a manual bubble covers, so the same text is NOT sent to
      // the AI twice. Previously the duplicate chip confused the model into
      // merging/swapping the per-bubble translations.
      final boxes = _translationBoxes();
      logInfo(
          'translatePage: mosaic input=${boxes.length} box (manual=${_manualBubbles.length}, detected=${_detectedBoxes.length})');

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
      // Diagnostic: AI merging/skipping chips (or fallback full-image when
      // boxes is empty) is the usual cause of "translations look merged".
      if (boxes.isNotEmpty && result.bubbles.length != boxes.length) {
        logWarning(
            'translatePage: AI mengembalikan ${result.bubbles.length}/${boxes.length} bubble — ada chip di-SKIP atau digabung oleh model');
      }
      _finish(result, cacheKey, contentId, pageIndex, imageWidth, imageHeight,
          imageUrl);
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
          logWarning(
              'translatePage: FALLBACK full-image (0 bubble) — posisi ditentukan model, bukan bubble detector');
          emit(const ReaderTranslationBuildingMosaic());
          final fallback = _fallbackHandler;
          final pageBytes = imageBytes;
          // Full-page compress (decode + resize + JPEG85) is CPU-bound — run
          // on a background isolate so the loading frame renders immediately.
          final compressed =
              await _heavyRunner(() => fallback.compressPage(pageBytes));
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
          // Mosaic build (decode page, crop each bubble, 2× scale, composite,
          // JPEG85 + downscale loop) is CPU-bound — run on a background
          // isolate so the spinner appears right away instead of after the
          // bubble cuts finish. Only sendable locals are captured.
          final mosaicBuilder = _mosaicBuilder;
          final pageBytes = imageBytes;
          final likeBoxes = boxes.map(_toLike).toList();
          final mosaic = await _heavyRunner(
              () => mosaicBuilder.buildMosaic(pageBytes, likeBoxes));
          emit(ReaderTranslationTranslating(total: boxes.length));
          result = await impl.translatePage(
            image: mosaic,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            bubbles: likeBoxes,
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

  /// Flags flat/wide text boxes (cypy "bubble flat"): ratio ≥ 2.4, at least
  /// 45% of image width, at most 22% of image height — text sitting directly
  /// on busy artwork. Such bubbles render a white patch behind the text.
  PageTranslation _flagFlatBubbles(PageTranslation result) {
    final imageBytes = _pageBytes;
    if (imageBytes == null || imageBytes.isEmpty) return result;
    img.Image? page;
    try {
      page = img.decodeImage(imageBytes);
    } catch (_) {
      return result;
    }
    if (page == null) return result;
    final w = page.width.toDouble();
    final h = page.height.toDouble();
    return result.copyWith(bubbles: [
      for (final b in result.bubbles)
        b.copyWith(
          needsWhitePatch: b.rect.width / b.rect.height >= 2.4 &&
              b.rect.width >= w * 0.45 &&
              b.rect.height <= h * 0.22,
        ),
    ]);
  }

  void _finish(PageTranslation result, String cacheKey, String contentId,
      int pageIndex, int imageWidth, int imageHeight, String imageUrl) {
    result = _attachShapes(result);
    result = _flagFlatBubbles(result);
    // Track per-bubble failures (empty translation = AI skipped)
    _failedBubbles.clear();
    final fontFamily = _currentStyle != null
        ? _styleFontMap[_currentStyle]
        : null;
    if (fontFamily != null) {
      result = result.copyWith(
        bubbles: result.bubbles
            .map((b) => b.fontFamily == null ? b.copyWith(fontFamily: fontFamily) : b)
            .toList(),
      );
    }
    for (var i = 0; i < result.bubbles.length; i++) {
      if (result.bubbles[i].translated.trim().isEmpty) {
        _failedBubbles[i] = 'AI skipped this bubble';
      }
    }
    _currentImageWidth = imageWidth;
    _currentImageHeight = imageHeight;
    _currentPageIndex = pageIndex;
    _currentContentId = contentId;
    _currentImageUrl = imageUrl;
    _currentResult = result;
    _overlayVisible = true;
    if (result.bubbles.isNotEmpty) {
      final first = result.bubbles.first.rect;
      logInfo(
          'translatePage output: firstBubble=(${first.left.toStringAsFixed(1)},${first.top.toStringAsFixed(1)}) ${first.width.toStringAsFixed(1)}x${first.height.toStringAsFixed(1)} image=${imageWidth}x$imageHeight');
    } else {
      logInfo(
          'translatePage output: no bubbles image=${imageWidth}x$imageHeight');
    }
    unawaited(_cacheRepository.put(
      cacheKey,
      result,
      contentId: contentId,
      pageIndex: pageIndex,
    ));
    emit(_translatedState());
  }

  /// Re-attach ONNX polygon `shape` to translated bubbles by matching the
  /// detection box (same rect). The AI/mosaic round-trip only carries boxes,
  /// so shape is re-joined here from [_detectedBoxes].
  PageTranslation _attachShapes(PageTranslation result) {
    if (_detectedBoxes.isEmpty) {
      logInfo('_attachShapes: _detectedBoxes kosong, shape kosong');
      return result;
    }
    final detected = _detectedBoxes;
    var attached = 0;
    final bubbles = <BubbleTranslation>[];
    for (final b in result.bubbles) {
      if (b.shape != null) {
        bubbles.add(b);
        continue;
      }
      // Manual bubble: user drew a RECT, text must fit that box. Never hand it
      // a detected polygon shape — otherwise the text fits the balloon's
      // inscribed shape instead of the box the user drew.
      if (_manualCovers(b.rect)) {
        bubbles.add(b);
        continue;
      }
      final s = _nearestShape(detected, b.rect);
      if (s != null) attached++;
      bubbles.add(b.copyWith(shape: s));
    }
    logInfo(
        '_attachShapes: ${result.bubbles.length} bubble, shape-attached=$attached, detected=${_detectedBoxes.length}');
    return result.copyWith(bubbles: bubbles);
  }

  /// Best-matching detected bubble's shape for an AI-returned rect. The AI
  /// round-trip returns per-bubble boxes that may differ by a few px from the
  /// ONNX detection box (model or edit shift). Exact rect match would drop the
  /// polygon → bubble renders as a plain box. Match on closest center + IoU
  /// so shape survives small coord drift but a far frame never steals it.
  /// True when any manual bubble covers >60% of [rect]'s smaller area.
  bool _manualCovers(Rect rect) {
    if (_manualBubbles.isEmpty) return false;
    final rArea = rect.width * rect.height;
    if (rArea <= 0) return false;
    for (final m in _manualBubbles) {
      final mRect = Rect.fromLTWH(
          m.x.toDouble(), m.y.toDouble(), m.w.toDouble(), m.h.toDouble());
      final inter = rect.intersect(mRect);
      if (inter.isEmpty) continue;
      final smaller = rArea < m.w * m.h ? rArea : m.w * m.h;
      if (inter.width * inter.height / smaller >= 0.6) return true;
    }
    return false;
  }

  List<List<int>>? _nearestShape(List<BubbleBox> detected, Rect rect) {
    BubbleBox? best;
    var bestScore = double.negativeInfinity;
    for (final d in detected) {
      final shape = d.shape;
      if (shape == null || shape.length < 3) continue;
      final iou = _iou(
        d,
        BubbleBox(
          x: rect.left.round(),
          y: rect.top.round(),
          w: rect.width.round(),
          h: rect.height.round(),
        ),
      );
      // IoU dominates; center distance breaks ties. Normalized by img area.
      final dx = (d.cx - rect.center.dx).abs();
      final dy = (d.cy - rect.center.dy).abs();
      final score = iou - (dx + dy) * 1e-4;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best?.shape;
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

  /// Re-translate a single failed bubble (spec 3.2). Builds a 1-chip mosaic
  /// for that bubble, calls the AI provider, and merges the result back.
  Future<void> retryBubble(int index) async {
    final result = _currentResult;
    if (result == null || index < 0 || index >= result.bubbles.length) return;
    final bubble = result.bubbles[index];
    final providers = await _providerRepository.getProviders();
    var provider = providers.where((p) => p.isDefault).firstOrNull ??
        (providers.isEmpty ? null : providers.first);
    if (provider == null) return;
    if (!provider.isVisionCapable) {
      final vision = providers.where((p) => p.isVisionCapable).firstOrNull;
      if (vision == null) return;
      provider = vision;
    }
    final impl = _providerFactory.create(provider);
    final targetLang = await _preferencesRepository.getTargetLanguage();
    final style = await _preferencesRepository.getTranslationStyle();

    // Build single-bubble mosaic
    final singleBox = BubbleBoxLike(
      bubble.rect.left.round(),
      bubble.rect.top.round(),
      bubble.rect.width.round(),
      bubble.rect.height.round(),
    );
    final pageBytes = _pageBytes;
    if (pageBytes == null) return;
    final mosaic = await _heavyRunner(
        () => _mosaicBuilder.buildMosaic(pageBytes, [singleBox]));
    try {
      final retryResult = await impl.translatePage(
        image: mosaic,
        imageWidth: _currentImageWidth,
        imageHeight: _currentImageHeight,
        bubbles: [singleBox],
        targetLang: targetLang,
        style: style,
        skipSfx: skipSfx,
      );
      if (retryResult.bubbles.isNotEmpty) {
        final updated = List<BubbleTranslation>.from(_currentResult!.bubbles);
        updated[index] = retryResult.bubbles.first;
        _currentResult = _currentResult!.copyWith(bubbles: updated);
      }
    } catch (e) {
      logWarning('retryBubble[$index] failed: $e');
    }
    // Clear failed entry regardless of outcome
    final newFailed = Map<int, String>.from(
        _translatedState().failedBubbles);
    newFailed.remove(index);
    emit(ReaderTranslationTranslated(
      result: _currentResult!,
      imageWidth: _currentImageWidth,
      imageHeight: _currentImageHeight,
      pageIndex: _currentPageIndex,
      contentId: _currentContentId,
      imageUrl: _currentImageUrl,
      failedBubbles: newFailed,
    ));
  }

  BubbleBoxLike _toLike(BubbleBox b) => BubbleBoxLike(b.x, b.y, b.w, b.h);

  /// Mosaic input boxes: manual bubbles (user-corrected) first, then detected
  /// boxes NOT already covered by a manual bubble. Prevents the same text from
  /// being cropped into two mosaic chips (manual + detected duplicates of one
  /// region), which made the model merge/swap per-bubble translations.
  /// Mosaic input boxes: manual bubbles (user-corrected) first, then detected
  /// boxes NOT already covered by a manual bubble. Prevents the same text from
  /// being cropped into two mosaic chips (manual + detected duplicates of one
  /// region), which made the model merge/swap per-bubble translations.
  List<BubbleBox> _translationBoxes() {
    final manual = List<BubbleBox>.from(_manualBubbles);
    final detected = List<BubbleBox>.from(_translationDetectedBoxes);
    if (manual.isEmpty || detected.isEmpty) {
      return [...manual, ...detected];
    }
    final kept = <BubbleBox>[];
    for (final d in detected) {
      final dRect = Rect.fromLTWH(
          d.x.toDouble(), d.y.toDouble(), d.w.toDouble(), d.h.toDouble());
      final coveredByManual = manual.any((m) {
        final mRect = Rect.fromLTWH(
            m.x.toDouble(), m.y.toDouble(), m.w.toDouble(), m.h.toDouble());
        final inter = dRect.intersect(mRect);
        final interArea = inter.isEmpty ? 0.0 : inter.width * inter.height;
        final dArea = dRect.width * dRect.height;
        final mArea = mRect.width * mRect.height;
        if (dArea <= 0 || mArea <= 0) return false;
        final smaller = dArea < mArea ? dArea : mArea;
        return interArea / smaller >= 0.6;
      });
      if (!coveredByManual) kept.add(d);
    }
    // Sort in reading order: RTL manga = right-to-left, LTR manhwa/webtoon = left-to-right
    // Both top-to-bottom, X direction flips.
    kept.sort((a, b) {
      final ay = a.y.compareTo(b.y);
      if (ay != 0) return ay;
      return _rtlReading
          ? b.x.compareTo(a.x) // RTL: rightmost first
          : a.x.compareTo(b.x); // LTR: leftmost first
    });
    return [...manual, ...kept];
  }
}

class _ImageChunk {
  const _ImageChunk(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Webtoon: slice into ≤1280px chunks. Runs inside a background isolate from
/// [ReaderTranslationCubit.translatePage] — decode + per-chunk crop/encode is
/// CPU-bound and would otherwise jank the UI and delay the loading state.
List<_ImageChunk> _splitWebtoonIsolate(Uint8List bytes, int width, int height) {
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
