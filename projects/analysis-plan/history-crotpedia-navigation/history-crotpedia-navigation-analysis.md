# History Navigation for Crotpedia Chapters - Analysis

**Date**: 2026-01-15  
**Author**: Antigravity AI  
**Status**: Analysis  

## Overview

User melaporkan bahwa pada halaman `/history`, ketika user mengklik item history untuk content dari Crotpedia, aplikasi navigasi ke detail screen. Ini tidak tepat karena:
1. Sistem Crotpedia menggunakan chapter-based structure (berbeda dengan Nhentai yang series-based)
2. Yang disimpan ke tabel history adalah **chapter** (bukan series)
3. Klik pada chapter seharusnya langsung ke reader screen, bukan detail screen

## Current State

### 1. Data Model & Entity

#### Content Entity (`kuron_core/lib/src/entities/content.dart`)
```dart
class Content extends Equatable {
  final String id;              // Content ID (varies by source)
  final String sourceId;        // 'nhentai', 'crotpedia'
  final List<Chapter>? chapters; // NULL for nhentai, FILLED for crotpedia series
  // ... other fields
}
```

#### Chapter Entity (`kuron_core/lib/src/entities/chapter.dart`)
```dart
class Chapter extends Equatable {
  final String id;      // Chapter ID/slug
  final String title;   // "Chapter 1"
  final String url;     // Chapter URL/slug untuk fetching
  // ... other fields
}
```

#### History Entity (`lib/domain/entities/history.dart`)
```dart
class History extends Equatable {
  final String contentId;  // BISA berisi:
                           // - Series ID (nhentai: "123456")
                           // - Chapter ID (crotpedia: "manga-slug-chapter-1")
  final String sourceId;   // 'nhentai' atau 'crotpedia'
  final String? title;     // Chapter title atau series title
  final String? coverUrl;
  // ... other fields
}
```

### 2. Current Navigation Flow

#### File: [history_screen.dart:L324-329](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart#L324-L329)
```dart
void _navigateToContent(BuildContext context, History historyItem) {
  // Navigate to content detail/reader with sourceId
  context.push(
    '/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}',
  );
}
```

**Route:** `/content/{id}?sourceId={sourceId}`  
**Destination:** `DetailScreen` (always!)

#### File: [app_router.dart:L118-135](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/core/routing/app_router.dart#L118-L135)
```dart
GoRoute(
  path: AppRoute.contentDetail, // '/content/:id'
  name: AppRoute.contentDetailName,
  pageBuilder: (context, state) {
    final contentId = state.pathParameters['id']!;
    final sourceId = state.uri.queryParameters['sourceId'];
    return AppAnimations.animatedPageBuilder(
      context,
      state,
      DetailScreen(
        contentId: contentId,
        sourceId: sourceId,
      ),
      type: RouteTransitionType.fadeSlide,
    );
  },
),
```

### 3. How History is Saved

#### File: [reader_cubit.dart:L605-621](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/cubits/reader/reader_cubit.dart#L605-L621)
```dart
Future<void> _saveToHistory() async {
  try {
    final params = AddToHistoryParams.fromString(
      state.content!.id,        // ← CHAPTER ID for Crotpedia!
      state.currentPage ?? 1,
      state.content!.pageCount,
      timeSpent: state.readingTimer ?? Duration.zero,
      title: state.content!.title,
      coverUrl: state.content!.coverUrl,
      sourceId: state.content!.sourceId,
    );
    await addToHistoryUseCase(params);
  } catch (e) {
    // Log error but don't emit error state for history saving
  }
}
```

**Key Insight:** Ketika user membaca chapter Crotpedia, yang disimpan adalah:
- `contentId` = Chapter ID (misal: "manga-slug-chapter-5")
- `sourceId` = "crotpedia"
- `title` = Chapter title (misal: "Chapter 5 - Battle Arc")

## Requirements Analysis

### Functional Requirements

#### FR-01: Crotpedia Chapter Navigation
**Deskripsi:** Ketika user mengklik item history dari Crotpedia, aplikasi harus langsung membuka reader screen (bukan detail screen).

**Reasoning:**
- Crotpedia yang disimpan adalah **chapter**, bukan series
- User ingin melanjutkan membaca dari halaman terakhir di chapter tersebut
- Navigasi ke detail screen akan menampilkan series info dan list chapter, yang tidak relevan karena user sudah tahu chapter mana yang mau dibaca

#### FR-02: Nhentai Navigation (Backward Compatibility)
**Deskripsi:** Untuk Nhentai, navigasi tetap ke detail screen seperti sebelumnya.

**Reasoning:**
- Nhentai tidak memiliki chapter system
- Yang disimpan di history adalah series ID
- User mungkin ingin melihat detail/tags sebelum lanjut baca

#### FR-03: History Data Integrity
**Deskripsi:** Tidak ada perubahan pada cara menyimpan history data.

**Reasoning:**
- Current implementation sudah benar menyimpan chapter ID untuk Crotpedia
- Perubahan hanya pada navigation logic, bukan data storage

### Non-Functional Requirements

#### NFR-01: Performance
- Navigation decision harus instant (no additional API calls)
- Harus menggunakan data yang sudah ada di History entity

#### NFR-02: Maintainability
- Solution harus mudah di-extend untuk source baru di masa depan
- Clear separation of concerns antara source-specific logic

#### NFR-03: User Experience
- Smooth transition ke reader screen
- Preserve last read page dari history

## Technical Analysis

### Impact Analysis

#### Affected Components

1. **Presentation Layer**
   - ✅ [history_screen.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart) - **MODIFY**
     - Method: `_navigateToContent()`
   
2. **Core/Routing Layer**
   - ✅ [app_router.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/core/routing/app_router.dart) - **NO CHANGES** (route sudah ada)
   - ✅ Navigation helper methods - **OPTIONAL** (bisa tambahkan helper)

#### Dependencies Analysis

**Current Dependencies:**
- ✅ `History` entity - no changes needed
- ✅ `AppRouter` - existing routes sufficient
- ✅ Reader route: `/reader/{id}` - already exists
- ✅ Detail route: `/content/{id}` - already exists

**New Dependencies:**
- ❌ NONE needed

### Architecture Impact

```
History Screen
     │
     ├─ Nhentai Item Click
     │    └─> Detail Screen (/content/{seriesId})
     │
     └─ Crotpedia Item Click
          └─> Reader Screen (/reader/{chapterId})
```

**Changes Required:**
1. Add source detection logic di `_navigateToContent()`
2. Route ke `/reader/{id}` untuk Crotpedia
3. Route ke `/content/{id}` untuk Nhentai (existing)

## Solution Approaches

### Option 1: Source-Based Navigation (RECOMMENDED) ⭐

**Approach:**
Detect source dari `History.sourceId` dan route accordingly.

**Pros:**
- ✅ Simple & straightforward
- ✅ Zero new dependencies
- ✅ Easy to extend for new sources
- ✅ Minimal code changes

**Cons:**
- ⚠️ Assumes all Crotpedia history items are chapters (currently TRUE)

**Implementation:**
```dart
void _navigateToContent(BuildContext context, History historyItem) {
  // Source-aware navigation
  if (historyItem.sourceId == 'crotpedia') {
    // Crotpedia: Navigate to reader (chapter-based)
    context.push('/reader/${historyItem.contentId}');
  } else {
    // Nhentai & others: Navigate to detail (series-based)
    context.push(
      '/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}',
    );
  }
}
```

**Estimated Effort:** 5 minutes

---

### Option 2: Add `isChapter` Flag to History Entity

**Approach:**
Add new field `isChapter: bool` ke History entity untuk explicit marking.

**Pros:**
- ✅ More explicit & future-proof
- ✅ Works even if Crotpedia later supports series-level history

**Cons:**
- ❌ Requires domain layer changes
- ❌ Requires data layer migration
- ❌ Database schema change needed
- ❌ Much higher complexity

**Implementation:**
```dart
// Domain entity
class History {
  final bool isChapter; // NEW field
  // ...
}

// Navigation
void _navigateToContent(BuildContext context, History historyItem) {
  if (historyItem.isChapter) {
    context.push('/reader/${historyItem.contentId}');
  } else {
    context.push('/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}');
  }
}
```

**Estimated Effort:** 2-3 hours

---

### Option 3: Check Content Type via API

**Approach:**
Call API to check if contentId is a chapter or series before navigation.

**Pros:**
- ✅ 100% accurate

**Cons:**
- ❌ Requires network call on every click
- ❌ Slow UX (loading state needed)
- ❌ Fails offline
- ❌ Unnecessary complexity

**Estimated Effort:** 1-2 hours

## Risks & Considerations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Source ID mismatch** | Medium | Add validation di history saving |
| **Future sources** | Low | Document pattern di code comments |
| **Crotpedia series-level history** | Low | Currently not implemented, safe to hardcode |
| **Deep link support** | Low | Consider di implementation plan |

## Open Questions

- [x] **Q1:** Apakah Crotpedia akan support series-level history di masa depan?  
  **A1:** Tidak. Crotpedia selalu chapter-based. Safe to use source-based detection.

- [x] **Q2:** Apakah perlu preserve last page ketika navigate ke reader?  
  **A2:** Ya, History entity sudah menyimpan `lastPage`. Reader screen sudah support `initialPage` parameter.

- [x] **Q3:** Apakah perlu loading state untuk navigation?  
  **A3:** Tidak. Navigation langsung tanpa API call.

- [ ] **Q4:** Apakah user ingin lihat detail button di history item untuk Crotpedia?  
  **A4:** Perlu konfirmasi user. Bisa tambahkan secondary action button.

## Recommendations

### Primary Recommendation: **Option 1** - Source-Based Navigation

**Reasoning:**
1. ✅ **Simplicity:** Hanya 1 file edit, ~10 baris code
2. ✅ **Performance:** Zero overhead, instant navigation
3. ✅ **Maintainability:** Easy to understand & extend
4. ✅ **Risk:** Very low, isolated change
5. ✅ **Effort:** 5 minutes vs 2-3 hours for Option 2

**Implementation Steps:**
1. Modify `_navigateToContent()` di [history_screen.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart)
2. Add source detection logic
3. Route to reader for Crotpedia, detail for others
4. Test dengan Crotpedia & Nhentai history items

### Additional Enhancements (OPTIONAL)

1. **Secondary Action Button:**
   - Add "View Series" button untuk Crotpedia items
   - Navigate to series detail screen dari chapter ID

2. **Navigation Helper:**
   - Extract logic ke `AppRouter.navigateFromHistory()`
   - Centralize source-based routing logic

3. **Analytics:**
   - Track source-specific navigation patterns
   - Monitor user bounce rate dari reader

## Next Steps

1. **User Confirmation:**
   - Konfirmasi bahwa solution approach sudah sesuai
   - Tanya apakah perlu secondary action button untuk "View Series"

2. **Move to Planning:**
   - Create implementation plan di `future-plan/`
   - Detail verification strategy

3. **Implementation:**
   - Execute changes
   - Manual testing dengan kedua sources
   - Update task.md progress

## References

- [History Screen Implementation](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart)
- [App Router Configuration](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/core/routing/app_router.dart)
- [History Entity](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/domain/entities/history.dart)
- [Content Entity](file:///Users/asix/Documents/learn_flutter/nhasixapp/packages/kuron_core/lib/src/entities/content.dart)
- [Chapter Entity](file:///Users/asix/Documents/learn_flutter/nhasixapp/packages/kuron_core/lib/src/entities/chapter.dart)
- [Reader Cubit](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/cubits/reader/reader_cubit.dart)
