---
name: doc-workflow
description: Panduan lengkap workflow dokumentasi project NhasixApp dari analysis hingga completion
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: documentation
---

## Documentation Workflow Guide untuk NhasixApp

### Overview

NhasixApp menggunakan sistem dokumentasi 4 fase untuk setiap feature/task:

```
projects/
├── analysis-plan/     # Fase 1: Analisis (READ-ONLY)
├── future-plan/       # Fase 2: Perencanaan (Design only)
├── onprogress-plan/   # Fase 3: Eksekusi (Code allowed)
└── success-plan/      # Fase 4: Selesai (Archived)
```

### Fase 1: Analysis

**Lokasi**: `projects/analysis-plan/[folder-name]/[feature-name]-analysis.md`

**Tujuan**: Memahami requirements dan mendokumentasikan findings.

**Template**:
```markdown
# [Feature Name] Analysis

**Date**: YYYY-MM-DD
**Author**: [Name]
**Status**: Analysis

## Overview
Deskripsi singkat fitur/task yang akan dianalisis.

## Current State
- Implementasi yang sudah ada (jika ada)
- File dan dependencies terkait
- Behavior saat ini

## Requirements

### Functional Requirements
1. FR-01: [Requirement]
2. FR-02: [Requirement]

### Non-Functional Requirements
1. NFR-01: Performance requirement
2. NFR-02: Security requirement

## Technical Analysis
- Arsitektur yang akan terpengaruh
- Dependencies yang dibutuhkan
- Integrasi dengan fitur lain

## Risks & Considerations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High/Medium/Low | Mitigation strategy |

## Open Questions
- [ ] Question 1
- [ ] Question 2

## References
- Link ke dokumentasi terkait
- Link ke issue/ticket
```

### Fase 2: Planning

**Lokasi**: `projects/future-plan/[folder-name]/[feature-name]-plan.md`

**Tujuan**: Membuat rencana implementasi detail. **TIDAK ADA perubahan code**.

**Template**:
```markdown
# [Feature Name] Implementation Plan

**Date**: YYYY-MM-DD
**Author**: [Name]
**Status**: Planning
**Analysis Ref**: `projects/analysis-plan/[folder]/[file].md`

## Summary
Ringkasan pendekatan implementasi.

## Architecture Design

### Domain Layer
- Entities yang akan dibuat/dimodifikasi
- Repository interfaces
- Use cases

### Data Layer
- Models
- Data sources (remote/local)
- Repository implementations

### Presentation Layer
- Cubit/BLoC
- Pages
- Widgets

## Implementation Tasks

### Phase 1: Domain
- [ ] Task 1.1: Create entity
- [ ] Task 1.2: Create repository interface
- [ ] Task 1.3: Create use case

### Phase 2: Data
- [ ] Task 2.1: Create model
- [ ] Task 2.2: Create data source
- [ ] Task 2.3: Implement repository

### Phase 3: Presentation
- [ ] Task 3.1: Create Cubit/BLoC
- [ ] Task 3.2: Create pages
- [ ] Task 3.3: Create widgets

### Phase 4: Integration
- [ ] Task 4.1: Register DI
- [ ] Task 4.2: Add routes
- [ ] Task 4.3: Write tests

## Dependencies
- Package 1: `package_name: ^version`
- Package 2: `package_name: ^version`

## Effort Estimate
| Task | Estimate |
|------|----------|
| Domain | X hours |
| Data | X hours |
| Presentation | X hours |
| Testing | X hours |
| **Total** | **X hours** |

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All tests pass
- [ ] Code review approved
```

### Fase 3: Execution (Progress)

**Lokasi**: `projects/onprogress-plan/[folder-name]/[feature-name]-progress.md`

**Tujuan**: Track progress implementasi. **Code changes ALLOWED**.

**Requirements**:
- WAJIB buat Todo list terlebih dahulu
- Update file `.md` hanya untuk menandai completion `[x]`
- Gunakan MCP tools untuk task kompleks

**Template**:
```markdown
# [Feature Name] Progress

**Started**: YYYY-MM-DD
**Status**: In Progress
**Plan Ref**: `projects/future-plan/[folder]/[file].md`

## Progress Summary
- **Completed**: X of Y tasks
- **Current Phase**: [Phase name]

## Completed Tasks ✅
- [x] Task 1 - Brief description
  - Files: `path/to/file.dart`
  - Notes: Implementation notes
- [x] Task 2 - Brief description

## Current Task 🔄
- [ ] Task 3 - Description
  - Started: YYYY-MM-DD
  - Blockers: None / [Description]

## Remaining Tasks 📋
- [ ] Task 4
- [ ] Task 5

## Files Changed
```
lib/features/[feature]/
├── domain/
│   ├── entities/
│   └── repositories/
├── data/
│   ├── models/
│   └── datasources/
└── presentation/
    ├── bloc/
    └── pages/
```

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| Issue 1 | How it was resolved |

## Notes
- Implementation notes
- Decisions made
- Deviations from plan
```

### Fase 4: Completion

**Lokasi**: `projects/success-plan/[folder-name]/`

**Action**: Move completed progress file dari `onprogress-plan/` ke sini.

**Checklist sebelum move**:
- [ ] Semua tasks selesai `[x]`
- [ ] `flutter test` pass
- [ ] `flutter analyze` clean
- [ ] Code review approved
- [ ] Documentation updated

**Final Update**:
```markdown
## Completion Summary

**Completed**: YYYY-MM-DD
**Status**: ✅ Completed

### Deliverables
- Feature X implemented
- Y unit tests added
- Documentation updated

### Metrics
- Lines of code: ~XXX
- Test coverage: XX%
- Time spent: X hours

### Lessons Learned
- What went well
- What could be improved
```

### Quick Commands

```bash
# Create new analysis document
mkdir -p projects/analysis-plan/my-feature
touch projects/analysis-plan/my-feature/my-feature-analysis.md

# Create planning document
mkdir -p projects/future-plan/my-feature
touch projects/future-plan/my-feature/my-feature-plan.md

# Start execution
mkdir -p projects/onprogress-plan/my-feature
mv projects/future-plan/my-feature/my-feature-plan.md \
   projects/onprogress-plan/my-feature/my-feature-progress.md

# Complete feature
mv projects/onprogress-plan/my-feature \
   projects/success-plan/my-feature
```

### Best Practices

1. **One folder per feature** - Jangan campur multiple features
2. **Update regularly** - Update progress file setiap selesai task
3. **Link references** - Selalu link ke document sebelumnya
4. **Keep it concise** - Fokus pada informasi essential
5. **Use checklists** - Mudah track progress dengan `[ ]` dan `[x]`
