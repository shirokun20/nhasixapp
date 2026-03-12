# Project Workflow Skill

## 📋 Overview

This skill defines the development workflow phases and processes for NhasixApp. Following these rules ensures consistency, traceability, and quality across all development work.

---

## 🔄 Development Workflow Phases

### Phase 1: Analysis (READ-ONLY)

**Location:** `projects/analysis-plan/[feature-name]/`  
**File:** `analysis.md`  
**Rule:** 📖 READ-ONLY - Document findings only, NO code changes

```
projects/
└── analysis-plan/
    └── builtin-dns-resolver/
        └── analysis.md          # Deep analysis document
```

**What to do:**
- ✅ Research current implementation
- ✅ Identify problems and issues
- ✅ Document architecture and dependencies
- ✅ Propose multiple solutions
- ✅ Analyze trade-offs
- ✅ Create recommendations

**What NOT to do:**
- ❌ Don't modify any source code
- ❌ Don't make design decisions yet
- ❌ Don't start implementation planning

**Template:**
```markdown
# [Feature Name] Analysis

**Date:** YYYY-MM-DD  
**Status:** Analysis Phase  

## 📋 Executive Summary
Brief overview of the analysis

## 🎯 Problem Statement
What problem are we solving?

## 🔍 Current Implementation Analysis
- Architecture overview
- Key components
- Code flow diagrams

## 🔴 Identified Issues
List all problems found

## ✅ Recommendations
Proposed solutions with trade-offs

## 📊 Implementation Priority Matrix
Effort vs Impact analysis

## 📝 Files Requiring Changes
List of files that will be modified

## 🧪 Testing Strategy
How to verify the solution

## ✅ Next Steps
Ready for Planning Phase
```

---

### Phase 2: Planning (DESIGN ONLY)

**Location:** `projects/future-plan/[feature-name]/`  
**File:** `implementation-plan.md`  
**Rule:** 🎨 DESIGN ONLY - Create plan, NO code changes

```
projects/
└── future-plan/
    └── builtin-dns-resolver/
        └── implementation-plan.md   # Implementation plan
```

**What to do:**
- ✅ Break down into phases/tasks
- ✅ Create implementation checklist
- ✅ Define architecture changes
- ✅ Plan testing strategy
- ✅ Identify risks and mitigations
- ✅ Set success metrics
- ✅ Create rollback plan

**What NOT to do:**
- ❌ Don't write implementation code
- ❌ Don't modify existing files
- ❌ Don't start coding yet

**Template:**
```markdown
# [Feature Name] Implementation Plan

**Date:** YYYY-MM-DD  
**Status:** Planning Phase  
**Related Analysis:** `../analysis-plan/[feature-name]/analysis.md`

## 🎯 Goal
Clear statement of what we're implementing

## 📋 Implementation Phases
### Phase 1: [Name]
**Priority:** HIGH/MEDIUM/LOW

#### Tasks:
1. [ ] Task 1
2. [ ] Task 2

**Files to Modify:**
- `path/to/file1.dart`
- `path/to/file2.dart`

**Tests Required:**
- Unit test for X
- Integration test for Y

## 🏗️ Architecture Considerations
- Clean Architecture compliance
- DI pattern
- BLoC/Cubit pattern

## 📝 Implementation Checklist
Detailed task list for all phases

## 🧪 Testing Strategy
- Unit tests
- Integration tests
- Manual testing scenarios

## ⚠️ Risk Mitigation
Identify risks and how to handle them

## 📊 Success Metrics
How we measure success

## 🔄 Rollback Plan
What to do if things go wrong

## ✅ Definition of Done
Criteria for completion

**Plan Complete** → Ready for Execution Phase
```

---

### Phase 3: Execution (CODE ALLOWED)

**Location:** `projects/onprogress-plan/[feature-name]/`  
**File:** `progress.md` (optional, for tracking)  
**Rule:** 💻 CODE ALLOWED - Implement the plan

```
projects/
└── onprogress-plan/
    └── builtin-dns-resolver/
        └── progress.md            # Progress tracking (optional)
```

**What to do:**
- ✅ Create todo list before starting
- ✅ Implement tasks from plan
- ✅ Update `.md` file with completion `[x]`
- ✅ Run tests frequently
- ✅ Commit after each logical unit
- ✅ Use MCP Sequential Thinking for complex tasks
- ✅ Use Context7/Docfork for documentation lookup

**What NOT to do:**
- ❌ Don't skip the todo list
- ❌ Don't deviate from plan without updating it
- ❌ Don't commit without testing

**Workflow:**
```bash
# 1. Move plan to in-progress
mv projects/future-plan/[feature] projects/onprogress-plan/

# 2. Create todo list (in your task tracker)
# 3. Implement tasks one by one
# 4. Update progress.md
- [x] Task 1 completed
- [ ] Task 2 in progress

# 5. Commit with conventional commit
git add .
git commit -m "feat(dns): remove system DNS fallback"

# 6. Move to success when done
mv projects/onprogress-plan/[feature] projects/success-plan/
```

---

### Phase 4: Completion (DOCUMENT SUCCESS)

**Location:** `projects/success-plan/[feature-name]/`  
**Rule:** ✅ MOVE HERE after successful implementation

```
projects/
└── success-plan/
    └── builtin-dns-resolver/
        ├── implementation-plan.md   # Original plan
        └── progress.md              # What was actually done
```

**What to do:**
- ✅ Move folder from `onprogress-plan/`
- ✅ Document any deviations from plan
- ✅ Note lessons learned
- ✅ Update CHANGELOG.md
- ✅ Update README.md if needed

**Completion Template:**
```markdown
# [Feature Name] - COMPLETED ✅

**Completed Date:** YYYY-MM-DD  
**Original Plan:** `implementation-plan.md`

## 📝 Summary
What was implemented

## ✅ Completed Tasks
List of what was done

## 🔄 Deviations from Plan
Any changes from original plan

## 🐛 Issues Encountered
Problems faced and how they were solved

## 📊 Results
- All tests passing
- Performance metrics achieved
- Code reviewed and approved

## 📚 Documentation Updates
- [x] CHANGELOG.md updated
- [x] README.md updated (if needed)
- [x] User documentation updated (if applicable)

## 🎉 Success Criteria Met
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] `flutter analyze` passes
- [ ] Manual testing completed
- [ ] Code reviewed
- [ ] Documentation updated
```

---

## 📝 Git Workflow

### Branch Naming

```
master          # Production (protected)
develop         # Development branch
feature/xxx     # Feature branches
hotfix/xxx      # Production fixes
```

### Commit Messages (Conventional Commits)

```
feat: New feature
fix: Bug fix
docs: Documentation changes
style: Code style changes (formatting, etc)
refactor: Code refactoring
test: Adding tests
chore: Build/config changes
```

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples:**
```bash
# Feature
git commit -m "feat(dns): add DNS-over-HTTPS support"

# Bug fix
git commit -m "fix(license): resolve license validation timeout"

# Refactor
git commit -m "refactor(data): migrate to freezed models"

# Docs
git commit -m "docs: update README with DNS features"
```

---

## 🧪 Quality Gates

### Before Commit

```bash
# 1. Run tests
flutter test

# 2. Run analyzer
flutter analyze

# 3. Check formatting
dart format --set-exit-if-changed .

# 4. Check for sensitive data
# Search for API keys, passwords, etc.
grep -r "API_KEY" lib/
grep -r "password" lib/
```

### Before Push

```bash
# 1. Ensure all tests pass
flutter test

# 2. Ensure analyze passes
flutter analyze

# 3. Review your changes
git diff HEAD

# 4. Pull latest changes
git pull origin develop

# 5. Rebase if needed
git rebase origin/develop
```

---

## 📋 Code Review Checklist

### Architecture
- [ ] Follows Clean Architecture
- [ ] Proper dependency injection
- [ ] No circular dependencies
- [ ] Domain layer is pure Dart

### Code Quality
- [ ] Follows style guide (snake_case, PascalCase, camelCase)
- [ ] No print/debugPrint (use logger)
- [ ] Proper error handling
- [ ] Const widgets where possible

### Testing
- [ ] Unit tests added/updated
- [ ] Integration tests if needed
- [ ] All tests passing
- [ ] Test coverage adequate

### Performance
- [ ] ListView.builder for long lists
- [ ] Images cached properly
- [ ] No memory leaks
- [ ] Lazy loading for large data

### Security
- [ ] No sensitive data in logs
- [ ] Secure storage for sensitive data
- [ ] Input validation
- [ ] No hardcoded secrets

---

## 🚀 Release Workflow

### Version Numbering

```
MAJOR.MINOR.PATCH+BUILD
  │     │     │    │
  │     │     │    └─ Build number (CI/CD)
  │     │     └────── Patch (bug fixes)
  │     └──────────── Minor (new features)
  └────────────────── Major (breaking changes)
```

### Release Checklist

```markdown
## Pre-Release
- [ ] Update version in pubspec.yaml
- [ ] Update CHANGELOG.md
- [ ] Update README.md (if needed)
- [ ] Run all tests: `flutter test`
- [ ] Run analyzer: `flutter analyze`
- [ ] Build release: `flutter build apk --release`
- [ ] Test on real devices
- [ ] Check for sensitive data in logs

## Release
- [ ] Create git tag: `git tag v1.1.2`
- [ ] Push tag: `git push origin --tags`
- [ ] Create GitHub release
- [ ] Deploy to Play Store (staged rollout)

## Post-Release
- [ ] Monitor crash reports
- [ ] Check user feedback
- [ ] Update issue tracker
```

---

## 📚 MCP Tools Usage

### Sequential Thinking (Complex Tasks)

```dart
// Use when:
// - Task requires multiple steps
// - Need to maintain context
// - Might need course correction

// Example: Implementing DNS health monitor
1. Design API structure
2. Implement health check logic
3. Add endpoint ranking
4. Integrate with DnsResolver
5. Write tests
```

### Context7 (Documentation Lookup)

```dart
// Use when:
// - Need up-to-date library docs
// - Looking for code examples
// - Verifying API usage

// Example: Query flutter_bloc documentation
mcp__asix-context7__query-docs(
  libraryId: "/felangel/bloc",
  query: "How to use BlocListener for side effects"
)
```

### Docfork (Library Documentation)

```dart
// Use when:
// - Searching library documentation
// - Need official docs with code examples
// - Multiple libraries to search

// Example: Search for DNS-over-HTTPS implementation
mcp__asix-docfork__search_docs(
  library: "dio",
  query: "custom HTTP client with connectionFactory"
)
```

---

## 🎯 Quick Reference

### Workflow Summary

```
1. ANALYSIS  → projects/analysis-plan/[feature]/analysis.md
2. PLANNING  → projects/future-plan/[feature]/implementation-plan.md
3. EXECUTION → projects/onprogress-plan/[feature]/progress.md
4. COMPLETION→ projects/success-plan/[feature]/
```

### Command Summary

```bash
# Move plan between phases
mv projects/future-plan/feature projects/onprogress-plan/
mv projects/onprogress-plan/feature projects/success-plan/

# Quality checks
flutter test
flutter analyze
dart format --set-exit-if-changed .

# Build
flutter clean && flutter pub get
flutter build apk --release
```

### File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Analysis | `analysis.md` | `builtin-dns-resolver/analysis.md` |
| Plan | `implementation-plan.md` | `builtin-dns-resolver/implementation-plan.md` |
| Progress | `progress.md` | `builtin-dns-resolver/progress.md` |
| Screens | `snake_case_screen.dart` | `comic_list_screen.dart` |
| Cubits | `snake_case_cubit.dart` | `comic_cubit.dart` |
| Models | `snake_case_model.dart` | `comic_model.dart` |

---

## 📚 References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [flutter_bloc](https://bloclibrary.dev/)
- [GetIt](https://github.com/fluttercommunity/get_it)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
