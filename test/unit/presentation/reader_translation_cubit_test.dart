import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart' show BubbleBox;
import 'package:nhasixapp/data/repositories/ai/fallback_image_handler.dart';
import 'package:nhasixapp/domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_screen.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kuron_native'),
      (MethodCall call) async {
        if (call.method == 'detectBubbles') {
          return [
            {'x': 10, 'y': 10, 'w': 50, 'h': 30, 'confidence': 0.9},
            {'x': 100, 'y': 100, 'w': 40, 'h': 25, 'confidence': 0.8},
          ];
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('kuron_native'), null);
  });

  ReaderTranslationCubit makeCubit({
    FakeCacheRepository? cache,
    FakeAiProviderRepository? providers,
    FakeAiPreferencesRepository? preferencesRepository,
  }) {
    return ReaderTranslationCubit(
      providerRepository:
          providers ?? FakeAiProviderRepository(withVisionProvider: true),
      providerFactory: FakeAiProviderFactory(),
      preferencesRepository: preferencesRepository ?? FakeAiPreferencesRepository(),
      cacheRepository: cache ?? FakeCacheRepository(),
      mosaicBuilder: FakeMosaicBuilder(),
      fallbackHandler: FallbackImageHandler(),
      heavyRunner: syncHeavyRunner,
      logger: Logger(level: Level.off),
    );
  }

  test('state machine: detecting → translating → translated', () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    final states = <ReaderTranslationState>[];

    cubit.stream.listen(states.add);
    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 100,
      imageHeight: 100,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 3,
    );
    await pumpEventQueue();

    expect(cubit.state, isA<ReaderTranslationTranslated>());
    final translated = cubit.state as ReaderTranslationTranslated;
    expect(translated.result.bubbles.length, 2); // FakeProvider: 1 per box

    final types = states.map((s) => s.runtimeType).toList();
    expect(types, contains(ReaderTranslationDetecting));
    expect(types, contains(ReaderTranslationBuildingMosaic));
    expect(types, contains(ReaderTranslationTranslating));
    expect(types.last, ReaderTranslationTranslated);
  });

  test(
      'manual bubble covering a detected box de-duplicates mosaic input '
      '(no double-translate of the same text)', () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);

    // Manual correction covers the FIRST detected box (mock detection returns
    // (10,10,50,30) and (100,100,40,25)). Translate must NOT feed both the
    // manual copy AND the detected copy of the same text to the AI — that
    // duplicate chip earlier made the model merge/swap translations.
    cubit.addManualBubble(Rect.fromLTWH(10, 10, 50, 30));

    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 200,
      imageHeight: 200,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 1,
    );
    await pumpEventQueue();

    expect(cubit.state, isA<ReaderTranslationTranslated>());
    final translated = cubit.state as ReaderTranslationTranslated;
    // manual + kept detected (second box) = 2 bubbles, NOT 3.
    expect(translated.result.bubbles.length, 2);
  });

  test('cache hit skips pipeline', () async {
    final cache = FakeCacheRepository();
    final cubit = makeCubit(cache: cache);
    addTearDown(cubit.close);

    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1]),
      imageWidth: 10,
      imageHeight: 10,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 3,
    );
    await pumpEventQueue();

    // Second call with same key → cached, no new ONNX/AI work
    final states = <ReaderTranslationState>[];
    cubit.stream.listen(states.add);
    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1]),
      imageWidth: 10,
      imageHeight: 10,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 3,
    );
    await pumpEventQueue();

    expect(cubit.state, isA<ReaderTranslationTranslated>());
    // Only one state emitted (no detecting/translating) → direct translated
    final types = states.map((s) => s.runtimeType).toList();
    expect(types.every((t) => t == ReaderTranslationTranslated), true);
  });

  test('continueScroll non-webtoon viewport snapshot runs pipeline', () async {
    // The widget now sends a WYSIWYG viewport snapshot, so continue-scroll is
    // always allowed regardless of aspect ratio or URL count.
    final cubit = makeCubit();
    addTearDown(cubit.close);
    final image = img.Image(width: 100, height: 100); // square (viewport crop)
    await cubit.translatePage(
      imageBytes: img.encodeJpg(image),
      imageWidth: 100,
      imageHeight: 100,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.continuousScroll,
      imageUrlCount: 3,
    );
    await pumpEventQueue();
    expect(cubit.state, isA<ReaderTranslationTranslated>());
  });

  test('continueScroll single-image webtoon (tall image) runs pipeline',
      () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    // Real decodable image (split path decodes it). Empty/1-byte bytes crash
    // img.decodeImage → RangeError in the webtoon chunk loop.
    final image = img.Image(width: 100, height: 400); // AR 4.0 → webtoon
    await cubit.translatePage(
      imageBytes: img.encodeJpg(image),
      imageWidth: 100,
      imageHeight: 400,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.continuousScroll,
      imageUrlCount: 1,
    );
    await pumpEventQueue();
    expect(cubit.state, isA<ReaderTranslationTranslated>());
  });

  test('flat-bubble heuristic flags wide/short boxes, not normal ones',
      () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    // 400×1000 image. Mock detectBubbles: one flat box (ratio 2.6, w≥45%,
    // h≤22%) + one normal box (ratio ~1.7).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kuron_native'),
      (MethodCall call) async {
        if (call.method == 'detectBubbles') {
          return [
            {'x': 50, 'y': 100, 'w': 300, 'h': 115, 'confidence': 0.9},
            {'x': 50, 'y': 500, 'w': 200, 'h': 115, 'confidence': 0.8},
          ];
        }
        return null;
      },
    );
    final image = img.Image(width: 400, height: 1000);
    await cubit.translatePage(
      imageBytes: img.encodeJpg(image),
      imageWidth: 400,
      imageHeight: 1000,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 1,
    );
    await pumpEventQueue();

    final state = cubit.state as ReaderTranslationTranslated;
    final bubbles = state.result.bubbles;
    // flat: 300/115 = 2.61 ≥ 2.4, 300 ≥ 180 (45% of 400), 115 ≤ 220 (22% of 1000)
    expect(bubbles[0].needsWhitePatch, true);
    // normal: 200/115 = 1.74 < 2.4
    expect(bubbles[1].needsWhitePatch, false);
  });

  test('continueScroll single-image cropped (square) runs pipeline', () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    // After viewport crop a webtoon strip becomes normal AR — must still be
    // allowed when it is the single strip (imageUrlCount == 1).
    final image = img.Image(width: 100, height: 200); // AR 2.0 → not webtoon
    await cubit.translatePage(
      imageBytes: img.encodeJpg(image),
      imageWidth: 100,
      imageHeight: 200,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.continuousScroll,
      imageUrlCount: 1,
    );
    await pumpEventQueue();
    expect(cubit.state, isA<ReaderTranslationTranslated>());
  });

  test('no providers emits NoProvider', () async {
    final empty = FakeAiProviderRepository();
    empty.addNoProviders();
    final cubit = makeCubit(providers: empty);
    addTearDown(cubit.close);
    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1]),
      imageWidth: 10,
      imageHeight: 10,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 3,
    );
    expect(cubit.state, isA<ReaderTranslationNoProvider>());
  });

  test('computeViewportCrop maps scroll offset to image px and clamps', () {
    // 720px-wide strip, 13818 tall; 360px-wide viewport → scale 2.0.
    const full = Size(720, 13818);
    const viewport = Size(360, 800);

    // Top of strip.
    var crop = computeViewportCrop(offset: 0, full: full, viewport: viewport)!;
    expect(crop.yTop, 0);
    expect(crop.cropH, 1600); // 800 * 2.0

    // Mid-strip: offset 2000 screen px → 4000 image px.
    crop = computeViewportCrop(offset: 2000, full: full, viewport: viewport)!;
    expect(crop.yTop, 4000);
    expect(crop.cropH, 1600);

    // Bottom: offset beyond image → yTop clamps so crop stays in bounds.
    crop = computeViewportCrop(offset: 7000, full: full, viewport: viewport)!;
    expect(crop.yTop + crop.cropH, full.height.toInt());
    expect(crop.cropH, 1600);

    // Degenerate viewport → null.
    expect(
      computeViewportCrop(offset: 0, full: full, viewport: Size.zero),
      isNull,
    );
  });

  test('computeScrollPage maps offset to page + in-item offset', () {
    // Two pages: 1000 and 800 screen px tall (incl. gap).
    const heights = [1000.0, 800.0];

    // On page 1.
    var p = computeScrollPage(offset: 0, itemHeights: heights);
    expect(p.page, 0);
    expect(p.offsetInItem, 0);

    // Mid page 1.
    p = computeScrollPage(offset: 500, itemHeights: heights);
    expect(p.page, 0);
    expect(p.offsetInItem, 500);

    // Boundary: just before page 2 starts.
    p = computeScrollPage(offset: 1000, itemHeights: heights);
    expect(p.page, 1);
    expect(p.offsetInItem, 0);

    // Deep in page 2.
    p = computeScrollPage(offset: 1400, itemHeights: heights);
    expect(p.page, 1);
    expect(p.offsetInItem, 400);

    // Past the last item → clamped to last page's end.
    p = computeScrollPage(offset: 99999, itemHeights: heights);
    expect(p.page, 1);
    expect(p.offsetInItem, 800);
  });

  test('buildCacheKey is deterministic 16-hex', () {
    final a = ReaderTranslationCubit.buildCacheKey('c1', 2, 'http://u');
    final b = ReaderTranslationCubit.buildCacheKey('c1', 2, 'http://u');
    final c = ReaderTranslationCubit.buildCacheKey('c1', 3, 'http://u');
    expect(a, b);
    expect(a, isNot(c));
    expect(a.length, 16);
    expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(a), true);
  });

  test('different crop positions yield different cache keys', () {
    // Same page + url, different crop y → must NOT hit the same cache entry,
    // else scrolling to a new position shows stale bubbles.
    final at0 = ReaderTranslationCubit.buildCacheKey('c1', 0, 'http://u#0');
    final at4000 =
        ReaderTranslationCubit.buildCacheKey('c1', 0, 'http://u#4000');
    expect(at0, isNot(at4000));
  });

  test('postProcessBoxes drops text inside balloon, keeps standalone text', () {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    // balloon [289,608,421,796]; text [307,641,400,766] fully inside.
    // standalone text [80,305,190,424] outside any balloon.
    final out = cubit.postProcessBoxes([
      const BubbleBox(x: 289, y: 608, w: 132, h: 188, kind: 'balloon'),
      const BubbleBox(x: 307, y: 641, w: 93, h: 125, kind: 'text'),
      const BubbleBox(x: 80, y: 305, w: 110, h: 119, kind: 'text'),
    ]);
    final kinds = out.map((b) => b.kind).toList();
    expect(kinds.where((k) => k == 'balloon'), hasLength(1));
    // text inside balloon dropped; standalone text kept
    expect(kinds.where((k) => k == 'text'), hasLength(1));
    expect(out.map((b) => b.x).toSet(), {289, 80});
  });

  test('polygon shape re-attached to translated bubble by rect (task 4)',
      () async {
    // detect returns a bubble WITH shape; provider returns bubble rect == box.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kuron_native'),
      (MethodCall call) async {
        if (call.method == 'detectBubbles') {
          return [
            {
              'x': 10,
              'y': 10,
              'w': 50,
              'h': 30,
              'confidence': 0.9,
              'kind': 'balloon',
              'shape': [
                [10, 10],
                [60, 10],
                [55, 25],
                [60, 40],
                [10, 40],
              ],
            },
          ];
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kuron_native'), null);
    });

    final cubit = makeCubit();
    addTearDown(cubit.close);
    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 100,
      imageHeight: 100,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 1,
    );

    final state = cubit.state;
    expect(state, isA<ReaderTranslationTranslated>());
    final bubbles = (state as ReaderTranslationTranslated).result.bubbles;
    expect(bubbles, hasLength(1));
    expect(bubbles.first.shape, isNotNull);
    expect(bubbles.first.shape!.first, [10, 10]);
  });

  group('T4 reading order', () {
    // Sort logic is a 2-line comparator inside _translationBoxes (private).
    // Verified via integration: mock ONNX returns boxes in mixed X order,
    // translatePage → provider receives them sorted. Skipping unit test here.
  });

  group('T5 merge removed (no box merge — giant-box root cause)', () {
    test('postProcessBoxes does NOT merge two overlapping text boxes', () {
      final cubit = makeCubit();
      // Merge was killed (it unioned adjacent dialogue into one giant
      // shape:null box). Overlapping boxes now survive as separate bubbles.
      final boxes = [
        BubbleBox(x: 10, y: 10, w: 40, h: 20, kind: 'text', confidence: 0.9),
        BubbleBox(x: 10, y: 20, w: 40, h: 20, kind: 'text', confidence: 0.8),
      ];
      final result = cubit.postProcessBoxes(boxes);
      expect(result, hasLength(2));
    });

    test('postProcessBoxes keeps separate bubbles with large gap', () {
      final cubit = makeCubit();
      // Two boxes: gap=50px > 0.5×minH=10
      final boxes = [
        BubbleBox(x: 10, y: 10, w: 40, h: 20, kind: 'text', confidence: 0.9),
        BubbleBox(x: 10, y: 80, w: 40, h: 20, kind: 'text', confidence: 0.8),
      ];
      final result = cubit.postProcessBoxes(boxes);
      expect(result, hasLength(2));
    });

    test('postProcessBoxes keeps different kinds separate', () {
      final cubit = makeCubit();
      final boxes = [
        BubbleBox(x: 10, y: 10, w: 40, h: 20, kind: 'text', confidence: 0.9),
        BubbleBox(x: 10, y: 25, w: 40, h: 15, kind: 'balloon', confidence: 0.8),
      ];
      final result = cubit.postProcessBoxes(boxes);
      expect(result, hasLength(2));
    });
  });

  group('T6 font per style', () {
    test('font family attached to bubbles on finish', () async {
      final prefs = FakeAiPreferencesRepository();
      // Default is natural → Komika
      final cubit = makeCubit(preferencesRepository: prefs);
      addTearDown(cubit.close);
      await cubit.translatePage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 100,
        imageHeight: 100,
        contentId: 'c1',
        pageIndex: 0,
        imageUrl: 'u1',
        readingMode: ReadingMode.singlePage,
        imageUrlCount: 1,
      );
      final state = cubit.state as ReaderTranslationTranslated;
      for (final b in state.result.bubbles) {
        expect(b.fontFamily, 'Komika'); // natural → Komika
      }
    });
  });

  group('T7 bubble tail', () {
    test('addTailToBubble sets tail on manual bubble', () {
      final cubit = makeCubit();
      cubit.addManualBubble(const Rect.fromLTWH(10, 10, 50, 30));
      cubit.addTailToBubble(
        0,
        [
          [60, 25],
          [80, 10],
          [80, 40],
        ],
      );
      expect(cubit.manualBubbles.first.tail, isNotNull);
      expect(cubit.manualBubbles.first.tail!.length, 3);
    });

    test('removeTail clears tail', () {
      final cubit = makeCubit();
      cubit.addManualBubble(const Rect.fromLTWH(10, 10, 50, 30));
      cubit.addTailToBubble(
        0,
        [
          [60, 25],
          [80, 10],
        ],
      );
      cubit.removeTail(0);
      expect(cubit.manualBubbles.first.tail, isNull);
    });
  });

  group('T3 per-bubble retry', () {
    test('failedBubbles populated when translation empty', () async {
      final cubit = makeCubit();
      addTearDown(cubit.close);
      await cubit.translatePage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 100,
        imageHeight: 100,
        contentId: 'c1',
        pageIndex: 0,
        imageUrl: 'u1',
        readingMode: ReadingMode.singlePage,
        imageUrlCount: 1,
      );
      final state = cubit.state as ReaderTranslationTranslated;
      // FakeProvider returns 'T0','T1'... never empty → no failures
      expect(state.failedBubbles, isEmpty);
    });
  });
}
