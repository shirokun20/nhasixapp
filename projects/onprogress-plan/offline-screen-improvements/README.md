# Offline Screen & Download Improvements

## 📌 Quick Overview

This project focuses on improving the Offline Screen functionality, fixing download notification sounds, enhancing PDF generation for webtoon images, and improving the reading mode for vertical content.

## 🎯 Main Goals

1. **Move PDF Generation to Offline Screen** - Users can generate PDFs from their offline library
2. **Add Delete Feature** - Delete offline content with proper confirmation and storage cleanup
3. **Handle Webtoon Images in PDF** - Smart splitting for extremely tall images
4. **Fix Notification Sounds** - Sound only on start/completion, not every progress update
5. **Improve Offline UI** - Modern, polished interface with better UX
6. **Fix Reading Mode** - Proper handling of webtoon/tall images in reader

## 📋 Task Summary

| Task | Priority | Complexity | Status |
|------|----------|------------|--------|
| Fix Notification Sounds | Low (Already Done!) | Low | ✅ **VERIFIED CORRECT** |
| Add Delete Feature | High | Medium | ⏳ Not Started |
| Move PDF to Offline | High | Medium | ⏳ Not Started |
| Webtoon PDF Handling | High | High | ⏳ Not Started |
| Fix Reading Mode | High | High | ⏳ Not Started |
| Improve UI | Medium | Medium | ⏳ Not Started |

**Note:** Notification implementation already uses correct `Importance` levels (Android-only project)

## 🚀 Recommended Implementation Order

1. **✅ Notification Sounds** - **ALREADY CORRECT!** (No work needed)
2. **Add Delete Feature** (1-1.5 days)
3. **Move PDF to Offline Screen** (1 day)
4. **Webtoon PDF Handling** (1.5-2 days)
5. **Fix Reading Mode** (1.5-2 days)
6. **Improve UI** (1-1.5 days)

**Total Estimated Time:** 5-6 days (reduced from 5-7 since Task 1 is done)

## 📁 Files to Modify

### Core Files
- `lib/presentation/pages/offline/offline_content_screen.dart`
- `lib/presentation/pages/downloads/downloads_screen.dart`
- `lib/presentation/pages/reader/reader_screen.dart`
- `lib/services/notification_service.dart`
- `lib/services/pdf_service.dart`
- `lib/services/pdf_conversion_service.dart`

### Supporting Files
- `lib/presentation/widgets/content_card_widget.dart`
- `lib/presentation/widgets/extended_image_reader_widget.dart`
- `lib/presentation/cubits/offline_search/offline_search_cubit.dart`
- `lib/core/utils/offline_content_manager.dart`

## 🔧 Key Technical Challenges

1. **Webtoon Image Splitting (VERIFIED)**
   - Detect tall images: aspect ratio > 2.5 (Normal=1.42, Webtoon=12.85)
   - **Actual dimensions:** Normal 902×1280px, Webtoon 1275×16383px
   - Split into ~13 chunks of 1280px height each
   - Maintain quality and continuity with 30px overlap
   - Result: Chunks with AR≈1.0 fit normal reading flow

2. **Scroll Tracking**
   - Current implementation uses fixed approximation
   - Need actual image heights for accuracy
   - Handle varying image sizes (normal vs webtoon)
   - Cache rendered heights for performance

3. **Notification Sound Management** ✅ **ALREADY CORRECT**
   - ✅ Android-only project (iOS code unused)
   - ✅ Uses `Importance.low` for progress (no sound)
   - ✅ Uses `Importance.defaultImportance` for completion (with sound)
   - Optional: Remove unused iOS code for clarity

4. **Delete with Safety**
   - Check for active readers
   - Handle partial/corrupted content
   - Update all references and caches
   - **Path structure:** `[basePath]/nhasix/[contentId]/images/`

## 📚 Resources Used

- **MCP Sequential Thinking** - For complex problem analysis
- **Context7** - Flutter Local Notifications, Dart PDF documentation
- **Docfork** - Flutter best practices and examples
- **Project Guidelines** - AGENTS.md for code style and architecture

## 🧪 Testing Requirements

- Unit tests for all new logic
- Integration tests for critical flows
- Manual testing on Android (multiple devices/versions)
- Performance testing for large datasets (100+ items)
- Memory testing for image processing (webtoon splitting)
- Accessibility testing with TalkBack

**Note:** This is an Android-only project. iOS testing not required.

## 📊 Success Metrics

- ✅ PDF generation available from Offline Screen
- ✅ Delete feature working with confirmation
- ✅ Webtoon PDFs properly split (no oversized pages)
- ✅ Notifications only sound on start/complete
- ✅ Improved UI with smooth animations
- ✅ Reading mode handles tall images correctly
- ✅ No performance regressions
- ✅ Memory usage within acceptable limits

## 📝 Important Notes

- **Follow AGENTS.md guidelines** - Especially code style and architecture
- **Use logger package** - For all logging (not print/debugPrint)
- **Clean Architecture** - Respect layer boundaries
- **Test thoroughly** - Both platforms, multiple scenarios
- **Update documentation** - Keep this plan updated

## 🔗 Related Documents

- [Implementation Plan](./implementation-plan.md) - Detailed technical plan
- [AGENTS.md](../../../AGENTS.md) - Project guidelines
- [flutter_bug_01.png](../../../flutter_bug_01.png) - Reading mode bug reference

## 💡 Quick Start

To begin implementation:

1. Read the full [Implementation Plan](./implementation-plan.md)
2. ✅ **Task 4 Complete!** Notifications already use correct `Importance` levels
3. Start with **Task 2** (Add Delete Feature) - High priority
4. Follow the recommended implementation order
5. Update checkboxes in [CHECKLIST.md](./CHECKLIST.md) as you complete each todo
6. Run tests after each task
7. Update this README with progress

---

**Created:** 2025-11-27  
**Updated:** 2025-11-27 (Verified notification implementation, analyzed webtoon dimensions)  
**Status:** Planning Complete, Ready for Implementation  
**Next Step:** Begin Task 2 - Add Delete Feature
