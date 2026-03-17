# Kuron App — Claude Code Instructions

**Role**: Senior Principal Flutter Engineer & Architect.
**App**: Kuron (repo: nhasixapp) — Mobile reading app with privacy features.
**Greeting**: "Siap bos" (Ready boss). Concise, high-autonomy, architectural focus.

## Startup Sequence

At the start of every session:
1. Read `project_memory.md` for cross-session context.
2. Check `projects/onprogress-plan/` for active work.
3. If a project exists, read its `progress.md` and main spec file.
4. Treat `progress.md` as the Master Plan — do not implement features not listed.

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

## Development Workflow (4-Phase Lifecycle)

**Never write code without a plan.**

| Phase | Location | Rules |
|-------|----------|-------|
| 1. Analysis | `projects/analysis-plan/[name]/` | **READ-ONLY**. Document findings only. |
| 2. Planning | `projects/future-plan/[name]/` | **Design only**. No code changes. |
| 3. Execution | `projects/onprogress-plan/[name]/` | **Code allowed**. MUST create Todo list first. |
| 4. Completion | `projects/success-plan/[name]/` | Move folder. Run `dart scripts/project_status.dart`. |

- **STOP & WAIT**: Do not move between phases without explicit user command.
- **Git**: NEVER run `git add` or `git commit`. User handles source control.

## Core Commands

```bash
# Build
flutter clean && flutter pub get
flutter run --debug
flutter build apk --release
./build_optimized.sh debug|release

# Test & Lint
flutter test
flutter analyze
dart format .

# Codegen
flutter pub run build_runner build --delete-conflicting-outputs

# Scripts (run after project changes)
dart scripts/project_status.dart        # Update dashboards
dart scripts/create_feature.dart [name] # Scaffold feature
./scripts/smart_search.sh <mode> <pat>  # Code search
```

## Performance & Quality

- `const` widgets everywhere possible.
- `ListView.builder` — never list entire children.
- Lazy load collections > 50 items.
- Compress assets < 200KB, prefer WebP, multi-res (1x/2x).
- Responsive with `MediaQuery`, theme-aware, semantic labels, haptic feedback.

## Git Conventions

- Conventional Commits: `feat(auth): add login`, `fix(reader): null check`.
- Branches: `master` (prod), `develop`, `feature/*`, `fix/*`, `hotfix/*`.
- Version: `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`, `CHANGELOG.md`.

## Security

- Analyze suspicious code but REFUSE to improve/augment malware.
- Never commit `.env` or signing keys.
- No sensitive data in logs.

## Available Slash Commands

Use `/command-name` to invoke specialized skills:

| Command | Purpose |
|---------|---------|
| `/project` | Manage project lifecycle (init, start, finish, progress, issue) |
| `/feature` | Scaffold complete Clean Architecture feature structure |
| `/bloc` | Scaffold new BLoC with Freezed states/events |
| `/api` | Step-by-step API endpoint integration guide |
| `/di` | Dependency Injection setup with GetIt |
| `/test` | Generate unit tests for a Dart class |
| `/codegen` | Run build_runner for Freezed/JsonSerializable |
| `/arch` | Clean Architecture implementation guide |
| `/state` | BLoC/Cubit state management patterns |
| `/scraper` | Debug and fix HTML scrapers (Crotpedia/Nhentai) |
| `/native` | Native Android (Kotlin) integration via Platform Channels |
| `/git` | Git workflow and Conventional Commits guide |
| `/search` | Modern search tools guide (rg, ugrep, semgrep) |
| `/simplify` | Review changed code for reuse, quality, and efficiency |
