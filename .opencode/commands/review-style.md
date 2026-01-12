---
description: Review code style and conventions
subtask: true
---
# Style Review

Review code style and conventions for NhasixApp.

## Target
> $ARGUMENTS

## Check List

### Naming
- [ ] Files use `snake_case.dart`
- [ ] Classes use `PascalCase`
- [ ] Variables use `camelCase`
- [ ] Constants use `camelCase` or `SCREAMING_SNAKE_CASE`

### Logging
- [ ] No `print()` statements
- [ ] No `debugPrint()` statements
- [ ] Uses `logger` package with proper levels

### Imports
- [ ] Dart SDK imports first
- [ ] Flutter imports second
- [ ] Package imports third
- [ ] Project imports last

### Widgets
- [ ] Uses `const` constructors where possible
- [ ] ListView uses `.builder` (not children list)
- [ ] Proper widget decomposition

### State Management
- [ ] Cubit extends `BaseCubit`
- [ ] States are immutable (freezed/sealed)
- [ ] Proper error states handled

## Report violations with file path and fix suggestion.
