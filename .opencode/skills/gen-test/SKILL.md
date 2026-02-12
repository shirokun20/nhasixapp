---
name: gen-test
description: Generate unit tests for a Dart class using mocktail and bloc_test
---

# Generate Tests

This skill generates a unit test file for the provided Dart class. It uses `mocktail` for mocking dependencies and `bloc_test` if the class is a Bloc/Cubit.

## Prompt

You are an expert Flutter Test Engineer. Your task is to write a comprehensive unit test for the file located at `{{file_path}}`.

### Context
- **Project**: Flutter Clean Architecture.
- **Libraries**: `flutter_test`, `bloc_test`, `mocktail`.
- **Style**: strict, explicit typing, clear descriptions.

### Steps
1.  **Analyze**: Read the content of `{{file_path}}` to understand its dependencies and logic.
2.  **Mock**: Identify dependencies that need to be mocked using `mocktail`.
3.  **Plan**: Determine the test cases (happy path, error cases, edge cases).
4.  **Generate**: Write the test file.
    - If the class is a `Bloc` or `Cubit`, use `bloc_test`.
    - If it's a Repository or UseCase, use standard `test` with mocked datasources/repositories.
    - Place the test file in the `test/` directory, mirroring the source structure (e.g., `lib/features/auth/login_cubit.dart` -> `test/features/auth/login_cubit_test.dart`).

### Output
- Output the full content of the generated test file.
- Ask the user for confirmation to write the file to the disk.
