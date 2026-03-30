---
name: project-workflow
description: Follow NhasixApp development workflow - analysis, planning, execution, completion phases
license: MIT
compatibility: opencode
metadata:
  category: workflow
  project: nhasixapp
---

# Project Workflow Skill for NhasixApp

This skill ensures you follow the strict 4-phase development workflow.

## Overview

The project uses a structured workflow in the `projects/` folder:

```
projects/
├── analysis-plan/      # Phase 1: Analysis only
├── future-plan/        # Phase 2: Planning only
├── onprogress-plan/    # Phase 3: Execution
└── success-plan/       # Phase 4: Completed
```

## Phase 1: Analysis

**Location**: `projects/analysis-plan/[feature-name]/`
**Status**: READ-ONLY - No code changes

### Steps:
1. Create folder: `projects/analysis-plan/my-feature/`
2. Create `plan.md` with analysis
3. Document findings without modifying code

### plan.md Template:
```markdown
# Analysis: Feature Name

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Current Code Analysis
- Affected files: 
  - `lib/domain/...`
  - `lib/data/...`
- Dependencies: 
  - Package A
  - Package B

## Technical Considerations
- Database changes needed: Yes/No
- API changes needed: Yes/No
- Breaking changes: Yes/No

## Risks
- Risk 1: Mitigation
- Risk 2: Mitigation

## Notes
Additional observations...
```

### Do NOT:
- ❌ Modify any code files
- ❌ Create new implementations
- ❌ Run code generation
- ❌ Update dependencies

### DO:
- ✅ Read and analyze existing code
- ✅ Document your findings
- ✅ Identify dependencies
- ✅ Note potential issues

## Phase 2: Planning

**Location**: `projects/future-plan/[feature-name]/`
**Status**: Design only - No code changes

### Steps:
1. Copy from analysis: `cp -r projects/analysis-plan/my-feature projects/future-plan/`
2. Update plan.md with detailed design
3. Create implementation checklist

### plan.md Template:
```markdown
# Plan: Feature Name

## Architecture Design

### Domain Layer
- [ ] Entity: `UserEntity`
- [ ] Repository Interface: `UserRepository`
- [ ] Use Cases:
  - `GetUserUseCase`
  - `UpdateUserUseCase`

### Data Layer
- [ ] Models:
  - `UserModel`
- [ ] Data Sources:
  - `UserRemoteDataSource`
  - `UserLocalDataSource`
- [ ] Repository Implementation:
  - `UserRepositoryImpl`

### Presentation Layer
- [ ] BLoC/Cubit: `UserCubit`
- [ ] States: `UserInitial`, `UserLoading`, `UserLoaded`, `UserError`
- [ ] Page: `UserPage`
- [ ] Widgets: `UserProfile`, `UserForm`

### Dependency Injection
- [ ] Register UseCases
- [ ] Register Repository
- [ ] Register DataSources

## UI/UX Design
- [ ] Mockups/wireframes
- [ ] Responsive breakpoints
- [ ] Theme integration
- [ ] Accessibility labels

## Testing Plan
- [ ] Unit tests for UseCases
- [ ] Widget tests for UI
- [ ] Integration tests

## Implementation Steps
1. [ ] Create domain layer
2. [ ] Create data layer
3. [ ] Create presentation layer
4. [ ] Configure DI
5. [ ] Write tests
6. [ ] Run analysis
```

### Do NOT:
- ❌ Write implementation code
- ❌ Modify existing files
- ❌ Run code generation

### DO:
- ✅ Plan architecture thoroughly
- ✅ Define all interfaces
- ✅ Plan UI/UX in detail
- ✅ Create comprehensive checklist

## Phase 3: Execution

**Location**: `projects/onprogress-plan/[feature-name]/`
**Status**: Code Allowed

### Steps:
1. Copy from planning: `cp -r projects/future-plan/my-feature projects/onprogress-plan/`
2. **CRITICAL**: Create Todo list first
3. Implement following checklist
4. Update plan.md with `[x]` for completed items

### Starting Execution:

```markdown
# Execution: Feature Name

## Todo List
- [x] Copy to onprogress-plan
- [ ] Setup domain layer
- [ ] Setup data layer
- [ ] Setup presentation layer
- [ ] Configure DI
- [ ] Write tests
- [ ] Run flutter analyze
- [ ] Run flutter test
- [ ] Move to success-plan
```

### Implementation Guidelines:

1. **Start with Todo List**
   - Use todo tool to create task list
   - Update status as you progress

2. **Use Tools Appropriately**
   - `MCP Sequential Thinking` for complex logic
   - `Context7` for documentation
   - `Docfork` for API references

3. **Follow Code Standards**
   - Clean Architecture (domain -> data -> presentation)
   - DI via GetIt
   - flutter_bloc or Cubit (extend BaseCubit)
   - snake_case files, PascalCase classes, camelCase vars
   - logger package only (.t to .f), NO print/debugPrint

4. **Update Plan**
   - Mark completed items with `[x]`
   - Add notes for any deviations
   - Document blockers or issues

### Do NOT:
- ❌ Skip the todo list
- ❌ Modify files not in plan
- ❌ Skip tests
- ❌ Ignore analysis errors

### DO:
- ✅ Mark tasks complete immediately
- ✅ Run analyze frequently
- ✅ Test incrementally
- ✅ Commit logical chunks

## Phase 4: Completion

**Location**: `projects/success-plan/[feature-name]/`
**Status**: Completed

### Steps:
1. Verify all checklist items complete
2. Run final checks:
   ```bash
   flutter analyze
   flutter test
   ```
3. Move folder: `mv projects/onprogress-plan/my-feature projects/success-plan/`
4. Update final plan.md with completion notes

### Final plan.md Template:
```markdown
# Completed: Feature Name

## Summary
Feature implemented successfully following Clean Architecture.

## What Was Implemented
- Domain layer with entities and use cases
- Data layer with models and repositories
- Presentation layer with BLoC and UI
- Comprehensive test coverage

## Files Created/Modified
- Created: 15 files
- Modified: 3 files
- Lines of code: ~500

## Testing
- Unit tests: 12 passed
- Widget tests: 8 passed
- Coverage: 85%

## Verification
- [x] flutter analyze: No issues
- [x] flutter test: All passing
- [x] Manual testing: Verified
- [x] Code review: Approved

## Notes
Any additional notes or learnings...
```

## Workflow Commands

```bash
# Start new feature
mkdir -p projects/analysis-plan/my-feature
touch projects/analysis-plan/my-feature/plan.md

# Move to planning
cp -r projects/analysis-plan/my-feature projects/future-plan/

# Move to execution
cp -r projects/future-plan/my-feature projects/onprogress-plan/

# Complete feature
mv projects/onprogress-plan/my-feature projects/success-plan/
```

## Common Mistakes

- ❌ Writing code in analysis phase
- ❌ Skipping planning phase
- ❌ Not creating todo list before execution
- ❌ Moving to success-plan before tests pass
- ❌ Not updating plan.md with progress

## When to Use

- Starting new features
- Bug fixes (follow same workflow)
- Refactoring projects
- Code reviews (verify workflow followed)
