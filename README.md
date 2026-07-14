![Kuron](https://socialify.git.ci/shirokun20/nhasixapp/image?custom_description=&description=1&font=Source+Code+Pro&forks=1&issues=1&logo=https://github.com/shirokun20/nhasixapp/blob/master/assets/icons/logo_app.png%3Fraw%3Dtrue&name=1&owner=1&pattern=Floating+Cogs&pulls=1&stargazers=1&theme=Auto)
# 📱 Kuron - Unofficial Nhentai Client

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)
[![18+](https://img.shields.io/badge/Age_Restriction-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)](#)
[![RELEASE](https://img.shields.io/badge/Status-RELEASE_v0.9.22%2B32-green?style=for-the-badge&logo=android&logoColor=white)](#)
[![Downloads](https://img.shields.io/github/downloads/shirokun20/nhasixapp/total?style=for-the-badge&logo=github&logoColor=white&color=007ec6)](https://github.com/shirokun20/nhasixapp/releases)
[![Hits](https://komarev.com/ghpvc/?username=shirokun20&repo=nhasixapp&style=for-the-badge&color=007ec6)](https://github.com/shirokun20/nhasixapp)
<a href="https://trakteer.id/shirokun20" target="_blank"><img src="https://img.shields.io/badge/Support_Me-Trakteer-be1e2d?style=for-the-badge&logo=ko-fi&logoColor=white" height="30"/></a>
[![Sponsor shirokun20](https://img.shields.io/badge/Sponsor-shirokun20-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/shirokun20)

> [!TIP]  
> **[🇮🇩 Baca dalam Bahasa Indonesia](README_ID.md)**

**Kuron** (formerly NhasixApp) provides a **70% faster** mobile reading experience with privacy at its core. Built with **Clean Architecture** and optimized for performance, it features smart offline reading, App Disguise mode, a modern Material 3 design, and support for **multiple content providers** including E-Hentai, HentaiNexus, and Hitomi.

---

## 📥 **Download Latest Release**

[📦 **Get v0.9.22+33**](https://github.com/shirokun20/nhasixapp/releases/tag/v0.9.23%2B33)

| Variant | Size | Best For | Status |
|:-------|:----:|:---------|:------:|
| **ARM64** | 80MB | Modern Devices (2019+) | ✅ Available |
| **ARM32** | 69MB | Older Devices (2015-2018) | ✅ Available |

---

## ✨ **Key Features**

### � **Nhentai Login, Sync & Comments**
- **Account Login**: Sign in with your nhentai account directly in the app (Drawer → Login).
- **CAPTCHA Solver**: Native Android WebView activity for smooth Turnstile / hCaptcha solving.
- **Online Favorites**: Sync favorites with your nhentai account — choose Offline, Online, or Both per gallery.
- **Tag Blacklist Sync**: Merge server-side nhentai blacklist with local rules; blured thumbnails across all feeds.
- **Submit Comments**: Logged-in users can write comments directly from gallery detail pages, with CAPTCHA fallback when needed.
- **Random Gallery**: Discover random content with one tap from the home screen.

### 💬 **Multi-Provider Support (v0.9.14)**
- **E-Hentai Gallery**: Full support with session adapter and per-page reader.
- **HentaiNexus**: XOR decryption adapter with image URL transformation.
- **Hitomi Support**: Fallback-safe registration for enhanced content breadth.
- **Smart Pagination**: Token-based & indexed pagination across all providers.

> ⚠️ **Premium Sources**: E-Hentai, HentaiNexus, Hitomi, and other third-party sources are **advanced/premium** and require manual installation via **Settings → Sources → Add via Link or Import ZIP**. nhentai is the default free source.

### 💬 **Community Interaction**
- **View & Submit Comments**: Read discussions and post replies directly on detail pages when logged in.
- **Modern UI**: Clean, card-based layout optimized for both Light & Dark modes.
- **Realtime Data**: Uses official API for reliable and fast comment loading.

### 🎯 **Reading & Discovery**
- **Immersive Reader**: Full-screen mode, smooth page transitions, and high-quality rendering.
- **Smart Search**: Advanced filtering by tags, popularity, and date.
- **Auto-Bookmark**: Never lose your place; progress tracks automatically.

### 🛡️ **Privacy & Offline**
- **App Disguise**: Mask the app as a Calculator, Notes, or Weather app.
- **Recent Apps Privacy**: Recent-apps preview is obscured automatically, with a stronger native fallback on Android 13+.
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

## 🔧 **Adding a Custom Source**

Kuron's source system is fully config-driven — no code changes required. Each source is a single JSON file that tells the app how to scrape or call an API.

> [!TIP]
> **Don't want to build from scratch?**
> You can install hundreds of community-built extensions directly from our official extensions repository!
> 
> 🔗 **[github.com/shirokun20/kuron-extensions](https://github.com/shirokun20/kuron-extensions)**
> 
> Simply copy the `manifest.json` link from that repository and paste it into **Settings → Sources → Add via Link**. Don't forget to star the repo and support the developer! ❤️

### Where to look

| Guide | Link |
|:------|:-----|
| Full guide (EN) | [docs/en/CONFIG-GUIDE.md](docs/en/CONFIG-GUIDE.md) |
| Full guide (ID) | [docs/id/CONFIG-GUIDE.md](docs/id/CONFIG-GUIDE.md) |
| Full guide (ZH) | [docs/zh/CONFIG-GUIDE.md](docs/zh/CONFIG-GUIDE.md) |

### Quick steps

1. **Write the config JSON** — create a JSON file describing how to scrape or call the target site's API. See the full guide below for selectors, reader, and auth details.
2. **Fill in selectors / endpoints** — use browser DevTools to inspect the target site.
3. **Create a manifest entry** — to make the source appear in Source Manager, register it via a `manifest.json` hosted online. Entry format:
   ```json
   {
     "id": "mysite",
     "version": "1.0.0",
     "url": "https://yourhost.com/config/mysite-config.json",
     "meta": {
       "displayName": "My Site",
       "description": "Short description",
       "contentType": "manga",
       "language": "en",
       "requiresAuth": false
     }
   }
   ```
4. **Install** — via **Settings → Sources → Add via Link** (paste manifest URL) or **Import ZIP**.
5. **Validate** — run `dart run kuron_generic:kuron_config_validate --help` to catch schema errors before testing.

> See [docs/en/CONFIG-GUIDE.md](docs/en/CONFIG-GUIDE.md) for the full walkthrough including reader nav, auth, decryption, and common pitfalls.

---

## 🆘 **Support**

**FAQ**
- **Can't Install?** Enable "Unknown Sources" and check your architecture (ARM64 vs ARM32).
- **Missing Images?** Check your internet or clear cache.
- **Hidden Downloads?** They are private by design. View them inside the app.

---

## ☕ **Support Developer**

If you love **Kuron** and want to support its development, you can sponsor me on GitHub or buy me a coffee! ☕  

[![Sponsor shirokun20](https://img.shields.io/badge/Sponsor-shirokun20-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/shirokun20)

You can also scan the QRIS below to donate:

<p align="center">
  <img src="assets/images/donation_qris.jpeg" width="300" alt="QRIS Donation" style="border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
</p>

> **Note:** Your support helps keep the servers running and the updates coming! 🚀

---

## 👥 Contributors

Thanks to all contributors who helped make kuron better!

[![Contributors](https://contrib.rocks/image?repo=shirokun20/nhasixapp&max=150&columns=15&anon=1&v=20260309)](https://github.com/shirokun20/nhasixapp/graphs/contributors)

---

## 📈 **Star History**

<div align="center">
  <a href="https://www.star-history.com/#shirokun20/nhasixapp&type=date&legend=top-left">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&theme=dark&legend=top-left" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&legend=top-left" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&legend=top-left" width="600"/>
    </picture>
  </a>
</div>

---

## 📜 **License & Legal**

**⚠️ 18+ Content Warning** • **Educational Use Only** • **MIT License**

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
We strongly support content creators; please support official releases whenever possible.
