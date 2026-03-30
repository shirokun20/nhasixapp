---
name: git-workflow
description: Panduan Git workflow dan Conventional Commits untuk NhasixApp
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: git
---

## Git Workflow Guide untuk NhasixApp

### Branch Strategy

```
master (production)
  │
  └── develop (integration)
        │
        ├── feature/auth-login
        ├── feature/user-profile
        ├── fix/crash-on-startup
        └── hotfix/security-patch
```

| Branch | Deskripsi |
|--------|-----------|
| `master` | Production-ready code |
| `develop` | Integration branch |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `hotfix/*` | Urgent production fixes |

### Conventional Commits

Format:
```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

#### Types

| Type | Deskripsi | Contoh |
|------|-----------|--------|
| `feat` | Fitur baru | `feat(auth): add biometric login` |
| `fix` | Bug fix | `fix(cart): resolve quantity update issue` |
| `docs` | Dokumentasi | `docs(readme): update installation guide` |
| `style` | Formatting, semicolons | `style(lint): fix trailing commas` |
| `refactor` | Refactoring code | `refactor(user): simplify validation logic` |
| `perf` | Performance improvement | `perf(list): implement lazy loading` |
| `test` | Adding tests | `test(auth): add login unit tests` |
| `chore` | Maintenance tasks | `chore(deps): update flutter_bloc to 8.1.0` |
| `build` | Build system changes | `build(android): update gradle version` |
| `ci` | CI configuration | `ci(github): add flutter analyze step` |

#### Scopes (berdasarkan features)

Gunakan nama feature atau module:
- `auth` - Authentication
- `user` - User management
- `cart` - Shopping cart
- `product` - Product catalog
- `order` - Order management
- `core` - Core utilities
- `ui` - UI components
- `deps` - Dependencies

#### Examples

```bash
# Feature baru
git commit -m "feat(auth): implement social login with Google"

# Bug fix
git commit -m "fix(cart): prevent negative quantity values"

# Dengan body
git commit -m "feat(notification): add push notification support

Implemented Firebase Cloud Messaging integration.
Added notification permission handling for iOS and Android.

Closes #123"

# Breaking change
git commit -m "feat(api)!: migrate to v2 endpoints

BREAKING CHANGE: All API endpoints now use /v2 prefix.
Old endpoints will be deprecated in next release."
```

### Git Commands Cheat Sheet

```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/new-feature

# Commit changes
git add .
git commit -m "feat(scope): description"

# Push branch
git push -u origin feature/new-feature

# Rebase dengan develop (sebelum PR)
git fetch origin
git rebase origin/develop

# Squash commits (jika perlu)
git rebase -i HEAD~3

# Merge ke develop (via PR)
# Gunakan GitHub/GitLab PR untuk code review

# Tag release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
```

### Pre-commit Checklist

Sebelum commit, pastikan:

1. [ ] `flutter analyze` - No errors
2. [ ] `flutter test` - All tests pass
3. [ ] No sensitive data (API keys, passwords)
4. [ ] No `print` statements (use logger)
5. [ ] Code follows project conventions
6. [ ] Commit message follows Conventional Commits

### Pull Request Template

```markdown
## Summary
Brief description of changes.

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style
- [ ] Self-review completed
- [ ] No sensitive data exposed
- [ ] flutter analyze passes
- [ ] flutter test passes

## Related Issues
Closes #XXX
```

### Version Numbering

Format: `MAJOR.MINOR.PATCH+BUILD`

| Part | Kapan Increment |
|------|-----------------|
| MAJOR | Breaking changes |
| MINOR | New features (backward compatible) |
| PATCH | Bug fixes |
| BUILD | Build number (auto-increment) |

Contoh: `1.2.3+45`

Update di:
- `pubspec.yaml`
- `CHANGELOG.md`
- `README.md` (jika perlu)

### Release Checklist

1. [ ] All features merged to `develop`
2. [ ] `flutter test` passes
3. [ ] `flutter analyze` clean
4. [ ] Update version in `pubspec.yaml`
5. [ ] Update `CHANGELOG.md`
6. [ ] Create release branch: `release/v1.2.0`
7. [ ] Final testing
8. [ ] Merge to `master`
9. [ ] Tag release: `v1.2.0`
10. [ ] Merge back to `develop`
11. [ ] Build & deploy
