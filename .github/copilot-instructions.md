# NhasixApp — GitHub Copilot Instructions

## Project Context
NhasixApp (Kuron) is a Flutter Android application built with **Clean Architecture**.
Read `project_memory.md` in root for full context.

## Architecture Rules (STRICT)
- **Clean Architecture**: `Domain` → `Data` → `Presentation`
- **Domain**: Pure Dart only. Entities, UseCases, Repository interfaces. NO JSON, NO Flutter UI imports.
- **Data**: Implements Domain interfaces. JSON parsing, API calls, DB storage.
- **Presentation**: Flutter UI + BLoC/Cubit. NEVER call APIs directly. Go through UseCases.
- **DI**: `GetIt` + `Injectable` in `core/di/`. Use proper DI, never service locator anti-patterns.

## State Management
- Use `flutter_bloc` for complex logic, `Cubit` for simple state
- Always extend `BaseCubit`
- UI widgets should be stateless when possible

## Coding Conventions
- **Files**: `snake_case` (e.g., `user_repository.dart`)
- **Classes**: `PascalCase` (e.g., `UserRepository`)
- **Variables**: `camelCase` (e.g., `userName`)
- **Logging**: Use `logger` package (`.t` `.d` `.i` `.w` `.e` `.f`). NEVER use `print` or `debugPrint`.
- **Models**: Must extend entities. Implement `.fromEntity()`, `.toEntity()`, `.fromMap()`.

## Import Order
1. Dart SDK (`dart:async`)
2. Flutter (`package:flutter/material.dart`)
3. External packages
4. Project imports (relative)

## Protected Files — NEVER edit
- `*.g.dart` — build_runner generated
- `*.freezed.dart` — Freezed generated

## Performance Rules
- Always use `const` widgets where possible
- Use `ListView.builder` — never put lists as children
- Lazy load collections > 50 items
- Compress assets < 200KB, prefer WebP

## Git Conventions
- Conventional Commits: `feat(auth): add login`, `fix(reader): null check`
- Branches: `master` (prod), `develop`, `feature/*`

## Reference Files
- `project_memory.md` — Full project context and session log
- `AGENTS.md` — Agent rules and skills reference
- `projects/README.md` — Project dashboard
