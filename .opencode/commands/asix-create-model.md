---
description: Generate model from entity with all required methods
subtask: true
return:
  - Show the generated model code.
  - Remind to run build_runner if using freezed.
---
# Create Model

Generate a data model that extends an entity.

## Entity/Model Name
> $ARGUMENTS

## Model Template

```dart
import 'package:nhasixapp/features/[feature]/domain/entities/[name].dart';

class [Name]Model extends [Name] {
  const [Name]Model({
    required super.id,
    required super.field1,
    required super.field2,
  });
  
  /// Create model from entity
  factory [Name]Model.fromEntity([Name] entity) {
    return [Name]Model(
      id: entity.id,
      field1: entity.field1,
      field2: entity.field2,
    );
  }
  
  /// Convert to entity
  [Name] toEntity() {
    return [Name](
      id: id,
      field1: field1,
      field2: field2,
    );
  }
  
  /// Create from JSON map
  factory [Name]Model.fromMap(Map<String, dynamic> map) {
    return [Name]Model(
      id: map['id'] as String,
      field1: map['field1'] as String,
      field2: map['field2'] as int,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field1': field1,
      'field2': field2,
    };
  }
  
  /// Create from JSON string
  factory [Name]Model.fromJson(String source) {
    return [Name]Model.fromMap(json.decode(source));
  }
  
  /// Convert to JSON string
  String toJson() => json.encode(toMap());
}
```

## Required Methods Checklist

- [ ] `.fromEntity()` - Create model from entity
- [ ] `.toEntity()` - Convert to entity
- [ ] `.fromMap()` - Create from JSON map
- [ ] `.toMap()` - Convert to JSON map
- [ ] `.fromJson()` - Create from JSON string (optional)
- [ ] `.toJson()` - Convert to JSON string (optional)

Load skill: `skill({ name: "clean-arch" })`
