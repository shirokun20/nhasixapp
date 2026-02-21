# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.1.1+5] - 2026-02-21

### 📝 Ringkas (Summary)
- **Version:** Bumped to 1.1.1+5
- **Perubahan:** Minor fixes and alignment with configuration files

---

## [1.1.0+4] - 2026-02-21

### ✨ Ditambahkan (Added)
- **Start.io Ads Integration:** Menambahkan dukungan iklan tipe _Banner_, _Interstitial_, dan _Rewarded Video_ dengan *method channel* Native Kotlin demi menopang server dan operasional aplikasi.
- **Deteksi AdGuard & Private DNS:** Sistem proaktif yang akan memperingatkan pengguna apabila ada aplikasi pemblokir DNS yang berjalan, sekaligus memotivasi untuk menonaktifkan AdBlocker (atau beralih ke premium) untuk mendukung developer.
- **Global AdGuard Blocker Watcher:** Pop-up Private DNS yang wajib (_non-bypassable_) kini diimplmentasikan secara global. Pop-up ini akan sigap menyela di layar mana pun pengguna berada apabila aplikasi baru saja di-_resume_ dari latar belakang dan AdGuard masih menyala.

### 🐛 Diperbaiki (Fixed)
- **Perbaikan Header Reader:** Memperbaiki malfungsi auto-hide *Header / AppBar* pada navigasi _Reader Screen_ sehingga Header kini otomatis muncul kembali dengan lancar kala pembaca menggulir (scroll) layar ke atas.
- **Perbaikan Penomoran Chapter:** Mengganti angka indeks (1, 2, 3..) urutan bab yang membingungkan dengan Ikon Buku universal di _Detail Screen_ maupun _Daftar Bab_, sehingga lebih akurat dan elegan apalagi bila penomoran asli sumbernya melompat/acak (_newest-first_ order). 
- **Pre-loading Interstitial Ads:** Menghaluskan alur transisi dari _Feed_ (Home) ke _Detail Screen_ tanpa efek _freeze_ (membeku) sekalipun iklan Start.io tertahan koneksi yang lambat.
- **Perbaikan Path Download:** Menyempurnakan mekanisme _fallback_ alamat (_base URL_) pengunduhan servis _updater_ aplikasi.

### 🎨 Peningkatan UI/UX (Improvements)
- **KomikTap Brand Identity:** Mengaplikasikan warna _brand_ oranye terang ciri khas KomikTap pada UI keseluruhan (baik di _Light Mode_ maupun _Dark Mode_) serta memperbarui ikon aplikasi secara selaras.
- **Penyederhanaan UI Kartu:** Melakukan perampingan tampilan kartu komik (_Content Card_) dengan me-nonaktifkan (_disable_) lambang bendera bahasa (_language flag_) beserta penghitung halaman untuk estetika beranda yang lebih lega.
- **Penyederhanaan UI Download:** Menghapus fungsi seleksi rentang (_range selection_) yang tidak efisien dari menu tombol Download demi memangkas _flow_ pengguna.

---

## [1.0.1] - 2026-02-17

### 🐛 Bug Fixes

#### Chapter Navigation
- **Fixed chapter navigation bug in KomikTap**: Corrected prevUrl/nextUrl mapping to match proper navigation semantics
  - Next button now correctly navigates to newer chapters
  - Previous button navigates to older chapters
  - Last chapter (e.g., Chapter 24) now properly disables next button instead of incorrectly showing Chapter 23
  - First chapter properly disables previous button
- **Implemented ChapterData entity**: Replaced index-based navigation with API-based navigation data
  - Added `prevChapterId` and `nextChapterId` fields for reliable chapter detection
  - KomiktapScraper and CrotpediaScraper now extract navigation data from HTML
  - Fixes bug where next button appeared on last chapter

#### Reader Performance
- **Enhanced image loading performance**: Fixed image re-loading issue when scrolling
  - Increased ListView cache extent from 1000px to 10000px
  - Added `AutomaticKeepAliveClientMixin` to keep images alive in memory
  - Enabled `addAutomaticKeepAlives` and `addRepaintBoundaries` for better performance
  - Images now stay cached when scrolling up/down, eliminating unnecessary reloads

#### Localization
- **Updated reader navigation to Indonesian**: Changed navigation labels for better UX
  - "End of Chapter" → "Akhir Halaman"
  - "What would you like to do?" → "Apa yang ingin Anda lakukan?"
  - "Next Chapter" → "Chapter Berikutnya"
  - "Prev Chapter" → "Chapter Sebelumnya"
  - "Back" → "Kembali ke Detail Content"
  - Changed icon from `arrow_back` to `info_outline` to avoid confusion with back navigation
  - Improved layout from Row to Column with full-width buttons for better accessibility

### 🎨 UI/UX Improvements
- **Reader Navigation Page**: Redesigned with vertical layout
  - Full-width buttons for easier interaction
  - Conditional rendering (buttons only show when chapters are available)
  - Icon + text aligned horizontally for clarity
  - Primary button highlighted for next chapter action

### 🛠 Refactoring
- **ReaderState optimization**: Simplified chapter navigation logic
  - Replaced `parentContent` and `allChapters` with unified `chapterData`
  - Updated progress calculation methods
  - Cleaned up redundant chapter navigation logic
  - StreamAppBar now uses `chapterData` for navigation

### 📦 Legal & Branding
- **Updated app name in legal documents**: Changed references from Kuron to KomikTap
- **Centralized premium feature checks**: Refactored to use LicenseService
- **Relocated legal documents**: Moved FAQ and legal files to `assets/` with unit tests
- **Updated StartApp application ID**: Configured for KomikTap branding

### 🔧 Other Changes
- **Version bump**: Updated to 1.0.1+3
- **Removed favorites from drawer**: Simplified navigation items
- **Update download URL**: Changed to centralized portal download page

---

## [1.0.0] - 2026-02-08

### 🚀 Official Release & Rebranding
- **Rebranding**: Application renamed from **Kuron** to **KomikTap**.
- **New Update System**: Switched to a centralized portal for reliable updates.
- **Universal APK**: Optimized universal APK for all devices.

### 🛠 Improvements & Fixes
- **Reader Experience**: Fixed image distortion on devices with different aspect ratios (e.g., Infinix vs POCO).
- **Storage**: Migrated app base folder to `komikTapXKuron` for better organization.
- **Smart History**: Enabled auto-cleanup for history.
- **Monetization**: Updated ad configuration.

## [0.9.9] - 2026-01-28

### 🚀 Pre-Release Polish
- **Git Migration**: Migrated local packages (`kuron_core`, etc.) to proper git structure.
- **Cleanup**: Removed legacy documentation and unused assets.
- **Stability**: Repository restructuring in preparation for v1.0.0.

## [0.9.0] - 2026-01-26

### 🚀 New Features
- **KomikTap Support**: Added full support for **KomikTap** source, including:
  - Latest updates feed
  - Search functionality
  - Detail view with chapter list
  - Reading capability
- **Dynamic Offline Filters**: 
  - Offline content filter chips are now dynamically generated from configuration.
  - Added support for source-specific coloring (Purple for Crotpedia, Orange for KomikTap, Red for nHentai).
- **Source Labels**: Added colored source labels to download items for easy identification.

### 🛠 Improvements
- **Configuration**: moved hardcoded UI elements to `assets/configs/` for flexibility.
- **Search Logic**: Improved search result prioritization logic.
- **Error Handling**: Enhanced error messages with localization support (EN, ID, ZH).

---

## [0.8.0] - 2026-01-15

### 🚀 Features & UX
- **Tag Pagination**: 
  - Implemented pagination for tag-based searches on **Nhentai** (`/tag/{slug}/?page={N}`).
  - Implemented pagination for genre browsing on **Crotpedia** (`/baca/genre/{slug}/page/{N}/`).
- **Nhentai Smart Search**:
  - Direct navigation to gallery detail page when inputting numeric ID (Gallery ID) in Nhentai search.
  - Skips search results step for faster access to known IDs.
  - Automatic normalization of numeric IDs (removes leading zeros).
- **Crotpedia Account Integration**:
  - Added login functionality for Crotpedia to access all chapters.
  - Source-aware account status in App Drawer.

### 🎨 Rebranding
- **APK Naming**: Updated APK output filename to `kuron_[version]_[date]_[abi].apk` to match the brand identity.

---

## [0.7.2] - 2025-12-28

### 🔒 Privacy & Safety
- **Blur Thumbnails by Default**: Thumbnail blur enabled by default for child safety protection.
- **Blur Toggle Setting**: New setting in Display section to enable/disable blur effect.

### 📋 Legal & Info
- **Terms and Conditions**: New menu in About screen with user agreement.
- **Privacy Policy**: New menu explaining data handling practices.
- **FAQ**: Frequently asked questions with helpful information.
- **Hybrid Loading**: Legal docs fetched from GitHub with local fallback for offline access.
- **2-Language Support**: All legal content available in English and Indonesian.

### Added
- `markdown_widget` package for rendering markdown content in bottom sheets.
- `LegalContentService` with GitHub fetch, caching, and local fallback.
- `LegalContentSheet` bottom sheet widget with loading/error states.

---

## [0.7.1] - 2025-12-21

### 🛠 Fixes & Improvements
- **Detail Screen Image**:
  - Replaced unreliable cover image source with **Page 1 Full Image** (guaranteed high definition & availability).
  - Fixed logic so Detail cover works **Offline** by checking downloaded pages.
- **Sync Notification Context**:
  - Notification `System Sync` now only appears during explicit storage scans (Import/Auto Scan).
  - Silenced notifications for internal DB refreshes and App Startup.
- **Image Fallback**:
  - Implemented robust fallback to Page 1 Thumbnail (`1t`) for list items if main cover fails.

## [0.7.0] - 2025-12-21

### 🌟 Rebranding & UI Overhaul
- **Rebranded to "Kuron"**: New name, identity, and premium feel.
- **Premium UI Redesign**:
  - **Glassmorphism App Drawer**: Animated logo, gradients, and modern navigation.
  - **Paper-Like Light Theme**: Completely revamped light mode with warm, comfortable tones.
  - **Refined Settings**: Card-based layouts, better controls, and cleaner typography.
- **New About Screen**: Interactive branding, changelog summary, and direct links.

### Added
- **In-App Update Checker**: Automatically checks GitHub releases for updates.
- **Animated Logos**: Pulsing animations in Drawer and About screen.
- **Sort By UI**: Improved sorting chips and dropdowns styling.

### Fixed
- **Localization Bug**: Fixed app name reverting to old name in some locales.
- **Text Visibility**: Fixed invisible text in light theme hardcoded colors.
- **Navigation Transitions**: Unified smooth fade transitions across all screens.

## [0.6.2] - 2025-12-21

### Fixed
- Fixed API sorting issue where "Popular" filters were ignored and defaulted to "Newest"
- Fixed content reader attempting to load items with 0 images (now forces fresh fetch)
- Improved cache validation to prevent using incomplete content data from search results

## [0.6.1] - 2025-12-14

### Fixed
- Fixed offline content bugs where deleted files persisted in list
- Fixed notification permission issues causing missing notifications
- Fixed build error related to desugaring libs

## [0.6.0] - 2025-12-12

### Added
- **Export Library**: Export database and content files to shareable folder with progress dialog
- **Import from Backup**: Manual import button to sync backup folder content to database
- **Database-First Loading**: Offline screen now loads from database first (faster startup)
- **Sync to Database**: Automatic sync of backup folder content with duplicate handling

### Changed
- Offline screen no longer auto-scans file system on startup (uses database)
- Delete now works for backup-scanned items (passes content path directly)
- AppBar redesigned with Import/Export buttons instead of permission debug button

### Fixed
- Delete offline content not working for items from backup folder
- Path lookup failing for content not in database

### Technical
- New `ExportService` for library export and sharing
- `OfflineSearchCubit` now uses `UserDataRepository.getAllDownloads()`
- `OfflineContentManager.syncBackupToDatabase()` with smart duplicate handling
- `OfflineContentManager.deleteOfflineContent()` now accepts optional `contentPath`

---

## [0.5.0] - 2025-11-26

### Added
- Initial release with core features
- Home screen with content discovery
- Immersive reader mode
- Smart search with filters
- App Disguise mode
- Offline downloads with bulk management
- History and favorites
- Dark/Light theme with Material 3

---

## Version History

| Version | Date | Type | Description |
|:--------|:-----|:-----|:------------|
| 0.6.0 | 2025-12-12 | Feature | Offline export & database-first |
| 0.5.0 | 2025-11-26 | Release | Initial public release |
