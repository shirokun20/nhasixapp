import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';
import 'package:nhasixapp/domain/usecases/tags/get_tag_detail_usecase.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

/// API-v2 oriented tag detail screen.
///
/// This screen focuses on actionable tag exploration:
/// - Shows core API fields (id, slug, type, count)
/// - Uses query token template from source config for search navigation
class TagDetailScreen extends StatefulWidget {
  final String tagType;
  final String slug;
  final String sourceId;

  const TagDetailScreen({
    super.key,
    required this.tagType,
    required this.slug,
    required this.sourceId,
  });

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  final Logger _logger = Logger();
  TagDetailEntity? _tagDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTagDetail();
  }

  Future<void> _loadTagDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCase = getIt<GetTagDetailUseCase>();
      final tagDetail = await useCase(GetTagDetailParams(
        tagType: widget.tagType,
        slug: widget.slug,
        sourceId: widget.sourceId,
      ));

      if (!mounted) {
        return;
      }

      setState(() {
        _tagDetail = tagDetail;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.e('Error loading tag detail', error: e, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffoldWithOffline(
      title: _tagDetail?.name ?? widget.slug,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(colorScheme, l10n)
              : _buildContent(colorScheme, l10n),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n?.errorOccurred ?? 'Error Occurred',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTagDetail,
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, AppLocalizations? l10n) {
    final tag = _tagDetail;
    if (tag == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      icon: Icons.label,
                      label: _formatTagType(tag.type),
                      colorScheme: colorScheme,
                    ),
                    _buildBadge(
                      icon: Icons.numbers,
                      label: AppLocalizations.of(context)!.nGalleries(tag.count),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildMetaCard(tag, colorScheme),
          if (tag.description != null &&
              tag.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              title: AppLocalizations.of(context)!.descriptionLabel,
              child: Text(
                tag.description!.trim(),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
          if (tag.aliases != null && tag.aliases!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              title: AppLocalizations.of(context)!.aliasesLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tag.aliases!
                    .where((alias) => alias.trim().isNotEmpty)
                    .map(
                      (alias) => Chip(
                        label: Text(alias),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _searchWithTag(tag),
            icon: const Icon(Icons.search),
            label: Text(AppLocalizations.of(context)!.searchContentWithTag),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: Text(AppLocalizations.of(context)!.backToFilters),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(TagDetailEntity tag, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildMetaRow(AppLocalizations.of(context)!.tagId, tag.id.toString(), colorScheme),
            const Divider(height: 18),
            _buildMetaRow(AppLocalizations.of(context)!.slug, tag.slug, colorScheme),
            if (tag.url != null && tag.url!.trim().isNotEmpty) ...[
              const Divider(height: 18),
              _buildMetaRow(AppLocalizations.of(context)!.path, tag.url!, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  String _formatTagType(String type) {
    if (type.isEmpty) {
      return AppLocalizations.of(context)!.tag;
    }
    return '${type[0].toUpperCase()}${type.substring(1)}';
  }

  void _searchWithTag(TagDetailEntity tag) {
    final rawConfig =
        getIt<RemoteConfigService>().getRawConfig(widget.sourceId);
    final searchConfig = rawConfig?['searchConfig'] as Map?;
    final tokenTemplates = searchConfig?['queryTokenTemplates'] as Map?;
    final includeTemplate =
        (tokenTemplates?['include'] as String?) ?? '{type}:"{name}"';

    final token = includeTemplate
        .replaceAll('{type}', tag.type)
        .replaceAll('{name}', tag.name);

    _logger.i('Search with tag token: $token');

    AppRouter.goToContentByTag(
      context,
      token,
      displayLabel: '${_formatTagType(tag.type)}: ${tag.name}',
    );
  }
}
