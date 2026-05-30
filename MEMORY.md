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

> Tracked via `openspec/` — Last updated: 2026-05-28

### ✅ Archived (in `openspec/changes/archive/`)
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
- `2026-03-xx-komiktap-navigation-lists`
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

### 🚧 Active Changes (in `openspec/changes/`)
- `tachiyomi-extensions-integration` — Phase 4 pending (deploy config ke kuron-config-providers)
- `revamp-kuron-config-runtime` — §1–11 implementation complete; deferred: §8.4 (header dedup), §8.6 (app tests), §10.4 (device tests), §10.6 (provider-repo configs). Ready to archive.

### 📋 Exploration / Analysis (in `openspec/changes/`)
- `pin-biometric-app-lock`

### 🐛 Open Issues (in `openspec/changes/`)
- *(none currently)*


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
- **Startup Context**: `MEMORY.md` -> active `openspec/changes/` (non-archived) -> `proposal.md` + `tasks.md`
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

> Session log tersimpan di tabel ini. Untuk detail perubahan kode, lihat `openspec/changes/archive/` yang relevan.

| Date | Tool | Topic | Status | Detail |
|---|---|---|---|---|
| 2026-05-30 | Copilot | revamp-kuron-config-runtime §4–11 implementation | ✅ Done | Completed all remaining tasks in `openspec/changes/revamp-kuron-config-runtime/tasks.md`. §4: CLI validator (`kuron_generic:kuron_config_validate` bin) + report writers (JSON/MD) + test harness. §5: `PageResolutionPipeline` with download-readiness checks (16/16 tests). §6: `SourcePluginRegistry` + 4 plugin interfaces in `kuron_generic` (11/11 tests). §7: `NativeDownloadPayload` v2 model in `kuron_native` with per-page headers, `startDownloadV2()` in app `NativeDownloadService`, `parsePerPagePayload()` in `DownloadWorker.kt` (10/10 Dart tests). §8: `RemoteConfigService` now runs static `SourceConfigParser` validation on every config load → `getValidationReport(sourceId)`; `DownloadContentUseCase` checks `PageResolutionPipeline.isDownloadReady` before native call; `ReaderCubit` logs pipeline diagnostics after fallback chapter fetch. §9: New docs in `docs/en/` — `SOURCE_CONFIG_CONTRACT_V2.md`, `PACKAGE_USAGE_EXAMPLES.md`, `EXAMPLE_CONFIGS.md`; updated `informations/documentation/source-config-templates/README.md`. §10: All package tests pass (kuron_core 27/27, kuron_native 28/28, kuron_generic pipeline+plugin+generator 33+/33+ new tests); CLI validator run against all `informations/configs/` producing JSON report. §11: `EnginePrimitive.all` + `PluginCapability.all` Maps exposed; `compatibilityStatusNames` + `featureStatusNames` const lists; generator round-trip fixture (6/6 tests). CLI fix: `main` → `async`, `IOSink.flush()/close()` replacing invalid `RandomAccessFile?` cast. |
| 2026-05-28 | Codex | Komikcast chapter-image fail-soft preservation | ✅ Done | Hardened `DownloadBloc` chapter-image fallback so resolved direct image URLs are preserved even if post-fetch metadata/state update throws (prevents false abort `No image URLs resolved` after successful extraction from Komikcast image host URLs such as `sv1.imgkc1.my.id`). Verified with `fvm flutter test test/presentation/blocs/download/download_bloc_test.dart`, `fvm flutter analyze lib/presentation/blocs/download/download_bloc.dart`, and `dart test test/integration/komikcast_rest_integration_test.dart` (in `packages/kuron_generic`). |
| 2026-05-28 | Codex | Komikcast chapter-id parity + false-complete download guard | ✅ Done | Fixed chapter download ID consistency so composite chapter IDs (contoh `slug/17`) stay intact for metadata/native queue/reader route even when detail lookup is normalized to parent slug. Updated detail-to-reader chapter launch to pass `chapter.id` as `Content.id` for offline path alignment. Added regression test in `download_bloc_test` to assert native completion cannot mark download as completed when zero valid image files exist. Verified: `fvm flutter test test/presentation/blocs/download/download_bloc_test.dart`, `fvm flutter analyze lib/presentation/blocs/download/download_bloc.dart lib/presentation/cubits/detail/detail_cubit.dart test/presentation/blocs/download/download_bloc_test.dart`, `dart test test/integration/komikcast_rest_integration_test.dart` + `dart test test/mappers/generic_content_mapper_test.dart` + `dart analyze lib/src/adapters/generic_rest_adapter.dart lib/src/mappers/generic_content_mapper.dart` (in `packages/kuron_generic`). |
| 2026-05-28 | Codex | Reader false chapter-classification guard (Komikcast slug) | ✅ Done | Fixed `ReaderCubit` false-positive chapter detection that treated dash-heavy non-Crotpedia slugs as Crotpedia chapter IDs (triggering `Chapter not available offline...` and blocking online fallback). Added source-aware classifier `ChapterIdClassifier` and updated reader loading/history fallback checks to use source hints (`preloadedContent/parent/state sourceId`) plus source-aware `GetContentDetailParams(..., sourceId: hint)` for online strategy. Added unit test `test/unit/core/utils/chapter_id_classifier_test.dart` to lock regression (Komikcast slug false, Crotpedia chapter true, numeric false). Verification: `dart analyze` touched files + `flutter test test/unit/core/utils/chapter_id_classifier_test.dart`. |
| 2026-05-28 | Codex | Komikcast chapter download fallback cast + detail-id normalization | ✅ Done | Fixed chapter-download failure from log `type '_Map<String, dynamic>' is not a subtype of type 'String?'` by hardening fallback URL generation in `DownloadBloc` + `SourceUrlResolver` for endpoint object schema (`detail.path`). Added composite detail-id normalization (`slug/17` -> `slug`) before `getContentDetail` to stop 404 requests to `/series/{slug}/{chapter}` during chapter download bootstrap. Added regression bloc test (`download_bloc_test`) to assert composite-id normalization and continued start flow when chapter images resolve, plus unit test (`source_url_resolver_test`) for endpoint object schema path/base-url priority. Verification: `dart analyze` (touched files), `flutter test test/unit/core/utils/source_url_resolver_test.dart`, `flutter test test/presentation/blocs/download/download_bloc_test.dart`. |
| 2026-05-28 | Codex | Komikcast REST schema hardening + proposal sync | ✅ Done | Updated `openspec/changes/fix-generic-rest-adapter-schema-support/proposal.md` with execution status and relation to `tachiyomi-extensions-integration`. Implemented/validated runtime fixes in `packages/kuron_generic`: endpoint object schema normalization (`_getEndpointPath`), base URL priority (`api.url/api.apiBase`), chapter-id composition (`contentId/chapterId`) for detail->reader flow, chapter-image placeholder support, and scalar-to-string chapter mapping in `GenericContentMapper`. Added integration regression test `test/integration/komikcast_rest_integration_test.dart` (search pagination, detail chapters, reader images). Follow-up hardening in app layer (`DownloadBloc`): preserve explicit source `Referer/Origin` headers (avoid dynamic override mismatch) and fail-fast when chapter image resolution returns empty before native download starts. Verification passed: targeted `dart analyze` + targeted `dart test` suites (`download_bloc_test`, `komikcast_rest_integration_test`); full package test still has unrelated pre-existing failures. Archived to `openspec/changes/archive/2026-05-28-fix-generic-rest-adapter-schema-support`. |
| 2026-05-24 | Codex | AVIF->WebP loading i18n polish + OpenSpec archive | ✅ Done | Updated reader loading copy during AVIF fallback conversion to a conversion-specific message (`processingBadAvifToWebp`) and added localization for ID/EN/ZH, then regenerated l10n and re-verified (`fvm flutter analyze` target + widget tests pass). Archived change `avif-to-webp-conversion` via `openspec archive -y`; OpenSpec auto-synced delta spec by creating `openspec/specs/avif-webp-converter/spec.md`. Manual device QA tasks 7.5/7.7/7.8 remain unchecked in archived `tasks.md` with explicit sub-checklist notes. |
| 2026-05-23 | Copilot | Remove AVIF->WebP conversion and switch reader fallback to external open | ✅ Done | Removed the remaining AVIF conversion/WebP fallback paths from `ExtendedImageReaderWidget` and `packages/kuron_native`. Reader failures for AVIF now fall back to external open only: local AVIF uses new native `openAvif(filePath)` via `FileProvider` so Android gallery/photo apps can handle it, while remote AVIF opens via existing native browser/WebView path. Deleted conversion-only Kotlin classes, removed Dart conversion APIs, added Android `FileProvider` wiring, kept native animated-image routing intact, and verified with focused error checks plus `packages/kuron_native` tests (11 passed). |
| 2026-05-24 | Copilot | Native AVIF animated converter (libavif+libwebp) + strict-scan spam fix | ✅ Done | Implemented native C++ AVIF pipeline in `kuron_native` using vendored `libavif` + `libwebp` with JNI bridge: decoder now iterates all AVIF frames and preserves frame timing into animated WebP via `WebPAnimEncoder` (with static fallback for single-frame cases). Added/updated native wiring in `CMakeLists.txt`, linked `libwebpmux`, enabled Android externalNativeBuild in plugin Gradle, and integrated Kotlin bridge call before bitmap fallback path. Also fixed OfflineContentManager strict-scan spam by adding miss-cache TTL, per-content log throttling, custom-root log throttling, and downloads-directory cache. Verified with `./android/gradlew -p android :app:assembleDebug` (BUILD SUCCESSFUL) and targeted Dart analyze clean. |
| 2026-05-23 | Copilot | Native AVIF decode fallback to local WebP (no Pub.dev dependency) | ✅ Done | Implemented a new Kuron Native method-channel path `convertAvifToWebpFallback` that converts failed AVIF files to WebP fallback using Android native decoder/encoder APIs only (no new Pub.dev package). Wired reader fallback in `ExtendedImageReaderWidget` for both local AVIF and cached network AVIF failures (one-shot attempt, loading guard, cache routing to native view). Added Kotlin helper `AvifWebpTranscoder.kt`, plugin handler in `KuronNativePlugin.kt`, and Dart API exposure in `kuron_native` platform interface/method channel/facade. Verified with focused `fvm dart analyze` and full Android `./gradlew :app:assembleDebug -x lint` (BUILD SUCCESSFUL). |
| 2026-05-23 | Copilot | manga18.club image loading investigation + reader WebView fallback | ✅ Done | Investigated why `view-source:` on manga18.club chapter pages doesn't show CDN image URLs. Traced full scraper flow: `GenericScraperAdapter.fetchChapterImages()` first tries `_extractScriptSlidesImageUrls()` which finds `slides_p_path = [...]` JS variable embedded in the raw server-rendered HTML — each item is a base64-encoded CDN URL decoded via `_decodeMaybeBase64Url()`. Images never appear in `view-source:` either because CF blocks the browser request (showing challenge page) or the base64 strings don't visually look like URLs until decoded. CSS selector `.chapter_boxImages img[src]` is only a final DOM fallback. Also added "Open in WebView" button to `_buildErrorWidget` in `extended_image_reader_widget.dart`: when any network image fails to load, a new `OutlinedButton` appears below Retry that calls `KuronNative.instance.openWebView(url: widget.imageUrl)` to open the image directly in the native Android WebView. Button hidden for local file paths and disabled during other repair actions. |
| 2026-05-23 | Codex | Manga18 AVIF reader decode fallback hardening | ✅ Done | Investigated repeated Android decode failures for cached Manga18 AVIF pages (`videoFrame is a nullptr`, `invalid input`) and confirmed the issue is decoder/runtime capability, not cache miss. Hardened native reader path in `AnimatedWebPView.kt`: added a runtime failed-decode key set, skip repeated animated decode attempts for known-bad assets, and render static bitmap fallback from local file/network bytes before retrying network. Also fixed Kotlin init-flow compile issue in the skip path, then verified with `./gradlew app:compileDebugKotlin` (success) and `fvm flutter test packages/kuron_native/test/animated_webp_view_test.dart` (all pass). |
| 2026-05-23 | Codex | E-Hentai part-mode metadata sync + detail chapter list | ✅ Done | Implemented `openspec/changes/ehentai-part-mode-metadata-sync`: E-Hentai detail now exposes virtual part chapters (`__ehpart__`) derived from gallery `?p=` pagination, reader/download flows navigate part-by-part instead of `Load more images`, and route parsing safely preserves malformed or percent-encoded internal IDs. Added shared chapter-scoped metadata reconciliation in `OfflineContentManager` so completed downloads and reader/manual repair remove stale `failed_pages` markers using the same serialized merge rules. Refactored detail tag-query + reader launch payload helpers, then fixed follow-up regressions where direct `Read now` launches lost E-Hentai part navigation context and chapter-row downloads still aggregated linked next parts instead of staying scoped to the selected part. Part-row downloads now persist the DB title as `<gallery title> - Part N`, while storage paths still derive from the safe hashed `contentId`. Final follow-up: enabled `features.chapters=true` in `ehentai-config.json` so detail pages render the part list instead of the old `Read Now` fallback when chapters are present. Verified with focused app/package `fvm flutter test`, targeted `fvm flutter analyze`, and `jq empty ehentai-config.json`. |
| 2026-05-19 | Codex | Generic scraper Unicode slug extraction fix | 🚧 In Progress | Refactored `GenericScraperAdapter._extractSlugFromUrl()` to use regex-first extraction, safe percent-decoding, and query-safe slug matching. Added regression coverage for Komiku `〜` URLs, encoded/mixed/malformed slugs, chapter navigation IDs, and search-to-detail navigation. Followed up by hardening `AppRouter` route-param decoding with `UriComponentUtils.safeDecode()` so GoRouter content IDs containing literal `%` or malformed percent sequences no longer crash with `Illegal percent encoding in URI`. Also hardened raw query decoding in `GenericScraperAdapter` and `EHentaiScraperAdapter`, normalized E-Hentai raw tag/uploader searches before delegation, and fixed E-Hentai query pagination to seed from live `?f_search=...` HTML then follow `dnext` / `next=` token URLs (without assuming `page=1` style pagination) so Unicode uploader pages continue loading across page 2+. Verification blocker remains: pre-existing `GenericScraperAdapter.search() — Crotpedia placeholder cleanup` test is still failing outside this change scope. |
| 2026-05-10 | Kiro | DoujinDesu v2 API discovery & config-driven integration | ✅ Done | User reported scraper from other repo failed. Initial analysis assumed SSR-only, but user provided actual API responses showing DoujinDesu v2 HAS REST API endpoints: `/api/manga-list` (paginated list), `/api/search` (search), `/api/manga/{slug}` (detail), `/api/read/{slug}/{chapter}` (chapter images). Created complete documentation and config-driven integration: (1) `doujindesuv2-config.json` - Config-driven format matching komiku-config.json pattern with JSON path selectors; (2) `doujindesuv2-api-reference.md` - Full API docs with Dart models and code examples; (3) `doujindesuv2-config-summary.md` - Quick reference guide; (4) `doujindesuv2-analysis.md` - Technical analysis; (5) `source-config-templates/data.md` - API response examples. Key findings: Hybrid Architecture (API + SSR), JSON API for all operations, no auth required, rate limit 30 req/min, similar to NHentai pattern. Config ready for integration with existing scraper architecture. |
| 2026-04-26 | Codex | E-Hentai range download numbering + metadata preservation | ✅ Done | Fixed the E-Hentai range-download path so selected ranges keep original gallery numbering all the way into native storage and final metadata. `DownloadContentUseCase` now passes `startPage`, `endPage`, and original `totalPages` into `NativeDownloadService`; `DownloadHandler`, `NativeDownloadManager`, and `DownloadWorker` preserve those values through WorkManager, write files using original page numbers like `page_009.webp`, and emit `metadata.json` with correct `is_range_download`, `start_page`, `end_page`, `total_pages`, and original-numbered `failed_pages`. `OfflineContentManager` now injects failed-page placeholders only inside the selected slice for range downloads. Added a focused unit test for the Dart/native contract and verified with targeted `fvm flutter test`, targeted `fvm flutter analyze`, and root Android `./gradlew app:compileDebugKotlin`. |
| 2026-04-26 | Codex | Restore reader failed-page placeholder repair actions | ✅ Done | Restored offline reader repair actions for metadata-driven `failed_pages` placeholders. `ReaderScreen` now treats `__failed__:` placeholders as repairable/manual-repairable when the embedded source URL is present, `ExtendedImageReaderWidget` shows both the WebView source-page fallback and redownload buttons on the skipped-page card, and `ReaderCubit` now resolves placeholder `/s/...` URLs through the normal source-config repair pipeline while deriving a writable local file path even before the missing page exists on disk. Added widget regression coverage for placeholder action visibility and verified with targeted `fvm flutter test test/widget/presentation/widgets/extended_image_reader_widget_test.dart` plus targeted `fvm flutter analyze`. |
| 2026-04-26 | Codex | E-Hentai uploader + namespace tag navigation fix | ✅ Done | Fixed the reported E-Hentai detail parsing issue for `https://e-hentai.org/g/3906586/971a6d4051/`. Fetched live HTML into `packages/kuron_special/test/fixtures/ehentai/detail_3906586_ai_generated.html`, then updated `EHentaiScraperAdapter` to inject uploader from `#gdn a` as a typed `uploader` tag and preserve E-Hentai namespaces such as `other`, `female`, and `male` instead of flattening them to generic `tag`. Updated `ehentai-config.json` detail tag selector to parse current `#taglist div[id^=td_] a` / `toggle_tagmenu(...)` namespace values. Added regression coverage for uploader, `other:ai generated`, female/male namespace tags, and raw quoted E-Hentai search syntax. Verified with targeted `fvm flutter test test/ehentai/ehentai_scraper_adapter_test.dart`, targeted `fvm flutter analyze`, and `jq empty ehentai-config.json`. |
| 2026-04-26 | Kiro | Failed page tracking + reader retry card | ✅ Done | Fixed missing pages after parallel download with skipped images. Native: `DownloadWorker.kt` sekarang track `failedPages` (1-based index + original URL) via `DownloadImagesResult` data class, tulis ke `metadata.json` sebagai `failed_pages: [{page, url}]` dengan `total_pages` tetap pakai jumlah asli. Dart: `OfflineContentManager.getOfflineImageUrls()` baca `failed_pages` dari metadata dan inject placeholder `__failed__:{originalUrl}` di posisi yang benar sehingga `pageCount` tetap 14 bukan 13. Reader: `ExtendedImageReaderWidget.build()` deteksi prefix `__failed__:` dan tampilkan `_buildFailedPagePlaceholderWidget` — card dengan icon, teks "Page X not downloaded", dan tombol "Redownload page". `ReaderCubit.repairBrokenImage()` handle placeholder dengan extract original URL dan pass sebagai `overrideTarget` ke `_repairBrokenImageInternal`. `isLocalReaderImagePath()` diupdate agar placeholder tidak dianggap local path. Verified: `fvm flutter analyze` clean + `./gradlew app:compileDebugKotlin` BUILD SUCCESSFUL. |
| 2026-04-26 | Kiro | Download/Reader offline bug fixes + parallel download | ✅ Done | Fixed 3 issues: (A) Reader masuk offline mode saat download sedang berlangsung — `isContentAvailableOffline()` sekarang skip filesystem scan jika DB state adalah `downloading`/`queued`/`paused`, sehingga partial files tidak memicu offline mode. (B) Reader masih offline setelah file download dihapus — tambah `invalidateCacheFor(contentId)` di `OfflineContentManager` dan panggil dari `DownloadBloc._onRemove()` + `_onBulkDelete()` agar `_pathCache`/`_imageUrlsCache` tidak stale. (C) Download paralel per-image — refactor `DownloadWorker.kt` dari sequential `forEachIndexed` ke `coroutineScope + async/awaitAll` dengan `Semaphore` (default 3 parallel) dan `withTimeoutOrNull` per-image (default 60s), image yang timeout di-skip dan dilanjutkan ke berikutnya. Config `maxParallelImages` dan `imageTimeoutMs` dapat di-pass dari Dart via `NativeDownloadService.startDownload()`. Verified: `fvm flutter analyze` clean + `./gradlew app:compileDebugKotlin` BUILD SUCCESSFUL. |
| 2026-04-20 | Codex | Offline screen safe-thumbnail wiring fix | ✅ Done | Traced a follow-up report that offline covers were still animating and confirmed the earlier thumbnail safeguard had not actually been wired into the real offline entry points. `OfflineContentBody` was still building `ContentCard` without `preferStaticCover: true`, and the long-press action-sheet header still bypassed the safe path via direct `Image.network` / `Image.memory(File(...).readAsBytesSync())`. Updated both the grid cards and action-sheet preview to route through `ProgressiveThumbnailWidget` / `ProgressiveImageWidget` with safe-thumbnail mode enabled, so heavy or animated local offline covers now degrade to placeholders instead of animating or triggering expensive preview work. Verified with targeted `fvm flutter analyze` and `fvm flutter test` (`offline_content_body_test`, `progressive_image_widget_test`). |
| 2026-04-20 | Codex | Offline heavy animated cover freeze guard | ✅ Done | Added a defensive offline-library cover path after the previous animated-WebP playback optimization surfaced a new freeze in the offline grid: when an offline thumbnail falls back to a heavy local animated page image instead of a dedicated `cover/thumbnail/thumb` asset, `ProgressiveImageWidget` now skips static-preview generation entirely and shows a lightweight animated placeholder badge instead. Dedicated heavy cover assets still render normally. Verified with targeted `fvm flutter analyze` and `fvm flutter test` (`progressive_image_widget_test`, `offline_content_body_test`). |
| 2026-04-20 | Codex | Offline large animated WebP playback optimization | ✅ Done | Optimized the offline reader path for very large animated WebP pages (10 MB+) after reproducing the “downloaded but still janky” symptom. `AnimatedWebPView` now skips the extra thumbnail-preparation pass when a large local file is already the visible autoplaying page, native thumbnail generation now decodes directly from the local file instead of first copying it into a giant `ByteArray`, `AnimatedWebPView.kt` now decodes local playback directly from `ImageDecoder.createSource(file)` rather than `readBytes()`, and `ExtendedImageReaderWidget` now applies a smaller native target width for ultra-heavy animated files. Verified with targeted `fvm dart format`, `fvm flutter analyze`, `fvm flutter test` (`extended_image_reader_widget_test`, `animated_webp_view_test`), and successful root `./gradlew app:compileDebugKotlin`. |
| 2026-04-20 | Codex | Offline library cover/reader/source-version polish | ✅ Done | Polished three user-facing offline/source-management behaviors: offline library cards and action-sheet previews now prefer dedicated cover assets and render local GIF/WebP/AVIF covers through a static first-frame preview path, opening a chapter from the offline library now forces the reader to start from page 1 instead of restoring a stale saved position, and installed source versions are now surfaced in both Settings and the drawer source-selector bottom sheet as `sourceId • v{version}` when available. Verified with targeted `fvm flutter analyze` and `fvm flutter test` (`source_config_display_utils_test`, `offline_content_body_test`). |
| 2026-04-20 | Codex | Android release build unblock for integration_test registrant | ✅ Done | Fixed a release-only Android compilation failure where `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` still referenced `dev.flutter.plugins.integration_test.IntegrationTestPlugin`, but the dev-only package was absent from the release classpath. Added a release-source-set no-op shim at `android/app/src/release/java/dev/flutter/plugins/integration_test/IntegrationTestPlugin.java`, kept debug/integration-test behavior untouched, and verified with `./gradlew app:compileReleaseJavaWithJavac`, full `./gradlew app:assembleRelease`, and targeted analyze. |
| 2026-04-20 | Codex | E-Hentai WebView direct-image repair save | ✅ Done | Closed the gap in the previous WebView-assisted repair fallback: native `showLoginWebView` now returns `currentUrl` plus a DOM-derived `resolvedImageUrl` using selector/attribute rules passed from Flutter, and `ReaderScreen` forwards the installed E-Hentai config rules into that WebView launch. `ReaderCubit.retryRepairAfterManualSession()` can now use the live image URL from the WebView session to overwrite only the broken local page directly instead of merely syncing cookies and retrying the old HTML resolve path. Verified with targeted analyze, app/package Flutter tests, and successful native `./gradlew app:compileDebugKotlin`. |
| 2026-04-20 | Codex | E-Hentai config-driven image selector resolution | ✅ Done | Refactored the E-Hentai reader-page resolver so it no longer hardcodes `#img`. `reader_image_repair_utils.dart` now reads `scraper.selectors.detail.imageUrls` from the installed source config, resolves selector/attribute rules with safe fallbacks, and both `ReaderCubit` repair flow plus `ExtendedImageReaderWidget` lazy `/s/...` resolution now use that same config-driven helper. `ReaderScreen` passes raw source config into the widget, `ReaderCubit` now receives `RemoteConfigService`, and focused analyze/test coverage now includes a non-default selector regression case. |
| 2026-04-20 | Codex | E-Hentai WebView-assisted page repair fallback | ✅ Done | Added a reader-side fallback for broken local E-Hentai pages when direct repair is not enough. `ReaderCubit` can now resolve the exact source `/s/...` page for the failing image, prepare current E-Hentai cookies for a native WebView handoff, and re-sync cookies/user-agent from that WebView session before retrying repair for only the affected page. `ReaderScreen` wires this into the offline image error card, and `ExtendedImageReaderWidget` now shows a new "Open source page" action alongside redownload/retry so users can refresh the source page session without leaving the app. Verified with targeted `fvm flutter analyze`, `fvm flutter test`, and regenerated l10n strings. |
| 2026-04-20 | Codex | Offline decode guard + native payload validation | ✅ Done | Hardened the E-Hentai/offline-image stability work by adding two more defenses. On the native side, `DownloadWorker.kt` now downloads into a temp file, validates that the payload is a real supported image before moving it into the chapter folder, retries alternate header attempts when a `200` response is actually invalid content, and refuses to treat previously corrupted files as completed pages during resume. On the reader side, `ExtendedImageReaderWidget` now preflights local file headers, bypasses repeated decode attempts after a local page has already failed once, and routes the user straight back to the existing repair UI instead of repeatedly triggering `FlutterImageDecoderImplDefault` errors on rebuild. Added focused utility/widget assertions and re-verified with targeted analyze, test, and native Kotlin compile. |
| 2026-04-20 | Codex | Reader corrupt-image repair + E-Hentai API research | ✅ Done | Added in-reader recovery for broken offline pages: `ExtendedImageReaderWidget` now exposes a repair action on local-file failures, `ReaderScreen` routes the action through `ReaderCubit`, and the cubit re-fetches only the requested page, validates that the response is an actual image with HTTP 200, then atomically replaces just that file on disk and refreshes the reader state. For E-Hentai, the repair flow reuses the existing `/s/...` reader-page strategy by resolving page links back to tokenized image URLs on demand instead of requiring a full API migration. Added `reader_image_repair_utils.dart`, localized repair strings, and focused utility tests; verified with targeted `fvm flutter analyze`, `fvm flutter gen-l10n`, and focused `fvm flutter test`. |
| 2026-04-20 | Codex | E-Hentai download + reader stability fix | ✅ Done | Implemented the stability fix package under `projects/onprogress-plan/ehentai_download_reader_stability/`. Hardened reader route payload handling by introducing shared reader-extra serialization/parsing so `imageMetadata`, `chapterData`, `allChapters`, and `currentChapter` survive `List<dynamic>` / map-based rebuilds without crashing. Added a monotonic progress guard in `DownloadBloc`, updated native `DownloadWorker.kt` to resume via existing page files across normalized extensions (`.jpg` -> `.png/.webp`) and to report progress from completed-page count instead of raw loop index, and disabled the legacy partial-resume background worker fallback that could conflict with native WorkManager downloads. Verified with focused `fvm flutter test`, targeted `fvm flutter analyze`, and successful `./gradlew app:compileDebugKotlin` in `packages/kuron_native/example/android`. |
| 2026-04-20 | Codex | E-Hentai download retry + reader route-cast analysis | ✅ Done | Investigated a user report that E-Hentai downloads jump from page 4 back to page 1 and that opening recent apps during reading triggers a reader error. Confirmed the provided Flutter log is not primary OOM evidence; the immediate reader crash comes from an unsafe `List<ImageMetadata>` cast in `AppRouter` when `state.extra['imageMetadata']` arrives as `List<dynamic>`. Native download analysis found two retry/resume regressions in `DownloadWorker.kt`: any single-page failure returns `Result.retry()` for the whole job, and E-Hentai pages that were normalized from `.jpg` to `.png/.webp` are not recognized as already downloaded on retry, so progress can appear to restart and pages may be downloaded again. Also noted `LifecycleWatcher` still schedules the legacy Flutter background worker on app pause even though downloads already run through native WorkManager, which risks conflicting resume behavior. |
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
| 2026-04-03 | Copilot | Release prep v0.9.15+24 — changelog, docs, README | ✅ Done | Bumped version 0.9.14+23 → 0.9.15+24. Wrote full `[0.9.15+24]` CHANGELOG entry covering: nhentai login + native CAPTCHA solver, online favorites (2-tab, add/remove/check, offline/online/both), tag blacklist (local settings manager + nhentai online sync + blur overlays + picker fix), random gallery, gesture navigation, centralized settings, native explorer, ZIP import. Added premium-source callout (E-Hentai/HentaiNexus/Hitomi require manual install via Link/ZIP). Updated docs/en/FAQ.md + docs/id/FAQ.md with new Q&A sections: nhentai login, online favorites, tag blacklist, other sources premium req. Updated README.md + README_ID.md: version badge v0.9.15, download link +24, new login/sync features block, premium source warning. Updated MEMORY.md. |
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
| 2026-03-17 | Codex | Codex repo alignment | ✅ Done | Added Codex compatibility guidance to `AGENTS.md`, created `.codex/README.md`, installed project-scoped skills under `.codex/skills/`, and registered Codex in `MEMORY.md` so local skills/rules remain the single source of truth. |
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
- Release finalization:
  - prepared a dedicated follow-up release-memory commit so the final annotated tag can point to a clean `0.9.17+26` snapshot instead of an older commit
  - target release tag: `v0.9.17+26`

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

---

## Current Session — 2026-05-10

### Tachiyomi Extensions Integration ✅

Implemented 6 Tachiyomi extensions as config-driven sources:

**Sources Added:**
- DoujinDesu (scraper, Indonesian doujin)
- DoujinDesu v2 (scraper, Indonesian doujin)
- Komiku (scraper, Indonesian manga)
- MangaFire (API, English manga)
- Uncensored Manhwa (scraper, English manhwa)
- Hentai Cosplay (API, English image sets)

**Implementation:**
- Created 6 config files in `assets/configs/`:
  - `doujindesu-config.json` (3.8 KB)
  - `doujindesuv2-config.json` (3.8 KB)
  - `komiku-config.json` (3.7 KB)
  - `mangafire-config.json` (2.8 KB)
  - `uncensoredmanhwa-config.json` (3.8 KB)
  - `hentaicosplay-config.json` (2.3 KB)

- Updated `lib/core/config/remote_config_service.dart`:
  - Added 6 sources to `_bundledAssetPaths` map
  - Added 6 sources to `_bundledSourceIds` set
  - Sources auto-load via `smartInitialize()` on app startup

- Configs follow existing patterns:
  - Scraper mode: CSS selectors for HTML parsing (4 sources)
  - API mode: JSON endpoints with pagination (2 sources)
  - Both support search, detail, chapters, and image extraction

**Architecture:**
- Leverages existing `GenericHttpSource` infrastructure
- No custom Dart code needed per source
- Config-driven approach enables easy updates when sites change
- All sources bundled in APK via `assets/configs/` in pubspec.yaml

**Project Tracking:**
- Created `projects/onprogress-plan/tachiyomi_extensions_integration/`
- Progress: Phase 1-2 complete, Phase 3-4 pending
- Next: Build APK to verify bundling, run integration tests

**Files Modified:**
- `lib/core/config/remote_config_service.dart` (added 6 sources to bundled registry)

**Files Created:**
- `assets/configs/doujindesu-config.json`
- `assets/configs/doujindesuv2-config.json`
- `assets/configs/komiku-config.json`
- `assets/configs/mangafire-config.json`
- `assets/configs/uncensoredmanhwa-config.json`
- `assets/configs/hentaicosplay-config.json`
- `projects/onprogress-plan/tachiyomi_extensions_integration/progress.md`
- `projects/onprogress-plan/tachiyomi_extensions_integration/tachiyomi_extensions_integration_2026-05-10.md`

---

## Current Session — 2026-05-10

### Tachiyomi Extensions Integration (External Config-Driven)

Implemented 6 Tachiyomi extensions as **external config-driven sources** (NOT bundled):

**Sources Added:**
- DoujinDesu (scraper, Indonesian doujin) - doujindesu.fun
- DoujinDesu v2 (scraper, Indonesian doujin) - v2.doujindesu.fun
- Komiku (scraper, Indonesian manga) - komiku.id
- MangaFire (API, English manga) - mangafire.to
- Uncensored Manhwa (scraper, English manhwa) - uncensoredmanhwa.com
- Hentai Cosplay (API, English cosplay) - hentaicosplay.com

**Implementation:**
- Created 6 config files (ready to deploy):
  - `/tmp/doujindesu-config.json`
  - `/tmp/doujindesuv2-config.json`
  - `/tmp/komiku-config.json`
  - `/tmp/mangafire-config.json`
  - `/tmp/uncensoredmanhwa-config.json`
  - `/tmp/hentaicosplay-config.json`

- **NO code changes** in app — RemoteConfigService already supports external config loading
- **Reverted** earlier changes that bundled configs (incorrect approach)
- Follows same pattern as komiktap, crotpedia, mangadex (external kuron-config-providers)

**Deployment Required:**
1. Copy 6 config files to `kurun-config-providers/config/`
2. Update `manifest.json` with 6 new entries
3. Commit & push to repo

**Project Tracking:**
- `projects/onprogress-plan/tachiyomi_extensions_integration/`
- Config creation ✅, App integration ✅, Deployment pending

---

## Current Session — 2026-05-10

### Komiku Source Integration Bug Fixes ✅

Fixed multiple issues with Komiku source integration:

**Issue 1: Search results showing "untitled" + missing `post_type=manga` parameter**
- Root cause: `_searchRaw()` in `generic_scraper_adapter.dart` was overwriting template query params (like `post_type=manga`) with empty raw params (like `post_type=`)
- Fix: Modified merge logic to only add non-empty raw params, preserving template defaults
- File: `packages/kuron_generic/lib/src/adapters/generic_scraper_adapter.dart` lines 258-277

**Issue 2: Detail page empty in release build but works in debug**
- Root cause: Dio `CookieManagerSaveException` caused by invalid cookie date header from komiku.org (`Expires: Sun` without full date)
- HTTP 200 response succeeded, but Dio crashed when trying to save malformed cookie
- Fix: Added cookie exception handler in `HttpClientManager` interceptor to ignore malformed Set-Cookie headers and continue with response
- File: `lib/core/network/http_client_manager.dart` lines 75-113
- Error message: `CookieManagerSaveException: HttpException: Invalid cookie date Sun`

**Issue 3: HTMX pagination not detected**
- Root cause: `_hasEnabledLink()` only checked `href` attribute, but Komiku uses `hx-get` attribute on span elements for infinite scroll
- Fix: Modified method to also check `hx-get` attribute
- File: `packages/kuron_generic/lib/src/adapters/generic_scraper_adapter.dart` lines 1538-1549

**Config Updates:**
- Bumped version from `1.0.0` to `1.0.1` in `komiku-config.json`
- Added `"inherits": "home"` to `homePage` pattern for proper pagination support

**Files Modified:**
- `komiku-config.json` (version bump + pagination fix)
- `packages/kuron_generic/lib/src/adapters/generic_scraper_adapter.dart` (search params + HTMX pagination)
- `lib/core/network/http_client_manager.dart` (cookie exception handler)

**Verification:**
- Debug mode: ✅ Working
- Release mode: ✅ Fixed after cookie exception handler
- Search: ✅ Titles display correctly with `post_type=manga`
- Pagination: ✅ HTMX infinite scroll detected
- Detail page: ✅ No longer crashes on malformed cookies

---


---

## 🔄 Latest Session Update (2026-05-10)

### DoujinDesu v2 API Discovery & Unit Tests ✅

**Status**: Complete

**What was done**:
1. **API Discovery & Documentation**
   - User reported scraper from another repo failed for DoujinDesu v2
   - Initial analysis assumed SSR-only, but user provided actual API responses
   - Discovered 4 working REST API endpoints:
     - `/api/manga-list?limit={limit}&page={page}&q={query}` - Paginated list with search
     - `/api/search?q={query}` - Search endpoint
     - `/api/manga/{slug}` - Manga detail with chapters & recommendations
     - `/api/read/{slug}/{chapter}` - Chapter images (75+ images per chapter)

2. **Config-Driven Integration**
   - Created `doujindesuv2-config.json` following existing format (komiku-config.json pattern)
   - Uses JSON path selectors (`$.data[*]`, `$.pagination.totalItems`, etc.)
   - API mode enabled (not scraper mode)
   - Pagination support with page-based navigation
   - All 4 endpoints configured with proper parameter placeholders

3. **Documentation Created**
   - `doujindesuv2-api-reference.md` - Complete API docs with Dart models
   - `doujindesuv2-config-summary.md` - Quick reference guide
   - `doujindesuv2-analysis.md` - Technical analysis
   - `source-config-templates/data.md` - Real API response examples

4. **Unit Tests (39 tests, 100% pass rate)**
   - **Config Validation Tests** (`doujindesuv2_config_test.dart`)
     - 10 tests covering: required fields, UI config, network headers, API endpoints, JSON path selectors, pagination settings, JSON serialization, parameter placeholders, HTTPS validation, API mode enabled
     - All tests passed ✅
   
   - **API Response Parsing Tests** (`doujindesuv2_models_test.dart`)
     - 13 tests covering: manga-list parsing, last_chapter parsing, search response, detail response, chapters parsing, recommendations parsing, chapter read response, empty tags, null last_chapter, empty chapters, multiple chapters, multiple images, content types
     - All tests passed ✅
   
   - **API Integration Tests** (`doujindesuv2_api_integration_test.dart`)
     - 16 tests covering: endpoint URL building, search/detail/read URLs, special character handling, URL encoding, response parsing, pagination, missing fields, content URL patterns, content types, empty/multiple chapters, recommendations
     - All tests passed ✅

**Key Findings**:
- Hybrid Architecture: API + SSR support
- No authentication required
- Rate limit: 30 requests/minute (recommended)
- Similar pattern to NHentai API integration
- Config ready for integration with existing scraper architecture

**Files Created**:
- `test/unit/data/datasources/remote/doujindesuv2_config_test.dart`
- `test/unit/data/models/doujindesuv2_models_test.dart`
- `test/unit/data/datasources/remote/doujindesuv2_api_integration_test.dart`

**Verification**:
```bash
fvm flutter test test/unit/data/datasources/remote/doujindesuv2_config_test.dart
fvm flutter test test/unit/data/models/doujindesuv2_models_test.dart
fvm flutter test test/unit/data/datasources/remote/doujindesuv2_api_integration_test.dart
# All: 00:02 +39: All tests passed!
```

**Next Steps**:
- Implement DoujinDesu v2 data source layer using config-driven approach
- Create repository implementation
- Wire into source provider system
- Add to available sources list in UI


---

## 🆕 Latest Session — 2026-05-10

### DoujinDesu v2 Tag Search Bug Fix ✅

**Status**: Complete

**Bug Fixed**: Tag click from detail screen was going to `/api/search?q=...` instead of `/api/manga-list?genre=...`

**Root Causes & Fixes**:

1. **Config Update** (`doujindesuv2-config.json`):
   - Removed `configUrl` to prevent remote GitHub override
   - Added `tagSearch` endpoint: `/api/manga-list?genre={tagId}&page={page}`
   - Added `navigation.tagQueryMapping` for tag click → `raw:genre=...` mapping
   - Version bumped to 1.0.1

2. **Adapter Fix** (`generic_rest_adapter.dart`):
   - **Old schema path** (line ~163): Added support for multiple tag parameter names (`tag_id`, `genre`, `category`, `tag`)
   - **New schema path** (line ~650): Added SAME tag search logic to `_searchNewSchema()` method (was missing!)
   - Priority order: `tag_id` (nhentai) → `genre` (doujindesu) → `category` → `tag`

**How It Works Now**:
1. User clicks tag "Business Suit" in detail screen
2. Query becomes: `raw:genre=Business+Suit` ✅
3. Adapter detects `genre` parameter in raw params ✅
4. Uses `tagSearch` endpoint: `/api/manga-list?genre=Business+Suit&page=1` ✅

**Files Modified**:
- `packages/kuron_generic/lib/src/adapters/generic_rest_adapter.dart` (both old + new schema paths)
- `informations/documentation/doujindesuv2-config.json` (tagSearch endpoint + navigation mapping)

**Verification**:
- ✅ flutter analyze clean
- ✅ Tag click now goes to correct genre-filtered endpoint
- ✅ Images extraction fixed (removed `replaceAll('[*]', '')` that broke JSONPath)

**Also Fixed Earlier - Image Extraction**:
- Root cause: `extractList()` selector was stripping `[*]` from JSONPath
- Fix: Keep `[*]` so individual URLs are extracted, not array as string
- File: `generic_rest_adapter.dart` line 476

## 🆕 Latest Session — 2026-05-19

### KomikTap Chapter Debug + Generic Scraper Hardening ✅

**Status**: In Progress / Root cause narrowed

**Findings**:

1. **Generic scraper chapter parsing works on current KomikTap HTML**
   - Saved live fixture `you-wont-break-me` detail page parses **37 chapters**
   - Selector path `#chapterlist li` + `.chbox .eph-num a` is valid against current site

2. **Confirmed bug in `generic_scraper_adapter.dart`**
   - `fetchDetail()` was reading `reader.images` directly from the **detail page**
   - For chapter-based sources like KomikTap, this incorrectly treated unrelated `<img>` tags
     (cover/avatar/etc.) as page images
   - Fix: only extract detail-page reader images when **no chapters** were found

3. **Confirmed cache serialization bug in `ContentModel`**
   - `ContentModel.fromEntity()` and `toEntity()` were dropping `chapters`
   - Fix: preserve `chapters` during entity <-> cache model conversion

4. **Added repository-side stale cache bypass**
   - `ContentRepositoryImpl.getContentDetail()` now bypasses cached detail when:
     - source feature `chapters == true`, and
     - cached content still has `chapters == null`
   - This heals old SharedPreferences/detail cache entries created before the cache model fix

**Files Modified**:
- `packages/kuron_generic/lib/src/adapters/generic_scraper_adapter.dart`
- `packages/kuron_generic/test/adapters/generic_scraper_adapter_test.dart`
- `packages/kuron_generic/test/fixtures/komiktap/you-wont-break-me-detail.html`
- `lib/data/models/content_model.dart`
- `lib/data/repositories/content_repository_impl.dart`
- `test/unit/data/models/content_model_test.dart`
- `test/unit/data/repositories/content_repository_impl_test.dart`

**Verification**:
- ✅ `fvm dart test` targeted adapter tests in `packages/kuron_generic`
- ✅ Live KomikTap fixture test proves adapter extracts 37 chapters
- ✅ `fvm flutter test test/unit/data/models/content_model_test.dart`
- ✅ `fvm flutter test test/unit/data/repositories/content_repository_impl_test.dart`
- ✅ `fvm flutter analyze lib/data/models/content_model.dart test/unit/data/models/content_model_test.dart`
- ✅ `fvm flutter analyze lib/data/repositories/content_repository_impl.dart test/unit/data/repositories/content_repository_impl_test.dart`

## 🆕 Latest Session — 2026-05-24

### Native AVIF Animated Converter + Offline Strict-Scan Spam Fix ✅

**Status**: Done

**Done**:
1. **Native AVIF animated converter (no pub.dev dependency)**
  - Added JNI native bridge and C++ converter path using vendored `libavif` + `libwebp`.
  - AVIF decode now iterates all frames via `avifDecoderNextImage()` and keeps frame timing from `avifImageTiming`.
  - Animated output now uses `WebPAnimEncoder` + `libwebpmux` linking; single-frame fallback still encodes static WebP.
  - Kotlin fallback flow remains: try NDK bridge first, then existing Android bitmap-based fallback if needed.

2. **Native build wiring**
  - Enabled Android `externalNativeBuild`/CMake in `packages/kuron_native/android/build.gradle`.
  - Added native bridge files and CMake wiring in `packages/kuron_native/android/src/main/cpp/`.
  - Vendored dependencies into `packages/kuron_native/android/src/main/cpp/third_party/`.
  - Linked missing animated symbols by adding `libwebpmux` in CMake.

3. **Offline strict-scan spam fix**
  - Added negative miss-cache TTL for `getOfflineContentPath()` misses.
  - Added throttled warning log per content ID for repeated strict-scan misses.
  - Added downloads directory cache + throttled custom-root logging to reduce repetitive logs and I/O.

4. **Verification**
  - `./android/gradlew -p android :app:assembleDebug` -> **BUILD SUCCESSFUL**.
  - `fvm dart analyze` targeted files -> **No issues found**.

**Files touched (highlights)**:
- `lib/core/utils/offline_content_manager.dart`
- `packages/kuron_native/android/build.gradle`
- `packages/kuron_native/android/src/main/cpp/CMakeLists.txt`
- `packages/kuron_native/android/src/main/cpp/kuron_avif_jni.cpp`
- `packages/kuron_native/android/src/main/kotlin/id/nhasix/kuron_native/kuron_native/LibavifNdkBridge.kt`
- `packages/kuron_native/android/src/main/kotlin/id/nhasix/kuron_native/kuron_native/AvifWebpTranscoder.kt`

**Notes**:
- Third-party warnings from vendored `libavif` were isolated/suppressed at target level where needed.
- Runtime path now supports animated conversion output, not only first-frame fallback.

## 🆕 Latest Session — 2026-05-28

### Komikcast Chapter Download False-Complete Guard + Reader Offline Path Stabilization ✅

**Status**: Done (hotfix validated)

**Root cause confirmed**:
1. Native terminal `FAILED` event was emitted through the same marker shape as `COMPLETED`, then interpreted by `DownloadBloc` as completed.
2. Native worker returned `Result.success` even when valid downloaded images were zero (and reported `downloadedCount` as total input URLs).
3. Download completion handler in Flutter did not validate actual saved image files before setting DB state to `completed`.

**Fix implemented**:
- `DownloadManager` now differentiates terminal markers:
  - `COMPLETED` => marker `-1/-1`
  - `FAILED` => marker `-1/-2`
- `DownloadBloc` now handles native failed marker via dedicated event `DownloadNativeFailedEvent`, routed to existing failure/retry logic.
- `DownloadWorker` now:
  - reports actual `downloadedCount` from saved files,
  - returns `Result.failure` when zero valid images are produced.
- `DownloadBloc._onCompleted` now validates filesystem image count when path hint exists; zero files immediately flips to failure path (not completed).

**Verification**:
- ✅ `fvm flutter test test/presentation/blocs/download/download_bloc_test.dart`
- ✅ `fvm flutter test test/unit/core/utils/source_url_resolver_test.dart test/unit/core/utils/chapter_id_classifier_test.dart`
- ✅ `./gradlew app:compileDebugKotlin` (from `packages/kuron_native/example/android`)
- ✅ Manual URL probe for Komikcast image CDN sample (`sv1.imgkc1`) returns HTTP 200 (with/without referer), so failure was pipeline/status logic, not hotlink blocking.

**Files touched**:
- `lib/services/download_manager.dart`
- `lib/presentation/blocs/download/download_bloc.dart`
- `lib/presentation/blocs/download/download_event.dart`
- `packages/kuron_native/android/src/main/kotlin/.../download/DownloadWorker.kt`
- `test/presentation/blocs/download/download_bloc_test.dart`

**Impact**:
- Prevents “download status successful but image empty” false positives.
- Reader no longer sees completed chapter entries that have zero offline pages.
