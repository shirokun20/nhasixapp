
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/fallback_image_handler.dart';
import 'package:nhasixapp/domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';

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
  }) {
    return ReaderTranslationCubit(
      providerRepository:
          providers ?? FakeAiProviderRepository(withVisionProvider: true),
      providerFactory: FakeAiProviderFactory(),
      preferencesRepository: FakeAiPreferencesRepository(),
      cacheRepository: cache ?? FakeCacheRepository(),
      mosaicBuilder: FakeMosaicBuilder(),
      fallbackHandler: FallbackImageHandler(),
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
    );
    await pumpEventQueue();

    expect(cubit.state, isA<ReaderTranslationTranslated>());
    // Only one state emitted (no detecting/translating) → direct translated
    final types = states.map((s) => s.runtimeType).toList();
    expect(types.every((t) => t == ReaderTranslationTranslated), true);
  });

  test('continueScroll guard emits error', () async {
    final cubit = makeCubit();
    addTearDown(cubit.close);
    await cubit.translatePage(
      imageBytes: Uint8List.fromList([1]),
      imageWidth: 10,
      imageHeight: 10,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.continuousScroll,
    );
    expect(cubit.state, isA<ReaderTranslationError>());
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
    );
    expect(cubit.state, isA<ReaderTranslationNoProvider>());
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
}
