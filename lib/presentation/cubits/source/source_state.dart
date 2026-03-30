import 'package:kuron_core/kuron_core.dart';
import '../base/base_cubit.dart';

class SourceState extends BaseCubitState {
  const SourceState({
    this.availableSources = const [],
    this.activeSource,
    this.isSwitching = false,
  });

  final List<ContentSource> availableSources;
  final ContentSource? activeSource;

  /// True while a source switch is in progress (triggers loading UI).
  final bool isSwitching;

  @override
  List<Object?> get props => [availableSources, activeSource, isSwitching];

  SourceState copyWith({
    List<ContentSource>? availableSources,
    ContentSource? activeSource,
    bool? isSwitching,
  }) {
    return SourceState(
      availableSources: availableSources ?? this.availableSources,
      activeSource: activeSource ?? this.activeSource,
      isSwitching: isSwitching ?? this.isSwitching,
    );
  }
}
