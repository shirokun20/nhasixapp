# 📱 NhentaiApp - Flutter Clone
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![18+](https://img.shields.io/badge/Age_Restriction-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

> **⚠️ AGE RESTRICTION WARNING**  
> **This application is intended for users 18 years of age and older only.**  
> **The content accessed through this application may contain mature themes and is not suitable for minors.**  
> **By using this application, you confirm that you are at least 18 years old and legally permitted to access such content in your jurisdiction.**

A comprehensive Flutter Android application that serves as a clone of nhentai.net, built with **Clean Architecture** and modern Flutter development practices. This app provides an enhanced mobile experience for browsing, reading, and managing manga/doujinshi content with offline capabilities.

## 🚀 Features

### 📖 Core Reading Experience
- **Content Browsing** - Browse latest, popular, and random content
- **Advanced Search** - Filter by tags, artists, characters, language, and more
- **Manga Reader** - Smooth reading experience with zoom, pan, and navigation
- **Multiple Reading Modes** - Single page, continuous scroll, dual page support
- **Reading Progress** - Track reading history and progress automatically

### 💾 Offline & Storage
- **Favorites System** - Organize favorites with custom categories
- **Download Manager** - Download content for offline reading with queue management
- **Reading History** - Track reading progress and statistics
- **Offline Reading** - Access downloaded content without internet

### 🎨 Customization
- **Multiple Themes** - Light, Dark, and AMOLED themes with custom color schemes
- **Reader Settings** - Customize reading direction, page transitions, and controls
- **Grid Layouts** - Adjustable grid columns for different screen orientations
- **Content Filtering** - Blacklist tags and customize content visibility

### 🔧 Advanced Features
- **Cloudflare Bypass** - Automatic bypass of website protection
- **Web Scraping** - Direct content extraction from HTML
- **Background Downloads** - Continue downloads in background
- **Statistics Dashboard** - Reading statistics and analytics
- **Backup & Sync** - Export/import user data and settings

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── 📁 core/                    # Core utilities and configuration
│   ├── config/                 # App configuration
│   ├── constants/              # App constants and themes
│   ├── di/                     # Dependency injection setup
│   ├── routing/                # Navigation and routing
│   └── utils/                  # Utility functions
├── 📁 data/                    # Data layer
│   ├── datasources/            # Remote and local data sources
│   ├── models/                 # Data models and DTOs
│   └── repositories/           # Repository implementations
├── 📁 domain/                  # Domain layer (Business Logic)
│   ├── entities/               # Core business entities
│   ├── repositories/           # Repository interfaces
│   ├── usecases/               # Business use cases
│   └── value_objects/          # Value objects for type safety
├── 📁 presentation/            # Presentation layer
│   ├── blocs/                  # BLoC state management
│   ├── pages/                  # Screen implementations
│   └── widgets/                # Reusable UI components
└── main.dart                   # Application entry point
```

## 🛠️ Tech Stack

### **Core Framework**
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language

### **Offline-First Strategy**
- **Intelligent Caching** - 6-hour cache expiration with automatic refresh
- **Fallback Mechanisms** - Cache → Remote → Cache fallback pattern
- **Error Handling** - Comprehensive error handling with graceful degradation
- **Performance Optimization** - Database transactions and memory management

### **Data Models**
- **ContentModel** - Content entity with database serialization
- **TagModel** - Tag entity with relationship management
- **DownloadStatusModel** - Download progress tracking
- **HistoryModel** - Reading history with statistics

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

### **LocalDataSource Capabilities**
- **Content Operations**: Cache, get, search with pagination
- **Tag Management**: Tag relationships and filtering
- **Favorites System**: Categories and batch operations
- **Download Tracking**: Status monitoring and queue management
- **History Management**: Reading progress and statistics
- **User Preferences**: Settings and customization storage
- **Database Optimization**: Transactions, indexes, and cleanup

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

### ✅ **Completed Tasks**
- [x] **Task 1**: Project structure and core dependencies setup
- [x] **Task 2**: Core domain layer implementation
  - [x] Domain entities and value objects
  - [x] Repository interfaces
  - [x] Use cases with comprehensive business logic
- [x] **Task 3**: Data layer foundation (Week 1)
  - [x] Repository implementations with offline-first architecture
  - [x] Local data sources with SQLite integration (EXCELLENT implementation!)
  - [x] Remote data sources with web scraping capabilities
  - [x] Data models with entity conversion
  - [x] Caching strategy and error handling
- [x] **Task 4.1**: Enhanced SplashBloc implementation ✨
  - [x] Comprehensive state management for app initialization
  - [x] Cloudflare bypass integration with proper error handling
  - [x] Network connectivity validation and retry mechanisms
  - [x] Enhanced UI with loading states and progress indicators
  - [x] Comprehensive unit testing with mocking
- [x] **Task 4.2**: ContentBloc for content management ✨
  - [x] Advanced pagination with infinite scrolling
  - [x] Pull-to-refresh functionality with SmartRefresher
  - [x] Comprehensive state management (loading, loaded, error)
  - [x] LocalDataSource integration ready
  - [x] Complete testing suite (10 unit + 8 integration tests)
  - [x] Real nhentai.net connection verification
- [x] **Task 4.3**: SearchBloc for advanced search functionality ✨
  - [x] Advanced search with comprehensive filter support (query, tags, artists, language, category)
  - [x] Search history management with persistent storage (max 50 items, FIFO)
  - [x] Debounced search with 500ms delay for performance optimization
  - [x] Real-time tag suggestions with debounced requests
  - [x] Complex filter combinations and state management
  - [x] Comprehensive testing suite (38+ tests across unit, real API, and integration)

### ✅ **Recently Completed**
- [x] **Task 4**: Core BLoC state management (Week 2) - ✅ COMPLETED
  - [x] **Task 4.1**: SplashBloc untuk initial loading ✅
    - [x] Cloudflare bypass logic with comprehensive flow
    - [x] Loading states and error handling with retry mechanisms
    - [x] Navigation after bypass success
    - [x] Network connectivity validation
  - [x] **Task 4.2**: ContentBloc untuk content management ✅
    - [x] Pagination support with infinite scrolling
    - [x] Loading, loaded, error states with proper transitions
    - [x] Pull-to-refresh functionality with SmartRefresher
    - [x] Advanced content management (sort, search, popular, random, tags)
  - [x] **Task 4.3**: SearchBloc untuk advanced search ✅
    - [x] Advanced search with comprehensive filter support
    - [x] Search history functionality with persistent storage
    - [x] Debounced search with 500ms delay optimization
    - [x] Real-time tag suggestions with performance optimization

### 🚧 **In Progress**
- [ ] **Task 5**: Core UI components (Week 3)

### 📅 **Upcoming Tasks** (12-week roadmap)
- [ ] **Task 6**: Reader functionality (Week 4)
- [ ] **Task 7**: Favorites & download system (Week 5)
- [ ] **Task 8**: Settings & preferences (Week 6)
- [ ] **Task 9**: Advanced features (Week 7)
- [ ] **Task 10**: Performance optimization & testing (Week 8)
- [ ] **Task 11**: Polish & deployment preparation (Week 9)
- [ ] **Task 12**: Documentation & learning resources (Week 10)

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

*Screenshots will be added as development progresses*

## 🤝 Contributing

This project follows Clean Architecture principles and uses BLoC for state management. When contributing:

1. Follow the established architecture patterns
2. Write comprehensive tests for new features
3. Update documentation for significant changes
4. Follow Dart/Flutter style guidelines

## ⚖️ Legal Notice

**AGE RESTRICTION:** This application is strictly intended for users who are 18 years of age or older. The content accessed through this application contains mature themes and adult material that is not suitable for minors.

This application is created for educational purposes and personal use only. It demonstrates modern Flutter development practices and Clean Architecture implementation. Users are responsible for:
- Verifying they meet the minimum age requirement (18+) in their jurisdiction
- Complying with applicable laws and terms of service of content sources
- Using the application responsibly and legally

By downloading, installing, or using this application, you acknowledge and confirm that you are at least 18 years old and legally permitted to access adult content in your location.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- BLoC library maintainers for excellent state management
- Clean Architecture principles by Robert C. Martin
- Open source community for the fantastic packages used

---

## 📊 Project Statistics

- **Architecture**: Clean Architecture with 3 layers
- **State Management**: BLoC Pattern with comprehensive testing
- **Dependencies**: 45+ carefully selected packages
- **Test Coverage**: Unit tests with mocking for critical components
- **Development Progress**: 42% complete (5/12 tasks)
- **Estimated Development Time**: 12 weeks (1 task per week)
- **Target Platform**: Android
- **Minimum SDK**: Android API 21+ (Android 5.0)
- **Latest Achievement**: Complete BLoC state management system with SplashBloc, ContentBloc, and SearchBloc ✨

---

**Built with ❤️ using Flutter and Clean Architecture**

---

## 🌐 Other Languages

- [English](README.md) ← You are here
- [Bahasa Indonesia](README_ID.md)