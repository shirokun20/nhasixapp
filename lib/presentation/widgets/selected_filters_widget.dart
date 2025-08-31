import 'package:flutter/material.dart';

import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';

/// Horizontal scrollable widget for displaying selected filters
class SelectedFiltersWidget extends StatelessWidget {
  const SelectedFiltersWidget({
    super.key,
    required this.selectedFilters,
    required this.onRemove,
    this.height = 60,
  });

  final List<FilterItem> selectedFilters;
  final ValueChanged<String> onRemove;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (selectedFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: selectedFilters.length,
        itemBuilder: (context, index) {
          final filter = selectedFilters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectedFilterChip(
              filterItem: filter,
              onRemove: () => onRemove(filter.value),
            ),
          );
        },
      ),
    );
  }
}

/// Individual chip for selected filter item
class SelectedFilterChip extends StatelessWidget {
  const SelectedFilterChip({
    super.key,
    required this.filterItem,
    required this.onRemove,
  });

  final FilterItem filterItem;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getChipColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prefix icon
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                filterItem.isExcluded ? Icons.remove : Icons.add,
                size: 16,
                color: _getIconColor(context),
              ),
            ),

            // Filter text
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Text(
                  filterItem.value,
                  style: TextStyleConst.label.copyWith(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _getRemoveButtonColor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: _getRemoveIconColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.1);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }

  Color _getBorderColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.3);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
  }

  Color _getIconColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _getTextColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _getRemoveButtonColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.2);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
  }

  Color _getRemoveIconColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }
}

/// Compact version for smaller spaces
class SelectedFiltersWidgetCompact extends StatelessWidget {
  const SelectedFiltersWidgetCompact({
    super.key,
    required this.selectedFilters,
    required this.onRemove,
    this.maxVisible = 3,
  });

  final List<FilterItem> selectedFilters;
  final ValueChanged<String> onRemove;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (selectedFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleFilters = selectedFilters.take(maxVisible).toList();
    final remainingCount = selectedFilters.length - maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...visibleFilters.map((filter) => SelectedFilterChipCompact(
              filterItem: filter,
              onRemove: () => onRemove(filter.value),
            )),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+$remainingCount more',
              style: TextStyleConst.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact chip for selected filter item
class SelectedFilterChipCompact extends StatelessWidget {
  const SelectedFilterChipCompact({
    super.key,
    required this.filterItem,
    required this.onRemove,
  });

  final FilterItem filterItem;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getChipColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prefix icon
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                filterItem.isExcluded ? Icons.remove : Icons.add,
                size: 12,
                color: _getIconColor(context),
              ),
            ),

            // Filter text
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                child: Text(
                  filterItem.value,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: _getIconColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.1);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }

  Color _getBorderColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.3);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
  }

  Color _getIconColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _getTextColor(BuildContext context) {
    if (filterItem.isExcluded) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }
}
