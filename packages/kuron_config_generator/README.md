# Kuron Config Generator

Developer tooling for generating Kuron source configs through interactive guided questions.

## Status

**Phase 1 Complete (Option A)** - Interactive wizard shipped ✅
- Sections 1-3 complete (15/56 tasks)
- Sections 4-10 deferred (HTTP discovery, browser, GitHub, validation integration)

## What This Does

Generates valid Source Config v2 JSON files through an interactive CLI wizard. No manual JSON writing required.

## Prerequisites

- Flutter/Dart environment (FVM recommended)
- Depends on: `kuron_core`, `kuron_generic` packages

## Installation

Already installed as part of Kuron monorepo at:
```
packages/kuron_config_generator/
```

## Usage

Run from **project root**:

```bash
# 1. Generate
fvm dart run packages/kuron_config_generator/bin/kuron_config_generator.dart generate --interactive

# 2. Validate
fvm dart run kuron_generic:kuron_config_validate build/generated/<source>-config.json

# 3. Deploy
cp build/generated/<source>-config.json informations/configs/
```
- Source identity (ID, name, version, home URL)
- Content type (manga, doujin, novel, etc.)
- Mode (REST API vs HTML scraper)
- Features (search, chapters, comments)
- API endpoints (for REST mode)
- Scraper selectors (for scraper mode)
- Headers (Referer, User-Agent if needed)

**Output:** `build/generated/{sourceId}-config.json`

### Example Session

```
=== Kuron Config Generator - Interactive Mode ===

--- Identity ---
  Source ID (e.g., "mangadex", "nhentai"):
  > example_source
  Display name:
  > Example Source
  Config version: (default: 1.0.0)
  > 
  Home URL (e.g., https://example.com):
  > https://example.com
  Content type: [manga/doujin/novel/anime/other] (default: manga)
  > manga

--- Features ---
  Source mode: [rest_json/scraper] (default: rest_json)
  > rest_json
  Supports search? [y/n] (default: y)
  > y
  ...
```

### Validating Generated Configs

Generated configs can be validated using the runtime validator:

```bash
# From project root
fvm dart run kuron_generic:kuron_config_validate \
  packages/kuron_config_generator/build/generated/example_source-config.json
```

## Architecture

```
kuron_config_generator/
├── bin/
│   └── kuron_config_generator.dart    # CLI entry point
├── lib/
│   └── src/
│       ├── commands/                   # CLI commands
│       │   ├── generate_command.dart   # Interactive wizard
│       │   ├── discover_command.dart   # URL discovery (stub)
│       │   └── validate_command.dart   # Validation workflow (stub)
│       ├── models/
│       │   └── wizard_question.dart    # Question models
│       ├── wizard/
│       │   ├── wizard_builder.dart     # Question flow
│       │   └── wizard_runner.dart      # Interactive runner
│       └── generator/
│           └── config_generator.dart   # Answers → JSON
└── test/
    ├── commands_test.dart              # CLI tests
    └── wizard_test.dart                # Wizard flow tests
```

## Generated Config Structure

Produces Source Config Contract v2 compliant JSON:

```json
{
  "source": "example_source",
  "displayName": "Example Source",
  "schemaVersion": "2.0",
  "version": "1.0.0",
  "homeUrl": "https://example.com",
  "features": {
    "home": {"supported": true},
    "search": {"supported": true},
    "detail": {"supported": true},
    "reader": {"supported": true},
    "download": {"supported": true}
  },
  "requiredPrimitives": [
    "imageMode.directUrl",
    "pagination.page",
    "auth.none"
  ],
  "api": {
    "type": "rest_json",
    "url": "https://api.example.com",
    "listEndpoint": "/list",
    "detailEndpoint": "/detail/{id}"
  }
}
```

## Deferred Features

Following Ponytail ultra / YAGNI principles, these features are deferred:

- **Section 4: HTTP Discovery** (7 tasks) - URL-assisted generation via HTTP probing
- **Section 5: Browser Discovery** (6 tasks) - Browser automation for JS-rendered sites
- **Section 6: GitHub Mining** (5 tasks) - Extract from Tachiyomi extensions
- **Section 8: Validation Engine** (5 tasks) - Integrated validation workflow
- **Additional artifacts** - Evidence reports, fixtures, Markdown summaries

**Rationale:**
- Interactive wizard works and produces valid configs ✓
- Manual input proven viable (15 configs exist)
- Discovery features add heavy dependencies (browser automation, GitHub API)
- Can be added later if manual input proves too slow

## Testing

```bash
cd packages/kuron_config_generator

# Run all tests
fvm dart test

# Run specific test suite
fvm dart test test/wizard_test.dart
fvm dart test test/commands_test.dart
```

## Development

```bash
# Install dependencies
fvm dart pub get

# Run analyzer
fvm dart analyze

# Format code
fvm dart format .
```

## Next Steps

1. **Try it**: Run `generate --interactive` to create a config
2. **Validate**: Use `kuron_config_validate` to check output
3. **Test in app**: Copy generated config to `informations/configs/`
4. **Import**: Use app's source import flow to load the config

## Future Enhancements

If manual input proves too slow for bulk config creation:
- Add HTTP discovery (Section 4) for URL-assisted generation
- Add browser probing (Section 5) for JS-rendered sites
- Add validation integration (Section 8) for immediate feedback

Priority based on actual pain, not anticipated pain.

## See Also

- [Source Config Contract v2](../../docs/en/SOURCE_CONFIG_CONTRACT_V2.md)
- [Runtime Validator CLI](../kuron_generic/README.md#kuron_config_validate)
- [revamp-kuron-config-runtime](../../openspec/changes/revamp-kuron-config-runtime/)
