---
description: Complete feature and move to success - Phase 4 of workflow
subtask: true
return:
  - Verify all tests pass and code is clean.
  - Congratulate the user and summarize what was built!
---
# Complete Feature

You are finalizing a feature in NhasixApp.

## Feature to Complete
> $ARGUMENTS

## Your Task

1. **Verify completion checklist**:
   - [ ] All tasks in progress document are `[x]` completed
   - [ ] `flutter test` passes
   - [ ] `flutter analyze` is clean
   - [ ] Code follows conventions
   - [ ] No `print` statements (use logger)

2. **Run verification commands**:
   ```bash
   flutter analyze
   flutter test
   ```

3. **Update progress document** with completion summary:
   ```markdown
   ## Completion Summary
   
   **Completed**: [Today's date]
   **Status**: ✅ Completed
   
   ### Deliverables
   - Feature X implemented
   - Y unit tests added
   
   ### Files Created/Modified
   - `lib/features/[feature]/...`
   ```

4. **Move to success-plan**:
   ```bash
   mv projects/onprogress-plan/$ARGUMENTS projects/success-plan/$ARGUMENTS
   ```

5. **Register in DI** if not done:
   - Add to `core/di/injection_container.dart`

6. **Update any routes** if needed

## Final Checks
- No TODO comments left
- No debug code
- Proper error handling
- Documentation updated
