# Contributing to Kuron

Thank you for your interest in contributing to **Kuron** — an unofficial, privacy-first manga reader for Android built with Flutter and Clean Architecture.

We welcome contributions of all kinds: bug fixes, features, documentation, and ideas. This guide will help you get started quickly and keep the codebase consistent.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Architecture Overview](#architecture-overview)
- [Development Setup](#development-setup)
- [Branching & Workflow](#branching--workflow)
- [Commit Convention](#commit-convention)
- [Code Style & Quality](#code-style--quality)
- [Testing](#testing)
- [Pull Request Checklist](#pull-request-checklist)
- [Reporting Issues](#reporting-issues)
- [License](#license)

---

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold its terms. Please be respectful and constructive in all interactions.

---

## Ways to Contribute

- **Report bugs** — open an issue with reproduction steps, expected vs actual behavior, and device info.
- **Suggest features** — describe the use case and why it matters; include mockups if helpful.
- **Improve docs** — fix typos, clarify setup steps, or add examples.
- **Submit code** — pick an open issue or propose a new one before starting large changes.

> **First time contributing?** See [How to Contribute to an Open Source Project on GitHub](https://kcd.im/pull-request) for a step-by-step guide.

---

## Architecture Overview

Kuron follows **Clean Architecture** with strict layer separation:

| Layer | Responsibility | Dependencies |
|-------|---------------|--------------|
| **Domain** | Entities, use cases, repository interfaces — pure Dart, no Flutter | None |
| **Data** | Repository implementations, models, data sources (API, DB, scraping) | Domain only |
| **Presentation** | Widgets, pages, BLoC/Cubit, navigation | Domain (+ DI) |

- **State management:** `flutter_bloc` / `Cubit` (all cubits extend `BaseCubit`).
- **Dependency injection:** `GetIt` via `core/di/service_locator.dart`.
- **Routing:** `go_router`.
- **Storage:** `sqflite` + `SharedPreferences`.

See [DESIGN.md](DESIGN.md) and [AGENTS.md](AGENTS.md) for deeper architectural details.

---

## Development Setup

### Prerequisites

- **Flutter** via [FVM](https://fvm.app/) (see `.fvmrc` for the pinned version)
- **Dart** 3.5+
- **Android SDK** with NDK (for native builds)

### Steps

1. **Fork and clone**

   ```bash
   git clone https://github.com/<your-username>/nhasixapp.git
   cd nhasixapp
   ```

2. **Install dependencies**

   ```bash
   fvm flutter pub get
   ./scripts/pub_get_all.sh   # also fetches workspace packages
   ```

3. **Generate code** (Freezed, JSON, Injectable)

   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**

   ```bash
   fvm flutter run --debug
   # or with flavor
   fvm flutter run --debug --flavor dev --dart-define=cronetHttpNoPlay=true
   ```

5. **Create a feature branch**

   ```bash
   git checkout -b feat/your-feature-name
   ```

---

## Branching & Workflow

| Branch | Purpose |
|--------|---------|
| `master` | Production releases |
| `develop` | Integration branch for next release |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `hotfix/*` | Urgent production fixes |

- Branch from `develop` for features/fixes; open PRs against `develop`.
- Keep PRs focused and small — one logical change per PR.
- Rebase or merge `develop` regularly to avoid large conflicts.

---

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

[optional body]
[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`

**Examples:**

```
feat(reader): add continuous scroll mode
fix(search): handle empty query edge case
docs(readme): clarify FVM setup steps
```

---

## Code Style & Quality

- **Formatting:** `fvm dart format .` (enforced in CI).
- **Linting:** `fvm flutter analyze` must pass with no issues.
- **Naming:**
  - Files: `snake_case` — `user_repository.dart`
  - Classes: `PascalCase` — `UserRepository`
  - Variables: `camelCase` — `userName`
- **Logging:** Use `logger` (`.t` / `.d` / `.i` / `.w` / `.e` / `.f`). Never `print` / `debugPrint`.
- **Models:** Extend their entity and implement `.fromEntity()`, `.toEntity()`, `.fromMap()`.
- **Imports order:** Dart SDK → Flutter → external packages → project imports.
- **Generated files:** Never edit `*.g.dart` / `*.freezed.dart` directly — edit the source and re-run `build_runner`.
- **Performance:** Prefer `const` widgets, `ListView.builder` over `Column(children:)`, lazy-load large lists, compress assets (< 200 KB, WebP preferred).

Run before pushing:

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```

---

## Testing

- **Unit tests:** `fvm flutter test`
- **Single file:** `fvm flutter test test/path/to_test.dart`
- **Coverage:** `fvm flutter test --coverage`

Please add or update tests for new logic, especially for domain use cases, mappers, and BLoC/Cubit behavior.

---

## Pull Request Checklist

Before requesting review, ensure:

- [ ] Branch is up to date with `develop`
- [ ] `fvm dart format .` and `fvm flutter analyze` pass
- [ ] Tests pass (`fvm flutter test`)
- [ ] Code follows Clean Architecture layer rules
- [ ] No generated files (`*.g.dart`, `*.freezed.dart`) were manually edited
- [ ] Commit messages follow Conventional Commits
- [ ] PR description explains **what**, **why**, and **how** (with screenshots for UI changes)
- [ ] Related issue is linked (e.g., `Closes #123`)

---

## Reporting Issues

Use the [Issues](https://github.com/shirokun20/nhasixapp/issues) tab and include:

- Kuron version (`pubspec.yaml` → `version`)
- Device / Android version
- Steps to reproduce
- Expected vs actual behavior
- Logs or screenshots if applicable

For security vulnerabilities, see [SECURITY.md](SECURITY.md) — please do **not** open a public issue.

---

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE) as the project.

---

Thank you for helping make Kuron better!
