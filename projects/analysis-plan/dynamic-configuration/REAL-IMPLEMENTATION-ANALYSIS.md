# 📋 **Real Implementation Analysis: Deep Dive findings**

Dokumen ini mendokumentasikan hasil audit mendalam terhadap source code asli di package `kuron_nhentai`, `kuron_crotpedia`, dan `lib/core/`.

---

## 🔍 **1. nhentai Implementation Details (`kuron_nhentai`)**

Aplikasi menggunakan pendekatan **Hybrid: API + HTML Scraping**.

### **A. API Endpoints (Actual Findings)**
Semua endpoint ini saat ini di-hardcode di `kuron_nhentai`.

| Feature | REAL Endpoint | Logic Pattern |
|---------|---------------|---------------|
| **Gallery Detail** | `/api/gallery/{id}` | Direct API call |
| **Homepage** | `/api/galleries/all?page={page}` | Direct API call |
| **Search** | `/api/galleries/search?query={q}&page={page}&sort={sort}` | Direct API call |
| **Tag Search** | `/api/galleries/tagged?tag_id={id}&page={page}` | Direct API call |
| **Related** | `/api/gallery/{id}/related` | Direct API call |
| **Popular** | `/api/galleries/search?q=&sort=popular-{period}` | API (Empty query) |
| **Random** | `/random/` | ⚠️ **HTML Scraping Required** |

**Temuan Penting - Random Endpoint**: 
Berbeda dengan anggapan awal, nhentai API **TIDAK** punya endpoint `/api/gallery/random`. App harus mengunjungi `https://nhentai.net/random/`, menangkap redirect URL (MISAL: `https://nhentai.net/g/12345/`), mengekstrak ID `12345`, baru kemudian memanggil `/api/gallery/12345`.

### **B. Image Pattern & Extension Mapping**
Ditemukan di `nhentai_api_models.dart`:
- **Domain**: `i.nhentai.net` (images), `t.nhentai.net` (thumbs).
- **Mapping Logic**:
    - `'j'` → `'jpg'`
    - `'p'` → `'png'`
    - `'g'` → `'gif'`
    - `'w'` → `'webp'`
- **Case Sensitivity**: Sistem saat ini melakukan `.toLowerCase()` sebelum mapping.
- **Default**: Jika kode tidak dikenal, sistem force ke `jpg`.

### **C. Anti-Rate Limit Implementation**
- **Requests Per Minute**: 60 (Hardcoded).
- **Min Delay**: 200ms (Hardcoded).
- **Cooldown**: 5 menit jika terkena 429 (Too Many Requests).
- **Rotate Headers**: Menggunakan User-Agent random dari list internal.

---

## 🔍 **2. Crotpedia Implementation Details (`kuron_crotpedia`)**

### **A. Scraping Architecture**
Crotpedia tidak memiliki API publik. Semua data diambil via `html` parsing menggunakan package `beautiful_soup` atau `html_parser`.

### **B. Real Selectors Found**
| Element | CSS Selector | Notes |
|---------|--------------|-------|
| **Home Container** | `.flexbox4-item` | Latest updates |
| **Search Card** | `.flexbox2-item` | Grid search results |
| **Detail Title** | `.series-titlex h2` | Main h2 title |
| **Gallery Cover** | `.series-thumb img` | Main thumbnail |
| **Chapter List** | `.series-chapterlist li` | List of chapters |
| **Reader Images** | `.reader-area p img` | Direct image mapping |

### **C. Search Limitation (Critical Finding)**
Crotpedia memiliki struktur query search yang berbeda:
- `/advanced-search/?title={q}&author={a}&artist={ar}...`
- ⚠️ **NO TAG EXCLUSION**: Berbeda dengan nhentai (yang bisa pakai `-tag`), Crotpedia hanya mendukung filter inklusif. Konfigurasi `supportsTagExclusion` harus diset `false`.

---

## 🏷️ **3. Tag Data Manager Analysis (`lib/core/utils/`)**

Sistem tag saat ini sangat efisien secara memori tapi kaku untuk diupdate.

### **A. Bundled Assets**
- File: `assets/json/tags.json`
- Ukuran: 5.17 MB (JSON Raw).
- Jumlah Tag: ~50,000 items (Artists, Groups, Parodies, Tags, etc).

### **B. Matrix/TypeCode Mapping**
Hardcoded mapping di `tag_data_manager.dart`:
- `0` → `category`
- `1` → `artist`
- `2` → `parody`
- `3` → `tag`
- `4` → `character`
- `5` → `group`
- `6` → `language`
- `7` → `category` (Duplicate code found in code)

### **C. Multi-Select Logic**
Hardcoded Map `_multipleSelectSupport`:
- `tag`: true
- `artist`: true
- `character`: true
- `parody`: true
- `group`: true
- `language`: false (Single select only)
- `category`: false (Single select only)

---

## ⚙️ **4. Network Configuration (`api_config.dart`)**

Ditemukan daftar default timeouts:
- `connectTimeout`: 30 detik.
- `receiveTimeout`: 30 detik.
- `sendTimeout`: 30 detik.
- `enableApiFallback`: true (Jika API error, coba scrap).

**Rekomendasi**: Semua angka ini harus dipindah ke `app-config.json` agar bisa ditingkatkan jika server nhentai sedang lambat tanpa perlu deploy app baru.
