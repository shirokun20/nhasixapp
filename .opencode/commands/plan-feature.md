---
description: Create implementation plan from analysis - Phase 2 of workflow
subtask: true
return:
  - Validate the plan against the codebase. Check if the proposed architecture is correct.
  - If plan is solid, ask user if ready to start implementation with /start-feature
---
# Feature Planning

You are creating the **Implementation Plan** for a feature in NhasixApp.

## Feature to Plan
> $ARGUMENTS

## Your Task

1. **Read the analysis document** from `projects/analysis-plan/$ARGUMENTS/`

2. **Create planning document** at `projects/future-plan/$ARGUMENTS/`
   - Create `[feature-name]-plan.md`

3. **Design the architecture** following Clean Architecture:

### Domain Layer
- Entities needed
- Repository interfaces
- Use cases

### Data Layer  
- Models (extending entities)
- Data sources (remote/local)
- Repository implementations

### Presentation Layer
- Cubit/BLoC for state management
- Pages (screens)
- Widgets

4. **Create task breakdown** with estimates

5. **Define acceptance criteria**

## Template Structure

```markdown
# [Feature] Implementation Plan

**Date**: [Today's date]
**Status**: Planning
**Analysis Ref**: `projects/analysis-plan/[folder]/[file].md`

## Summary
[Implementation approach]

## Architecture Design

### Domain Layer
- [ ] Entity: [Name]
- [ ] Repository Interface: [Name]
- [ ] Use Case: [Name]

### Data Layer
- [ ] Model: [Name]
- [ ] Data Source: [Name]
- [ ] Repository Impl: [Name]

### Presentation Layer
- [ ] Cubit: [Name]
- [ ] Page: [Name]
- [ ] Widgets: [Names]

## Implementation Tasks
- [ ] Task 1
- [ ] Task 2

## Effort Estimate
| Phase | Hours |
|-------|-------|
| Domain | X |
| Data | X |
| Presentation | X |
| Testing | X |

## Acceptance Criteria
- [ ] Criterion 1
```

Load skills: `skill({ name: "clean-arch" })`, `skill({ name: "doc-workflow" })`
