# Project Management

Manage the strict 4-phase project lifecycle.

## Actions

### Init (`/project init [name]`)
1. Create `projects/analysis-plan/$ARGUMENTS/`
2. Generate `$ARGUMENTS_[YYYY-MM-DD].md` from `projects/templates/project_plan_template.md`
3. Replace `[Project Name]` placeholder with actual name
4. Run `dart scripts/project_status.dart`

### Start (`/project start [name]`)
1. Move `projects/analysis-plan/$ARGUMENTS` to `projects/onprogress-plan/$ARGUMENTS`
2. Create `progress.md` — copy Implementation Plan section from main spec
3. Run `dart scripts/project_status.dart`

### Finish (`/project finish [name]`)
1. Verify `progress.md` has 100% completion (all `[x]`)
2. Run `flutter analyze` and `flutter test`
3. Move `projects/onprogress-plan/$ARGUMENTS` to `projects/success-plan/$ARGUMENTS`
4. Run `dart scripts/project_status.dart`

### Progress (`/project progress`)
1. Run `dart scripts/project_status.dart` to update all dashboards

### Issue (`/project issue [title]`)
1. Generate `projects/issues/YYYY-MM-DD-[title_snake_case].md` from `projects/templates/issue_template.md`
2. Update `projects/issues/README.md` Active Issues table:
   ```
   | [Title](./YYYY-MM-DD-file.md) | YYYY-MM-DD | Type | Priority | Status |
   ```
3. Update `projects/README.md` Active Issues section
4. Run `dart scripts/project_status.dart`

## Status Labels
- Documented — Issue created, awaiting approval
- Analyzing — In analysis phase
- In Progress — Being implemented
- Resolved — Completed
