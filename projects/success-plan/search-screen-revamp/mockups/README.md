# UI/UX Mockups - Search Screen Revamp

## 📱 Interactive Preview Files

### 1. **search-screen-mockup.html**
Preview of search screen implementation for both sources:
- **Nhentai**: Query-string mode with include/exclude tags
- **Crotpedia**: Form-based mode with text fields, radios, checkboxes

**Features**:
- ✅ Source toggle (Nhentai ↔ Crotpedia)
- ✅ Theme toggle (Light ↔ Dark)
- ✅ Bilingual (English ↔ Bahasa Indonesia)
- ✅ Mobile viewport (400px width)
- ✅ Interactive elements (expandable genre section)

---

### 2. **main-screen-sorting-mockup.html**
Preview of main screen with dynamic sorting widget:
- **Nhentai Results**: Interactive dropdown (can re-sort)
- **Crotpedia Results**: Readonly display (tap to modify)

**Features**:
- ✅ Source toggle (Nhentai ↔ Crotpedia)
- ✅ Theme toggle (Light ↔ Dark)
- ✅ Bilingual (English ↔ Bahasa Indonesia)
- ✅ Demonstrates different sorting behaviors
- ✅ Visual feedback on interaction

---

## 🎨 Design Decisions

### Color Scheme
**Light Theme**:
- Primary: `#ffffff` (white)
- Secondary: `#f5f5f5` (light gray)
- Accent: `#2196F3` (blue)
- Text: `#000000` → `#999999` (black to gray)

**Dark Theme**:
- Primary: `#121212` (near black)
- Secondary: `#1e1e1e` (dark gray)
- Accent: `#64B5F6` (light blue)
- Text: `#ffffff` → `#808080` (white to gray)

### Typography
- Font Family: System fonts (`-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto`)
- Heading: 20px (bold)
- Body: 16px (normal)
- Small: 14px → 12px
- Input: 16px (prevents iOS zoom on focus)

### Spacing
- Container padding: 16px
- Element gap: 12px → 8px
- Border radius: 8px → 20px (pills)

---

## 📊 Comparison Table

| Aspect | Nhentai Search | Crotpedia Search |
|--------|----------------|-------------------|
| **Mode** | Query-string | Form-based |
| **Main Input** | Single search box | Multiple text fields |
| **Tags** | Include/Exclude chips | Checkbox groups only |
| **Filters** | Language, Category dropdowns | Status, Type, Order radios |
| **Genres** | No genre filter | Expandable checkbox list |
| **Sorting** | Post-search (interactive) | Pre-search (in form) |
| **URL Style** | `?q=tag:"romance"&sort=popular` | `?title=xxx&genre[]=romance&order=update` |

---

## 🔍 Main Screen Sorting Comparison

| Source | Widget Type | User Can | Tap Action |
|--------|------------|----------|------------|
| **Nhentai** | Interactive Dropdown | Change sort dynamically | Opens dropdown menu |
| **Crotpedia** | Readonly Display | View current sort | Navigate to search |

---

## 🧪 How to Test

1. **Open in Browser**:
   ```bash
   open mockups/search-screen-mockup.html
   open mockups/main-screen-sorting-mockup.html
   ```

2. **Test Interactions**:
   - Click "Nhentai" / "Crotpedia" tabs → UI changes
   - Click "🌙 Dark Mode" → Theme switches
   - Click "🇮🇩 Bahasa Indonesia" → Language changes

3. **Test Search Screen Mockup**:
   - **Nhentai mode**: See query input + tag chips + dropdowns
   - **Crotpedia mode**: See text fields + radios + expandable genres

4. **Test Main Screen Mockup**:
   - **Nhentai mode**: Click dropdown → can change sort
   - **Crotpedia mode**: Click readonly widget → shows navigation hint

---

## ✅ Review Checklist

Before approving implementation:
- [ ] UI matches app theme (light/dark)
- [ ] All text supports bilingual (EN/ID)
- [ ] Mobile viewport is appropriate (400px)
- [ ] Nhentai search looks intuitive
- [ ] Crotpedia form is clear and organized
- [ ] Sorting widgets make sense for each source
- [ ] No confusing UI elements
- [ ] Layout is clean and scannable

---

## 📝 Next Steps

### If Approved:
1. Move to `projects/onprogress-plan/search-screen-revamp/`
2. Start Phase 1: Config Models
3. Implement according to `implementation-guide.md`

### If Changes Needed:
1. Document feedback
2. Update mockups
3. Re-review

---

## 🎯 Key Highlights

**What Makes This Design Good**:
1. ✅ **Source-Aware**: UI adapts to source capabilities
2. ✅ **Clear Separation**: Nhentai vs Crotpedia clearly different
3. ✅ **Intuitive Sorting**: Dropdown for dynamic, readonly for static
4. ✅ **Consistent Theme**: Follows app design language
5. ✅ **Accessible**: Good contrast, readable fonts, clear labels
6. ✅ **Localized**: Bilingual from day one

---

**Created**: 2026-01-13
**For**: Search Screen Revamp Project
**Status**: Ready for Review
