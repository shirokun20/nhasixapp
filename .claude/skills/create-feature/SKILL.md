---
name: create-feature
description: Scaffolds a complete Clean Architecture feature structure (Domain, Data, Presentation).
---

# Create Feature Skill

This skill automates the creation of a standard Clean Architecture feature module. It ensures separation of concerns from the start.

## Usage
`/create-feature [feature_name]`

**Example**: `/create-feature authentication`

## Actions

### 1. Execute Scaffolding
- **Input**: `feature_name` (string)
- **Steps**:
  1. Run `dart scripts/create_feature.dart [feature_name]`.
  2. Verify the output confirms successful creation.

### 2. Verify
Checks if the folders were created successfully.
