# Release v0.6.1

## Changes

### [0.6.1] - 2025-12-14
**Fixed**
- Fixed offline content bugs where deleted files persisted in list
- Fixed notification permission issues causing missing notifications
- Fixed build error related to desugaring libs

### [0.6.0] - 2025-12-12
**Added**
- **Export Library**: Export database and content files to shareable folder with progress dialog
- **Import from Backup**: Manual import button to sync backup folder content to database
- **Database-First Loading**: Offline screen now loads from database first (faster startup)
- **Sync to Database**: Automatic sync of backup folder content with duplicate handling

**Changed**
- Offline screen no longer auto-scans file system on startup (uses database)
- Delete now works for backup-scanned items (passes content path directly)
- AppBar redesigned with Import/Export buttons instead of permission debug button

**Fixed**
- Delete offline content not working for items from backup folder
- Path lookup failing for content not in database

---

## What's Changed
* Feature asix/offline revamp by @shirokun20 in https://github.com/shirokun20/nhasixapp/pull/3
* Feature asix/offline revamp by @shirokun20 in https://github.com/shirokun20/nhasixapp/pull/4

**Full Changelog**: https://github.com/shirokun20/nhasixapp/compare/v0.5.0-release...v0.6.1
