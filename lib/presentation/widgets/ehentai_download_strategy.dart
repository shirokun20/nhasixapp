import '../../domain/entities/entities.dart';

enum EhentaiDownloadStrategyKind {
  wholeGallery,
  galleryRange,
  partOnly,
  partRange,
}

class EhentaiDownloadStrategy {
  const EhentaiDownloadStrategy({
    required this.kind,
    required this.title,
    required this.description,
  });

  final EhentaiDownloadStrategyKind kind;
  final String title;
  final String description;

  bool get isRange =>
      kind == EhentaiDownloadStrategyKind.galleryRange ||
      kind == EhentaiDownloadStrategyKind.partRange;
}

class EhentaiDownloadStrategyResolver {
  static const String _ehentaiSourceId = 'ehentai';
  static const String _ehentaiPartPrefix = '__ehpart__';
  static const String _ehentaiImageMode = 'ehentai_page_fetch';

  const EhentaiDownloadStrategyResolver._();

  static bool supports(
    Content content, {
    Map<String, dynamic>? rawConfig,
  }) {
    if (content.sourceId.trim().toLowerCase() != _ehentaiSourceId) {
      return false;
    }

    if (rawConfig == null || rawConfig.isEmpty) {
      return false;
    }

    final configSource = (rawConfig['source'] as String?)?.trim().toLowerCase();
    if (configSource != _ehentaiSourceId) {
      return false;
    }

    final features = (rawConfig['features'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    if (features['download'] != true || features['chapters'] != true) {
      return false;
    }

    final selectors = (((rawConfig['scraper'] as Map?)?['selectors']
        as Map?)?['detail'] as Map?)?['imageUrls'] as Map?;
    final imageMode = (selectors?['mode'] as String?)?.trim();
    return imageMode == _ehentaiImageMode;
  }

  static List<EhentaiDownloadStrategy> resolve(
    Content content, {
    Map<String, dynamic>? rawConfig,
  }) {
    if (!supports(content, rawConfig: rawConfig)) {
      return const <EhentaiDownloadStrategy>[];
    }

    if (_isPartId(content.id)) {
      return const <EhentaiDownloadStrategy>[
        EhentaiDownloadStrategy(
          kind: EhentaiDownloadStrategyKind.partOnly,
          title: 'Download this part',
          description: 'Downloads only the selected E-Hentai part.',
        ),
      ];
    }

    final strategies = <EhentaiDownloadStrategy>[
      const EhentaiDownloadStrategy(
        kind: EhentaiDownloadStrategyKind.wholeGallery,
        title: 'Download whole gallery',
        description: 'Queues every E-Hentai part in gallery order.',
      ),
    ];

    if (content.pageCount > 0) {
      strategies.add(
        const EhentaiDownloadStrategy(
          kind: EhentaiDownloadStrategyKind.galleryRange,
          title: 'Choose gallery range',
          description: 'Uses original gallery page numbers.',
        ),
      );
    }

    return strategies;
  }

  static bool _isPartId(String contentId) {
    return contentId.startsWith(_ehentaiPartPrefix);
  }
}
