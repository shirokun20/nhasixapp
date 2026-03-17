# Run Codegen

Run Flutter build_runner to regenerate code for Freezed and JsonSerializable.

## When to Use
After creating or editing any file with `@freezed` or `@JsonSerializable` annotations.

## Command
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Watch Mode (continuous)
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Reminders
- NEVER edit `*.g.dart` or `*.freezed.dart` files directly
- NEVER write `copyWith`, `==`, `hashCode`, `toString`, or `fromJson/toJson` by hand if Freezed can generate them
- Always run codegen immediately after modifying annotated files
