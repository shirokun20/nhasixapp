# DoujinDesu v2 - Complete Analysis & Implementation Guide

**Status**: ✅ Analysis Complete (Updated with API Discovery) | ⏳ Implementation Ready  
**Date**: 2026-05-10  
**Website**: https://v2.doujindesu.fun/  
**API Discovery**: ✅ DoujinDesu v2 MEMILIKI API endpoints! (2026-05-10)

---

## 📚 Documentation Files

### 1. **doujindesuv2-analysis.md** (MUST READ FIRST)
Comprehensive analysis of the website architecture, technology stack, and scraping challenges.

**Key Sections**:
- Executive Summary (UPDATED: API Discovery)
- Technology Stack (Next.js 14+, Hybrid Architecture)
- API Endpoints Documentation
- Data Structure Analysis
- Scraping Strategy Recommendations
- Critical Differences from NHentai

**When to Read**: Before starting implementation

---

### 2. **doujindesuv2-api-reference.md** ⭐ NEW (MUST READ)
Complete API documentation with endpoints, data models, and code examples.

**Contains**:
- API Endpoints (`/api/manga/{slug}`, `/api/read/{slug}/{chapter}`)
- Request/Response examples
- Data models (Dart classes)
- Error handling
- Rate limiting guidelines
- Complete implementation examples

**When to Use**: Primary reference for API integration

---

### 3. **doujindesuv2-config.json** (REFERENCE - UPDATED)
Complete configuration template for DoujinDesu v2 scraper.

**Contains**:
- API configuration (enabled: true)
- Scraping configuration (hybrid mode)
- Route definitions
- Data structure schemas
- Network settings (rate limits, headers)
- Feature flags
- UI/UX patterns
- Performance settings

**When to Use**: As reference during implementation

---

### 4. **doujindesuv2-implementation-guide.md** (CODING GUIDE)
Step-by-step implementation guide with code examples.

**Includes**:
- Setup dependencies
- Rate limiter implementation
- API integration (JSON parsing)
- HTML scraping for homepage
- Manga detail via API
- Chapter reading via API
- Testing examples
- Integration with existing codebase

**When to Use**: While writing code

---

### 5. **doujindesuv2-vs-existing-sources.md** (UNDERSTANDING)
Comparison with NHentai and Komiku to understand implementation approach.

**Explains**:
- Why DoujinDesu v2 is now similar to NHentai (has API)
- Hybrid approach (API + HTML)
- Common mistakes and how to avoid them
- Migration path from other scrapers

**When to Read**: To understand the hybrid architecture

---

## 🎯 Quick Start

### For Developers New to This

1. **Read First**: `doujindesuv2-api-reference.md` (10 min) ⭐ NEW
2. **Understand**: `doujindesuv2-analysis.md` (15 min)
3. **Code**: `doujindesuv2-implementation-guide.md` (30 min)
4. **Reference**: `doujindesuv2-config.json` (as needed)

### For Developers Familiar with NHentai Scraper

1. **Read**: `doujindesuv2-api-reference.md` (10 min) ⭐ Similar pattern!
2. **Skim**: `doujindesuv2-analysis.md` (5 min)
3. **Reference**: `doujindesuv2-config.json` (API endpoints)
4. **Code**: `doujindesuv2-implementation-guide.md` (adapt from NHentai)

### For Developers Familiar with Komiku Scraper

1. **Read**: `doujindesuv2-api-reference.md` (10 min) ⭐ NEW approach
2. **Understand**: Hybrid architecture (API + HTML)
3. **Learn**: JSON API integration
4. **Code**: `doujindesuv2-implementation-guide.md` (combine both approaches)

---

## 🔑 Key Takeaways

### What is DoujinDesu v2?

```
Website: https://v2.doujindesu.fun/
Type: Indonesian Manga/Manhwa/Doujinshi Reader
Framework: Next.js 14+ with App Router
Rendering: Server-Side Rendering (SSR)
Protection: Cloudflare
```

### Why It's Different

| Aspect | NHentai | DoujinDesu v2 |
|--------|---------|---------------|
| **API** | ✅ Has REST API | ❌ No API |
| **Data Format** | JSON | HTML + Embedded JSON |
| **Scraping** | Direct JSON parsing | HTML parsing + JSON extraction |
| **Rate Limit** | 60 req/min | 30 req/min |
| **Complexity** | Low | High |

### What You Need to Do

```
1. ✅ Parse HTML (not JSON)
2. ✅ Extract embedded JSON from <script> tags
3. ✅ Implement rate limiting (30 req/min)
4. ✅ Handle Cloudflare protection
5. ✅ Persist cookies for sessions
6. ✅ Cache aggressively
```

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────┐
│   DoujinDesu v2 (Next.js SSR)           │
├─────────────────────────────────────────┤
│                                         │
│  Frontend: React Server Components      │
│  Backend: Next.js API Routes (SSR)      │
│  Database: MongoDB (inferred)           │
│  CDN: cdn-images.doujindesu.fun         │
│  Protection: Cloudflare                 │
│                                         │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│   Your Flutter App Scraper              │
├─────────────────────────────────────────┤
│                                         │
│  1. HTTP Request (with headers)         │
│  2. Receive HTML + Embedded JSON        │
│  3. Parse HTML with html package        │
│  4. Extract JSON from <script> tags     │
│  5. Convert to Dart models              │
│  6. Cache locally                       │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🚀 Implementation Roadmap

### Phase 1: Setup (1-2 hours)
- [ ] Add `html` package to pubspec.yaml
- [ ] Create RateLimiter class
- [ ] Setup cookie persistence
- [ ] Configure default headers

### Phase 2: Core Scraping (2-3 hours)
- [ ] Implement HTML parsing
- [ ] Extract Next.js embedded JSON
- [ ] Parse manga list
- [ ] Parse manga detail
- [ ] Handle errors & retries

### Phase 3: Integration (1-2 hours)
- [ ] Create DoujinDesuV2DataSource
- [ ] Integrate with RemoteDataSourceFactory
- [ ] Add to source selection UI
- [ ] Test with real data

### Phase 4: Optimization (1-2 hours)
- [ ] Implement caching layer
- [ ] Add image lazy loading
- [ ] Performance monitoring
- [ ] Error handling improvements

**Total Estimated Time**: 5-9 hours

---

## ⚠️ Critical Points

### 1. No JSON API
```dart
// ❌ WRONG
final response = await http.get('https://v2.doujindesu.fun/api/manga');
// Returns HTML, not JSON!

// ✅ CORRECT
final response = await http.get('https://v2.doujindesu.fun/manga');
final document = html_parser.parse(response.body);
```

### 2. Respect Rate Limits
```dart
// ❌ WRONG - Gets blocked
for (var i = 0; i < 100; i++) {
  await fetchManga(i);
}

// ✅ CORRECT - Respects limits
for (var i = 0; i < 100; i++) {
  await rateLimiter.wait();
  await fetchManga(i);
}
```

### 3. Handle Cloudflare
```dart
// ❌ WRONG - Fails on Cloudflare challenge
final response = await http.get(url);

// ✅ CORRECT - Realistic headers + delays
final response = await http.get(
  url,
  headers: {
    'User-Agent': 'Mozilla/5.0...',
    'Accept': 'text/html...',
    // ... more headers
  },
);
```

### 4. Extract from Script Tags
```dart
// ❌ WRONG - Data not in DOM
final title = document.querySelector('.title')?.text;

// ✅ CORRECT - Extract from embedded JSON
final scriptData = _extractNextJsData(response.body);
final title = scriptData['trending'][0]['title'];
```

---

## 📋 Checklist Before Implementation

- [ ] Read `doujindesuv2-analysis.md` completely
- [ ] Understand why NHentai approach won't work
- [ ] Review `doujindesuv2-config.json` structure
- [ ] Check `doujindesuv2-implementation-guide.md` code examples
- [ ] Have `html` package ready
- [ ] Have rate limiter implementation ready
- [ ] Understand Next.js SSR architecture
- [ ] Know how to parse HTML with CSS selectors
- [ ] Understand JSON extraction from script tags

---

## 🔗 Related Documentation

### In This Folder
- `doujindesuv2-analysis.md` - Deep dive analysis
- `doujindesuv2-config.json` - Configuration reference
- `doujindesuv2-implementation-guide.md` - Code examples
- `doujindesuv2-vs-existing-sources.md` - Comparison guide

### In Project
- `lib/data/datasources/remote/remote_data_source.dart` - Interface
- `lib/data/datasources/remote/remote_data_source_factory.dart` - Factory
- `lib/data/datasources/remote/nhentai_scraper.dart` - Reference implementation
- `assets/configs/nhentai-config.json` - Reference config

---

## 🎓 Learning Resources

### HTML Parsing in Dart
- [html package](https://pub.dev/packages/html)
- [CSS Selectors Guide](https://www.w3schools.com/cssref/css_selectors.asp)
- [HTML Parser Examples](https://github.com/google/html)

### Next.js SSR
- [Next.js Documentation](https://nextjs.org/docs)
- [Server-Side Rendering](https://nextjs.org/docs/basic-features/pages)
- [Data Fetching](https://nextjs.org/docs/basic-features/data-fetching)

### Rate Limiting
- [Rate Limiting Patterns](https://en.wikipedia.org/wiki/Rate_limiting)
- [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff)

---

## 🐛 Troubleshooting

### Issue: "FormatException: Unexpected character"
**Cause**: Trying to parse HTML as JSON  
**Solution**: Use `html_parser.parse()` instead of `json.decode()`

### Issue: "429 Too Many Requests"
**Cause**: Rate limiting exceeded  
**Solution**: Increase `minDelayMs` and `cooldownDurationMs` in RateLimiter

### Issue: "Empty data / No results"
**Cause**: Cloudflare blocking or wrong selectors  
**Solution**: Check headers, add delays, verify CSS selectors

### Issue: "Connection timeout"
**Cause**: Cloudflare challenge or network issue  
**Solution**: Increase timeout, add retry logic, check headers

---

## 📞 Support

### Questions About Analysis?
→ Read `doujindesuv2-analysis.md` again

### Questions About Implementation?
→ Check `doujindesuv2-implementation-guide.md` code examples

### Questions About Why Previous Approach Failed?
→ Read `doujindesuv2-vs-existing-sources.md`

### Questions About Configuration?
→ Reference `doujindesuv2-config.json`

---

## ✅ Verification Checklist

After implementation, verify:

- [ ] Can fetch manga list from homepage
- [ ] Can fetch manga detail page
- [ ] Can search for manga
- [ ] Can filter by type (manga/manhwa/doujinshi)
- [ ] Can filter by order (latest/popular)
- [ ] Rate limiting works (30 req/min)
- [ ] Cloudflare challenges handled
- [ ] Caching works (1 hour for lists, 24 hours for details)
- [ ] Error handling works
- [ ] Retry logic works
- [ ] No crashes or exceptions
- [ ] Performance acceptable (<2s per request)

---

## 📈 Performance Targets

```
Homepage Load: < 2 seconds
Manga List: < 2 seconds
Manga Detail: < 3 seconds
Search: < 3 seconds
Image Load: < 1 second (with caching)
```

---

## 🎯 Success Criteria

✅ **Implementation is successful when:**

1. Can scrape manga list from DoujinDesu v2
2. Can scrape manga detail pages
3. Respects rate limits (30 req/min)
4. Handles Cloudflare protection
5. Caches data appropriately
6. No crashes or errors
7. Performance is acceptable
8. Integrated with app UI

---

## 📝 Notes

### Why This Analysis Exists

The previous scraper from another repository failed because it assumed DoujinDesu v2 had a REST API like NHentai. This analysis explains:

1. **Why it failed**: No API endpoints exist
2. **What to do instead**: HTML scraping + JSON extraction
3. **How to implement**: Step-by-step guide with code
4. **How to avoid mistakes**: Common pitfalls and solutions

### Key Insight

> **Not all websites have APIs.** Modern frameworks like Next.js use Server-Side Rendering, which means data is embedded in HTML, not served as separate JSON. Always analyze the website first before assuming an approach.

---

## 🚀 Ready to Start?

1. **Read**: `doujindesuv2-analysis.md` (15 min)
2. **Understand**: `doujindesuv2-vs-existing-sources.md` (10 min)
3. **Code**: `doujindesuv2-implementation-guide.md` (30 min)
4. **Reference**: `doujindesuv2-config.json` (as needed)
5. **Implement**: Start coding!

---

**Created by**: Kiro AI Assistant  
**For**: Kuron App Development  
**Date**: 2026-05-10  
**Status**: ✅ Ready for Implementation

---

## 📊 File Summary

| File | Size | Purpose | Read Time |
|------|------|---------|-----------|
| `doujindesuv2-analysis.md` | ~8KB | Deep analysis | 15 min |
| `doujindesuv2-config.json` | ~12KB | Configuration | 5 min |
| `doujindesuv2-implementation-guide.md` | ~10KB | Code guide | 20 min |
| `doujindesuv2-vs-existing-sources.md` | ~8KB | Comparison | 15 min |
| `DOUJINDESUV2_README.md` | This file | Overview | 10 min |

**Total Documentation**: ~48KB | ~65 minutes to read all

---

**Siap bos! Dokumentasi lengkap sudah tersimpan di `informations/documentation/`**
