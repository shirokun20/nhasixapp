# NhasixApp Agent Rules

## 🤖 Custom Agents & Skills

This project includes custom OpenCode agents and skills in `.opencode/`:

### Agents (invoke with @)
- `@flutter-architect` - Clean Architecture guidance and reviews
- `@feature-dev` - Development workflow coordinator
- `@code-reviewer` - Flutter code quality reviews
- `@ui-designer` - UI/UX and responsive design guidance

### Skills (loaded via skill tool)
- `clean-arch` - Clean Architecture implementation patterns
- `bloc-pattern` - BLoC/Cubit state management patterns
- `project-workflow` - Development workflow phases and processes
- `di-setup` - Dependency Injection with GetIt setup

---

## ⚡ Core Commands
- **Build/Run**: `flutter clean && flutter pub get` | `flutter run --debug` | `flutter build apk --release`
- **Test/Lint**: `flutter test` | `flutter analyze` | `dart run build_runner build`
- **Release**: `./build_release.sh` (Custom) | `flutter build ipa` (iOS)

## 🧠 Development Workflow (CRITICAL)
1. **Analysis**: `projects/analysis-plan/[folder]/[file].md`. **READ-ONLY**. Document findings.
2. **Planning**: `projects/future-plan/[folder]/[file].md`. **Design only**. No code changes.
3. **Execution**: `projects/onprogress-plan/[folder]/[file].md`. **Code Allowed**.
   - **MUST** create Todo list first. Update `.md` only for completion `[x]`.
   - Use `MCP Sequential Thinking`, `Context7`, `Docfork` for complex tasks.
4. **Completion**: Move folder to `projects/success-plan/[folder]/`.

## 🛠 Code Standards
- **Arch**: Clean Architecture (`domain` -> `data` -> `presentation`). DI via `GetIt` (`core/di/`).
- **Style**: `snake_case` (files), `PascalCase` (classes), `camelCase` (vars).
- **State**: `flutter_bloc` (complex) or `Cubit` (simple). Extend `BaseCubit`.
- **Logs**: Use `logger` package (`.t` to `.f`). **NO** `print`/`debugPrint`.
- **Models**: Extend entities. Implement `.fromEntity()`, `.toEntity()`, `.fromMap()`.

## 🚀 Quality & Performance
- **Git**: Conventional Commits (`feat(auth): msg`). Branches: `master` (prod), `develop`, `feature/`.
- **Perf**: `const` widgets, `ListView.builder` (never list children), lazy load >50 items.
- **Assets**: Compress (<200KB), multi-res (1x/2x), declare in `pubspec`. WebP preferred.
- **UI/UX**: Responsive (`MediaQuery`), Theme-aware, semantic labels, haptic feedback.

## 📦 Release Policy
- **Ver**: `MAJOR.MINOR.PATCH+BUILD`. Update `pubspec`, `CHANGELOG.md`, `README.md`.
- **Check**: Pass `flutter test` & `analyze`. No sensitive data logs. Staged rollout.