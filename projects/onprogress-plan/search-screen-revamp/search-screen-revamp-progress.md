# Search Screen Revamp - Progress Tracking

## 📊 Project Info
- **Started**: 2026-01-13
- **Estimated**: 4 days (Option B - Split execution)
- **Current Phase**: Day 1 - Config Setup
- **Status**: 🟡 In Progress

---

## 📅 Day-by-Day Plan

### Day 1: Config Models & CDN Setup ⏳ IN PROGRESS
**Goal**: Setup configuration foundation (Phase 1 + 2)
**Estimated**: 1-1.5 hours

#### Phase 1: Config Models
- [x] Create `SearchConfig` model with searchMode, endpoint, sortingConfig
- [x] Create `SortingConfig` model with allowDynamicReSort, widgetType, options
- [x] Create `SortOptionConfig` model
- [x] Create `SortingMessages` model
- [x] Create `FilterSupportConfig`, `TextFieldConfig`, `RadioGroupConfig`, `CheckboxGroupConfig`
- [x] Update `SourceConfig` to include `SearchConfig? searchConfig`
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Verify no compile errors with `flutter analyze`

#### Phase 2: CDN Configs
- [x] Update `nhentai-config.json` with searchConfig (query-string mode)
- [x] Add sortingConfig to nhentai (allowDynamicReSort: true, dropdown)
- [x] Update `crotpedia-config.json` with searchConfig (form-based mode)
- [x] Add sortingConfig to crotpedia (allowDynamicReSort: false, readonly)
- [x] Add textFields, radioGroups, checkboxGroups to crotpedia
- [x] Commit: "feat(search): add dynamic search config models and CDN configs"

**End of Day 1**: ✅ Config foundation ready

---

### Day 2: Dynamic Sorting Widget ⏸ PENDING
**Goal**: Implement universal sorting widget (Phase 3)
**Estimated**: 1.5-2 hours

#### Phase 3: UI Components
- [ ] Create `lib/presentation/widgets/dynamic_sorting_widget.dart`
- [ ] Implement dropdown mode (interactive - nhentai)
- [ ] Implement readonly mode (display-only - crotpedia)
- [ ] Implement chips mode (alternative)
- [ ] Add icon mapping helper (string → IconData)
- [ ] Update `main_screen_scrollable.dart` to use DynamicSortingWidget
- [ ] Replace `_shouldShowSorting()` with source-aware check
- [ ] Test both modes (nhentai vs crotpedia)
- [ ] Commit: "feat(ui): add dynamic sorting widget with source-aware behavior"

**End of Day 2**: ✅ Sorting widget works for both sources

---

### Day 3: Search Screen & Scrapers ⏸ PENDING
**Goal**: Implement dynamic search UI (Phase 4 + 5)
**Estimated**: 2-2.5 hours

#### Phase 4: Search Screen Revamp
- [ ] Create `lib/presentation/widgets/query_string_search_ui.dart` (nhentai)
- [ ] Create `lib/presentation/widgets/form_based_search_ui.dart` (crotpedia)
- [ ] Update `search_screen.dart` with conditional rendering
- [ ] Implement `_buildTextField()` for crotpedia text fields
- [ ] Implement `_buildRadioGroup()` for crotpedia radios
- [ ] Implement `_buildCheckboxGroup()` for crotpedia genres
- [ ] Remove hardcoded genre field logic
- [ ] Test UI switching when source changes

#### Phase 5: Scraper Updates
- [ ] Update `CrotpediaScraper.buildAdvancedSearchUrl()` for form params
- [ ] Handle `genre[]` array parameter encoding
- [ ] Verify `NhentaiScraper` still works with query-string
- [ ] Test search URL generation for both sources
- [ ] Commit: "feat(search): implement dynamic search UI and form-based scraper"

**End of Day 3**: ✅ Search functionality works for both sources

---

### Day 4: Testing & Polish ⏸ PENDING
**Goal**: End-to-end testing and bug fixes
**Estimated**: 1 hour

#### Testing Checklist
- [ ] **Nhentai Search**:
  - [ ] Query input works
  - [ ] Tag filters (include/exclude) work
  - [ ] Language/Category dropdowns work
  - [ ] Search results show correctly
  - [ ] Interactive sorting dropdown works
  - [ ] Re-sort triggers new API call
  
- [ ] **Crotpedia Search**:
  - [ ] Form fields (title, author, artist, year) work
  - [ ] Status, Type, Order radios work
  - [ ] Genre checkboxes load from tags
  - [ ] Form submission generates correct URL
  - [ ] Readonly sorting widget displays current order
  - [ ] Tap widget navigates to search

- [ ] **Source Switching**:
  - [ ] Change source in drawer → UI changes
  - [ ] Search filters reset on source change
  - [ ] No cross-contamination of filters

- [ ] **Final Polish**:
  - [ ] `flutter analyze` passes
  - [ ] `flutter test` passes (if tests exist)
  - [ ] No console errors
  - [ ] Update CHANGELOG.md
  - [ ] Update README.md if needed
  - [ ] Commit: "test: verify search revamp and fix bugs"

**End of Day 4**: ✅ Feature complete and tested

---

## 🎯 Success Criteria (from planning)

### Nhentai:
- [x] Search screen: Query input + tag chips from config
- [ ] Main screen: Interactive dropdown sorting (can re-sort)
- [ ] Query: `tag:"romance" -tag:"netorare" language:"english"`
- [ ] Sort change: Re-fetch with `?sort=popular`

### Crotpedia:
- [x] Search screen: Form fields from config (title, author, year, genre checkboxes)
- [ ] Main screen: Read-only sorting widget (shows current, tap to go back)
- [ ] Query: Form params `?title=xxx&genre[]=ahegao&order=update`
- [ ] Sort change: Navigate back to search, change order radio, re-submit

---

## 📝 Commit Strategy

Setiap end of day, commit dengan format:

```bash
git add .
git commit -m "feat(search): [phase name]

[bullet points of what was done]

Refs: #search-screen-revamp Day [X]"
```

---

## 🚨 Blockers & Notes

### Day 1:
- None yet

### Day 2:
- TBD

### Day 3:
- TBD

### Day 4:
- TBD

---

## 📚 Reference Docs (Always Open)
1. `implementation-guide.md` - Step-by-step checklist
2. `search-screen-revamp-plan.md` - Architecture & design
3. `cdn-config-requirements.md` - Config structure
4. `mockups/search-screen-revised.html` - UI reference

---

**Status Legend**:
- ⏳ In Progress
- ⏸ Pending
- ✅ Complete
- ❌ Blocked
