part of 'ai_settings_cubit.dart';

abstract class AiSettingsState extends BaseCubitState {
  const AiSettingsState();
}

class AiSettingsInitial extends AiSettingsState {
  const AiSettingsInitial();

  @override
  List<Object?> get props => [];
}

class AiSettingsLoading extends AiSettingsState {
  const AiSettingsLoading();

  @override
  List<Object?> get props => [];
}

class AiSettingsLoaded extends AiSettingsState {
  const AiSettingsLoaded({
    required this.providers,
    required this.targetLang,
    required this.style,
    this.skipSfx = true,
    this.isSaving = false,
  });

  final List<AiProviderConfig> providers;
  final String targetLang;
  final TranslationStyle style;
  final bool skipSfx;
  final bool isSaving;

  AiProviderConfig? get activeProvider {
    for (final p in providers) {
      if (p.isDefault) return p;
    }
    return providers.isEmpty ? null : providers.first;
  }

  AiSettingsLoaded copyWith({
    List<AiProviderConfig>? providers,
    String? targetLang,
    TranslationStyle? style,
    bool? skipSfx,
    bool? isSaving,
  }) {
    return AiSettingsLoaded(
      providers: providers ?? this.providers,
      targetLang: targetLang ?? this.targetLang,
      style: style ?? this.style,
      skipSfx: skipSfx ?? this.skipSfx,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props =>
      [providers, targetLang, style, skipSfx, isSaving];
}

class AiSettingsError extends AiSettingsState {
  const AiSettingsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
