# CMS Template Analysis — Kuron Sources

> **Date:** 2026-06-29
> **Method:** Config analysis + HTTP probe (Node.js `https`) + Browser (curl/Node)
> **Playwright MCP status:** ❌ Not available (sandbox blocked)
> **Scope:** All 20 source configs in `informations/configs/`

---

## 1. Summary

| Category | Count | Source Names |
|----------|-------|-------------|
| **WordPress Madara** | 2 | `hentairead`, `manhwaread` |
| **ZManga** (WordPress child) | 2 | `shirodoujin`, `crotpedia` |
| **Blogger** | 1 | `tooncubus` |
| **REST API** | 3 | `komikcast`, `mangadex`, `spyfakku` |
| **Custom HTML** (config doang) | 7 | `nicomanga`, `manga18.club`, `komiku`, `komiktap`, `doujindesuv2`, `hentaicosplay`, `hentaifox` |
| **Custom + adapter Dart** | 5 | `hentainexus`, `hitomi`, `ehentai`, `mangafire`, `vihentai` |
| **Total** | **20** | |

---

## 2. Template: WordPress Madara

### Sources

| Source | Config Evidence | Live Verification |
|--------|---------------|------------------|
| **hentairead** | `/?s={query}&post_type=wp-manga`, `.manga-item`, `chapterDataScript` | CF-blocked, but config pattern is definitive |
| **manhwaread** | `/?s={query}&post_type=wp-manga`, `.manga-item`, `chapterDataScript` | ✅ `wp-content` 15x, Madara classes verified live |

### URL Pattern

```
home:     /{category}/
search:   /?s={query}&post_type=wp-manga
detail:   /{category}/{id}/
genre:    /genre/{tag}/
chapter:  /{category}/{id}/{ch}
```

### Selectors

| Field | Selector |
|-------|----------|
| List item | `.manga-item` |
| Title | `a[href*='/{category}/']` |
| Cover | `img` (lazyload) |
| Detail title | `h1` |
| Detail cover | `.summary_image img`, `img[class*="cover"]` |
| Author | `a[href*='/author/']` |
| Artist | `a[href*='/artist/']` |
| Genre | `a[href*='/genre/']` |
| Status | `.post-status .status` |
| Chapters | `#chapterlist li a`, `a[href*="chapter"]` |

### Reader Mode

```json
{ "mode": "chapterDataScript" }
// Fallback: tsReaderRegex
```

### Pagination

```
next: a.page-numbers.next, a[rel="next"]
links: a.page-numbers
```

### CMS Signatures

```
<meta name="generator" content="WordPress ..."/>
wp-content/themes/madara/
class="manga-item"
class="wp-manga"
postid-
```

---

## 3. Template: ZManga

### Sources

| Source | Config Evidence | Live Verification |
|--------|---------------|------------------|
| **shirodoujin** | `/series/{id}`, `.flexbox4-item`, `/?s={query}` | ✅ `wp-content` 46x, zmanga theme verified live |
| **crotpedia** | `/baca/series/{id}/`, `.flexbox4-item`, `/?s={query}` | Config identik shirodoujin (slight prefix variant) |

### URL Pattern

```
home:     /
search:   /?s={query}
detail:   /series/{id}
chapter:  /{id}
genre:    /genre/{tag}/
```

### Selectors

| Field | Selector |
|-------|----------|
| List item | `.flexbox4-item` |
| Title | `.flexbox4-side .title a` |
| Cover | `.flexbox4-thumb img.lazyload` (`data-src`) |
| Detail title | `.series-title h2` |
| Detail cover | `.series-thumb img.lazyload` |
| Author | `a[href*='/author/']` |
| Artist | `a[href*='/artist/']` |
| Genre | `a[href*='/genre/']` |
| Status | `.status` |
| Chapters | `.series-chapterlist li` |

### Reader Mode

```json
{ "selector": "img.lazyload", "attribute": "data-src" }
```

### Pagination

```
next: .next, a[rel="next"]
links: a.page-numbers
```

### CMS Signatures

```
wp-content/themes/zmanga/
class="flexbox4-item"
class="series-title"
lazyload images
```

---

## 4. Template: Blogger

### Sources

| Source | Config Evidence | Live Verification |
|--------|---------------|------------------|
| **tooncubus** | `/search`, `max-results=`, `.grid.gtc-f141a > div` | ✅ `blogger.com` refs, `.blog-pager`, `atom.xml` verified live |

### URL Pattern

```
home:     /search/label/Series?max-results=N
search:   /search?q={query}&max-results=N
detail:   /{year}/{month}/{slug}.html
tag:      /search/label/{tag}?max-results=N
```

### Selectors

| Field | Selector |
|-------|----------|
| List item | `.grid.gtc-f141a > div` |
| Title | `a.clamp` |
| Cover | `.b-img img` (`src`) |
| Detail title | `meta[property="og:title"]` |
| Detail cover | `img[src*='blogger.googleusercontent.com']` |
| Tags | `.label-name, a[rel="tag"]` |

### Reader Mode

```json
{ "selector": "img", "attribute": "src" }
```

### Pagination

```
next: .blog-pager-older-link
```

### CMS Signatures

```
blogger.com
Content-Type: text/html; charset=UTF-8
blog-pager
atom.xml/feed
```

---

## 5. Custom HTML — Config Only (No Adapter Needed)

> These sources can be handled entirely by `GenericScraperAdapter`. No Dart code needed.

| Source | Notes |
|--------|-------|
| **nicomanga** | Custom, NOT WordPress. Class-based layout with `manga-card`/`manga-grid`. Zero adapter needed |
| **manga18.club** | Custom CMS. NOT WordPress (corrected after live check). `iedu_*` class naming |
| **komiku** | `/manga/{id}` pattern from `komiku.org`. Standard HTML scraping |
| **komiktap** | `/manga/{id}` pattern. Sucuri firewall protected but config is complete |
| **doujindesuv2** | `/manga/{id}` pattern. Reader uses `ajaxHtmlImages` mode — already supported by engine |
| **hentaicosplay** | Image gallery `/image/{id}`. CF-protected. Config covers all |
| **hentaifox** | Custom gallery. Needs `hentaifoxCdn` reader mode — requires minimal adapter |

---

## 6. Custom Protocol — Needs Adapter Dart

> These sources require non-standard protocols that cannot be expressed in pure config JSON.

| Source | Protocol | Adapter Needed |
|--------|----------|---------------|
| **hentainexus** | XOR/RC4 image path decryption | `HentaiNexusDecryptAdapter` |
| **hitomi** | nozomi binary protocol | `HitomiAdapter` |
| **ehentai** | Tokenized page fetch + auth session | `EHentaiAdapter` |
| **mangafire** | CDN VRF signature verification | `MangaFireAdapter` |
| **vihentai** | Livewire password gate + packed JS eval | `ViHentaiAdapter` |

---

## 7. REST API Sources

| Source | API Base | Notes |
|--------|----------|-------|
| **komikcast** | `https://be.komikcast.cc` | Full REST. JSON path selectors |
| **mangadex** | `https://api.mangadex.org` | Full REST. MangaDex API |
| **spyfakku** | Internal | REST internal |

These use `GenericRestAdapter`, not scraper.

---

## 8. Template Registry Proposal

```dart
// Proposed structure in kuron_generic/lib/src/templates/

abstract class SourceTemplate {
  String get id;
  String get displayName;
  Map<String, dynamic> get defaultConfig; // base config template
  Map<String, String> get cmsSignatures; // hints untuk auto-detect
}

class WordPressMadaraTemplate extends SourceTemplate { ... }
class ZmangaTemplate extends SourceTemplate { ... }
class BloggerTemplate extends SourceTemplate { ... }
```

When a config specifies `"template": "wordpress-madara"`, the engine:
1. Loads the base template config
2. Merges user overrides (`baseUrl`, custom selectors, etc.)
3. Produces final complete config
4. Validates via `SourceConfigParser`

Auto-detection flow:
```
User enters URL → probe HTML → match CMS signatures → resolve template → merge overrides → done
```

---

## 9. Verification Notes

### Sites accessible via HTTP probe (static HTML analysis worked):
- `manhwaread.com` — ✅ WordPress Madara confirmed
- `shirodoujin.com` — ✅ ZManga confirmed (46x wp-content)
- `tooncubus.top` — ✅ Blogger confirmed (.blog-pager, atom.xml)
- `nicomanga.com` — ✅ NOT WordPress, Custom HTML
- `manga18.club` — ✅ NOT WordPress, Custom HTML

### Sites blocked (CF / Sucuri):
- `hentairead.com` — Cloudflare (config pattern indicates Madara)
- `hentaicosplay.com` — Cloudflare
- `komiktap.info` — Sucuri WebSite Firewall
- `crotpedia.org` — Timeout/unreachable
- `doujindesu.tv` — 301 redirect (config uses doujindesu.es)

---

## 10. Conclusion

| Aspect | Count | % |
|--------|-------|---|
| Reusable template | 3 CMS types | ~25% of sources |
| Config-only (no adapter) | 12 sources | 60% |
| Needs adapter Dart | 5 sources | 25% |
| REST API | 3 sources | 15% |

**Key insight:** Only 5 of 20 sources truly need custom Dart code. The rest are either:
- Reusable CMS templates (5 sources)
- Config-only custom HTML (7 sources)
- REST API (3 sources)

Building template registry for Madara + ZManga + Blogger would cover ~25% of sources with minimal effort, while the remaining custom HTML sources need only a config JSON drop — no rebuild, no Dart.
