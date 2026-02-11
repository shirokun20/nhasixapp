---
name: run-codegen
description: Run Flutter build_runner to regenerate code (freezed, json_serializable)
disable-model-invocation: true
---

# Run Codegen

This skill runs the Flutter build_runner command to regenerate code. This is necessary when you modify models annotated with @freezed or @JsonSerializable.

```bash
echo "Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs
```
