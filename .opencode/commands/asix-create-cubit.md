---
description: Create a new Cubit with proper structure
subtask: true
return:
  - Register the Cubit in dependency injection.
  - Show example usage in a widget.
---
# Create Cubit

Create a new Cubit following NhasixApp conventions.

## Cubit Name
> $ARGUMENTS

## Generated Files

1. **State file**: `[name]_state.dart`
2. **Cubit file**: `[name]_cubit.dart`

## State Template (using freezed)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_state.freezed.dart';

@freezed
class [Name]State with _$[Name]State {
  const factory [Name]State.initial() = _Initial;
  const factory [Name]State.loading() = _Loading;
  const factory [Name]State.loaded(/* data */) = _Loaded;
  const factory [Name]State.error(String message) = _Error;
}
```

## Cubit Template

```dart
import 'package:nhasixapp/core/base/base_cubit.dart';
import '[name]_state.dart';

class [Name]Cubit extends BaseCubit<[Name]State> {
  final [UseCase] _useCase;
  
  [Name]Cubit(this._useCase) : super(const [Name]State.initial());
  
  Future<void> load() async {
    emit(const [Name]State.loading());
    
    final result = await _useCase();
    
    result.fold(
      (failure) => emit([Name]State.error(failure.message)),
      (data) => emit([Name]State.loaded(data)),
    );
  }
}
```

## DI Registration

```dart
// In core/di/injection_container.dart
sl.registerFactory(() => [Name]Cubit(sl()));
```

Load skill: `skill({ name: "bloc-cubit" })`
