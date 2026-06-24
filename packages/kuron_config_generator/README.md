# Kuron Config Generator

Developer tooling for generating Kuron source configs — interactive wizard **and** URL-assisted discovery (HTML → CMS scraper, JSON → REST API).

## Status

**Phase 1 Complete** — Interactive wizard + HTTP discovery shipped ✅
- 27 tests passing, analyzer clean
- Sections 4-6 (browser, GitHub, validation) deferred per YAGNI

## Quick Start

| Goal | Command |
|------|---------|
| Interactive wizard | `fvm dart run ... generate --interactive` |
| HTML site probe | `fvm dart run ... generate --url https://site.com` |
| JSON API probe | `fvm dart run ... generate --url https://api.site.com/endpoint` |
| Validate output | `fvm dart run kuron_generic:kuron_config_validate build/generated/*.json` |
| Deploy | `cp build/generated/*.json informations/configs/` |

## Usage

Run from **project root**:

### Interactive Wizard (Manual)

```bash
fvm dart run packages/kuron_config_generator/bin/kuron_config_generator.dart \
    generate --interactive
```

Prompts: source identity, mode (REST / scraper), features, endpoints, headers.  
**Output:** `build/generated/{sourceId}-config.json`

### URL-Assisted HTML → Scraper

```bash
fvm dart run packages/kuron_config_generator/bin/kuron_config_generator.dart \
    generate --url https://manhwaread.com/
```

1. HTTP probe with browser User-Agent  
2. Detect CMS (Madara / WordPress / custom) from HTML signatures  
3. Inject candidate selectors into config (list, detail, chapters, reader)  
4. Detect Cloudflare → add `network.cloudflare.bypassRequired`  
5. Output scraper-mode Source Config v2

**Example probe output:**
```
✓ HTTP 200, 45231 bytes received (html)
📋 CMS detected: madara (100% confidence)
✓ Config generated: build/generated/manhwaread-config.json
💡 Review suggested selectors — adjust paths as needed.
```

### URL-Assisted JSON → REST API

```bash
fvm dart run packages/kuron_config_generator/bin/kuron_config_generator.dart \
    generate --url https://api.example.com/v1/manga
```

1. Detect `content-type: application/json` (or sniff `{` / `[`)  
2. Infer structure — direct array, `data[]`, `results[]`, or single detail object  
3. Detect pagination hints (`page`, `offset`, total count)  
4. Output rest_json-mode Source Config v2 with inferred endpoints

**Example probe output:**
```
✓ HTTP 200, 12304 bytes received (json)
📡 API mode detected — inferred structure:
  isList=true isDetail=false confidence=70%
✓ Config generated: build/generated/api.example.com-config.json
💡 This is a draft — review endpoints and pagination.
```

### Validate & Deploy

```bash
# Validate with runtime validator
fvm dart run kuron_generic:kuron_config_validate \
    build/generated/manhwaread-config.json

# Deploy to app configs
cp build/generated/manhwaread-config.json informations/configs/
```

> 💡 `build/` is gitignored. Generated output stays local until deployed.

## Architecture

```
kuron_config_generator/
├── bin/
│   └── kuron_config_generator.dart  # CLI entry point
├── lib/src/
│   ├── commands/                   # 3 CLI commands
│   │   ├── generate_command.dart   # Wizard + URL-assisted
│   │   ├── discover_command.dart   # URL discovery (stub)
│   │   └── validate_command.dart   # Validation workflow (stub)
│   ├── models/
│   │   └── wizard_question.dart    # Question models
│   ├── wizard/
│   │   ├── wizard_builder.dart     # Question flow
│   │   └── wizard_runner.dart      # Interactive runner
│   ├── discovery/
│   │   ├── http_probe.dart         # HTTP GET + content-type detect
│   │   ├── cms_detector.dart       # HTML → CMS detection
│   │   └── api_detector.dart       # JSON → API structure
│   └── generator/
│       └── config_generator.dart   # Answers → JSON
└── test/
    ├── commands_test.dart          # CLI tests (4)
    ├── wizard_test.dart            # Wizard flow (3)
    ├── cms_detector_test.dart      # CMS detection (6)
    ├── probe_discovery_test.dart   # Probe + API detection (10)
    └── integration_smoke_test.dart # End-to-end (3)
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

## Testing

```bash
cd packages/kuron_config_generator

# Run all 27 tests
fvm dart test

# Run specific suite
fvm dart test test/probe_discovery_test.dart
fvm dart test test/cms_detector_test.dart
fvm dart test test/wizard_test.dart
fvm dart test test/commands_test.dart
fvm dart test test/integration_smoke_test.dart
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

1. **Try interactive**: `generate --interactive` — manual wizard
2. **Try URL-assisted**: `generate --url https://site.com` — auto-detect
3. **Validate**: `kuron_config_validate build/generated/*.json`
4. **Deploy**: `cp build/generated/*.json informations/configs/`
5. **Test in app**: Import via Settings → Sources → Add Link

## Deferred Features

- Browser discovery — add if JS-rendered sites become common
- GitHub mining — add if bulk config creation from extensions needed
- Validation engine integration — add if `kuron_config_validate` CLI is too manual

Priority based on actual pain, not anticipated pain.

## See Also

- [Source Config Contract v2](../../docs/en/SOURCE_CONFIG_CONTRACT_V2.md)
- [Runtime Validator CLI](../kuron_generic/README.md#kuron_config_validate)
- [revamp-kuron-config-runtime](../../openspec/changes/revamp-kuron-config-runtime/)
