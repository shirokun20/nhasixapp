import 'package:kuron_core/kuron_core.dart';
import '../base/base_cubit.dart';

class SourceState extends BaseCubitState {
  const SourceState({
    this.availableSources = const [],
    this.activeSource,
  });

  final List<ContentSource> availableSources;
  final ContentSource? activeSource;

  @override
  List<Object?> get props => [availableSources, activeSource];

  SourceState copyWith({
    List<ContentSource>? availableSources,
    ContentSource? activeSource,
  }) {
    return SourceState(
      availableSources: availableSources ?? this.availableSources,
      activeSource: activeSource ?? this.activeSource,
    );
  }
}
