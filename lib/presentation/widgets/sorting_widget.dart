import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/domain/entities/entities.dart';

/// Modern sorting widget for MainScreen
class SortingWidget extends StatelessWidget {
  const SortingWidget({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.isCompact = false,
  });

  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactSorting();
    } else {
      return _buildFullSorting();
    }
  }

  /// Build compact sorting for smaller spaces
  Widget _buildCompactSorting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorsConst.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorsConst.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort,
            size: 16,
            color: ColorsConst.darkTextSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            currentSort.displayName,
            style: TextStyleConst.bodySmall.copyWith(
              color: ColorsConst.darkTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: ColorsConst.darkTextSecondary,
          ),
        ],
      ),
    );
  }

  /// Build full sorting with all options visible
  Widget _buildFullSorting() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkSurface,
        border: const Border(
          bottom: BorderSide(
            color: ColorsConst.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorsConst.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.sort,
                  color: ColorsConst.accentBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sort by',
                style: TextStyleConst.headingSmall.copyWith(
                  color: ColorsConst.darkTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SortOption.values.map((sort) {
                final isSelected = currentSort == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(sort.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onSortChanged(sort);
                      }
                    },
                    backgroundColor: ColorsConst.darkCard,
                    selectedColor:
                        ColorsConst.accentBlue.withValues(alpha: 0.2),
                    labelStyle: TextStyleConst.bodySmall.copyWith(
                      color: isSelected
                          ? ColorsConst.accentBlue
                          : ColorsConst.darkTextSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? ColorsConst.accentBlue
                          : ColorsConst.borderDefault,
                      width: isSelected ? 2 : 1,
                    ),
                    elevation: isSelected ? 2 : 0,
                    pressElevation: 4,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown version of sorting widget for compact spaces
class SortingDropdown extends StatelessWidget {
  const SortingDropdown({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: currentSort,
      onSelected: onSortChanged,
      color: ColorsConst.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ColorsConst.borderDefault),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColorsConst.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorsConst.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 16,
              color: ColorsConst.darkTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              currentSort.displayName,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: ColorsConst.darkTextSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => SortOption.values.map((sort) {
        final isSelected = currentSort == sort;
        return PopupMenuItem<SortOption>(
          value: sort,
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: ColorsConst.accentBlue,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sort.displayName,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: isSelected
                        ? ColorsConst.accentBlue
                        : ColorsConst.darkTextPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
