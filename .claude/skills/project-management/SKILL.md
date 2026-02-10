---
name: project-management
description: Manage the "Advanced Engineering" project lifecycle (init, start, finish, progress, issue).
---

# Project Management Skill

This skill manages the strict project lifecycle defined in `CLAUDE.md`.

## Actions

### 1. Init Project (`init`)
Scaffolds a new analysis folder using the standard template.
- **Input**: `name` (string)
- **Steps**:
  1. Create directory `projects/analysis-plan/[name]/`.
  2. Copy `projects/templates/project_plan_template.md` to `projects/analysis-plan/[name]/README.md`.
  3. Replace `[Project Name]` in the file with the actual name.
  4. Add entry to `projects/master-project-list.md` under "Analysis".
  5. Run `dart scripts/project_status.dart` to update dashboards.

### 2. Start Project (`start`)
Moves a project to execution.
- **Input**: `name` (string)
- **Steps**:
  1. Move `projects/analysis-plan/[name]` to `projects/onprogress-plan/[name]`.
  2. Create `projects/onprogress-plan/[name]/progress.md` with a checkbox list derived from the analysis plan.
  3. Update `projects/master-project-list.md` (Analysis -> In Progress).
  4. Run `dart scripts/project_status.dart` to update dashboards.

### 3. Finish Project (`finish`)
Archives a completed project.
- **Input**: `name` (string)
- **Steps**:
  1. Verify all checkboxes in `progress.md` are checked.
  2. Run `flutter analyze` and `flutter test`.
  3. Move `projects/onprogress-plan/[name]` to `projects/success-plan/[name]`.
  4. Update `projects/master-project-list.md` (In Progress -> Completed).
  5. Run `dart scripts/project_status.dart` to update dashboards.

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
