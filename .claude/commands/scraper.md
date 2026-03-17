# Scraper Debug

Diagnosis and repair guide for HTML scrapers (Crotpedia/Nhentai) when target websites change layout.

## Diagnosis Phase

Before changing any code:

1. **Reproduce**: Confirm the specific URL/page that fails (e.g., "Chapter list empty", "Image 404")
2. **Check Raw Response**: Get raw HTML from the website
   - Use `curl -A "Mozilla/5.0 ..."` or browser Inspect Element
   - **IMPORTANT**: Match the User-Agent from `AppConstants` / Dio config
3. **Compare Structure**: Diff new HTML against old `test/fixtures/`
   - Did CSS class names change? (e.g., `.gallery-item` -> `.g-item`)
   - Did DOM structure change? (e.g., `div > a` -> `div > span > a`)

## Repair Phase

### 1. Update Fixtures FIRST (mandatory)
Do NOT touch scraper code until test fixtures are updated.
- Save the new HTML to `test/fixtures/crotpedia/` or `test/fixtures/nhentai/`
- Name clearly: e.g., `detail_page_new_layout.html`

### 2. Update Selectors
Open the scraper file (`lib/data/datasources/remote/scraper/...`):
- Update `querySelector` or `getElementsByClassName` based on diagnosis
- Use Chrome DevTools or Selector Gadget to validate new selectors

### 3. Handle Edge Cases
- Use `?` nullable checks — scraper must not crash on missing elements
- Throw descriptive exceptions for critical missing elements

### 4. Run Targeted Tests
```bash
flutter test test/data/datasources/remote/scraper/crotpedia_scraper_test.dart
```
**DO NOT PROCEED** until tests pass.

## Final Verification
1. Check backward compatibility with older page layouts
2. Run the app (`flutter run`) and check logs for parsing warnings
