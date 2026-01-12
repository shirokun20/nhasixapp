---
description: Start new feature workflow - creates analysis doc and guides through phases
subtask: true
return:
  - Review the analysis document created. Is there anything missing? Ask clarifying questions if needed.
  - Once analysis is complete, run /plan-feature to create the implementation plan.
---
# New Feature Analysis

You are starting the **Analysis Phase** for a new feature in NhasixApp.

## Feature Request
> $ARGUMENTS

## Your Task

1. **Create analysis document** at `projects/analysis-plan/$ARGUMENTS/`
   - Use kebab-case for folder name
   - Create `[feature-name]-analysis.md`

2. **Document the following**:
   - Overview of the feature
   - Current state (existing code if any)
   - Functional requirements
   - Non-functional requirements
   - Technical analysis (architecture impact)
   - Risks and considerations
   - Open questions

3. **Research the codebase** to understand:
   - Related existing features
   - Similar implementations
   - Dependencies needed

## Template Structure

```markdown
# [Feature] Analysis

**Date**: [Today's date]
**Status**: Analysis

## Overview
[Brief description]

## Current State
- [Existing implementation]
- [Related files]

## Requirements

### Functional Requirements
1. FR-01: [Requirement]

### Non-Functional Requirements  
1. NFR-01: [Requirement]

## Technical Analysis
- Architecture impact
- Dependencies
- Integration points

## Risks & Considerations
| Risk | Impact | Mitigation |
|------|--------|------------|

## Open Questions
- [ ] Question 1
```

Load skill for guidance: `skill({ name: "doc-workflow" })`
