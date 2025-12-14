# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

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
