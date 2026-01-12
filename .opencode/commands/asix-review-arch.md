---
description: Review architecture and Clean Architecture compliance
subtask: true
---
# Architecture Review

Review Clean Architecture compliance for the specified code.

## Target
> $ARGUMENTS

## Check List

### Domain Layer
- [ ] Entities are pure Dart (no Flutter imports)
- [ ] Repository interfaces are abstract
- [ ] Use cases have single responsibility
- [ ] No dependencies on data/presentation layers

### Data Layer
- [ ] Models extend entities
- [ ] Models have `.fromEntity()`, `.toEntity()`, `.fromMap()`
- [ ] Data sources properly abstracted
- [ ] Repository implementations use Either for error handling

### Presentation Layer
- [ ] BLoC/Cubit doesn't contain business logic
- [ ] States are immutable
- [ ] No direct data layer access

### Dependency Injection
- [ ] All dependencies registered in `core/di/`
- [ ] Proper lifecycle (Factory vs LazySingleton)

## Report violations with:
- File path and line number
- What's wrong
- How to fix it
