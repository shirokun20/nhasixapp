# Tags Directory

This directory will contain tag data files for remote sync.

## Files:
- `nhentai-tags.json` - Full tag data (to be copied from assets/json/tags.json)

## Usage:
When `migration.enabled` is set to `true` in `tags-config.json`, the app will:
1. Try to download from GitHub Raw (main branch)
2. Fallback to develop branch if main fails
3. Cache locally for 24 hours
4. Use bundled asset if download fails

## Sync Flow:
```
GitHub: configs/tags/nhentai-tags.json
    ↓
https://raw.githubusercontent.com/shirokun20/nhasixapp/main/configs/tags/nhentai-tags.json
    ↓
App downloads & caches
    ↓
Local cache (24h TTL)
```

## To Enable Remote Sync:
1. Copy `assets/json/tags.json` to `configs/tags/nhentai-tags.json`
2. Commit and push to GitHub
3. Set `migration.enabled: true` in `tags-config.json`
4. App will auto-sync from GitHub on next launch
