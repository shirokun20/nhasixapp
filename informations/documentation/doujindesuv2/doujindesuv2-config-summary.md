# DoujinDesu v2 - Config Summary (API Mode)

**Date**: 2026-05-10  
**Status**: ✅ API Mode - Ready for Integration  
**Config File**: `doujindesuv2-config.json`

---

## Quick Overview

DoujinDesu v2 menggunakan **JSON API** dengan format **API Mode** (seperti MangaDex). Config sudah disesuaikan dengan format config-driven yang ada di project.

### API Endpoints

| Endpoint | URL | Purpose |
|----------|-----|---------|
| **All Galleries** | `/api/manga-list?limit=24&page={page}` | Paginated manga list |
| **Search** | `/api/search?q={query}` | Search manga |
| **Detail** | `/api/manga/{id}` | Manga detail + chapters |
| **Images** | `/api/read/{id}/{chapter}` | Chapter images |

### Key Features

- ✅ **API Mode** - Menggunakan `api` section (bukan `scraper`)
- ✅ **JSON Path Selectors** - `$` notation untuk parsing
- ✅ **No Auth** - Tidak perlu login/token
- ✅ **Pagination** - Page-based pagination
- ✅ **Config-Driven** - Compatible dengan existing architecture

---

## Config Structure

```json
{
  "source": "doujindesuv2",
  "api": {
    "enabled": true,
    "endpoints": {
      "allGalleries": "/api/manga-list?limit=24&page={page}",
      "search": "/api/search?q={query}",
      "detail": "/api/manga/{id}",
      "images": "/api/read/{id}/{chapter}"
    },
    "list": {
      "items": "$.data[*]",
      "pagination": { "pageMode": true, ... },
      "fields": { ... }
    },
    "detail": {
      "chapters": { "items": "$.data.chapters[*]", ... },
      "fields": { ... }
    },
    "images": {
      "mode": "direct",
      "items": "$.data.chapter.images[*]"
    }
  }
}
```

---

## Response Structure Mapping

### 1. Manga List Response
```json
{
  "success": true,
  "data": [
    {
      "slug": "new-town-massage",
      "title": "New Town Massage",
      "thumb": "https://cdn-images.doujindesu.fun/covers/new-town-massage.jpg",
      "metadata": { "type": "Manhwa", "status": "Publishing", "rating": "8.80" },
      "tags": ["Ahegao", "Big Ass", ...],
      "views": 5843,
      "chapter_count": 8,
      "last_chapter": { "title": "8", ... }
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 117,
    "totalItems": 932,
    "perPage": 24
  }
}
```

**Mapping**:
- `items`: `$.data[*]`
- `total`: `$.pagination.totalItems`
- `limit`: `$.pagination.perPage`
- `currentPage`: `$.pagination.currentPage`
- `totalPages`: `$.pagination.totalPages`

### 2. Detail Response
```json
{
  "success": true,
  "data": {
    "info": {
      "slug": "tsuma-no-imouto",
      "title": "Tsuma no Imouto",
      "thumb": "...",
      "metadata": { "type": "Doujinshi", "status": "Finished", "rating": "8.50" },
      "tags": ["Big Ass", "Big Penis", ...],
      "synopsis": "...",
      "chapter_count": 4
    },
    "chapters": [
      { "slug": "tsuma-no-imouto-4", "title": "4 END", "chapter_index": 4 }
    ],
    "recommendations": [ ... ]
  }
}
```

**Mapping**:
- `detail.fields`: `$.data.info.*`
- `chapters`: `$.data.chapters[*]`
- `related`: `$.data.recommendations[*]`

### 3. Images Response
```json
{
  "success": true,
  "data": {
    "chapter": {
      "images": [
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (1).webp",
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (2).webp"
      ]
    },
    "navigation": { "next": "tsuma-no-imouto-2", "prev": null }
  }
}
```

**Mapping**:
- `images`: `$.data.chapter.images[*]`

---

## Implementation Notes

### Similar to MangaDex Pattern
DoujinDesu v2 menggunakan API mode seperti MangaDex:
- Menggunakan `api` section (bukan `scraper`)
- JSON path selectors (`$.data.*`)
- Pagination page-based
- Endpoints terpisah untuk list/detail/images

### Differences from Komiku
Komiku menggunakan HTML scraping, DoujinDesu v2 menggunakan API:
- **Komiku**: HTML selectors (`.bge`, `.kan h3`)
- **DoujinDesu v2**: JSON paths (`$.data[*]`, `$.data.info.title`)

### Differences from NHentai
NHentai juga API mode, tapi struktur berbeda:
- **NHentai**: `/api/galleries/{id}` (single endpoint)
- **DoujinDesu v2**: Terpisah (`/api/manga/{id}`, `/api/read/{id}/{chapter}`)

---

## Files Reference

| File | Purpose |
|------|---------|
| `doujindesuv2-config.json` | Main config file (API mode format) |
| `doujindesuv2-api-reference.md` | Complete API documentation |
| `doujindesuv2-analysis.md` | Technical analysis |
| `source-config-templates/data.md` | API response examples |

---

## Next Steps

1. ✅ Config file ready (`doujindesuv2-config.json`)
2. ⏳ Test config dengan existing API scraper
3. ⏳ Implement rate limiting (30 req/min)
4. ⏳ Add to source selection UI

---

**Created**: 2026-05-10  
**By**: Kiro AI Assistant  
**For**: Kuron App Development
