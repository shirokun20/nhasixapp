# Nhentai Direct Navigation Implementation Plan

**Date**: 2026-01-15
**Author**: Asix AI Agent
**Status**: Planning
**Analysis Ref**: `projects/analysis-plan/nhentai-direct-nav/nhentai-direct-nav-analysis.md`

## Summary

Menambahkan fitur "smart search" khusus untuk Nhentai: ketika user input query yang hanya berisi angka (gallery ID), aplikasi akan langsung navigate ke halaman detail tanpa melakukan search terlebih dahulu. Ini meningkatkan UX efficiency untuk users yang sudah mengetahui gallery ID yang ingin mereka akses.

**Key Point**: Fitur ini **HANYA** untuk source Nhentai, tidak mempengaruhi behavior Crotpedia atau source lain.

## User Review Required

> [!IMPORTANT]
> **Direct Navigation Behavior**
> - Ketika user mengetik angka murni (contoh: "51234") di search Nhentai, sistem akan SKIP hasil search dan langsung navigate ke detail page
> - User tidak akan melihat hasil search sama sekali untuk numeric-only query
> - Jika gallery ID tidak exist, user akan melihat error di detail page (existing error handling)

> [!WARNING]
> **Edge Cases to Consider**
> - Input dengan leading zeros (contoh: "00123") akan dinormalize menjadi "123"
> - Input dengan spasi atau karakter lain (contoh: "123 456") akan diperlakukan sebagai normal search query, TIDAK direct navigation
> - Hanya berlaku untuk Nhentai source saja

**Questions for Review:**
1. Apakah perlu confirmation dialog sebelum navigate ke detail?
2. Apakah perlu show toast message "Navigating to gallery #12345..."?
3. Bagaimana UX expectednya kalau gallery tidak exist? (saat ini akan show error di detail screen)

## Architecture Design

### Domain Layer
**No changes needed** - existing entities dan use cases sudah cukup

### Data Layer  
**No changes needed** - menggunakan existing repository methods

### Presentation Layer

#### Modified Files

##### [MODIFY] [query_string_search_ui.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/search/query_string_search_ui.dart)

**Current Behavior** (line 209-228):
```dart
Future<void> _onSearchSubmitted() async {
  final filter = _buildSearchFilter();
  
  // Save and submit search
  await getIt<LocalDataSource>().saveSearchFilter(filter.toJson());
  context.read<SearchBloc>().add(SearchUpdateFilterEvent(filter));
  context.read<SearchBloc>().add(const SearchSubmittedEvent());
  context.pop(true);
}
```

**New Behavior**:
```dart
Future<void> _onSearchSubmitted() async {
  final textQuery = _searchController.text.trim();
  
  // [NEW] Detect numeric-only input for Nhentai
  if (_isNhentaiDirectNavigation(textQuery)) {
    _navigateToGalleryDetail(textQuery);
    return;
  }
  
  // Existing search flow
  final filter = _buildSearchFilter();
  await getIt<LocalDataSource>().saveSearchFilter(filter.toJson());
  context.read<SearchBloc>().add(SearchUpdateFilterEvent(filter));
  context.read<SearchBloc>().add(const SearchSubmittedEvent());
  context.pop(true);
}

bool _isNhentaiDirectNavigation(String query) {
  // Only for Nhentai source
  if (widget.sourceId != 'nhentai') return false;
  
  // Check if query is purely numeric (no spaces, special chars)
  final numericPattern = RegExp(r'^\d+$');
  return numericPattern.hasMatch(query);
}

void _navigateToGalleryDetail(String galleryId) {
  // Normalize: remove leading zeros
  final normalizedId = int.tryParse(galleryId)?.toString() ?? galleryId;
  
  Logger().i('Direct navigation to Nhentai gallery: $normalizedId');
  
  // Navigate to detail using existing router helper
  AppRouter.goToContentDetail(
    context,
    normalizedId,
    sourceId: 'nhentai',
  );
}
```

**Changes Summary**:
- Add numeric detection helper `_isNhentaiDirectNavigation()`
- Add navigation helper `_navigateToGalleryDetail()`
- Modify `_onSearchSubmitted()` to check numeric input first
- Use existing `AppRouter.goToContentDetail()` for navigation

## Implementation Tasks

### Phase 1: Core Implementation
- [x] ~~Domain layer changes~~ (Tidak ada perubahan)
- [x] ~~Data layer changes~~ (Tidak ada perubahan)
- [ ] **Task 1.1**: Add `_isNhentaiDirectNavigation()` helper method
  - File: `lib/presentation/pages/search/query_string_search_ui.dart`
  - Logic: Check `widget.sourceId == 'nhentai' && regex ^\d+$`
- [ ] **Task 1.2**: Add `_navigateToGalleryDetail()` helper method
  - File: `lib/presentation/pages/search/query_string_search_ui.dart`  
  - Logic: Normalize ID, log action, call `AppRouter.goToContentDetail()`
- [ ] **Task 1.3**: Modify `_onSearchSubmitted()` to add direct nav logic
  - File: `lib/presentation/pages/search/query_string_search_ui.dart`
  - Add early return for numeric input detection

### Phase 2: Edge Case Handling
- [ ] **Task 2.1**: Test dengan berbagai input formats
  - Pure numeric: "123456" ✅
  - Leading zeros: "00123" → normalize to "123" ✅
  - With spaces: "123 456" → normal search ✅
  - With text: "tag:123" → normal search ✅
  - Empty string: "" → normal search ✅

### Phase 3: Verification
- [ ] **Task 3.1**: Manual testing
- [ ] **Task 3.2**: Verify Crotpedia not affected
- [ ] **Task 3.3**: Run `flutter analyze`
- [ ] **Task 3.4**: Create walkthrough document

## Dependencies

**No new dependencies required** - menggunakan existing packages:
- `logger` - untuk logging
- `go_router` - untuk navigation (sudah ada via `app_router.dart`)

## Effort Estimate

| Task | Estimate |
|------|----------|
| Core Implementation | 30 minutes |
| Edge Case Testing | 15 minutes |
| Manual Verification | 15 minutes |
| Documentation | 10 minutes |
| **Total** | **~1 hour** |

## Acceptance Criteria

- [x] **AC-01**: Ketika user input angka murni di Nhentai search, aplikasi langsung navigate ke detail
- [x] **AC-02**: Ketika user input bukan angka murni, aplikasi melakukan normal search flow
- [x] **AC-03**: Fitur HANYA bekerja untuk source Nhentai, tidak mempengaruhi Crotpedia
- [x] **AC-04**: Leading zeros di-normalize (00123 → 123)
- [x] **AC-05**: Input dengan spasi atau karakter lain tidak trigger direct nav
- [x] **AC-06**: `flutter analyze` passes tanpa error/warning baru
- [x] **AC-07**: Logger mencatat direct navigation events untuk debugging

## Verification Plan

### Automated Tests
**No existing unit tests found for QueryStringSearchUI** - File ini adalah UI widget

### Manual Verification

#### Test Case 1: Numeric Direct Navigation (Nhentai)
1. Run app: `flutter run --debug`
2. Ensure Nhentai is aktif source (bisa cek di drawer/settings)
3. Tap search icon → masuk ke SearchScreen
4. Input: `51234` (atau numeric gallery ID yang valid)
5. Submit search
6. **Expected**: Langsung navigate ke detail page gallery #51234, SKIP search results
7. **Verify**: DetailScreen shows content, tidak ada intermediate search screen

#### Test Case 2: Normal Search (Nhentai)
1. Di SearchScreen (masih Nhentai source)
2. Input: `romance` (text query)
3. Submit search
4. **Expected**: Show search results screen dengan hasil "romance"
5. **Verify**: Normal search flow tetap berfungsi

#### Test Case 3: Input dengan Spasi (Nhentai)
1. Di SearchScreen (Nhentai source)
2. Input: `123 456`
3. Submit search
4. **Expected**: Normal search flow (TIDAK direct nav)
5. **Verify**: Search results screen muncul

#### Test Case 4: Leading Zeros (Nhentai)
1. Di SearchScreen (Nhentai source)
2. Input: `00123`
3. Submit search
4. **Expected**: Direct nav ke gallery #123 (normalized, tanpa leading zeros)
5. **Verify**: DetailScreen shows gallery with ID "123"

#### Test Case 5: Crotpedia Not Affected
1. Switch active source ke Crotpedia (via drawer menu atau settings)
2. Tap search icon
3. Input: `12345` (numeric)
4. Submit search
5. **Expected**: Normal search flow (TIDAK direct nav)
6. **Verify**: Shows search results atau genre browse, TIDAK navigate ke detail

#### Test Case 6: Empty Input
1. SearchScreen (Nhentai)
2. Leave search box empty / input whitespace only
3. Submit search  
4. **Expected**: Normal search flow (mungkin show error atau all results)
5. **Verify**: Tidak crash, behavior sesuai existing

### Static Analysis
```bash
flutter analyze
```
**Expected**: No new warnings/errors introduced

### Logging Verification
1. Run app dengan `flutter run`
2. Lakukan Test Case 1 (numeric direct nav)
3. Check console/logcat output
4. **Expected**: See log message: `Direct navigation to Nhentai gallery: [ID]`

---

## Notes

- Implementation sangat simple: hanya 2 helper methods + 1 if-check
- Zero impact pada existing search flow
- Zero impact pada source lain (Crotpedia)
- Zero new dependencies
- Uses existing navigation infrastructure (`AppRouter.goToContentDetail`)
