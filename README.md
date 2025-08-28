# 📱 NhasixApp - Enhanced Mobile Reading Experience

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![18+](https://img.shields.io/badge/Age_Restriction-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Beta](https://img.shields.io/badge/Status-BETA_v0.2.0-blue?style=for-the-badge&logo=android&logoColor=white)

> **⚠️ AGE RESTRICTION WARNING**  
> **This application is intended for users 18 years of age and older only.**  
> **The content accessed through this application may contain mature themes and is not suitable for minors.**  
> **By using this application, you confirm that you are at least 18 years old and legally permitted to access such content in your jurisdiction.**

## 🚀 **BETA v0.2.0 - NOW AVAILABLE!**

**NhasixApp** is a comprehensive Flutter Android application that provides an enhanced mobile reading experience with **70% faster content loading**, smart offline capabilities, and modern UI improvements. Built with **Clean Architecture** and optimized for performance.

### 📱 **Download Beta APKs**

| **APK Type** | **Size** | **Target Devices** | **Download** |
|--------------|----------|-------------------|--------------|
| **ARM64** ⭐ | 24MB | Modern devices (2019+) | `nhasix_0.2.0_20250828_release_arm64_optimized.apk` |
| **ARM32** | 22MB | Older devices (2015-2019) | `nhasix_0.2.0_20250828_release_arm_optimized.apk` |
| **Universal** | 22MB | All devices | `nhasix_0.2.0_20250828_release_universal_optimized.apk` |

> **Recommended**: Download ARM64 APK for best performance on modern Android devices

## 🚀 Features

### 🆕 Recent Updates

- [x] Comprehensive dependency injection setup using get_it for better scalability
- [x] Added external dependencies like SharedPreferences and Connectivity
- [x] Configured core utilities including Logger, Dio HTTP client, CacheManager, TagDataManager
- [x] Setup data sources for remote scraping, anti-detection, cloudflare bypass, and local database
- [x] Implemented repository registrations for content, user data, reader settings, and offline content
- [x] Registered use cases for content, favorites, downloads, and history management
- [x] Configured BLoCs for splash, home, content, search, and download features
- [x] Setup Cubits for network, settings, detail, filter data, reader, offline search, and favorites
- [x] Updated MultiBlocProvider configuration for all BLoCs and Cubits
- [x] Updated dependencies in pubspec.yaml to support new features
- Comprehensive dependency injection setup using get_it for better scalability
- Added external dependencies like SharedPreferences and Connectivity
- Core utilities configured: Logger, Dio HTTP client, CacheManager, TagDataManager
- Data sources for remote scraping, anti-detection, cloudflare bypass, and local database
- Repository implementations for content, user data, reader settings, and offline content
- Use cases for content, favorites, downloads, and history management
- BLoCs for splash, home, content, search, and download features
- Cubits for network, settings, detail, filter data, reader, offline search, and favorites
- Updated MultiBlocProvider configuration for all BLoCs and Cubits
- Updated dependencies in pubspec.yaml to support new features

## 🚀 Features

## ✨ **NEW in BETA v0.2.0**

### 🚀 **Performance Breakthroughs**
- **70% faster content loading** with smart image preloader
- **Optimized APK builds** - 3 variants for different device architectures
- **Enhanced pagination** with intelligent prefetching
- **Reduced app size** with code optimization

### 🔒 **Privacy & Security**
- **Enhanced download privacy** with `.nomedia` file protection
- **Private gallery** - downloads won't appear in system gallery
- **Secure storage** with improved file management

### � **UI/UX Improvements**
- **Download progress highlighting** - visual feedback for active downloads
- **Improved search experience** with better navigation
- **Modern pagination** with smoother transitions
- **Enhanced reader interface** with gesture improvements

### 🎯 **Smart Features**
- **Intelligent image preloading** - next pages load while you read
- **Range-based downloads** - download specific page ranges
- **Background download management** with progress tracking
- **Optimized memory usage** for better performance

---

## 🎯 **Key Features**

### 📚 **Core Reading Experience**
- **Clean, modern interface** optimized for mobile reading
- **High-quality image rendering** with zoom and pan support
- **Full-screen reading mode** for immersive experience
- **Smooth page transitions** with gesture controls

### 🔍 **Advanced Search & Discovery**
- **Powerful search engine** with tag and category filters
- **Advanced filtering** by popularity, date, and tags
- **Smart recommendations** based on reading history
- **Bookmark management** with offline access

### � **Offline & Download Features**
- **Full offline reading** - download for reading without internet
- **Range downloads** - download specific pages or chapters
- **Private downloads** - content hidden from system gallery
- **Download progress tracking** with visual indicators
- **Background downloads** - continue browsing while downloading

### 🎨 **User Experience**
- **Responsive design** that works on all screen sizes
- **Dark/Light theme** support with system preference detection
- **Gesture navigation** - swipe, pinch, and tap controls
- **Reading progress tracking** with automatic bookmarks

## 🛠️ **Technical Architecture**

### 🏗️ **Clean Architecture Implementation**
```
📁 lib/
├── 🎯 presentation/     # UI Layer (Widgets, Pages, Bloc)
├── 🏢 domain/          # Business Logic (Entities, Use Cases)
├── 💾 data/            # Data Layer (Repositories, Data Sources)
├── 🔧 core/            # Core Utilities (DI, Constants, Errors)
├── 🌐 services/        # External Services (API, Storage)
└── 🛠️ utils/           # Helper Functions and Extensions
```

### 📱 **Tech Stack**
- **Framework**: Flutter 3.24+ with Dart 3.5+
- **State Management**: Flutter Bloc with Cubit
- **Architecture**: Clean Architecture with MVVM
- **Storage**: SharedPreferences + SQLite (sqflite)
- **Network**: HTTP with custom interceptors
- **Image Processing**: Optimized with native caching
- **Performance**: Smart preloading and pagination

### 🚀 **Performance Optimizations**
- **Smart Image Preloader**: 70% faster loading with intelligent prefetching
- **Optimized APK Builds**: Separate ARM64/ARM32/Universal variants
- **Memory Management**: Efficient image caching and disposal
- **Background Processing**: Non-blocking downloads and operations

---

## 📥 **Installation**

### 📱 **Method 1: APK Installation (Recommended)**

1. **Download the appropriate APK**:
   - **ARM64** (most modern devices): `nhasix_0.2.0_20250828_release_arm64_optimized.apk`
   - **ARM32** (older devices): `nhasix_0.2.0_20250828_release_arm_optimized.apk`
   - **Universal** (all devices): `nhasix_0.2.0_20250828_release_universal_optimized.apk`

2. **Enable installation from unknown sources**:
   - Go to **Settings → Security → Unknown Sources**
   - Or **Settings → Apps → Special Access → Install Unknown Apps**

3. **Install the APK**:
   - Tap the downloaded APK file
   - Follow the installation prompts
   - Grant necessary permissions when requested

### 🛠️ **Method 2: Build from Source**

#### **Prerequisites**
- Flutter SDK 3.24+
- Android Studio with Android SDK 34+
- Dart 3.5+
- Git

#### **Quick Build**
```bash
# Clone the repository
git clone https://github.com/yourusername/nhasixapp.git
cd nhasixapp

# Get dependencies
flutter pub get

# Build optimized release APK
chmod +x build_optimized.sh
./build_optimized.sh
```

#### **Development Setup**
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for release
flutter build apk --release
```

---

## 🎮 **Usage Guide**

### 🔍 **Basic Navigation**
1. **Browse Content**: Swipe through the main feed
2. **Search**: Use the search bar with filters and tags
3. **Read**: Tap any item to start reading
4. **Download**: Long press or use download button for offline access

### 📥 **Download Features**
- **Full Download**: Download entire content for offline reading
- **Range Download**: Select specific pages to download
- **Private Mode**: Downloads are hidden from system gallery (`.nomedia`)
- **Progress Tracking**: Visual indicators show download status

### ⚙️ **Settings & Customization**
- **Theme**: Switch between light and dark modes
- **Reading Preferences**: Adjust zoom, transition effects
- **Download Location**: Choose storage directory
- **Privacy Settings**: Configure download visibility

---

## 🧪 **Beta Testing & Feedback**

### 🐛 **Known Issues**
- Some rare devices may experience slower loading on first startup
- Download progress may not update in real-time on older Android versions
- Search filters may need refinement for very specific queries

### 📝 **Beta Feedback**
We're actively seeking feedback to improve NhasixApp! Please report:
- **Performance issues** on your specific device
- **UI/UX suggestions** for better usability
- **Feature requests** that would enhance your experience
- **Bugs or crashes** with device/Android version details

**Contact**: Create an issue on GitHub or reach out via project discussions.

---

## 📜 **License & Legal**

### 📋 **License**
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### ⚖️ **Legal Disclaimer**
- This application is for **educational and personal use only**
- Users are responsible for compliance with local laws and regulations
- The developers do not host or distribute any content through this application
- All content accessed through this app comes from publicly available sources
- **Age restriction: 18+ only** - This app accesses mature content

### 🤝 **Respect for Content Creators**
- We encourage users to support original content creators
- This app is designed to enhance the reading experience, not replace official channels
- Consider supporting artists and creators through official platforms

---

## 👥 **Contributing**

### 🤝 **How to Contribute**
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### 📋 **Contribution Guidelines**
- Follow Flutter/Dart best practices
- Maintain clean architecture principles
- Add tests for new features
- Update documentation as needed
- Ensure code is formatted with `dart format`

---

## 🆘 **Support & FAQ**

### ❓ **Frequently Asked Questions**

**Q: Why won't the app install?**
A: Enable "Install from Unknown Sources" in Android settings. Make sure you downloaded the correct APK for your device architecture.

**Q: Downloads are not showing in my gallery?**
A: This is intentional! Downloads are private (`.nomedia` protection). Access them through the app's download section.

**Q: The app is slow on my device?**
A: Try the ARM32 APK for older devices, or clear the app cache in Android settings.

**Q: Can I use this on iOS?**
A: Currently Android only. iOS support may be considered for future releases.

### 🛠️ **Troubleshooting**
- **Slow loading**: Check your internet connection and try restarting the app
- **Download issues**: Verify storage permissions and available space
- **Search problems**: Clear app cache or try different search terms
- **Crashes**: Report with your device model and Android version

---

## 🔮 **Roadmap**

### 🚀 **Upcoming Features (v0.3.0)**
- [ ] **Cloud sync** for bookmarks and reading progress
- [ ] **Advanced reader features** - night mode, reading themes
- [ ] **Improved recommendations** with AI-powered suggestions
- [ ] **Social features** - reading lists and community sharing
- [ ] **Performance optimizations** - even faster loading times

### 🎯 **Long-term Goals**
- [ ] **iOS support** - native iOS app
- [ ] **Web version** - PWA for desktop/tablet use
- [ ] **Advanced customization** - themes, layouts, gestures
- [ ] **Offline-first architecture** - complete offline functionality

---

## 📞 **Contact & Links**

### 🔗 **Project Links**
- **GitHub Repository**: [NhasixApp](https://github.com/yourusername/nhasixapp)
- **Issue Tracker**: [Report Bugs](https://github.com/yourusername/nhasixapp/issues)
- **Discussions**: [Community Forum](https://github.com/yourusername/nhasixapp/discussions)

### 📧 **Contact**
- **Developer**: [Your Name]
- **Email**: your.email@example.com
- **Project Discussions**: GitHub Discussions tab

---

## 🎉 **Acknowledgments**

### 🙏 **Special Thanks**
- **Flutter Team** - for the amazing framework
- **Community Contributors** - for feedback and suggestions
- **Beta Testers** - for helping improve the app
- **Open Source Libraries** - that made this project possible

### 📚 **Built With**
- [Flutter](https://flutter.dev/) - UI framework
- [Bloc](https://bloclibrary.dev/) - State management
- [Get It](https://pub.dev/packages/get_it) - Dependency injection
- [Sqflite](https://pub.dev/packages/sqflite) - Local database
- [HTTP](https://pub.dev/packages/http) - Network requests

---

<div align="center">

**🌟 Star this repository if you found it helpful! 🌟**

Made with ❤️ using Flutter

**⚠️ Remember: This app is for users 18+ only ⚠️**

</div>
- **Error Handling** - Comprehensive error handling with graceful degradation
- **Performance Optimization** - Database transactions and memory management

### **Data Models (Simplified)**
- **DownloadStatusModel** - Download progress tracking with title and cover
- **HistoryModel** - Reading history with title and cover for display
- **UserPreferences** - User settings and preferences
- **SearchFilter** - Advanced search filtering

## 🎯 Recent Implementation: ContentBloc with Advanced Features

### **Key Features Implemented**
- **🔄 Advanced State Management** - Loading, loaded, error states with pagination support
- **📱 Pull-to-Refresh** - SmartRefresher integration for seamless content updates
- **♾️ Infinite Scrolling** - Automatic load more with performance optimization
- **🎯 Content Management** - Complete content browsing with caching strategy
- **🛡️ Error Handling** - Comprehensive error handling with retry mechanisms
- **💾 LocalDataSource Integration** - Full SQLite database operations ready
- **🧪 Comprehensive Testing** - 10/10 unit tests + 8/8 integration tests passing

### **ContentBloc State Flow**
```
ContentInitial → ContentLoading → ContentLoaded (with pagination)
                              ↘ ContentError (with retry)
ContentRefreshing → ContentLoaded (pull-to-refresh)
ContentLoadingMore → ContentLoaded (infinite scroll)
```

### **LocalDataSource Capabilities (Simplified)**
- **Favorites System**: Simple ID + cover URL storage
- **Download Tracking**: Basic status monitoring with title and cover
- **History Management**: Reading progress with title and cover for display
- **User Preferences**: Settings and customization storage
- **Search History**: Recent search queries management
- **Database Optimization**: Lightweight schema with 5 tables only

## 🛠️ Tech Stack

### **Core Framework**
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language

### **Architecture & State Management**
- **Clean Architecture** - Separation of concerns
- **BLoC Pattern** - Reactive state management with `flutter_bloc`
- **Get It** - Dependency injection
- **Equatable** - Value equality and immutability

### **Navigation & Routing**
- **Go Router** - Declarative routing with deep linking support

### **Data & Storage**
- **SQLite** (`sqflite`) - Local database for caching and offline data
- **SharedPreferences** - Simple key-value storage for settings
- **Path Provider** - File system access
- **Offline-First Architecture** - Intelligent caching with fallback mechanisms

### **Networking & Web Scraping**
- **Dio** - HTTP client for API calls
- **HTML Parser** - HTML parsing for web scraping
- **WebView Flutter** - Cloudflare bypass integration
- **Connectivity Plus** - Network connectivity monitoring

### **Image Handling**
- **Cached Network Image** - Image caching and loading
- **Photo View** - Image zoom and pan functionality
- **Image** - Image processing and manipulation

### **UI & User Experience**
- **Flutter Staggered Grid View** - Masonry grid layouts
- **Pull to Refresh** - Pull-to-refresh functionality
- **Flutter Slidable** - Swipe actions
- **Badges** - Notification badges
- **Shimmer** - Loading skeleton animations
- **Lottie** - Advanced animations

### **Background & Notifications**
- **Flutter Local Notifications** - Local push notifications
- **Wakelock Plus** - Keep screen awake during reading

### **File Management**
- **File Picker** - File selection for import/export
- **Share Plus** - Content sharing functionality
- **Open File** - Open downloaded files

### **Utilities**
- **Logger** - Comprehensive logging system
- **Permission Handler** - Runtime permissions
- **Crypto** - Cryptographic operations
- **Intl** - Internationalization support
- **Package Info Plus** - App information
- **Device Info Plus** - Device information

### **Testing & Development**
- **BLoC Test** - Testing utilities for BLoC state management
- **Mockito** - Mock generation for unit testing
- **Build Runner** - Code generation for mocks and other build tasks
- **Flutter Test** - Core testing framework
- **Flutter Lints** - Code quality and style enforcement

## 📋 Development Progress

### ✅ **Completed Major Features (~70%)**
- [x] **Core Architecture**: Clean Architecture with BLoC/Cubit pattern
- [x] **Search System**: SearchBloc, FilterDataScreen, TagDataManager, Matrix Filter Support
- [x] **Reader System**: ReaderCubit with 3 reading modes, settings persistence, progress tracking
- [x] **UI Framework**: Comprehensive widgets with modern design (ColorsConst, TextStyleConst)
- [x] **Navigation**: Go Router with deep linking and parameter passing
- [x] **Database**: SQLite with search state persistence and reader settings
- [x] **Web Scraping**: NhentaiScraper with anti-detection and TagResolver

### ✅ **Completed Tasks (1-7)**
- [x] **Task 1**: Project structure and core dependencies setup
- [x] **Task 2**: Core domain layer implementation
- [x] **Task 3**: Data layer foundation (Simplified)
- [x] **Task 4**: Core BLoC state management
  - [x] SplashBloc, ContentBloc, SearchBloc, HomeBloc
  - [x] DetailCubit, ReaderCubit, FilterDataCubit
- [x] **Task 5**: Core UI components
  - [x] AppMainDrawerWidget, AppMainHeaderWidget, ContentListWidget
  - [x] PaginationWidget, SortingWidget, FilterDataSearchWidget
- [x] **Task 6**: Advanced search flow
  - [x] SearchScreen, FilterDataScreen, TagDataManager
  - [x] Matrix Filter Support, state persistence
- [x] **Task 7**: Reader functionality
  - [x] ReaderScreen with 3 reading modes
  - [x] Settings persistence, progress tracking, gesture navigation
- [x] **Task 8**: Favorites and download system
  - [x] FavoritesScreen with FavoriteCubit
  - [x] DownloadBloc with queue system
  - [x] Offline reading capabilities

### 🎯 **Next Priority Features (30% Remaining)**
- [ ] **Task 9**: Settings and preferences
  - [ ] SettingsScreen with SettingsCubit
  - [ ] Theme customization and backup functionality
- [ ] **Task 10**: Advanced features and network management
  - [ ] NetworkCubit for connectivity monitoring
  - [ ] Tag management and history statistics
- [ ] **Task 11**: Performance optimization and testing
  - [ ] Memory management and real device testing
  - [ ] Project cleanup and documentation
- [ ] **Task 12**: UI polish and accessibility
  - [ ] Animations, loading skeletons, accessibility features
- [ ] **Task 13**: Deployment preparation
  - [ ] App branding, build configuration, release testing

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.4)
- Dart SDK (>=3.5.4)
- Android Studio / VS Code
- Android SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nhasixapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Google Play Store)
flutter build appbundle --release
```

## 🧪 Testing

The project includes comprehensive testing with mocking for reliable unit tests:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/presentation/blocs/splash/splash_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# Generate mock files
flutter packages pub run build_runner build

# Analyze code
flutter analyze
```

### **Test Coverage**
- **SplashBloc Tests** - Complete state management testing with mocked dependencies
- **ContentBloc Tests** - 10/10 unit tests + 8/8 integration tests passing
- **Repository Tests** - Data layer testing with offline-first scenarios
- **Use Case Tests** - Business logic validation
- **Integration Tests** - End-to-end testing for critical flows
- **Real Connection Tests** - Verified nhentai.net connectivity

## 📱 Screenshots

### 🏠 Home & Details
<div align="center">
  <img src="screenshots/flutter_01.png" width="250" alt="Home Screen"/>
  <img src="screenshots/flutter_02.png" width="250" alt="Content Grid"/>
  <img src="screenshots/flutter_03.png" width="250" alt="Content List"/>
</div>

### 🔍 Reading, Detail & Reading Mode
<div align="center">
  <img src="screenshots/flutter_04.png" width="250" alt="Search Screen"/>
  <img src="screenshots/flutter_05.png" width="250" alt="Advanced Filters"/>
  <img src="screenshots/flutter_06.png" width="250" alt="Tag Selection"/>
</div>

### 📖 Reading, Side Menus, Search & Filters
<div align="center">
  <img src="screenshots/flutter_07.png" width="250" alt="Content Detail"/>
  <img src="screenshots/flutter_08.png" width="250" alt="Reader Mode"/>
  <img src="screenshots/flutter_09.png" width="250" alt="Reader Settings"/>
</div>

### ⚙️ Filters & Search
<div align="center">
  <img src="screenshots/flutter_10.png" width="250" alt="App Settings"/>
  <img src="screenshots/flutter_11.png" width="250" alt="Theme Options"/>
</div>

> **Note**: Screenshots showcase the current development progress with modern Material Design 3 UI components and responsive layouts.

## 📚 Development References

This project includes comprehensive reference materials for development and testing:

### **HTML Reference Files**
