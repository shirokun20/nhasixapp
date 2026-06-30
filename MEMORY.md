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
| **Version** | 0.9.21+31 |
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

> Tracked via `openspec/` — Last updated: 2026-06-25

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
- `2026-04-xx-komiktap-navigation-lists`
- `2026-03-xx-multi-provider-integration`
- `2026-03-xx-smart-caching-and-fixes`
- `2026-03-xx-unity-ads-fix`
- `2026-03-xx-view-comments`
- `2026-04-12-local-collection-categories`
- `2026-04-19-blur-recent-apps-privacy`
- `2026-04-20-ehentai-download-reader-stability`
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
- `2026-06-23-lazy-load-chapters`
- `2026-06-23-mangafire-integration`
- `2026-06-26-bloc-pattern-modernization`
- `2026-06-26-purge-ui-packages`
- `2026-06-27-update-manhwaread-config`
- `2026-06-28-native-dns-rollout`
- `2026-06-28-home-scroll-reader-optimization`

### Active Changes (in `openspec/changes/`)
- `add-doujin-desu-xxx-source`
- `add-kuron-config-generator`
- `pin-biometric-app-lock`
- `reader-ai-learning-mode`
- `revamp-kuron-config-runtime`
- `source-health-monitor` — Proposed. Per-source HTTP health check in settings (HEAD to baseUrl, timeout 10s, green/red/grey dot indicators, "Check All" button, aggregate "N/N reachable" summary). Advisory only — no auto-disable.
- `add-vihentai-source` — Proposed. ViHentai (vi-hentai.moe) source integration. Config done, needs Livewire auth + packed JS decode plugins in kuron_special. See `output/pdf/vihentai-integration-analysis.pdf`.

### Exploration / Analysis (in `openspec/changes/`)
- *(none)*

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
| 2026-06-17 | Codex | Crotpedia search field dedupe | Done | Removed duplicate Crotpedia search input by deduplicating search-form field synthesis in `DynamicSearchFormContract`: explicit legacy `searchConfig.textFields` / radio / checkbox groups now win, fields sharing same `queryParam` no longer emitted twice. Added regression coverage ensuring `title` query field appears only once when both `searchForm` and `searchConfig` overlap. Verified with `cd packages/kuron_generic && fvm dart test test/config/source_config_parser_test.dart` and focused analyze on touched package files. |
| 2026-06-16 | Codex | Search and filter chip contrast polish | Done | Polished theme-aware selected chip colors across search and filter UIs. `DynamicFormSearchUI` select chips now use `onPrimaryContainer` for selected text/checkmarks, checkbox chips use explicit selected/unselected label and border colors, MangaDex include/exclude tag pickers use distinct readable green/red palettes in light/dark mode, picker-backed include/exclude data fields share same selected-state colors. `FilterDataScreen` and `SelectedFiltersWidget` aligned so include chips green and exclude chips red in both result grid and selected-filter summary. Verified with focused `fvm flutter analyze` on touched search/filter UI files. |
| 2026-06-16 | Codex | search-runtime-autowiring canonical contract bridge | In Progress | Implemented safe first slice of `openspec/changes/search-runtime-autowiring`: package `DynamicSearchFormContract` now supports radio/hidden fields, string options, sort `apiValue`, legacy form-based text/radio/checkbox groups, query/sort/page inference from `searchConfig` and conventional search URL params, plus diagnostics for inferred/unsupported search forms. App `RemoteConfigService` exposes canonical package contract, `SearchScreen` routes safe canonical forms into `DynamicFormSearchUI`, rich legacy query-string configs like `filterSupport` remain on old UI to avoid losing advanced filters before parity. Added `SearchFormContractAdapter`, checkbox/radio support in dynamic renderer, package parser tests, app adapter test. Follow-up fixes preserved `searchForm.dataSources` and field `ui.dataSource` in canonical bridge so MangaDex picker-backed tag fields can open bottom sheet and load `/manga/tag` options, fixed REST raw search URL building so Komikcast `raw:query=neko` fills endpoint placeholders inside `filter=title=like="{query}"...` instead of emitting `query=neko` with empty filter, moved `DynamicFormSearchUI` route pop outside save try/catch using `Navigator.canPop()` so route/context pop issue no longer appears as `failed to save filter: Null check operator used on a null value`, fixed search-result sorting so `DynamicSortingWidget` updates `_currentSearchFilter` before dispatching `ContentSearchEvent`, finalized UX decision that sort belongs only to Home/Search Results: Search page hides and does not serialize sort fields, stale raw `sort=` stripped when saved filters reloaded, REST sort follows `SearchFilter.sortBy` from Home. Verified with focused `fvm dart test packages/kuron_generic/test/config/source_config_parser_test.dart`, `fvm flutter test test/unit/presentation/pages/search/search_form_contract_adapter_test.dart`, `cd packages/kuron_generic && fvm dart test test/integration/komikcast_rest_integration_test.dart`, focused analyze for touched package/app files. Remaining OpenSpec tasks: dedicated search-form orchestration layer, broader widget/state/request tests, final legacy UI deprecation/removal after parity. |
| 2026-06-16 | Codex | Offline library/detail + reader interaction + custom storage permission polish | Done | Fixed offline library grouped metadata and actions: group/item size now uses per-item DB `file_size`, long-press sheet on `OfflineContentBody` is info-only with chapter count and path list, destructive/read/PDF actions moved to `OfflineSeriesDetailScreen`. Fixed offline detail delete flow to use singleton offline search cubit, refresh local item state, refresh reader progress after returning from reader. Reader now force-flushes offline progress to `reader_positions` on dispose, supports tap zones over native/animated images, has draggable mini chrome toggle for show/hide header/footer. `AnimatedDiceWidget` icon color now follows `IconTheme`/theme. `DownloadsScreen` no longer requires full storage permission when `StorageSettings.custom_storage_root` configured; checks custom root and only requests notification permission, with Settings snackbar when no download directory set. Verified with targeted `fvm flutter analyze` on touched files. |
| 2026-06-11 | Antigravity | Offline library pagination & N+1 fix planning | In Progress | User approved architectural finding that offline library grouping pagination was broken because it fetched 20 raw items from Isar DB then grouped them. Wrote `implementation_plan.md` to fetch all raw items, group in memory, paginate resulting groups. Also planned to fix N+1 `ReaderRepository` query by extracting progress checking into separate function running only on visible paginated groups. Implementation deferred. |
| 2026-06-10 | Antigravity | Offline Sort & Filter UI Polish + BottomSheet Path | Done | Improved `OfflineContentBody` sorting/filter UI with Glowing Gradient FAB, modern AnimatedContainer filter chips, pill TabBar ripples. Fixed FAB auto-hide by adding `_scrollController` to `GridView`. Fixed filter state anomaly by reading `offline_selected_source_filter` from `SharedPreferences` during `OfflineSearchLoading` state to prevent UI flickering back to "All" tab. Added file path display in offline long-press bottom sheet with "Copy Path" and "Open in Explorer" (`open_file` package) utilities. |
| 2026-06-02 | Codex | revamp-kuron-config-runtime verification closeout | Done | Closed remaining feasible tasks for `revamp-kuron-config-runtime`: `RemoteConfigService.applySourceConfigFromJson()` now caches/removes `ValidationReport` alongside imported/uninstalled configs, new app tests cover import compatibility state caching plus download parity warnings (`test/unit/core/config/remote_config_service_test.dart`, `test/unit/domain/usecases/download_content_usecase_test.dart`). Verification passed for import/reader/download app paths (`remote_config_service_test`, `download_content_usecase_test`, `reader_screen_policy_test`, `download_bloc_test`). Android payload parsing compile verification passed in `packages/kuron_native/example/android` with `./gradlew app:compileDebugKotlin` (`BUILD SUCCESSFUL`). Provider-repo validation ran against `/Users/asix/Documents/ide_baru/kuron-config-providers/config` with report saved to `/tmp/kuron_provider_validation_report.txt`: `hitomi` and `hentainexus` = `needsEngineSupport`, `crotpedia` = `partiallyCompatible`, all other checked provider configs = `compatible`. |
| 2026-06-01 | Codex | Rate-limit hardening + config baseline sync | Done | Hardened rate-limit flow end-to-end: `RequestRateManager` now source-config aware (`enabled`, `cooldownDurationMs`), 429 cooldown now uses manager timing (removed hardcoded 5-minute cooldown in remote datasource), nhentai cooldown wait now explicit and loop-based, generic runtime pipeline (`GenericSourceFactory` -> `GenericHttpSource` -> REST/Scraper adapters) now applies config-driven `RateLimiter` (`requestsPerSecond`/`requestsPerMinute`, `maxConcurrentRequests`, `minDelayMs`). Fixed `flutter_secure_storage` test override compatibility by switching to `AppleOptions`. Added baseline `network.rateLimit` blocks for multiple source configs under `informations/configs` (not tracked in git because directory ignored). Verified with targeted analyze/tests in app, `kuron_generic`, and `kuron_special`. |
| 2026-06-24 | Kiro | Config Generator Phase 2 — HTTP Discovery | Done | Extended `add-kuron-config-generator` with URL-assisted discovery: `http_probe.dart` (HTTP GET + content-type detection for HTML/JSON), `cms_detector.dart` (Madara/WordPress/custom CMS detection from HTML signatures + selector suggestion), `api_detector.dart` (JSON array/map/data[]/detail inference + pagination hints), integrated into `generate --url` command. Test: probe manhwaread.com via Playwright, generated real working config validated as `compatible`. 27 tests passing, analyzer clean. README updated with URL-assisted workflow. |
---

## Protected Files (NEVER edit directly)
- `*.g.dart` — Generated by `build_runner`
- `*.freezed.dart` — Generated by Freezed
- `pubspec.lock` — Auto-generated

> Edit source file and run: `fvm flutter pub run build_runner build --delete-conflicting-outputs`

---