---
description: Start feature implementation - Phase 3 of workflow
subtask: true
return:
  - Check the progress. Update the progress document with completed tasks.
  - Continue with the next task until all tasks are complete.
  - When done, run /asix-complete-feature to finalize.
---
# Start Feature Implementation

You are starting the **Execution Phase** for a feature in NhasixApp.

## Feature to Implement
> $ARGUMENTS

## Your Task

1. **Read the plan document** from `projects/future-plan/$ARGUMENTS/`

2. **Create progress document** at `projects/onprogress-plan/$ARGUMENTS/`
   - Create `[feature-name]-progress.md`
   - Copy tasks from plan

3. **Create TODO list** using the todowrite tool

4. **Start implementing** following the plan:
   - Work on one task at a time
   - Update progress document as you complete tasks
   - Follow Clean Architecture strictly
   - Use proper naming conventions

## Implementation Guidelines

### File Structure
```
lib/features/[feature-name]/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Code Standards
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Use `logger` package (no print!)
- Cubit extends `BaseCubit`
- Models implement `.fromEntity()`, `.toEntity()`, `.fromMap()`

### After Each Task
Update the progress document:
```markdown
## Completed Tasks ✅
- [x] Task 1 - Description
  - Files: `path/to/file.dart`
```

Load skills: `skill({ name: "flutter-dev" })`, `skill({ name: "bloc-cubit" })`
