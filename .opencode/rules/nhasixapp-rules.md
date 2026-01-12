---
trigger: always_on
---

# NhasixApp Development Rules

## ⚡ Core Commands
- **Build/Run**: `flutter clean && flutter pub get` | `flutter run --debug` | `flutter build apk --release`
- **Test/Lint**: `flutter test` | `flutter analyze` | `dart run build_runner build`
- **Release**: `./build_release.sh` (Custom) | `flutter build ipa` (iOS)

## 🧠 Development Workflow (CRITICAL)

### Phase 1: Analysis
- **Path**: `projects/analysis-plan/[folder-name]/[file-name]-analysis.md`
- **Mode**: READ-ONLY. Document findings only.
- **Purpose**: Understand requirements, identify risks, document existing behavior.

### Phase 2: Planning
- **Path**: `projects/future-plan/[folder-name]/[file-name]-plan.md`
- **Mode**: Design only. NO code changes.
- **Purpose**: Create implementation plan, define architecture, estimate effort.

### Phase 3: Execution
- **Path**: `projects/onprogress-plan/[folder-name]/[file-name]-progress.md`
- **Mode**: Code allowed.
- **Requirements**:
  - MUST create Todo list first
  - Update `.md` only for completion `[x]`
  - Use MCP tools: `Sequential Thinking`, `Context7`, `Docfork` for complex tasks

### Phase 4: Completion
- Move folder to `projects/success-plan/[folder-name]/`
- Verify all tests pass
- Update documentation

## 🛠 Code Standards

### Architecture
- **Pattern**: Clean Architecture (`domain` → `data` → `presentation`)
- **DI**: GetIt in `core/di/`
- **Dependencies flow**: presentation → domain ← data

### Naming Conventions
- **Files**: `snake_case` (e.g., `user_repository.dart`)
- **Classes**: `PascalCase` (e.g., `UserRepository`)
- **Variables**: `camelCase` (e.g., `userName`)

### State Management
- **Complex state**: `flutter_bloc` (BLoC pattern)
- **Simple state**: `Cubit` (extend `BaseCubit`)

### Logging
- Use `logger` package with levels: `.t` (trace) to `.f` (fatal)
- **NEVER** use `print` or `debugPrint`

### Models
- Extend entities
- Implement: `.fromEntity()`, `.toEntity()`, `.fromMap()`

## 🚀 Quality & Performance

### Git
- **Commits**: Conventional Commits (`feat(auth): message`)
- **Branches**: `master` (prod), `develop`, `feature/*`

### Performance
- Use `const` widgets
- Use `ListView.builder` (never list children directly)
- Lazy load lists with >50 items

### Assets
- Compress to <200KB
- Use multi-resolution (1x/2x/3x)
- Declare in `pubspec.yaml`
- Prefer WebP format

### UI/UX
- Responsive layouts with `MediaQuery`
- Theme-aware styling
- Semantic labels for accessibility
- Haptic feedback for interactions

## 📦 Release Policy

### Versioning
- Format: `MAJOR.MINOR.PATCH+BUILD`
- Update: `pubspec.yaml`, `CHANGELOG.md`, `README.md`

### Pre-release Checklist
- [ ] `flutter test` passes
- [ ] `flutter analyze` clean
- [ ] No sensitive data in logs
- [ ] Staged rollout planned
