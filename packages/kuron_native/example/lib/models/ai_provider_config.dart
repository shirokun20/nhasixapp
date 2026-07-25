enum AiProviderType { zen, openCodeGo, gemini, openAi, openRouter, custom }

class AiProviderConfig {
  final String id;
  final String displayName;
  final AiProviderType type;
  final String? apiKey;
  final String? baseUrl;
  final String model;
  bool isDefault;
  bool isEnabled;

  AiProviderConfig({
    required this.id,
    required this.displayName,
    required this.type,
    this.apiKey,
    this.baseUrl,
    this.model = 'minimax-m3-free',
    this.isDefault = false,
    this.isEnabled = true,
  });

  static const Map<AiProviderType, String> defaultModels = {
    AiProviderType.zen: 'minimax-m3-free',
    AiProviderType.openCodeGo: 'minimax-m3-free',
    AiProviderType.gemini: 'gemini-2.5-flash',
    AiProviderType.openAi: 'gpt-4o-mini',
    AiProviderType.openRouter: 'google/gemma-4-27b-it:free',
    AiProviderType.custom: 'ocg/minimax-m3',
  };

  static String defaultBaseUrl(AiProviderType type) {
    switch (type) {
      case AiProviderType.zen:
        return 'https://api.opencode.ai/zen/v1/chat/completions';
      case AiProviderType.openCodeGo:
        return 'https://api.opencode.ai/zen/go/v1/chat/completions';
      case AiProviderType.gemini:
        return 'https://generativelanguage.googleapis.com';
      case AiProviderType.openAi:
        return 'https://api.openai.com/v1/chat/completions';
      case AiProviderType.openRouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
      case AiProviderType.custom:
        return 'http://192.168.0.6:20128/v1/chat/completions';
    }
  }

  bool get needsKey => type != AiProviderType.zen;

  bool get hasValidSetup {
    if (type == AiProviderType.zen) return true;
    if (type == AiProviderType.custom && apiKey == null) {
      return baseUrl != null && baseUrl!.isNotEmpty;
    }
    return apiKey != null && apiKey!.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'type': type.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'isDefault': isDefault,
        'isEnabled': isEnabled,
      };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      AiProviderConfig(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        type: AiProviderType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AiProviderType.zen,
        ),
        apiKey: json['apiKey'] as String?,
        baseUrl: json['baseUrl'] as String?,
        model: (json['model'] as String?) ?? 'minimax-m3-free',
        isDefault: json['isDefault'] as bool? ?? false,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  AiProviderConfig copyWith({
    String? displayName,
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? isDefault,
    bool? isEnabled,
  }) =>
      AiProviderConfig(
        id: id,
        displayName: displayName ?? this.displayName,
        type: type,
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        isDefault: isDefault ?? this.isDefault,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}
