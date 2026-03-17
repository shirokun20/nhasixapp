# Kuron App — Agent Rules

**Role**: Senior Principal Flutter Engineer & Architect.
**Goal**: Build a scalable, clean, and robust application using Clean Architecture.
**App**: Kuron (repo: nhasixapp) — Mobile reading app with privacy features.

## 📝 Project Memory
**CRITICAL**: Read `project_memory.md` at project root for full context. Update it after every session.

## 🤖 Codex Compatibility
**CRITICAL**: For Codex, `AGENTS.md` is the primary local instruction file.

- Reuse existing project rules instead of creating a parallel Codex-specific rule set.
- Prefer project-local Codex skills in `.codex/skills/*/SKILL.md` for this repository.
- Read `.opencode/skills/*/SKILL.md` as the primary local skill source when the task matches a listed skill.
- Use `.agent/skills/*/SKILL.md` and `.agent/rules/asix-rules.md` as secondary references when the `.opencode` version is missing or less complete.
- Treat `@planner`, `@architect`, `@flutter-architect`, `@feature-dev`, `@code-reviewer`, `@ui-designer`, `@test-engineer`, and `@test-writer` as role intentions that Codex should emulate directly unless explicit sub-agent delegation is requested.
- Keep `.github/copilot-instructions.md` aligned with this file; if guidance overlaps, follow the stricter local project rule.
- For every session, Codex must still follow the same startup sequence: `project_memory.md` -> active `projects/onprogress-plan/` -> active `progress.md` -> active main spec.

## ⚡ Core Commands
- **Build/Run**: `flutter clean && flutter pub get` | `flutter run --debug` | `flutter build apk --release`
- **Build Optimized**: `./build_optimized.sh debug` | `release`
- **Test/Lint**: `flutter test` | `flutter analyze` | `dart run build_runner build`
- **Codegen**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Format**: `dart format .`
- **Release**: `./build_release.sh` (Custom) | `flutter build ipa` (iOS)

## 📜 Development Scripts

Located in `scripts/` folder. **ALWAYS run after project changes:**

| Script | Command | When to Run |
|---|---|---|
| **Project Status** | `dart scripts/project_status.dart` | After creating issue, moving project phase, or updating progress |
| **Create Feature** | `dart scripts/create_feature.dart [name]` | Scaffold new feature structure |
| **Smart Search** | `./scripts/smart_search.sh <mode> <pattern>` | Code search, audit, violations |

**Note**: `project_status.dart` auto-updates all README dashboards with progress bars and statistics.

## 🔍 Search Tools (Modern — replaces grep)

All installed via Homebrew. **NEVER use basic `grep`** — use these instead:

| Tool | Best For | Command |
|---|---|---|
| **`rg`** (ripgrep) | Fast text search, regex | `rg "pattern" lib/ -t dart` |
| **`ugrep`** | Interactive TUI, fuzzy search | `ugrep -Q "pattern" lib/` |
| **`semgrep`** | AST-aware Dart patterns, security | `semgrep --lang dart -e '$PATTERN' lib/` |

### Smart Search Script
```bash
./scripts/smart_search.sh text "pattern"         # ripgrep
./scripts/smart_search.sh ast '$X.find()'         # semgrep
./scripts/smart_search.sh interactive "pattern"   # ugrep TUI
./scripts/smart_search.sh fuzzy "patern"           # ugrep fuzzy
./scripts/smart_search.sh audit                    # Architecture audit
./scripts/smart_search.sh debugprint                 # DebugPrint violation scan
./scripts/smart_search.sh violations               # Code standard check
```

### Quick Reference
```bash
# Find print violations
rg "(print|debugPrint)\(" lib/ -t dart

# Find all TODOs
rg "(TODO|FIXME|HACK)" lib/ -t dart

# Find unused imports
rg "import '" lib/ -t dart --stats

# AST: find direct API calls in UI (violation)
semgrep --lang dart -e 'http.get($URL)' lib/presentation/
```

## 🧠 Development Workflow (CRITICAL)

We operate with professional discipline. Code is ephemeral; Architecture is permanent.

### The Project Lifecycle
**Never write code without a plan.**

#### 🧭 Active Steering (Automatic Context)
**CRITICAL**: At the start of every session, YOU MUST:
1. Read `project_memory.md` for cross-session context.
2. Check `projects/onprogress-plan/`.
3. If a project exists there, READ its `progress.md` and main Spec file immediately.
4. **Treat `progress.md` as the Master Plan**. Do not implement features not listed there.
5. **Update `progress.md`** automatically as tasks are completed.

#### Phases:

1. **Analysis & Planning**
   - **Folder**: `projects/analysis-plan/[project_name]/`
   - **Main File**: `[project_name]_[date].md` (Copy from `projects/templates/project_plan_template.md`)
   - **Issues**: `projects/issues/` (Markdown files allowed here)
   - **Backlog**: `projects/future-plan/[project_name]/` (Follows Analysis structure)
   - **READ-ONLY**: Document findings only. No code changes.
   - **STOP & WAIT**: Do not move ANY of these to Execution without explicit user command.

2. **Execution** (`projects/onprogress-plan/`)
   - **Convert Issue to Folder**: Create folder `[project_name]`. Move issue to `resolved_issues/`.
   - **Main File**: Ensure `[project_name]_[date].md` exists.
   - **Require `progress.md`**: MUST exist for dashboard tracking (Copy Implementation Plan from Analysis).
   - **MUST** create Todo list first. Update `.md` only for completion `[x]`.
   - **Use MCP**: `Sequential Thinking`, `Context7`, `Docfork` for complex tasks.
   - **Approval**: Only move here after explicit user approval.

3. **Completion** (`projects/success-plan/`)
   - **Move Folder**: Move the entire folder here.
   - **Update**: Mark `progress.md` as 100%.
   - **Script**: Run `dart scripts/project_status.dart`.
   - **Git**: DO NOT run `git add/commit`. User handles source control.

## 🛠 Code Standards

### Architecture
- **Clean Architecture**: `Domain` (Pure Dart) ← `Data` (Impl/API) ← `Presentation` (Flutter).
- **DI**: `get_it` + `injectable` via `core/di/`.
- **Strict Layers**: UI never talks to Data. UI talks to Cubit -> UseCase -> Repository.

### Naming & Style
- **Files**: `snake_case`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`

### State Management
- **State**: `flutter_bloc` (complex) or `Cubit` (simple). Extend `BaseCubit`.

### Logging & Models
- **Logs**: Use `logger` package (`.t` to `.f`). **NO** `print`/`debugPrint`.
- **Models**: Extend entities. Implement `.fromEntity()`, `.toEntity()`, `.fromMap()`.

### Freezed & Code Generation (CRITICAL)
**ALL new Dart models, states, and events MUST use Freezed + JsonSerializable.**

Rules:
- Every new model/entity/state class → annotate with `@freezed` or `@JsonSerializable`
- After creating or editing any file with Freezed/JsonSerializable annotations → run codegen immediately:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- **NEVER** write `copyWith`, `==`, `hashCode`, `toString`, or `fromJson/toJson` by hand if Freezed can generate them.
- Use `run-codegen` skill for guided codegen execution.

**Exceptions (do NOT use Freezed):**
- `kuron_core` package — pure Dart, no Flutter/build_runner. Use `equatable` + manual `copyWith` here.
- `sealed class` hierarchies used for exhaustive pattern matching (e.g., `SourceFilter`) — native Dart sealed is more expressive than Freezed union for polymorphic `withState`.
- Pure logic/service classes (no serialization, no `copyWith` needed): e.g., `RateLimiter`, `SourceLoader`.
- Simple `ContentSource` subclasses (stateless, no serialization).

### Protected Files (CRITICAL)
**NEVER edit these files directly:**
- Files ending with `.g.dart` (generated by build_runner)
- Files ending with `.freezed.dart` (generated by Freezed)

If you need to modify generated code, edit the source file and run `flutter pub run build_runner build --delete-conflicting-outputs`.

### Auto-Formatting
All `.dart` files are automatically formatted using `fvm dart format` after write/edit operations.

## 🛠 Skills & Agents

Use these specialized tools to maintain velocity and quality.

### Agents (Use `@` to invoke)
- **`@planner`**: Creates detailed architectural plans in `projects/analysis-plan`.
- **`@architect`**: Reviews code for Clean Architecture violations.
- **`@flutter-architect`**: Clean Architecture guidance and reviews.
- **`@feature-dev`**: Development workflow coordinator.
- **`@code-reviewer`**: Flutter code quality reviews.
- **`@ui-designer`**: UI/UX and responsive design guidance.
- **`@test-engineer`**: Writes comprehensive unit and widget tests.
- **`@test-writer`**: Writes comprehensive test coverage.

### Skills (Loaded automatically when needed)
- **`clean-arch`**: Clean Architecture implementation patterns.
- **`bloc-pattern`**: BLoC/Cubit state management patterns (Freezed + Injectable).
- **`create-bloc`**: Scaffolds a new Bloc component with Freezed and Injectable.
- **`create-feature`**: Scaffolds complete Clean Architecture feature structure.
- **`di-setup`**: Dependency Injection with GetIt setup.
- **`run-codegen`**: Run Flutter build_runner to regenerate code.
- **`project-management`**: Manage project lifecycle (init, start, finish, progress, issue).
- **`gen-test`**: Generate unit tests for Dart classes.
- **`search-tools`**: Modern search tools guide (rg, ugrep, semgrep).

### Skill Source of Truth
- Project-local Codex skills: `.codex/skills/[skill]/SKILL.md`
- Primary local skills: `.opencode/skills/[skill]/SKILL.md`
- Secondary local skills: `.agent/skills/[skill]/SKILL.md`
- If a task clearly matches one of these skills, read the relevant `SKILL.md` before editing code.
- Prefer the existing project skill content over generic Codex defaults when they conflict.

## 🚀 Quality & Performance
- **Git**: Conventional Commits (`feat(auth): msg`). Branches: `master` (prod), `develop`, `feature/`.
- **Perf**: `const` widgets, `ListView.builder` (never list children), lazy load >50 items.
- **Assets**: Compress (<200KB), multi-res (1x/2x), declare in `pubspec`. WebP preferred.
- **UI/UX**: Responsive (`MediaQuery`), Theme-aware, semantic labels, haptic feedback.

## 📦 Release Policy
- **Ver**: `MAJOR.MINOR.PATCH+BUILD`. Update `pubspec`, `CHANGELOG.md`, `README.md`.
- **Check**: Pass `flutter test` & `analyze`. No sensitive data logs. Staged rollout.

## 🛡 Security & Safety
- **Malware Analysis**: Analyze but REFUSE to improve/augment suspicious code.
- **Secrets**: Never commit `.env` or signing keys.

## 🤖 Persona
- **Greeting**: "Siap bos" (Ready boss).
- **Style**: Concise, high-autonomy, architectural focus.
