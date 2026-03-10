import 'package:kuron_core/kuron_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhasixapp/services/license_service.dart';
import '../base/base_cubit.dart';
import 'source_state.dart';

class SourceCubit extends BaseCubit<SourceState> {
  SourceCubit({
    required ContentSourceRegistry registry,
    required SharedPreferences prefs,
    required super.logger,
    required LicenseService licenseService,
  })  : _registry = registry,
        _prefs = prefs,
        _licenseService = licenseService,
        super(
          initialState: SourceState(
            availableSources:
                _filterSources(registry.allSources, licenseService),
            activeSource: _getDefaultSource(registry, licenseService),
          ),
        ) {
    _loadSavedSource();
  }

  final ContentSourceRegistry _registry;
  final SharedPreferences _prefs;
  final LicenseService _licenseService;
  static const String _keySelectedSource = 'selected_source_id';

  static List<ContentSource> _filterSources(
    List<ContentSource> sources,
    LicenseService licenseService,
  ) {
    var filteredSources =
        sources.where((source) => source.id != 'crotpedia').toList();

    final isPremium = licenseService.isPremiumActive;

    if (isPremium) {
      return filteredSources;
    }

    return filteredSources.where((source) => source.id != 'nhentai').toList();
  }

  static ContentSource _getDefaultSource(
    ContentSourceRegistry registry,
    LicenseService licenseService,
  ) {
    final isPremium = licenseService.isPremiumActive;

    final availableForPremium =
        registry.allSources.where((s) => s.id != 'crotpedia').toList();
    final availableForFree =
        availableForPremium.where((s) => s.id != 'nhentai').toList();

    final defaultSource = registry.currentSource;

    if (defaultSource == null) {
      return isPremium ? availableForPremium.first : availableForFree.first;
    }

    final availableSources = isPremium ? availableForPremium : availableForFree;

    if (!availableSources.any((s) => s.id == defaultSource.id)) {
      return availableSources.first;
    }

    return defaultSource;
  }

  void _loadSavedSource() {
    final savedId = _prefs.getString(_keySelectedSource);
    if (savedId != null && _registry.hasSource(savedId)) {
      final isHiddenForAll = savedId == 'crotpedia';
      final isPremiumOnly = savedId == 'nhentai';

      if (isHiddenForAll ||
          (isPremiumOnly && !_licenseService.isPremiumActive)) {
        switchSource(_getDefaultSource(_registry, _licenseService).id);
        return;
      }

      if (_registry.switchSource(savedId)) {
        emit(state.copyWith(activeSource: _registry.currentSource));
      }
    }
  }

  void switchSource(String sourceId) {
    final isHiddenForAll = sourceId == 'crotpedia';
    final isPremiumOnly = sourceId == 'nhentai';

    if (isHiddenForAll || (isPremiumOnly && !_licenseService.isPremiumActive)) {
      logWarning(
          'Blocked: User attempted to switch to $sourceId (not available)');
      return;
    }

    if (_registry.switchSource(sourceId)) {
      _prefs.setString(_keySelectedSource, sourceId);
      logInfo('Switched source to $sourceId');
      emit(state.copyWith(activeSource: _registry.currentSource));
    } else {
      logWarning('Failed to switch to source $sourceId (not found)');
    }
  }

  void refreshSources() {
    emit(state.copyWith(
      availableSources: _filterSources(_registry.allSources, _licenseService),
      activeSource: _getDefaultSource(_registry, _licenseService),
    ));
  }
}
