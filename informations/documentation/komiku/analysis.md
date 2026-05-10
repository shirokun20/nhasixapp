# Komiku Scraper Analysis - FINAL

**Tanggal:** 2026-05-10  
**Status:** ✅ Analysis Complete, Ready for Implementation  

---

## SUMMARY

Komiku adalah **hybrid source** (API + HTML scraping):
- **API Mode**: Home, Search, Genre listing → `api.komiku.org`
- **Scraping Mode**: Detail page, Chapter reading → `komiku.org`

**Implementation Strategy:** Config-driven via `komiku-config.json` + `GenericHttpSource`

---

## FILE STRUCTURE

```
packages/kuron_generic/lib/src/sources/komiku/
├── komiku_scraper.dart    # HTML parser (detail + chapter)
├── komiku_models.dart     # Data models
└── (NO komiku_source.dart - use GenericHttpSource!)
```

**Config:** `/komiku-config.json` (root project)

---

## KEY ENDPOINTS

### 1. Home/Latest (API Mode)
```
GET https://api.komiku.org/manga/
GET https://api.komiku.org/manga/page/{page}/
```
**Response:** HTML dengan `article.ls2` cards

### 2. Search (API Mode)
```
GET https://api.komiku.org/manga/?orderby={order}&tipe={type}&genre={genre}&genre2={genre2}&status={status}&s={query}
```

**Parameters:**
- `orderby`: modified, date, meta_value_num, rand
- `tipe`: manga, manhwa, manhua
- `genre`: action, fantasy, isekai, dll (100+ genre)
- `genre2`: second genre filter
- `status`: ongoing, end

### 3. Genre Listing (API Mode)
```
GET https://api.komiku.org/genre/{genre}/
GET https://api.komiku.org/genre/{genre}/page/{page}/
```

### 4. Detail Page (Scraping Mode)
```
GET https://komiku.org/manga/{slug}/
```

**Key Selectors:**
- Cover: `img[itemprop="image"]`
- Title: `h1 span[itemprop="name"]`
- Genres: `table.inftable tr:contains("Genre:") ul.genre li a span`
- Synopsis: `p.desc[itemprop="description"]`
- Chapters: `table#Daftar_Chapter tbody tr[itemprop="itemListElement"]`

### 5. Chapter Reading (Scraping Mode)
```
GET https://komiku.org/{chapterSlug}/
```

**Key Selectors:**
- Images: `#Baca_Komik img.klazy, #Baca_Komik img.ww`
- JavaScript Data: `var chapterData = {...}` (JSON extract)

**Image URL Pattern:**
```
https://img.komiku.org/uploads2/{chapter_id}-{page}.jpg
```

---

## DATA MODELS

### KomikuMangaCard
```dart
- id, title, slug, coverUrl
- type (Manga/Manhwa/Manhua)
- latestChapter, genres, views
```

### KomikuMangaDetail
```dart
- id, title, alternativeTitle, slug
- coverUrl, type, genres, author
- status, rating, totalViews
- synopsis, chapters[]
```

### KomikuChapter
```dart
- id, title, slug, url
- releaseDate, pageCount
```

### KomikuChapterPages
```dart
- chapterId, chapterTitle, seriesTitle
- imageUrls[], prevChapterUrl, nextChapterUrl
```

---

## IMPLEMENTATION CHECKLIST

### ✅ Phase 1: Core Structure (DONE)
- [x] Analysis document
- [x] Config JSON (komiku-config.json)
- [x] Data models (komiku_models.dart)
- [x] HTML scraper (komiku_scraper.dart)

### 🔄 Phase 2: Integration (NEXT)
- [ ] Register Komiku di `GenericSourceFactory`
- [ ] Test home/latest parsing
- [ ] Test search with filters
- [ ] Test detail page parsing
- [ ] Test chapter reading

### 📋 Phase 3: Testing
- [ ] Unit tests untuk scraper
- [ ] Integration tests dengan real HTML
- [ ] Edge cases (missing data, special chars)

### 🎨 Phase 4: Polish
- [ ] Error handling
- [ ] Retry mechanism
- [ ] Caching strategy
- [ ] Performance optimization

---

## USAGE EXAMPLE

```dart
// GenericHttpSource akan load config dari komiku-config.json
final komikuSource = await GenericSourceFactory.create('komiku');

// Search
final results = await komikuSource.search(
  SearchFilter(
    query: 'isekai',
    filters: {'type': 'manga', 'genre': 'fantasy'},
    page: 1,
  ),
);

// Detail
final detail = await komikuSource.getDetail('manga-slug');

// Chapter images
final chapterData = await komikuSource.getChapterImages('chapter-slug');
```

---

## SPECIAL FEATURES

### Type Detection
```dart
Flag image → Type
/jp.png   → Manga
/kr.png   → Manhwa
/cn.png   → Manhua
```

### Views Parsing
```dart
"1.1jt views" → 1,100,000
"32rb views"  → 32,000
```

### Date Parsing
```dart
"13/07/2024" → DateTime(2024, 7, 13)
```

---

## COMPARISON

| Feature | Komiku | KomikTap | Crotpedia |
|---------|--------|----------|-----------|
| API Support | ✅ Partial | ❌ No | ❌ No |
| Content | Manga/Manhwa/Manhua | Manga/Manhwa | Doujinshi |
| Search Filters | ✅✅ Advanced | ✅ Basic | ✅ Basic |
| Genres | 100+ | 50+ | 30+ |
| Multi-Genre | ✅ Yes (2) | ❌ No | ❌ No |

---

## NOTES

1. **Hybrid Mode**: API untuk listing, Scraping untuk detail/chapter
2. **Config-Driven**: Semua selector di `komiku-config.json`
3. **No Custom Source**: Pakai `GenericHttpSource` + config
4. **Scraper Helper**: `KomikuScraper` untuk parsing HTML kompleks
5. **Models**: Data transfer objects untuk type safety

---

## NEXT STEPS

1. Register di `GenericSourceFactory`
2. Test dengan real data
3. Fix bugs yang muncul
4. Optimize performance
5. Add to production

**Estimated Time:** 1-2 days untuk full integration + testing.
