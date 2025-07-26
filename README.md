# 📱 NhentaiApp - Flutter Clone

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

## 📋 Development Progress

### ✅ **Completed Tasks**
- [x] **Task 1**: Project structure and core dependencies setup
- [x] **Task 2**: Core domain layer implementation
  - [x] Domain entities and value objects
  - [x] Repository interfaces
  - [x] Use cases with comprehensive business logic

### 🚧 **In Progress**
- [ ] **Task 3**: Data layer foundation (Week 1)
- [ ] **Task 4**: Core BLoC state management (Week 2)
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

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 📱 Screenshots

*Screenshots will be added as development progresses*

## 🤝 Contributing

This project follows Clean Architecture principles and uses BLoC for state management. When contributing:

1. Follow the established architecture patterns
2. Write comprehensive tests for new features
3. Update documentation for significant changes
4. Follow Dart/Flutter style guidelines

## ⚖️ Legal Notice

This application is created for educational purposes and personal use only. It demonstrates modern Flutter development practices and Clean Architecture implementation. Users are responsible for complying with applicable laws and terms of service of content sources.

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
- **State Management**: BLoC Pattern
- **Dependencies**: 40+ carefully selected packages
- **Estimated Development Time**: 12 weeks (1 task per week)
- **Target Platform**: Android
- **Minimum SDK**: Android API 21+ (Android 5.0)

---

**Built with ❤️ using Flutter and Clean Architecture**