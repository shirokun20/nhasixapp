---
name: search-tools
description: Panduan penggunaan search tools modern (ripgrep, ugrep, semgrep) untuk Kuron app — pengganti grep tradisional
license: MIT
compatibility: opencode, antigravity
metadata:
  audience: developers
  tools: [ripgrep, ugrep, semgrep]
---

# 🔍 Search Tools Skill

Panduan penggunaan search tools modern untuk Kuron app. Tools ini menggantikan `grep` tradisional dengan performa dan fitur yang jauh lebih baik.

## Tool Overview

| Tool | Best For | Speed | AST-Aware |
|---|---|---|---|
| **`rg`** (ripgrep) | Pencarian teks cepat, regex | ⚡⚡⚡ | ❌ |
| **`ugrep`** | Interactive search, fuzzy, hex | ⚡⚡ | ❌ |
| **`semgrep`** | Pattern matching, security audit | ⚡ | ✅ |

---

## 1. Ripgrep (`rg`) — Pencarian Teks Utama

Pengganti utama `grep`. Otomatis skip `.gitignore`, binary files, dan `build/` folders.

### Common Commands

```bash
# Cari text di lib/
rg "pattern" lib/

# Case-insensitive
rg -i "pattern" lib/

# Cari hanya di file Dart
rg -t dart "pattern"

# Cari dengan context lines (3 baris sebelum/sesudah)
rg -C 3 "pattern" lib/

# Cari file yang MENGANDUNG pattern (hanya nama file)
rg -l "pattern" lib/

# Cari file yang TIDAK mengandung pattern
rg --files-without-match "pattern" lib/

# Regex: cari method calls
rg "\.find\(\)" lib/

# Cari dan replace (dry-run)
rg "oldPattern" lib/ -r "newPattern"

# Cari hanya class definitions
rg "^class \w+" lib/ -t dart

# Count matches per file
rg -c "import" lib/ -t dart | sort -t: -k2 -rn | head -20

# Cari TODO/FIXME
rg "(TODO|FIXME|HACK|XXX)" lib/ -t dart

# Exclude directories
rg "pattern" lib/ --glob '!**/generated/**' --glob '!**/*.g.dart'

# Cari multi-line (dot matches newline)
rg -U "class.*\{.*dispose" lib/ -t dart
```

### Kuron-Specific Searches

```bash
# Cari semua print/debugPrint (violations)
rg "(^|\s)(print|debugPrint)\(" lib/ -t dart

# Cari semua BaseCubit usage
rg "extends BaseCubit" lib/ -t dart

# Cari semua repository interfaces
rg "abstract class.*Repository" lib/domain/ -t dart

# Cari unused imports
rg "import '.*'" lib/ -t dart --stats

# Cari hardcoded strings (potential l10n issues)
rg "Text\(['\"]" lib/presentation/ -t dart

# Cari TODO/FIXME
rg "(TODO|FIXME|HACK|XXX)" lib/ -t dart
```

---

## 2. UGrep (`ugrep`) — Interactive & Fuzzy Search

Lebih versatile dari ripgrep dengan mode interactive dan fuzzy matching.

### Common Commands

```bash
# Interactive TUI search
ugrep -Q "pattern" lib/

# Fuzzy search (approximate matching)
ugrep -Z "patern" lib/ -t dart    # matches "pattern" even if typo

# Search with file tree view
ugrep --tree "pattern" lib/

# Column number output
ugrep -ckn "pattern" lib/ -t dart

# Hex dump search (binary files)
ugrep -X "pattern" assets/

# Search with boolean operators
ugrep "import%dart:io" lib/ -t dart    # AND operator

# JSON output
ugrep --json "pattern" lib/

# Search in archives/compressed files
ugrep -z "pattern" *.tar.gz

# Multi-threaded search with stats
ugrep --stats "pattern" lib/
```

### Kuron-Specific Searches

```bash
# Interactive hunt for debugPrint violations
ugrep -Q "debugPrint" lib/

# Fuzzy search for misspelled class names
ugrep -Z "UserRepostiory" lib/ -t dart

# Tree view of all Cubit files
ugrep --tree "extends Cubit" lib/ -t dart
```

---

## 3. Semgrep — AST-Aware Pattern Matching

Understands code structure. Ideal untuk security audits dan refactoring patterns.

### Common Commands

```bash
# Cari pattern di Dart files
semgrep --lang dart -e '$X.find()' lib/

# Cari function calls dengan specific args
semgrep --lang dart -e 'print($MSG)' lib/

# Cari assignment patterns
semgrep --lang dart -e '$X = Get.find<$T>()' lib/

# Cari class definitions extending specific class
semgrep --lang dart -e 'class $NAME extends GetxController { ... }' lib/

# Cari try-catch tanpa proper error handling
semgrep --lang dart -e 'try { ... } catch($E) { }' lib/

# Cari unused variables (potential)
semgrep --lang dart -e 'final $X = $Y;' lib/ --include '*.dart'

# Multiple rules dari config
semgrep --config auto lib/

# Output JSON untuk processing
semgrep --lang dart -e '$PATTERN' lib/ --json
```

### Kuron Code Quality Audit

```bash
# Cari hardcoded credentials
semgrep --lang dart -e 'password = "$VAL"' lib/
semgrep --lang dart -e 'apiKey = "$VAL"' lib/

# Cari unhandled async
semgrep --lang dart -e '$X.then(($Y) { ... })' lib/

# Cari direct API calls in presentation layer (violation)
semgrep --lang dart -e 'http.get($URL)' lib/presentation/
semgrep --lang dart -e 'http.post($URL)' lib/presentation/
```

---

## 4. Smart Search Script

Gunakan script wrapper untuk memilih tool otomatis:

```bash
# Text search (uses ripgrep)
./scripts/smart_search.sh text "pattern"

# Text search hanya di lib/
./scripts/smart_search.sh text "pattern" lib/

# AST-aware search (uses semgrep) 
./scripts/smart_search.sh ast '$X.find()'

# Interactive search (uses ugrep)
./scripts/smart_search.sh interactive "pattern"

# Architecture audit (predefined rules)
./scripts/smart_search.sh audit
```

---

## 5. When to Use What

| Scenario | Tool | Why |
|---|---|---|
| Quick text search | `rg` | Fastest, respects .gitignore |
| Find & replace preview | `rg -r` | Shows replacement preview |
| Explore codebase visually | `ugrep -Q` | Interactive TUI |
| Find typos/fuzzy match | `ugrep -Z` | Fuzzy matching |
| Find code patterns | `semgrep` | Understands syntax tree |
| Security audit | `semgrep` | Pattern-based vulnerability scan |
| Count/stats | `rg -c` or `ugrep --stats` | Both work well |
| Search generated files | `ugrep` | Doesn't skip by default |
| Multi-file refactoring | `rg` + `sed` | Fast pipeline |

---

## 6. Pro Tips

```bash
# Combine rg with fzf for interactive file selection
rg -l "pattern" lib/ | fzf --preview 'rg --color=always "pattern" {}'

# Pipeline: find files, then deep-search
rg -l "GetX" lib/ | xargs rg -C 5 "Get\."

# Export search results to file
rg "TODO" lib/ -t dart > /tmp/todos.txt

# Create semgrep rule file for reuse
# Save as .semgrep.yml in project root
```
