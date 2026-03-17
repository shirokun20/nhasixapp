---
name: manager-assistant
description: Comprehensive workflow assistant for NhasixApp enforcing Clean Architecture, strict development phases, and clean core standards.
---

# Manager Assistant Skill

This skill provides the comprehensive operational rules and standards for developing the NhasixApp, derived from the project's custom core guidelines. Enable this skill whenever starting a new development task to ensure 100% compliance with the NhasixApp manager's strict rules.

## 🧠 Development Workflow (CRITICAL)
Every single task executed must strictly follow these four predefined directories and phases:

1. **Analysis Phase**:
   - Location: `projects/analysis-plan/[folder]/[file].md`
   - **READ-ONLY**: Do NOT modify actual code in this phase. Perform investigation, read files, and write your findings into the analysis markdown.
2. **Planning Phase**:
   - Location: `projects/future-plan/[folder]/[file].md`
   - **Design Only**: Create the technical design and plan. Detail the API contracts, component structural changes, and verification strategies without touching the real implementation.
3. **Execution Phase**:
   - Location: `projects/onprogress-plan/[folder]/[file].md`
   - **Code Allowed**: You may now write the code.
   - **Requirement**: You MUST first create a Todo list in this file. Continuously update this markdown file (e.g., ticking `[x]`) as you achieve each subtask.
   - For complex problem-solving, forcefully utilize `MCP Sequential Thinking`, `Context7`, and `Docfork`.
4. **Completion Phase**:
   - Location: `projects/success-plan/[folder]/`
   - Once all logic is done and verified, physically move the `.md` plan file here to signify task completeness.

## 🛠 Code Standards & Architecture
- **Architecture**: Enforce Clean Architecture strictly (`domain` -> `data` -> `presentation`).
- **Dependency Injection**: Utilize `GetIt` specifically within the `core/di/` setup.
- **Naming Conventions**:
  - `snake_case` for all files.
  - `PascalCase` for all classes.
  - `camelCase` for variables and functions.
- **State Management**: Utilize `flutter_bloc` for complex business logic, or `Cubit` for trivial states. Must always extend `BaseCubit`.
- **Logging**: Strictly use the custom `logger` package (`.t` through `.f`). **NEVER** use standard `print` or `debugPrint`.
- **Data Models**: All models must extend base entities. You must implement `.fromEntity()`, `.toEntity()`, and `.fromMap()` on every model bridging the data and domain layer.

## 🚀 Quality, Performance & UI/UX
- **Git Strategy**: Use Conventional Commits globally (e.g., `feat(auth): xyz`). Use `develop` or `feature/` branches.
- **Performance**:
  - Maximize the use of `const` widgets unconditionally.
  - NEVER list entire children in `ListView.builder`.
  - Pagination/lazy-loading is strictly required for collections >50 items.
- **Assets**: Compress everything under 200KB, maintain multi-res (1x/2x), and prefer WebP formatting. Register formally in `pubspec.yaml`.
- **UI/UX**: Hardcode responsive layouts using `MediaQuery`. Everything must be theme-aware with semantic labels attached for accessibility, and UX paths must integrate haptic feedback points.

## 📦 Core Commands & Releases
- **Build/Run**:
  - `flutter clean && flutter pub get`
  - `flutter run --debug`
  - `flutter build apk --release`
- **Testing & Analyzing**:
  - `flutter test`
  - `flutter analyze`
  - `dart run build_runner build`
- **Release Verification**: All builds must pass `analyze` and `test` inherently. Secrets and sensitive data must not show in logs. Must upgrade `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`, `CHANGELOG.md`, and `README.md`.
