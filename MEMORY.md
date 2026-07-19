# Kuron — Project Memory

> **Unified context file** for tracking progress across AI tools.
> Read by: **Codex** | **OpenCode** | **GitHub Copilot** | **Antigravity** | **Manual Review**

---

## Project Identity

| Key | Value |
|---|---|
| **App Name** | **Kuron** (formerly NhasixApp) |
| **Repo** | `shirokun20/nhasixapp` |
| **Platform** | Android (Flutter) |
| **Flutter SDK** | Stable (3.24+, Dart 3.5+ via FVM) |
| **Version** | 0.9.23+33 |
| **Architecture** | Clean Architecture (Domain → Data → Presentation) |
| **State Management** | `flutter_bloc` / `Cubit` (extending `BaseCubit`) |
| **DI** | `GetIt` (`core/di/`) |
| **Networking** | `Dio` + `native_dio_adapter` |
| **Routing** | GoRouter (`go_router`) |
| **Database** | SQLite (`sqflite`) + `SharedPreferences` |
| **Logging** | `logger` package (`.t` to `.f`) — NO `print`/`debugPrint` |

### Packages (Internal)
| Package | Description |
|---|---|
| `kuron_core` | Shared core utilities |
| `kuron_config_generator` | Configuration generator |
| `kuron_generic` | Generic utilities |
| `kuron_native` | Native Android (Kotlin) integrations |
| `kuron_special` | Special utilities |
| `kuron_native` | Native Android (Kotlin) integrations |

### Key Features
- Immersive Reader with smooth page transitions
- App Disguise mode (Calculator, Notes, Weather)
- Offline-first with background downloading
- Smart Search with advanced filtering
- Material 3, Dark/Light/AMOLED modes, responsive UI
- Community comments on detail pages

---

## Architecture Overview

```
lib/
├── core/              # Shared utilities, DI, constants, themes
│   ├── di/            # GetIt setup
│   ├── network/       # Dio clients, interceptors
│   └── utils/         # Helpers, extensions
├── domain/            # Pure Dart — entities, use cases, repo interfaces
├── data/              # Implementations — models, sources, repos
│   ├── models/        # extend entities (.fromEntity/.toEntity/.fromMap)
│   ├── datasources/   # Remote/Local data sources
│   └── repositories/  # Repository implementations
├── presentation/      # Flutter UI — BLoC/Cubit, pages, widgets
│   ├── blocs/         # State management (cubits)
│   ├── pages/         # Screen-level widgets
│   └── widgets/       # Reusable components
└── packages/          # Internal packages (kuron_core, kuron_generic, kuron_native, kuron_special, etc.)
```

### Layer Rules
- **Domain**: Pure Dart. Zero dependencies on Data/Presentation.
- **Data**: Depends only on Domain. JSON parsing, API calls, DB storage.
- **Presentation**: Depends only on Domain (+ DI). BLoC/Cubit + UI widgets.

---

## Current Progress Dashboard

> Tracked via `openspec/` — Last updated: 2026-07-18

### Archived (in `openspec/changes/archive/`)
- `2026-02-11-nhentai-search-revamp`
- `2026-02-14-favorites-bug-fix`
- `2026-02-15-chapter-reading-history`
- `2026-02-15-download-metadata-revamp`
- `2026-02-15-fix-download-metadata-parentid`
- `2026-02-17-fix-download-range-page-bounds`
- `2026-02-22-app-audit-hardcode-ui`
- `2026-02-xx-doujin-search-highlight`
- `2026-02-xx-offline-search-highlight`
- `2026-02-xx-reader-header-auto-show`
- `2026-03-03-komiktap-migration`
- `2026-03-07-fix-source-switch-shimmer`
- `2026-03-12-builtin-dns-resolver`
- `2026-03-14-app-config-externalization`
- `2026-03-15-cross-source-search-ui`
- `2026-03-15-mangadex-detail-pagination-bug`
- `2026-03-31-fix-import-zip-metadata`
- `2026-03-xx-crotpedia-ui-modernization`
- `2026-03-xx-fix-app-drawer-transparency`
- `2026-03-xx-multi-provider-integration`
- `2026-03-xx-smart-caching-and-fixes`
- `2026-03-xx-unity-ads-fix`
- `2026-03-xx-view-comments`
- `2026-04-12-local-collection-categories`
- `2026-04-19-blur-recent-apps-privacy`
- `2026-04-20-ehentai-download-reader-stability`
- `2026-04-xx-komiktap-navigation-lists`
- `2026-04-xx-qol-enhancements`
- `2026-05-19-fix-url-special-chars`
- `2026-05-24-avif-to-webp-conversion`
- `2026-05-24-ehentai-part-mode-metadata-sync`
- `2026-05-28-fix-generic-rest-adapter-schema-support`
- `2026-06-01-doujindesuv2-scraper`
- `2026-06-01-reader-ux-revamp`
- `2026-06-16-offline-library-sorting-source-buckets`
- `2026-06-16-offline-library-v2`
- `2026-06-16-tachiyomi-extensions-integration`
- `2026-06-21-search-runtime-autowiring`
- `2026-06-21-tabbed-multilang-chapters`
- `2026-06-23-ehentai-download-strategy`
- `2026-06-23-lazy-load-chapters`
- `2026-06-23-mangafire-integration`
- `2026-06-25-refine-card-surface-a11y`
- `2026-06-26-bloc-pattern-modernization`
- `2026-06-26-purge-ui-packages`
- `2026-06-26-upgrade-core-packages`
- `2026-06-27-update-manhwaread-config`
- `2026-06-28-home-scroll-reader-optimization`
- `2026-06-28-native-dns-rollout`
- `2026-07-03-migrate-legacy-search-configs`
- `2026-07-03-search-form-ui-parity`
- `2026-07-03-smart-config-generator`
- `2026-07-05-add-kuron-config-generator`
- `2026-07-05-config-generator-validation-loop`
- `2026-07-05-revamp-kuron-config-runtime`
- `2026-07-05-upgrade-android-deps-july-2026`
- `2026-07-06-deprecate-legacy-search-ui`
- `2026-07-06-migrate-legacy-search-configs`
- `2026-07-06-smart-query-parser`
- `2026-07-06-source-health-monitor`
- `2026-07-10-add-vihentai-source`
- `2026-07-10-revamp-mangafire-to-json-api`
- `2026-07-12-reader-120fps-optimization`
- `2026-07-13-download-jank-reduction`
- `2026-07-13-rawdevart-config`
- `2026-07-13-sync-native-theme`
- `2026-07-14-note-mode`
- `2026-07-14-schale-network-source`
- `2026-07-16-fix-overheat-lock-screen`
- `2026-07-17-code-quality-refactor-phase-1`
- `2026-07-18-code-quality-refactor-phase-2`
- `2026-07-18-fix-performance-overheat`
- `2026-07-18-hdoujin-source-integration`
- `2026-07-18-notification-snackbar-audit-fix`

### Active Changes (in `openspec/changes/`)
- `add-doujin-desu-xxx-source`
- `mangadex-search-language-to-detail` — Proposed. Pass search language filters (originalLanguage, availableTranslatedLanguage) from search to detail page for auto-selecting chapter language.
- `pin-biometric-app-lock`
- `reader-ai-learning-mode`

### Open Issues (in `openspec/changes/`)
- *(none)*

---

## Search Tools

Project uses modern search tools instead of `grep`:

| Tool | Use Case | Command |
|---|---|---|
| `rg` (ripgrep) | Fast text search, regex | `rg "pattern" lib/ -t dart` |
| `ugrep` | Interactive, fuzzy, hex search | `ugrep -Q "pattern" lib/` |
| `semgrep` | AST-aware Dart patterns | `semgrep --lang dart -e '$PATTERN' lib/` |

> See `smart_search.sh` and `search-tools/SKILL.md` for details.

---

## RTK - Rust Token Killer

Project requires **RTK** for AI token optimization (60-90% savings):

| Rule | Description |
|---|---|
| **Prefix `rtk`** | Always prepend `rtk` to terminal commands (git, flutter, ls, etc.). |
| **Filtering** | RTK strips boilerplate/noise so AI focuses on relevant data. |
| **Statistics** | Use `rtk gain` to see token savings. |

> Global config at `~/.gemini/GEMINI.md`, `AGENTS.md`, `CLAUDE.md`.

---

### Recent Sessions

> Session log in this table. For code details, see `openspec/changes/archive/`.

| Date | Tool | Topic | Status | Detail |
|---|---|---|---|---|
| 2026-07-19 | Claude Code | Nicomanga config fix: detail tag selector via contains() + chapter id self + cache bypass, answer.md | Done | **Nicomanga** site HTML changed completely. Detail page: info fields restructured (.manga-info-item > .info-field-label/.info-field-value), author/genre/magazine text now **base64 encoded**. Reader unchanged. **Config v1.0.3->v1.1.0**: fixed detail selectors using `:contains()` + `transform: base64`, genreSearch URL `/g/{tag}.html` + `tagTransform: base64`. **Adapter**: added `tagTransform: "base64"` in `GenericScraperAdapter._resolvePattern()`. **Bug found**: config file pake `.manga-info-item:nth-child(N)` yg **tidak didukung `package:html`** → tags selalu kosong. Fix: ganti ke `:contains(Label)` yg custom parser `_selectAll` support. **Chapter id**: container `<a>` langsung, fix pake `selector: "self"`, `attribute: "href"` + chapter template `"{id}"` (absolute URL). **Detail cache**: `content_repository_impl` bypass list include `nicomanga`. **Tests**: 74/74 pass, +1 test for base64 encoding. **Files**: `nicomanga-config.json`, `generic_scraper_adapter.dart`, `generic_scraper_adapter_test.dart`, `content_repository_impl.dart`. |
| 2026-07-18 | OpenCode | Code Quality Refactor — Phase 2 Complete + CS Go to First Page | Done | Phase 2 (91/91 tasks) complete. Verified all tasks, squashed 1 missed `debugPrint` in `image_cache_service.dart`. Plus: added "Go to First Page" button to `EndOfChapterOverlay` in CS mode via `onGoToFirstPage` callback → jumps to page 0. Files: `end_of_chapter_overlay.dart`, `reader_screen.dart`. Archived `code-quality-refactor-phase-2`. |
| 2026-07-18 | OpenCode | Notification + SnackBar + Global Banner Audit & Fix | Done | 3-area audit → proposal → 32 tasks. System notif: Completer ganti busy-wait, NotificationAppLaunchDetails cold start, 3 channel Android, localization via .arb mapper, dead code. Global banner: StatefulWidget + SlideTransition + auto-hide + dismiss. SnackBar: CoreSnackbar (4s/6s/8s), fix 60s/30s durations. Bugs: _isProgrammaticAnimation skip onPageChanged → non-CS counter stuck. download_bloc in-place list mutate → progress stuck 0. Archived. |
| 2026-07-17 | Claude Code | Code Quality Refactor — Phase 1 & Phase 2 | Done (Ph1), In Progress (Ph2) | Phase 1 (44 tasks): dead code removal, services/→core/services/, settings entity extraction, BaseCubit compliance, domain JSON purification, ContentRepository→UseCase (5 new UseCases, 4 callers migrated). Phase 2 (~59 tasks done): debugPrint→Logger (51 calls in 9 files), Logger injection (25 files), catch-block logging (15 files), GetReaderPositionUseCase + offline_series + content_list migrated. Remaining heavy: ~460 safe casts, ReaderCubit/FavoriteCubit UseCase boundary, mega-file splits. See [[code-quality-refactor-phases]]. |
| 2026-07-16 | Claude Code | Overheat fix — lifecyle-aware Cubits + native cancel WebP (openspec: fix-overheat-lock-screen) | Done | Fixed CPU/GPU overheating saat lock screen. **ReaderCubit**: +`WidgetsBindingObserver` di ReaderScreen, `handleLifecyclePause()` cancel timer + disable wakelock, `handleLifecycleResume()` restore. **DownloadBloc**: +`pauseBackgroundWork()` flush DB timer + remove FrameTimingCallback, `resumeBackgroundWork()` restore. **ReaderCubit pindah screen-level**: removed from app-level BlocProviderConfig → `BlocProvider` wrapping di route builder → `close()` kepanggil otomatis. **Native HTTP cancel WebP**: `requestId` + `cancelWebPThumbnail()` MethodChannel, flag check di native `downloadBytesForThumbnail()` read loop, cancel di `AnimatedWebPViewState.dispose()`. **Suppress decode errors**: `FlutterError.onError` + `PlatformDispatcher.onError` skip `Failed to decode image` + `Invalid image data`. Files: `reader_cubit.dart`, `reader_screen.dart`, `download_bloc.dart`, `lifecycle_watcher.dart`, `multi_bloc_provider_config.dart`, `app_router.dart`, `main.dart`, `KuronNativePlugin.kt`, `kuron_native.dart` + method_channel + platform_interface, `animated_webp_view.dart`, `kuron_native_test.dart`, `backup_utils_test.dart`. |
| 2026-07-14 | Kiro | HDoujin source integration (openspec: hdoujin-source-integration) | Done | Added HDoujin as readable source reusing Schale Network's clearance engine. Created `hdoujin-config.json`, refactored `SchaleClearanceService` for dynamic `domainUrl`+`sourceId`, refactored `SchaleSourceFactory` for conditional routing, registered hdoujin in service locator. Fixed `getImageDownloadHeaders()` in `generic_http_source.dart` so hdoujin CDN requests get correct Origin/Referer from config instead of API URL. Added hdoujin to forced cache refresh in `content_repository_impl.dart`. Added `ponytail:` comments on hardcoded boundaries (erocdn.net, switch catch-all, fallback omission). Files: +`informations/configs/hdoujin-config.json`, `schale_clearance_service.dart`, `schale_source_factory.dart`, `service_locator.dart`, `generic_http_source.dart`, `content_repository_impl.dart`. |
| 2026-07-14 | Antigravity | Schale Network Cloudflare Bypass & CDN Fix | Done | Fully resolved Schale Network image loading issues. 1) Implemented Turnstile challenge bypass using `showLoginWebView` and injected JavaScript to extract `cf_clearance` cookie from `localStorage`. Cached this cookie and User-Agent in secure storage. 2) Created `_SchaleHttpSource` to intercept generic requests and inject the Cloudflare cookie and User-Agent into `getImageDownloadHeaders` for CDN image loading. 3) Fixed CDN URL construction: CDN `erocdn.net` returned `404 Not Found` when `?w=$quality` was appended to the image URL (e.g. `?w=1280`). Removed the hardcoded `?w=$quality` from `generic_rest_adapter.dart` because Schale Network already embeds the resolution inside the path (e.g. `/1280/`). All manga pages now load smoothly. |
| 2026-07-13 | Antigravity | Native theme sync & offline PDF routing | Done | Added `readerBackgroundColorHex` and `readerTextColorHex` to `NativeThemeHelper`. Updated Kotlin `PdfReaderActivity`, `WebViewActivity`, and `CaptchaWebViewActivity` to parse intent `textColor` and tint navigation/overflow icons to match Flutter theme. Fixed `OfflineSeriesDetailScreen` so clicking "Read Now (PDF)" correctly routes to native PDF reader via `AppRouter.goToReaderPdf` by sniffing for `.pdf` in the offline chapter directory. |
| 2026-07-12 | Codex | Reader 120 FPS optimization + state cleanup (openspec: reader-120fps-optimization) | Done | 4 perubahan pada reader performance dan code quality. Summary: - **State Management Cleanup**: Hapus subclass pattern (`ReaderInitial`/`ReaderLoading`/`ReaderLoaded`/`ReaderError`) → `ReaderStatus` enum + 7 focused copy methods (`copyWithPage`, `copyWithUI`, `copyWithContent`, `copyWithMessage`, `copyWithMode`, `copyWithTimer`, `copyWithOffline`). Hapus `_undefined` sentinel `copyWith`. Kurangi `Equatable.props`. Tambah `isLoaded` getter. - **Dual-Rate Scroll**: Page indicator (ValueNotifier) update via vsync-aligned `Ticker` (~8ms/120 FPS), heavy ops (prefetch/evict/save) tetap throttle 300ms. `_scrollProcessInterval` → `_scrollHeavyOpsInterval`. - **O(n) Page Estimation with exit-early**: Pakai cached heights (atau average fallback), scan stop pas viewport center tercapai. Gak ada full scan 200 pages. - **GPU Memory Budget**: `_heavyImageCount` tracking — evict farthest 25% pages only when budget exceeded (30 images in 5s window). Hapus window-based evict (`_lastEvictedPage`/`_evictionWindowPages`). - **Rapid tap non-CS**: Deteksi tap interval < 200ms → skip `PageController.animateToPage` → `jumpToPage` langsung. Gak ada queue animation. - **BlocListener prefetch scoped to CS only**: SinglePage/VerticalPage gak panggil `_prefetchImages` di listener — ExtendedImage handle sendiri via PageView. - **Bug fix CS animated WebP**: O(1) average-based estimation gak akurat buat chapter dengan height variance → `_animatedPauseNotifier` nyalain AnimatedWebPView yang salah. Fix: O(n) scan pake cached heights.Files: `reader_state.dart`, `reader_cubit.dart`, `reader_screen.dart`.
| 2026-07-12 | Claude Code | 120fps performance session — 8+ fixes across 4 files | Done | Massive perf overhaul targeting 120fps reader. Summary: \n- Removed dead `scrollingNotifier` code from `AnimatedWebPView` (scroll state now managed entirely via `_animatedPauseNotifier` sentinel in reader_screen)\n- Bug: non-CS `onPageChanged` gak update `_animatedPauseNotifier` → animated WebP mati di page 2+. Fix: tambah `_animatedPauseNotifier.value = reportPage`\n- `_targetDecodeWidth` gak lagi return `null` untuk non-CS — decode di display width (1080px), bukan native 4000px\n- `FilterQuality.medium` untuk heavy source → `FilterQuality.low` untuk SEMUA static image\n- `clipBehavior: Clip.none` di PageView\n- Guard `if (!_scrollingNotifier.value)` pada sentinel pause — hindari mount/unmount PlatformView loop tiap scroll tick\n- Impeller (Vulkan) enable di AndroidManifest\n- `_isHeavyPrefetchSource` gak lagi block `ExtendedResizeImage.preCacheImage` — semua source dapet pre-decode\n- Pre-decode pake `ExtendedResizeImage.resizeIfNeeded(cacheWidth, provider)` + `precacheImage` — fix `.resolve()` tanpa listener (no-op bug)\n- Online: `ExtendedNetworkImageProvider` — offline: auto fallback ke `LocalImagePreloader.getLocalImagePath` → `FileImage`\n- Non-CS: `_prefetchImages` + `_evictDistantPages` di-skip — PageView pre-build adjacent pages sendiri\n- `loadStateChanged` skip loading indicator untuk local files\n- Native static `AnimatedWebPView(staticOnly)` via Kotlin `renderStaticBitmapFromFile` — tapi rollback karena PlatformView overhead di non-CS swipe + CS ListView\n- Final: semua mode pake `ExtendedImage` + cacheWidth + pre-decode (tidak native)\n- Bugs confirmed: \n  - asimetri forward/backward pre-decode — backward pages gak di-decode\n  - `ExtendedResizeImage.resizeIfNeeded().resolve()` tanpa listener = no-op\n  - `.g.` bisa di-inject\n  - offline → ExtendedImage.network loading state muncul (HTTP fail) sebelum file lokal terdeteksi\n  - PageView tap cepat → snap animation override → halaman loncat (Framework limit, gak bisa di-fix dari app code)\n- Pending: \n  - native static rendering via PlatformView (butuh SurfaceTexture / VirtualDisplay, bukan hybrid composition)\n  - custom PageView dengan shorter snap animation utk 120fps tap\n  - novel support (butuh proposal terpisah)\n  - rawdevart config implementasi\n  - note-mode proposal\nFiles: `reader_screen.dart`, `extended_image_reader_widget.dart`, `animated_webp_view.dart`, `AnimatedWebPView.kt`, `AndroidManifest.xml`. |
| 2026-07-11 | Claude Code | Animated WebP non-CS mode bug — commit c1cc959d regression | Done | `c1cc959d` introduced `_animatedPauseNotifier` for continuous-scroll scroll pause, but non-CS `onPageChanged` (horizontal + vertical PageView) only updated `_visiblePageNotifier`. Animated WebP in singlePage/verticalPage page 2+ never got "now visible" signal → `_shouldAutoPlay` always false → animation dead. Fix: added `_animatedPauseNotifier.value = reportPage` alongside `_visiblePageNotifier.value = reportPage` in both `onPageChanged` callbacks. One line, `replace_all:true` covered both paths. |
| 2026-07-10 | Claude Code | Reader continuous scroll performance overhaul | Done | Fixed 7+ bottlenecks in continuous scroll reader: `cacheWidth` applied to ALL images (not just heavy sources — 25× decode gain), `FilterQuality.low` for non-heavy (GPU bicubic→bilinear), `setState({})` debounced per frame on image height, scroll throttle 200→300ms, `_evictDistantPages` skips scan when still in eviction window, `_prefetchImages` skips on page jump >3, `_estimateContinuousVisiblePage` O(1) average-height estimate for 200+ page chapters. Added `visiblePageNotifier.value=0` sentinel during scroll — pauses ALL animated WebP (single state channel, no cascade). Added `_animatedPauseNotifier` separate from `_visiblePageNotifier` so page indicator never flickers. `AnimatedWebPView` uses `AnimatedSwitcher` crossfade (thumbnail↔AndroidView — no blink). `_lastShouldAutoPlay` guard prevents redundant play/pause cascade from 3 notifier sources. Also fixed offline grid lag: `Image.file` now passes `cacheWidth` (400px thumbnail, not full 4500px decode). Files: `reader_screen.dart`, `extended_image_reader_widget.dart`, `animated_webp_view.dart`, `progressive_image_widget.dart`. |
| 2026-07-10 | Claude Code | ToonCubus imgbox URL missing dot fix | Done | Fixed broken image URLs in ToonCubus reader (`images2/imgbox.com` instead of `images2.imgbox.com`). Root cause: HTML page itself has missing dot in ~50% of imgbox URLs. Fix: added regex in `_sanitizeImageUrl()` to fix hostname with missing dot before known image hosts. Also routed detail-page image hydration through `_sanitizeImageUrl()` so download also gets fixed URLs. File: `generic_scraper_adapter.dart`. |
| 2026-07-10 | Claude Code | Hentaicosplay config analysis | Done | Verified `hentaicosplay-config.json` selectors against live site. Site migrated from numeric IDs (`/image/78586/`) to slugs (`/image/yenny-volume/`). Config selectors all valid (home list, detail fields, reader images, pagination). |
| 2026-07-10 | Claude Code | RawDevArt config proposal | Done | Created `openspec/changes/rawdevart-config/` with proposal, design, specs, tasks. Pure JSON REST API (`/spa/` endpoints). Ready for `/opsx:apply`. |
| 2026-07-10 | OpenCode | ViHentai packed JS image URL regex fix | Done | Fixed `_imageUrlRegex` in `vihentai_packed_js.dart` — JS-escaped forward slashes (`\/`) in decoded URLs prevented regex from matching, falling back to `<img>` extraction which grabbed `/imgs/fav2.png`. Fix: normalize `\/` → `/` before regex matching. Also aligned `_packedArgsRegex` group 1 to `(.+)` per Tachiyomi reference. 18/18 tests pass. |
| 2026-07-10 | Claude Code | MangaDex search language filters (originalLanguage, availableTranslatedLanguage) | Done | Added `originalLanguage[]` and `availableTranslatedLanguage[]` multi-picker fields to `mangadex-config.json` search form. 62 language options via static `dataSources.languages` block. Excluded `excludedOriginalLanguage` from scope for now. Proposed `mangadex-search-language-to-detail` change (pass search language filters → detail page auto-selection) — drafted proposal/design/specs/tasks but not implemented. |
| 2026-07-09 | Claude Code | MangaFire/MangaDex chapter pagination, volume separation, language filtering | Done | Complete overhaul: `scanGroup` now respected in adapter (skip volumes when `scanGroup='Chapter'`). `translatedLanguage[]` injected for MangaDex. Page-based (MangaFire) / offset-based (MangaDex) load more via `ContentRepository`. Reader cubit lazy pool expansion. Language emoji flags replacing SVG. `_selectLanguage` fix. General `onLanguageSelected` handler. 60 language entries in `languages.json`. ARB `loadMoreChapters` key. |
| 2026-07-07 | Antigravity | MangaFire volumes and chapters scanGroup fix | Done | Fixed missing Volumes tab on MangaFire detail page. Switched `fallback` to `value` in `mangafire-config.json` for `scanGroup` inside both `chapters` and `volumes` config blocks because generic parser skips fields without selectors. This correctly populates the `scanGroup` on `Chapter` models so `DetailMangaFireCoordinator` displays the tabs. Also added `date` extraction and removed hardcoded `en` language to fetch all translations. |
| 2026-07-07 | Codex | Numeric gallery ID search redirect | Done | Fixed `DynamicFormSearchUI._onSearch()` to detect numeric-only query (e.g. `544433`) and navigate directly to `/content/{id}` instead of saving a search filter. Search APIs (nhentai, hentaifox, hentainexus, e-hentai, etc.) do full-text search and return empty results for numeric gallery IDs — detail endpoint fetches correctly. Applied to all sources via shared DynamicFormSearchUI. Verified real API: nhentai REST + 4 scraper sources. Affected file: `dynamic_form_search_ui.dart` (+7 lines).
| 2026-07-06 | Claude Code | Deprecate legacy search UI + smart query parser placeholder | Done | Deprecated legacy `QueryStringSearchUI` and `FormBasedSearchUI` in favor of `DynamicFormSearchUI`. Added placeholder hints for `smart-query-parser` syntax (`tag:yuri -tag:futanari language:english`) in 3 configs (nhentai, ehentai, hitomi). Verified 464/464 tests. |
| 2026-07-06 | Claude Code | Heavy image continuous scroll for ehentai | Done | Added `ehentai` to all 3 heavy source switch-cases: `shouldSkipHeavyImageAutoSwitchForSource` (keeps continuous scroll, no auto-kick to singlePage), `_isHeavyPrefetchSource` (disables prefetch), `_isHeavyReaderSource` (25% scroll-cache, ClampingScrollPhysics). Fixed `AnimatedWebPView` to pass `visiblePageNotifier` for heavy sources even in continuous scroll → off-screen animations auto-pause. Added `_evictDistantPages()` call on scroll for heavy sources (±4 window). Ehentai 10MB+ WebP now works in continuous scroll (online + offline). Deleted `query_string_search_ui.dart` (+44KB) and `form_based_search_ui.dart` (+21KB). Rewrote `search_screen.dart` (195→128 lines) — stripped `SearchConfig` routing, `_buildScraperQueryFallback`, `_shouldUseLegacySearchUi`, `_buildLegacySearchUi`. Hardwired to `DynamicFormSearchUI`. 8/8 tasks, 464/464 tests. Also proposed `smart-query-parser` for `tag:yuri -tag:futanari language:english` syntax — archived with only placeholder hints added to 3 config files (nhentai, ehentai, hitomi). |
| 2026-07-04 | OpenCode | AVIF offline height fix iteration | In Progress | AVIF images in continuous scroll show extra empty space + scroll jump only in offline mode (online fine). Multiple `_buildImageViewer` fixes tried: removed SizedBox height (blank items), restored with 0.2 viewport fallback + setState (still broken on AVIF), GlobalKey measurement (still broken). Suspect root cause: offline AVIF triggers `_preCheckDiskCacheForHeavy` which fires `onImageLoaded` EARLY with wrong dimensions from WebP VP8X chunk parsing, while online waits for `ExtendedImage.network` → `LoadState.completed` → correct decoded dimensions. Dual `onImageLoaded` path causes height miscalculation. Reverted to original code; created `docs/fix_avif_offline_height.md` for external AI analysis. |
| 2026-07-03 | OpenCode | melos v8 migration + cleanup | Done | Migrated melos v6→v8 with pub workspaces. Deleted `melos.yaml`. Added `workspace:` key, `resolution: workspace` to packages, `melos:` scripts. Resolution: `json_path ^0.7.0→^0.9.0`, removed `flutter_launcher_icons` (cli_util conflict), no `dependency_overrides`. Stripped `analysis_options.yaml` to bare `flutter_lints` + excludes. Added `mocktail`/`bloc_test` to root dev_deps. Fixed 10 `unintended_html_in_doc_comment`. `flutter analyze`: zero issues. |
| 2026-07-01 | Claude Code | Search Form UI Parity | Done | Advanced Filters toggle panel, config `options` upgrade, sort sync, migrated 6 configs to `searchForm`, bugfix: `_collectEncodedQueryParts` missing `sort` type, main screen sort preserve, `QueryStringSearchUI` sort chip selector, `SearchFormOptionConfig` dual String/Map fromJson, `AuthConfig.enabled` null safety, `SearchFormFieldOption.fromMap` reads `name` key, field restore cross-contamination fix (prefix matching + `joinMode:space`), chip value double-prefix fix (`_extractFieldCoreFromToken`). Manhwaread radioGroups/checkboxGroups migrated to searchForm.params. manhwaread sort 12 options, status 5 options, genre 32 static numeric IDs, extra fields (keyword_mode, artist, author, year_range, chapter_range). manhwaread s_mode hidden (follow-up). 464/464 tests. |
| 2026-06-30 | Antigravity | Dynamic Form Sort Fix | Done | Fixed a bug where dynamic form sort inputs were stripped when returning to the Main Screen, causing sources like MangaFire and all generic scraper sources to fall back to the default Main Screen sort. Removed `MainScreenUtils.removeRawSearchQueryParam` from `MainScreenScrollable._reloadSearchFilter` to preserve the `raw:` query sort parameter intact for the adapter. |
| 2026-06-29 | Codex | ViHentai Source Integration Analysis | Proposal | Config valid, openspec proposal created, PDF analysis generated. Needs 3 custom plugins for Livewire/packed JS/chapters. |
| 2026-06-29 | Claude Code | CMS template analysis + config generator MangaThemesia + dojing.net test | Done | CMS analysis of 20 configs, live-verified 11 sites. 3 reusable templates (Madara/ZManga/Blogger) → `output/cms-template-analysis.md`. Fixed `cms_detector.dart` + `config_generator.dart` for MangaThemesia theme detection. Added smart probes (lang/favicon/color). Tested against `dojing.net`, output `output/gen-dojing-config.json`. |
| 2026-06-29 | Claude Code | Code review, CA refactor, security audit, build fix | Done | Comprehensive code review: cursor pagination DRY refactor (−63 lines), `_maxPrimePages=10` guard. Test fixes (crotpedia+doujindesu). Security: `.gitleaks.toml` (45→0 leaks), `.air/mcp.json` timeout fix, `print()` removed. CA Path A: `ReaderSettings`→domain entity. CA Path B: 6 files→`UserDataRepository`/`TagRepository`. CA SplashBloc: `AppInitializer` abstraction. Package: `kuron_ads` deleted. CLAUDE.md+AGENTS.md synced (FVM, search/security tools). ARB keys fixed→release APK 265MB. |
| 2026-06-29 | Codex | HentaiNexus cover stabilization + ToonCubus reader/tag runtime fix | Done | HentaiNexus detail cover scraping now uses `meta[property="og:image"]` so cover URLs come from page metadata instead of guessed reader image extensions. Locked in recent HentaiNexus reader fixes: page-URL dedupe with format priority, detail-cache bypass, continuous-scroll heavy-image guard, continuous-scroll height fallback, safer detail-header cover fallback. For ToonCubus, updated local config/runtime to match real Blogger fixtures: home uses `max-results=16`, search uses `max-results=12`, label/tag pages use `/search/label/{tag}`, detail exposes real `Baca Online` chapter list, reader fetching follows explicit `tooncubus-read.my.id` link before scraping final `imgbox` images. Added focused `kuron_generic` fixture tests for ToonCubus home pagination, detail chapter extraction, reader-link handoff, label-route tag search. |
| 2026-06-28 | Antigravity | Tag duplicate fix & slug resolution fallback | Done | Fixed duplicate tags ("Shiro Marimo\n1" vs "Shiro Marimo") by stripping counts and trailing newlines from generic text fields. Implemented regex-based trailing count stripping in `hentairead-config.json` for future extractions and `ContentModel._decodeStringList` to clean cached tags in DB on load. Fixed tag resolution bug with slug generation fallback when older corrupted tags fail to resolve `tagId`. |
| 2026-06-28 | Claude Code | Native DNS roll-out + source health monitor proposal | Done | Promoted native Android DoH as canonical managed DNS path. Removed Dart-side DnsResolver from DI. Added Private DNS diagnostics (ConnectivityManager API 29+), system DNS settings launch with layered fallback, settings UI showing device Private DNS status with l10n (en/id/zh). Proposed `source-health-monitor` — per-source HTTP health check in settings with colored dot indicators, "Check All" button, advisory-only guidance. |
| 2026-06-28 | Claude Code | Home scroll + reader performance optimization | Done | Merged nested FutureBuilders in grid cards into single `Future.wait`, added `RepaintBoundary` to each grid card and reader page, added `buildWhen` to BlocBuilders, set `clipBehavior: Clip.none` on scrollable grids. Fixed offline→reader blank screen bug by removing Strategy A4 in ReaderCubit that skipped offline content resolution. Fixed home grid badges not updating after navigating back. |
| 2026-06-28 | Codex | HentaiRead source bootstrap + generator Cloudflare probe hardening | Done | Added local `hentairead` source config as no-chapters reader source that falls back to `/hentai/{slug}/english/p/1/` and patched `chapterDataScript` extraction to support alternate `single-chapter-js-extra` + `single-chapter-js-before` script pair. Added focused config/runtime tests and hardened `kuron_config_generator` probe detection so Cloudflare challenge pages returning HTTP 200 are treated as blocked during `generate --url` smoke tests. Note: in-app browser skill was requested but `iab` was unavailable in this session, so discovery fell back to source code + protected probe verification. |
| 2026-06-28 | Codex | ManhwaRead latest feed + chapter scoping + random dice fix | Done | Fixed `manhwaread` browse feed to use `/manhwa/` latest-release listing, scoped detail chapter extraction to `#groupChapterList #chaptersList a.chapter-item` so unrelated series chapters no longer leak into detail page, enabled random dice support via scraper `randomUrl` plus `GenericHttpSource.getRandom()` scraper fallback. Added focused regression tests for config contract, real detail fixture chapter scoping, scraper-random ID extraction. Note: `informations/configs` is still gitignored, so config change is local unless mirrored into tracked config provider path. |
| 2026-06-28 | Codex | ShiroDoujin chapter title cleanup | Done | Removed chapter date parsing from local `shirodoujin-config.json` and made chapter title extraction ignore inline trailing dates like `Januari 22, 2026`, so detail chapters keep only URL + clean title. Verified with targeted `packages/kuron_generic` scraper/config tests. |
| 2026-06-28 | Claude Code | ManhwaRead full config + reader + tag routing | Done | Full `manhwaread-config.json` rewrite: `urlPatterns`, `selectors`, pagination, `chapterDataScript` reader, prefix routing. Added `"self"` pseudo-selector in engine. Injected author/artist/publisher as typed Tags. Tag count strip regexes. 5 unit tests for `mode:name`. |
| 2026-06-27 | Claude Code | SpyFakku remote tag autocomplete + multi-select search filters | Done | Added client-side tag autocomplete for SpyFakku without API endpoint. Extracted 4,423 tags from hentalk.pw boot data into `configs/tags/tags_spyfakku.json`. Added `tagSource` block to `spyfakku-config.json` with remote URL. Added `TagDataManager.loadAndCacheTagsFromUrl()` for per-source remote tag loading. `TagRepositoryImpl.getAutocomplete()` falls back to `TagDataManager.searchTags()` for tag-data-enabled sources. `QueryStringSearchUI` now encodes multi-select filter selections (tag/artist/parody) into query string for `GenericRestAdapter`. `_parseAndExtractFilters` strips tag tokens from restored queries with multi-word quoted value support. |
| 2026-06-27 | Codex | Offline metadata `content_id` resync fix | Done | Fixed offline DB rebuild for hashed download folders (`komiktap`, `crotpedia`, and similar native-worker downloads). `DownloadStorageUtils` / `OfflineContentManager` now read native `metadata.json` keys like `content_id` and `source`, so full offline resync rebuilds DB rows with real chapter ID instead of hash folder name (e.g. `10vlmmznl1`, `11k38msg3d`). Added regression tests for metadata sync and card download-status matching. |
| 2026-06-27 | Codex | Tag page + offline card revamp | Done | `content_by_tag` now reuses home-style featured/grid cards instead of older generic card renderer. Offline library group cards remade with clearer offline/read status pills, stronger cover-first hierarchy, extra bottom grid padding so last row does not sit too close to floating sort button. |
| 2026-06-26 | Antigravity | Core upgrades & ZIP import polish | Done | Upgraded `flutter_local_notifications` (v22.0.1) and fixed breaking API changes. Purged UI packages (`shimmer`, `flutter_spinkit`, `pull_to_refresh`) for native/local `KuronShimmer`. Polished offline ZIP import by moving extraction notification into `onStarted` to fix ghost notifications on picker cancel, added file progression `[x/y]` to bulk ZIP extraction notifications. |
| 2026-06-26 | Antigravity | BLoC pattern modernization | Done | Modernized BLoC patterns: extracted presentation logic (chapter-language grouping, filter-summary formatting) into reusable helpers. Moved display-formatted summary logic out of BLoC/Cubit state classes into dedicated presenters/mappers. Extracted high-risk orchestration logic from oversized widgets into focused coordinators. Replaced ad-hoc `debugPrint` and `Logger` usage with centralized project logging strategy. Archived `openspec/changes/bloc-pattern-modernization`. |
| 2026-06-25 | Codex | Release v0.9.21+31 | Done | Bumped version/build to `0.9.21+31`, added release notes for home card read/offline borders and cover badges, updated README download links, tagged snapshot as `v0.9.21+31`. Verified with `dart format` and `flutter analyze`. |
| 2026-06-25 | Codex | LifecycleWatcher nhentai config guard | Done | Guarded `LifecycleWatcher.didChangeAppLifecycleState()` so it skips `DownloadBloc` access until `RemoteConfigService` loads bundled `nhentai` config. Removes startup/resume crash `Bad state: nhentai config not loaded` without changing bootstrap order. Verified with `fvm flutter analyze lib/presentation/widgets/lifecycle_watcher.dart`. |
| 2026-06-24 | Kiro | Config Generator Phase 1 (Option A) | Done | Implemented `add-kuron-config-generator` Phase 1 per Ponytail ultra principles: built complete interactive wizard CLI for generating Kuron source configs without manual JSON writing. Completed 15/56 tasks (27%): §1 Runtime Coordination (confirmed `kuron_core` APIs ready), §2 CLI Scaffold (3 commands with args/logging/tests), §3 Guided Wizard (question flow + stdin/stdout runner + config generator + tests). Deferred 41 tasks (73%): HTTP discovery, browser automation, GitHub mining, validation integration - all YAGNI per design doc. Deliverables: working `packages/kuron_config_generator/` with CLI entry point, WizardBuilder (identity/features/API/scraper/headers questions), WizardRunner (interactive stdin/stdout), ConfigGenerator (answers→JSON), README with usage, all tests passing. Tool generates valid Source Config v2 files. Usage: `cd packages/kuron_config_generator && fvm dart run bin/kuron_config_generator.dart generate --interactive`. Validation via existing `kuron_config_validate` CLI. Decision rationale: 15 configs already written manually prove manual input works; discovery features add heavy dependencies (browser, GitHub API); ship working wizard now, iterate if manual proves too slow. |
| 2026-06-24 | Codex | ZIP import multiple + local path flattening | Done | Added native multi-ZIP picker support and wired Dart fallback to single-pick when multi-select unavailable. ZIP extraction now flattens image paths to filename leaf so nested archive folders no longer create `[folder]/[image]` under `images/`. Backup sync now honors active source filter: `local` gets source-folder-only resync with stale local DB rows cleared first, `all` keeps scanning all source roots. Verified with targeted `fvm flutter test test/unit/core/utils/offline_content_manager_metadata_sync_test.dart test/unit/domain/usecases/import_zip_usecase_test.dart` and `fvm flutter analyze` on touched Dart files. |
| 2026-06-24 | Kiro | Config Generator Phase 2 — HTTP Discovery | Done | Extended `add-kuron-config-generator` with URL-assisted discovery: `http_probe.dart` (HTTP GET + content-type detection for HTML/JSON), `cms_detector.dart` (Madara/WordPress/custom CMS detection from HTML signatures + selector suggestion), `api_detector.dart` (JSON array/map/data[]/detail inference + pagination hints), integrated into `generate --url` command. Test: probe manhwaread.com via Playwright, generated real working config validated as `compatible`. 27 tests passing, analyzer clean. README updated with URL-assisted workflow. |
| 2026-06-23 | Codex | MangaFire integration + lazy chapter lanes archive | Done | Finalized MangaFire integration and follow-up lazy chapter lane behavior. MangaFire detail now keeps non-default language/volume lanes deferred until selected, shows loading for active lane, reuses embedded related content, hides empty related UI, avoids leaking internal lane metadata tags into public tag list. Recorded changes in `CHANGELOG.md` / `MEMORY.md`, archived `openspec/changes/mangafire-integration` + `openspec/changes/lazy-load-chapters` with known caveat that some OpenSpec verification/task checkboxes left incomplete despite shipped implementation. |
| 2026-06-23 | Antigravity | MangaFire generic tag routing intercept | Done | Fixed `MangaFireAdapter` search so generic tag queries from `rawParam` config mappings (like `raw:author:{value}=` or `raw:magazine:{value}=`) are intercepted and converted into explicit `author:` / `magazine:` prefixes before routing. Restores MangaFire detail-page tag navigation (author, magazine) which fell back to generic keyword search. |
| 2026-06-22 | Codex | E-Hentai download strategy chooser | Done | Added minimal E-Hentai-specific strategy resolver gated by live E-Hentai config shape (`source=ehentai`, `download`, `chapters`, `imageUrls.mode=ehentai_page_fetch`). Follow-up fix: main gallery download button now opens action sheet for `Download whole gallery` and `Choose gallery range`, part-row buttons no longer offer range and go straight to part-only download. Verified focused resolver tests and analyze. |
| 2026-06-22 | Codex | Offline content body duplicate chapter fix | Done | Fixed duplicate chapter counts/rows in `OfflineContentBody` and offline detail by normalizing `ContentGroup` to unique items and reusing deduped list in body/detail consumers. Chapter badges, long-press info, detail fallback now derive from same unique chapter set, so stale duplicate DB IDs no longer show as extra chapters. Verified with focused offline cubit test and analyze. |
| 2026-06-21 | Codex | Offline duplicate chapter detail fix | Done | Fixed duplicate offline detail rows when DB contains multiple completed downloads with same source/title/local path but different IDs. `ContentGroup` now dedupes items by source + normalized title + cover directory, `OfflineSearchCubit` computes grouped size/progress from unique item list, `OfflineSeriesDetailScreen` applies same dedupe in direct storage fallback. Verified focused offline search cubit test and targeted analyze. |
| 2026-06-21 | Codex | archive tabbed-multilang + search-runtime-autowiring | Done | Added changelog notes for chapter language lane and search runtime wiring work, archived `openspec/changes/tabbed-multilang-chapters` and `openspec/changes/search-runtime-autowiring` to `openspec/changes/archive/2026-06-21-*`. |
| 2026-06-21 | Codex | Detail chapter preview UI polish | Done | Polished chapter preview section on detail page (`DetailChapterSection`) to match improved bottom sheet direction: lighter container, quieter header, compact language chips with stronger selected state, slimmer preview rows, scanlation/date/read-progress subtitle, lighter read/download actions. Verified focused analyze and detail chapter widget test. |
| 2026-06-21 | Codex | Chapter bottom-sheet UI polish | Done | Modernized `ChapterListBottomSheet` after MangaDex paging follow-up: language chips in fixed rail with stronger selected styling, header shows selected language and loaded count, rows show scanlation group/date subtitle when available, read/completed border states clearer, MangaDex load-more uses stronger footer action (`Load 100 more ...`). Verified focused analyze and detail chapter widget test. |
| 2026-06-21 | Codex | MangaDex chapter lane bottom-sheet paging | Done | Follow-up to `tabbed-multilang-chapters`: `View all chapters` opens bottom sheet scoped to selected chapter language lane. MangaDex detail chapter config sets `autoPaginate=false`, generic REST adapter honors it so detail load stops at first chapter page instead of fetching all offsets. `ChapterListBottomSheet` adds MangaDex-only `Load more` that fetches next page for active `translatedLanguage[]` lane and de-dupes chapters. Verified JSON, targeted analyze, detail widget test, `packages/kuron_generic` MangaDex integration test. |
| 2026-06-21 | Codex | tabbed-multilang-changes implementation | Done | Added shared chapter language presentation (`ChapterLanguagePresenter`) for alias normalization, unknown fallback, lane ordering, selected-lane preservation. Detail chapter preview and `ChapterListBottomSheet` now show language chips only for multi-language chapter sets while keeping single-language lists non-tabbed. Reader route extras carry active chapter language into reader defaults, reader same-language navigation uses shared normalizer. Verified with targeted analyze plus unit/widget tests for presenter, reader route payload, detail chapter UI. |
| 2026-06-17 | Codex | Crotpedia search field dedupe | Done | Removed duplicate Crotpedia search input by deduplicating search-form field synthesis in `DynamicSearchFormContract`: explicit- Fixed `DynamicFormSearchUI` `_setRestoredFieldValue` to correctly handle and restore multiple fields sharing the same `queryParam` (e.g. `rawParam`). - Fixed `DynamicFormSearchUI` picker restore logic (`_isPickerField`) to correctly respect and strip `valuePrefix` before queuing for multi-restore, preventing cross-contamination and duplicated dummy chips when multiple pickers share the same `queryParam`. - Transformed MangaFire's search config to use dynamic `dataSources` targeting `/api/filter-options`. Implemented multi-select pickers for `Types`, `Status`, `Genres`, `Themes`, `Demographics`, `Content Rating`, and `Formats`, matching the robust functionality of MangaDex without any app-side UI code changes. emitted twice. Added regression coverage ensuring `title` query field appears only once when both `searchForm` and `searchConfig` overlap. Verified with `cd packages/kuron_generic && fvm dart test test/config/source_config_parser_test.dart` and focused analyze on touched package files. |
| 2026-06-16 | Codex | Search and filter chip contrast polish | Done | Polished theme-aware selected chip colors across search and filter UIs. `DynamicFormSearchUI` select chips now use `onPrimaryContainer` for selected text/checkmarks, checkbox chips use explicit selected/unselected label and border colors, MangaDex include/exclude tag pickers use distinct readable green/red palettes in light/dark mode, picker-backed include/exclude data fields share same selected-state colors. `FilterDataScreen` and `SelectedFiltersWidget` aligned so include chips green and exclude chips red in both result grid and selected-filter summary. Verified with focused `fvm flutter analyze` on touched search/filter UI files. |
| 2026-06-16 | Codex | search-runtime-autowiring canonical contract bridge | In Progress | Implemented safe first slice of `openspec/changes/search-runtime-autowiring`: package `DynamicSearchFormContract` now supports radio/hidden fields, string options, sort `apiValue`, legacy form-based text/radio/checkbox groups, query/sort/page inference from `searchConfig` and conventional search URL params, plus diagnostics for inferred/unsupported search forms. App `RemoteConfigService` exposes canonical package contract, `SearchScreen` routes safe canonical forms into `DynamicFormSearchUI`, rich legacy query-string configs like `filterSupport` remain on old UI to avoid losing advanced filters before parity. Added `SearchFormContractAdapter`, checkbox/radio support in dynamic renderer, package parser tests, app adapter test. Follow-up fixes preserved `searchForm.dataSources` and field `ui.dataSource` in canonical bridge so MangaDex picker-backed tag fields can open bottom sheet and load `/manga/tag` options, fixed REST raw search URL building so Komikcast `raw:query=neko` fills endpoint placeholders inside `filter=title=like="{query}"...` instead of emitting `query=neko` with empty filter, moved `DynamicFormSearchUI` route pop outside save try/catch using `Navigator.canPop()` so route/context pop issue no longer appears as `failed to save filter: Null check operator used on a null value`, fixed search-result sorting so `DynamicSortingWidget` updates `_currentSearchFilter` before dispatching `ContentSearchEvent`, finalized UX decision that sort belongs only to Home/Search Results: Search page hides and does not serialize sort fields, stale raw `sort=` stripped when saved filters reloaded, REST sort follows `SearchFilter.sortBy` from Home. Verified with focused `fvm dart test packages/kuron_generic/test/config/source_config_parser_test.dart`, `fvm flutter test test/unit/presentation/pages/search/search_form_contract_adapter_test.dart`, `cd packages/kuron_generic && fvm dart test test/integration/komikcast_rest_integration_test.dart`, focused analyze for touched package/app files. Remaining OpenSpec tasks: dedicated search-form orchestration layer, broader widget/state/request tests, final legacy UI deprecation/removal after parity. |
| 2026-06-16 | Codex | Offline library/detail + reader interaction + custom storage permission polish | Done | Fixed offline library grouped metadata and actions: group/item size now uses per-item DB `file_size`, long-press sheet on `OfflineContentBody` is info-only with chapter count and path list, destructive/read/PDF actions moved to `OfflineSeriesDetailScreen`. Fixed offline detail delete flow to use singleton offline search cubit, refresh local item state, refresh reader progress after returning from reader. Reader now force-flushes offline progress to `reader_positions` on dispose, supports tap zones over native/animated images, has draggable mini chrome toggle for show/hide header/footer. `AnimatedDiceWidget` icon color now follows `IconTheme`/theme. `DownloadsScreen` no longer requires full storage permission when `StorageSettings.custom_storage_root` configured; checks custom root and only requests notification permission, with Settings snackbar when no download directory set. Verified with targeted `fvm flutter analyze` on touched files. |
| 2026-06-11 | Antigravity | Offline library pagination & N+1 fix planning | In Progress | User approved architectural finding that offline library grouping pagination was broken because it fetched 20 raw items from Isar DB then grouped them. Wrote `implementation_plan.md` to fetch all raw items, group in memory, paginate resulting groups. Also planned to fix N+1 `ReaderRepository` query by extracting progress checking into separate function running only on visible paginated groups. Implementation deferred. |
| 2026-06-10 | Antigravity | Offline Sort & Filter UI Polish + BottomSheet Path | Done | Improved `OfflineContentBody` sorting/filter UI with Glowing Gradient FAB, modern AnimatedContainer filter chips, pill TabBar ripples. Fixed FAB auto-hide by adding `_scrollController` to `GridView`. Fixed filter state anomaly by reading `offline_selected_source_filter` from `SharedPreferences` during `OfflineSearchLoading` state to prevent UI flickering back to "All" tab. Added file path display in offline long-press bottom sheet with "Copy Path" and "Open in Explorer" (`open_file` package) utilities. |
| 2026-06-01 | Codex | Rate-limit hardening + config baseline sync | Done | Hardened rate-limit flow end-to-end: `RequestRateManager` now source-config aware (`enabled`, `cooldownDurationMs`), 429 cooldown now uses manager timing (removed hardcoded 5-minute cooldown in remote datasource), nhentai cooldown wait now explicit and loop-based, generic runtime pipeline (`GenericSourceFactory` -> `GenericHttpSource` -> REST/Scraper adapters) now applies config-driven `RateLimiter` (`requestsPerSecond`/`requestsPerMinute`, `maxConcurrentRequests`, `minDelayMs`). Fixed `flutter_secure_storage` test override compatibility by switching to `AppleOptions`. Added baseline `network.rateLimit` blocks for multiple source configs under `informations/configs` (not tracked in git because directory ignored). Verified with targeted analyze/tests in app, `kuron_generic`, and `kuron_special`. |
---

## Protected Files (NEVER edit directly)
- `*.g.dart` — Generated by `build_runner`
- `*.freezed.dart` — Generated by Freezed
- `pubspec.lock` — Auto-generated

> Edit source file and run: `fvm flutter pub run build_runner build --delete-conflicting-outputs`

---