---
description: Quick fix - analyze and fix a bug
subtask: true
return:
  - Verify the fix works. Run relevant tests.
  - If tests pass, summarize what was fixed.
---
# Quick Bug Fix

Quickly analyze and fix a bug in NhasixApp.

## Bug Description
> $ARGUMENTS

## Process

1. **Locate the issue**
   - Search codebase for relevant code
   - Identify the root cause

2. **Analyze impact**
   - What's affected?
   - Any related code?

3. **Implement fix**
   - Follow code conventions
   - Use logger for debugging
   - Add error handling if needed

4. **Test the fix**
   ```bash
   flutter test
   flutter analyze
   ```

## Guidelines

- Keep changes minimal and focused
- Don't refactor unrelated code
- Add comments if fix is non-obvious
- Update tests if behavior changes

## Git Commit Format
```
fix(scope): brief description

Detailed explanation of what was wrong and how it was fixed.
```
