import 'package:equatable/equatable.dart';

class DynamicOption extends Equatable {
  const DynamicOption({
    required this.value,
    required this.label,
    this.group,
  });

  final String value;
  final String label;
  final String? group;

  @override
  List<Object?> get props => [value, label, group];
}
