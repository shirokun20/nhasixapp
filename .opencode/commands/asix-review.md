---
description: Full code review with multi-model validation
subtask: true
parallel:
  - /asix-review-arch
  - /asix-review-style
return:
  - Synthesize all review findings. Create a prioritized action list.
  - If critical issues found, help fix them. Otherwise, approve the code.
---
# Code Review

Perform a comprehensive code review for NhasixApp.

## Target
> $ARGUMENTS

## Review Focus Areas

1. **Clean Architecture Compliance**
   - Domain layer independence
   - Proper dependency direction
   - Use case single responsibility

2. **Code Style**
   - Naming conventions (snake_case files, PascalCase classes)
   - No print/debugPrint (use logger)
   - Proper imports ordering

3. **State Management**
   - Cubit extends BaseCubit
   - Immutable states
   - Proper error handling

4. **Performance**
   - const widgets
   - ListView.builder usage
   - No unnecessary rebuilds

## Output Format

```markdown
# Code Review: [Target]

## Summary
[Brief overview]

## Issues

### Critical 🔴
- Issue + location + fix

### Major 🟠
- Issue + location + fix

### Minor 🟡
- Issue + location + fix

## Good Practices ✅
- What's done well

## Action Items
1. [Prioritized fix]
```

Load skill: `skill({ name: "clean-arch" })`
