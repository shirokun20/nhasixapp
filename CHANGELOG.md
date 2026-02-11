# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.9.11] - 2026-02-11

### 🚀 New Features
- **View Comments**:
  - Added ability to view comments on gallery detail pages.
  - Integration with **NHentai JSON API** for reliable comment data.
  - Robust handling of avatar URLs and comment formatting (Markdown).
  - Modern, card-based UI optimized for readability in both Light and Dark modes.

### 🛠 Improvements
- **Network Stability**:
  - Implemented `NativeAdapter` for Dio HTTP client to bypass Cloudflare TLS fingerprinting issues (`Connection reset by peer`).
  - Improved resilience of API requests and scraping fallbacks.
- **Architecture**:
  - Refactored `Comment` entity to `kuron_core` for better modularity across packages.
  - Cleaned up legacy scraping code in favor of API-first approach for comments.

### 🔧 Technical
- Updated `pubspec.yaml` to version `0.9.11+19`.
- Added unit tests for API model parsing and comment mapping.
- Enhanced error logging for network requests.

---

## [0.9.10] - 2026-02-08

### 🚀 New Features
- **Crotpedia Enhancements**: 
  - Added **Genre List** screen with browsable genre categories and item counts
  - Added **Doujin List** screen with alphabetical index (A-Z) for easy navigation
  - Added **Project Request** screen displaying community-requested content with pagination
- **Login Required Detection**: Implemented automatic detection and handling for content requiring authentication in Crotpedia

### 🎨 Reader UX Improvements
- **Auto-Hide UI on Scroll**: Reader interface now automatically hides on scroll for immersive reading experience
- **Disabled Zoom in Continuous Scroll**: Prevents accidental zoom gestures in continuous scroll mode for smoother reading
- **Conditional Page Count Display**: Page count now displayed contextually based on reading mode

### 🛠 Improvements
- Enhanced request list parsing with support for genres, ratings, and synopsis
- Updated Crotpedia config to version 1.2.0 with new menu configurations
- Propagated `LoginRequiredException` through content detail retrieval for better error handling

### 🔧 Technical
- New localization strings for login-required scenarios
- Removed debug print statements from Crotpedia scraper tests
- Added `flutter_02.png` screenshot to repository

---

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
