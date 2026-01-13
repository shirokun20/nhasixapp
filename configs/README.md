# Dynamic Configuration Files

## 📋 Overview

This directory contains JSON configuration files for NhasixApp's dynamic configuration system. These configs allow runtime updates without app rebuilds.

## 📁 File Structure

```
configs/
├── version.json           # Master config manifest
├── nhentai-config.json    # nhentai source configuration  
├── crotpedia-config.json  # Crotpedia source configuration
├── app-config.json        # App-wide settings
├── tags-config.json       # Tag data configuration
└── README.md              # This file
```

## 🔧 Configuration Files

### 1. **version.json** - Master Manifest
Controls all config versions and URLs for remote sync.

**Key fields:**
- `version`: Current config system version
- `minimumAppVersion`: Minimum app version required
- `forceUpdate`: Force users to update app
- `configs`: Map of all config files with versions and URLs

### 2. **nhentai-config.json** - nhentai Source
Complete configuration for nhentai source.

**Sections:**
- `api`: API endpoints, image URLs, extension mapping
- `scraper`: HTML selectors for fallback scraping
- `network`: Rate limiting, retry logic, cloudflare bypass
- `features`: Capability flags (search, random, download, etc)
- `ui`: Display settings (theme color, card style)

**Key features:**
- ✅ Real API endpoints from production code
- ✅ Mirror server support for failover
- ✅ WebP image format support
- ✅ Tag exclusion capability

### 3. **crotpedia-config.json** - Crotpedia Source  
Complete configuration for Crotpedia source.

**Sections:**
- `scraper`: HTML selectors for all page types
- `urlPatterns`: URL templates for navigation
- `auth`: Login/session configuration
- `network`: Timeout and retry settings
- `features`: Capability flags (chapters, bookmarks, etc)
- `ui`: Display settings

**Key features:**
- ✅ Pure HTML scraping (no API)
- ✅ Chapter-based content support
- ✅ Authentication for bookmarks
- ❌ No tag exclusion support

### 4. **app-config.json** - App-Wide Settings
Global app configuration affecting all sources.

**Sections:**
- `limits`: Page sizes, download limits, buffers
- `durations`: Timeouts, cache TTL, animations
- `ui`: Grid layout, card styles, text limits
- `storage`: Folders, compression, cache limits  
- `download`: WiFi-only, retries, notifications
- `reader`: Navigation mode, preload settings
- `privacy`: Analytics, history, data collection

### 5. **tags-config.json** - Tag Data  
Configuration for tag data source and management.

**Current:**
- Using bundled asset: `assets/json/tags.json` (5.17 MB)
- Type code mapping for tag types
- Multi-select rules per type

**Future Migration:**
- Remote CDN with gzip compression
- Reduce app size
- Allow dynamic tag updates

## 🚀 Usage

### Local Development
```bash
# Config files are loaded from local directory
configs/nhentai-config.json
configs/crotpedia-config.json
```

### Production (Future)
```bash
# Configs served via GitHub + jsdelivr CDN
https://cdn.jsdelivr.net/gh/YOU/nhasix-configs@main/nhentai-config.json
https://cdn.jsdelivr.net/gh/YOU/nhasix-configs@main/crotpedia-config.json
```

## 📝 Editing Configs

### Best Practices
1. **Validate JSON** before committing (use `validate_configs.sh`)
2. **Increment version** when making changes
3. **Update lastUpdated** timestamp
4. **Test locally** before pushing to GitHub
5. **Update changelog** in `version.json`

### Common Edits

**Add mirror server:**
```json
"mirrors": [
  "https://nhentai.xxx",
  "https://nhentai.to",
  "https://new-mirror.com"  // ADD HERE
]
```

**Change rate limit:**
```json
"rateLimit": {
  "requestsPerMinute": 30,  // DECREASE if getting 429 errors
  "minDelayMs": 500
}
```

**Update HTML selector:**
```json
"selectors": {
  "homepage": {
    "container": ".new-container-class"  // UPDATE when site changes
  }
}
```

**Toggle feature:**
```json
"features": {
  "download": false  // DISABLE downloads for a source
}
```

## ⚙️ Configuration Schema

### Variable Substitution
Configs support template variables:

- `{id}` - Content ID
- `{page}` - Page number
- `{query}` - Search query
- `{slug}` - Content slug (Crotpedia)
- `{mediaId}` - Media ID (nhentai)
- `{ext}` - File extension

**Example:**
```json
"fullSize": "https://i.nhentai.net/galleries/{mediaId}/{page}.{ext}"
```
Becomes:
```
https://i.nhentai.net/galleries/3473061/1.jpg
```

### Extension Mapping
```json
"extensionMapping": {
  "j": "jpg",   // JPEG images
  "p": "png",   // PNG images
  "g": "gif",   // GIF animations
  "w": "webp"   // WebP (modern, smaller)
}
```

## 🔄 Update Workflow

### Local Testing
1. Edit config JSON
2. Run `./validate_configs.sh`
3. Test in app locally
4. Verify changes work

### Production Deployment (Future)
1. Edit config JSON
2. Commit to GitHub
3. Push to `main` branch
4. App auto-syncs within cache TTL (24h default)
5. Or force refresh in app settings

## 🛡️ Version Control

**Semantic Versioning:**
- `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes (restructure)
- MINOR: New features (add fields)
- PATCH: Bug fixes (correct values)

**Example:**
- `1.0.0` → Initial release
- `1.1.0` → Add new endpoint
- `1.1.1` → Fix selector typo
- `2.0.0` → Completely new schema

## 📊 Monitoring

### Key Metrics to Watch
- Config load success rate
- Fallback activation count
- Rate limit triggers
- API vs scraper usage

### Debugging
```json
// Add to any config for verbose logging
"debug": {
  "enabled": true,
  "logLevel": "verbose"
}
```

## 🔒 Security Notes

1. **Public configs**: OK for non-sensitive data (URLs, selectors)
2. **No sensitive data**: Never include API keys, passwords
3. **Validation**: App validates config structure before loading
4. **Fallback**: App uses hardcoded defaults if config fails

## 📚 Implementation Status

- [x] Config files created
- [ ] Config loader service
- [ ] Config validator
- [ ] Remote sync capability  
- [ ] UI for config management
- [ ] GitHub repository setup
- [ ] CDN integration

## 🎯 Next Steps

1. Create `RemoteConfigService` Dart class
2. Implement JSON validation
3. Add config hot-reload support
4. Create GitHub repo for configs
5. Setup jsdelivr CDN
6. Add config version checker
7. Implement automatic updates

## 📞 Support

For questions or issues with configs:
1. Check this README
2. Review config examples
3. Validate JSON syntax
4. Check app logs for errors

---

**Last Updated**: 2026-01-13
**Config Version**: 1.0.0
**Status**: 🟡 Development (Local only)
