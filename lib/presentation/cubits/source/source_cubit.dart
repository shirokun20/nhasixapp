import 'package:kuron_core/kuron_core.dart';
import '../base/base_cubit.dart';
import 'source_state.dart';

class SourceCubit extends BaseCubit<SourceState> {
  SourceCubit({
    required ContentSourceRegistry registry,
    required super.logger,
  })  : _registry = registry,
        super(
          initialState: SourceState(
            availableSources: registry.allSources,
            activeSource: registry.currentSource,
          ),
        );

  final ContentSourceRegistry _registry;

  void switchSource(String sourceId) {
    if (_registry.switchSource(sourceId)) {
      logInfo('Switched source to $sourceId');
      emit(state.copyWith(activeSource: _registry.currentSource));
    } else {
      logWarning('Failed to switch to source $sourceId (not found)');
    }
  }

  /// Explicitly refresh available sources
  void refreshSources() {
    emit(state.copyWith(
      availableSources: _registry.allSources,
      activeSource: _registry.currentSource,
    ));
  }
}
