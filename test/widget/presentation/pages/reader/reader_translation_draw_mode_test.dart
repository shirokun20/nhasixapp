import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/fallback_image_handler.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_translation_draw_mode.dart';

import '../../../../unit/presentation/fakes.dart';

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

  ReaderTranslationCubit buildCubit() => ReaderTranslationCubit(
        providerRepository: FakeAiProviderRepository()
          ..addOnly(FakeAiProviderRepository.testProvider),
        providerFactory: FakeAiProviderFactory(),
        preferencesRepository: FakeAiPreferencesRepository(),
        cacheRepository: FakeCacheRepository(),
        mosaicBuilder: FakeMosaicBuilder(),
        fallbackHandler: FallbackImageHandler(),
        heavyRunner: syncHeavyRunner,
        logger: Logger(level: Level.off),
      );

  /// Renders [ReaderTranslationDrawMode] as a full-screen Stack so
  /// CoordinateMapping reflects fitWidth (like the real reader).
  Future<void> pump(WidgetTester tester, ReaderTranslationCubit cubit,
      {double screenW = 400, double screenH = 800}) async {
    await tester.binding.setSurfaceSize(Size(screenW, screenH));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Stack(
              children: const [
                Positioned.fill(child: ReaderTranslationDrawMode()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('draw off: locked, no controls, no crash with no page',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pump(tester, cubit);

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.radar), findsNothing);
    // Locked layer must not absorb taps on the page beneath.
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('draw mode shows control pill; expand/collapse actions',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    cubit.capturePage(
      imageBytes: Uint8List(0),
      imageWidth: 400,
      imageHeight: 800,
    );
    cubit.setDrawMode(true);
    await pump(tester, cubit);

    // Collapsed pill.
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.radar), findsNothing);

    // Expand → all four actions appear.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radar), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Tap Undo/Clear with empty list — no crash.
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pump();

    // Done → DrawMode exits.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(cubit.drawMode, isFalse);
  });

  testWidgets('pan adds manual bubble; undo/clear mutate cubit list',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    cubit.capturePage(
      imageBytes: Uint8List(0),
      imageWidth: 400,
      imageHeight: 800,
    );
    cubit.setDrawMode(true);
    await pump(tester, cubit);

    // Drag a rectangle over the page (screen space 400x800, image 400x800 →
    // scale 1:1, no letterbox).
    await tester.dragFrom(const Offset(100, 200), const Offset(100, 100));
    await tester.pump();

    expect(cubit.manualBubbles, hasLength(1));
    // Touch slop (~18px) shaves the start corner; assert a sane rect rather
    // than the exact drag vector.
    expect(cubit.manualBubbles.first.w, inInclusiveRange(40, 100));
    expect(cubit.manualBubbles.first.h, inInclusiveRange(40, 100));

    cubit.undoLastManual();
    expect(cubit.manualBubbles, isEmpty);

    cubit.addManualBubble(const Rect.fromLTWH(0, 0, 10, 10));
    cubit.clearManualBubbles();
    expect(cubit.manualBubbles, isEmpty);
  });

  testWidgets('detectBubblesOnly renders reference rects from channel',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    cubit.capturePage(
      imageBytes: Uint8List(4),
      imageWidth: 400,
      imageHeight: 800,
    );
    await cubit.detectBubblesOnly();
    expect(cubit.detectedBoxes, hasLength(2));

    cubit.setDrawMode(true);
    await pump(tester, cubit);
    // Drag over detected bubble → tap-to-delete (10,10 50x30, scale 1:1).
    await tester.tapAt(const Offset(35, 25));
    await tester.pump();
    expect(cubit.detectedBoxes, hasLength(1));
  });
}
