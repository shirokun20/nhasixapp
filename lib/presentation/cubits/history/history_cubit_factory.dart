import 'package:logger/logger.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../services/history_cleanup_service.dart';
import 'history_cubit.dart';

/// Factory class for creating HistoryCubit instances
class HistoryCubitFactory {
  /// Create a new HistoryCubit instance with dependencies from service locator
  static HistoryCubit create() {
    return HistoryCubit(
      getHistoryUseCase: getIt<GetHistoryUseCase>(),
      clearHistoryUseCase: getIt<ClearHistoryUseCase>(),
      removeHistoryItemUseCase: getIt<RemoveHistoryItemUseCase>(),
      getHistoryCountUseCase: getIt<GetHistoryCountUseCase>(),
      historyCleanupService: getIt<HistoryCleanupService>(),
      logger: getIt<Logger>(),
    );
  }
}

/// Extension to make it easier to create HistoryCubit in widgets
extension HistoryCubitExtension on HistoryCubit {
  /// Static factory method for convenience
  static HistoryCubit create() => HistoryCubitFactory.create();
}
