# 📱 NhasixApp - Enhanced Mobile Reading Experience

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)
[![18+](https://img.shields.io/badge/Age_Restriction-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)](#)
[![RELEASE](https://img.shields.io/badge/Status-RELEASE_v0.7.2-green?style=for-the-badge&logo=android&logoColor=white)](#)

> [!TIP]  
> **[🇮🇩 Baca dalam Bahasa Indonesia](README_ID.md)**

**Kuron** (formerly NhasixApp) provides a **70% faster** mobile reading experience with privacy at its core. Built with **Clean Architecture** and optimized for performance, it features smart offline reading, App Disguise mode, and a modern Material 3 design.

---

## 📥 **Download Latest Release**

[📦 **Get v0.7.2**](https://github.com/shirokun20/nhasixapp/releases/tag/v0.7.2)

| Variant | Size | Best For | Status |
|:-------|:----:|:---------|:------:|
| **ARM64** | 24MB | Modern Devices (2019+) | ✅ Available |
| **ARM32** | 22MB | Older Devices (2015-2018) | ✅ Available |

---

## ✨ **Key Features**

### 🎯 **Reading & Discovery**
- **Immersive Reader**: Full-screen mode, smooth page transitions, and high-quality rendering.
- **Smart Search**: Advanced filtering by tags, popularity, and date.
- **Auto-Bookmark**: Never lose your place; progress tracks automatically.

### 🛡️ **Privacy & Offline**
- **App Disguise**: Mask the app as a Calculator, Notes, or Weather app.
- **Private Downloads**: Content is hidden from the system gallery (`.nomedia`).
- **Offline First**: Full offline capability with background downloading and bulk management.
- **Export Library**: Backup your entire library with database and files to share or restore.
- **Blur Thumbnails**: Privacy-focused blur on thumbnails, enabled by default.

### 🎨 **Performance & UX**
- **Fast Loading**: Smart image preloading makes reading 70% faster.
- **Adaptive UI**: Responsive design with Dark/Light modes and Material 3 aesthetics.
- **Battery Friendly**: Optimized resource usage with Wakelock and efficient caching.

---

## 📱 **Screenshots**

<details>
<summary>🖼️ Click to view screenshots (18+ content warning)</summary>

<table>
  <tr>
    <td align="center"><b>Home & Feed</b></td>
    <td align="center"><b>Detail & Content</b></td>
    <td align="center"><b>Immersive Reader</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/flutter_02.png" width="250" alt="Home Screen"/></td>
    <td><img src="screenshots/flutter_13.png" width="250" alt="Detail Screen"/></td>
    <td><img src="screenshots/flutter_12.png" width="250" alt="Reader Mode"/></td>
  </tr>
  <tr>
    <td align="center"><b>Search & Filters</b></td>
    <td align="center"><b>Settings & Privacy</b></td>
    <td align="center"><b>Offline & Downloads</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/flutter_04.png" width="250" alt="Search Filters"/></td>
    <td><img src="screenshots/flutter_06.png" width="250" alt="Settings"/></td>
    <td><img src="screenshots/flutter_11.png" width="250" alt="Downloads"/></td>
  </tr>
</table>

</details>

---

## 🛠️ **Tech Stack**

| Layer | Technologies |
|:------|:-------------|
| **Core** | Flutter 3.24+, Dart 3.5+ |
| **Arch** | Clean Architecture, BLoC Pattern, GetIt (DI) |
| **Data** | SQLite (Offline), SharedPreferences, Dio (Network) |
| **UI/UX** | CachedNetworkImage, PhotoView, Shimmer, Lottie |
| **System** | Local Notifications, Wakelock Plus, Permission Handler |

---

## 🚀 **Quick Start**

### **Installation**
1. **Download APK** from [Releases](https://github.com/shirokun20/nhasixapp/releases).
2. **Enable Unknown Sources** in Settings > Security.
3. **Install** and enjoy!

### **Build from Source**
```bash
git clone https://github.com/shirokun20/nhasixapp.git
cd nhasixapp
flutter pub get
flutter run
```

---

## 🆘 **Support**

**FAQ**
- **Can't Install?** Enable "Unknown Sources" and check your architecture (ARM64 vs ARM32).
- **Missing Images?** Check your internet or clear cache.
- **Hidden Downloads?** They are private by design. View them inside the app.

---

## 📜 **License & Legal**

**⚠️ 18+ Content Warning** • **Educational Use Only** • **MIT License**

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
We strongly support content creators; please support official releases whenever possible.
