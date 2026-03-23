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
| **Version** | 0.9.12+20 |
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

### ✅ Completed (11)
- chapter_reading_history_navigation
- crotpedia_ui_modernization
- doujin_search_highlight
- favorites_bug_fix
- fix_app_drawer_transparency_on_list_screens
- komiktap_navigation_lists
- offline_search_highlight
- reader_header_auto_show
- smart-caching-and-fixes
- unity-ads-fix
- view_comments

### 🚧 In Progress (1)
- **multi_provider_integration** — 88% — Phase 0 ✅, Phase 0B ✅, Phase 1 ✅, Phase 2 ✅, Phase 3 ✅, Phase 4 ✅, Phase 5 ✅ (Phase 6 next)

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

## 📦 Key Commands

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
