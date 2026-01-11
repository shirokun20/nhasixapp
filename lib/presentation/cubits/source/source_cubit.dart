import 'package:kuron_core/kuron_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_cubit.dart';
import 'source_state.dart';

class SourceCubit extends BaseCubit<SourceState> {
  SourceCubit({
    required ContentSourceRegistry registry,
    required SharedPreferences prefs,
    required super.logger,
  })  : _registry = registry,
        _prefs = prefs,
        super(
          initialState: SourceState(
            availableSources: registry.allSources,
            activeSource: registry.currentSource,
          ),
        ) {
    _loadSavedSource();
  }

  final ContentSourceRegistry _registry;
  final SharedPreferences _prefs;
  static const String _keySelectedSource = 'selected_source_id';

  void _loadSavedSource() {
    final savedId = _prefs.getString(_keySelectedSource);
    if (savedId != null && _registry.hasSource(savedId)) {
      if (_registry.switchSource(savedId)) {
        emit(state.copyWith(activeSource: _registry.currentSource));
      }
    }
  }

  void switchSource(String sourceId) {
    if (_registry.switchSource(sourceId)) {
      _prefs.setString(_keySelectedSource, sourceId);
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
