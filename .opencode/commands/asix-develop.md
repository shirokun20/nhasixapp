---
description: Full development workflow - analysis, plan, implement, complete
subtask: true
parallel:
  - command: asix-new-feature
    arguments: $ARGUMENTS
return:
  - /asix-plan-feature $ARGUMENTS
  - /asix-start-feature $ARGUMENTS
  - /asix-complete-feature $ARGUMENTS
---
# Full Feature Development

This command orchestrates the complete feature development workflow:

1. **Analysis** → Create analysis document
2. **Planning** → Create implementation plan  
3. **Implementation** → Build the feature
4. **Completion** → Finalize and move to success

## Feature Request
> $ARGUMENTS

This will guide you through all 4 phases automatically.
