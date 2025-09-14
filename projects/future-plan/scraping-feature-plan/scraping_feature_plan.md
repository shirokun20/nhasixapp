# Scraping Feature Plan for NhasixApp

## Overview
This plan outlines the implementation of a web scraping feature for NhasixApp to fetch manga and image content from three websites: e-hentai.org, hitomi.la, and pixhentai.com. The feature will focus exclusively on images and manga content, ignoring video content. This is a future plan requiring careful consideration of legal, technical, and ethical aspects.

## Background Analysis
- **e-hentai.org**: Large hentai gallery system with doujinshi, manga, and image sets. No official API detected. Content is organized by categories, tags, and uploader. Simple search with basic tag filtering, rich metadata including uploader, rating, and detailed tags.
- **hitomi.la**: Indonesian-focused hentai manga site with tag-based organization. Has "nozomi.la" integration which may provide API-like access. No official API found. Simple tag navigation, focused on manga content.
- **pixhentai.com**: WordPress-based hentai comic site with categories and tags. No official API detected. Standard blog-style search and categorization.
- **API Availability**: No official APIs found for any of the three websites. Scraping will be necessary using HTTP requests and HTML parsing.
- **Library Research**: No specific API libraries found for these sites. Will use standard Flutter packages like `http`, `html`, and `dio`.

## Detailed Website Analysis

### e-hentai.org Scraping Details
- **Search Mechanism**: Uses `f_search` parameter in URL (e.g., `?f_search=keyword&page=1`). Supports simple search with basic tag filtering.
- **Language Filtering**: Focus on Indonesian (if available) and English content only. Skip other languages.
- **Tags Extraction**: Tags displayed in gallery list and detail pages. Extract from class `.gt` elements, includes namespaces like `f:` (female), `m:` (male), etc.
- **Pagination**: Next/previous links with `?next=ID` format. Page numbers not directly available, use sequential loading.
- **Content Structure**: Each gallery has thumbnail, title, uploader, page count, and tags. Detail page contains image URLs.
- **Image URLs**: Extract from gallery detail pages, images hosted on `ehgt.org` or similar.
- **CSS Selectors** (from HTML analysis): Gallery items: `.gl1t`, Titles: `.glname`, Thumbnails: `img`, Tags: `.gt a`, Pagination: `.ptt td a`.
- **Language Detection**: Extract language from tags or content metadata (look for Indonesian language tags).
- **Completeness**: Most comprehensive due to rich metadata, simple search, and large content variety.

### hitomi.la Scraping Details
- **Search Mechanism**: Primarily tag-based search via `/tag/tagname-1.html`. Indonesian content via `/index-indonesian.html?page=1`.
- **Language Filtering**: Focus on English and Javanese content only. Skip other languages.
- **Tags Extraction**: Tags listed on gallery pages, extract from `.tag` elements. No namespaces, simpler tag system.
- **Pagination**: Simple page numbers in URL (e.g., `?page=2`). Limited to Indonesian index.
- **Content Structure**: Focus on manga, each entry has thumbnail, title, artist, and basic tags.
- **Image URLs**: Images accessed via reader URLs, need to parse reader pages for actual image links.
- **CSS Selectors** (from HTML analysis): Gallery covers: `.gallery-content .cover img`, Titles: `.gallery-content h3 a`, Tags: `.tag`, Pagination: `.page-list a`.
- **Language Detection**: Extract language from content metadata or URL patterns (e.g., `/index-indonesian.html` for Indonesian, detect Javanese from tags).
- **Completeness**: Less comprehensive than e-hentai, focused on Indonesian-translated content, simpler metadata.

### pixhentai.com Scraping Details
- **Search Mechanism**: WordPress search using `?s=keyword` parameter. Category-based filtering via `/category/name/`.
- **Language Filtering**: Focus on Indonesian (if available) and English content only. Skip other languages.
- **Tags Extraction**: Tags and categories displayed in post metadata. Extract from `.tag` or category links.
- **Pagination**: Standard WordPress pagination with `/page/2/` format.
- **Content Structure**: Blog-style posts containing comic images. Each post has title, thumbnail, and content with embedded images.
- **Image URLs**: Images directly in post content, extract from `<img>` tags within post body.
- **CSS Selectors** (from Playwright snapshot): Posts: `article`, Thumbnails: `article img`, Titles: `article h2 a`, Content: `article .entry-content img`, Categories: `.cat-links a`, Pagination: `.pagination a`.
- **Language Detection**: Extract language from post content or category names (look for Indonesian language indicators).
- **Completeness**: Basic search and categorization, least comprehensive of the three, more like a blog than dedicated gallery.

## Detailed Website Analysis

### e-hentai.org Scraping Details
- **Search Mechanism**: Uses `f_search` parameter in URL (e.g., `?f_search=keyword&page=1`). Supports simple search with basic tag filtering.
- **Tags Extraction**: Tags displayed in gallery list and detail pages. Extract from class `.gt` elements, includes namespaces like `f:` (female), `m:` (male), etc.
- **Pagination**: Next/previous links with `?next=ID` format. Page numbers not directly available, use sequential loading.
- **Content Structure**: Each gallery has thumbnail, title, uploader, page count, and tags. Detail page contains image URLs.
- **Image URLs**: Extract from gallery detail pages, images hosted on `ehgt.org` or similar.
- **CSS Selectors** (from HTML analysis): Gallery items: `.gl1t`, Titles: `.glname`, Thumbnails: `img`, Tags: `.gt a`, Pagination: `.ptt td a`.
- **API Detection**: No official API found. Network requests show only ad servers, no data APIs. All data via HTML scraping.
- **JavaScript Dependencies**: May require JS execution for dynamic content, but basic structure is static HTML.
- **Completeness**: Most comprehensive due to rich metadata, simple search, and large content variety.

### hitomi.la Scraping Details
- **Search Mechanism**: Primarily tag-based search via `/tag/tagname-1.html`. Indonesian content via `/index-indonesian.html?page=1`.
- **Tags Extraction**: Tags listed on gallery pages, extract from `.tag` elements. No namespaces, simpler tag system.
- **Pagination**: Simple page numbers in URL (e.g., `?page=2`). Limited to Indonesian index.
- **Content Structure**: Focus on manga, each entry has thumbnail, title, artist, and basic tags.
- **Image URLs**: Images accessed via reader URLs, need to parse reader pages for actual image links.
- **CSS Selectors** (from HTML analysis): Gallery covers: `.gallery-content .cover img`, Titles: `.gallery-content h3 a`, Tags: `.tag`, Pagination: `.page-list a`.
- **API Detection**: No official API. Network requests primarily ads. May have internal APIs for image loading (e.g., via JS fetch).
- **JavaScript Dependencies**: Image URLs may be loaded dynamically via JS, requiring headless browser for full extraction.
- **Completeness**: Less comprehensive than e-hentai, focused on Indonesian-translated content, simpler metadata.

### pixhentai.com Scraping Details
- **Search Mechanism**: WordPress search using `?s=keyword` parameter. Category-based filtering via `/category/name/`.
- **Tags Extraction**: Tags and categories displayed in post metadata. Extract from `.tag` or category links.
- **Pagination**: Standard WordPress pagination with `/page/2/` format.
- **Content Structure**: Blog-style posts containing comic images. Each post has title, thumbnail, and content with embedded images.
- **Image URLs**: Images directly in post content, extract from `<img>` tags within post body.
- **CSS Selectors** (from Playwright snapshot): Posts: `article`, Thumbnails: `article img`, Titles: `article h2 a`, Content: `article .entry-content img`, Categories: `.cat-links a`, Pagination: `.pagination a`.
- **API Detection**: No official API. Network requests show WordPress AJAX calls for dynamic content, but no REST API for content access.
- **JavaScript Dependencies**: Minimal, content is mostly static HTML. Some lazy loading for images.
- **Completeness**: Basic search and categorization, least comprehensive of the three, more like a blog than dedicated gallery.

### Overall API and Technical Analysis
- **API Availability**: None of the three websites expose official REST APIs for content access. All require web scraping.
- **Network Patterns**: 
  - e-hentai: Heavy ad network traffic, no data APIs.
  - hitomi: Similar ad patterns, possible internal JS APIs for image serving.
  - pixhentai: WordPress standard requests, AJAX for dynamic elements.
- **Anti-Scraping Measures**: 
  - e-hentai/hitomi: Likely Cloudflare or similar protection causing navigation errors in automation.
  - pixhentai: Standard WordPress, more permissive.
- **Data Loading**: 
  - Static HTML for metadata, dynamic JS for image URLs (especially hitomi).
  - Rate limiting likely on all sites.
- **Legal Considerations**: No ToS explicitly forbidding scraping, but adult content requires careful handling.

## Requirements
### Functional Requirements
- Search content by keywords/tags across all three websites
- Display search results in gallery format
- View detailed content with image lists
- Download and cache images locally
- Support pagination for large result sets
- Offline viewing of downloaded content
- **Language filtering by source**:
  - hitomi.la: English and Javanese only
  - e-hentai.org & pixhentai.com: Indonesian (if available) and English only
- Respect website terms of service and robots.txt
- Rate limiting to avoid overloading servers

### Non-Functional Requirements
- Performance: Efficient parsing and caching
- Security: No storage of sensitive user data
- Reliability: Robust error handling for network issues
- Maintainability: Clean Architecture compliance
- Ethics: Adult content warnings and user consent

### Technical Requirements
- Flutter packages: `http`, `html`, `dio`, `path_provider`
- Data models for content, images, tags
- Service layer for scraping logic
- Repository pattern for data access
- Bloc/Cubit for state management
- Error handling with custom exceptions

## Specifications
### Data Models
```dart
class ScrapedContent {
  final String id;
  final String title;
  final String source; // 'ehentai', 'hitomi', 'pixhentai'
  final List<String> tags;
  final List<String> imageUrls;
  final String thumbnailUrl;
  final int pageCount;
  final DateTime uploadDate;
}

class SearchQuery {
  final String keyword;
  final List<String> tags;
  final String source;
  final int page;
  final int limit;
}
```

### Architecture Integration
- **Domain Layer**: Add `ScrapingRepository` interface, `SearchContent` usecase
- **Data Layer**: Implement `ScrapingRepositoryImpl` with HTTP clients
- **Presentation Layer**: Add search screen, gallery widget, detail screen
- **Core Layer**: Add scraping service to DI container

### API Endpoints (Estimated)
- e-hentai: `https://e-hentai.org/?f_search={query}&page={page}`
- hitomi: `https://hitomi.la/index-indonesian.html?page={page}` + tag filtering
- pixhentai: `https://pixhentai.com/?s={query}&page={page}`

## Tasks
### Phase 1: Research and Foundation (1 week)
1. Detailed analysis of website HTML structures
2. Identify stable CSS selectors for content extraction
3. Create data models and entities
4. Set up basic HTTP client configuration
5. Implement rate limiting and user-agent rotation

### Phase 2: Core Scraping Implementation (2 weeks)
1. Implement e-hentai.org scraper service
2. Implement hitomi.la scraper service
3. Implement pixhentai.com scraper service
4. Create unified scraping repository
5. Add search and pagination logic
6. Implement image URL extraction and validation

### Phase 3: UI and Integration (1 week)
1. Create search input screen
2. Implement gallery grid view
3. Add content detail screen with image viewer
4. Integrate download functionality
5. Add loading states and error handling UI
6. Connect with existing app navigation

### Phase 4: Testing and Polish (1 week)
1. Unit tests for scraping services
2. Integration tests for repositories
3. UI tests for new screens
4. Performance testing with large result sets
5. Error handling validation
6. Documentation and code review

## Risks and Mitigation
### Technical Risks
- **Website Structure Changes**: Mitigation - Use flexible selectors, monitor with automated tests
- **IP Blocking**: Mitigation - Rate limiting, user-agent rotation, proxy support
- **Large Content**: Mitigation - Pagination, lazy loading, background processing

### Legal/Ethical Risks
- **Terms of Service Violation**: Mitigation - Research ToS, implement opt-in with warnings
- **Adult Content**: Mitigation - Age verification, content warnings, user consent
- **Copyright Issues**: Mitigation - No redistribution, personal use only disclaimer

### Performance Risks
- **Slow Scraping**: Mitigation - Concurrent requests with limits, caching
- **Memory Usage**: Mitigation - Stream processing, garbage collection
- **Language Detection Overhead**: Mitigation - Efficient pattern matching, caching
- **Network Issues**: Mitigation - Retry logic, offline fallbacks

## Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  html: ^0.15.4
  dio: ^5.3.2
  path_provider: ^2.1.1
  cached_network_image: ^3.3.0
```

## Success Criteria
- Successfully scrape content from all three websites
- Display results in user-friendly gallery format
- Download and view images offline
- **Implement accurate language filtering per source**
- Handle errors gracefully
- Pass all tests and code review
- No violations of website terms

## Future Enhancements
- Support for additional websites
- Enhanced search with more tag options
- Batch download functionality
- Content recommendation system
- **Multi-language support expansion**
- Cloud sync for downloaded content

## Timeline
- **Week 1-2**: Research and core implementation (with language analysis)
- **Week 3**: UI development
- **Week 4**: Testing and deployment

## Resources Needed
- Flutter developer (1)
- Web scraping knowledge
- **Language detection and NLP expertise**
- Testing environment
- Legal review for adult content handling

## Source-Specific Feature Limitations

### Unified Simple Features for All Sources
- **Simple Search**: Basic keyword and tag search across all sources
- **Tag/Category Filtering**: Dropdown or chips for tag/category selection
- **No Advanced Filters**: Keep interface simple and consistent
- **Unified UI**: Same search components for all sources

### UI Adaptation Logic
- Simple filter UI for all sources
- Consistent search experience
- No complex filter state management
- Basic tag selection across all sources