
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/fallback_image_handler.dart';
import 'package:nhasixapp/domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_translation_widgets.dart';

import '../unit/presentation/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock ONNX detection to return 3 bubbles.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kuron_native'),
      (MethodCall call) async {
        if (call.method == 'detectBubbles') {
          return [
            {'x': 10, 'y': 10, 'w': 50, 'h': 30, 'confidence': 0.9},
            {'x': 100, 'y': 100, 'w': 40, 'h': 25, 'confidence': 0.8},
            {'x': 200, 'y': 50, 'w': 45, 'h': 28, 'confidence': 0.7},
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

  testWidgets('overlay renders one Positioned per translated bubble',
      (tester) async {
    final cubit = ReaderTranslationCubit(
      providerRepository: FakeAiProviderRepository()
        ..addOnly(FakeAiProviderRepository.testProvider),
      providerFactory: FakeAiProviderFactory(),
      preferencesRepository: FakeAiPreferencesRepository(),
      cacheRepository: FakeCacheRepository(),
      mosaicBuilder: FakeMosaicBuilder(),
      fallbackHandler: FallbackImageHandler(),
      logger: Logger(level: Level.off),
    );
    addTearDown(cubit.close);

    await cubit.translatePage(
      imageBytes: Uint8List(0),
      imageWidth: 100,
      imageHeight: 100,
      contentId: 'c1',
      pageIndex: 0,
      imageUrl: 'u1',
      readingMode: ReadingMode.singlePage,
      imageUrlCount: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: ReaderTranslationOverlay(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(cubit.state, isA<ReaderTranslationTranslated>());
    expect(find.byType(Positioned), findsNWidgets(3));
  });
}

/// Mosaic builder that returns minimal bytes (test image decoding not needed
/// because ONNX is mocked and FakeProvider produces bubbles directly).
