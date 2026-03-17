# Git Workflow

Git branching strategy and Conventional Commits for NhasixApp.

## Branch Strategy

```
master (production)
  └── develop (integration)
        ├── feature/auth-login
        ├── fix/crash-on-startup
        └── hotfix/security-patch
```

## Conventional Commits

Format: `<type>(<scope>): <subject>`

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructure, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding/updating tests |
| `chore` | Maintenance (deps, config) |
| `build` | Build system changes |
| `ci` | CI configuration |

Scopes: `auth`, `user`, `reader`, `core`, `ui`, `deps`, etc.

```bash
# Examples
git commit -m "feat(auth): implement social login with Google"
git commit -m "fix(cart): prevent negative quantity values"
git commit -m "feat(api)!: migrate to v2 endpoints

BREAKING CHANGE: All endpoints now use /v2 prefix."
```

## Pre-commit Checklist
1. `flutter analyze` — no errors
2. `flutter test` — all pass
3. No sensitive data (API keys, passwords)
4. No `print` statements (use logger)
5. Code follows project conventions
6. Commit message follows Conventional Commits

## Version Numbering

`MAJOR.MINOR.PATCH+BUILD`

Update in: `pubspec.yaml`, `CHANGELOG.md`, `README.md`

## Release Checklist
1. All features merged to `develop`
2. Tests pass, analyze clean
3. Update version in `pubspec.yaml`
4. Update `CHANGELOG.md`
5. Create `release/vX.Y.Z` branch
6. Final testing
7. Merge to `master`
8. Tag release: `vX.Y.Z`
9. Merge back to `develop`
10. Build & deploy

## IMPORTANT
- User handles all git operations manually
- Agent should NEVER run `git add` or `git commit`
