# 🧠 Kuron — Project Memory

> **Unified context file** untuk tracking progress lintas AI tools.
> Dibaca oleh: **Codex** | **OpenCode** | **GitHub Copilot** | **Antigravity** | **Manual Review**

---

## 📌 Project Identity

| Key | Value |
|---|---|
| **App Name** | **Kuron** (formerly NhasixApp) |
| **Repo** | `shirokun20/nhasixapp` |
| **Platform** | Android (Flutter) |
| **Flutter SDK** | Stable (3.24+, Dart 3.5+ via FVM) |
| **Version** | 0.9.17+26 |
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
| `kuron_nhentai` | Nhentai source implementation |
| `kuron_crotpedia` | Crotpedia source implementation |
| `kuron_komiktap` | KomikTap source implementation |
| `kuron_native` | Native Android (Kotlin) integrations |

### Key Features
- 🎯 Immersive Reader with smooth page transitions
- 🛡️ App Disguise mode (Calculator, Notes, Weather)
- 📥 Offline-first with background downloading
- 🔍 Smart Search with advanced filtering
- 🎨 Material 3, Dark/Light modes, responsive UI
- 💬 Community comments on detail pages

---

## 🏗 Architecture Overview

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
└── packages/          # Internal packages (kuron_core, kuron_nhentai, etc.)
```

### Layer Rules
- **Domain**: Pure Dart. ZERO dependencies on Data/Presentation.
- **Data**: Depends only on Domain. JSON parsing, API calls, DB storage.
- **Presentation**: Depends only on Domain (+ DI). BLoC/Cubit + UI widgets.

---

## 📊 Current Progress Dashboard

> Synced from `projects/README.md` — Last updated: 2026-04-19

### ✅ Completed (12)
- chapter_reading_history_navigation
- crotpedia_ui_modernization
- doujin_search_highlight
- favorites_bug_fix
- fix_app_drawer_transparency_on_list_screens
- komiktap_navigation_lists
- multi_provider_integration ✨ **NEW** (Phase 0-6 complete, all providers tested)
- offline_search_highlight
- reader_header_auto_show
- smart-caching-and-fixes
- unity-ads-fix
- view_comments

### 🚧 In Progress (2)
- local_collection_categories
- qol_enhancements ✨ **SCOPE COMPLETE** (submit comments shipped, execution docs updated, archive pending)

### 📋 Analysis Phase (5)
- app_audit_hardcode_ui_desktop
- download_metadata_revamp
- flutter-desktop-migration
- komiktap_navigation_lists
- reader-ads

### 🔮 Future/Backlog (1)
- nhentai_search_revamp

### 🐛 Open Issues (5)
- import-zip-and-metadata-bug (2026-03-31) → (Bug: KomikTap/Crotpedia Title Fixed ✅, Feature: Import ZIP Pending)
- local collection categories + reading status shelves (2026-04-12) → `analysis-plan/local_collection_categories/`
- qol_enhancements — Issue #32: Login/Gesture/Sort (2026-03-30) → `analysis-plan/qol_enhancements/`
- download range ignores page bounds (2026-02-17)
- download metadata chapter parentid (2026-02-15)

---

## 🔍 Search Tools

Project ini menggunakan search tools modern sebagai pengganti `grep`:

| Tool | Use Case | Command |
|---|---|---|
| `rg` (ripgrep) | Pencarian teks cepat, regex | `rg "pattern" lib/ -t dart` |
| `ugrep` | Interactive, fuzzy, hex search | `ugrep -Q "pattern" lib/` |
| `semgrep` | AST-aware Dart patterns | `semgrep --lang dart -e '$PATTERN' lib/` |

> Lihat `smart_search.sh` dan `search-tools/SKILL.md` untuk detail.

---

## 🚀 RTK - Rust Token Killer

Project ini mewajibkan penggunaan **RTK** untuk mengoptimalkan token AI (hemat 60-90%):

| Aturan | Deskripsi |
|---|---|
| **Awalan `rtk`** | Selalu tambahkan `rtk` di depan perintah terminal (git, flutter, ls, dll). |
| **Penyaringan** | RTK membuang boilerplate/noise agar AI fokus pada data relevan. |
| **Statistik** | Gunakan `rtk gain` untuk melihat total penghematan token. |

> Konfigurasi global tersedia di `~/.gemini/GEMINI.md` dan `AGENTS.md`.

---

## ⚙️ Tool-Specific Context

### OpenCode
- **Config**: `.opencode/` (agents, skills)
- **Agents**: `planner`, `architect`, `test-engineer`, `test-writer`, `code-reviewer`, `feature-dev`, `flutter-architect`, `ui-designer`
- **Skills**: `clean-arch`, `bloc-pattern`, `create-bloc`, `create-feature`, `di-setup`, `gen-test`, `manager-assistant`, `project-management`, `project-workflow`, `run-codegen`

### Codex
- **Config**: `AGENTS.md`, `.codex/README.md`, `.codex/skills/`
- **Startup Context**: `project_memory.md` -> active `projects/onprogress-plan/` -> active `progress.md` -> active main spec
- **Primary Skill Source**: `.codex/skills/*/SKILL.md`
- **Upstream Skill Mirrors**: `.opencode/skills/*/SKILL.md`
- **Secondary Skill Source**: `.agent/skills/*/SKILL.md`
- **Rule Mirrors**: `.github/copilot-instructions.md`, `.agent/rules/asix-rules.md`
- **Behavior**: Emulate local `@agent` roles directly when no explicit sub-agent delegation is requested

### GitHub Copilot
- **Config**: `.github/copilot-instructions.md`
- **Behavior**: Follows Clean Architecture, snake_case files, uses logger

### Antigravity
- **Config**: `.agent/rules/asix-rules.md`, `.agent/skills/`
- **Skills**: `api-integration`, `bloc-cubit`, `clean-arch`, `doc-workflow`, `flutter-dev`, `git-workflow`, `manager-assistant`, `native-integration`, `scraper-debug`, `search-tools`

---

## 📝 Session Log

> Gunakan format ini untuk mencatat progress per sesi.

### Template
```markdown
#### [DATE] — [AI Tool] — [Session Topic]
- **Done**: [List what was accomplished]
- **Issues**: [Any blockers or bugs found]
- **Next**: [What to do next session]
```

### Recent Sessions

> Detail lengkap di `projects/sessions/`. Format: `YYYY-MM-DD-tool-topic.md`

| Date | Tool | Topic | Status | Detail |
|---|---|---|---|---|
| 2026-04-19 | Codex | Release prep v0.9.17+26 | ✅ Done | Bumped app version to `0.9.17+26`, added a new changelog section for nhentai comment posting, animated WebP/offline reader fixes, E-Hentai original-format preservation, and recent-apps privacy. Updated `README.md`, `README_ID.md`, and FAQ docs under `docs/en` + `docs/id` to match the release, then synchronized stale tests so the full suite passes again. Verified with `fvm flutter analyze` and `fvm flutter test`, with the live Phase 6 smoke test now opt-in via `ENABLE_PHASE6_LIVE_SMOKE=true`. |
| 2026-04-19 | Codex | Blur recent apps privacy execution | ✅ Done | Created a focused execution package under `projects/onprogress-plan/blur_recent_apps_privacy/` and implemented a lightweight root-level privacy blur overlay for recent-apps snapshots. Added `AppPrivacyOverlayService`, wired it through `LifecycleWatcher` and `MaterialApp.builder`, kept background downloads untouched by leaving `DownloadLifecycleMixin` / native worker scheduling unchanged, then hardened Recents privacy with an Android 13+ native fallback in `MainActivity` plus a dedicated privacy window background. Verified with targeted service/widget tests, focused `flutter analyze`, and successful `./gradlew app:compileDebugKotlin`. |
| 2026-04-19 | Codex | PIN + biometric app lock analysis | ✅ Done | Audited the current settings, lifecycle, routing, storage, and Android host setup and confirmed the repo has no existing PIN/biometric lock foundation. Created a new analysis package under `projects/analysis-plan/pin_biometric_app_lock/` that defines the MVP scope, the recommended global `AppLockGate` + `AppLockCubit` architecture, Android host requirements, and a native-only biometric option via `kuron_native` MethodChannel instead of `local_auth`, then expanded the plan to include a lightweight root-level privacy blur overlay when the app enters inactive/paused so recent-apps snapshots are obscured. |
| 2026-04-19 | Codex | MP4 conversion feasibility clarification | ✅ Done | Confirmed the app currently has no MP4/video conversion or playback pipeline in the repo; the only built-in document conversion path is PDF. Clarified that MP4 is technically possible as a video export for animated assets, but it would no longer behave like a paged document and would lose the app's page-based reader semantics. |
| 2026-04-19 | Codex | Document conversion animated-format clarification | ✅ Done | Clarified that the app's current document-conversion path is PDF-only and does not preserve animation. The PDF pipeline preprocesses page assets into static image bytes (including JPEG re-encoding in `pdf_service`) and embeds them into `pw.MemoryImage` / `pw.Image` PDF pages, so animated WebP/GIF content is flattened to a single static page image during conversion. |
| 2026-04-19 | Codex | Animated reader format support clarification | ✅ Done | Clarified the current reader capability matrix from source code: the dedicated pause-aware animated reader is `AnimatedWebPView`, which is specifically for animated WebP on Android (API 28+ full playback, <28 first-frame fallback, non-Android fallback widget). General image file support in the native download/offline path includes `jpg/jpeg/png/gif/webp/avif/bmp`, but GIF/AVIF/JPG/PNG are not routed through the special animated reader logic, and PDF remains a separate non-animated renderer via `PdfReaderActivity`. |
| 2026-04-19 | Codex | E-Hentai download extension normalization + offline reader animated WebP detection | ✅ Done | Confirmed via device storage that the newest E-Hentai sample (`Carlotta (Animated WEBP)`) was being saved as `page_XXX.jpg` even though the file bytes start with `RIFF....WEBPVP8X` and carry the animation flag, while Hitomi saved the same class of content as proper `.webp`. Fixed the reader to sniff local/cached file headers so confirmed animated WebP bytes still route to the native pause-aware renderer even when filenames are misleading, and hardened `DownloadWorker.kt` to normalize saved filenames to the actual downloaded format after each E-Hentai page finishes. Verified with the extended reader widget test/analyze suite and a successful `./gradlew app:compileDebugKotlin` build in `packages/kuron_native/example/android`. |
| 2026-04-19 | Codex | Offline reader animated pause regression fix | ✅ Done | Traced an offline reader regression to `AnimatedWebPView`: pages that were built while visible kept `autoPlay=true` and never paused after scrolling away because visibility was OR-ed with the initial autoplay flag. Updated the native widget so `visiblePageNotifier` wins whenever page visibility is available, added a focused regression test for the stale-autoplay case, and verified with targeted `fvm flutter test` + `fvm flutter analyze` inside `packages/kuron_native`. |
| 2026-04-19 | Codex | Nhentai submit comments + app user-agent wiring | ✅ Done | Implemented authenticated nhentai comment submission on the detail screen by extending the config-driven token auth stack with a `galleryComments` endpoint, comment-specific PoW action, and create-comment client/service methods. Added an inline composer that reuses the existing login session, opens the native CAPTCHA solver when needed, and prepends successful comments immediately to the visible list. Also centralized the auth/client `User-Agent` to `Kuron/<version> (+https://github.com/shirokun20/nhasixapp)` using runtime package info. Verified with `fvm flutter gen-l10n`, targeted `config_driven_api_auth_client_test.dart`, and focused `flutter analyze`. |
| 2026-04-16 | Codex | Reader continuous-scroll cache regression fix | ✅ Done | Investigated the new non-animated scroll jank and confirmed a regression introduced by the native animated-WebP work: `ExtendedImageReaderWidget` had been changed to keep every continuous-scroll page alive and never clear network image memory cache. Restored selective retention so only heavy/native pages stay warm, while normal pages in continuous scroll can recycle again. Added testing helpers covering keep-alive and cache-clear decisions, then verified with targeted `fvm dart analyze` and the reader widget regression test. |
| 2026-04-16 | Codex | Reader native cache loader progress polish | ✅ Done | Audited the animated reader loading flow and confirmed `ExtendedImage.network` still exposes real chunk progress; the plain `Memuat...` state was coming from `AnimatedWebPView` when the native thumbnail was being prepared from an already-cached local WebP file. Seeded the native loader with the cached file size so `_buildLoadingIndicator` now shows real byte information instead of an empty loading label during native cache preparation. Verified with targeted `fvm dart analyze` in `packages/kuron_native` and the existing reader widget regression test. |
| 2026-04-15 | Codex | Reader animated WebP loader/routing/autoplay fix | ✅ Done | Fixed `ExtendedImageReaderWidget` so `_buildNativeAnimatedWebP` now uses the shared `_buildLoadingIndicator`, native animated rendering no longer hijacks every `.webp/.gif/-wbp` URL before heavy detection, and current visible animated pages auto-play through `AnimatedWebPView` while off-screen pages pause back to thumbnail mode. Follow-up polish removed manual tap/double-tap controls so the native animation flow is fully visibility-driven with a passive thumbnail preview, and native thumbnail preload now reports real byte progress back to Flutter so the loader can show actual downloaded size/percent on the native path too. Added helper-based regression tests for native routing + autoplay decisions. Verified with targeted `fvm flutter test` and `fvm dart analyze` in both app root and `packages/kuron_native`. |
| 2026-04-03 | Copilot | Release prep v0.9.15+24 — changelog, docs, README | ✅ Done | Bumped version 0.9.14+23 → 0.9.15+24. Wrote full `[0.9.15+24]` CHANGELOG entry covering: nhentai login + native CAPTCHA solver, online favorites (2-tab, add/remove/check, offline/online/both), tag blacklist (local settings manager + nhentai online sync + blur overlays + picker fix), random gallery, gesture navigation, centralized settings, native explorer, ZIP import. Added premium-source callout (E-Hentai/HentaiNexus/Hitomi require manual install via Link/ZIP). Updated docs/en/FAQ.md + docs/id/FAQ.md with new Q&A sections: nhentai login, online favorites, tag blacklist, other sources premium req. Updated README.md + README_ID.md: version badge v0.9.15, download link +24, new login/sync features block, premium source warning. Updated project_memory.md. |
| 2026-04-12 | Codex | Local collection categories MVP execution | ✅ Done | Moved `local_collection_categories` into onprogress and implemented the MVP requested by GitHub issue #37. Added SQLite support for `favorite_collections` + `favorite_collection_items`, introduced a new Freezed `FavoriteCollection` entity, extended favorites repository/data source contracts for collection CRUD and membership management, made favorite checks/removals source-aware, updated offline favorites UI with collection chips plus create/rename/delete and per-item assignment flows, and upgraded export/import schema to include collections. Targeted `fvm dart analyze` on touched files passed clean. |
| 2026-04-12 | Codex | Local collection categories + reading status analysis | ✅ Done | Audited current local favorites architecture and confirmed the app still uses a flat `favorites` table plus single-list `FavoriteCubit`/`FavoritesScreen`, while reading state already exists in `history` and `reader_positions`. Created a new local issue note and analysis package for `local_collection_categories`, recommending manual collections via new SQLite tables plus smart `Reading`/`Completed` shelves derived from history/progress instead of duplicating bookmark state. Estimated MVP at 2–4 days depending on export/import and polish scope. |
| 2026-04-02 | Copilot | Blacklist picker clear-all apply sync fix | ✅ Done | Fixed settings blacklist picker regression: `Clear All` then `Apply` previously kept old tags due to empty-result early return and append behavior. Updated flow so `null` remains cancel-only, empty selection is saved as valid clear state, and picker results replace prior local entries/metadata. |
| 2026-04-02 | Codex | QoL blacklist offline+online completion | ✅ Done | Finished Sub-Plan P5 for `qol_enhancements`: persisted local `blacklistedTags` through `PreferencesService` + `SettingsCubit`, added a modern blacklist manager in Settings, extended config-driven auth with nhentai `/api/v2/blacklist/ids`, and merged cached online IDs with local rules through `TagBlacklistUtils` / `TagBlacklistService`. Applied blurred blacklist cover overlays across main cards, generic content cards, tag-browse results, and offline library cards. |
| 2026-04-02 | Copilot | Native CAPTCHA migration + favorites online hardening | ✅ Done | Migrated CAPTCHA solving flow from embedded `webview_flutter` page to `kuron_native` (`showCaptchaWebView`) with a dedicated Android `CaptchaWebViewActivity`, token/error JS bridge, and status-bar-safe toolbar insets. In parallel, stabilized online favorites with auto-retry for transient network failures and localized friendly error messaging to avoid raw DioException output in UI. |
| 2026-04-02 | Copilot | QoL Enhancements moved to onprogress | ✅ Done | Moved Issue #32 analysis into `projects/onprogress-plan/qol_enhancements/`, updated the plan header/footer to execution, and created `progress.md` so the lifecycle now matches the onprogress workflow. |
| 2026-04-02 | Copilot | Workflow phase rule correction | ✅ Done | Reaffirmed the lifecycle rule: analysis stays read-only and tasks only move into `projects/onprogress-plan/` after explicit user approval. Added matching session and repo memory notes so future turns keep the same boundary. |
| 2026-04-06 | Codex | MangaDex author/artist tag fix + EHentai detail tag parser fix | ✅ Done | Live check confirmed MangaDex `authorOrArtist` works; fix preserves UUID tag navigation in detail screen instead of discarding non-numeric IDs. EHentai detail parser now reads both `.gt` and `.gtl` tag rows via normalized HTML + regex extraction, keeps scoped query slugs for `language/group/artist/female/male/...`, and no longer defaults missing language to `english`; regression tests added/passed. |
| 2026-03-31 | Antigravity | Build Bump +23: Release prep & docs sync | ✅ Done | Build number bumped from +22 → +23 across all release files. Updated: `pubspec.yaml`, `CHANGELOG.md` (new section with 8 recent commits), `README.md`, `README_ID.md`, `docs/en/FAQ.md`, `docs/id/FAQ.md` all synced to `v0.9.14+23`. Created annotated Git tag `v0.9.14+23` with full commit history and pushed to remote (`78b4294`). No breaking changes — pure build increment with reader enhancements (height caching, floating page indicator) + offline metadata fixes (duplicate prevention, ZIP fileSize, auto-generated manifest.json) + ZIP handler migration to `kuron_native`. |
| 2026-03-31 | Antigravity | KomikTap & Crotpedia Metadata Bug Fix | ✅ Done | Diagnosed and fixed empty/ciphertext `title` generation inside `metadata.json` when downloading chapters. Implemented a fallback in `DownloadBloc._onStart()` to restore `updatedDownload.title` if the scraper returns corrupted detail titles. Added `DownloadStorageUtils.getSafeTitleFromMetadata` on-the-fly formatter using the original slug `id` to fix retroactively broken offline files so they display cleanly instead of showing `Elegant ID` hashes. Unit tested via `download_storage_utils_test.dart` (all passed). Feature request for ZIP import remains open for Claude. |
| 2026-03-29 | Codex | Hitomi favorite cover fix | ✅ Done | Verified directly against `favorites.json` and `curl`: the saved Hitomi cover URL for `1852370` returned `404` both with and without headers because the persisted path was stale (`.../1774742402/...`). Then confirmed the current resolver path from live `galleries/1852370.js` + `gg.js` worked only with Hitomi headers: without `Referer/User-Agent` it returned `404`, with headers it returned `200 image/webp`. Implemented two-part fix in Favorites: `FavoritesScreen` now passes per-source image headers into `ContentCard.buildImage()`, and Hitomi favorite cards now refresh stale persisted cover URLs by resolving the latest cover from the source and caching it per content id. Verified with `fvm dart analyze` on touched files. |
| 2026-03-29 | Codex | Codex CLI chat reset guidance | ✅ Done | Verified local environment uses `codex-cli 0.118.0-alpha.2`. Checked local CLI help and official OpenAI Codex Help Center docs. Result: no explicit `clear chat` command surfaced in current CLI help; recommended workflow is to start a new session for a true context reset, while `clear`/`Ctrl+L` only clears terminal output. |
| 2026-03-29 | Codex | Nhentai API v2 endpoint migration + Hitomi release diagnostics | ✅ Done | Updated the active config-driven nhentai runtime only: bundled `nhentai-config.json` now points to list=`/api/v2/galleries?page={page}`, search=`/api/v2/search?...`, detail/comments=`/api/v2/galleries/{id}?include=comments`, related=`/api/v2/galleries/{id}/related`. Confirmed live JSON via `curl`: list/search now return compact items (`english_title`, `japanese_title`, relative `thumbnail`, `tag_ids`), while detail returns `title`, `cover`, `thumbnail`, `pages`, and embedded `comments`. Migrated nhentai image handling to a path-driven config model using `assetHosts` + selectors like `listThumbnailPath`, `detailCoverPath`, and `imagePaths`, so runtime no longer depends on the old template-based `coverUrlBuilder` / `imageUrlBuilder` for v2 assets. Added config-driven fallback language resolution from `tag_ids` (`6346=japanese`, `12227=english`, `29963=chinese`) so list cards no longer show `unknown` when compact payload omits named tags. Follow-up fix: normalized numeric `tag_ids` to strings before `languageTagMap` lookup, because v2 list/search returns integer IDs and the JSON config map is string-keyed; this removed the remaining false `unknown` language icons on compact cards. Follow-up fix: `GenericUrlBuilder.buildSearchUrl()` now removes empty query placeholders like `sort=` and `query=` from final URLs, because nhentai `v2` returns HTTP 400 for `/api/v2/search?...&sort=&page=1` but accepts the same request when the empty parameter is omitted. Follow-up fix: `GenericRestAdapter.search()` now propagates `SearchFilter.sort` into REST URLs using config-driven `searchConfig.sortingConfig.options`, and `nhentai-config.json` now maps `newest` to `apiValue: "date"` so default searches use `sort=date` while UI changes to `popular` / `popular-week` / `popular-today` correctly update the request URL. Added targeted builder and REST adapter regression tests. Follow-up instrumentation for Hitomi release triage: added targeted `logger` diagnostics in the special `HitomiAdapter`, Hitomi download-header path in `GenericHttpSource`, and Hitomi AVIF->WEBP reader fallback in `ExtendedImageReaderWidget`, so release `logcat` now shows query normalization, nozomi/gallery/gg.js requests, image-host resolution, generated reader URLs, and download headers without changing source behavior. Verified `fvm dart analyze` clean and `fvm flutter test packages/kuron_special/test/hitomi/hitomi_adapter_test.dart` passed. Kept legacy `kuron_nhentai` / `NhentaiApiClient` helpers untouched because nhentai runtime is now fully config-driven. |
| 2026-03-28 | Antigravity | KomikTap chapter download fix | ✅ Done | Two bugs: (1) `getChapterImages` fallback in `DownloadBloc._onStart()` was not passing `sourceId`, causing the wrong active source to be used to fetch chapter images. Fixed by passing `sourceId: updatedDownload.sourceId`. (2) `networkHeaders` was only extracted from `network.headers` in JSON config, but KomikTap is a **bundled source** with no config file — its Referer/UA headers are defined in `KomiktapSource.getImageDownloadHeaders()`. Added Priority-2 fallback: if config headers are empty, call `source.getImageDownloadHeaders()` via `ContentSourceRegistry`. This covers KomikTap and any future bundled source with custom image headers. Different from Hitomi (config JSON headers). |
| 2026-03-28 | Antigravity | Hitomi.la image download fix (missing HTTP headers) | ✅ Done | Root cause: DownloadWorker.kt built OkHttp requests with NO headers, causing Hitomi CDN to return 403 (requires `Referer: https://hitomi.la/`). HentaiNexus worked because its image URLs have no CDN restriction. Fix: (1) `DownloadWorker.kt` — added `KEY_HEADERS` constant + `parseHeaders()` + apply headers to every OkHttp request builder; (2) `NativeDownloadManager.kt` — added `headers` param to `queueDownload()`; (3) `DownloadHandler.kt` — reads `headers` from Flutter method call, passes to NativeDownloadManager; (4) `NativeDownloadService.dart` — added `headers` param to `startDownload()`; (5) `DownloadContentParams` — added `headers` field with `copyWith`/factory support; (6) `DownloadBloc._onStart()` — reads `network.headers` from `RemoteConfigService.getRawConfig(sourceId)` and injects as headers param. `flutter analyze` clean. |
| 2026-03-28 | Copilot | Settings source management polish (uninstall + ZIP batch + metadata) | ✅ Done | Restored uninstall action for all non-bundled sources in Settings, added backward-compatible ZIP import (single-source manifest, legacy manifest, and global `installableSources`), enabled multi-select + batch install from ZIP manifest, added install failure diagnostics with per-source reason, normalized legacy `network.rateLimit` schema in `RemoteConfigService` (`requestsPerSecond` -> `requestsPerMinute` + `minDelayMs`) to fix E-Hentai/HentaiNexus/Hitomi install failures, and persisted/read manifest metadata (`meta.description`) so installed source list shows proper descriptions instead of only source IDs. |
| 2026-03-28 | Copilot | Manual-only source mode migration | ✅ Done | Migrated source installation to manual-only Link/ZIP mode: disabled automatic remote manifest download in `RemoteConfigService.smartInitialize`, restored installed custom sources from local cache (`AppDocDir/configs`) instead of CDN manifest, removed manifest/CDN install APIs (`ensureManifestLoaded`, `downloadAndApplySourceConfigFromManifest`) and cleaned `_cdnBase`/`_manifestUrl` constants, removed CDN installable source list from Settings (kept only Add via Link + Import ZIP), analyzer clean, and native package tests passed (11). |
| 2026-03-28 | Copilot | Settings Available Sources hardening (Link/ZIP) | ✅ Done | Implemented secure custom source import in `settings_screen`: URL now requires manifest with checksum validation, ZIP now requires `manifest.json` + config file checksum verification, added install preview/confirm dialog (sourceId/version/displayName/integrity), migrated new UI texts to EN/ID/ZH localization, regenerated l10n, and validated analyzer clean + native package tests (11 passed). |
| 2026-03-28 | Copilot | Favorites export/import UX + storage path alignment | ✅ Done | Fixed FavoritesScreen export/import flow: added Import menu action, corrected stuck loading dialog by using non-blocking dialog calls, made export use `StorageSettings` custom root path, ensured favorites-only JSON export (`favorites.json`), added staged export progress (DB read → JSON encode → file write), and resolved analyzer lints (`unawaited`, `const`). |
| 2026-03-23 | Copilot | Phase 6 execution: E-Hentai + HentaiNexus + Hitomi fallback | 🚧 In Progress | Implemented special factories/adapters wiring, added `ehentai`/`hentainexus`/`hitomi` installable configs + manifest entries, registered resolver factories, added HentaiNexus decryptor baseline tests (2 passed), fixed short-payload decrypt bug, `flutter analyze` clean. |
| 2026-03-16 | Copilot | MangaDex search filter parity fix (include/exclude + raw URL) | ✅ Done | Fixed DynamicForm tag serialization order so picker UUID values are preserved, introduced combined include/exclude tri-state picker, persisted selected tags into SearchFilter summary state, removed empty template params (e.g. `title=`) in raw URL merge, updated default list ordering to latestUploadedChapter, added MangaDex integration regression test for included/excluded tags + mode params, and documented manifest-version cache invalidation requirement to prevent stale runtime source config. |
| 2026-03-17 | Codex | Codex repo alignment | ✅ Done | Added Codex compatibility guidance to `AGENTS.md`, created `.codex/README.md`, installed project-scoped skills under `.codex/skills/`, and registered Codex in `project_memory.md` so local skills/rules remain the single source of truth. |
| 2026-03-15 | Copilot | MangaDex author/artist tag navigation hardcode removal | ✅ Done | Replaced source-specific branch in generic REST detail parser with config-driven `api.detail.tagRelations`, updated MangaDex config mapping, added content-by-tag display label routing for human-readable AppBar while preserving UUID-based `authorOrArtist` search behavior. |
| 2026-03-15 | Copilot | Cross-source search UI and config design pack | ✅ Done | Created analysis package with per-provider search UI designs and draft `searchFormV2` configs for nhentai, mangadex, komiktap, crotpedia, and hentaifox under `projects/analysis-plan/cross_source_search_ui_config_design/`, validated with Explore subagent audit and Context7 MangaDex docs. |
| 2026-03-14 | Copilot | Reader chapter navigation language+direction fix | ✅ Done | Fixed end-of-chapter next/prev fallback to use chapter list context, scoped chapter selector in reader settings to active language, and corrected semantic direction (next: 35→36, prev: 36→35) with descending-list inference. |
| 2026-03-14 | Copilot | KomikTap app-main cleanup | ✅ Done | Removed app-main `kuron_komiktap` dependency/imports, dropped legacy DI registrations, and replaced KomikTap fallback content URL building with config-driven `SourceUrlResolver`. |
| 2026-03-14 | Copilot | Standalone app-config externalization audit | ✅ Done | Created new analysis in `projects/analysis-plan/app_config_externalization_audit/` focused only on provider hardcode in `lib/` and `packages/`, with migration classification toward `app/config`. |
| 2026-03-14 | Copilot | MangaDex personal feed request triage | ✅ Logged | Confirmed `titles/feed` maps to authenticated `GET /user/follows/manga/feed`, verified personal-client requirements from official docs, and created backlog issue `projects/issues/2026-03-14-mangadex_personal_feed.md` for later implementation. |
| 2026-03-14 | Copilot | MangaDex Phase 5 closure: runtime blockers + search form | ✅ Done | Added MangaDex `searchForm` (Swagger-aligned), enabled `raw:` dynamic-form support in GenericRestAdapter, enforced app language whitelist (`id/en/ja/zh`), fixed oneshot blank chapter label, and verified tests (integration + mapper + config). |
| 2026-03-13 | Antigravity | multi_provider Phase 5: MangaDex & HentaiFox | ✅ Done | Added full reader support, offset pagination, and custom thumbnail extraction to generic adapters |
| 2026-03-14 | Copilot | MangaDex Phase 5 core fix: cover/title/stats/reader | ✅ Done | Fixed `coverBuilder` key handling, added MangaDex statistics follows→favorites enrichment, updated config to v1.1.0, improved chapter/status mapping, and added integration tests (3 passed). |
| 2026-03-14 | Copilot | HentaiFox reader fix: prefer full-res webp & fallback images | ✅ Done | Reader now falls back to chapter-images when detail lacks image URLs; adapter prefers metadata-driven full-res webp (using `#load_dir`/`#load_id`) and keeps conservative fallbacks. Unit tests updated/ran — 13 passed. |
| 2026-03-07 | Copilot | Phase 3 Cleanup: Assets Reorganization & CDN Staging | ✅ Done | komiktap deleted from assets/configs, assets/app structure created, RemoteConfigService updated |
| 2026-03-07 | Copilot | Source Switch Shimmer Bug Fix (Phase 3 Stabilization) | ✅ Done | SourceCubit registerFactory→registerLazySingleton + context.read |
| 2026-03-07 | Copilot | multi_provider Phase 3B: Dynamic Search Form | ✅ Done | SearchFormConfig + DynamicFormSearchUI + raw param search |
| 2026-03-04 | Copilot | multi_provider Phase 3: Unified Schema Refactor | ✅ Done | GenericContentMapper + zero-hardcode architecture |
| 2026-03-03 | Copilot | multi_provider Phase 3: kuron_generic upgrades + KomikTap wiring | ✅ Done | — |
| 2026-03-02 | Copilot | nhentai Tag Display Fix (`detail_screen` + `generic_rest_adapter`) | ✅ Done | — |
| 2026-03-01 | Copilot | nhentai_test Bug Fixes: Search Filters + Comment Avatar | ✅ Done | [→](projects/sessions/2026-03-01-copilot-nhentai-bugfixes.md) |
| 2026-03-01 | OpenCode | Phase 2 Bug Fixes: Cover URL & Pagination | ✅ Done | [→](projects/sessions/2026-03-01-opencode-cover-pagination.md) |
| 2026-03-01 | OpenCode | multi_provider_integration Phase 2 Wiring | ✅ Done | [→](projects/sessions/2026-03-01-opencode-phase2-wiring.md) |
| 2026-03-01 | OpenCode | multi_provider_integration Phase 0 + 0B + 1 | ✅ Done | [→](projects/sessions/2026-03-01-opencode-phase0-phase1.md) |
| 2026-03-01 | OpenCode | Phase 2 AntiDetection Integration | ✅ Done | [→](projects/sessions/2026-03-01-opencode-antidetection.md) |
| 2026-03-01 | Antigravity | Project Memory & Tooling Setup | ✅ Done | — |

---

## 🛡 Protected Files (NEVER edit directly)
- `*.g.dart` — Generated by `build_runner`
- `*.freezed.dart` — Generated by Freezed
- `pubspec.lock` — Auto-generated

> Edit the source file and run: `flutter pub run build_runner build --delete-conflicting-outputs`

---

## � Latest Session — Phase 6 Complete (2026-03-28)

### multi_provider_integration Status: **100% COMPLETE** ✅

✅ **Phase 6: Special Adapters Delivery (E-Hentai, HentaiNexus, Hitomi) — ALL TESTED & MIGRATED**

All 3 providers fully wired, registered, and smoke tested:
- **E-Hentai**: Full support → Search→Detail→Reader validated ✅
- **HentaiNexus**: Full support → Search→Detail→Reader validated ✅
- **Hitomi**: Fallback support → Search→Detail→Reader validated ✅
- **Test Coverage**: 8 EHentai + 2 HentaiNexus tests passing ✅

**Project Status**: Version 0.9.14+23 | Moved to `success-plan/` | Production-Ready

---

## 🆕 Latest Session — 2026-03-31

### Build Bump +23: Release Prep & Docs Sync ✅

**Version**: `0.9.14+22` → `0.9.14+23`

**Files Updated** (6 total):
1. `pubspec.yaml` → version bumped
2. `CHANGELOG.md` → new `[0.9.14+23] - 2026-03-31` section added with 8 commits (reader enhancements, offline fixes, ZIP handler migration)
3. `README.md` → download link updated to `v0.9.14+23` with `%2B` encoding
4. `README_ID.md` → download link updated to `v0.9.14+23` with `%2B` encoding
5. `docs/en/FAQ.md` → latest release updated from `v0.9.13+21` to `v0.9.14+23`
6. `docs/id/FAQ.md` → "Rilis terbaru" updated from `v0.9.13+21` to `v0.9.14+23`

**Git Release**:
- Annotated tag: `v0.9.14+23`
- Remote commit hash: `78b4294`
- Pushed & verified on origin ✅

**Included Changes**:
- ✨ Reader: Image height caching, floating page indicator
- 🐛 Offline: Prevent duplicate externally-imported items
- 🐛 ZIP: Calculate & persist `fileSize` on import
- 🐛 Metadata: Auto-generate `metadata.json` for manual offline imports
- ♻️ Migration: ZIP handler moved from `MainActivity` to `kuron_native` plugin
- ♻️ Refactor: `ImportZipUseCase` readability improvements
- 📝 Docs: Comprehensive ZIP Import feature guide added

**Production Ready** ✅

## �📦 Key Commands

```bash
# Build & Run
flutter clean && flutter pub get
flutter run --debug
./build_optimized.sh debug|release

# Test & Analyze
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs

# Search (Modern)
rg "pattern" lib/ -t dart                  # Fast text search
ugrep -rn "pattern" lib/                   # Interactive search
semgrep --lang dart -e '$X.find()' lib/    # AST-aware search

# Project Management
dart scripts/project_status.dart           # Update dashboards
./scripts/smart_search.sh audit            # Architecture audit
./scripts/smart_search.sh debugprint       # Find print violations
```

---

## 🆕 Latest Session — 2026-03-30

### QoL Enhancements Analysis (Issue #32) — API v2 Verified

- Terhubung ke GitHub repo via `rtk gh issue list/view`, membaca Issue #32 (@viaans)
- Membaca **live nhentai API v2 docs** (`https://nhentai.net/api/v2/docs`) — hasil jauh lebih kaya dari asumsi awal
- Membuat & memperbarui `projects/analysis-plan/qol_enhancements/qol_enhancements_2026-03-30.md`

**Key API v2 findings & Final QoL Plan (Issue #32):**
- **P0 (Config)**: Update `nhentai-config.json` (Tambah flags: auth, blacklist, random, comments).
- **P1 (Login & Sync)**: REST Auth (Token-based) + PoW/Captcha bypass via Mini WebView + **Favorit Sync (Online ↔ Local)**.
- **P2 (Gesture)**: UI-only fix, `drawerEdgeDragWidth` 25% + HapticFeedback.
- **P3 (Settings)**: Hub Settings Terpusat + UI Input **Local Blacklist**.
- **P4 (History/Search)**: Native Tag Explorer (Live API v2) menggantikan JSON lokal statis.
- **P5 (Blacklist)**: NSFW Blur/Censor kover galeri (Hybrid: Local + Online API).
- **P6 (Interactive)**: Tombol **Random Gallery (Gacha)** + Fitur **Submit Comments**.

Status: **Analysis Phase (CLEAN & COMPLETE)** — Dokumen: `projects/analysis-plan/qol_enhancements/qol_enhancements_2026-03-30.md`.
Siap dieksekusi ke `onprogress-plan/` pada sesi berikutnya.

---

## 🆕 Latest Session — 2026-04-19

### Release Prep v0.9.17+26 ✅

- Release metadata updated:
  - bumped `pubspec.yaml` version from `0.9.16+25` to `0.9.17+26`
  - added a new `CHANGELOG.md` release section covering nhentai comment posting, recent-apps privacy, and animated-WebP / E-Hentai download fixes
- Documentation sync completed before tagging:
  - updated `README.md` and `README_ID.md` release badge, download link, and feature bullets
  - updated `docs/en/FAQ.md` and `docs/id/FAQ.md` with the new latest-release link plus entries for nhentai comment posting and recent-apps privacy blur behavior
- Release verification completed:
  - `fvm flutter analyze`
  - `fvm flutter test`
  - updated stale widget/service tests so the default suite passes again
  - changed `test/phase6/phase6_live_smoke_test.dart` to be opt-in via `ENABLE_PHASE6_LIVE_SMOKE=true` and to read configs from `assets/configs/` first
- Source-control caveat:
  - GitHub tag creation is still pending because a tag created before committing these changes would point at the previous commit instead of this release candidate

---

### Blur Recent Apps Privacy Execution ✅

- Execution package created:
  - `projects/onprogress-plan/blur_recent_apps_privacy/blur_recent_apps_privacy_2026-04-19.md`
  - `projects/onprogress-plan/blur_recent_apps_privacy/progress.md`
- Implemented app-side privacy obfuscation:
  - added `AppPrivacyOverlayService` to own a lightweight UI-only obscured state
  - added `AppPrivacyOverlayGate` at `MaterialApp.builder` so the routed UI can be blurred and scrimmed before Android captures the recent-apps snapshot
  - updated `LifecycleWatcher` to toggle the overlay on `inactive` / `paused` and clear it on `resumed`
- Added native stability fallback:
  - updated `MainActivity` to apply Android 13+ recent-apps privacy fallback during `onCreate` / `onResume`
  - added `privacy_recent_background.xml` and wired `NormalTheme` window background so the native fallback has a deliberate privacy-safe preview
  - retained the Flutter blur path for lower Android versions and as best-effort UI obfuscation while the app is transitioning
- Download safety:
  - kept the existing `DownloadLifecycleMixin` background scheduling path untouched
  - no native worker/download code was changed, so ongoing downloads continue to hand off to WorkManager as before when the app goes to background
- Verification completed:
  - `fvm flutter test test/services/app_privacy_overlay_service_test.dart test/widget/presentation/widgets/app_privacy_overlay_gate_test.dart`
  - `fvm flutter analyze lib/services/app_privacy_overlay_service.dart lib/presentation/widgets/app_privacy_overlay_gate.dart lib/core/di/service_locator.dart lib/presentation/widgets/lifecycle_watcher.dart lib/main.dart test/services/app_privacy_overlay_service_test.dart test/widget/presentation/widgets/app_privacy_overlay_gate_test.dart`
  - `./gradlew app:compileDebugKotlin`
  - adb device verification on SDK 35 confirmed the recent-apps card is privacy-obscured after opening Recents and capturing a device screenshot
- Remaining manual validation:
  - verify an active download keeps progressing while the app sits in recent apps

---

### PIN + Biometric App Lock Analysis ✅

- Confirmed current foundation:
  - no existing PIN, fingerprint, biometric, or app-lock implementation exists in the repo
  - reusable hooks already exist in `SettingsScreen`, `PreferencesService`, `UserPreferences`, `LifecycleWatcher`, and `MaterialApp.builder`
  - Android host is not yet ready for `local_auth` because `MainActivity` still extends `FlutterActivity`, launch themes are not AppCompat-based, and `USE_BIOMETRIC` is missing from the manifest
- Analysis deliverables created:
  - `projects/analysis-plan/pin_biometric_app_lock/pin_biometric_app_lock_2026-04-19.md`
- Recommended MVP architecture:
  - store lock flags in `SharedPreferences` via `UserPreferences`
  - store only salted/hash PIN material in `FlutterSecureStorage`
  - keep app PIN flow in Flutter/Dart, but prefer exposing fingerprint/biometric prompt from `kuron_native` instead of adding `local_auth`
  - add an app-wide `AppLockCubit` plus fullscreen `AppLockGate` overlay at `MaterialApp.builder`
  - trigger re-lock from the existing lifecycle watcher when the app returns from background
  - trigger a lightweight privacy blur/scrim overlay on `inactive`/`paused` so recent-apps previews capture an obscured frame
- Proposed execution scope:
  - enable/disable app lock from Settings
  - set, confirm, change, and remove PIN
  - optional biometric unlock when supported
  - cold-start and resume lock coverage
  - lightweight privacy blur in recent apps without interrupting the existing background download flow
  - targeted service/cubit/widget tests
- Approval gate captured in the analysis:
  - relock timing recommended as immediate on resume
  - PIN format recommended as numeric-only, 6 digits
  - biometric remains optional and always keeps PIN as fallback

---

### Local Collection Categories + Reading Status Analysis ✅

- Reviewed current local favorites implementation:
  - local storage still uses a flat `favorites` table with no concept of user-defined collections
  - `FavoriteCubit` and `FavoritesScreen` still assume a single local favorites list
  - export/import also still use a single-array `favorites.json` schema
- Confirmed reading/bookmark status support already exists elsewhere:
  - `history` stores `last_page`, `total_pages`, `is_completed`, chapter metadata, and parent linkage
  - `reader_positions` stores current page and computed reading progress
- Product conclusion:
  - user-defined multiple local favorite collections are feasible
  - bookmark-style shelves such as `Reading` and `Completed` are also feasible, and should be modeled as smart shelves derived from history/progress instead of manual duplicated flags on favorites
- Added planning artifacts:
  - `projects/issues/2026-04-12-local-collection-categories-and-reading-status.md`
  - `projects/analysis-plan/local_collection_categories/local_collection_categories_2026-04-12.md`
- Expanded the issue note with explicit DB-migration semantics:
  - existing `favorites` remains the base saved-items registry
  - new `favorite_collections` and `favorite_collection_items` sit on top as user-defined grouping layers
  - reading status remains a separate smart-view concern
- Effort estimate captured in analysis:
  - manual collections only: 2–3 days
  - manual collections + smart shelves: 3–4 days
  - with export/import + polish: 4–6 days

---

## Previous Session — 2026-04-02

### Native CAPTCHA Migration + Online Favorites Stabilization ✅

- Migrated CAPTCHA flow from Flutter embedded WebView to native plugin path:
  - Added `showCaptchaWebView` to `packages/kuron_native/lib/kuron_native_platform_interface.dart`.
  - Added method-channel wiring in `packages/kuron_native/lib/kuron_native_method_channel.dart`.
  - Added public wrapper in `packages/kuron_native/lib/kuron_native.dart`.
- Implemented native Android CAPTCHA activity:
  - Added `packages/kuron_native/android/src/main/kotlin/id/nhasix/kuron_native/kuron_native/CaptchaWebViewActivity.kt`.
  - Added plugin handler + activity result mapping in `KuronNativePlugin.kt`.
  - Registered activity in `packages/kuron_native/android/src/main/AndroidManifest.xml`.
- Migrated app-side page:
  - `lib/presentation/pages/auth/captcha_solver_page.dart` now calls `KuronNative.instance.showCaptchaWebView(...)`.
- Fixed native activity issues found on device:
  - Corrected malformed HTML injection in Kotlin raw strings (removed escaped quotes causing broken resource URLs like `%22https:/...`).
  - Added system bar inset handling so toolbar back/reload no longer overlaps status bar/notch.
- Hardened online favorites UX:
  - Added retry with backoff for transient online-favorites network failures.
  - Mapped errors to localized, user-friendly messages to avoid raw DioException output.
  - Added online favorites search and improved thumbnail/asset host resolution from source config.

### Tag Blacklist (Offline + Online) Completion ✅

- Finished P5 delivery for QoL Enhancements:
  - Added persistent local `blacklistedTags` support in `PreferencesService` and `SettingsCubit`.
  - Added `TagBlacklistUtils` for normalized tag/name/id matching and multi-entry parsing.
  - Added `TagBlacklistService` to cache/sync online blacklist IDs from config-driven auth sources.
- Extended generic nhentai auth config/runtime:
  - Added blacklist endpoints + feature flag to `assets/configs/nhentai-config.json`.
  - Added config-driven blacklist fetch support in `ConfigDrivenApiAuthClient` and `SourceAuthService`.
- Upgraded UX:
  - Added modern blacklist manager UI to `SettingsScreen` with chip previews, sheet editor, and login shortcut.
  - Applied blurred/dimmed blacklist overlays on main cards, generic content cards, tag-browse lists, and offline library items.
- Added regression coverage:
  - Added `test/unit/core/utils/tag_blacklist_utils_test.dart` for parsing and matching rules.

---

## Previous Session — 2026-03-29

### Hitomi Release Diagnostics + Native Download Extension Fix

- Added targeted Hitomi diagnostics in release path:
  - `packages/kuron_special/lib/src/hitomi/hitomi_adapter.dart`
  - `packages/kuron_generic/lib/src/generic_http_source.dart`
  - `lib/presentation/widgets/extended_image_reader_widget.dart`
- Root cause found for inconsistent Hitomi download/offline behavior:
  - native downloader hardcoded every page filename to `.jpg`
  - native `getDownloadedFiles/count` only recognized `.jpg`
  - Dart offline helpers partially ignored `.avif`
- Additional root cause found from release logcat:
  - Hitomi detail cache persisted `gold-usergeneratedcontent.net` image URLs that later expired and returned `404`
  - `clear cache all` temporarily fixed downloads because it forced a fresh detail fetch
- Fixed native worker and offline readers:
  - `DownloadWorker.kt` now preserves extension from source URL (`.webp`, `.avif`, etc.)
  - metadata file list now stores real filenames instead of forced `.jpg`
  - added native request/response diagnostics for first-image download flow
  - `DownloadHandler.kt` now counts and lists `.jpg/.jpeg/.png/.gif/.webp/.avif/.bmp`
  - Dart offline helpers now recognize `.avif` in preload/storage/metadata validation
- Fixed repository cache behavior:
  - `ContentRepositoryImpl.getContentDetail()` now bypasses cached detail for Hitomi / `gold-usergeneratedcontent.net` image sets and refreshes from source
- Verification:
  - `fvm dart analyze ...` for touched Dart files passed with `No issues found!`
- Operational note:
  - previously downloaded Hitomi galleries that already contain wrongly named `.jpg` files may need re-download or manual cleanup to fully normalize old data.
