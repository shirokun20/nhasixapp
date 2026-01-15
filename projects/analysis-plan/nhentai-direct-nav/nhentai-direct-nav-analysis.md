# Nhentai Direct Navigation Analysis

**Date**: 2026-01-15
**Author**: Asix AI Agent
**Status**: Analysis
**Related**: Conversation 6129dae5-6459-4a64-bc3b-c350ffa011b0 (Implement Tag Pagination)

## Overview

Penambahan fitur direct navigation ke halaman detail ketika user melakukan search di Nhentai dengan input berupa angka murni (gallery ID). Fitur ini akan meningkatkan UX dengan mengurangi 1 step navigasi untuk user yang sudah tahu gallery ID yang ingin dituju.

## Current State

### Existing Behavior
- User input search query di search bar
- Aplikasi melakukan search berdasarkan query
- Menampilkan hasil search dalam list
- User tap pada item untuk ke detail page

### Related Files
- `lib/presentation/pages/content_by_tag/content_by_tag_screen.dart` - Screen untuk menampilkan hasil search/tag
- `lib/data/datasources/remote/nhentai/nhentai_scraper_adapter_impl.dart` - Scraper untuk Nhentai
- `lib/domain/repositories/content_repository.dart` - Repository interface
- Navigation logic dalam `content_by_tag_screen.dart`

## Requirements

### Functional Requirements

**FR-01**: Deteksi Input Angka Murni
- Sistem harus dapat mendeteksi ketika search query **hanya** berisi angka (contoh: "51234", "123456")
- Deteksi harus case-specific untuk source Nhentai saja

**FR-02**: Direct Navigation
- Ketika input adalah angka murni di Nhentai search:
  - SKIP proses search
  - Langsung navigate ke detail page dengan contentId = input angka
  - sourceId = 'nhentai'

**FR-03**: Fallback Handling
- Jika gallery ID tidak ditemukan, tampilkan error yang appropriate
- User dapat kembali ke search

### Non-Functional Requirements

**NFR-01**: Performance
- Navigation harus instant tanpa delay search
- Tidak boleh ada request search yang tidak perlu

**NFR-02**: UX Consistency
- Loading state yang jelas saat fetch detail
- Error handling yang user-friendly
- Tetap konsisten dengan flow navigation lainnya

**NFR-03**: Source-Specific
- Fitur HANYA untuk Nhentai
- Tidak mempengaruhi behavior source lain (Crotpedia)

## Technical Analysis

### Architecture Impact

#### Presentation Layer
**File**: `content_by_tag_screen.dart`
- Perlu logic tambahan untuk detect angka-only input
- Routing logic untuk direct navigation
- State handling untuk loading/error

#### Domain Layer
**Tidak ada perubahan** - Existing use cases sudah cukup

#### Data Layer  
**Tidak ada perubahan** - Menggunakan existing repository methods

### Implementation Approach

**Option 1**: Logic di Widget Level (Recommended)
```dart
// Di content_by_tag_screen.dart atau search handler
void _handleSearch(String query) {
  if (_isNhentaiNumericId(query)) {
    _navigateToDetail(query);
  } else {
    _performNormalSearch(query);
  }
}

bool _isNhentaiNumericId(String query) {
  // Cek source == nhentai && query is purely numeric
  return sourceId == 'nhentai' && RegExp(r'^\d+$').hasMatch(query);
}
```

**Option 2**: Logic di Cubit/BLoC Level
- Lebih complex, less necessary untuk simple logic ini

### Integration Points

1. **Search Entry Point**: Di mana user input search query?
   - Search bar di main screen?
   - Search dalam content_by_tag screen?
   - Perlu identify exact entry point

2. **Navigation**: Gunakan existing navigation pattern
   - Reuse existing detail navigation logic
   - Pass sourceId='nhentai' dan contentId=inputNumber

3. **Error Handling**: 
   - DetailCubit sudah handle loading/error states
   - Reuse existing error UI

## Risks & Considerations

| Risk | Impact | Mitigation |
|------|--------|------------|
| User input "00123" vs "123" | Medium | Normalize dengan `.trim()` dan remove leading zeros |
| Large numbers (overflow) | Low | Nhentai ID masih dalam range int32 |
| Conflict dengan existing tag "666" | Low | Tag search always returns tag page, not numeric ID |
| Breaking existing search flow | Medium | Guard with sourceId check yang ketat |

## Open Questions

- [x] Di mana exact entry point untuk search? → `content_by_tag_screen.dart` kemungkinan besar, atau cek search bar di main screen
- [ ] Apakah perlu show confirmation dialog sebelum navigate?
- [ ] Bagaimana handle jika user input "123 456" (dengan space)?
- [ ] Apakah perlu analytics tracking untuk direct nav usage?

## References

- Previous conversation: Tag Pagination Implementation (6129dae5-6459-4a64-bc3b-c350ffa011b0)
- Related files: 
  - [`content_by_tag_screen.dart`](file:///Users/asix/Documents/learn_flutter/nhasixapp/lib/presentation/pages/content_by_tag/content_by_tag_screen.dart)
  - Clean Architecture Skill: [`.agent/skills/clean-arch/SKILL.md`](file:///Users/asix/Documents/learn_flutter/nhasixapp/.agent/skills/clean-arch/SKILL.md)
  - Flutter Dev Skill: [`.agent/skills/flutter-dev/SKILL.md`](file:///Users/asix/Documents/learn_flutter/nhasixapp/.agent/skills/flutter-dev/SKILL.md)
