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
| **Version** | 0.9.14+22 |
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

> Synced from `projects/README.md` — Last updated: 2026-03-07

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

### 🚧 In Progress (0)
- *(None)*

### 📋 Analysis Phase (5)
- app_audit_hardcode_ui_desktop
- download_metadata_revamp
- flutter-desktop-migration
- komiktap_navigation_lists
- reader-ads

### 🔮 Future/Backlog (1)
- nhentai_search_revamp

### 🐛 Open Issues (2)
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

**Project Status**: Version 0.9.14+22 | Moved to `success-plan/` | Production-Ready

---

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

## Latest Session — 2026-03-29

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
