# 🚀 Installation & Setup

This guide will help you set up the NhentaiApp development environment and get the project running on your local machine.

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Development Environment Setup](#development-environment-setup)
- [Project Setup](#project-setup)
- [Running the Application](#running-the-application)
- [Build Configuration](#build-configuration)
- [Troubleshooting](#troubleshooting)

---

## 📋 Prerequisites

### **System Requirements**
- **Operating System**: macOS, Windows, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: At least 10GB free space
- **Internet**: Stable internet connection for dependencies

### **Required Software**

#### **1. Flutter SDK**
```bash
# Check if Flutter is installed
flutter --version

# Required version
Flutter 3.5.4 or higher
Dart 3.5.4 or higher
```

**Installation:**
- **macOS**: `brew install flutter` or download from [flutter.dev](https://flutter.dev)
- **Windows**: Download from [flutter.dev](https://flutter.dev) and add to PATH
- **Linux**: Download and extract, add to PATH

#### **2. Android Studio / VS Code**
**Android Studio** (Recommended):
- Download from [developer.android.com](https://developer.android.com/studio)
- Install Flutter and Dart plugins
- Configure Android SDK (API 21+ required)

**VS Code** (Alternative):
- Download from [code.visualstudio.com](https://code.visualstudio.com)
- Install Flutter and Dart extensions

#### **3. Android SDK**
```bash
# Required components
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android API 21+ (Android 5.0)
- Android Emulator (for testing)
```

#### **4. Git**
```bash
# Check if Git is installed
git --version

# Install if needed
# macOS: brew install git
# Windows: Download from git-scm.com
# Linux: sudo apt install git
```

---

## 🛠️ Development Environment Setup

### **1. Verify Flutter Installation**
```bash
# Run Flutter doctor to check setup
flutter doctor

# Expected output should show:
✓ Flutter (Channel stable, 3.5.4)
✓ Android toolchain - develop for Android devices
✓ Android Studio
✓ VS Code (if using)
✓ Connected device (if device/emulator is running)
```

### **2. Configure Android SDK**
```bash
# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk  # Windows

# Add to PATH
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### **3. Accept Android Licenses**
```bash
flutter doctor --android-licenses
# Accept all licenses by typing 'y'
```

### **4. Setup Android Emulator**
```bash
# List available AVDs
flutter emulators

# Create new AVD if none exists
flutter emulators --create --name pixel_4

# Launch emulator
flutter emulators --launch pixel_4
```

---

## 📱 Project Setup

### **1. Clone Repository**
```bash
# Clone the repository
git clone https://github.com/shirokun20/nhasixapp.git
cd nhasixapp

# Check current branch
git branch
# Should be on 'master' branch
```

### **2. Install Dependencies**
```bash
# Get Flutter dependencies
flutter pub get

# Verify dependencies are installed
flutter pub deps
```

### **3. Generate Required Files**
```bash
# Generate mock files for testing
flutter packages pub run build_runner build

# If you encounter conflicts, use:
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### **4. Database Setup**
The app uses SQLite for local storage. The database will be created automatically on first run.

**Database Location:**
- **Android**: `/data/data/com.example.nhasixapp/databases/app.db`
- **Development**: `data/app.db` (in project root)

### **5. Configuration Files**

**pubspec.yaml** - Already configured with all required dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  flutter_bloc: ^9.1.1
  dio: ^5.7.0
  sqflite: ^2.3.0
  # ... other dependencies
```

**android/app/build.gradle** - Minimum SDK configuration:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Android 5.0+
        targetSdkVersion 34
    }
}
```

---

## 🏃‍♂️ Running the Application

### **1. Check Connected Devices**
```bash
# List available devices
flutter devices

# Expected output:
Android SDK built for x86_64 (mobile) • emulator-5554 • android-x64 • Android 11 (API 30)
```

### **2. Run in Debug Mode**
```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d emulator-5554

# Run with hot reload enabled (default in debug)
# Press 'r' to hot reload
# Press 'R' to hot restart
# Press 'q' to quit
```

### **3. Run with Different Flavors**
```bash
# Debug mode (default)
flutter run --debug

# Profile mode (for performance testing)
flutter run --profile

# Release mode (optimized)
flutter run --release
```

### **4. Development Features**
- **Hot Reload**: Press `r` to reload changes instantly
- **Hot Restart**: Press `R` to restart the app
- **Debug Console**: View logs and debug information
- **Flutter Inspector**: Available in Android Studio/VS Code

---

## 🔧 Build Configuration

### **1. Debug Build**
```bash
# Build debug APK
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### **2. Release Build**
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### **3. Build Optimization**
```bash
# Build with obfuscation (recommended for release)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Build with specific target platform
flutter build apk --release --target-platform android-arm64
```

---

## 🧪 Testing Setup

### **1. Run Unit Tests**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/presentation/blocs/content/content_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

### **2. Run Integration Tests**
```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d emulator-5554
```

### **3. Code Analysis**
```bash
# Analyze code for issues
flutter analyze

# Fix formatting issues
dart format lib/ test/

# Check for unused dependencies
flutter pub deps --style=compact
```

---

## 🔧 IDE Configuration

### **Android Studio Setup**
1. **Install Plugins**:
   - Flutter
   - Dart
   - Bloc (for BLoC pattern support)

2. **Configure Run Configuration**:
   - Go to Run → Edit Configurations
   - Add new Flutter configuration
   - Set entry point to `lib/main.dart`

3. **Enable Flutter Inspector**:
   - View → Tool Windows → Flutter Inspector
   - Useful for widget tree debugging

### **VS Code Setup**
1. **Install Extensions**:
   - Flutter
   - Dart
   - Bloc
   - Flutter Widget Snippets

2. **Configure launch.json**:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "nhasixapp",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart"
    }
  ]
}
```

3. **Configure settings.json**:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false
}
```

---

## 🐛 Troubleshooting

### **Common Issues**

#### **1. Flutter Doctor Issues**
```bash
# Issue: Android licenses not accepted
flutter doctor --android-licenses

# Issue: Android SDK not found
export ANDROID_HOME=/path/to/android/sdk

# Issue: Flutter not in PATH
export PATH=$PATH:/path/to/flutter/bin
```

#### **2. Build Issues**
```bash
# Issue: Gradle build failed
cd android && ./gradlew clean
cd .. && flutter clean && flutter pub get

# Issue: Dependency conflicts
flutter pub deps --style=compact
flutter pub upgrade

# Issue: Build tools version
# Update android/app/build.gradle:
compileSdkVersion 34
buildToolsVersion "34.0.0"
```

#### **3. Emulator Issues**
```bash
# Issue: Emulator won't start
flutter emulators --create --name test_device

# Issue: Device not detected
adb devices
adb kill-server && adb start-server

# Issue: Performance issues
# Increase emulator RAM in AVD Manager
# Enable hardware acceleration
```

#### **4. Database Issues**
```bash
# Issue: Database locked
# Stop the app and restart
flutter clean
flutter run

# Issue: Migration errors
# Delete database file and restart
rm data/app.db
flutter run
```

#### **5. Network Issues**
```bash
# Issue: Cloudflare bypass not working
# Check internet connection
# Try different DNS (8.8.8.8, 1.1.1.1)
# Restart app to retry bypass

# Issue: HTTP requests failing
# Check device/emulator internet connection
# Verify API endpoints are accessible
```

### **Performance Issues**
```bash
# Issue: Slow build times
flutter clean
flutter pub get
# Use --no-sound-null-safety if needed

# Issue: App crashes on startup
# Check logs:
flutter logs
# Or in Android Studio: View → Tool Windows → Logcat

# Issue: Memory leaks
# Use Flutter Inspector to check widget tree
# Profile memory usage:
flutter run --profile
```

### **Development Tips**
1. **Use Hot Reload**: Press `r` for quick changes
2. **Check Logs**: Use `flutter logs` for debugging
3. **Clear Cache**: Run `flutter clean` when in doubt
4. **Update Dependencies**: Regular `flutter pub upgrade`
5. **Profile Performance**: Use `flutter run --profile`

---

## 📚 Next Steps

After successful setup:

1. **Explore Architecture**: Read [Clean Architecture Overview](Clean-Architecture-Overview)
2. **Understand State Management**: Check [BLoC State Management](BLoC-State-Management)
3. **Learn Testing**: Review [Testing Strategy](Testing-Strategy)
4. **Contribute**: Follow [Contributing Guidelines](Contributing-Guidelines)

---

## 🆘 Getting Help

If you encounter issues:

1. **Check Documentation**: Review this wiki thoroughly
2. **Search Issues**: Check GitHub issues for similar problems
3. **Flutter Community**: Visit [flutter.dev/community](https://flutter.dev/community)
4. **Stack Overflow**: Tag questions with `flutter` and `dart`
5. **Create Issue**: Use our [Bug Report Template](Bug-Report-Template)

---

**Last Updated**: July 30, 2025  
**Author**: NhentaiApp Development Team