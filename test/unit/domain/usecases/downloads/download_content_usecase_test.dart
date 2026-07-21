import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/services/memory_budget_coordinator.dart';

final getIt = GetIt.instance;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (!getIt.isRegistered<Logger>()) {
      getIt.registerSingleton<Logger>(Logger(printer: SimplePrinter()));
    }
  });

  group('dynamic maxParallelImages', () {
    test('activeReader reduces parallel to budget value', () {
      final coordinator = MemoryBudgetCoordinator();
      coordinator.onReaderActiveChanged(true);

      final dynamicParallel = coordinator.isReaderActive
          ? coordinator.maxDownloadParallel
          : 3; // params.maxParallelImages fallback

      expect(coordinator.isReaderActive, true);
      expect(dynamicParallel, 1); // coordinator caps at 1 when active
      expect(dynamicParallel, lessThan(3)); // always lower than default
    });

    test('idle reader uses params.maxParallelImages', () {
      final coordinator = MemoryBudgetCoordinator();
      coordinator.onReaderActiveChanged(false);

      const paramsMax = 3;
      final dynamicParallel = coordinator.isReaderActive
          ? coordinator.maxDownloadParallel
          : paramsMax;

      expect(coordinator.isReaderActive, false);
      expect(dynamicParallel, paramsMax);
    });

    test('rapid toggle stays stable', () {
      final coordinator = MemoryBudgetCoordinator();
      // Toggle 10 times
      for (int i = 0; i < 10; i++) {
        coordinator.onReaderActiveChanged(true);
        coordinator.onReaderActiveChanged(false);
      }
      // Final state: idle
      const paramsMax = 3;
      final dynamicParallel = coordinator.isReaderActive
          ? coordinator.maxDownloadParallel
          : paramsMax;
      expect(dynamicParallel, paramsMax);
      expect(coordinator.isReaderActive, false);
    });

    test('params maxParallelImages preserved even when reader active', () {
      // Simulasi: user set custom maxParallel=5, reader aktif
      final coordinator = MemoryBudgetCoordinator();
      coordinator.onReaderActiveChanged(true);

      // Logic di usecase: if reader active, pake coordinator.maxDownloadParallel
      final customParams = 5;
      final dynamicParallel = coordinator.isReaderActive
          ? coordinator.maxDownloadParallel
          : customParams;

      // Reader active → override to 1 regardless of params
      expect(dynamicParallel, 1);
      expect(dynamicParallel, isNot(customParams));
    });
  });
}
