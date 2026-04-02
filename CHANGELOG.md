# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.9.14+23] - 2026-03-31

### 🔧 Build Update (Build #23)

#### ✨ Enhancement
- **Reader Experience**: Image height caching for instant page render without relayout; floating page indicator for quick navigation awareness.

#### 🐛 Bug Fixes
- **Offline Page**: Prevent duplicate items for externally imported content.
- **ZIP Import**: Calculate and persist `fileSize` when importing ZIP archives.
- **Offline Metadata**: Auto-generate `metadata.json` for manually imported offline content; fixes rendering errors on doujin import.
- **Lint**: Resolve lint errors introduced after ZIP import migration.

#### ♻️ Refactor
- **ZIP Import Handler**: Migrated from `MainActivity` to `kuron_native` plugin for cleaner native boundary separation.
- **ImportZipUseCase**: Improved code readability and formatting.

#### 📝 Docs
- Added comprehensive ZIP Import feature guide (`ZIP_IMPORT_GUIDE.md`).

---

## [0.9.14] - 2026-03-28

### 🎉 Phase 6 Complete: Multi-Provider Special Adapters
- **E-Hentai Source Added**:
  - Full E-Hentai gallery support with per-page reader image extraction
  - E-Hentai session adapter with igneous cookie verification and content warning bypass
  - Dynamic search form with token-based pagination
  - All smoke tests passing (Search→Detail→Reader validated)
- **HentaiNexus Source Added**:
  - HentaiNexus decryption adapter with Base64 → XOR stream decryption
  - Full image URL decryption pipeline for reader support
  - Gate A validation passed on live samples
  - All smoke tests passing (Search→Detail→Reader validated)
- **Hitomi Fallback Support Added**:
  - Hitomi source with fallback-safe registration (full protocol deferred due to gg.js volatility)
  - All smoke tests passing (Search→Detail→Reader via fallback mode validated)
- **Architecture Improvements**:
  - Added adapter override hook in GenericHttpSource for provider-specific adapters
  - Enhanced factory pattern across source resolvers for extensibility
  - All configs staged in manifest-driven `app/config/` layer

### ✅ Verification
- All Phase 6 tasks complete (10/10)
- Test coverage: 8 EHentai + 2 HentaiNexus tests passing
- flutter analyze: No issues found
- Smoke tests: All 3 providers (E-Hentai, HentaiNexus, Hitomi) validated

### 📊 Project Milestone
- **Multi-Provider Integration**: 100% complete (Phase 0-6)
- **Total projects completed**: 12/12 from onprogress → success-plan
- **Ready for**: Production rollout

---

## [0.9.13] - 2026-03-16

### 🚀 New Features
- **MangaDex Expansion**:
  - Added full MangaDex source support with language-aware gallery/chapter retrieval
  - Added original language and available translation metadata in API responses
  - Added chapter pagination support and integration tests for chapter fetch flow
- **Search UX Upgrade**:
  - Added included/excluded tag filtering with multi-select and combined picker support
  - Improved dynamic tag loading, endpoint sorting, and query mapping for search forms
  - Added raw query parameter support for advanced search scenarios
- **Metadata & Detail Enrichment**:
  - Added configurable tag-relations mapping to enrich tags and artists in detail pages
  - Improved detail field label routing and multi-candidate tag resolution
- **HentaiFox Support Improvements**:
  - Added API-first comments handling with CSRF/session fallback support
  - Added favorites/comments integration and robust full-resolution image fallback handling
  - Added upload date extraction and relative date parsing improvements

### 🛠 Fixes
- **Reader Navigation Stability**:
  - Fixed chapter navigation language and reading direction handling in reader settings
  - Fixed chapter list presentation to show chapter index consistently in detail view
  - Added fallback chapter title (`Oneshot`) for empty chapter title fields
- **Search Robustness**:
  - Prevented modal invocation when widget is unmounted to avoid runtime errors
  - Improved picker error handling, loading-state flow, and cache invalidation requirement handling

### 🛠 Improvements
- **Architecture & Source Management**:
  - Removed KomikTap dependency and refactored URL generation to use `SourceUrlResolver`
  - Refactored content URL building to prioritize config-driven URLs while keeping backward compatibility
  - Enhanced generic adapter query-rule support for multi-value parameters
- **Data & Performance**:
  - Added batch loading for completed downloads from local database
  - Improved chapter retrieval fallback logic and chapter ordering detection

### 🔧 Technical
- Updated `pubspec.yaml` to version `0.9.13+21`
- Updated MangaDex config versions through `1.1.4` with related manifest metadata updates

---

## [0.9.12] - 2026-02-15

### 🚀 New Features
- **Enhanced Chapter Reading Experience**:
  - End-of-chapter overlay with "Next Chapter" / "Back to Detail" options
  - Chapter navigation support (Next/Previous chapter buttons)
  - Integrated history tracking for each chapter
  - Chapter selector dropdown in reader settings
  - Support for chapter-based content (Crotpedia, Komiktap)
- **Improved Image Loading**:
  - Replaced `CachedNetworkImage` with `ProgressiveImageWidget` for better static GIF support
  - Source-specific HTTP headers passed to image loading widgets
  - Enhanced compatibility with various content sources
- **Auto-Hide UI**:
  - Reader UI (top/bottom bars) auto-hides and auto-shows on scroll
  - Improved reading experience for immersive content consumption

### 🛠 Fixes
- **Navigation Page Accessibility**:
  - Fixed PageView onPageChanged to report actual page number (35) instead of clamped (34)
  - Fixed nextPage() and updateCurrentPageFromSwipe() to allow pageCount+1 when navigation is enabled
  - UI now displays "Chapter Complete" (bold, primary color) instead of "Page 35 of 34"
  - UI now displays "100%" instead of "103%" overflow
  - Progress bar shows 100% instead of overflow
  - Navigation page accessible via both swipe AND tap "Next" button
  - Only enabled in online mode with content.imageUrls.isNotEmpty
- **Continuous Scroll Enhancement**:
  - Enhanced page detection accuracy using viewport center calculation
  - Adaptive item height calculation based on actual maxScrollExtent
  - Fixed false page saves during programmatic scroll operations
  - Better handling of webtoon (tall images) vs manga (normal images)

### 🛠 Improvements
- **Database**:
  - Database v11: Added chapter support to history table (chapter_id, chapter_index, chapter_title)
  - Database v12: Added parent_id to history for series/parent content tracking
- **History Tracking**:
  - Chapter-level read status tracking
  - Creative read indicators in chapter list:
    - Color-coded chapter badges (tertiary=completed, primary=in-progress)
    - Circular progress ring on chapter number
    - "Done" trophy badge for completed chapters
    - Percentage badge with mini progress for in-progress chapters
  - Auto-scroll to last read chapter when opening from history
- **Search**:
  - Search highlighting for Doujin List, Favorites, and Offline Downloads
  - Title-based search enabled in Favorites

### 🔧 Technical
- Updated `pubspec.yaml` to version `0.9.12+20`
- Added OpenCode configuration and skill definitions
- Modernized Crotpedia UI with Genre List, Doujin List (A-Z index), and Project Request screens

---

## [0.9.11] - 2026-02-11

### 🚀 New Features
- **View Comments**:
  - Added ability to view comments on gallery detail pages.
  - Integration with **NHentai JSON API** for reliable comment data.
  - Robust handling of avatar URLs and comment formatting (Markdown).
  - Modern, card-based UI optimized for readability in both Light and Dark modes.
- **Search Highlighting**:
  - Implemented search term highlighting for **Favorites**, **Offline Downloads**, and **Doujin List**.
  - Improved search experience with visual feedback on matching text.
- **Favorites Enhancement**:
  - Added ability to search favorites by **Title** (previously only ID).

### 🛠 Fixes
- **Favorites Bug Fix**: 
  - Fixed issue where items from certain sources (KomikTap, Crotpedia) displayed overflowing IDs and missing titles.
  - Implemented database migration (v10) to persist titles locally, ensuring data reliability.
  - Fixed UI layout overflow in Favorites cards for long IDs.

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
