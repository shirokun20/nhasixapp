import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';

/// Modern card widget for filter items with include/exclude toggle
class FilterItemCard extends StatelessWidget {
  const FilterItemCard({
    super.key,
    required this.tag,
    required this.isIncluded,
    required this.isExcluded,
    required this.onTap,
    required this.onInclude,
    required this.onExclude,
  });

  final Tag tag;
  final bool isIncluded;
  final bool isExcluded;
  final VoidCallback onTap;
  final VoidCallback onInclude;
  final VoidCallback onExclude;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _getCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tag info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Tag type indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagTypeColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            TagType.getDisplayName(tag.type),
                            style: TextStyleConst.label.copyWith(
                              color: _getTagTypeColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Popularity indicator
                        if (tag.isPopular) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Tag name
                    Text(
                      tag.name,
                      style: TextStyleConst.contentTitle.copyWith(
                        color: ColorsConst.darkTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Tag count
                    Text(
                      '${tag.count} items',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              const SizedBox(width: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (isIncluded || isExcluded) {
      // Show selected state with remove option
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isIncluded
                  ? ColorsConst.accentBlue.withValues(alpha: 0.1)
                  : ColorsConst.accentRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIncluded ? Icons.add : Icons.remove,
                  size: 16,
                  color: isIncluded
                      ? ColorsConst.accentBlue
                      : ColorsConst.accentRed,
                ),
                const SizedBox(width: 4),
                Text(
                  isIncluded ? 'Include' : 'Exclude',
                  style: TextStyleConst.label.copyWith(
                    color: isIncluded
                        ? ColorsConst.accentBlue
                        : ColorsConst.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remove button
          IconButton(
            onPressed: onTap, // Tap to remove/toggle
            icon: Icon(
              Icons.close,
              size: 20,
              color: ColorsConst.darkTextSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ColorsConst.darkCard,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      );
    } else {
      // Show include/exclude options
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Include button
          IconButton(
            onPressed: onInclude,
            icon: Icon(
              Icons.add,
              size: 20,
              color: ColorsConst.accentBlue,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ColorsConst.accentBlue.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
          const SizedBox(width: 8),
          // Exclude button
          IconButton(
            onPressed: onExclude,
            icon: Icon(
              Icons.remove,
              size: 20,
              color: ColorsConst.accentRed,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ColorsConst.accentRed.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      );
    }
  }

  Color _getCardColor() {
    if (isIncluded) {
      return ColorsConst.accentBlue.withValues(alpha: 0.05);
    } else if (isExcluded) {
      return ColorsConst.accentRed.withValues(alpha: 0.05);
    }
    return ColorsConst.darkSurface;
  }

  Color _getBorderColor() {
    if (isIncluded) {
      return ColorsConst.accentBlue;
    } else if (isExcluded) {
      return ColorsConst.accentRed;
    }
    return ColorsConst.borderDefault;
  }

  double _getBorderWidth() {
    return (isIncluded || isExcluded) ? 2 : 1;
  }

  Color _getTagTypeColor() {
    switch (tag.type.toLowerCase()) {
      case 'artist':
        return const Color(0xFFFF6B6B); // Red
      case 'character':
        return const Color(0xFF4ECDC4); // Teal
      case 'parody':
        return const Color(0xFF45B7D1); // Blue
      case 'group':
        return const Color(0xFF96CEB4); // Green
      case 'language':
        return const Color(0xFFFFA726); // Orange
      case 'category':
        return const Color(0xFFBA68C8); // Purple
      default:
        return ColorsConst.accentBlue; // Default blue
    }
  }
}

/// Compact version of filter item card for smaller spaces
class FilterItemCardCompact extends StatelessWidget {
  const FilterItemCardCompact({
    super.key,
    required this.tag,
    required this.isIncluded,
    required this.isExcluded,
    required this.onTap,
    required this.onInclude,
    required this.onExclude,
  });

  final Tag tag;
  final bool isIncluded;
  final bool isExcluded;
  final VoidCallback onTap;
  final VoidCallback onInclude;
  final VoidCallback onExclude;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _getCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Tag info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: ColorsConst.darkTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tag.count}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              const SizedBox(width: 8),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isIncluded || isExcluded) {
      return Icon(
        isIncluded ? Icons.add_circle : Icons.remove_circle,
        color: isIncluded ? ColorsConst.accentBlue : ColorsConst.accentRed,
        size: 24,
      );
    } else {
      return Icon(
        Icons.add_circle_outline,
        color: ColorsConst.darkTextSecondary,
        size: 24,
      );
    }
  }

  Color _getCardColor() {
    if (isIncluded) {
      return ColorsConst.accentBlue.withValues(alpha: 0.05);
    } else if (isExcluded) {
      return ColorsConst.accentRed.withValues(alpha: 0.05);
    }
    return ColorsConst.darkSurface;
  }

  Color _getBorderColor() {
    if (isIncluded) {
      return ColorsConst.accentBlue;
    } else if (isExcluded) {
      return ColorsConst.accentRed;
    }
    return ColorsConst.borderDefault;
  }

  double _getBorderWidth() {
    return (isIncluded || isExcluded) ? 2 : 1;
  }
}
