# Contributing

Thanks for being willing to contribute to **Kuron**!

**Working on your first Pull Request?** You can learn how from this *free* series [How to Contribute to an Open Source Project on GitHub](https://kcd.im/pull-request)

## Architecture Overview

Kuron is built using **Clean Architecture** with a strict separation of layers:
- **Domain**: Pure Dart. Contains business logic, entities, and use cases. ZERO dependencies on Data/Presentation.
- **Data**: Implements domain interfaces, handles API calls, JSON parsing, and DB storage.
- **Presentation**: UI widgets, and BLoC/Cubit for state management. Depends only on Domain.

## Project Setup

1. Fork and clone the repository.
2. Use [FVM](https://fvm.app/) to ensure you are using the correct Flutter version.
3. Install dependencies and run code generation (we rely heavily on `freezed`, `json_serializable`, and `injectable`):
   ```bash
   fvm flutter pub get
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Create a branch for your PR: `git checkout -b feat/my-feature`

## Committing and Pushing changes

Please make sure your commits follow the [Conventional Commits](https://www.conventionalcommits.org/) format (e.g., `feat(ui): add new reader mode` or `fix(data): parser bug`).

## Help needed

Please check the [Issues](https://github.com/shirokun20/nhasixapp/issues) tab to find issues that need help.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
