---
name: create-bloc
description: Scaffolds a new Bloc component with Freezed and Injectable.
---

# Create Bloc Skill

Generates a robust Bloc structure following the project's Clean Architecture standards.

## Usage
`/create-bloc [name] [feature_path]`

**Example**: `/create-bloc login lib/presentation/auth`

## Actions

1. **Create State File** (`[path]/bloc/[name]_state.dart`)
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

2. **Create Event File** (`[path]/bloc/[name]_event.dart`)
   ```dart
   part of '[name]_bloc.dart';

   @freezed
   class [Name]Event with _$[Name]Event {
     const factory [Name]Event.started() = _Started;
   }
   ```

3. **Create Bloc File** (`[path]/bloc/[name]_bloc.dart`)
   ```dart
   import 'package:flutter_bloc/flutter_bloc.dart';
   import 'package:freezed_annotation/freezed_annotation.dart';
   import 'package:injectable/injectable.dart';

   part '[name]_event.dart';
   part '[name]_state.dart';
   part '[name]_bloc.freezed.dart';

   @injectable
   class [Name]Bloc extends Bloc<[Name]Event, [Name]State> {
     [Name]Bloc() : super(const _Initial()) {
       on<_Started>((event, emit) {
         // TODO: implement event handler
       });
     }
   }
   ```

4. **Instructions**
   - Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate the freezed code.
