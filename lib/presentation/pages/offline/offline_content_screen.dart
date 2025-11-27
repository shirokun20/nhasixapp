import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/directory_utils.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../domain/entities/content.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/pdf_conversion_service.dart';
import '../../../utils/permission_helper.dart';
import '../../../core/utils/responsive_grid_delegate.dart';
import '../../cubits/offline_search/offline_search_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../widgets/app_scaffold_with_offline.dart';
import '../../widgets/content_card_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_content_shimmer.dart';

/// Screen for browsing offline/downloaded content
class OfflineContentScreen extends StatefulWidget {
  const OfflineContentScreen({super.key});

  @override
  State<OfflineContentScreen> createState() => _OfflineContentScreenState();
}

class _OfflineContentScreenState extends State<OfflineContentScreen> {
  late OfflineSearchCubit _offlineSearchCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _offlineSearchCubit = getIt<OfflineSearchCubit>();

    // Load all offline content initially
    _offlineSearchCubit.getAllOfflineContent();

    // Auto-scan backup folder setelah delay sebentar
    Future.delayed(const Duration(milliseconds: 500), () {
      _autoScanBackupFolder();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _autoScanBackupFolder() async {
    // Cari folder backup secara otomatis menggunakan DirectoryUtils
    debugPrint('OFFLINE_AUTO_SCAN: Starting auto-scan for backup folder...');

    // Check and request storage permission first
    debugPrint('OFFLINE_AUTO_SCAN: Checking storage permission...');
    final hasPermission = await PermissionHelper.hasStoragePermission();
    debugPrint('OFFLINE_AUTO_SCAN: Has storage permission: $hasPermission');

    if (!hasPermission) {
      debugPrint('OFFLINE_AUTO_SCAN: Requesting storage permission...');
      final granted = await PermissionHelper.requestStoragePermission(
          mounted ? context : null);
      debugPrint('OFFLINE_AUTO_SCAN: Permission request result: $granted');

      if (!granted) {
        debugPrint(
            'OFFLINE_AUTO_SCAN: Storage permission denied, cannot scan backup');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Storage permission required to scan backup folders'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final backupPath = await DirectoryUtils.findNhasixBackupFolder();
    debugPrint(
        'OFFLINE_AUTO_SCAN: DirectoryUtils.findNhasixBackupFolder() returned: $backupPath');

    if (backupPath != null) {
      debugPrint(
          'OFFLINE_AUTO_SCAN: Found backup path: $backupPath, starting scan...');
      await _scanBackupFolder(backupPath, showSnackBar: false);
    } else {
      debugPrint('OFFLINE_AUTO_SCAN: No backup folder found automatically');
    }
  }

  Future<void> _scanBackupFolder(String backupPath,
      {bool showSnackBar = true}) async {
    try {
      if (!mounted) return;

      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.scanningBackupFolder)),
        );
      }

      await _offlineSearchCubit.scanBackupContent(backupPath);
    } catch (e) {
      if (!mounted) return;
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorScanningBackup(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider<OfflineSearchCubit>(
      create: (context) => _offlineSearchCubit,
      child: AppScaffoldWithOffline(
        title: AppLocalizations.of(context)!.offlineContentTitle,
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
                builder: (context, state) => _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface),
      ),
      title: Row(
        children: [
          Icon(
            Icons.offline_bolt,
            color: Theme.of(context).colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.offlineContent,
            style: TextStyleConst.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // Debug: Check permission button
        IconButton(
          onPressed: () async {
            final hasPermission = await PermissionHelper.hasStoragePermission();
            debugPrint('DEBUG: Has storage permission: $hasPermission');
            if (!hasPermission) {
              if (mounted) {
                final granted =
                    await PermissionHelper.requestStoragePermission(context);
                debugPrint('DEBUG: Permission request result: $granted');
              }
            }
            // Retry auto-scan after permission check
            _autoScanBackupFolder();
          },
          icon: Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Check Permissions',
        ),
        // Storage info
        BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
          builder: (context, state) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _offlineSearchCubit.getOfflineStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stats['totalContent']} items',
                            style: TextStyleConst.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            stats['formattedSize'],
                            style: TextStyleConst.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
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
            child: TextField(
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _offlineSearchCubit.getAllOfflineContent();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
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
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _offlineSearchCubit.searchOfflineContent(value.trim());
                } else {
                  _offlineSearchCubit.getAllOfflineContent();
                }
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

  Widget _buildBody(OfflineSearchState state) {
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
              // Icon
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

              // Title
              Text(
                'No Offline Content',
                style: TextStyleConst.headingMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                state.emptyMessage,
                style: TextStyleConst.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tips
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
                    _buildTipRow(
                      colorScheme,
                      '1. Browse comics you like',
                    ),
                    const SizedBox(height: 8),
                    _buildTipRow(
                      colorScheme,
                      '2. Tap the download button',
                    ),
                    const SizedBox(height: 8),
                    _buildTipRow(
                      colorScheme,
                      '3. Access them here anytime, even offline!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              FilledButton.icon(
                onPressed: () => context.go('/downloads'),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Browse Downloads'),
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
          ),
        ),
      );
    }

    if (state is OfflineSearchLoaded) {
      return Column(
        children: [
          // Results header
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

          // Content grid
          Expanded(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      ResponsiveGridDelegate.createStandardGridDelegate(
                    context,
                    context.read<SettingsCubit>(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final content = state.results[index];
                    Logger().i(content);
                    return ContentCard(
                      content: content,
                      onTap: () =>
                          context.push('/reader/${content.id}', extra: content),
                      onLongPress: () => _showContentActions(context, content),
                      showOfflineIndicator: true,
                      isHighlighted: false,
                      offlineSize: state.offlineSizes[content.id], // From state
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // Initial state
    return const OfflineContentGridShimmer();
  }

  /// Show bottom sheet with content actions (Read, Convert to PDF, Delete)
  Future<void> _showContentActions(
      BuildContext context, Content content) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final offlineManager = getIt<OfflineContentManager>();

    // Calculate content size for delete action
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content header with thumbnail and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      content.coverUrl,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                  // Title and metadata
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
                          '${content.pageCount} pages',
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

            const Divider(height: 1),

            // Actions
            ListTile(
              leading: Icon(Icons.menu_book, color: colorScheme.primary),
              title: Text(l10n.readNow),
              onTap: () {
                Navigator.pop(context);
                context.push('/reader/${content.id}', extra: content);
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
              title: Text(l10n.convertToPdf),
              subtitle: Text('${content.pageCount} pages'),
              onTap: () {
                Navigator.pop(context);
                _generatePdf(context, content);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: colorScheme.error),
              title: Text(
                l10n.delete,
                style: TextStyle(color: colorScheme.error),
              ),
              subtitle: Text(
                sizeText,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, content);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Generate PDF from offline content
  Future<void> _generatePdf(BuildContext context, Content content) async {
    final l10n = AppLocalizations.of(context)!;
    final offlineManager = getIt<OfflineContentManager>();
    final pdfService = getIt<PdfConversionService>();

    try {
      // Show loading indicator
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.convertingToPdf),
          duration: const Duration(seconds: 2),
        ),
      );

      // Get offline image paths
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

      // Start PDF conversion in background
      await pdfService.convertToPdfInBackground(
        contentId: content.id,
        title: content.title,
        imagePaths: imagePaths,
        maxPagesPerFile: 50,
      );

      // Success notification will be shown by the service
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
    final offlineManager = getIt<OfflineContentManager>();

    // Check if user enabled 'don't ask again'
    final prefs = await SharedPreferences.getInstance();
    final skipConfirmation = prefs.getBool('skip_delete_confirmation') ?? false;

    // Calculate content size
    final imagePaths = await offlineManager.getOfflineImageUrls(content.id);
    double totalSize = 0;
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    final sizeInMB = (totalSize / (1024 * 1024)).toStringAsFixed(2);

    if (!context.mounted) return;

    // Skip confirmation if user enabled 'don't ask again'
    if (skipConfirmation) {
      await _deleteContent(context, content, sizeInMB);
      return;
    }

    bool dontAskAgain = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.delete,
                style: TextStyleConst.headingSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    content.coverUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                        style: TextStyleConst.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${content.pageCount} pages',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Storage info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Storage to be freed: $sizeInMB MB',
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning message
            Text(
              l10n.removeDownloadConfirmation,
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Don't ask again checkbox
            StatefulBuilder(
              builder: (context, setState) => CheckboxListTile(
                value: dontAskAgain,
                onChanged: (value) {
                  setState(() {
                    dontAskAgain = value ?? false;
                  });
                },
                title: Text(
                  "Don't ask again",
                  style: TextStyleConst.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyleConst.labelLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(
              l10n.delete,
              style: TextStyleConst.labelLarge,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Save 'don't ask again' preference if checkbox was enabled
      if (dontAskAgain) {
        await prefs.setBool('skip_delete_confirmation', true);
      }
      await _deleteContent(context, content, sizeInMB);
    }
  }

  /// Delete offline content
  Future<void> _deleteContent(
      BuildContext context, Content content, String sizeInMB) async {
    final offlineManager = getIt<OfflineContentManager>();

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleting ${content.title}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Delete content
      final success = await offlineManager.deleteOfflineContent(content.id);

      if (!context.mounted) return;

      if (success) {
        // Refresh offline content list
        _offlineSearchCubit.getAllOfflineContent();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${content.title} deleted. Freed $sizeInMB MB'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ${content.title}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Build a tip row for empty state
  Widget _buildTipRow(ColorScheme colorScheme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: colorScheme.primary,
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
}
