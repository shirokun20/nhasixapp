# Config Generator Gap Analysis

**Test Target:** `https://dojing.net`
**CMS Detected:** MangaThemesia (WordPress 7.0, theme: mangareader)
**Test Date:** 2026-06-29
**Artifacts:** `output/gen-dojing-config.json`

---

## 1. CMS Detection Quality

| Metric | Before Fixes | After Fixes |
|--------|-------------|-------------|
| Detected CMS | `custom` (0%) | `mangathemesia` (90%) |
| Container | `article, .post, .entry` ❌ | `.listupd .bsx, .listupd .bs, .box` ✅ |
| Detail URL | `/manhwa/{id}/` ❌ | `/manga/{id}/` ✅ |
| Chapter container | `a[href*="chapter"]` ❌ | `#chapterlist ul li` ✅ |
| Pagination | `a.page-numbers` ❌ | `.hpage a.r, a.page-numbers` ✅ |
| Genre URL | `/genre/{tag}/` ❌ | `/genres/{tag}/` ✅ |
| Reader | generic `.reading-content` | `#readerarea` + nav ✅ |
| Navigation | `null` ❌ | genreQueryPrefix set ✅ |
| ContentIdPattern | generic `/([^/]+)` | `/manga/([^/]+)` ✅ |

## 2. Format Compatibility vs Existing Configs

| Field | Generated | Existing | Match |
|-------|-----------|----------|-------|
| `source` | `dojing.net` | host-derived | ✅ |
| `displayName` | `dojing.net` | custom per source | ✅ |
| `schemaVersion` | `2.0` | `2.0` | ✅ |
| `version` | `1.0.0` | various | ✅ |
| `baseUrl` | `https://dojing.net` | per source | ✅ |
| `enabled` | `true` | `true` | ✅ |
| `defaultLanguage` | `english` ❌ | `indonesian` for .id sites | `.net` domain heuristic fails |
| `ui` | minimal | richer (icon, brandColor) | ⚠️ adequate |
| `network` | standard | standard + siteProtection | ✅ |
| `configUrl` | auto-generated | per-source URL | ✅ |
| `requiredPrimitives` | 3 items | varies | ✅ |
| `scraper.urlPatterns` | 12 patterns | varies | ✅ |
| `scraper.selectors` | list+detail+reader | same structure | ✅ |
| `searchForm` | basic text | varies | ✅ |
| `navigation` | genre mapping | varies | ✅ |
| `features` | 9 flags | varies | ✅ |
| `notes` | `MangaThemesia theme.` | descriptive | ✅ |

## 3. Gaps Found

### 3.1 Language Detection
- `dojing.net` (`net` TLD) fails `.id`/`komik`/`doujin` heuristic → `english`
- Quick manual fix after generation
- Auto-fix: check `<html lang="id">` from probe HTML

### 3.2 Search URL
- Generated `/?s={query}&post_type=manga` from CMS defaults
- Dojing uses plain `/?s={query}` (no `post_type` needed)
- Acceptable — most MangaThemesia sites use `post_type=manga`

### 3.3 Missing Blocks (Not Generated)
- No `auth` block — only crotpedia needs it
- No `decryption` block — HentaiNexus, ViHentai need it
- No `searchConfig` (radio/checkbox groups) — alternate format, not required

**None of these are blockages** — existing configs also omit these where not applicable.

## 4. Fixes Applied

### cms_detector.dart
- Added hints: `wp-content/themes/mangareader`, `listupd`, `class="bsx"`, `seriestugenre`, `class="hpage"`
- Updated list selects: `.listupd .bsx, .listupd .bs, .box`
- Updated title selects: `.tt`
- Updated cover selects: `.thumb img`

### config_generator.dart
- Added `mangathemesia` branch in `_scraperUrls`: container, pagination, detail/chapter URLs, genre URLs
- Added `mangathemesia` in `_listFields`, `_detailFields`, `_chaptersCfg`, `_readerCfg`, `_contentIdPattern`, `_navigation`, `_buildNotes`

## 5. Verdict

**Generator usable** for MangaThemesia sites. Output format matches existing config requirements. Manual override needed only for:

1. `defaultLanguage` (`english` → `indonesian`)
2. Detected CMS theme type (sometimes `mangathemesia` vs `madara-tailwind` nuance)
3. Icon/brandColor customization

**Existing configs still serve as reference** — generated config is a production-ready draft, not yet shipping quality without review.
