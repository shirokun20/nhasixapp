---
name: project-management
description: Manage the "Advanced Engineering" project lifecycle (init, start, finish, progress, issue).
---

# Project Management Skill

This skill manages the strict project lifecycle defined in `AGENTS.md`.

## Actions

### 1. Init Project (`init`)
Scaffolds a new analysis folder using the standard template.
- **Input**: `name` (string)
- **Steps**:
  1. Create directory `projects/analysis-plan/[name]/`.
  2. Generate filename: `projects/analysis-plan/[name]/[name]_[YYYY-MM-DD].md`.
  3. Copy `projects/templates/project_plan_template.md` to that file.
  4. Replace `[Project Name]` in the file with the actual name.
  5. Run `dart scripts/project_status.dart` to update dashboards.

### 2. Start Project (`start`)
Moves a project to execution.
- **Input**: `name` (string)
- **Steps**:
  1. Move `projects/analysis-plan/[name]` to `projects/onprogress-plan/[name]`.
  2. Create `projects/onprogress-plan/[name]/progress.md`.
  3. Copy the "Implementation Plan" section from the main project file to `progress.md`.
  4. Run `dart scripts/project_status.dart` to update dashboards.

### 3. Finish Project (`finish`)
Archives a completed project.
- **Input**: `name` (string)
- **Steps**:
  1. Verify `progress.md` has 100% completion (all checkboxes checked).
  2. Run `flutter analyze` and `flutter test`.
  3. Move `projects/onprogress-plan/[name]` to `projects/success-plan/[name]`.
  4. Run `dart scripts/project_status.dart` to update dashboards.

### 4. Check Progress (`progress`)
Updates all project dashboards.
- **Steps**:
  1. Run `dart scripts/project_status.dart`.

### 5. Create Issue (`issue`)
Creates a standardized issue ticket.
- **Input**: `title` (string)
- **Steps**:
  1. Generate filename: `projects/issues/YYYY-MM-DD-[title_snake_case].md`.
  2. Copy content from `projects/templates/issue_template.md`.
  3. Update title in file.
  4. **Update `projects/issues/README.md`** with the new issue entry.
  5. **Update `projects/README.md`** Active Issues section with the new issue.
  6. Run `dart scripts/project_status.dart` to update dashboards.

## 📋 README Update Guidelines

When creating/updating issues, always update:

### 1. `projects/issues/README.md`
Add entry to Active Issues table:
```markdown
| [Issue Title](./YYYY-MM-DD-file_name.md) | YYYY-MM-DD | Type | Priority | Status |
```

### 2. `projects/README.md`
Add entry to Active Issues section:
```markdown
| [Issue Title](./issues/YYYY-MM-DD-file_name.md) | YYYY-MM-DD | Type | Priority | Status |
```

### Status Labels
- 📝 Documented - Issue created, awaiting approval
- 🔍 Analyzing - In analysis phase
- 🚧 In Progress - Being implemented
- ✅ Resolved - Completed

## 📜 Available Scripts

Scripts located in `scripts/` folder:

| Script | Command | Purpose |
|---|---|---|
| **project_status.dart** | `dart scripts/project_status.dart` | Auto-update all project dashboards with progress bars |
| **create_feature.dart** | `dart scripts/create_feature.dart [name]` | Scaffold new feature structure (legacy) |

**Important**: Always run `dart scripts/project_status.dart` after:
- Creating new issue
- Moving project between phases
- Updating progress.md checkboxes
- Completing project implementation

This ensures all README.md dashboards stay synchronized.
