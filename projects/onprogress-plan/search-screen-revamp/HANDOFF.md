# Search Screen Revamp - Handoff Instructions

**Purpose**: Instruksi untuk AI baru ketika melanjutkan project ini

---

## 🎯 Quick Context

Project: **Search Screen Revamp untuk NhasixApp**
- **Goal**: Dynamic search UI untuk nhentai (query-string) dan crotpedia (form-based)
- **100% CDN-driven**: Zero hardcoding
- **Status**: Day 1 of 4 - Config Models & CDN Setup
- **Workflow**: `onprogress-plan/search-screen-revamp/`

---

## 📋 Instructions untuk AI Baru

Ketika user memulai chat baru, copy-paste instruksi ini:

```
Continue Search Screen Revamp project:

Context:
- Project: Dynamic search screen dengan 100% CDN config
- Location: projects/onprogress-plan/search-screen-revamp/
- Current Day: [isi dengan day yang sedang dikerjakan]
- Status: Check search-screen-revamp-progress.md

Must Read (urutan):
1. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-progress.md]
2. @[projects/onprogress-plan/search-screen-revamp/implementation-guide.md]
3. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-plan.md]

Rules:
- Follow NhasixApp Agent Rules (@[asix-rules.md])
- Update progress.md checklist after each task
- Commit after each phase with format:
  git commit -m "feat(search): [phase]
  
  [bullets]
  
  Refs: #search-screen-revamp Day [X]"
- Use MCP Sequential Thinking for complex logic
- Test after each component (flutter analyze)

Current Phase: [Day X, Phase Y]
Next Task: [check progress.md untuk task pertama yang belum complete]

Continue dari sini.
```

---

## 📝 Template Copy-Paste untuk User

### **Day 1** (Config Models & CDN):
```
Continue Search Screen Revamp - Day 1

Context: Dynamic search config setup
Location: projects/onprogress-plan/search-screen-revamp/
Current: Day 1 - Phase 1 + 2 (Config Models & CDN)

Read:
1. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-progress.md]
2. @[projects/onprogress-plan/search-screen-revamp/implementation-guide.md]

Task: Complete Phase 1 + 2 checklist in progress.md
Rules: Follow @[asix-rules.md], update progress.md, commit per phase

Start now.
```

### **Day 2** (Sorting Widget):
```
Continue Search Screen Revamp - Day 2

Context: Dynamic sorting widget implementation
Location: projects/onprogress-plan/search-screen-revamp/
Current: Day 2 - Phase 3 (UI Components)

Read:
1. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-progress.md]
2. @[projects/onprogress-plan/search-screen-revamp/sorting-widget-clarification.md]

Task: Create DynamicSortingWidget (dropdown + readonly modes)
Rules: Follow @[asix-rules.md], test both nhentai/crotpedia, commit

Start now.
```

### **Day 3** (Search Screen):
```
Continue Search Screen Revamp - Day 3

Context: Dynamic search UI implementation
Location: projects/onprogress-plan/search-screen-revamp/
Current: Day 3 - Phase 4 + 5 (Search Screen + Scrapers)

Read:
1. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-progress.md]
2. @[projects/onprogress-plan/search-screen-revamp/mockups/search-screen-revised.html]

Task: Create QueryStringSearchUI + FormBasedSearchUI + update scrapers
Rules: Follow @[asix-rules.md], match mockup UI, commit

Start now.
```

### **Day 4** (Testing):
```
Continue Search Screen Revamp - Day 4

Context: End-to-end testing & polish
Location: projects/onprogress-plan/search-screen-revamp/
Current: Day 4 - Testing & Polish

Read:
1. @[projects/onprogress-plan/search-screen-revamp/search-screen-revamp-progress.md]

Task: Complete testing checklist, fix bugs, final commit
Rules: Follow @[asix-rules.md], flutter analyze + test must pass

Finish and move to projects/success-plan/
```

---

## 🔍 Checklist untuk AI Baru

Setelah menerima handoff instruction, AI HARUS:

1. **[ ] Read progress.md** - Understand current status
2. **[ ] Check last git commit** - See what was done
3. **[ ] Identify current phase** - Know what to do next
4. **[ ] Review implementation-guide.md** - Get step-by-step details
5. **[ ] Follow NhasixApp rules** - Konsistensi workflow

---

## 🚨 Critical Reminders untuk AI

**ALWAYS**:
- ✅ Update `search-screen-revamp-progress.md` after EVERY task
- ✅ Commit with proper format after each phase
- ✅ Run `flutter analyze` before commit
- ✅ Reference planning docs (implementation-guide, mockups, etc)
- ✅ Use `snake_case` for files, `PascalCase` for classes

**NEVER**:
- ❌ Skip updating progress.md
- ❌ Make changes without reading current status
- ❌ Ignore NhasixApp agent rules
- ❌ Commit without clear message
- ❌ Use hardcoded values (MUST use CDN config)

---

## 📚 Essential Files Reference

| File | Purpose |
|------|---------|
| `search-screen-revamp-progress.md` | **Main tracker** - todo list per day |
| `implementation-guide.md` | Step-by-step code examples |
| `search-screen-revamp-plan.md` | Architecture & design decisions |
| `cdn-config-requirements.md` | Config structure & models |
| `sorting-widget-clarification.md` | Main screen sorting behavior |
| `mockups/search-screen-revised.html` | UI reference (no tabs!) |

---

## 💡 Tips untuk Smooth Handoff

### Before Starting New Chat:
1. User harus **commit** dulu (save current progress)
2. User **update progress.md** dengan status terakhir
3. User note down "Current Phase" dan "Next Task"

### When Starting New Chat:
1. Copy-paste template yang sesuai (Day 1/2/3/4)
2. AI akan auto-read progress.md
3. AI continue dari task terakhir yang belum `[x]`

---

## 🎯 Success Check

AI baru dianggap berhasil handoff jika:
- ✅ Membaca progress.md sebagai langkah pertama
- ✅ Tahu current phase dan next task
- ✅ Follow commit strategy yang sama
- ✅ Update progress.md setelah setiap task
- ✅ Konsisten dengan planning docs

---

**Created**: 2026-01-13
**For**: Context continuity antar AI conversations
**Status**: Ready to use
