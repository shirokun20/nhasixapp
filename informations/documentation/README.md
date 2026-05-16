# 📚 Scraper Documentation

Dokumentasi lengkap analisis scraper configuration untuk semua source yang ada di Kuron App.

---

## 📋 Daftar Isi

- [Overview](#overview)
- [Analisis Terbaru](#analisis-terbaru)
- [Struktur Folder](#struktur-folder)
- [Cara Menggunakan](#cara-menggunakan)
- [Testing](#testing)

---

## Overview

Folder ini berisi analisis mendalam untuk setiap scraper configuration, termasuk:
- ✅ Analisis struktur HTML sebenarnya
- ❌ Identifikasi masalah pada config
- 🔧 Rekomendasi perbaikan
- 📄 Sample HTML untuk referensi
- 🧪 URL testing

---

## Analisis Terbaru

### 🔴 Critical Issues Found (2026-05-16)

| Source | Status | Confidence | Files |
|--------|--------|-----------|-------|
| **hentaicosplay** | 🔴 Critical | 75% (after fix) | [Analysis](hentaicosplay/hentaicosplay_analysis.md) \| [HTML](hentaicosplay/sample_html_structure.html) |
| **uncensoredmanhwa** | 🔴 Critical | 85% (after fix) | [Analysis](uncensoredmanhwa/uncensoredmanhwa_complete_analysis.md) \| [HTML](uncensoredmanhwa/sample_html_structure.html) |

📊 **Summary**: [SCRAPER_ANALYSIS_SUMMARY.md](SCRAPER_ANALYSIS_SUMMARY.md)

---

## Struktur Folder

```
documentation/
├── README.md                           # File ini
├── SCRAPER_ANALYSIS_SUMMARY.md         # Summary semua analisis
│
├── hentaicosplay/
│   ├── hentaicosplay_analysis.md       # Analisis lengkap per halaman
│   └── sample_html_structure.html      # Visual HTML structure guide
│
├── uncensoredmanhwa/
│   ├── uncensoredmanhwa_complete_analysis.md  # Analisis lengkap per halaman
│   └── sample_html_structure.html             # Visual HTML structure guide
│
├── nhentai/
│   └── (existing documentation)
│
├── komiku/
│   └── (existing documentation)
│
└── ... (other sources)
```

---

## Cara Menggunakan

### 1. Baca Summary Dulu
Mulai dengan membaca [SCRAPER_ANALYSIS_SUMMARY.md](SCRAPER_ANALYSIS_SUMMARY.md) untuk overview semua issues.

### 2. Pilih Source yang Ingin Dianalisis
Masuk ke folder source yang ingin dipelajari, misalnya:
- `hentaicosplay/` untuk Hentai Cosplay
- `uncensoredmanhwa/` untuk Uncensored Manhwa

### 3. Baca Analisis Lengkap
Setiap folder berisi:
- **`*_analysis.md`**: Analisis text lengkap dengan:
  - Struktur HTML sebenarnya
  - Issues yang ditemukan
  - Rekomendasi perbaikan
  - Testing checklist
  
- **`sample_html_structure.html`**: Visual guide yang bisa dibuka di browser untuk melihat:
  - Struktur HTML dengan syntax highlighting
  - Perbandingan config lama vs baru
  - Contoh selector yang benar

### 4. Test dengan Sample URLs
Setiap analisis menyertakan sample URLs untuk testing:
```
Home:     https://site.com/
Search:   https://site.com/search?q=test
Detail:   https://site.com/manga/example
Reader:   https://site.com/manga/example/chapter-1
```

---

## Testing

### Prerequisites
1. **Playwright MCP** harus dikonfigurasi di `.air/mcp.json`
2. **RTK (Rust Token Killer)** untuk efisiensi terminal output
3. **Flutter environment** untuk menjalankan scraper

### Testing Steps

#### 1. Manual Testing (Browser)
```bash
# Buka sample HTML files di browser
open informations/documentation/hentaicosplay/sample_html_structure.html
open informations/documentation/uncensoredmanhwa/sample_html_structure.html
```

#### 2. Scraper Testing (Flutter)
```bash
# Test dengan Flutter app
flutter run --debug

# Atau test specific source
# (implement test command in your app)
```

#### 3. Playwright Testing (Recommended)
```bash
# Use Playwright MCP to verify selectors
# (requires MCP configuration)
```

---

## 📊 Analysis Methodology

### Tools Used
1. **web_fetch** dengan mode `rendered` - Untuk mendapatkan HTML setelah JavaScript execution
2. **Manual inspection** - Analisis struktur HTML secara manual
3. **Comparison** - Membandingkan config dengan HTML sebenarnya

### Analysis Process
1. **Fetch HTML** dari setiap jenis halaman (home, search, detail, reader)
2. **Identify selectors** yang sebenarnya digunakan di HTML
3. **Compare** dengan config yang ada
4. **Document issues** dan buat rekomendasi
5. **Create samples** untuk referensi visual

---

## 🔧 Common Issues Found

### Issue #1: Wrong Container Selectors
**Problem**: Config menggunakan selector yang tidak ada di HTML  
**Example**: `.item` (tidak ada) vs `a[href*='/image/']` (yang benar)  
**Impact**: 🔴 Critical - List extraction gagal total

### Issue #2: Missing Lazy Load Support
**Problem**: Config hanya cek `src`, padahal gambar pakai `data-src`  
**Example**: `attribute: "src"` vs `attribute: "data-src,src"`  
**Impact**: 🟡 Medium - Gambar tidak ter-load

### Issue #3: Wrong Theme Selectors
**Problem**: Config pakai generic selector, padahal site pakai theme khusus (Madara)  
**Example**: `.post-title-link` vs `.page-item-detail` (Madara)  
**Impact**: 🔴 Critical - Semua extraction gagal

### Issue #4: Images in Wrong Element
**Problem**: Config cari di `<img>`, padahal URL di `<a href>`  
**Example**: `img[src]` vs `a[href*='.jpg']`  
**Impact**: 🔴 Critical - Reader tidak bisa load gambar

---

## 📚 Reference Materials

### Hentai Cosplay
- **Technology**: AMP (Accelerated Mobile Pages)
- **Key Challenge**: JavaScript-heavy, lazy loading
- **Recommendation**: Use Playwright for scraping

### Uncensored Manhwa
- **Technology**: WordPress + Madara Theme
- **Key Challenge**: AJAX pagination, lazy loading
- **Recommendation**: Use Playwright for 100% reliability
- **Theme Reference**: Standard Madara selectors documented

---

## 🎯 Priority Matrix

| Source | Priority | Reason | Status |
|--------|----------|--------|--------|
| hentaicosplay | 🔥 HIGH | 0% success rate | ✅ Analyzed |
| uncensoredmanhwa | 🔥 HIGH | 0% success rate | ✅ Analyzed |
| nhentai | 🟡 MEDIUM | Existing docs | ⏳ Pending |
| komiku | 🟡 MEDIUM | Existing docs | ⏳ Pending |

---

## 🚀 Next Steps

### For Developers
1. ✅ Read analysis files
2. ⏳ Update config files with recommended fixes
3. ⏳ Test with sample URLs
4. ⏳ Deploy and monitor

### For QA
1. ⏳ Test each page type (home, search, detail, reader)
2. ⏳ Verify pagination works
3. ⏳ Check image loading
4. ⏳ Test search functionality

### For DevOps
1. ⏳ Configure Playwright MCP
2. ⏳ Set up rate limiting
3. ⏳ Monitor scraper success rates
4. ⏳ Set up alerts for failures

---

## 📞 Support

Jika menemukan issues atau butuh bantuan:

1. **Check Documentation**: Baca file analisis yang relevan
2. **Review HTML Samples**: Buka file HTML untuk visual reference
3. **Test URLs**: Gunakan sample URLs yang disediakan
4. **Use Playwright**: Untuk debugging, gunakan Playwright MCP

---

## 📝 Contributing

Untuk menambah analisis source baru:

1. **Create folder** dengan nama source
2. **Add analysis file**: `{source}_analysis.md` atau `{source}_complete_analysis.md`
3. **Add HTML sample**: `sample_html_structure.html`
4. **Update summary**: Tambahkan ke `SCRAPER_ANALYSIS_SUMMARY.md`
5. **Update this README**: Tambahkan entry di tabel

### Template Structure
```markdown
# {Source Name} - Complete Scraper Analysis

## Overview
- Source: {source_id}
- Base URL: {url}
- Status: {status}
- Last Analyzed: {date}

## Page-by-Page Analysis
### 1. HOME PAGE
### 2. SEARCH PAGE
### 3. DETAIL PAGE
### 4. READER PAGE

## Complete Fixed Config
## Confidence Level Summary
## Testing Checklist
## Known Limitations
```

---

**Last Updated**: 2026-05-16  
**Maintained By**: Kiro AI Assistant  
**Version**: 1.0.0