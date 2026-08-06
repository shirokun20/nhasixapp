import '../../../domain/entities/ai_translation.dart';
import '../../../domain/repositories/ai_translation_repositories.dart';
import '../../../data/repositories/ai/ai_provider_factory.dart';
import '../../../l10n/app_localizations.dart';
import '../base/base_cubit.dart';

part 'ai_settings_state.dart';

/// Manages AI translation providers, target language, and style.
class AiSettingsCubit extends BaseCubit<AiSettingsState> {
  AiSettingsCubit({
    required AiProviderRepository providerRepository,
    required AiPreferencesRepository preferencesRepository,
    required AiProviderFactory providerFactory,
    required TranslationCacheRepository cacheRepository,
    required super.logger,
    this.localizations,
  })  : _providerRepository = providerRepository,
        _preferencesRepository = preferencesRepository,
        _providerFactory = providerFactory,
        _cacheRepository = cacheRepository,
        super(initialState: const AiSettingsInitial()) {
    loadProviders();
  }

  final AiProviderRepository _providerRepository;
  final AiPreferencesRepository _preferencesRepository;
  final AiProviderFactory _providerFactory;
  final TranslationCacheRepository _cacheRepository;
  final AppLocalizations? localizations;

  static const List<String> supportedLanguages = [
    'Indonesian',
    'English',
    'Japanese',
    'Korean',
    'Chinese',
  ];

  Future<void> loadProviders() async {
    try {
      emitLoading();
      final providers = await _providerRepository.getProviders();
      final targetLang = await _preferencesRepository.getTargetLanguage();
      final style = await _preferencesRepository.getTranslationStyle();
      final skipSfx = await _preferencesRepository.getSkipSfx();
      emit(AiSettingsLoaded(
        providers: providers,
        targetLang: targetLang,
        style: style,
        skipSfx: skipSfx,
      ));
    } catch (e, st) {
      handleError(e, st, 'load AI settings');
      emit(AiSettingsError(message: 'Failed to load AI settings: $e'));
    }
  }

  Future<void> addProvider(AiProviderConfig provider) async {
    try {
      await _providerRepository.saveProvider(provider);
      await loadProviders();
    } catch (e, stackTrace) {
      logError(e, stackTrace, 'add provider');
      emit(AiSettingsError(message: 'Failed to add provider: $e'));
    }
  }

  Future<void> updateProvider(AiProviderConfig provider) async {
    await addProvider(provider);
  }

  Future<void> saveProvider(AiProviderConfig provider) async {
    await _providerRepository.saveProvider(provider);
    await loadProviders();
  }

  Future<void> deleteProvider(String id) async {
    try {
      await _providerRepository.deleteProvider(id);
      await loadProviders();
    } catch (e, stackTrace) {
      logError(e, stackTrace, 'delete provider');
      emit(AiSettingsError(message: 'Failed to delete provider: $e'));
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await _providerRepository.setDefault(id);
      await loadProviders();
    } catch (e, stackTrace) {
      logError(e, stackTrace, 'set default provider');
      emit(AiSettingsError(message: 'Failed to set default: $e'));
    }
  }

  Future<String?> validateProvider(AiProviderConfig provider) async {
    try {
      final factory = _providerFactory;
      final impl = factory.create(provider);
      await impl.validate();
      return null; // valid
    } on AiTranslationException catch (e) {
      return e.message;
    } catch (e) {
      return 'Validation failed: $e';
    }
  }

  /// Round-robin fallback: same-type keys first, then different providers.
  Future<AiProviderConfig?> getNextFallbackProvider(
    String currentId,
  ) async {
    final providers = await _providerRepository.getProviders();
    final current = providers.where((p) => p.id == currentId).firstOrNull;
    if (current == null) return null;

    final sameType = providers
        .where((p) => p.type == current.type && p.id != currentId)
        .toList();
    if (sameType.isNotEmpty) return sameType.first;

    final others = providers
        .where((p) => p.type != current.type && p.id != currentId)
        .toList();
    if (others.isNotEmpty) return others.first;
    return null;
  }

  Future<void> setTargetLanguage(String language) async {
    await _preferencesRepository.setTargetLanguage(language);
    final s = state;
    if (s is AiSettingsLoaded) {
      emit(s.copyWith(targetLang: language));
    }
  }

  Future<void> setTranslationStyle(TranslationStyle style) async {
    await _preferencesRepository.setTranslationStyle(style);
    final s = state;
    if (s is AiSettingsLoaded) {
      emit(s.copyWith(style: style));
    }
  }

  Future<void> clearCache() async {
    await _cacheRepository.clear();
  }

  Future<void> setSkipSfx(bool value) async {
    await _preferencesRepository.setSkipSfx(value);
    final s = state;
    if (s is AiSettingsLoaded) {
      emit(s.copyWith(skipSfx: value));
    }
  }

  Future<bool> isPrivacyAcknowledged() =>
      _preferencesRepository.isPrivacyAcknowledged();

  Future<void> acknowledgePrivacy() =>
      _preferencesRepository.setPrivacyAcknowledged();

  void emitLoading() {
    if (state is! AiSettingsLoaded) {
      emit(const AiSettingsLoading());
    }
  }

  void logError(Object e, StackTrace s, String op) => handleError(e, s, op);
}