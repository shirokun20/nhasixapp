import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';
import 'package:nhasixapp/domain/usecases/tags/get_tag_detail_usecase.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

/// Screen to display detailed information about a specific tag
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
      final result = await useCase(GetTagDetailParams(
        tagType: widget.tagType,
        slug: widget.slug,
        sourceId: widget.sourceId,
      ));

      if (result is DataSuccess && mounted) {
        setState(() {
          _tagDetail = result.data;
          _isLoading = false;
        });
      } else if (result is DataFailed && mounted) {
        setState(() {
          _errorMessage = result.exception?.message ?? 'Failed to load tag details';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error loading tag detail', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
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
    if (_tagDetail == null) {
      return const SizedBox.shrink();
    }

    final tag = _tagDetail!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag name
                  Text(
                    tag.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tag metadata
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.label,
                        _formatTagType(tag.type),
                        colorScheme,
                      ),
                      _buildInfoChip(
                        Icons.numbers,
                        '${tag.count} galleries',
                        colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description (if available)
          if (tag.description != null && tag.description!.isNotEmpty) ...[
            _buildSectionTitle('Description', colorScheme),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tag.description!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Aliases (if available)
          if (tag.aliases != null && tag.aliases!.isNotEmpty) ...[
            _buildSectionTitle('Aliases', colorScheme),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tag.aliases!
                      .map((alias) => Chip(
                            label: Text(alias),
                            backgroundColor:
                                colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _searchWithTag(tag),
              icon: const Icon(Icons.search),
              label: const Text('Search with this tag'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme colorScheme) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 13,
      ),
    );
  }

  String _formatTagType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  void _searchWithTag(TagDetailEntity tag) {
    // TODO: Implement search with tag
    // This will navigate back to search screen with the tag filter applied
    _logger.i('Search with tag: ${tag.name} (type: ${tag.type})');
    
    // For now, just go back
    context.pop();
  }
}
