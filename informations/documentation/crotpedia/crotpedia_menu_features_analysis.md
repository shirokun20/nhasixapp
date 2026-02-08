# Crotpedia Menu & Features Deep Analysis

> **Document Version**: 1.0.0  
> **Created**: 2026-02-08  
> **Purpose**: Analisis mendalam untuk penambahan fitur menu khusus Crotpedia

---

## 📋 Overview

Dokumen ini menganalisis penambahan 4 fitur menu baru untuk source **Crotpedia**:

| No | Fitur | URL | Status |
|----|-------|-----|--------|
| 1 | Donasi | `https://trakteer.id/crotpedia/tip` | 🔄 External Link |
| 2 | Genre List | `https://crotpedia.net/genre-list/` | 🆕 New Feature |
| 3 | Doujinshi List | `https://crotpedia.net/doujin-list/` | 🆕 New Feature |
| 4 | Project Request | `https://crotpedia.net/baca/publisher/request/` | 🆕 New Feature |

---

## 🔗 1. Fitur Donasi

### 1.1 URL Trakteer
```
https://trakteer.id/crotpedia/tip
```

### 1.2 Implementasi yang Direkomendasikan

**Opsi A: External Link (Recommended)**
- Buka langsung ke browser eksternal menggunakan `url_launcher`
- Pattern sudah ada di `about_screen.dart` pada method `_launchURL()`

**Opsi B: WebView Internal**
- Gunakan `webview_flutter` untuk menampilkan halaman Trakteer dalam aplikasi

### 1.3 Perubahan di `crotpedia-config.json`

```json
{
  "menuConfig": {
    "donation": {
      "enabled": true,
      "url": "https://trakteer.id/crotpedia/tip",
      "label": "Support Crotpedia",
      "icon": "favorite",
      "openMode": "external"
    }
  }
}
```

### 1.4 Perubahan di `app_drawer_content.dart`

Tambahkan menu item baru di section Crotpedia-specific:

```dart
// Setelah login/account section, line ~186
if (context.watch<SourceCubit>().state.activeSource?.id == SourceType.crotpedia.id) ...[
  // ... existing account section ...
  
  // Donation section
  _buildSectionLabel('SUPPORT', theme),
  const SizedBox(height: 8),
  _buildExternalLinkItem(
    context,
    icon: Icons.favorite_rounded,
    label: 'Donasi ke Crotpedia',
    url: 'https://trakteer.id/crotpedia/tip',
    theme: theme,
  ),
],
```

---

## 📚 2. Fitur Genre List

### 2.1 URL dan Struktur HTML

**URL**: `https://crotpedia.net/genre-list/`

### 2.2 Analisis HTML Scraping

```html
<main>
  <div class="content">
    <div class="container">
      <h2><span>Genre</span> List</h2>
      <ul class="achlist">
        <li>
          <a href="https://crotpedia.net/baca/genre/ahegao/" title="Lihat Anime Ahegao">
            Ahegao<span>1013</span>
          </a>
        </li>
        <!-- ... more items ... -->
      </ul>
    </div>
  </div>
</main>
```

### 2.3 Data Model yang Harus Dibuat

```dart
/// File: lib/domain/entities/genre_item.dart
class GenreItem {
  final String name;      // "Ahegao"
  final String slug;      // "ahegao"
  final String url;       // "https://crotpedia.net/baca/genre/ahegao/"
  final int count;        // 1013
  
  const GenreItem({
    required this.name,
    required this.slug,
    required this.url,
    required this.count,
  });
}
```

### 2.4 CSS Selectors untuk Scraping

```json
{
  "scraper": {
    "selectors": {
      "genreList": {
        "container": "ul.achlist",
        "item": "ul.achlist li",
        "link": "li > a",
        "name": "li > a",
        "count": "li > a > span"
      }
    }
  }
}
```

### 2.5 Perubahan di `crotpedia-config.json`

Tambahkan di `scraper.selectors`:

```json
{
  "scraper": {
    "selectors": {
      // ... existing selectors ...
      "genreList": {
        "container": "ul.achlist",
        "item": "ul.achlist li",
        "link": "li > a",
        "name": "li > a",
        "count": "li > a > span"
      }
    },
    "urlPatterns": {
      // ... existing patterns ...
      "genreList": "/genre-list/",
      "genreDetail": "/baca/genre/{slug}/"
    }
  }
}
```

### 2.6 Features Config

```json
{
  "features": {
    // ... existing features ...
    "genreList": true
  }
}
```

### 2.7 Menu Config

```json
{
  "menuConfig": {
    "genreList": {
      "enabled": true,
      "endpoint": "/genre-list/",
      "label": "Genre List",
      "icon": "category"
    }
  }
}
```

---

## 📖 3. Fitur Doujinshi List

### 3.1 URL dan Struktur HTML

**URL**: `https://crotpedia.net/doujin-list/`

### 3.2 Analisis HTML Scraping

> [!IMPORTANT]
> **Halaman ini sangat besar!** File HTML memiliki **6915 baris** dengan struktur **alphabetical index (A-Z)**.

```html
<main>
  <div class="content">
    <div class="container">
      <h2><span>Doujin</span> List</h2>
      <div class="mangalist">
        <!-- Alphabet Navigation -->
        <div class="mangalist-nav">
          <a href="#A">A</a><a href="#B">B</a>...<a href="#Z">Z</a>
        </div>
      </div>
      
      <!-- Per-Alphabet Blocks -->
      <div class="mangalist-blc">
        <span><a name="A">A</a></span>
        <ul>
          <li class="Doujinshi">
            <a class="series" rel="20143" href="https://crotpedia.net/baca/series/a-capriccio/">
              A Capriccio
            </a>
          </li>
          <!-- ... more items ... -->
        </ul>
      </div>
      <!-- ... more alphabet blocks ... -->
    </div>
  </div>
</main>
```

### 3.3 Data Model

```dart
/// File: lib/domain/entities/doujin_list_item.dart
class DoujinListItem {
  final String id;        // "20143" (dari rel attribute)
  final String title;     // "A Capriccio"
  final String url;       // "https://crotpedia.net/baca/series/a-capriccio/"
  final String slug;      // "a-capriccio"
  final String type;      // "Doujinshi" (dari class li)
  final String alphabet;  // "A"
  
  const DoujinListItem({
    required this.id,
    required this.title,
    required this.url,
    required this.slug,
    required this.type,
    required this.alphabet,
  });
}
```

### 3.4 CSS Selectors untuk Scraping

```json
{
  "scraper": {
    "selectors": {
      "doujinList": {
        "container": ".mangalist-blc",
        "alphabetNav": ".mangalist-nav a",
        "alphabetBlock": ".mangalist-blc",
        "alphabetLabel": ".mangalist-blc > span > a",
        "itemList": ".mangalist-blc ul",
        "item": ".mangalist-blc ul li",
        "link": "a.series",
        "itemId": "a.series[rel]",
        "itemType": "li[class]"
      }
    }
  }
}
```

> [!CAUTION]
> ## 3.5 Pertimbangan Database Table untuk Doujinshi List
> 
> **REKOMENDASI: YA, PERLU DATABASE TABLE**
> 
> ### Alasan:
> 1. **Volume Data Besar**: ~2000+ entries dari file HTML
> 2. **Performa**: Load time akan lambat jika fetch setiap kali
> 3. **Offline Access**: Memungkinkan browsing offline
> 4. **Search/Filter Cepat**: Query lokal lebih cepat daripada parsing HTML
> 5. **Alphabetical Index**: Navigasi cepat ke huruf tertentu

### 3.6 Database Schema

```sql
-- File: migrations/doujin_list.sql
CREATE TABLE IF NOT EXISTS doujin_list (
  id INTEGER PRIMARY KEY,
  source_id TEXT NOT NULL DEFAULT 'crotpedia',
  internal_id TEXT NOT NULL,       -- rel attribute
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  slug TEXT NOT NULL,
  type TEXT DEFAULT 'Doujinshi',
  alphabet TEXT NOT NULL,          -- A, B, C, etc.
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(source_id, internal_id)
);

CREATE INDEX idx_doujin_list_alphabet ON doujin_list(source_id, alphabet);
CREATE INDEX idx_doujin_list_title ON doujin_list(source_id, title);
```

### 3.7 Sync Strategy

```dart
/// File: lib/data/repositories/doujin_list_repository.dart
class DoujinListRepository {
  /// Sync Strategy:
  /// 1. Check last sync timestamp
  /// 2. If older than 24 hours OR table empty, fetch from web
  /// 3. Parse HTML and upsert to database
  /// 4. Update sync timestamp
  
  Future<void> syncDoujinList() async {
    final lastSync = await _getLastSyncTime();
    final shouldSync = lastSync == null || 
        DateTime.now().difference(lastSync).inHours > 24;
    
    if (shouldSync) {
      final html = await _fetchDoujinListPage();
      final items = _parseDoujinList(html);
      await _upsertAll(items);
      await _updateSyncTime();
    }
  }
}
```

### 3.8 Perubahan Config

```json
{
  "scraper": {
    "urlPatterns": {
      "doujinList": "/doujin-list/"
    }
  },
  "features": {
    "doujinList": true
  },
  "menuConfig": {
    "doujinList": {
      "enabled": true,
      "endpoint": "/doujin-list/",
      "label": "Doujin List",
      "icon": "list_alt",
      "cacheEnabled": true,
      "cacheDurationHours": 24
    }
  }
}
```

---

## 📝 4. Fitur Project Request

### 4.1 URL dan Struktur HTML

**URL**: `https://crotpedia.net/baca/publisher/request/`

### 4.2 Analisis HTML Scraping

```html
<div class="content">
  <div class="container">
    <h2><span>Archive for</span> Request</h2>
    <div class="flexbox2">
      <div class="flexbox2-item">
        <div class="flexbox2-content">
          <a href="https://crotpedia.net/baca/series/..." title="...">
            <div class="flexbox2-thumb">
              <img src="https://i0.wp.com/cover.eromanga.cfd/..." alt="...">
              <div class="flexbox2-title">
                <span>Title Here</span>
                <span class="studio">Author Name</span>
              </div>
              <span class="adult">18+</span>
            </div>
          </a>
          <div class="flexbox2-side">
            <div class="type Doujinshi">Doujinshi</div>
            <div class="info">
              <div class="score"><i class="fa-solid fa-star"></i> 10</div>
              <div class="season">1 Chapter</div>
            </div>
            <div class="synops"><p>Synopsis here...</p></div>
            <div class="genres">
              <span>
                <a href=".../genre/ahegao/" rel="tag">Ahegao</a>, ...
              </span>
            </div>
          </div>
        </div>
      </div>
      <!-- More items... -->
    </div>
    
    <!-- Pagination -->
    <div class="pagination">
      <span aria-current="page" class="page-numbers current">1</span>
      <a class="page-numbers" href=".../page/2/">2</a>
      <a class="page-numbers" href=".../page/3/">3</a>
      <span class="page-numbers dots">…</span>
      <a class="page-numbers" href=".../page/10/">10</a>
      <a class="next page-numbers" href=".../page/2/">Berikutnya »</a>
    </div>
  </div>
</div>
```

### 4.3 Data Model

```dart
/// File: lib/domain/entities/request_item.dart
class RequestItem {
  final String title;
  final String url;
  final String coverUrl;
  final String author;        // studio class
  final String type;          // Doujinshi, Manga, etc.
  final double score;
  final String chapterCount;  // "1 Chapter", "2 Chapter"
  final String synopsis;
  final List<GenreTag> genres;
  
  const RequestItem({...});
}

class GenreTag {
  final String name;
  final String url;
  
  const GenreTag({required this.name, required this.url});
}
```

### 4.4 CSS Selectors untuk Scraping

> [!NOTE]
> Selector `flexbox2` sudah ada di config sebagai `search` selector. Bisa di-reuse!

```json
{
  "scraper": {
    "selectors": {
      "requestList": {
        "container": ".flexbox2",
        "item": ".flexbox2-item",
        "link": ".flexbox2-content > a",
        "cover": ".flexbox2-thumb img",
        "title": ".flexbox2-title > span:first-child",
        "author": ".flexbox2-title .studio",
        "type": ".flexbox2-side .type",
        "score": ".flexbox2-side .score",
        "chapterCount": ".flexbox2-side .season",
        "synopsis": ".flexbox2-side .synops p",
        "genres": ".flexbox2-side .genres a"
      }
    },
    "urlPatterns": {
      "requestList": "/baca/publisher/request/",
      "requestListPaginated": "/baca/publisher/request/page/{page}/"
    }
  }
}
```

### 4.5 Pagination Config

```json
{
  "requestPagination": {
    "urlPattern": "/baca/publisher/request/page/{page}/",
    "selectors": {
      "current": ".pagination .page-numbers.current",
      "next": ".pagination .next.page-numbers",
      "previous": ".pagination .prev.page-numbers",
      "links": ".pagination a.page-numbers:not(.next):not(.prev)"
    }
  }
}
```

### 4.6 Features & Menu Config

```json
{
  "features": {
    "requestList": true
  },
  "menuConfig": {
    "requestList": {
      "enabled": true,
      "endpoint": "/baca/publisher/request/",
      "label": "Project Request",
      "icon": "request_page",
      "hasPagination": true
    }
  }
}
```

---

## ⚙️ 5. Perubahan Lengkap di `crotpedia-config.json`

> [!IMPORTANT]
> Berikut adalah ringkasan SEMUA penambahan yang diperlukan:

```json
{
  "source": "crotpedia",
  "version": "1.2.0",  // Update version
  "lastUpdated": "2026-02-08T09:00:00+07:00",
  
  // ... existing config ...
  
  "scraper": {
    "selectors": {
      // ... existing selectors ...
      
      "genreList": {
        "container": "ul.achlist",
        "item": "ul.achlist li",
        "link": "li > a",
        "name": "li > a",
        "count": "li > a > span"
      },
      
      "doujinList": {
        "container": ".mangalist-blc",
        "alphabetNav": ".mangalist-nav a",
        "alphabetBlock": ".mangalist-blc",
        "alphabetLabel": ".mangalist-blc > span > a",
        "itemList": ".mangalist-blc ul",
        "item": ".mangalist-blc ul li",
        "link": "a.series",
        "itemId": "a.series[rel]",
        "itemType": "li[class]"
      },
      
      "requestList": {
        "container": ".flexbox2",
        "item": ".flexbox2-item",
        "link": ".flexbox2-content > a",
        "cover": ".flexbox2-thumb img",
        "title": ".flexbox2-title > span:first-child",
        "author": ".flexbox2-title .studio",
        "type": ".flexbox2-side .type",
        "score": ".flexbox2-side .score",
        "chapterCount": ".flexbox2-side .season",
        "synopsis": ".flexbox2-side .synops p",
        "genres": ".flexbox2-side .genres a"
      }
    },
    
    "urlPatterns": {
      // ... existing patterns ...
      "genreList": "/genre-list/",
      "genreDetail": "/baca/genre/{slug}/",
      "doujinList": "/doujin-list/",
      "requestList": "/baca/publisher/request/",
      "requestListPaginated": "/baca/publisher/request/page/{page}/"
    }
  },
  
  "features": {
    // ... existing features ...
    "genreList": true,
    "doujinList": true,
    "requestList": true,
    "donation": true
  },
  
  "menuConfig": {
    "donation": {
      "enabled": true,
      "url": "https://trakteer.id/crotpedia/tip",
      "label": "Donasi",
      "icon": "favorite",
      "openMode": "external"
    },
    "genreList": {
      "enabled": true,
      "endpoint": "/genre-list/",
      "label": "Genre List",
      "icon": "category"
    },
    "doujinList": {
      "enabled": true,
      "endpoint": "/doujin-list/",
      "label": "Doujin List",
      "icon": "list_alt",
      "cacheEnabled": true,
      "cacheDurationHours": 24
    },
    "requestList": {
      "enabled": true,
      "endpoint": "/baca/publisher/request/",
      "label": "Project Request",
      "icon": "request_page",
      "hasPagination": true
    }
  }
}
```

---

## 🗂️ 6. File-File yang Perlu Dibuat/Dimodifikasi

### 6.1 File Baru yang Perlu Dibuat

| File | Purpose |
|------|---------|
| `lib/domain/entities/genre_item.dart` | Entity untuk Genre List |
| `lib/domain/entities/doujin_list_item.dart` | Entity untuk Doujin List |
| `lib/domain/entities/request_item.dart` | Entity untuk Request List |
| `lib/data/models/genre_item_model.dart` | Model + JSON parsing |
| `lib/data/models/doujin_list_item_model.dart` | Model + JSON parsing |
| `lib/data/models/request_item_model.dart` | Model + JSON parsing |
| `lib/data/repositories/genre_list_repository.dart` | Repository patterns |
| `lib/data/repositories/doujin_list_repository.dart` | Repository + DB sync |
| `lib/data/repositories/request_list_repository.dart` | Repository patterns |
| `lib/presentation/pages/genre_list/genre_list_screen.dart` | UI Screen |
| `lib/presentation/pages/doujin_list/doujin_list_screen.dart` | UI Screen |
| `lib/presentation/pages/request_list/request_list_screen.dart` | UI Screen |
| `lib/presentation/blocs/genre_list/genre_list_bloc.dart` | BLoC |
| `lib/presentation/blocs/doujin_list/doujin_list_bloc.dart` | BLoC |
| `lib/presentation/blocs/request_list/request_list_bloc.dart` | BLoC |

### 6.2 File yang Perlu Dimodifikasi

| File | Changes |
|------|---------|
| `assets/configs/crotpedia-config.json` | Add all new config sections |
| `lib/presentation/widgets/app_drawer_content.dart` | Add menu items for Crotpedia |
| `lib/core/routing/app_route.dart` | Add new routes |
| `lib/core/routing/app_router.dart` | Register new routes |
| `lib/core/di/service_locator.dart` | Register new dependencies |
| `lib/data/datasources/local/database_helper.dart` | Add doujin_list table |
| `lib/l10n/app_*.arb` | Add localization strings |

---

## 📱 7. UI/UX Recommendations

### 7.1 Genre List Screen
- Grid layout dengan 2-3 columns
- Badge count di pojok kanan
- Click navigasi ke halaman genre detail (search dengan filter)

### 7.2 Doujin List Screen
- **Sticky Alphabet Bar** di atas (A-Z horizontal scroll)
- **Indexed ListView** dengan section headers per alphabet
- **Search Bar** untuk quick filter
- **Jump to Letter** widget

### 7.3 Request List Screen
- Standard list/grid view seperti home page
- Pagination dengan infinite scroll atau page numbers
- Filter by genre (optional)

---

## 🔄 8. Drawer Menu Structure Proposal

```
┌─────────────────────────┐
│  [Logo + App Name]      │
├─────────────────────────┤
│  SOURCE SELECTOR        │
│  ○ nhentai              │
│  ● Crotpedia ✓          │
│  ○ Komiktap             │
├─────────────────────────┤
│  ACCOUNT                │  ← Crotpedia only
│  👤 Login / Account     │
├─────────────────────────┤
│  CROTPEDIA              │  ← NEW SECTION
│  📋 Genre List          │
│  📚 Doujin List         │
│  📝 Project Request     │
│  ❤️ Donasi (External)   │
├─────────────────────────┤
│  HOME                   │
│  🏠 Home                │
│  📥 Downloaded          │
│  📴 Offline Content     │
├─────────────────────────┤
│  EXPLORE                │
│  ❤️ Favorites           │
│  📜 History             │
├─────────────────────────┤
│  MORE                   │
│  ⚙️ Settings            │
│  ℹ️ About               │
└─────────────────────────┘
```

---

## ✅ 9. Checklist Implementasi

### Phase 1: Config & Data Layer
- [ ] Update `crotpedia-config.json` dengan semua selectors dan patterns baru
- [ ] Buat database migration untuk `doujin_list` table
- [ ] Buat entities dan models baru
- [ ] Buat repositories dengan HTML parsing logic

### Phase 2: Business Logic
- [ ] Buat BLoCs untuk masing-masing fitur
- [ ] Implementasi sync strategy untuk Doujin List
- [ ] Register di service locator

### Phase 3: UI Layer
- [ ] Buat screens untuk Genre List, Doujin List, Request List
- [ ] Update `app_drawer_content.dart` dengan menu baru
- [ ] Add routes di app_route.dart dan app_router.dart
- [ ] Add localization strings

### Phase 4: Testing & Polish
- [ ] Unit tests untuk repositories
- [ ] Widget tests untuk screens
- [ ] Integration testing
- [ ] Performance optimization untuk Doujin List

---

## 📊 10. Ringkasan Keputusan

| Pertanyaan | Keputusan | Alasan |
|------------|-----------|--------|
| Perlu database untuk Doujin List? | **YA** | Data 2000+ items, perlu cache untuk performa |
| Donasi di dalam app atau external? | **External** | Lebih aman, tidak perlu handle payment |
| Pagination untuk Request? | **YA** | Ada 10+ halaman dari HTML |
| Reuse selector flexbox2? | **YA** | Struktur sama dengan search results |

---

## 🔗 11. URL Reference Summary

| Feature | URL | Type |
|---------|-----|------|
| Donasi | `https://trakteer.id/crotpedia/tip` | External |
| Genre List | `https://crotpedia.net/genre-list/` | Internal |
| Doujin List | `https://crotpedia.net/doujin-list/` | Internal + Cache |
| Request List | `https://crotpedia.net/baca/publisher/request/` | Internal + Pagination |
| Request Page N | `https://crotpedia.net/baca/publisher/request/page/{N}/` | Internal |
| Genre Detail | `https://crotpedia.net/baca/genre/{slug}/` | Internal |
| Series Detail | `https://crotpedia.net/baca/series/{slug}/` | Internal (existing) |
