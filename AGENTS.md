# Flutter NhasixApp - Agent Guidelines

## Build/Test Commands
- `flutter clean && flutter pub get` - Clean and install dependencies
- `flutter run --debug` - Run in debug mode
- `flutter test` - Run all tests
- `flutter test test/specific_test.dart` - Run single test file
- `flutter analyze` - Run static analysis/linting
- `flutter build apk --release` - Build release APK
- `./build_release.sh` - Build release with custom naming
- `dart run build_runner build` - Generate freezed/json_serializable code

## Code Style Guidelines
- **Imports**: Group by type: `package:flutter` → external packages → `core/` → `domain/` → `data/` → `presentation/`
- **Naming**: snake_case files, PascalCase classes, camelCase variables/methods, private fields prefixed with `_`
- **Models**: Data models extend domain entities, include `.fromEntity()`, `.toEntity()`, `.fromMap()`, `.toMap()` methods
- **Error Handling**: Use structured exception hierarchy (`NetworkException`, `ServerException`, etc.), categorize errors in BaseCubit
- **Documentation**: Class-level comments for all entities, repositories, and complex business logic
- **Architecture**: Clean Architecture with strict separation: `domain/` → `data/` → `presentation/`
- **State Management**: flutter_bloc for complex state, Cubit for simple local state, extend BaseCubit for error handling
- **Dependency Injection**: All dependencies registered in `core/di/service_locator.dart` using GetIt

## Development Focus Guidelines
- **Analysis Tasks**: For analysis and research tasks, create documentation in `projects/analysis-plan/[folder-name]/[file-name].md` to organize findings and insights. This is for reading material, studying errors, or documenting important events. **DO NOT change any code** during analysis phase.
- **Future Planning**: For future feature plans and ideas, document them in `projects/future-plan/[folder-name]/[file-name].md` for later implementation. This is for brainstorming and planning only. **DO NOT change any code** during planning phase.
- **Active Development**: Code changes are **ONLY** allowed when tasks are in `projects/onprogress-plan/[folder-name]/[file-name].md`. When moving from analysis-plan or future-plan to onprogress-plan, then start implementing code changes and update todos with `[x]` checkbox when completed.
- **Todo Management**: Before starting any task, **ALWAYS create a todo list first** to plan and break down the work. If new tasks or requirements are discovered during development, update the todo list immediately to maintain accurate tracking of all work items.
- **Follow On-Progress Plans**: Always follow the rules and guidelines specified in the `.md` files located in the `projects/onprogress-plan/[folder-name]/[file-name].md` folder to maintain focus on current development tasks and avoid distractions.
- **Project Completion**: When all tasks in a `projects/onprogress-plan/[folder-name]/` are completed, move the entire folder to `projects/success-plan/[folder-name]/` to archive the completed work.
- **File Update Policy**: For `.md` files in `projects/onprogress-plan/[folder-name]/[file-name].md`, only update them if urgent. Otherwise, only mark completed items with `[x]` checkbox.
- **Complex Task Support**: Always use MCP Sequential Thinking, Context7, and Docfork when encountering complex or difficult tasks. These tools serve as brainstorming aids and a second brain to help solve challenging problems.

## Git & Version Control Guidelines
- **MCP Git Integration**: Use MCP Git tools when requested for git operations (status, diff, commit, branch, log, etc.)
- **Commit Messages**: Follow conventional commits format: `type(scope): description`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`
  - Example: `feat(auth): add biometric login support`
  - Keep first line under 72 characters
- **Branch Strategy**:
  - `master` - production-ready code only
  - `develop` - integration branch for ongoing development
  - `feature/[name]` - new features (branch from develop)
  - `bugfix/[name]` - bug fixes (branch from develop)
  - `hotfix/[name]` - urgent production fixes (branch from master)
- **Pull Request Standards**:
  - Must pass all tests (`flutter test`) and analysis (`flutter analyze`)
  - Keep PRs focused and small (< 400 lines changed preferred)
  - Include description of changes and related issue numbers
  - Self-review code before requesting review
- **Best Practices**:
  - Commit frequently with meaningful messages
  - Never commit sensitive data (API keys, tokens, credentials)
  - Use `.gitignore` properly for build artifacts and IDE files
  - Pull latest changes before starting new work

## Performance Guidelines
- **Widget Optimization**:
  - Use `const` constructors for immutable widgets whenever possible
  - Keep `build()` methods pure and lightweight (< 60 lines)
  - Extract complex widgets into separate `StatelessWidget` or `StatefulWidget`
  - Use `RepaintBoundary` to isolate expensive repainting areas
- **List Performance**:
  - Always use `ListView.builder` or `GridView.builder` for dynamic/long lists
  - Never use `ListView(children: [...])` for large datasets
  - Implement pagination/lazy loading for datasets > 50 items
  - Use `itemExtent` or `prototypeItem` when items have fixed height
- **State Management**:
  - Minimize widget rebuilds with proper Bloc/Cubit selectors
  - Use `Consumer` widget's `child` parameter for static parts
  - Avoid rebuilding entire screen, target specific widgets only
- **Image & Asset Optimization**:
  - Compress images before adding to assets (target < 200KB per image)
  - Use `cached_network_image` for network images with proper caching
  - Use appropriate formats: WebP for photos, PNG for transparency, SVG for icons
  - Provide multi-resolution assets (1x, 2x, 3x) for raster images
- **Memory Management**:
  - Dispose controllers, streams, and subscriptions in `dispose()`
  - Use `AutomaticKeepAliveClientMixin` sparingly
  - Avoid memory leaks by canceling timers and listeners
- **Build Optimization**:
  - Use deferred loading for large features/libraries
  - Enable code obfuscation and tree-shaking in release builds
  - Profile with DevTools before optimizing (measure first!)

## Code Review Checklist
**Before Creating PR:**
- [ ] Code runs without errors locally
- [ ] All tests pass (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code follows project style guidelines
- [ ] No commented-out code or debug statements (`print`, `debugPrint` removed)
- [ ] Added/updated tests for new features or bug fixes
- [ ] Updated documentation if needed

**During Code Review:**
- [ ] Code is readable, maintainable, and self-explanatory
- [ ] No code duplication (follows DRY principle)
- [ ] Proper error handling implemented with try-catch where needed
- [ ] No hardcoded values (use constants or configuration)
- [ ] Performance implications considered (list builders, unnecessary rebuilds)
- [ ] Security considerations addressed (input validation, data encryption)
- [ ] Accessibility guidelines followed (semantic labels, contrast)
- [ ] Clean Architecture layers respected (domain ← data ← presentation)
- [ ] Dependency injection used properly (no direct instantiation)
- [ ] Meaningful variable/function names that explain intent

## UI/UX & Accessibility Guidelines
- **Responsive Design**:
  - Test on multiple screen sizes: small (320-375), medium (375-414), large (414+)
  - Use `MediaQuery` and `LayoutBuilder` for adaptive layouts
  - Avoid fixed pixel values, prefer relative sizing
  - Test both portrait and landscape orientations
- **Theming**:
  - Support both light and dark themes
  - Use centralized theme configuration in `core/config/`
  - Access theme via `Theme.of(context)`, never hardcode colors
  - Maintain consistent spacing, typography, and color palette
- **Loading & Error States**:
  - Always show loading indicators for async operations (> 300ms)
  - Display user-friendly error messages with actionable solutions
  - Provide retry mechanisms for failed operations
  - Show helpful empty states with call-to-action when no data
- **Accessibility**:
  - Add semantic labels to all images, icons, and interactive elements
  - Ensure minimum contrast ratio of 4.5:1 for text
  - Make touch targets at least 48x48 logical pixels
  - Support screen readers with `Semantics` widget
  - Test with TalkBack (Android) and VoiceOver (iOS)
  - Avoid relying solely on color to convey information
- **User Feedback**:
  - Provide immediate visual feedback for all user interactions
  - Use appropriate loading states (skeleton screens, shimmer effects)
  - Show success/error notifications with SnackBar or Dialog
  - Implement haptic feedback for important actions

## Documentation Standards
- **Code Documentation**:
  - Document WHY, not WHAT (code should be self-explanatory)
  - Add dartdoc comments (`///`) for all public classes, methods, and functions
  - Include parameter descriptions and return value explanations
  - Add examples in comments for complex methods
  - Use TODO comments with context: `// TODO(TICKET-123): Implement feature X`
- **Project Documentation**:
  - Keep `README.md` updated with setup instructions and architecture overview
  - Update `CHANGELOG.md` for every release with categorized changes
  - Document architecture decisions in dedicated files when needed
  - Maintain API documentation for all public interfaces
- **Inline Comments**:
  - Use comments to explain complex business logic or algorithms
  - Document workarounds and known limitations
  - Explain non-obvious decisions or trade-offs
  - Remove outdated comments when code changes

## Asset Management
- **Organization**:
  - Group assets by type: `assets/images/`, `assets/icons/`, `assets/json/`
  - Use descriptive, lowercase names with underscores: `user_profile_icon.png`
  - Organize by feature when appropriate: `assets/images/auth/`, `assets/images/home/`
- **Image Optimization**:
  - Compress all images before adding to project (use tools like TinyPNG)
  - Target < 200KB per image, < 100KB for icons
  - Remove EXIF data and unnecessary metadata
  - Use vector formats (SVG) for icons and simple graphics
- **Multi-Resolution Support**:
  - Provide 1x, 2x, 3x variants for raster images in `assets/` structure
  - Use Flutter's asset variant system for automatic resolution selection
  - Test on different density screens (mdpi, hdpi, xhdpi, xxhdpi)
- **Asset Declaration**:
  - Declare all assets in `pubspec.yaml` under `assets:` section
  - Use directory declarations for multiple assets: `assets/images/`
  - Keep `pubspec.yaml` organized and commented
- **Tools & Automation**:
  - Use `flutter_launcher_icons` for generating app icons
  - Use `flutter_native_splash` for splash screen generation
  - Automate asset optimization in build scripts when possible

## Release & Deployment Process
- **Versioning**:
  - Follow semantic versioning: `MAJOR.MINOR.PATCH+BUILD`
  - Update version in `pubspec.yaml`: `version: 1.2.3+45`
  - Increment MAJOR for breaking changes, MINOR for features, PATCH for fixes
  - Increment BUILD number for every release to stores
- **Pre-Release Checklist**:
  - [ ] All features tested and working
  - [ ] Update `version` in `pubspec.yaml`
  - [ ] Update `CHANGELOG.md` with release notes
  - [ ] Run full test suite (`flutter test`)
  - [ ] Run code analysis (`flutter analyze`)
  - [ ] Test release build on physical devices
  - [ ] Update `README.md` if needed
  - [ ] Create git tag: `git tag v1.2.3 && git push --tags`
- **Build Process**:
  - Use build scripts (`build_release.sh`, `build_optimized.sh`)
  - Build with obfuscation: `--obfuscate --split-debug-info=build/debug-info`
  - Test release APK/IPA thoroughly before publishing
  - Keep release builds for rollback purposes
- **Deployment Strategy**:
  - Use staged rollout: 10% → 25% → 50% → 100% of users
  - Monitor crash reports during rollout
  - Have rollback plan ready for critical issues
  - Use internal testing track before production
- **Post-Release**:
  - Monitor crash analytics for 24-48 hours
  - Track user feedback and ratings
  - Document known issues and workarounds
  - Plan hotfix if critical bugs discovered

## Monitoring & Debugging Guidelines
- **Logging Standard**:
  - **ALWAYS use `logger` package** (`/sourcehorizon/logger`) as the standard logging solution
  - Configure logger in `core/config/logger_config.dart`
  - Use appropriate log levels:
    - `logger.t()` - TRACE: Very detailed debug information
    - `logger.d()` - DEBUG: Development debugging info (not in production)
    - `logger.i()` - INFO: Important business logic flow, user actions
    - `logger.w()` - WARNING: Recoverable errors, deprecated usage
    - `logger.e()` - ERROR: Unrecoverable errors requiring attention
    - `logger.f()` - FATAL: Critical failures causing app crash
  - Include context in logs: `logger.i('User login successful', userId: user.id)`
  - Never log sensitive data (passwords, tokens, PII)
- **Error Tracking**:
  - Integrate Firebase Crashlytics or Sentry for production
  - Catch and report all unhandled exceptions
  - Add custom error metadata for better debugging
  - Track non-fatal errors for important flows
- **Analytics**:
  - Track critical user flows and feature usage
  - Monitor app performance metrics (startup time, frame rendering)
  - Track conversion rates for key user journeys
  - Respect user privacy and GDPR compliance
- **Debug Tools**:
  - Use Flutter DevTools for performance profiling
  - Enable debug paint for layout debugging during development
  - Use `debugPrint` sparingly, prefer `logger` package
  - Implement debug-only features with `kDebugMode` flag
- **Production Monitoring**:
  - Set up alerts for crash rate thresholds
  - Monitor API response times and error rates
  - Track app version adoption and update rates
  - Review logs daily for warnings and errors