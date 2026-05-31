import 'package:equatable/equatable.dart';

import '../compat/feature_kind.dart';

/// Stable string identifier for an engine primitive that a config can
/// require.
///
/// Engine primitives are the building blocks that `kuron_generic` knows how
/// to interpret (image modes, pagination modes, header rules, query rules,
/// cover builders, tag namespace handling, etc.).
///
/// Keep IDs stable; new IDs may be added without renaming existing ones.
/// Grouped by concern with dotted notation: `<concern>.<primitive>`.
class EnginePrimitive {
  EnginePrimitive._();

  // Image modes (how to derive the final image URL).
  static const String imageModeDirectUrl = 'imageMode.directUrl';
  static const String imageModeTemplate = 'imageMode.template';
  static const String imageModeCdnRegex = 'imageMode.cdnRegex';
  static const String imageModeScriptRegex = 'imageMode.scriptRegex';
  static const String imageModeAjaxHtml = 'imageMode.ajaxHtml';
  static const String imageModeExtensionMap = 'imageMode.extensionMap';
  static const String imageModeProxy = 'imageMode.proxy';

  // Pagination modes.
  static const String paginationPage = 'pagination.page';
  static const String paginationOffset = 'pagination.offset';
  static const String paginationCursor = 'pagination.cursor';

  // Dynamic search form features.
  static const String dynamicFormBasic = 'dynamicForm.basic';
  static const String dynamicFormOperators = 'dynamicForm.operators';
  static const String dynamicFormQuoteWhitespace =
      'dynamicForm.quoteWhitespace';
  static const String searchCategoryRouting = 'search.categoryRouting';

  // Header / referer rules.
  static const String headersStatic = 'headers.static';
  static const String headersDynamic = 'headers.dynamic';
  static const String refererTemplate = 'referer.template';

  // Network policy.
  static const String networkRateLimit = 'network.rateLimit';
  static const String networkRequiresBypass = 'network.requiresBypass';

  // Auth modes.
  static const String authNone = 'auth.none';
  static const String authCookie = 'auth.cookie';
  static const String authToken = 'auth.token';
  static const String authNonce = 'auth.nonce';

  // Tag namespaces.
  static const String tagNamespacesFlat = 'tagNamespaces.flat';
  static const String tagNamespacesMulti = 'tagNamespaces.multi';
  static const String tagRelations = 'tagRelations';

  // Query rules (REST).
  static const String queryRulesEnforceMultiValue =
      'queryRules.enforceMultiValue';
  static const String queryRulesEnsureParams = 'queryRules.ensureParams';

  // Cover builder.
  static const String coverBuilderTemplate = 'coverBuilder.template';

  // Comments.
  static const String commentsEmbedded = 'comments.embedded';
  static const String commentsEndpoint = 'comments.endpoint';

  // ── Generator metadata (§11.1) ────────────────────────────────────────────

  /// All known primitive identifiers mapped to a short description.
  ///
  /// The config generator can iterate this map to:
  /// - Provide auto-complete suggestions for `requiredPrimitives` fields.
  /// - Validate that generated configs only reference known primitives.
  static const Map<String, String> all = <String, String>{
    imageModeDirectUrl: 'Image URLs are direct (no transform needed).',
    imageModeTemplate: 'Image URL built from a template string.',
    imageModeCdnRegex: 'Image URL resolved via CDN-path regex.',
    imageModeScriptRegex: 'Image URL extracted via embedded-script regex.',
    imageModeAjaxHtml: 'Image URL extracted via AJAX response HTML.',
    imageModeExtensionMap:
        'Image extension resolved per-page via a server map.',
    imageModeProxy: 'Image served through an app-side proxy.',
    paginationPage: 'Pagination uses a 1-based page number parameter.',
    paginationOffset: 'Pagination uses an offset/skip parameter.',
    paginationCursor: 'Pagination uses an opaque cursor/token.',
    dynamicFormBasic: 'Dynamic search form with basic text fields.',
    dynamicFormOperators: 'Dynamic search form with boolean operators.',
    dynamicFormQuoteWhitespace: 'Search form quotes multi-word terms.',
    searchCategoryRouting:
        'Search browse routing can switch URL pattern by category.',
    headersStatic: 'Source requires static request headers (Referer, etc.).',
    headersDynamic: 'Source requires dynamically computed headers.',
    refererTemplate: 'Referer header built from a template.',
    networkRateLimit: 'Source enforces a request rate limit.',
    networkRequiresBypass: 'Source requires Cloudflare or equivalent bypass.',
    authNone: 'Source requires no authentication.',
    authCookie: 'Source uses cookie-based authentication.',
    authToken: 'Source uses a token-based authentication.',
    authNonce: 'Source uses a nonce-based authentication.',
    tagNamespacesFlat: 'Tags use a single flat namespace.',
    tagNamespacesMulti: 'Tags are organised in multiple named namespaces.',
    tagRelations: 'Tags carry relational metadata (parody, character, etc.).',
    queryRulesEnforceMultiValue: 'Query params enforce multi-value arrays.',
    queryRulesEnsureParams: 'Query must always include specific parameters.',
    coverBuilderTemplate: 'Cover URL built from a template string.',
    commentsEmbedded: 'Comments embedded in the detail page HTML.',
    commentsEndpoint: 'Comments available via a dedicated API endpoint.',
  };
}

/// Stable string identifier for a `kuron_special` plugin capability.
///
/// Configs that declare a non-generic feature (e.g. tokenized e-hentai page
/// fetch, hitomi nozomi protocol, hentainexus XOR/RC4 decrypt, Cloudflare
/// WebView bypass) must list the required plugin capability so the
/// validator can match it against plugins registered by the host app.
class PluginCapability {
  PluginCapability._();

  static const String ehentaiPageTokenFetch = 'plugin.ehentai.pageTokenFetch';
  static const String ehentaiSession = 'plugin.ehentai.session';
  static const String hitomiNozomi = 'plugin.hitomi.nozomi';
  static const String hentainexusDecrypt = 'plugin.hentainexus.decrypt';
  static const String cloudflareWebview = 'plugin.cloudflare.webview';
  static const String wordpressNonce = 'plugin.wordpress.nonce';

  // ── Generator metadata (§11.3) ────────────────────────────────────────────

  /// All known plugin capability identifiers mapped to a short description.
  ///
  /// The config generator can use this map to:
  /// - Suggest known capabilities for `requiredPlugins` feature fields.
  /// - Warn when a generated config references an unknown capability.
  static const Map<String, String> all = <String, String>{
    ehentaiPageTokenFetch:
        'E-Hentai tokenized page fetch (per-page token refresh).',
    ehentaiSession: 'E-Hentai authenticated session management.',
    hitomiNozomi: 'Hitomi nozomi protocol for image URL resolution.',
    hentainexusDecrypt: 'HentaiNexus XOR/RC4 image path decryption.',
    cloudflareWebview: 'Cloudflare Turnstile bypass via embedded WebView.',
    wordpressNonce: 'WordPress REST API nonce extraction for comments.',
  };
}

/// Declared contract for a single feature inside a Source Config.
///
/// The validator uses the contract to decide whether a feature can be
/// considered compatible without inferring from raw config fields.
class FeatureContract extends Equatable {
  FeatureContract({
    required this.feature,
    required this.declared,
    this.required = false,
    Set<String>? requiredPrimitives,
    Set<String>? requiredPlugins,
    this.notes,
  })  : requiredPrimitives =
            Set<String>.unmodifiable(requiredPrimitives ?? const <String>{}),
        requiredPlugins =
            Set<String>.unmodifiable(requiredPlugins ?? const <String>{});

  /// Feature this contract describes.
  final FeatureKind feature;

  /// Whether the config explicitly declared this feature (true) or whether
  /// the contract was inferred (false).
  final bool declared;

  /// Whether this feature is required for the source to be considered
  /// compatible overall. Required failures cap [CompatibilityStatus] at
  /// `configError` / `needsEngineSupport` / etc. Optional failures only
  /// degrade to `partiallyCompatible`.
  final bool required;

  /// Engine primitives (see [EnginePrimitive]) that the runtime must
  /// support for this feature to work.
  final Set<String> requiredPrimitives;

  /// Plugin capabilities (see [PluginCapability]) that the host must
  /// register for this feature to work.
  final Set<String> requiredPlugins;

  /// Free-form notes preserved from the config (e.g. v1 `notes` field).
  final String? notes;

  FeatureContract copyWith({
    FeatureKind? feature,
    bool? declared,
    bool? required,
    Set<String>? requiredPrimitives,
    Set<String>? requiredPlugins,
    String? notes,
  }) {
    return FeatureContract(
      feature: feature ?? this.feature,
      declared: declared ?? this.declared,
      required: required ?? this.required,
      requiredPrimitives: requiredPrimitives ?? this.requiredPrimitives,
      requiredPlugins: requiredPlugins ?? this.requiredPlugins,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'feature': feature.name,
        'declared': declared,
        'required': required,
        if (requiredPrimitives.isNotEmpty)
          'requiredPrimitives': requiredPrimitives.toList(growable: false),
        if (requiredPlugins.isNotEmpty)
          'requiredPlugins': requiredPlugins.toList(growable: false),
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => <Object?>[
        feature,
        declared,
        required,
        requiredPrimitives,
        requiredPlugins,
        notes,
      ];
}

/// Top-level capability declaration for a Source Config.
///
/// Captures the schema version, minimum engine version, and the list of
/// per-feature contracts. The validator consumes a
/// [SourceCapabilityDeclaration] together with the parsed runtime config
/// to produce a [ValidationReport].
class SourceCapabilityDeclaration extends Equatable {
  SourceCapabilityDeclaration({
    required this.sourceId,
    required this.schemaVersion,
    required List<FeatureContract> contracts,
    this.minEngineVersion,
    Map<String, Object?>? vendorExtensions,
  })  : contracts = List<FeatureContract>.unmodifiable(contracts),
        vendorExtensions = Map<String, Object?>.unmodifiable(
            vendorExtensions ?? const <String, Object?>{});

  final String sourceId;
  final String schemaVersion;
  final String? minEngineVersion;
  final List<FeatureContract> contracts;

  /// Unknown config blocks preserved verbatim so the validator can report
  /// them (e.g. `decryption`, `hitomiProtocol`, `tsReaderRegex`).
  final Map<String, Object?> vendorExtensions;

  /// Returns the contract for [feature], or `null` if none was declared.
  FeatureContract? contractFor(FeatureKind feature) {
    for (final FeatureContract c in contracts) {
      if (c.feature == feature) return c;
    }
    return null;
  }

  /// Set of all engine primitives required by all contracts.
  Set<String> get allRequiredPrimitives => <String>{
        for (final FeatureContract c in contracts) ...c.requiredPrimitives,
      };

  /// Set of all plugin capabilities required by all contracts.
  Set<String> get allRequiredPlugins => <String>{
        for (final FeatureContract c in contracts) ...c.requiredPlugins,
      };

  /// Set of features marked as required across all contracts.
  Set<FeatureKind> get requiredFeatures => <FeatureKind>{
        for (final FeatureContract c in contracts)
          if (c.required) c.feature,
      };

  SourceCapabilityDeclaration copyWith({
    String? sourceId,
    String? schemaVersion,
    String? minEngineVersion,
    List<FeatureContract>? contracts,
    Map<String, Object?>? vendorExtensions,
  }) {
    return SourceCapabilityDeclaration(
      sourceId: sourceId ?? this.sourceId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      minEngineVersion: minEngineVersion ?? this.minEngineVersion,
      contracts: contracts ?? this.contracts,
      vendorExtensions: vendorExtensions ?? this.vendorExtensions,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'schemaVersion': schemaVersion,
        if (minEngineVersion != null) 'minEngineVersion': minEngineVersion,
        'contracts': contracts.map((FeatureContract c) => c.toJson()).toList(
              growable: false,
            ),
        if (vendorExtensions.isNotEmpty) 'vendorExtensions': vendorExtensions,
      };

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        schemaVersion,
        minEngineVersion,
        contracts,
        vendorExtensions,
      ];
}
