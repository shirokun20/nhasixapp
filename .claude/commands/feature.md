# Create Feature

Scaffold a complete Clean Architecture feature module structure.

## Usage
`/feature $ARGUMENTS`

## Steps

1. Run the scaffolding script:
   ```bash
   dart scripts/create_feature.dart $ARGUMENTS
   ```
2. Verify output confirms successful creation
3. Check that the following structure was created:
   ```
   lib/features/$ARGUMENTS/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   ├── data/
   │   ├── models/
   │   ├── datasources/
   │   └── repositories/
   └── presentation/
       ├── bloc/
       ├── pages/
       └── widgets/
   ```
