# Search Tools

Modern search tools for Kuron codebase. **NEVER use basic `grep`**.

## Tool Overview

| Tool | Best For | Speed |
|------|----------|-------|
| `rg` (ripgrep) | Fast text search, regex | Fastest |
| `ugrep` | Interactive TUI, fuzzy search | Medium |
| `semgrep` | AST-aware patterns, security audit | Slow |

## Ripgrep (`rg`) — Primary Search

```bash
rg "pattern" lib/                           # Basic search
rg -i "pattern" lib/                        # Case-insensitive
rg -t dart "pattern"                        # Dart files only
rg -C 3 "pattern" lib/                      # With context lines
rg -l "pattern" lib/                        # File names only
rg "^class \w+" lib/ -t dart               # Class definitions
rg --glob '!**/*.g.dart' "pattern" lib/     # Exclude generated
```

### Kuron-Specific Searches
```bash
rg "(print|debugPrint)\(" lib/ -t dart      # Print violations
rg "extends BaseCubit" lib/ -t dart         # BaseCubit usage
rg "abstract class.*Repository" lib/domain/ # Repository interfaces
rg "(TODO|FIXME|HACK)" lib/ -t dart        # TODOs
rg "Text\(['\"]" lib/presentation/ -t dart  # Hardcoded strings
```

## UGrep — Interactive & Fuzzy

```bash
ugrep -Q "pattern" lib/           # Interactive TUI
ugrep -Z "patern" lib/ -t dart   # Fuzzy (finds typos)
ugrep --tree "pattern" lib/       # Tree view
```

## Semgrep — AST-Aware

```bash
semgrep --lang dart -e 'print($MSG)' lib/                    # Find prints
semgrep --lang dart -e 'http.get($URL)' lib/presentation/    # Direct API calls (violation)
semgrep --lang dart -e 'password = "$VAL"' lib/               # Hardcoded credentials
```

## Smart Search Script

```bash
./scripts/smart_search.sh text "pattern"        # ripgrep
./scripts/smart_search.sh ast '$X.find()'       # semgrep
./scripts/smart_search.sh interactive "pattern"  # ugrep TUI
./scripts/smart_search.sh audit                  # Architecture audit
./scripts/smart_search.sh violations             # Code standard check
```

## When to Use What

| Scenario | Tool |
|----------|------|
| Quick text search | `rg` |
| Find & replace preview | `rg -r` |
| Explore visually | `ugrep -Q` |
| Find typos | `ugrep -Z` |
| Code patterns | `semgrep` |
| Security audit | `semgrep` |

Note: In Claude Code, prefer using the built-in Grep tool (which uses ripgrep) for most searches.
