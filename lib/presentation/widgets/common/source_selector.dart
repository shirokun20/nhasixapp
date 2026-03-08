import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/config/source_loader.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/cubits/source/source_cubit.dart';
import 'package:nhasixapp/presentation/cubits/source/source_state.dart';

/// A SourceSelector widget styled to match the AppDrawerContent nav items.
/// Displays the current source and allows switching between available sources.
///
/// **Purpose**: Allows users to switch between content sources (e.g., NHentai,
/// Crotpedia). When a source is switched, the main screen refreshes with
/// content from the new source, downloads are saved in source-specific folders,
/// and search filters are reset since tags differ between sources.
class SourceSelector extends StatelessWidget {
  const SourceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<SourceCubit, SourceState>(
      builder: (context, state) {
        final sourceLoader = getIt<SourceLoader>();
        final activeId = state.activeSource?.id;
        final isActiveUnderMaintenance =
            activeId != null && sourceLoader.isUnderMaintenance(activeId);

        // Hide if only one source available (uncomment for production)
        // if (state.availableSources.length <= 1) {
        //   return const SizedBox.shrink();
        // }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showSourceMenu(context, state, colorScheme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Source Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildSourceIconWidget(
                        iconPath: state.activeSource?.iconPath,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text - matches nav item
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.activeSource?.displayName ?? 'Select Source',
                            style: TextStyleConst.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                          if (isActiveUnderMaintenance)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Under maintenance',
                                style: TextStyleConst.bodySmall.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActiveUnderMaintenance)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                      ),
                    // Dropdown indicator
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 18,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show source selection popup menu with proper sizing
  void _showSourceMenu(
    BuildContext context,
    SourceState state,
    ColorScheme colorScheme,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height + 4,
        position.dx + button.size.width,
        position.dy + button.size.height + 300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: colorScheme.surfaceContainer,
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: button.size.width,
        maxWidth: button.size.width,
      ),
      items: state.availableSources.map((source) {
        final sourceLoader = getIt<SourceLoader>();
        final isActive = source.id == state.activeSource?.id;
        final isUnderMaintenance = sourceLoader.isUnderMaintenance(source.id);
        return PopupMenuItem<String>(
          enabled: !isUnderMaintenance,
          value: source.id,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildSourceIconWidget(
                  iconPath: source.iconPath,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isUnderMaintenance
                      ? '${source.displayName} (Maintenance)'
                      : source.displayName,
                  style: TextStyleConst.bodyMedium.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isUnderMaintenance
                        ? colorScheme.error
                        : (isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface),
                  ),
                ),
              ),
              if (isUnderMaintenance)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                ),
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedId) {
      if (selectedId != null && context.mounted) {
        context.read<SourceCubit>().switchSource(selectedId);
      }
    });
  }

  Widget _buildSourceIconWidget({
    required String? iconPath,
    required Color color,
  }) {
    if (iconPath == null || iconPath.isEmpty) {
      return Icon(
        Icons.dns_rounded,
        size: 20,
        color: color,
      );
    }

    final iconUri = Uri.tryParse(iconPath);
    final isRemote = iconUri != null &&
        (iconUri.scheme == 'http' || iconUri.scheme == 'https');

    if (isRemote) {
      return Image.network(
        iconPath,
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.dns_rounded,
            size: 20,
            color: color,
          );
        },
      );
    }

    return Image.asset(
      iconPath,
      width: 20,
      height: 20,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.dns_rounded,
          size: 20,
          color: color,
        );
      },
    );
  }
}
