import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:nhasixapp/core/routing/app_router.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/offline_content_manager.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pdf_conversion_service.dart';
import '../blocs/download/download_bloc.dart';
import '../cubits/offline_search/offline_search_cubit.dart';
import '../cubits/settings/settings_cubit.dart';
import 'content_card_widget.dart';
import 'error_widget.dart';
import 'offline_content_shimmer.dart';

/// Reusable widget that displays offline content with search and filtering
/// Used by OfflineContentScreen and OfflineMode in MainScreen
class OfflineContentBody extends StatefulWidget {
  const OfflineContentBody({super.key});

  @override
  State<OfflineContentBody> createState() => _OfflineContentBodyState();
}

class _OfflineContentBodyState extends State<OfflineContentBody> {
  late OfflineSearchCubit _offlineSearchCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Assuming OfflineSearchCubit is provided in the context or via GetIt
    // For safety, we use GetIt here as it's a singleton
    _offlineSearchCubit = getIt<OfflineSearchCubit>();

    // Ensure content is loaded if not already
    if (_offlineSearchCubit.state is OfflineSearchInitial) {
      _offlineSearchCubit.getAllOfflineContent();
    } else {
      // Check for stale data (e.g. downloaded while on another screen)
      // If the count differs from DownloadBloc, refresh it
      try {
        final downloadState = context.read<DownloadBloc>().state;
        if (downloadState is DownloadLoaded &&
            _offlineSearchCubit.state is OfflineSearchLoaded) {
          final offlineCount =
              (_offlineSearchCubit.state as OfflineSearchLoaded).results.length;
          final downloadCount = downloadState.completedDownloads.length;
          if (offlineCount != downloadCount) {
            _offlineSearchCubit.getAllOfflineContent();
          }
        }
      } catch (e) {
        debugPrint('Error syncing offline state with downloads: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: BlocListener<DownloadBloc, DownloadBlocState>(
            listenWhen: (previous, current) {
              // Only trigger if completed downloads count changes (success or delete)
              // This filters out frequent progress updates
              if (previous is DownloadLoaded && current is DownloadLoaded) {
                return previous.completedDownloads.length !=
                    current.completedDownloads.length;
              }
              return true;
            },
            listener: (context, downloadState) {
              // Auto-refresh when a download completes
              if (downloadState is DownloadLoaded) {
                if (_searchController.text.isEmpty) {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              }
            },
            child: BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
              bloc: _offlineSearchCubit,
              builder: (context, state) => _buildContent(state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)!.searchOfflineContentHint,
                    hintStyle: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _offlineSearchCubit.getAllOfflineContent();
                            },
                            icon: Icon(
                              Icons.clear,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (text) {
                    // Reactive UI handled by ValueListenableBuilder
                  },
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      _offlineSearchCubit.searchOfflineContent(query.trim());
                    } else {
                      _offlineSearchCubit.getAllOfflineContent();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _offlineSearchCubit.searchOfflineContent(query);
              } else {
                _offlineSearchCubit.getAllOfflineContent();
              }
              _searchFocusNode.unfocus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.search,
              style: TextStyleConst.buttonMedium.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OfflineSearchState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state is OfflineSearchLoading) {
      return const OfflineContentGridShimmer();
    }

    if (state is OfflineSearchError) {
      return Center(
        child: AppErrorWidget(
          title: AppLocalizations.of(context)!.offlineContentError,
          message: state.message,
          onRetry: () => _offlineSearchCubit.getAllOfflineContent(),
        ),
      );
    }

    if (state is OfflineSearchEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.query.isEmpty
                    ? 'No offline content'
                    : AppLocalizations.of(context)!.noResultsFoundFor(state.query),
                textAlign: TextAlign.center,
                style: TextStyleConst.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (state.query.isEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Explicit Import Action for Empty State
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Importing from backup...')),
                    );
                    await _offlineSearchCubit.importFromBackup();
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('Import from Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
              if (state.query.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noResultsFound,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              if (state.query.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to get started',
                            style: TextStyleConst.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipRow(colorScheme, '1. Browse comics you like'),
                      const SizedBox(height: 8),
                      _buildTipRow(colorScheme, '2. Tap the download button'),
                      const SizedBox(height: 8),
                      _buildTipRow(colorScheme,
                          '3. Access them here anytime, even offline!'),
                    ],
                  ),
                ),
              if (state.query.isEmpty) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/downloads'),
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Browse Downloads'), // Hardcoded to avoid key guessing
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (state is OfflineSearchLoaded) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  state.displayTitle,
                  style: TextStyleConst.headingSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  state.resultsSummary,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                // Wrap GridView with NotificationListener for infinite scroll
                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    // Trigger load more when user scrolls to 80% of content
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                      if (state.hasMore && !state.isLoadingMore) {
                        _offlineSearchCubit.loadMoreContent();
                      }
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        ResponsiveGridDelegate.createStandardGridDelegate(
                      context,
                      context.read<SettingsCubit>(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    // Add 1 for loading indicator if loading more
                    itemCount: state.results.length + 
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at bottom if loading more
                      if (index == state.results.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading more...',
                                  style: TextStyleConst.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final content = state.results[index];
                      return ContentCard(
                        content: content,
                        onTap: () => _openReader(context, content),
                        onLongPress: () => _showContentActions(context, content),
                        showOfflineIndicator: true,
                        isHighlighted: false,
                        offlineSize: state.offlineSizes[content.id],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return const OfflineContentGridShimmer();
  }

  Widget _buildTipRow(ColorScheme colorScheme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showContentActions(
      BuildContext context, Content content) async {
    final colorScheme = Theme.of(context).colorScheme;
    final offlineManager = getIt<OfflineContentManager>();
    final l10n = AppLocalizations.of(context)!;

    // Calculate content size for info
    final imagePaths = await offlineManager.getOfflineImageUrls(content.id);
    int totalBytes = 0;
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    final sizeText = OfflineContentManager.formatStorageSize(totalBytes);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // Capture parent context safely
        final parentContext = context;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: content.coverUrl.startsWith('http')
                          ? Image.network(
                              content.coverUrl,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 50,
                                height: 70,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Image.file(
                              File(content.coverUrl),
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 50,
                                height: 70,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: TextStyleConst.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${content.pageCount} pages • $sizeText',
                            style: TextStyleConst.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              FutureBuilder<bool>(
                future: _checkPdfExists(content.id),
                builder: (context, snapshot) {
                  final isPdf = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.remove_red_eye,
                        color:
                            isPdf ? colorScheme.tertiary : colorScheme.primary),
                    title: Text(
                        isPdf ? '${l10n.readNow} (PDF)' : l10n.readNow),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _openReader(parentContext, content);
                    },
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
                title: Text(l10n.convertToPdf),
                subtitle: Text('${content.pageCount} pages'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _generatePdf(parentContext, content);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmation(parentContext, content);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Generate PDF from offline content
  Future<void> _generatePdf(BuildContext context, Content content) async {
    final l10n = AppLocalizations.of(context)!;
    final offlineManager = getIt<OfflineContentManager>();
    final pdfService = getIt<PdfConversionService>();

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.convertingToPdf),
          duration: const Duration(seconds: 2),
        ),
      );

      final imagePaths = await offlineManager.getOfflineImageUrls(content.id);

      if (imagePaths.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfConversionFailedWithError(
              content.title,
              'No images found',
            )),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      await pdfService.convertToPdfInBackground(
        contentId: content.id,
        title: content.title,
        imagePaths: imagePaths,
        sourceId: content.sourceId,  // ← FIX: Use sourceId property
        maxPagesPerFile: 50,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pdfConversionFailedWithError(
            content.title,
            e.toString(),
          )),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      BuildContext context, Content content) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final prefs = await SharedPreferences.getInstance();
    final skipConfirmation = prefs.getBool('skip_delete_confirmation') ?? false;

    if (skipConfirmation) {
      if (!context.mounted) return;
      await _deleteContent(context, content);
      return;
    }

    final dontAskAgainNotifier = ValueNotifier<bool>(false);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n
                .removeDownloadConfirmation), // Ensure this key exists or use fallback
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: dontAskAgainNotifier,
              builder: (context, dontAskAgain, child) => CheckboxListTile(
                value: dontAskAgain,
                onChanged: (value) =>
                    dontAskAgainNotifier.value = value ?? false,
                title: const Text(
                    "Don't ask again"), // Hardcoded fallback if key missing
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (dontAskAgainNotifier.value) {
        await prefs.setBool('skip_delete_confirmation', true);
      }
      if (!context.mounted) return;
      await _deleteContent(context, content);
    }
    dontAskAgainNotifier.dispose();
  }

  /// Delete offline content
  Future<void> _deleteContent(BuildContext context, Content content) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletingContent(content.title)),
          duration: const Duration(seconds: 1),
        ),
      );

      await context.read<OfflineSearchCubit>().deleteOfflineContent(content.id);

      // Add a small delay to ensure DB transaction is committed
      // Use getIt to access the singleton DownloadBloc, bypassing context entirely
      Future.delayed(const Duration(milliseconds: 500), () {
        getIt<DownloadBloc>().add(const DownloadRefreshEvent());
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.contentDeleted),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openReader(BuildContext context, Content content) async {
    final offlineManager = getIt<OfflineContentManager>();
    // Try to find PDF
    try {
      final firstImagePath = await offlineManager.getOfflineFirstImagePath(content.id);
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        final pdfDir = Directory(p.join(contentDir, 'pdf'));
        
        if (await pdfDir.exists()) {
          final files = await pdfDir.list().toList();
          final pdfs = files.where((f) => f.path.toLowerCase().endsWith('.pdf')).toList();
          if (pdfs.isNotEmpty) {
             // Found PDF!
             final pdfFile = pdfs.first;
             if (context.mounted) {
                 AppRouter.goToReaderPdf(
                    context, 
                    filePath: pdfFile.path, 
                    contentId: content.id, 
                    title: content.title
                 );
                 return;
             }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for PDF: $e');
    }
    
    // Fallback to Image Reader
    if (context.mounted) {
       AppRouter.goToReader(
          context, 
          content.id, 
          content: content
       );
    }
  }

  Future<bool> _checkPdfExists(String contentId) async {
    final offlineManager = getIt<OfflineContentManager>();
    try {
      final firstImagePath = await offlineManager.getOfflineFirstImagePath(contentId);
      debugPrint('First image path: $firstImagePath');
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        debugPrint('contentDir: $contentDir');
        final pdfDir = Directory(p.join(contentDir, 'pdf'));
        debugPrint('pdfDir: $pdfDir');
        if (await pdfDir.exists()) {
          final files = await pdfDir.list().toList();
          return files.any((f) => f.path.toLowerCase().endsWith('.pdf'));
        }
      }
    } catch (e) {
      debugPrint('Error checking PDF existence: $e');
    }
    return false;
  }
}
