# Kuron App — Claude Code Instructions

**Role**: Senior Principal Flutter Engineer & Architect.
**App**: Kuron (repo: nhasixapp) — Mobile reading app with privacy features.
**Greeting**: "Siap bos" (Ready boss). Concise, high-autonomy, architectural focus.

## Startup Sequence

At the start of every session:
1. Read `MEMORY.md` for cross-session context.
2. Check `openspec/changes/` for active (non-archived) changes.
3. If an active change exists, read its `proposal.md` and `tasks.md`.
4. Treat `tasks.md` as the Master Plan — do not implement features not listed.

## Architecture (STRICT)

**Clean Architecture**: `Domain` (Pure Dart) <- `Data` (Impl/API) <- `Presentation` (Flutter).

```
lib/
├── domain/          # Entities, Repository interfaces, UseCases (NO Flutter, NO JSON)
├── data/            # Models, DataSources, Repository implementations
├── presentation/    # BLoC/Cubit, Pages, Widgets
└── core/
    └── di/          # GetIt dependency injection (service_locator.dart)
```

- UI never talks to Data directly. Flow: UI -> Cubit -> UseCase -> Repository.
- DI: `get_it` via `core/di/service_locator.dart`. Manual registration (no injectable codegen).
- Repository returns `DataState<T>` (DataSuccess/DataFailed) from `kuron_core`.

## State Management

- `flutter_bloc` for complex logic, `Cubit` for simple state.
- All Cubits MUST extend `BaseCubit`.
- Use `freezed` for states and events. Run codegen after changes.

## Coding Conventions

| Rule | Convention |
|------|-----------|
| Files | `snake_case` |
| Classes | `PascalCase` |
| Variables | `camelCase` |
| Logging | `logger` package (`.t` to `.f`). **NEVER** `print`/`debugPrint` |
| Models | Extend entities. Implement `.fromEntity()`, `.toEntity()`, `.fromMap()` |
| Imports | Dart SDK -> Flutter -> External packages -> Project imports |

## Protected Files — NEVER edit

- `*.g.dart` — build_runner generated
- `*.freezed.dart` — Freezed generated
- Edit the source file and run codegen instead.

## Freezed & Code Generation

ALL new models, states, and events MUST use Freezed + JsonSerializable.
After creating/editing annotated files, run immediately:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Exceptions** (do NOT use Freezed):
- `kuron_core` package — pure Dart, use `equatable` + manual `copyWith`.
- `sealed class` hierarchies for exhaustive pattern matching.
- Pure logic/service classes (no serialization needed).

## Git Conventions

- Conventional Commits: `feat(auth): add login`, `fix(reader): null check`.
- Branches: `master` (prod), `develop`, `feature/*`, `fix/*`, `hotfix/*`.
- **Never** run `git add` or `git commit`. User handles source control.