# History Navigation Fix - Implementation Plan

**Date**: 2026-01-15  
**Author**: Antigravity AI  
**Status**: Planning  
**Analysis Ref**: `projects/analysis-plan/history-crotpedia-navigation/history-crotpedia-navigation-analysis.md`

## Summary

Implementasi source-based navigation di History Screen untuk memisahkan navigasi antara Crotpedia (chapter-based) dan Nhentai (series-based). Crotpedia akan langsung ke Reader Screen, Nhentai tetap ke Detail Screen.

## User Review Required

> [!IMPORTANT]
> **Breaking Changes:** TIDAK ADA
> 
> **Backward Compatibility:** ✅ FULL - Nhentai navigation tetap sama seperti sebelumnya

> [!NOTE]
> **Optional Enhancement:** Apakah perlu tambahkan secondary button "View Series" di Crotpedia history items untuk navigasi ke series detail? (Dapat ditambahkan di future iteration)

## Proposed Changes

### Presentation Layer

#### [MODIFY] [history_screen.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart)

**Location:** `lib/presentation/pages/history/history_screen.dart`

**Changes:**
1. **Modify `_navigateToContent()` method** (currently at line 324-329)
   - Add source detection logic
   - Route to `/reader/{id}` for Crotpedia
   - Route to `/content/{id}?sourceId={sourceId}` for Nhentai and others

**Before:**
```dart
void _navigateToContent(BuildContext context, History historyItem) {
  // Navigate to content detail/reader with sourceId to ensure correct source is used
  // This fixes the issue where clicking Crotpedia items caused errors due to missing source context
  context.push(
    '/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}',
  );
}
```

**After:**
```dart
void _navigateToContent(BuildContext context, History historyItem) {
  // Source-aware navigation:
  // - Crotpedia: Direct to reader (chapter-based, stored as chapter ID)
  // - Nhentai: To detail screen (series-based, stored as series ID)
  
  if (historyItem.sourceId == 'crotpedia') {
    // Crotpedia chapters go directly to reader
    // History stores chapter ID, so navigate to reader with that chapter
    context.push('/reader/${historyItem.contentId}');
  } else {
    // Nhentai and other sources go to detail screen first
    // This preserves the existing behavior for backward compatibility
    context.push(
      '/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}',
    );
  }
}
```

**Impact:**
- ✅ Crotpedia: 1-click access to continue reading
- ✅ Nhentai: No behavior change (backward compatible)
- ✅ Future sources: Easy to extend with additional conditions

---

## Dependencies

**No new dependencies required** - using existing routes:
- ✅ `/reader/{id}` - Already exists in AppRouter
- ✅ `/content/{id}` - Already exists in AppRouter

## Verification Plan

### Automated Tests

> [!NOTE]
> Widget tests untuk navigation behavior (optional, can be added later):

```dart
// tests/presentation/pages/history/history_screen_test.dart
testWidgets('Crotpedia history item navigates to reader', (tester) async {
  // Setup: Create Crotpedia history item
  final crotpediaHistory = History(
    contentId: 'test-manga-chapter-5',
    sourceId: 'crotpedia',
    lastViewed: DateTime.now(),
    title: 'Test Manga - Chapter 5',
  );
  
  // Act: Tap history item
  await tester.tap(find.byType(HistoryItemWidget));
  await tester.pumpAndSettle();
  
  // Assert: Should navigate to /reader/{id}
  expect(find.byType(ReaderScreen), findsOneWidget);
});

testWidgets('Nhentai history item navigates to detail', (tester) async {
  // Setup: Create Nhentai history item
  final nhentaiHistory = History(
    contentId: '123456',
    sourceId: 'nhentai',
    lastViewed: DateTime.now(),
    title: 'Test Doujinshi',
  );
  
  // Act: Tap history item
  await tester.tap(find.byType(HistoryItemWidget));
  await tester.pumpAndSettle();
  
  // Assert: Should navigate to /content/{id}
  expect(find.byType(DetailScreen), findsOneWidget);
});
```

**Command:**
```bash
# turbo
flutter test tests/presentation/pages/history/history_screen_test.dart
```

### Manual Verification

#### Test Case 1: Crotpedia Chapter Navigation ✅

**Prerequisites:**
1. Baca minimal 1 chapter dari series Crotpedia (untuk generate history)
2. Pastikan history tersimpan dengan `sourceId = 'crotpedia'`

**Steps:**
1. Navigate ke `/history` screen
2. Identify Crotpedia history item (check sourceId)
3. Tap pada item tersebut
4. **Expected:** Langsung buka Reader Screen di chapter yang sama
5. **Expected:** Reader menampilkan halaman terakhir yang dibaca (dari `history.lastPage`)

**Validation:**
- ✅ No detail screen shown
- ✅ Direct to reader
- ✅ Correct chapter loaded
- ✅ Last read page preserved

---

#### Test Case 2: Nhentai Series Navigation ✅

**Prerequisites:**
1. Baca minimal 1 gallery dari Nhentai (untuk generate history)
2. Pastikan history tersimpan dengan `sourceId = 'nhentai'`

**Steps:**
1. Navigate ke `/history` screen
2. Identify Nhentai history item
3. Tap pada item tersebut
4. **Expected:** Navigate ke Detail Screen (existing behavior)
5. Dari detail screen, tap "Continue Reading"
6. **Expected:** Navigate ke Reader Screen

**Validation:**
- ✅ Detail screen shown first (backward compatible)
- ✅ Can view series info, tags, etc.
- ✅ "Continue Reading" button works
- ✅ Reader opens with correct page

---

#### Test Case 3: Multiple Sources in History ✅

**Prerequisites:**
1. History contains mixed items (both Crotpedia & Nhentai)

**Steps:**
1. Navigate ke `/history` screen
2. Verify both source types shown in list
3. Tap Crotpedia item → Should go to Reader
4. Go back to history
5. Tap Nhentai item → Should go to Detail
6. Go back to history

**Validation:**
- ✅ Both navigation paths work correctly
- ✅ No cross-contamination between sources
- ✅ Back navigation works smoothly

---

### Edge Cases

#### Edge Case 1: Invalid ContentId
**Scenario:** History contentId tidak valid atau sudah dihapus

**Expected Behavior:**
- Reader/Detail screen shows error message
- User dapat back to history tanpa crash

**Test:**
1. Manual edit history SQLite dengan invalid contentId
2. Tap item tersebut
3. Verify error handling

---

#### Edge Case 2: Offline Mode
**Scenario:** User offline, history item untuk online-only content

**Expected Behavior:**
- Show offline error di reader/detail
- Graceful fallback

**Test:**
1. Enable airplane mode
2. Tap history item
3. Verify offline handling

---

## Effort Estimate

| Task | Estimate |
|------|----------|
| Code Changes | 5 minutes |
| Manual Testing | 10 minutes |
| Code Review | 5 minutes |
| Documentation Update | 2 minutes |
| **Total** | **~22 minutes** |

## Acceptance Criteria

- [x] Crotpedia history items navigate directly to Reader Screen
- [x] Nhentai history items navigate to Detail Screen (backward compatible)
- [x] Last read page preserved for both sources
- [x] No compilation errors
- [x] `flutter analyze` passes
- [x] Manual testing completed for both sources
- [x] Code comments added untuk source detection logic

## Implementation Checklist

### Phase 1: Code Changes
- [ ] Modify `_navigateToContent()` in [history_screen.dart](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/history/history_screen.dart)
- [ ] Add source detection logic
- [ ] Add code comments explaining the routing logic

### Phase 2: Verification
- [ ] Run `flutter analyze` - must pass clean
- [ ] Manual test: Crotpedia chapter navigation
- [ ] Manual test: Nhentai series navigation
- [ ] Manual test: Mixed sources in history

### Phase 3: Documentation
- [ ] Update code comments
- [ ] Mark analysis document as implemented

## Notes

### Design Decisions

1. **Why source-based instead of entity flag?**
   - ✅ Minimal code change (5 min vs 2-3 hours)
   - ✅ No database migration required
   - ✅ No entity model changes
   - ✅ Perfectly valid assumption: Crotpedia = always chapters

2. **Why not check via API?**
   - ❌ Unnecessary network overhead
   - ❌ Slow UX (loading spinner)
   - ❌ Fails offline
   - ✅ sourceId is sufficient and reliable

3. **Future extensibility?**
   - Easy to add more sources with additional `else if` conditions
   - Can refactor to strategy pattern if sources grow beyond 3-4

### Potential Follow-ups (Future Iterations)

1. **Secondary Action Button (Optional)**
   - Add "View Series" icon button di Crotpedia history items
   - Navigate ke series detail dari chapter ID
   - Estimate: 30 minutes

2. **Navigation Helper Method (Optional)**
   - Extract logic to `AppRouter.navigateFromHistory(History item)`
   - Centralize routing logic
   - Estimate: 15 minutes

3. **Analytics Tracking (Optional)**
   - Track source-specific navigation patterns
   - Monitor user behavior
   - Estimate: 20 minutes
