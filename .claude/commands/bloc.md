# Create BLoC

Scaffold a new BLoC component with Freezed states and events.

## Usage
`/bloc [name] [feature_path]`

Example: `/bloc login lib/presentation/auth`

## Files to Create

### 1. State File (`[path]/bloc/[name]_state.dart`)
```dart
part of '[name]_bloc.dart';

@freezed
class [Name]State with _$[Name]State {
  const factory [Name]State.initial() = _Initial;
  const factory [Name]State.loading() = _Loading;
  const factory [Name]State.success() = _Success;
  const factory [Name]State.failure(String message) = _Failure;
}
```

### 2. Event File (`[path]/bloc/[name]_event.dart`)
```dart
part of '[name]_bloc.dart';

@freezed
class [Name]Event with _$[Name]Event {
  const factory [Name]Event.started() = _Started;
}
```

### 3. BLoC File (`[path]/bloc/[name]_bloc.dart`)
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_event.dart';
part '[name]_state.dart';
part '[name]_bloc.freezed.dart';

class [Name]Bloc extends Bloc<[Name]Event, [Name]State> {
  [Name]Bloc() : super(const _Initial()) {
    on<_Started>((event, emit) {
      // TODO: implement event handler
    });
  }
}
```

### 4. Run Codegen
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## For Cubit (simple state)

If the feature is simple, create a Cubit instead:

### State File (`[path]/cubit/[name]_state.dart`)
```dart
part of '[name]_cubit.dart';

@freezed
class [Name]State with _$[Name]State {
  const factory [Name]State.initial() = _Initial;
  const factory [Name]State.loading() = _Loading;
  const factory [Name]State.loaded(DataType data) = _Loaded;
  const factory [Name]State.error(String message) = _Error;
}
```

### Cubit File (`[path]/cubit/[name]_cubit.dart`)
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nhasixapp/core/base/base_cubit.dart';

part '[name]_state.dart';
part '[name]_cubit.freezed.dart';

class [Name]Cubit extends BaseCubit<[Name]State> {
  [Name]Cubit() : super(const [Name]State.initial());
}
```

## Decision: BLoC vs Cubit

| Use BLoC when | Use Cubit when |
|---------------|----------------|
| Complex state with multiple events | Simple state changes |
| Event transformations (debounce/throttle) | Few actions/methods |
| Complex async workflows | Direct state mutations |
| Multiple event types | Simple async operations |
