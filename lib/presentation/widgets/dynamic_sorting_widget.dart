import 'package:flutter/material.dart';
import '../../core/config/config_models.dart';

/// A dynamic sorting widget that adapts based on [SortingConfig].
///
/// Supports:
/// - [SortWidgetType.dropdown]: Interactive dropdown for immediate re-sorting (nhentai style)
/// - [SortWidgetType.readonly]: Read-only display of current sort (crotpedia style)
/// - [SortWidgetType.chips]: Interactive chips (alternative style)
class DynamicSortingWidget extends StatelessWidget {
  final String currentSortValue;
  final SortingConfig config;
  final Function(String)? onSortChanged;
  final VoidCallback? onNavigateToSearch;

  const DynamicSortingWidget({
    super.key,
    required this.currentSortValue,
    required this.config,
    this.onSortChanged,
    this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (config.options.isEmpty) return const SizedBox.shrink();

    switch (config.widgetType) {
      case SortWidgetType.dropdown:
        return _buildDropdown(context);
      case SortWidgetType.readonly:
        return _buildReadonly(context);
      case SortWidgetType.chips:
        return _buildChips(context);
    }
  }

  Widget _buildDropdown(BuildContext context) {
    final currentOption = config.options.firstWhere(
      (opt) => opt.value == currentSortValue,
      orElse: () => config.options
          .firstWhere((o) => o.isDefault, orElse: () => config.options.first),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentOption.value,
          isDense: true,
          icon:
              Icon(Icons.sort, size: 20, color: Theme.of(context).primaryColor),
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (newValue) {
            if (newValue != null && newValue != currentSortValue) {
              onSortChanged?.call(newValue);
            }
          },
          items: config.options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    Icon(_getIconData(option.icon!), size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(option.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReadonly(BuildContext context) {
    final currentOption = config.options.firstWhere(
      (opt) => opt.value == currentSortValue,
      orElse: () => config.options
          .firstWhere((o) => o.isDefault, orElse: () => config.options.first),
    );

    return InkWell(
      onTap: onNavigateToSearch,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config.messages.readOnlyPrefix != null)
              Text(
                config.messages.readOnlyPrefix!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(width: 4),
            Text(
              currentOption.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (config.messages.readOnlySuffix != null) ...[
              const SizedBox(width: 4),
              Text(config.messages.readOnlySuffix!),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: config.options.map((option) {
          final isSelected = option.value == currentSortValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSortChanged?.call(option.value);
              },
              avatar: option.icon != null
                  ? Icon(_getIconData(option.icon!), size: 16)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'update':
        return Icons.update;
      case 'trending_up':
        return Icons.trending_up;
      case 'date_range':
        return Icons.date_range;
      case 'today':
        return Icons.today;
      case 'new_releases':
        return Icons.new_releases;
      case 'star':
        return Icons.star;
      case 'sort_by_alpha':
        return Icons.sort_by_alpha;
      default:
        return Icons.sort;
    }
  }
}
