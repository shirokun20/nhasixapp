# SortingWidget vs SearchConfig Clarification

## ❓ User Question
> SortingWidget di main_screen_scrollable.dart akan hilang dengan perubahan searchConfig?

## ✅ Answer: TIDAK AKAN HILANG! 

SortingWidget dan searchConfig adalah **dua hal yang berbeda** dengan tujuan berbeda.

---

## 📊 Comparison Table

| Aspect | SortingWidget (Main Screen) | searchConfig (Search Screen) |
|--------|----------------------------|------------------------------|
| **Location** | `main_screen_scrollable.dart` | `search_screen.dart` |
| **Purpose** | Sort **search results** di main screen | Configure search UI per source |
| **When Shown** | Saat `_isShowingSearchResults = true` | Always in search screen |
| **Options** | `newest`, `popular`, `popular-week`, `popular-today` | Source-specific (from config) |
| **Scope** | Main screen only | Search screen only |
| **Affected by Changes?** | ❌ NO | ✅ YES |

---

## 🔍 Detailed Explanation

### 1. **SortingWidget di Main Screen**

**File**: `lib/presentation/pages/main/main_screen_scrollable.dart:608-617`

```dart
// Sorting widget - sebagai sliver
if (_shouldShowSorting(state))
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SortingWidget(
        currentSort: _currentSortOption,
        onSortChanged: _onSortingChanged,
      ),
    ),
  ),
```

**Kapan Muncul**:
```dart
bool _shouldShowSorting(ContentState state) {
  // Only show sorting when there's an active search/filter AND there's data
  if (!_isShowingSearchResults) {
    return false; // Hide for normal content browsing
  }
  
  if (state is ContentLoaded && state.contents.isNotEmpty) {
    return true;
  }
  // ...
}
```

**Purpose**:
- Sort **hasil pencarian** yang ditampilkan di main screen
- User search dari search screen → results tampil di main screen
- SortingWidget muncul di atas results untuk re-sort
- Options: Newest, Popular, Popular This Week, Popular Today

**Example Flow**:
1. User tap search icon di header
2. Navigate to `SearchScreen`
3. User input query/tags, tap Search
4. Navigate back to `MainScreen` dengan `_isShowingSearchResults = true`
5. **SortingWidget muncul** di atas grid results
6. User bisa re-sort: popular → newest

---

### 2. **searchConfig di Search Screen**

**File**: `search_screen.dart` (akan di-update)

**Purpose**:
- Configure **search UI** per source
- Nhentai: query input + tag chips
- Crotpedia: form fields (title, author, year, genre checkboxes)

**Example for Crotpedia**:
```json
{
  "searchConfig": {
    "searchMode": "form-based",
    "radioGroups": [
      {
        "name": "order",
        "label": "Order By",
        "options": [
          { "value": "title", "label": "A-Z" },
          { "value": "update", "label": "Latest Update" },
          { "value": "popular", "label": "Popular" }
        ]
      }
    ]
  }
}
```

This is for **building the search form**, NOT for sorting results in main screen!

---

## 🎯 Key Differences

### SortingWidget (Main Screen)
- **Location**: Above search results grid in main screen
- **Trigger**: `_isShowingSearchResults = true`
- **Function**: Re-sort already fetched results
- **Options**: Fixed nhentai sort options (newest, popular, etc)
- **Will Change?**: ❌ **NO** - stays as is

### searchConfig "order" Radio (Search Screen)
- **Location**: Inside search form in search screen
- **Trigger**: Always visible during search
- **Function**: Configure initial sort BEFORE submitting search
- **Options**: Dynamic from config (crotpedia: A-Z, update, popular, etc)
- **Will Change?**: ✅ **YES** - new implementation for Crotpedia

---

## 🔄 Full User Flow Example

### Scenario: Search with Crotpedia

1. **Main Screen** - User browsing content
   - NO SortingWidget visible (not showing search results)

2. **Tap Search Icon** - Navigate to Search Screen
   - Show **Crotpedia search form** (from searchConfig)
   - Form fields: title, author, artist, year
   - Radio group: "Order By" with options A-Z/update/popular
   - Checkboxes: Genre list

3. **User Fills Form**:
   - Title: "isekai"
   - Order: "Popular" ← This is searchConfig radio
   - Genre: [romance, fantasy]

4. **Tap Search Button** - Submit & return to Main Screen
   - `_isShowingSearchResults = true`
   - Results loaded with "Popular" sort
   - **SortingWidget appears** above grid ← This is main screen widget

5. **User Changes Sort** (in Main Screen)
   - Click SortingWidget: Popular → Newest
   - Re-fetch results with new sort
   - Grid updates

---

## ✅ Summary

**Will SortingWidget in main_screen_scrollable.dart be removed?**
- ❌ **NO**
- It serves a different purpose (re-sorting results)
- Located in different screen (main vs search)
- Works with search results, not search form

**What WILL change?**
- ✅ Search Screen UI (dynamic form from config)
- ✅ Search query building (form params for Crotpedia)
- ✅ Initial sort selection (during search, not after)

**What WON'T change?**
- ❌ SortingWidget in main screen
- ❌ Main screen grid layout
- ❌ Search results display

---

## 📝 Recommendation

**Keep SortingWidget** exactly as is:
- It's for **post-search** sorting in main screen
- Different from **pre-search** order selection in search form
- Users expect both:
  1. Choose sort when searching (search screen)
  2. Re-sort after viewing results (main screen)

**Add searchConfig** for search screen only:
- Configures the search **input** UI
- Crotpedia gets form-based search
- Nhentai keeps query-string search
- Both return to main screen and show SortingWidget for re-sorting

---

**Conclusion**: SortingWidget tetap ada dan tidak terpengaruh oleh searchConfig changes!
