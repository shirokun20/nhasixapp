# Code Snippets & Implementation Examples

Quick reference for copy-paste ready code during implementation.

---

## 🔔 Notification Sound Configuration (Android-only)

### notification_service.dart - CURRENT IMPLEMENTATION (ALREADY CORRECT!)

**IMPORTANT:** This project is **Android-only**. The current implementation is **ALREADY CORRECT** - notifications use `Importance` levels to control sound.

```dart
// ✅ CURRENT: Download started - NO sound (Importance.low)
Future<void> showDownloadStarted({
  required String contentId,
  required String title,
}) async {
  if (!isEnabled) return;
  
  final notificationId = _getNotificationId(contentId);
  await _notificationsPlugin.show(
    notificationId,
    _getLocalized('downloadStarted', fallback: 'Download Started'),
    _getLocalized('downloadingWithTitle', args: {'title': _truncateTitle(title)}),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low, // ✅ NO SOUND - Already correct!
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
      ),
      iOS: const DarwinNotificationDetails(
        // NOT USED - Android-only project
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    ),
    payload: contentId,
  );
}

// ✅ CURRENT: Download progress - NO sound (Importance.low)
Future<void> updateDownloadProgress({
  required String contentId,
  required int progress,
  required String title,
  bool isPaused = false,
}) async {
  if (!isEnabled) return;
  
  final notificationId = _getNotificationId(contentId);
  await _notificationsPlugin.show(
    notificationId,
    statusText,
    _truncateTitle(title),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low, // ✅ NO SOUND - Already correct!
        priority: Priority.low,
        ongoing: !isPaused,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        // ... action buttons
      ),
      iOS: const DarwinNotificationDetails(
        // NOT USED - Android-only project
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    ),
    payload: contentId,
  );
}

// ✅ CURRENT: Download completed - WITH sound (Importance.defaultImportance)
Future<void> showDownloadCompleted({
  required String contentId,
  required String title,
  required String downloadPath,
}) async {
  if (!isEnabled) return;
  
  final notificationId = _getNotificationId(contentId);
  await _notificationsPlugin.show(
    notificationId,
    _getLocalized('downloadComplete', fallback: 'Download Complete'),
    _getLocalized('downloadedWithTitle', args: {'title': _truncateTitle(title)}),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannelId,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.defaultImportance, // ✅ WITH SOUND - Already correct!
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
        actions: [
          AndroidNotificationAction('open', 'Open', showsUserInterface: true),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        // NOT USED - Android-only project
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: contentId,
  );
}
```

**Key Points (Android-only):**
- `Importance.low` = No sound, no vibration, minimized notification
- `Importance.defaultImportance` = Default notification sound
- `Importance.high` = High priority with sound and heads-up
- **No `playSound` parameter needed** - `importance` controls everything!
- iOS code exists but is **never executed** (Android-only project)

---

## ✅ Bulk Delete / Selection Mode (PLANNED - Based on flutter_11.png)

### offline_content_screen.dart - Add Selection Mode State & Methods

**IMPORTANT:** This feature is PLANNED (shown in flutter_11.png mockup) but NOT YET IMPLEMENTED.

```dart
class _OfflineContentScreenState extends State<OfflineContentScreen> {
  late OfflineSearchCubit _offlineSearchCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // ✅ NEW: Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedContentIds = {};
  
  // ... existing initState, dispose, etc.
  
  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedContentIds.clear(); // Clear selection when exiting
      }
    });
  }
  
  /// Toggle content selection
  void _toggleContentSelection(String contentId) {
    setState(() {
      if (_selectedContentIds.contains(contentId)) {
        _selectedContentIds.remove(contentId);
      } else {
        _selectedContentIds.add(contentId);
      }
    });
  }
  
  /// Select all visible content
  void _selectAll(List<Content> allContent) {
    setState(() {
      _selectedContentIds.addAll(allContent.map((c) => c.id));
    });
  }
  
  /// Deselect all
  void _deselectAll() {
    setState(() {
      _selectedContentIds.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AppScaffoldWithOffline(
      title: 'Offline Content',
      // ✅ Add selection mode toggle in AppBar
      actions: [
        if (!_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Select items',
            onPressed: _toggleSelectionMode,
          )
        else ..[
          // Select All / Deselect All
          if (_selectedContentIds.isNotEmpty)
            TextButton(
              onPressed: _deselectAll,
              child: Text('Deselect All'),
            )
          else
            TextButton(
              onPressed: () {
                final state = _offlineSearchCubit.state;
                if (state is OfflineSearchLoaded) {
                  _selectAll(state.results);
                }
              },
              child: Text('Select All'),
            ),
          // Cancel selection mode
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: _toggleSelectionMode,
          ),
        ],
      ],
      body: Stack(
        children: [
          // Main content grid
          BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
            builder: (context, state) {
              if (state is OfflineSearchLoaded) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: ResponsiveGridDelegate.createStandardGridDelegate(
                    context,
                    context.read<SettingsCubit>(),
                  ),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final content = state.results[index];
                    final isSelected = _selectedContentIds.contains(content.id);
                    
                    return Stack(
                      children: [
                        ContentCard(
                          content: content,
                          onTap: _isSelectionMode
                              ? () => _toggleContentSelection(content.id)
                              : () => context.push('/reader/${content.id}', extra: content),
                          onLongPress: !_isSelectionMode
                              ? () => _showContentActions(context, content)
                              : null,
                          showOfflineIndicator: true,
                          isHighlighted: isSelected,
                        ),
                        // ✅ Checkbox overlay in selection mode
                        if (_isSelectionMode)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    )
                                  : const SizedBox(width: 20, height: 20),
                            ),
                          ),
                      ],
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          
          // ✅ Floating action for bulk delete (when items selected)
          if (_isSelectionMode && _selectedContentIds.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: InkWell(
                  onTap: _showBulkDeleteConfirmation,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete ${_selectedContentIds.length} items',
                          style: TextStyleConst.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Show bulk delete confirmation dialog
  Future<void> _showBulkDeleteConfirmation() async {
    if (_selectedContentIds.isEmpty) return;
    
    final colorScheme = Theme.of(context).colorScheme;
    final offlineManager = getIt<OfflineContentManager>();
    
    // Calculate total size of selected items
    int totalSize = 0;
    for (final contentId in _selectedContentIds) {
      totalSize += await offlineManager.getContentSize(contentId);
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Delete ${_selectedContentIds.length} items?',
          style: TextStyleConst.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete ${_selectedContentIds.length} offline items.',
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Will free: ${_formatBytes(totalSize)}',
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ This action cannot be undone!',
              style: TextStyleConst.bodySmall.copyWith(
                color: colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyleConst.labelLarge,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete ${_selectedContentIds.length} items',
              style: TextStyleConst.labelLarge.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _performBulkDelete();
    }
  }
  
  /// Perform bulk delete operation with progress
  Future<void> _performBulkDelete() async {
    final offlineManager = getIt<OfflineContentManager>();
    final total = _selectedContentIds.length;
    int completed = 0;
    int totalFreedSpace = 0;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Deleting $completed/$total...',
              style: TextStyleConst.bodyMedium,
            ),
          ],
        ),
      ),
    );
    
    // Delete each item
    for (final contentId in _selectedContentIds.toList()) {
      try {
        final result = await offlineManager.deleteOfflineContent(contentId);
        if (result.success) {
          completed++;
          totalFreedSpace += result.freedSpace;
        }
      } catch (e) {
        debugPrint('Error deleting $contentId: $e');
      }
    }
    
    if (!mounted) return;
    
    // Close progress dialog
    Navigator.of(context).pop();
    
    // Refresh content list
    _offlineSearchCubit.getAllOfflineContent();
    
    // Exit selection mode
    setState(() {
      _isSelectionMode = false;
      _selectedContentIds.clear();
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $completed items, freed ${_formatBytes(totalFreedSpace)}',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
```

---

## 🔘 Long Press + Bottom Sheet (PLANNED - Based on flutter_11.png)

### ✅ ContentCard Widget (ALREADY SUPPORTS onLongPress!)

**VERIFIED:** `lib/presentation/widgets/content_card_widget.dart` line 22 has `final VoidCallback? onLongPress;`

Widget is **READY TO USE** - just need to pass the parameter!

### offline_content_screen.dart - Use Existing onLongPress

```dart
// ❌ CURRENT: Only uses onTap
ContentCard(
  content: content,
  onTap: () => context.push('/reader/${content.id}', extra: content),
  showOfflineIndicator: true,
  isHighlighted: false,
)

// ✅ UPDATED: Add onLongPress to show bottom sheet
ContentCard(
  content: content,
  onTap: () => context.push('/reader/${content.id}', extra: content),
  onLongPress: () => _showContentActions(context, content), // ✅ Use existing parameter!
  showOfflineIndicator: true,
  isHighlighted: false,
)

/// Show bottom sheet with actions (Read, Convert PDF, Delete)
/// Based on UI mockup: screenshots/flutter_11.png
void _showContentActions(BuildContext context, Content content) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: false,
    enableDrag: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content header with thumbnail and title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: content.thumbnailUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.errorContainer,
                      child: Icon(Icons.error, color: colorScheme.onErrorContainer),
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
          
          // Action: Read
          ListTile(
            leading: Icon(Icons.menu_book, color: colorScheme.primary),
            title: Text(
              AppLocalizations.of(context)!.read,
              style: TextStyleConst.bodyLarge,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/reader/${content.id}', extra: content);
            },
          ),
          
          // Action: Convert to PDF
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
            title: Text(
              AppLocalizations.of(context)!.convertToPdf,
              style: TextStyleConst.bodyLarge,
            ),
            subtitle: Text(
              'Generate PDF (${content.pageCount} pages)',
              style: TextStyleConst.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _generatePdf(content);
            },
          ),
          
          // Action: Delete
          ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyleConst.bodyLarge.copyWith(
                color: colorScheme.error,
              ),
            ),
            subtitle: FutureBuilder<int>(
              future: getIt<OfflineContentManager>().getContentSize(content.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Free ${_formatBytes(snapshot.data!)} storage',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.error.withOpacity(0.8),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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

/// Format bytes to human-readable string
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
```

---

## 🗑️ Delete Feature for Offline Screen

### offline_content_manager.dart - Delete Method

**VERIFIED Path Structure from Code:**
- Primary: `[basePath]/nhasix/[contentId]/images/page_XXX.jpg`
- Metadata: `[basePath]/nhasix/[contentId]/metadata.json`
- Old structure: `[basePath]/nhasix/[contentId]/page_XXX.jpg` (fallback)

```dart
/// Result of delete operation
class DeleteResult {
  final bool success;
  final int freedSpace; // bytes
  final String? error;
  
  DeleteResult.success({required this.freedSpace})
      : success = true,
        error = null;
  
  DeleteResult.error(this.error)
      : success = false,
        freedSpace = 0;
  
  DeleteResult.notFound()
      : success = false,
        freedSpace = 0,
        error = 'Content not found';
}

/// Delete offline content and free storage
Future<DeleteResult> deleteOfflineContent(String contentId) async {
  try {
    _logger.i('Deleting offline content: $contentId');
    
    // Check if content exists
    final exists = await isContentAvailableOffline(contentId);
    if (!exists) {
      _logger.w('Content not found for deletion: $contentId');
      return DeleteResult.notFound();
    }
    
    // Calculate current size before deletion
    final sizeBefore = await getContentSize(contentId);
    _logger.d('Content size before deletion: $sizeBefore bytes');
    
    // Get content directory (ACTUAL path structure)
    final paths = await _getPossibleDownloadPaths();
    Directory? contentDir;
    
    for (final basePath in paths) {
      final dir = Directory('$basePath/nhasix/$contentId');
      if (await dir.exists()) {
        contentDir = dir;
        break;
      }
    }
    
    if (contentDir == null || !await contentDir.exists()) {
      throw Exception('Content directory not found');
    }
    
    // Delete the entire content directory
    await contentDir.delete(recursive: true);
    _logger.i('Deleted content directory: ${contentDir.path}');
    
    // Delete metadata
    try {
      await _metadataStorage.delete(contentId);
      _logger.i('Deleted metadata for: $contentId');
    } catch (e) {
      _logger.w('Failed to delete metadata: $e');
    }
    
    // Delete thumbnails
    await _deleteThumbnails(contentId);
    
    // Clear from cache
    _contentCache.remove(contentId);
    
    _logger.i('Successfully deleted content $contentId, freed ${sizeBefore} bytes');
    return DeleteResult.success(freedSpace: sizeBefore);
    
  } catch (e, stackTrace) {
    _logger.e('Error deleting offline content $contentId: $e', 
              error: e, stackTrace: stackTrace);
    return DeleteResult.error(e.toString());
  }
}

/// Delete thumbnails for content
Future<void> _deleteThumbnails(String contentId) async {
  try {
    final baseDir = await getApplicationDocumentsDirectory();
    final thumbnailPath = '${baseDir.path}/thumbnails/$contentId.jpg';
    final thumbnailFile = File(thumbnailPath);
    
    if (await thumbnailFile.exists()) {
      await thumbnailFile.delete();
      _logger.d('Deleted thumbnail: $thumbnailPath');
    }
  } catch (e) {
    _logger.w('Failed to delete thumbnails: $e');
  }
}

/// Get size of offline content in bytes
Future<int> getContentSize(String contentId) async {
  try {
    final baseDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${baseDir.path}/downloads/$contentId');
    
    if (!await contentDir.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    await for (final entity in contentDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  } catch (e) {
    _logger.e('Error calculating content size: $e');
    return 0;
  }
}
```

### offline_content_screen.dart

```dart
/// Show delete confirmation dialog
void _showDeleteConfirmation(BuildContext context, Content content) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        AppLocalizations.of(context)!.deleteContent,
        style: TextStyleConst.headlineSmall.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.deleteContentMessage(content.title),
            style: TextStyleConst.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: getIt<OfflineContentManager>().getContentSize(content.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final sizeFormatted = _formatBytes(snapshot.data!);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Will free: $sizeFormatted',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.deleteWarning,
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.error,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyleConst.labelLarge,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _deleteContent(content);
          },
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: TextStyleConst.labelLarge.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Delete offline content
Future<void> _deleteContent(Content content) async {
  // Show loading
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.deletingContent),
      duration: const Duration(seconds: 1),
    ),
  );
  
  final offlineManager = getIt<OfflineContentManager>();
  final result = await offlineManager.deleteOfflineContent(content.id);
  
  if (!mounted) return;
  
  if (result.success) {
    // Refresh the list
    _offlineSearchCubit.getAllOfflineContent();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.contentDeleted(
            _formatBytes(result.freedSpace),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to delete content'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Format bytes to human-readable string
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
```

---

## 📄 PDF Generation from Offline Screen

### offline_content_screen.dart

```dart
/// Show content actions bottom sheet
void _showContentActions(BuildContext context, Content content) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              content.title,
              style: TextStyleConst.headlineSmall.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(),
          
          // Open action
          ListTile(
            leading: Icon(Icons.book, color: colorScheme.primary),
            title: Text(
              AppLocalizations.of(context)!.openReader,
              style: TextStyleConst.bodyLarge,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/reader/${content.id}', extra: content);
            },
          ),
          
          // Generate PDF action
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
            title: Text(
              AppLocalizations.of(context)!.generatePdf,
              style: TextStyleConst.bodyLarge,
            ),
            subtitle: Text(
              '${content.pageCount} pages',
              style: TextStyleConst.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              _generatePdf(content);
            },
          ),
          
          // Share action
          ListTile(
            leading: Icon(Icons.share, color: colorScheme.secondary),
            title: Text(
              AppLocalizations.of(context)!.share,
              style: TextStyleConst.bodyLarge,
            ),
            onTap: () {
              Navigator.pop(context);
              _shareContent(content);
            },
          ),
          
          // Delete action
          ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyleConst.bodyLarge.copyWith(
                color: colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, content);
            },
          ),
        ],
      ),
    ),
  );
}

/// Generate PDF from offline content
Future<void> _generatePdf(Content content) async {
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.generatingPdf,
              style: TextStyleConst.bodyMedium,
            ),
          ],
        ),
      ),
    );
    
    // Get PDF conversion service
    final pdfService = getIt<PdfConversionService>();
    final offlineManager = getIt<OfflineContentManager>();
    
    // Get image paths
    final baseDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${baseDir.path}/downloads/${content.id}/images');
    
    if (!await imagesDir.exists()) {
      throw Exception('Images directory not found');
    }
    
    // Collect image files
    final imageFiles = await imagesDir
        .list()
        .where((entity) => entity is File && 
               (entity.path.endsWith('.jpg') || entity.path.endsWith('.png')))
        .map((entity) => entity.path)
        .toList();
    
    // Sort by page number
    imageFiles.sort();
    
    // Generate PDF
    final result = await pdfService.convertToPdfInIsolate(
      contentId: content.id,
      title: content.title,
      imagePaths: imageFiles,
      outputDir: '${baseDir.path}/pdfs',
    );
    
    if (!mounted) return;
    
    // Close loading dialog
    Navigator.of(context).pop();
    
    if (result.success) {
      // Show success message with actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pdfGeneratedSuccess(
              _formatBytes(result.fileSize!),
            ),
          ),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.open,
            onPressed: () => _openPdf(result.pdfPath!),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'PDF generation failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    
    // Close loading dialog if still open
    Navigator.of(context).pop();
    
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Open PDF file
Future<void> _openPdf(String pdfPath) async {
  try {
    await OpenFile.open(pdfPath);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open PDF: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
```

### content_card_widget.dart - Add Long Press

```dart
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.onLongPress, // NEW
    this.showOfflineIndicator = false,
    this.isHighlighted = false,
  });

  final Content content;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // NEW
  final bool showOfflineIndicator;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      // ... existing code
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress, // NEW
        borderRadius: BorderRadius.circular(8),
        child: // ... existing content
      ),
    );
  }
}
```

---

## 📐 Webtoon Image Detection & Splitting (VERIFIED from actual images)

### webtoon_image_processor.dart (NEW FILE)

**VERIFIED Dimensions:**
- Normal image: 902×1280px (AR=1.42)
- Webtoon image: 1275×16383px (AR=12.85)
- Threshold: AR > 2.5 (safe margin between 1.42 and 12.85)

```dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Processor for handling webtoon-style (extremely tall) images
/// VERIFIED: Normal AR=1.42, Webtoon AR=12.85, Threshold=2.5
class WebtoonImageProcessor {
  // VERIFIED threshold: Normal=1.42, Webtoon=12.85, safe margin=2.5
  static const double WEBTOON_ASPECT_RATIO_THRESHOLD = 2.5;
  
  // Target height: Match normal image (1280px) for consistent reading
  static const int MAX_PDF_PAGE_HEIGHT = 1280; 
  
  static const int OVERLAP_PIXELS = 30; // Small overlap for continuity
  static const int JPEG_QUALITY = 90; // balance size vs quality
  
  /// Detect if image is webtoon-style (extremely tall)
  /// VERIFIED: Normal=1.42 (false), Webtoon=12.85 (true)
  static bool isWebtoonImage(int width, int height) {
    if (width == 0) return false;
    final aspectRatio = height / width;
    return aspectRatio > WEBTOON_ASPECT_RATIO_THRESHOLD;
  }
  
  /// Split tall image into multiple parts for PDF
  static Future<List<Uint8List>> splitTallImage(
    img.Image image, {
    int maxHeight = MAX_PDF_PAGE_HEIGHT,
    int overlap = OVERLAP_PIXELS,
    int quality = JPEG_QUALITY,
  }) async {
    final parts = <Uint8List>[];
    final totalHeight = image.height;
    int currentY = 0;
    int partNumber = 1;
    
    debugPrint('WebtoonProcessor: Splitting ${image.width}x$totalHeight image');
    
    while (currentY < totalHeight) {
      // Calculate slice height
      final remainingHeight = totalHeight - currentY;
      final sliceHeight = remainingHeight > maxHeight 
          ? maxHeight 
          : remainingHeight;
      
      // Crop image slice
      final slice = img.copyCrop(
        image,
        x: 0,
        y: currentY,
        width: image.width,
        height: sliceHeight,
      );
      
      // Encode slice
      final sliceBytes = img.encodeJpg(slice, quality: quality);
      parts.add(Uint8List.fromList(sliceBytes));
      
      debugPrint('WebtoonProcessor: Part $partNumber - y=$currentY, h=$sliceHeight');
      partNumber++;
      
      // Move to next slice
      if (currentY + sliceHeight < totalHeight) {
        currentY += sliceHeight - overlap; // Overlap for continuity
      } else {
        break; // Last slice
      }
    }
    
    debugPrint('WebtoonProcessor: Split complete - ${parts.length} parts');
    return parts;
  }
  
  /// Get estimated part count for webtoon image
  static int estimatePartCount(int width, int height) {
    if (!isWebtoonImage(width, height)) return 1;
    
    final parts = (height / (MAX_PDF_PAGE_HEIGHT - OVERLAP_PIXELS)).ceil();
    return parts;
  }
}
```

### pdf_service.dart - Integration

```dart
// Update _processImageStatic to handle webtoons

static Future<List<Uint8List>> _processImageStatic(
  String imagePath, {
  required int maxWidth,
  required int quality,
}) async {
  try {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    final imageBytes = await file.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Could not decode image: $imagePath');
    }

    // Check if webtoon image
    if (WebtoonImageProcessor.isWebtoonImage(image.width, image.height)) {
      debugPrint('PDF: Webtoon detected ${image.width}x${image.height}');
      
      // Resize width first if needed
      img.Image resizedImage = image;
      if (image.width > maxWidth) {
        final aspectRatio = image.height / image.width;
        final newHeight = (maxWidth * aspectRatio).round();
        
        resizedImage = img.copyResize(
          image,
          width: maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Split into multiple parts
      final parts = await WebtoonImageProcessor.splitTallImage(
        resizedImage,
        quality: quality,
      );
      
      debugPrint('PDF: Webtoon split into ${parts.length} parts');
      return parts;
    } else {
      // Normal image processing
      img.Image processedImage = image;
      
      // Resize if needed
      if (image.width > maxWidth) {
        final aspectRatio = image.height / image.width;
        final newHeight = (maxWidth * aspectRatio).round();

        processedImage = img.copyResize(
          image,
          width: maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG
      final compressedBytes = img.encodeJpg(processedImage, quality: quality);
      return [Uint8List.fromList(compressedBytes)];
    }
  } catch (e) {
    debugPrint('Error processing image $imagePath: $e');
    return [];
  }
}
```

---

## 📖 Reading Mode - Comprehensive Revamp (4 Phases)

### Phase 1: Variable Height Support - reader_screen.dart

```dart
class _ReaderScreenState extends State<ReaderScreen> {
  // ✅ NEW: Cache actual image heights for accurate scroll tracking
  final Map<int, double> _imageHeights = {};
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }
  
  /// ✅ NEW: Called when image is loaded with actual dimensions
  void _onImageLoaded(int pageIndex, Size imageSize) {
    // Calculate rendered height based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = imageSize.height / imageSize.width;
    final renderedHeight = screenWidth * aspectRatio;
    
    setState(() {
      _imageHeights[pageIndex] = renderedHeight;
    });
    
    logger.d('Reader: Cached height for page $pageIndex: $renderedHeight px (AR: ${aspectRatio.toStringAsFixed(2)})');
  }
  
  /// ✅ UPDATED: Accurate scroll tracking using cached heights
  void _onScrollChanged() {
    final state = _readerCubit.state;
    if (state.readingMode == ReadingMode.continuousScroll && 
        state.content != null) {
      
      final scrollPosition = _scrollController.offset;
      int currentPage = 1;
      double accumulatedHeight = 0;
      
      // ✅ Use cached heights for accuracy (not approximation!)
      for (int i = 0; i < state.content!.pageCount; i++) {
        // Get cached height or use screen height as fallback
        final imageHeight = _imageHeights[i] ?? 
            MediaQuery.of(context).size.height;
        
        // Account for spacing between images
        const spacing = 8.0; // from Container margin
        final totalItemHeight = imageHeight + spacing;
        
        // Check if scroll position is within this image bounds
        if (scrollPosition >= accumulatedHeight && 
            scrollPosition < accumulatedHeight + totalItemHeight) {
          currentPage = i + 1;
          break;
        }
        
        accumulatedHeight += totalItemHeight;
      }
      
      // Update only if page changed (avoid unnecessary rebuilds)
      if (currentPage != _lastReportedPage) {
        logger.i('Reader: Page changed: $_lastReportedPage → $currentPage');
        _lastReportedPage = currentPage;
        _readerCubit.updateCurrentPage(currentPage);
      }
    }
  }
  
  /// ✅ UPDATED: Pass callback to image widget
  Widget _buildImageViewer(String imageUrl, int pageNumber, {bool isContinuous = false}) {
    return isContinuous
      ? Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExtendedImageReaderWidget(
            imageUrl: imageUrl,
            contentId: widget.contentId,
            pageNumber: pageNumber,
            readingMode: ReadingMode.continuousScroll,
            enableZoom: enableZoom,
            onImageLoaded: (Size size) => _onImageLoaded(pageNumber - 1, size), // ✅ NEW
          ),
        )
      : ExtendedImageReaderWidget(...);
  }
}
```

### Phase 2: Webtoon Detection - webtoon_detector.dart (NEW FILE)

```dart
// lib/core/utils/webtoon_detector.dart

/// Utility for detecting webtoon-style (extremely tall) images
/// 
/// Based on verified dimensions from actual project images:
/// - Normal manga: 902×1280px, AR = 1.42
/// - Webtoon: 1275×16383px, AR = 12.85
/// - Threshold: 2.5 (safe midpoint)
class WebtoonDetector {
  /// Aspect ratio threshold for webtoon detection
  /// Normal manga: AR ~1.4, Webtoon: AR ~12.8
  static const double ASPECT_RATIO_THRESHOLD = 2.5;
  
  /// Detect if image is webtoon-style (extremely tall)
  /// 
  /// Returns true if height/width > 2.5
  /// 
  /// Examples:
  /// - Normal (902×1280): AR=1.42 → false
  /// - Webtoon (1275×16383): AR=12.85 → true
  static bool isWebtoon(Size imageSize) {
    if (imageSize.width == 0) return false; // Avoid division by zero
    
    final aspectRatio = imageSize.height / imageSize.width;
    final result = aspectRatio > ASPECT_RATIO_THRESHOLD;
    
    if (result) {
      logger.d('Webtoon detected: ${imageSize.width.toInt()}×${imageSize.height.toInt()} (AR: ${aspectRatio.toStringAsFixed(2)})');
    }
    
    return result;
  }
  
  /// Get recommended BoxFit for image based on webtoon detection
  static BoxFit getRecommendedBoxFit(Size? imageSize, ReadingMode mode) {
    if (imageSize != null && isWebtoon(imageSize)) {
      return BoxFit.fitWidth; // Always fit width for webtoons
    }
    
    // Default based on reading mode
    switch (mode) {
      case ReadingMode.singlePage:
        return BoxFit.contain;
      case ReadingMode.verticalPage:
      case ReadingMode.continuousScroll:
        return BoxFit.fitWidth;
    }
  }
}
```

### Phase 2: Webtoon Detection - extended_image_reader_widget.dart

```dart
class ExtendedImageReaderWidget extends StatefulWidget {
  // ✅ NEW: Callback for image loaded with dimensions
  final Function(Size imageSize)? onImageLoaded;
  
  const ExtendedImageReaderWidget({
    super.key,
    required this.imageUrl,
    required this.contentId,
    required this.pageNumber,
    required this.readingMode,
    this.enableZoom = false,
    this.onImageLoaded, // ✅ NEW parameter
  });
  
  // ... existing code
}

class _ExtendedImageReaderWidgetState extends State<ExtendedImageReaderWidget> {
  Size? _imageSize; // ✅ NEW: Store image size for webtoon detection
  
  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
      image: imageProvider,
      fit: _getBoxFit(), // ✅ Uses webtoon detection
      mode: ExtendedImageMode.gesture,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.completed) {
          // ✅ Notify parent of actual image size
          final imageInfo = state.extendedImageInfo;
          if (imageInfo != null) {
            final size = Size(
              imageInfo.image.width.toDouble(),
              imageInfo.image.height.toDouble(),
            );
            
            setState(() {
              _imageSize = size; // ✅ Store for BoxFit calculation
            });
            
            widget.onImageLoaded?.call(size); // ✅ Notify parent
          }
        }
        
        // ... existing load state handling (loading, failed, etc.)
      },
      // ... other properties
    );
  }
  
  /// ✅ UPDATED: Auto-detect webtoon and apply fitWidth
  BoxFit _getBoxFit() {
    // Use WebtoonDetector utility for consistent detection
    if (_imageSize != null) {
      return WebtoonDetector.getRecommendedBoxFit(_imageSize, widget.readingMode);
    }
    
    // Fallback before image loads
    switch (widget.readingMode) {
      case ReadingMode.singlePage:
        return BoxFit.contain;
      case ReadingMode.verticalPage:
      case ReadingMode.continuousScroll:
        return BoxFit.fitWidth;
    }
  }
}
```

### Phase 2: Optional Webtoon Visual Badge

```dart
/// Optional: Visual indicator for webtoon images
Widget _buildWebtoonBadge() {
  if (_imageSize != null && WebtoonDetector.isWebtoon(_imageSize!)) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'WEBTOON',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}

// Use in Stack:
return Stack(
  children: [
    ExtendedImage(...),
    _buildWebtoonBadge(), // ✅ Optional badge
  ],
);
```

### Phase 3: Adaptive Preloading - reader_screen.dart

```dart
class _ReaderScreenState extends State<ReaderScreen> {
  // ✅ NEW: Scroll velocity tracking
  double _lastScrollOffset = 0;
  DateTime _lastScrollTime = DateTime.now();
  double _scrollVelocity = 0; // pixels per second
  
  final Set<int> _prefetchedPages = {};
  
  /// ✅ UPDATED: Track velocity and trigger adaptive prefetch
  void _onScrollChanged() {
    // Calculate scroll velocity
    final now = DateTime.now();
    final offset = _scrollController.offset;
    final duration = now.difference(_lastScrollTime).inMilliseconds;
    
    if (duration > 0) {
      _scrollVelocity = (offset - _lastScrollOffset) / (duration / 1000);
    }
    
    _lastScrollOffset = offset;
    _lastScrollTime = now;
    
    // Existing scroll tracking logic...
    // ... (page calculation code from Phase 1)
    
    // ✅ NEW: Adaptive prefetch based on velocity
    final prefetchCount = _calculatePrefetchCount(_scrollVelocity.abs());
    _prefetchImages(prefetchCount);
  }
  
  /// ✅ NEW: Calculate prefetch count based on scroll speed
  int _calculatePrefetchCount(double velocity) {
    if (velocity < 100) {
      return 2; // Slow scroll: minimal prefetch
    } else if (velocity < 500) {
      return 5; // Normal scroll: moderate prefetch
    } else {
      return 8; // Fast scroll: aggressive prefetch
    }
  }
  
  /// ✅ NEW: Prefetch images ahead
  Future<void> _prefetchImages(int count) async {
    final state = _readerCubit.state;
    if (state.content == null) return;
    
    final currentPage = state.currentPage;
    final totalPages = state.content!.pageCount;
    
    // Prefetch ahead
    for (int i = 1; i <= count; i++) {
      final targetPage = currentPage + i;
      if (targetPage > totalPages) break;
      if (_prefetchedPages.contains(targetPage)) continue;
      
      final imageUrl = state.content!.imageUrls[targetPage - 1];
      await _prefetchImage(imageUrl, targetPage);
    }
    
    // Cleanup old cache
    _cleanupPrefetchCache(currentPage);
  }
  
  /// ✅ NEW: Prefetch single image
  Future<void> _prefetchImage(String imageUrl, int page) async {
    try {
      final provider = NetworkImage(imageUrl);
      await precacheImage(provider, context);
      _prefetchedPages.add(page);
      logger.d('Reader: Prefetched page $page');
    } catch (e) {
      logger.w('Reader: Failed to prefetch page $page: $e');
    }
  }
  
  /// ✅ NEW: Cleanup distant pages from cache
  void _cleanupPrefetchCache(int currentPage) {
    _prefetchedPages.removeWhere((page) => 
      page < currentPage - 2 || page > currentPage + 10
    );
  }
}
```

### Phase 4: Performance Optimization - reader_screen.dart

```dart
class _ReaderScreenState extends State<ReaderScreen> {
  Timer? _scrollDebounceTimer; // ✅ NEW: For debouncing
  
  /// ✅ UPDATED: Debounce scroll events
  void _onScrollChanged() {
    _scrollDebounceTimer?.cancel();
    
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      _performScrollTracking(); // ✅ Extract to separate method
    });
  }
  
  /// ✅ NEW: Actual scroll tracking logic (debounced)
  void _performScrollTracking() {
    // Calculate velocity
    final now = DateTime.now();
    final offset = _scrollController.offset;
    final duration = now.difference(_lastScrollTime).inMilliseconds;
    
    if (duration > 0) {
      _scrollVelocity = (offset - _lastScrollOffset) / (duration / 1000);
    }
    
    _lastScrollOffset = offset;
    _lastScrollTime = now;
    
    // Page calculation logic (from Phase 1)
    final state = _readerCubit.state;
    if (state.readingMode == ReadingMode.continuousScroll && state.content != null) {
      // ... (existing page calculation code)
    }
    
    // Adaptive prefetch (from Phase 3)
    final prefetchCount = _calculatePrefetchCount(_scrollVelocity.abs());
    _prefetchImages(prefetchCount);
  }
  
  /// ✅ UPDATED: Wrap with RepaintBoundary
  Widget _buildImageViewer(String imageUrl, int pageNumber, {bool isContinuous = false}) {
    return RepaintBoundary( // ✅ Isolate repaint
      child: isContinuous
        ? Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ExtendedImageReaderWidget(
              imageUrl: imageUrl,
              contentId: widget.contentId,
              pageNumber: pageNumber,
              readingMode: ReadingMode.continuousScroll,
              enableZoom: enableZoom,
              onImageLoaded: (Size size) => _onImageLoaded(pageNumber - 1, size),
            ),
          )
        : ExtendedImageReaderWidget(...),
    );
  }
  
  @override
  void dispose() {
    _scrollDebounceTimer?.cancel(); // ✅ Cleanup
    _scrollController.removeListener(_onScrollChanged);
    super.dispose();
  }
}
```

### Phase 4: Optional AutomaticKeepAlive for Images

```dart
/// Optional: Keep recent pages alive in memory
class ImageViewerWidget extends StatefulWidget {
  // ... widget code
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive {
    // Keep alive if within ±3 pages of current
    final currentPage = widget.currentPage;
    final thisPage = widget.pageNumber;
    return (thisPage - currentPage).abs() <= 3;
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Must call when using AutomaticKeepAliveClientMixin
    
    return ExtendedImage(...);
  }
}
```

### Unit Tests - webtoon_detector_test.dart (NEW FILE)

```dart
// test/core/utils/webtoon_detector_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/webtoon_detector.dart';

void main() {
  group('WebtoonDetector', () {
    test('detects normal manga as NOT webtoon', () {
      // Verified from actual project: 902×1280px, AR=1.42
      final normalSize = Size(902, 1280);
      expect(WebtoonDetector.isWebtoon(normalSize), false);
    });
    
    test('detects actual webtoon image', () {
      // Verified from actual project: 1275×16383px, AR=12.85
      final webtoonSize = Size(1275, 16383);
      expect(WebtoonDetector.isWebtoon(webtoonSize), true);
    });
    
    test('handles edge case at threshold', () {
      // Exactly at threshold: AR = 2.5
      final edgeSize = Size(1000, 2500);
      expect(WebtoonDetector.isWebtoon(edgeSize), false); // Should be false (not greater)
    });
    
    test('detects image just above threshold', () {
      // Just above threshold: AR = 2.6
      final aboveSize = Size(1000, 2600);
      expect(WebtoonDetector.isWebtoon(aboveSize), true);
    });
    
    test('handles zero width safely', () {
      final invalidSize = Size(0, 1000);
      expect(WebtoonDetector.isWebtoon(invalidSize), false); // No crash
    });
    
    test('recommends fitWidth for webtoon', () {
      final webtoonSize = Size(1275, 16383);
      final boxFit = WebtoonDetector.getRecommendedBoxFit(
        webtoonSize,
        ReadingMode.continuousScroll,
      );
      expect(boxFit, BoxFit.fitWidth);
    });
    
    test('recommends contain for normal in singlePage mode', () {
      final normalSize = Size(902, 1280);
      final boxFit = WebtoonDetector.getRecommendedBoxFit(
        normalSize,
        ReadingMode.singlePage,
      );
      expect(boxFit, BoxFit.contain);
    });
  });
}
```

---

## 🎨 Enhanced UI Components

### content_actions_sheet.dart (NEW FILE)

```dart
import 'package:flutter/material.dart';

class ContentActionsSheet extends StatelessWidget {
  const ContentActionsSheet({
    super.key,
    required this.content,
    required this.actions,
  });

  final Content content;
  final List<ContentAction> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content.title,
              style: TextStyleConst.headlineSmall.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Divider(height: 24),
          
          // Actions list
          ...actions.map((action) => ListTile(
            leading: Icon(action.icon, color: action.color ?? colorScheme.primary),
            title: Text(action.label, style: TextStyleConst.bodyLarge),
            subtitle: action.subtitle != null 
                ? Text(action.subtitle!, style: TextStyleConst.bodySmall)
                : null,
            onTap: () {
              Navigator.pop(context);
              action.onTap();
            },
          )),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ContentAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  ContentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });
}
```

---

**Last Updated:** 2025-11-27  
**Purpose:** Quick reference for implementation  
**Usage:** Copy-paste snippets as needed during development
