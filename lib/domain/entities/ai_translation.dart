import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Minimal bubble descriptor used by AI providers (domain-level, decoupled
/// from kuron_native's BubbleBox).
class BubbleBoxLike {
  const BubbleBoxLike(this.x, this.y, this.w, this.h);

  final int x;
  final int y;
  final int w;
  final int h;
}

/// Provider types supported for AI image translation.
enum AiProviderType {
  zen,
  openCodeGo,
  gemini,
  openAi,
  openRouter,
  metaAi,
  clinePass,
  cohere,
  custom;

  String get displayName {
    switch (this) {
      case AiProviderType.zen:
        return 'Zen (Free)';
      case AiProviderType.openCodeGo:
        return 'OpenCode Go';
      case AiProviderType.gemini:
        return 'Gemini';
      case AiProviderType.openAi:
        return 'OpenAI';
      case AiProviderType.openRouter:
        return 'OpenRouter';
      case AiProviderType.metaAi:
        return 'Meta AI';
      case AiProviderType.clinePass:
        return 'ClinePass';
      case AiProviderType.cohere:
        return 'Cohere';
      case AiProviderType.custom:
        return 'Custom';
    }
  }

  /// Default base URL per type (OpenAI-compatible chat completions).
  ///
  /// NOTE: OpenCode has TWO distinct endpoints. Free models
  /// (`deepseek-v4-flash-free`, `mimo-2.5-free`) live on `/zen/v1/...`;
  /// subscription models (`kimi-k2.6`) live on `/zen/go/v1/...`. Mixing
  /// them yields "Model ... is not supported".
  String? get defaultBaseUrl {
    switch (this) {
      case AiProviderType.zen:
        return 'https://opencode.ai/zen/v1/chat/completions';
      case AiProviderType.openCodeGo:
        return 'https://opencode.ai/zen/go/v1/chat/completions';
      case AiProviderType.gemini:
        return null; // Uses Google REST API, not OpenAI-compatible
      case AiProviderType.openAi:
        return 'https://api.openai.com/v1/chat/completions';
      case AiProviderType.openRouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
      case AiProviderType.metaAi:
        return 'https://api.meta.ai/v1/chat/completions';
      case AiProviderType.clinePass:
        return 'https://api.clinepass.com/v1/chat/completions';
      case AiProviderType.cohere:
        return 'https://api.cohere.com/v2/chat';
      case AiProviderType.custom:
        return null; // User must supply
    }
  }

  /// List-models endpoint per type (null = no listing, manual entry).
  ///
  /// Verified via curl 2026-09-03:
  /// - zen/go/openRouter: no key, `{object, data:[{id}]}`.
  /// - openAi: Bearer key required (401 without).
  /// - gemini: `?key=` required (403 without), native shape
  ///   `{models:[{name, supportedGenerationMethods}]}`.
  String? get modelsUrl {
    switch (this) {
      case AiProviderType.zen:
        return 'https://opencode.ai/zen/v1/models';
      case AiProviderType.openCodeGo:
        return 'https://opencode.ai/zen/go/v1/models';
      case AiProviderType.openAi:
        return 'https://api.openai.com/v1/models';
      case AiProviderType.openRouter:
        return 'https://openrouter.ai/api/v1/models';
      case AiProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/models';
      case AiProviderType.metaAi:
        return 'https://api.meta.ai/v1/models';
      case AiProviderType.clinePass:
        return 'https://api.clinepass.com/v1/models';
      case AiProviderType.cohere:
        return 'https://api.cohere.com/v1/models';
      case AiProviderType.custom:
        return null; // Excluded from fetching — manual entry only.
    }
  }

  /// Whether this type needs an API key before listing models.
  bool get needsKeyForListing {
    switch (this) {
      case AiProviderType.openAi:
      case AiProviderType.gemini:
      case AiProviderType.metaAi:
      case AiProviderType.clinePass:
      case AiProviderType.cohere:
        return true;
      case AiProviderType.zen:
      case AiProviderType.openCodeGo:
      case AiProviderType.openRouter:
      case AiProviderType.custom:
        return false;
    }
  }
}

/// One selectable model entry for the provider LOV.
///
/// [isVision] is null when the list API exposes no capability flag —
/// the UI shows no badge and the Test button decides.
class AiModelOption extends Equatable {
  const AiModelOption({
    required this.id,
    this.isVision,
    this.label,
  });

  /// Model ID as returned by the provider list API.
  final String id;

  /// Human label; defaults to [id] when null.
  final String? label;

  /// True = vision, false = text-only, null = unknown (API gave no flag).
  final bool? isVision;

  String get displayLabel => label ?? id;

  @override
  List<Object?> get props => [id, label, isVision];
}

/// AI provider configuration (BYOK).
class AiProviderConfig extends Equatable {
  const AiProviderConfig({
    required this.id,
    required this.displayName,
    required this.type,
    required this.model,
    this.apiKey,
    this.baseUrl,
    this.isDefault = false,
    this.modelIsVision,
  });

  final String id; // UUID
  final String displayName;
  final AiProviderType type;
  final String model;
  final String? apiKey; // Optional: some types list models without a key
  final String? baseUrl; // Custom only; auto-detected from type otherwise
  final bool isDefault;

  /// Vision flag captured from the live model LOV at selection time.
  /// Null = unknown (legacy stored config or manual entry) — the Test
  /// button decides instead of any name-based guessing.
  final bool? modelIsVision;

  /// Whether this provider can read page images for translation.
  ///
  /// Fully dynamic: stored LOV flag wins; empty model is never capable;
  /// unknown falls back to capable so new vision models keep working
  /// (Test validates before save).
  bool get isVisionCapable {
    if (model.isEmpty) return false;
    if (modelIsVision != null) return modelIsVision!;
    return true;
  }

  AiProviderConfig copyWith({
    String? id,
    String? displayName,
    AiProviderType? type,
    String? model,
    String? apiKey,
    String? baseUrl,
    bool? isDefault,
    bool? modelIsVision,
  }) {
    return AiProviderConfig(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      modelIsVision: modelIsVision ?? this.modelIsVision,
    );
  }

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    return AiProviderConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      type: AiProviderType.values.byName(json['type'] as String),
      model: json['model'] as String,
      apiKey: json['apiKey'] as String?,
      baseUrl: json['baseUrl'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      modelIsVision: json['modelIsVision'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'type': type.name,
      'model': model,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'isDefault': isDefault,
      if (modelIsVision != null) 'modelIsVision': modelIsVision,
    };
  }

  @override
  List<Object?> get props =>
      [id, displayName, type, model, apiKey, baseUrl, isDefault, modelIsVision];
}

/// Translation tone/style — injected into the AI prompt.
enum TranslationStyle {
  natural,
  genz,
  action,
  romantis,
  formal,
  kasar,
  literal;

  String get label {
    switch (this) {
      case TranslationStyle.natural:
        return 'Natural';
      case TranslationStyle.genz:
        return 'Gen Z';
      case TranslationStyle.action:
        return 'Action';
      case TranslationStyle.romantis:
        return 'Romantis';
      case TranslationStyle.formal:
        return 'Formal';
      case TranslationStyle.kasar:
        return 'Kasar';
      case TranslationStyle.literal:
        return 'Literal';
    }
  }

  /// Prompt-injected style instruction.
  String get instruction {
    switch (this) {
      case TranslationStyle.natural:
        return 'Use natural, fluent Indonesian. Match tone to context. Default style.';
      case TranslationStyle.genz:
        return 'Use informal Indonesian slang: gue/lo, sih/dong/nih/deh/doang. For comedy/light romance.';
      case TranslationStyle.action:
        return 'Short, punchy sentences. Exclamations: Hah!, Hragh!, Mati lo!. For battle series.';
      case TranslationStyle.romantis:
        return 'Soft, poetic. Aku/Kamu. Light metaphor. For romance/drama.';
      case TranslationStyle.formal:
        return 'Standard literary Indonesian for narrators, mystery, horror, wise characters.';
      case TranslationStyle.kasar:
        return 'Blunt. anjir/bangsat/kampret/goblok. (18+, requires confirmation)';
      case TranslationStyle.literal:
        return 'Word-for-word accurate. Keep honorifics. For learning / checking meaning.';
    }
  }
}

/// One translated speech bubble with its position on the page.
class BubbleTranslation extends Equatable {
  const BubbleTranslation({
    required this.rect,
    required this.original,
    required this.translated,
    this.reading = '',
    this.isUserEdited = false,
    this.isSfxSkipped = false,
    this.needsWhitePatch = false,
    this.shape,
    this.fontFamily,
  });

  final Rect rect; // Pixel coordinates in original page space
  final String original;
  final String translated;

  /// Latin reading of the original (romaji for JP, romanization for
  /// KR/ZH/other scripts) so users can pronounce the source text.
  final String reading;
  final bool isUserEdited; // User corrected — AI must not overwrite
  final bool isSfxSkipped;

  /// Flat/wide text box sitting directly on busy artwork — render a white
  /// patch behind the text (cypy "bubble flat" heuristic, computed post-AI).
  final bool needsWhitePatch;

  /// Bubble outline polygon in original image pixel coords ([[x,y],...]).
  /// Null = box-only fallback (rounded-rect render). Attached post-AI from
  /// the ONNX detection (shape doesn't survive the mosaic/AI round-trip).
  final List<List<int>>? shape;

  /// Font family for this bubble's translation text. Null → default font.
  final String? fontFamily;

  BubbleTranslation copyWith({
    Rect? rect,
    String? original,
    String? translated,
    String? reading,
    bool? isUserEdited,
    bool? isSfxSkipped,
    bool? needsWhitePatch,
    List<List<int>>? shape,
    String? fontFamily,
  }) {
    return BubbleTranslation(
      rect: rect ?? this.rect,
      original: original ?? this.original,
      translated: translated ?? this.translated,
      reading: reading ?? this.reading,
      isUserEdited: isUserEdited ?? this.isUserEdited,
      isSfxSkipped: isSfxSkipped ?? this.isSfxSkipped,
      needsWhitePatch: needsWhitePatch ?? this.needsWhitePatch,
      shape: shape ?? this.shape,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  factory BubbleTranslation.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return BubbleTranslation(
      rect: Rect.fromLTRB(
        (r['left'] as num).toDouble(),
        (r['top'] as num).toDouble(),
        (r['right'] as num).toDouble(),
        (r['bottom'] as num).toDouble(),
      ),
      original: json['original'] as String? ?? '',
      translated: json['translated'] as String,
      reading: json['reading'] as String? ?? '',
      isUserEdited: json['isUserEdited'] as bool? ?? false,
      isSfxSkipped: json['isSfxSkipped'] as bool? ?? false,
      needsWhitePatch: json['needsWhitePatch'] as bool? ?? false,
      shape: (json['shape'] as List<dynamic>?)
          ?.map((p) =>
              (p as List<dynamic>).map((e) => (e as num).toInt()).toList())
          .toList(),
      fontFamily: json['fontFamily'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      },
      'original': original,
      'translated': translated,
      'reading': reading,
      'isUserEdited': isUserEdited,
      'isSfxSkipped': isSfxSkipped,
      'needsWhitePatch': needsWhitePatch,
      if (shape != null) 'shape': shape,
      if (fontFamily != null) 'fontFamily': fontFamily,
    };
  }

  @override
  List<Object?> get props => [
        rect,
        original,
        translated,
        reading,
        isUserEdited,
        isSfxSkipped,
        needsWhitePatch,
        shape,
        fontFamily,
      ];
}

/// Full page translation result.
class PageTranslation extends Equatable {
  const PageTranslation({
    required this.bubbles,
    this.detectedLang = '',
    this.usedFallback = false,
  });

  final List<BubbleTranslation> bubbles;
  final String detectedLang;
  final bool usedFallback;

  PageTranslation copyWith({
    List<BubbleTranslation>? bubbles,
    String? detectedLang,
    bool? usedFallback,
  }) {
    return PageTranslation(
      bubbles: bubbles ?? this.bubbles,
      detectedLang: detectedLang ?? this.detectedLang,
      usedFallback: usedFallback ?? this.usedFallback,
    );
  }

  factory PageTranslation.fromJson(Map<String, dynamic> json) {
    return PageTranslation(
      bubbles: (json['bubbles'] as List<dynamic>? ?? [])
          .map((e) => BubbleTranslation.fromJson(e as Map<String, dynamic>))
          .toList(),
      detectedLang: json['detectedLang'] as String? ?? '',
      usedFallback: json['usedFallback'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bubbles': bubbles.map((b) => b.toJson()).toList(),
      'detectedLang': detectedLang,
      'usedFallback': usedFallback,
    };
  }

  @override
  List<Object?> get props => [bubbles, detectedLang, usedFallback];
}
