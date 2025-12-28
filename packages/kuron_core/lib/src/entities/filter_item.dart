import 'package:equatable/equatable.dart';

/// A filter item used in search filters.
class FilterItem extends Equatable {
  const FilterItem({
    required this.id,
    required this.name,
    required this.type,
    this.count = 0,
    this.isExcluded = false,
  });

  /// Filter item ID
  final int id;

  /// Filter item name
  final String name;

  /// Filter type (tag, artist, character, etc.)
  final String type;

  /// Usage count
  final int count;

  /// Whether this filter is an exclusion
  final bool isExcluded;

  @override
  List<Object?> get props => [id, name, type, count, isExcluded];

  FilterItem copyWith({
    int? id,
    String? name,
    String? type,
    int? count,
    bool? isExcluded,
  }) {
    return FilterItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      count: count ?? this.count,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }

  /// Toggle exclusion status
  FilterItem toggleExclusion() => copyWith(isExcluded: !isExcluded);

  /// Get display string
  String get displayName => isExcluded ? '-$name' : name;
}
