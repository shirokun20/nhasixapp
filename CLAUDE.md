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

## 🔍 Search & Audit Tools (Modern — replaces grep)

All installed via Homebrew. **NEVER use basic `grep`** — use these instead:

| Tool | Best For | Command |
|---|---|---|
| **`rg`** (ripgrep) | Fast text + regex + PCRE2 | `rg "pattern" lib/ -t dart` |
| **`ugrep`** | Fast search, fuzzy/approx | `ugrep "pattern" -R lib/ -g "*.dart"` |
| **`semgrep`** | AST-aware Dart patterns, security | `semgrep --lang dart -e 'Logger().i(...)' lib/` |
| **`gitleaks`** | Secret scanning (API keys, tokens) | `gitleaks detect --source . --no-git` |
| **`typos-cli`** | Spell check source code | `typos lib/` |

### rg Advanced Patterns (PCRE2)

| Pattern | Purpose |
|---------|---------|
| `rg -U "Future.*\n\s+Future" lib/ -t dart` | Multiline — match across lines |
| `rg -P '(\w+)(?=\s*\()' file -o \| sort \| uniq -c \| sort -rn` | Function call frequency |
| `rg -P '"(?:[^"\\]|\\.)*"' file` | Match string literals |
| `rg -P '(?<!await\s)(?!Future|Stream)\w+Async\b' lib/ -t dart` | Find un-`await`ed `*Async` calls |
| `rg -P 'catch\s*\([^)]+\)\s*\{[^}]*\}' lib/ -t dart` | Find empty catch blocks |

### semgrep Real Patterns

| Pattern | Finds |
|---------|-------|
| `semgrep --lang dart -e 'print(...)' lib/` | `print()` violations |
| `semgrep --lang dart -e 'Logger().i(...)' lib/` | Bare `Logger()` instantiation |
| `semgrep --lang dart -e 'try {...} catch (\$E) {...}' lib/` | Bare catch (no type) |
| `semgrep --lang dart -e 'Future.delayed(...)' lib/` | All delayed/async calls |

### gitleaks Secrets

Run after staging but **before commit**:
```bash
gitleaks detect --source . --no-git
```

Untuk false positive management, buat `.gitleaks.toml`:
```toml
[allowlist]
paths = [
  "test/fixtures/",
  "*.arb",
]
```

### typos-cli

```bash
typos lib/                    # Find typos
typos --diff lib/             # Show fixes without applying
typos lib/ --write-changes    # Auto-fix
```
**Note**: Indonesian/localization files produce false positives (`lokal` → `local`, `Analisis` → `Analysis`). Add exception:
```bash
typos lib/ --exclude "*.arb"
```

> **`ugrep`**: `-Q` = query/prompt mode (not TUI). Correct: `-R` for recursive, `-g "*.dart"` for glob.
