# Business Requirement Document (BRD)
## Proyek Ekstraksi Data Katalog Komik - KomikTap.info

---

**Dokumen:** Business Requirement Document  
**Proyek:** Sistem Akuisisi Data Katalog Komik Digital KomikTap  
**Versi:** 1.0.0  
**Tanggal:** 25 Januari 2026  
**Status:** Draft untuk Review  
**Prepared by:** Senior Business Analyst - Data Engineering & Content Management

---

## 1. Ringkasan Eksekutif

### 1.1 Latar Belakang
Dalam ekosistem konten digital, katalog komik memiliki struktur data yang kompleks dan hierarkis. Data terdistribusi dalam berbagai level halaman web, mulai dari daftar indeks, halaman detail metadata, hingga aset visual per chapter. Proyek ini bertujuan untuk mengakuisisi seluruh data katalog komik dari situs **KomikTap.info** secara sistematis dan terstruktur.

### 1.2 Tujuan Bisnis
Membangun sistem ekstraksi data yang mampu:

1. **Mengakuisisi Metadata Lengkap** — Mengumpulkan informasi bibliografis komik (judul, penulis, artis, status publikasi, genre, sinopsis)
2. **Memetakan Hierarki Konten** — Memahami relasi Parent-Child antara Series Detail dan Chapter
3. **Mengarsipkan Aset Visual** — Memperoleh daftar URL gambar secara berurutan untuk setiap chapter
4. **Mendukung Navigasi Multi-Dimensi** — Memfasilitasi akses melalui pagination, kategori genre, dan pencarian kata kunci
5. **Memastikan Integritas Data** — Menjamin kelengkapan atribut dan ketepatan urutan konten

### 1.3 Manfaat yang Diharapkan
- **Katalogisasi Komprehensif** — Database terstruktur untuk analisis konten
- **Efisiensi Operasional** — Otomasi proses yang sebelumnya manual
- **Skalabilitas** — Kemampuan untuk menangani pertumbuhan katalog
- **Kualitas Data** — Standardisasi format dan validasi atribut

---

## 2. Lingkup Proyek & Pola URL (Project Scope)

Sistem ekstraksi harus mampu menangani **7 (tujuh) area navigasi** yang membentuk arsitektur informasi situs:

### 2.1 Halaman Utama (Homepage)
- **URL:** `https://komiktap.info/`
- **Fungsi Bisnis:** Entry point untuk monitoring update terbaru
- **Karakteristik:**
  - Menampilkan daftar komik yang baru diupdate
  - Berisi link ke halaman detail komik
  - Menyediakan thumbnail dan metadata ringkas (rating, chapter terakhir)
- **Pola Ekstraksi:** List-mode dengan elemen identik pada pagination

### 2.2 Navigasi Halaman (Standard Pagination)
- **URL:** `https://komiktap.info/page/{N}/`
  - Contoh: `https://komiktap.info/page/2/`
- **Parameter:** `{N}` = nomor halaman (integer, dimulai dari 2)
- **Fungsi Bisnis:** Menelusuri arsip historis update ke halaman belakang
- **Karakteristik:**
  - Struktur HTML identik dengan Homepage
  - Memuat konten yang lebih lama secara kronologis
- **Aturan Navigasi:**
  - Halaman 1 = Homepage (`/`)
  - Halaman berikutnya mengikuti pola `/page/{N}/`
  - Hentikan iterasi jika mencapai halaman kosong atau error 404

### 2.3 Halaman Kategori/Genre
- **URL:** `https://komiktap.info/genres/{slug}/`
  - Contoh: `https://komiktap.info/genres/comedy/`
  - Contoh: `https://komiktap.info/genres/big-ass/`
- **Parameter:** `{slug}` = identifier genre dalam format lowercase dengan pemisah dash
- **Fungsi Bisnis:** Filter konten berdasarkan taksonomi genre
- **Karakteristik:**
  - Menampilkan komik yang termasuk dalam genre tertentu
  - Mendukung pagination dengan pola `/genres/{slug}/page/{N}/`
- **Catatan:** Daftar genre lengkap harus diekstrak dari navigasi atau filter pada situs

### 2.4 Halaman Pencarian (Search)
- **URL:** `https://komiktap.info/?s={query}`
  - Contoh: `https://komiktap.info/?s=abc`
- **Parameter:** `{query}` = kata kunci pencarian (URL-encoded)
- **Fungsi Bisnis:** Pencarian spesifik berdasarkan kata kunci judul atau metadata
- **Karakteristik:**
  - Simple Search (tidak ada advanced filtering)
  - Mengembalikan hasil yang cocok dengan query
- **Perbedaan dengan Crotpedia:** Tidak memiliki form-based advanced search dengan multiple fields

### 2.5 Navigasi Halaman Pencarian
- **URL:** `https://komiktap.info/page/{N}/?s={query}`
  - Contoh: `https://komiktap.info/page/2/?s=one`
- **Parameter:**
  - `{N}` = nomor halaman
  - `{query}` = kata kunci pencarian (harus dipertahankan)
- **Fungsi Bisnis:** Pagination yang mempertahankan parameter search query
- **Karakteristik:**
  - Query string parameter (`?s=`) harus konsisten di setiap halaman
  - Struktur hasil identik dengan halaman pencarian pertama

### 2.6 Halaman Detail Komik (Series Detail / Manga Page)
- **URL:** `https://komiktap.info/manga/{slug}/`
  - Contoh: `https://komiktap.info/manga/lets-make-a-deal/`
- **Parameter:** `{slug}` = unique identifier series dalam format lowercase dengan dash
- **Fungsi Bisnis:** Halaman induk (Parent) yang berisi metadata lengkap dan daftar chapter
- **Karakteristik:**
  - **Metadata Bibliografis:** Judul, Judul Alternatif, Author, Artist, Status (Ongoing/Completed)
  - **Metadata Deskriptif:** Sinopsis, Genre Tags, Rating
  - **Aset Visual:** URL Cover/Thumbnail beresolusi tinggi
  - **Daftar Chapter:** List seluruh chapter dengan link ke halaman baca
- **Aturan Hierarki:** 
  - Level ini adalah **Parent** bagi semua chapter
  - Harus dikunjungi terlebih dahulu untuk mendapatkan inventory chapter

### 2.7 Halaman Baca (Chapter Viewer / Reading Page)
- **URL:** `https://komiktap.info/{slug}-chapter-{N}/`
  - Contoh: `https://komiktap.info/lets-make-a-deal-chapter-1/`
- **Parameter:**
  - `{slug}` = identifier series (sama dengan parent)
  - `{N}` = nomor chapter
- **Fungsi Bisnis:** Halaman konten (Child) yang memuat aset gambar cerita
- **Karakteristik:**
  - **Aset Konten:** Daftar URL gambar halaman komik secara berurutan
  - **Navigasi Lateral:** Link Previous Chapter, Link Next Chapter
  - **Metadata Kontekstual:** Judul chapter, tanggal publikasi
- **Aturan Hierarki:**
  - Level ini adalah **Child** dari Series Detail
  - Urutan gambar HARUS dipertahankan (posisi 1 sampai N)

---

### 2.8 Diagram Hierarki URL

```
[Homepage / Genre / Search]
        │
        ├─── (List Item) ───┐
        │                   │
        └─── Pagination ────┘
                │
                ▼
        [Series Detail Page]  ◄── PARENT
                │
                ├─── Chapter 1 ◄── CHILD
                ├─── Chapter 2
                ├─── Chapter 3
                └─── Chapter N
                        │
                        └─── Image 1, 2, 3, ..., M
```

---

## 3. Persyaratan Data (Data Requirements)

### 3.1 Level List (Homepage / Search / Genre)

Data yang harus diekstrak dari setiap item dalam list:

| No | Elemen Data       | Tipe Data | Wajib | Deskripsi                                    | Fallback Value |
|----|-------------------|-----------|-------|----------------------------------------------|----------------|
| 1  | URL Detail        | String    | Ya    | Link absolut ke halaman Series Detail       | -              |
| 2  | Judul             | String    | Ya    | Judul komik yang ditampilkan                | -              |
| 3  | URL Thumbnail     | String    | Ya    | Link gambar cover/thumbnail                 | -              |
| 4  | Rating            | Float     | Tidak | Nilai rating numerik (jika tersedia)       | null           |
| 5  | Chapter Terakhir  | String    | Tidak | Label chapter terbaru (misal: "Ch. 25")    | null           |
| 6  | Status Update     | String    | Tidak | Informasi timestamp update terakhir         | null           |

**Catatan:**
- URL harus dalam format absolut (full URL dengan domain)
- Jika rating tidak ada, set sebagai `null` bukan `0`
- Chapter Terakhir bisa dalam berbagai format ("Chapter 25", "Ch.25", "Ep.25")

---

### 3.2 Level Detail (Series Detail / Manga Page)

#### 3.2.1 Metadata Utama

| No | Elemen Data          | Tipe Data      | Wajib | Deskripsi                                      | Fallback Value |
|----|----------------------|----------------|-------|------------------------------------------------|----------------|
| 1  | Judul Utama          | String         | Ya    | Judul primary series                           | -              |
| 2  | Judul Alternatif     | Array[String]  | Tidak | Daftar judul dalam bahasa lain                | []             |
| 3  | Author (Penulis)     | String         | Tidak | Nama penulis/pengarang                        | "Unknown"      |
| 4  | Artist (Seniman)     | String         | Tidak | Nama ilustrator/seniman                       | "Unknown"      |
| 5  | Status Publikasi     | Enum           | Ya    | `Ongoing` atau `Completed`                    | "Ongoing"      |
| 6  | Tipe Konten          | String         | Tidak | Manga, Manhwa, Manhua, Doujinshi, dll.        | "Manga"        |
| 7  | Rating               | Float          | Tidak | Nilai rating agregat (0-10 atau 0-5)         | null           |
| 8  | Total Views          | Integer        | Tidak | Jumlah total view/pembaca                     | null           |
| 9  | Sinopsis/Deskripsi   | Text           | Ya    | Deskripsi cerita/plot summary                 | ""             |
| 10 | URL Cover            | String         | Ya    | Link gambar cover beresolusi tinggi            | -              |
| 11 | Tanggal Rilis        | Date           | Tidak | Tanggal publikasi pertama kali                | null           |
| 12 | Tanggal Update       | Date           | Tidak | Tanggal update terakhir                       | null           |

#### 3.2.2 Genre Tags

| No | Elemen Data   | Tipe Data      | Wajib | Deskripsi                                   | Fallback Value |
|----|---------------|----------------|-------|---------------------------------------------|----------------|
| 1  | Genre List    | Array[String]  | Tidak | Daftar genre/tag yang terkait dengan series | []             |
| 2  | Genre URL     | Array[String]  | Tidak | Link ke halaman genre (untuk navigasi)      | []             |

**Catatan:**
- Setiap genre harus dinormalisasi (lowercase, trim whitespace)
- Genre bisa memiliki URL untuk cross-reference ke halaman kategori

#### 3.2.3 Daftar Chapter

| No | Elemen Data        | Tipe Data | Wajib | Deskripsi                                      | Fallback Value |
|----|--------------------|-----------|-------|------------------------------------------------|----------------|
| 1  | Nomor Chapter      | String    | Ya    | Identifier chapter (bisa numerik atau string) | -              |
| 2  | Judul Chapter      | String    | Tidak | Judul spesifik chapter (jika ada)             | ""             |
| 3  | URL Chapter        | String    | Ya    | Link absolut ke halaman reading page          | -              |
| 4  | Tanggal Publikasi  | Date      | Tidak | Tanggal chapter dipublikasikan                | null           |
| 5  | Urutan             | Integer   | Ya    | Sequence number untuk sorting                 | -              |

**Aturan Bisnis:**
- Daftar chapter harus dikumpulkan secara LENGKAP dari halaman detail
- Urutan chapter bisa dari terlama ke terbaru ATAU terbaru ke terlama (harus dikonfirmasi)
- Setiap chapter harus memiliki `Urutan` untuk memastikan sorting yang benar

---

### 3.3 Level Chapter (Reading Page / Viewer)

#### 3.3.1 Navigasi Chapter

| No | Elemen Data              | Tipe Data | Wajib | Deskripsi                                | Fallback Value |
|----|--------------------------|-----------|-------|------------------------------------------|----------------|
| 1  | URL Chapter Sebelumnya   | String    | Tidak | Link ke previous chapter (jika ada)     | null           |
| 2  | URL Chapter Berikutnya   | String    | Tidak | Link ke next chapter (jika ada)         | null           |
| 3  | URL Kembali ke Detail    | String    | Ya    | Link untuk kembali ke series detail page | -              |

#### 3.3.2 Aset Konten (Gambar)

| No | Elemen Data      | Tipe Data      | Wajib | Deskripsi                                        | Fallback Value |
|----|------------------|----------------|-------|--------------------------------------------------|----------------|
| 1  | Daftar URL Gambar| Array[String]  | Ya    | List URL gambar halaman komik (terurut)         | -              |
| 2  | Urutan Gambar    | Integer        | Ya    | Sequence number untuk setiap gambar (1 sd N)    | -              |
| 3  | Alt Text         | String         | Tidak | Descriptive text untuk gambar (accessibility)   | ""             |

**Aturan Bisnis KRITIS:**
- **Urutan gambar TIDAK BOLEH tertukar** — Sequence harus dipertahankan dari 1 sampai N
- URL gambar harus dalam format absolut (full path)
- Jika gambar gagal dimuat, tetap simpan URL-nya untuk troubleshooting

---

### 3.4 Metadata Pagination

Untuk setiap halaman yang mendukung pagination (Homepage, Genre, Search):

| No | Elemen Data       | Tipe Data | Wajib | Deskripsi                                  | Fallback Value |
|----|-------------------|-----------|-------|--------------------------------------------|----------------|
| 1  | Current Page      | Integer   | Ya    | Nomor halaman saat ini                     | 1              |
| 2  | Total Pages       | Integer   | Tidak | Total jumlah halaman (jika tersedia)      | null           |
| 3  | Has Next Page     | Boolean   | Ya    | Indikator apakah ada halaman berikutnya   | false          |
| 4  | Has Previous Page | Boolean   | Ya    | Indikator apakah ada halaman sebelumnya   | false          |
| 5  | Next Page URL     | String    | Tidak | Link ke halaman berikutnya                | null           |
| 6  | Previous Page URL | String    | Tidak | Link ke halaman sebelumnya                | null           |

---

## 4. Aturan Bisnis & Logika (Business Logic)

### 4.1 Hierarki Parent-Child

**Aturan Fundamental:**

1. **Sequence Akuisisi:**
   ```
   List Page → Series Detail (PARENT) → Chapter List → Chapter Reader (CHILD) → Images
   ```

2. **Dependency Chain:**
   - Sistem TIDAK BOLEH langsung mengakses Chapter Reader tanpa terlebih dahulu mengunjungi Series Detail
   - Series Detail adalah satu-satunya sumber untuk mendapatkan daftar chapter lengkap
   - Setiap Chapter Reader harus memiliki reference ke Parent (Series Detail URL)

3. **Inventory Management:**
   - Daftar chapter dari Series Detail menjadi "inventory list" yang harus dikunjungi
   - Sistem harus memvalidasi apakah semua chapter dari inventory telah dikunjungi
   - Jika ada chapter yang gagal diakses, log sebagai "incomplete extraction"

### 4.2 Integritas Data & Validasi

**4.2.1 Integritas Urutan Gambar**

- **Aturan:** Urutan gambar pada Chapter Reader TIDAK BOLEH tertukar
- **Implementasi:** 
  - Setiap gambar harus memiliki attribute `sequence` atau `position` (1, 2, 3, ..., N)
  - Sorting harus berdasarkan urutan kemunculan di DOM, bukan berdasarkan URL atau filename
- **Validasi:**
  - Konfirmasi sequence tidak ada yang terlewat (contoh: 1, 2, 4 → INVALID, missing 3)
  - Konfirmasi tidak ada duplikasi sequence (contoh: 1, 2, 2, 3 → INVALID)

**4.2.2 Handling Empty atau Missing Data**

| Field           | Aturan jika Empty/Null                                  |
|-----------------|--------------------------------------------------------|
| Author          | Set sebagai `"Unknown"`                                |
| Artist          | Set sebagai `"Unknown"`                                |
| Rating          | Set sebagai `null` (BUKAN 0)                           |
| Sinopsis        | Set sebagai `""` (empty string)                        |
| Genre List      | Set sebagai `[]` (empty array)                         |
| Chapter List    | **ERROR** — Series tanpa chapter tidak valid           |
| Image List      | **ERROR** — Chapter tanpa gambar tidak valid           |

**4.2.3 Normalisasi Data**

- **Genre Tags:** 
  - Konversi ke lowercase
  - Trim leading/trailing whitespace
  - Replace multiple spaces dengan single space
  - Contoh: `"  Action  "` → `"action"`

- **Status Publikasi:**
  - Standardisasi ke enum: `"Ongoing"` atau `"Completed"`
  - Alternatif yang diterima: `"ongoing"`, `"ONGOING"`, `"Berlangsung"` → semua menjadi `"Ongoing"`

- **URL:**
  - Semua URL harus dalam format absolut
  - Jika mendapat relative URL, prepend dengan base URL
  - Contoh: `/manga/abc/` → `https://komiktap.info/manga/abc/`

### 4.3 Logika Pagination

**4.3.1 Deteksi Akhir Pagination**

Sistem harus berhenti iterasi jika salah satu kondisi terpenuhi:

1. **HTTP 404:** Halaman tidak ditemukan
2. **Empty Result:** Tidak ada item dalam list
3. **No Next Link:** Tidak ada elemen navigasi "Next Page"
4. **Duplicate Content:** Konten halaman N identik dengan halaman N-1 (indikasi loop)

**4.3.2 Pagination dengan Query Parameter**

- Untuk Search: Parameter `?s=` HARUS dipertahankan di semua halaman
- Format benar: `/page/2/?s=keyword`
- Jangan menukar urutan parameter: `/?s=keyword&page=2` (jika tidak didukung)

### 4.4 Error Handling & Retry Logic

**4.4.1 Klasifikasi Error**

| Error Type              | Action                                      | Retry? |
|-------------------------|---------------------------------------------|--------|
| Network Timeout         | Retry dengan exponential backoff           | Ya     |
| HTTP 404                | Skip item, log sebagai "Not Found"         | Tidak  |
| HTTP 403/429            | Pause, tunggu cooldown, lalu retry         | Ya     |
| Parsing Error           | Log error detail, skip item                | Tidak  |
| Empty Required Field    | Mark sebagai "Invalid Data", skip          | Tidak  |

**4.4.2 Retry Strategy**

- **Max Retry:** 3 kali
- **Backoff:** Exponential (1s, 2s, 4s)
- **Cooldown untuk Rate Limiting:** 60 detik jika mendapat HTTP 429
- **Circuit Breaker:** Stop semua request jika 10 consecutive errors

### 4.5 Data Consistency Rules

**4.5.1 Relational Integrity**

- Setiap Chapter HARUS memiliki reference ke Parent Series (via `seriesSlug` atau `seriesUrl`)
- Setiap Image HARUS memiliki reference ke Parent Chapter (via `chapterUrl` atau `chapterId`)

**4.5.2 Timestamp Rules**

- Semua timestamp harus dalam format ISO 8601: `YYYY-MM-DDTHH:mm:ss+07:00`
- Jika timezone tidak tersedia, assume UTC+7 (WIB) untuk kompatibilitas lokal

**4.5.3 Uniqueness Constraints**

- **Series:** Unik berdasarkan `slug` atau `url`
- **Chapter:** Unik berdasarkan kombinasi `(seriesSlug, chapterNumber)`
- **Image:** Unik berdasarkan kombinasi `(chapterUrl, sequenceNumber)`

---

## 5. Kriteria Keberhasilan (Success Criteria)

### 5.1 Kriteria Kelengkapan Data

| No | Kriteria                            | Target Metric                          | Notes                                      |
|----|-------------------------------------|----------------------------------------|--------------------------------------------|
| 1  | Kelengkapan Metadata Series         | 100% field wajib terisi                | Author/Artist boleh "Unknown"              |
| 2  | Kelengkapan Daftar Chapter          | 100% chapter dari detail page terakuisisi | Tidak boleh ada chapter terlewat        |
| 3  | Akurasi Urutan Gambar               | 100% sequence benar (no swap)          | Validasi manual sampling 10% chapter       |
| 4  | Validitas URL                       | 95% URL accessible (HTTP 200)          | Kecuali jika sumber memang unavailable     |
| 5  | Integritas Parent-Child Relation    | 100% child memiliki reference ke parent| Check foreign key consistency              |

### 5.2 Kriteria Kualitas Data

| No | Kriteria                       | Target Metric                          | Measurement Method                         |
|----|--------------------------------|----------------------------------------|--------------------------------------------|
| 1  | Normalisasi Genre              | 100% genre dalam lowercase, trimmed    | Automated validation script                |
| 2  | Format Timestamp               | 100% dalam ISO 8601                    | Regex validation                           |
| 3  | URL Format                     | 100% absolute URL                      | Check untuk presence of `https://`         |
| 4  | Duplicate Series               | 0% duplicate berdasarkan slug          | Database unique constraint check           |
| 5  | Empty Required Fields          | 0% missing value untuk field wajib     | NOT NULL validation                        |

### 5.3 Kriteria Performa

| No | Kriteria                       | Target Metric                          | Measurement Tool                           |
|----|--------------------------------|----------------------------------------|--------------------------------------------|
| 1  | Throughput Ekstraksi           | Minimum 50 series/hour                 | Progress log analysis                      |
| 2  | Error Rate                     | Maksimum 5% dari total request         | Error log monitoring                       |
| 3  | Retry Success Rate             | Minimum 80% error teratasi setelah retry| Retry attempt logs                        |
| 4  | Resource Efficiency            | Tidak ada memory leak                  | Memory profiling                           |

### 5.4 Kriteria Fungsional

| No | Fitur                                | Expected Behavior                      | Test Method                                |
|----|--------------------------------------|----------------------------------------|--------------------------------------------|
| 1  | Homepage List Extraction             | Semua item list berhasil diekstrak     | Compare dengan manual count                |
| 2  | Pagination Navigation                | Iterasi hingga halaman terakhir        | Verify last page = no next link            |
| 3  | Genre Filtering                      | Data sesuai dengan genre yang dipilih  | Manual spot check                          |
| 4  | Search Functionality                 | Hasil relevan dengan query             | Test dengan known keyword                  |
| 5  | Chapter List Completeness            | Jumlah chapter sesuai dengan tampilan web | Cross-reference dengan UI                 |
| 6  | Image Sequence Preservation          | Urutan gambar identik dengan web reader| Manual visual comparison                   |

### 5.5 Acceptance Criteria

Proyek dianggap SUKSES jika memenuhi SEMUA kriteria berikut:

✅ **Kriteria 1:** Minimal 95% series berhasil diekstrak dengan metadata lengkap  
✅ **Kriteria 2:** TIDAK ADA chapter dengan urutan gambar yang tertukar (0% error rate)  
✅ **Kriteria 3:** Sistem dapat menangani pagination hingga endpoint (tidak infinite loop)  
✅ **Kriteria 4:** Error rate di bawah 5% untuk seluruh request HTTP  
✅ **Kriteria 5:** Data tersimpan dalam format terstruktur yang dapat divalidasi (JSON/Database)  
✅ **Kriteria 6:** Dokumentasi lengkap tentang struktur data dan aturan bisnis tersedia  

### 5.6 Sample Data Validation

Untuk validasi awal, sistem harus diuji dengan sample berikut:

1. **Test Case 1 - Single Series:**
   - URL: `https://komiktap.info/manga/lets-make-a-deal/`
   - Expected: Metadata lengkap + semua chapter + semua gambar terurut benar

2. **Test Case 2 - Genre Page:**
   - URL: `https://komiktap.info/genres/comedy/`
   - Expected: List komik comedy + pagination berhasil

3. **Test Case 3 - Search:**
   - URL: `https://komiktap.info/?s=one`
   - Expected: Hasil pencarian relevan + pagination dengan query parameter

4. **Test Case 4 - Empty Result:**
   - URL: `https://komiktap.info/?s=xyzabc123impossible`
   - Expected: Sistem handling gracefully (tidak crash)

---

## 6. Arsitektur & Integrasi Sistem

### 6.1 Analisis Pola Eksisting (Crotpedia)

Berdasarkan review terhadap sistem yang sudah ada (`crotpedia`), identifikasi pola berikut:

**6.1.1 Struktur Paket (Package-Based Architecture)**

```
packages/
├── kuron_core/           # Core framework/utilities
├── kuron_crotpedia/      # Crotpedia-specific implementation
├── kuron_nhentai/        # NHentai-specific implementation
└── kuron_komiktap/       # [TO BE CREATED] KomikTap implementation
```

**Kesimpulan:** Sistem menggunakan **modular package-based architecture**. Setiap sumber konten (source) diimplementasikan sebagai package terpisah.

**6.1.2 Struktur Konfigurasi**

```
configs/
├── app-config.json           # Global app configuration
├── crotpedia-config.json     # Crotpedia-specific config
├── nhentai-config.json       # NHentai-specific config
├── tags-config.json          # Global tags configuration
├── tags/
│   └── tags_crotpedia.json   # Crotpedia-specific tags
└── komiktap-config.json      # [TO BE CREATED] KomikTap config
```

**Kesimpulan:** Setiap source memiliki konfigurasi JSON terpisah yang mendefinisikan:
- Base URL
- Search configuration
- Scraping selectors
- URL patterns
- Feature flags
- UI customization

### 6.2 Rekomendasi Integrasi KomikTap

#### 6.2.1 Apakah Perlu Core Baru?

**Jawaban: TIDAK**

**Justifikasi:**
- `kuron_core` sudah menyediakan framework yang generic
- Pola arsitektur KomikTap **mirip** dengan Crotpedia (List → Detail → Chapter → Images)
- Perbedaan utama hanya pada:
  - Search mechanism (simple vs advanced)
  - URL patterns
  - HTML selectors
  
Semua perbedaan ini dapat ditangani melalui **configuration**, tidak memerlukan core logic baru.

#### 6.2.2 Apakah Perlu Package Baru?

**Jawaban: YA**

**Justifikasi:**
- Mengikuti prinsip **Separation of Concerns**
- Memudahkan maintenance (isolasi code untuk setiap source)
- Memungkinkan customization spesifik tanpa affecting source lain
- Konsisten dengan pattern yang sudah established (`kuron_crotpedia`, `kuron_nhentai`)

**Action Item:**
```
✅ Buat package baru: packages/kuron_komiktap/
```

#### 6.2.3 Struktur Package Baru

Berdasarkan analogi dengan `kuron_crotpedia`:

```
packages/kuron_komiktap/
├── lib/
│   ├── models/              # Data models
│   │   ├── komiktap_series.dart
│   │   ├── komiktap_chapter.dart
│   │   └── komiktap_search_result.dart
│   ├── services/            # Business logic
│   │   ├── komiktap_scraper.dart
│   │   └── komiktap_parser.dart
│   ├── repositories/        # Data access layer
│   │   └── komiktap_repository.dart
│   └── komiktap.dart        # Public API
├── test/                    # Unit tests
└── pubspec.yaml
```

### 6.3 Konfigurasi KomikTap

Sistem harus menggunakan **configuration-driven approach** untuk mendefinisikan behavior ekstraksi.

**Lokasi File:**
```
configs/komiktap-config.json
```

**Prinsip Desain Konfigurasi:**

1. **Declarative, Not Imperative** — Konfigurasi mendeskripsikan "APA" yang harus diekstrak, bukan "BAGAIMANA" cara ekstraknya
2. **Selector-Based** — Menggunakan selector (CSS/XPath) untuk locate elemen HTML
3. **Pattern-Based URL** — Mendefinisikan pola URL dengan placeholder `{param}`
4. **Feature Flags** — Enable/disable fitur tertentu via boolean flags

**Section yang Harus Ada:**

| Section           | Purpose                                              |
|-------------------|------------------------------------------------------|
| `source`          | Identifier untuk source ("komiktap")                 |
| `version`         | Versi konfigurasi untuk backward compatibility       |
| `baseUrl`         | Base URL website (`https://komiktap.info`)           |
| `searchConfig`    | Konfigurasi mechanism pencarian                      |
| `scraper`         | Selector HTML untuk ekstraksi data                   |
| `urlPatterns`     | Template URL untuk berbagai jenis halaman            |
| `pagination`      | Logika navigasi pagination                           |
| `features`        | Feature flags (search, download, bookmark, etc.)     |
| `ui`              | Customization tampilan UI (nama, icon, theme color) |

**Detail Spesifikasi:** Lihat Section 7 (Spesifikasi Konfigurasi)

### 6.4 Point of Integration

**6.4.1 Entry Point**

Sistem utama akan load konfigurasi KomikTap melalui:

```
AppConfigManager
  └── loadSourceConfig("komiktap")
        └── parse configs/komiktap-config.json
              └── initialize KomikTapRepository
```

**6.4.2 Dependency Injection**

Package `kuron_komiktap` harus menerima config sebagai dependency:

```
(Pseudo-flow, technology agnostic)

config = loadConfig("configs/komiktap-config.json")
komiktapRepo = new KomikTapRepository(config)
scraper = new KomikTapScraper(config.scraper.selectors)
```

**6.4.3 Runtime Behavior**

- Scraper menggunakan `config.scraper.selectors` untuk locate HTML elements
- URLBuilder menggunakan `config.urlPatterns` untuk construct URLs
- SearchHandler menggunakan `config.searchConfig` untuk build query
- Feature Manager menggunakan `config.features` untuk enable/disable functionality

### 6.5 Pemetaan Konfigurasi ke Business Logic

| Business Requirement        | Config Section                          | Technical Implementation         |
|-----------------------------|-----------------------------------------|----------------------------------|
| Ekstraksi List Homepage     | `scraper.selectors.latest`              | Parse container items            |
| Ekstraksi Search Results    | `scraper.selectors.search`              | Parse search result items        |
| Ekstraksi Detail Metadata   | `scraper.selectors.detail`              | Parse series info fields         |
| Ekstraksi Chapter List      | `scraper.selectors.detail.chapterList`  | Iterate chapter links            |
| Ekstraksi Gambar Reader     | `scraper.selectors.reader.images`       | Extract image URLs in sequence   |
| Simple Search               | `searchConfig.searchMode: "query-param"`| Build URL dengan `?s={query}`    |
| Pagination Homepage         | `urlPatterns.page`                      | Generate `/page/{num}/`          |
| Pagination Search           | `urlPatterns.searchPaginated`           | Generate `/page/{num}/?s={q}`    |

---

## 7. Spesifikasi Konfigurasi `komiktap-config.json`

Berikut adalah spesifikasi detail untuk file konfigurasi.

### 7.1 Root Level Fields

```json
{
  "source": "komiktap",
  "version": "1.0.0",
  "lastUpdated": "2026-01-25T20:30:00+07:00",
  "baseUrl": "https://komiktap.info",
  ...
}
```

| Field          | Type   | Required | Description                                  |
|----------------|--------|----------|----------------------------------------------|
| `source`       | string | Yes      | Unique identifier untuk source ("komiktap")  |
| `version`      | string | Yes      | Semantic version untuk config format         |
| `lastUpdated`  | string | Yes      | Timestamp ISO 8601 last update konfigurasi   |
| `baseUrl`      | string | Yes      | Base URL website tanpa trailing slash        |

### 7.2 Search Configuration

**Perbedaan dengan Crotpedia:**
- Crotpedia: `"searchMode": "form-based"` dengan advanced fields (title, author, artist, year)
- KomikTap: `"searchMode": "query-param"` dengan simple keyword search

```json
{
  "searchConfig": {
    "searchMode": "query-param",
    "endpoint": "/",
    "paramName": "s",
    "placeholder": "Search comics...",
    "sortingConfig": {
      "allowDynamicReSort": false,
      "widgetType": "readonly"
    },
    "pagination": {
      "urlPattern": "/page/{page}/",
      "paramName": "page"
    }
  }
}
```

| Field                              | Type    | Description                                              |
|------------------------------------|---------|----------------------------------------------------------|
| `searchMode`                       | string  | `"query-param"` untuk simple search                      |
| `endpoint`                         | string  | URL endpoint untuk search (`/` atau `/?s={query}`)       |
| `paramName`                        | string  | Nama parameter query string (`s`)                        |
| `placeholder`                      | string  | Placeholder text untuk search input UI                   |
| `sortingConfig.allowDynamicReSort` | boolean | Apakah user bisa ubah sorting (false untuk KomikTap)     |
| `sortingConfig.widgetType`         | string  | `"readonly"` jika tidak ada sorting options              |
| `pagination.urlPattern`            | string  | Template URL untuk pagination dengan search              |
| `pagination.paramName`             | string  | Nama parameter halaman (`page`)                          |

**Note:**
- Tidak perlu `textFields`, `radioGroups`, `checkboxGroups` seperti Crotpedia karena simple search
- Jika KomikTap memiliki pra-defined sorting (misal: Latest, Popular), tambahkan `sortingConfig.options[]`

### 7.3 Scraper Selectors

Definisi CSS selectors untuk ekstraksi elemen HTML.

**Format Umum:**
```json
{
  "scraper": {
    "enabled": true,
    "selectors": {
      "latest": { ... },
      "search": { ... },
      "detail": { ... },
      "reader": { ... },
      "pagination": { ... }
    }
  }
}
```

#### 7.3.1 Latest (Homepage List)

```json
{
  "latest": {
    "container": "[CSS_SELECTOR_FOR_ITEM_CONTAINER]",
    "link": "[CSS_SELECTOR_FOR_DETAIL_LINK]",
    "cover": "[CSS_SELECTOR_FOR_THUMBNAIL_IMG]",
    "title": "[CSS_SELECTOR_FOR_TITLE_TEXT]",
    "rating": "[CSS_SELECTOR_FOR_RATING]",
    "latestChapter": "[CSS_SELECTOR_FOR_LATEST_CHAPTER]"
  }
}
```

**Contoh (假设 - perlu validasi dari actual HTML):**
```json
{
  "latest": {
    "container": ".manga-item",
    "link": "a.manga-link",
    "cover": ".manga-thumb img",
    "title": ".manga-title",
    "rating": ".manga-rating span",
    "latestChapter": ".latest-chapter"
  }
}
```

#### 7.3.2 Search (Search Results)

Struktur identik dengan `latest` jika layout sama, atau custom jika berbeda:

```json
{
  "search": {
    "container": "[CSS_SELECTOR_FOR_SEARCH_ITEM]",
    "link": "[...]",
    "cover": "[...]",
    "title": "[...]"
  }
}
```

#### 7.3.3 Detail (Series Detail Page)

```json
{
  "detail": {
    "title": "[CSS_SELECTOR_FOR_SERIES_TITLE]",
    "alternativeTitles": "[CSS_SELECTOR_FOR_ALT_TITLES]",
    "cover": "[CSS_SELECTOR_FOR_COVER_IMG]",
    "status": "[CSS_SELECTOR_FOR_STATUS]",
    "author": "[CSS_SELECTOR_FOR_AUTHOR]",
    "artist": "[CSS_SELECTOR_FOR_ARTIST]",
    "rating": "[CSS_SELECTOR_FOR_RATING]",
    "genres": "[CSS_SELECTOR_FOR_GENRE_TAGS]",
    "synopsis": "[CSS_SELECTOR_FOR_SYNOPSIS]",
    "chapterList": "[CSS_SELECTOR_FOR_CHAPTER_LIST_CONTAINER]",
    "chapterLink": "[CSS_SELECTOR_FOR_CHAPTER_LINK_WITHIN_ITEM]",
    "chapterTitle": "[CSS_SELECTOR_FOR_CHAPTER_TITLE]",
    "chapterDate": "[CSS_SELECTOR_FOR_CHAPTER_DATE]"
  }
}
```

**Notes:**
- Jika ada info list (`Type`, `Views`, dll.) yang dalam format `<li><b>Label:</b> <span>Value</span>`, bisa tambahkan:
  ```json
  "infoList": "selector_for_li_items",
  "infoLabel": "selector_for_label",
  "infoValue": "selector_for_value"
  ```

#### 7.3.4 Reader (Chapter Page)

```json
{
  "reader": {
    "container": "[CSS_SELECTOR_FOR_READER_CONTAINER]",
    "images": "[CSS_SELECTOR_FOR_IMAGE_ELEMENTS]",
    "prevChapter": "[CSS_SELECTOR_FOR_PREV_LINK]",
    "nextChapter": "[CSS_SELECTOR_FOR_NEXT_LINK]"
  }
}
```

**Contoh:**
```json
{
  "reader": {
    "container": "#chapter-reader",
    "images": "#chapter-reader img.page-image",
    "prevChapter": "a.prev-chapter",
    "nextChapter": "a.next-chapter"
  }
}
```

#### 7.3.5 Pagination

```json
{
  "pagination": {
    "current": "[CSS_SELECTOR_FOR_CURRENT_PAGE_NUMBER]",
    "next": "[CSS_SELECTOR_FOR_NEXT_PAGE_LINK]",
    "previous": "[CSS_SELECTOR_FOR_PREV_PAGE_LINK]",
    "links": "[CSS_SELECTOR_FOR_ALL_PAGE_LINKS]"
  }
}
```

### 7.4 URL Patterns

Template URL menggunakan placeholder `{parameter}` yang akan digantikan dengan value actual.

```json
{
  "urlPatterns": {
    "home": "/",
    "page": "/page/{num}/",
    "seriesDetail": "/manga/{slug}/",
    "chapterReader": "/{slug}-chapter-{num}/",
    "genre": "/genres/{slug}/",
    "genrePaginated": "/genres/{slug}/page/{num}/",
    "search": "/?s={query}",
    "searchPaginated": "/page/{num}/?s={query}"
  }
}
```

| Pattern              | Parameters         | Example Output                                 |
|----------------------|--------------------|------------------------------------------------|
| `home`               | -                  | `/`                                            |
| `page`               | `num`              | `/page/2/`                                     |
| `seriesDetail`       | `slug`             | `/manga/lets-make-a-deal/`                     |
| `chapterReader`      | `slug`, `num`      | `/lets-make-a-deal-chapter-1/`                 |
| `genre`              | `slug`             | `/genres/comedy/`                              |
| `genrePaginated`     | `slug`, `num`      | `/genres/comedy/page/2/`                       |
| `search`             | `query`            | `/?s=abc`                                      |
| `searchPaginated`    | `num`, `query`     | `/page/2/?s=abc`                               |

**Notes:**
- Semua pattern akan di-prepend dengan `baseUrl` saat runtime
- `{query}` harus di-URL-encode sebelum substitusi

### 7.5 Features

Feature flags untuk enable/disable functionality.

```json
{
  "features": {
    "search": true,
    "random": false,
    "related": false,
    "download": true,
    "favorite": true,
    "chapters": true,
    "bookmark": true,
    "supportsTagExclusion": false,
    "supportsAdvancedSearch": false
  }
}
```

| Feature                    | Type    | Description                                      | KomikTap Value |
|----------------------------|---------|--------------------------------------------------|----------------|
| `search`                   | boolean | Support simple/advanced search                   | `true`         |
| `random`                   | boolean | Support random series feature                    | `false`        |
| `related`                  | boolean | Support related/similar series                   | `false`        |
| `download`                 | boolean | Support download chapters                        | `true`         |
| `favorite`                 | boolean | Support add to favorites                         | `true`         |
| `chapters`                 | boolean | Content memiliki multi-chapter (vs single page)  | `true`         |
| `bookmark`                 | boolean | Support bookmarking reading progress             | `true`         |
| `supportsTagExclusion`     | boolean | Support exclude genre di search                  | `false`        |
| `supportsAdvancedSearch`   | boolean | Support form-based advanced search               | `false`        |

### 7.6 Network Configuration

```json
{
  "network": {
    "timeout": 30000,
    "retry": {
      "maxAttempts": 3,
      "delayMs": 1000,
      "exponentialBackoff": true
    },
    "headers": {
      "User-Agent": "Mozilla/5.0 (compatible; DataExtractor/1.0)"
    }
  }
}
```

| Field                   | Type    | Description                                  | Default        |
|-------------------------|---------|----------------------------------------------|----------------|
| `timeout`               | integer | Request timeout dalam milliseconds           | `30000` (30s)  |
| `retry.maxAttempts`     | integer | Maximum retry attempts untuk failed request  | `3`            |
| `retry.delayMs`         | integer | Initial delay antara retry                   | `1000` (1s)    |
| `retry.exponentialBackoff` | boolean | Use exponential backoff (1s, 2s, 4s, ...)    | `true`         |
| `headers`               | object  | Custom HTTP headers untuk request            | Optional       |

### 7.7 Authentication (Optional)

Jika KomikTap memerlukan login untuk akses konten tertentu:

```json
{
  "auth": {
    "enabled": false,
    "loginEndpoint": null,
    "sessionCookies": [],
    "sessionDurationSeconds": null
  }
}
```

**Notes:**
- Set `enabled: false` jika tidak ada requirement login
- Jika perlu auth, duplicate pattern dari `crotpedia-config.json`

### 7.8 UI Customization

```json
{
  "ui": {
    "displayName": "KomikTap",
    "iconPath": "assets/icons/komiktap.png",
    "themeColor": "#FF6B35",
    "cardStyle": "chapters"
  }
}
```

| Field          | Type   | Description                                      |
|----------------|--------|--------------------------------------------------|
| `displayName`  | string | Display name di UI                               |
| `iconPath`     | string | Path ke icon file (relatif dari project root)   |
| `themeColor`   | string | Hex color code untuk branding                    |
| `cardStyle`    | string | Layout style untuk card (chapters/gallery/list)  |

**Action Item:**
```
✅ Buat icon asset di: assets/icons/komiktap.png
```

---

## 8. Deliverables

### 8.1 Dokumentasi

| No | Deliverable                        | Format | Status       |
|----|------------------------------------|--------|--------------|
| 1  | Business Requirement Document      | .md    | ✅ Draft     |
| 2  | Configuration Schema Specification | .json  | ⏳ To Create |
| 3  | Data Dictionary                    | .md    | ⏳ To Create |
| 4  | Test Case Specification            | .md    | ⏳ To Create |

### 8.2 Konfigurasi

| No | Deliverable                | Path                                | Status       |
|----|----------------------------|-------------------------------------|--------------|
| 1  | KomikTap Config File       | `configs/komiktap-config.json`      | ⏳ To Create |
| 2  | KomikTap Icon Asset        | `assets/icons/komiktap.png`         | ⏳ To Create |

### 8.3 Package Implementation (Out of Scope untuk BRD)

> **Note:** Implementasi teknis package adalah tahap berikutnya setelah BRD diapprove.

| No | Component                   | Path                                     | Status       |
|----|-----------------------------|------------------------------------------|--------------|
| 1  | Package Structure           | `packages/kuron_komiktap/`               | ⏳ Future    |
| 2  | Data Models                 | `packages/kuron_komiktap/lib/models/`    | ⏳ Future    |
| 3  | Scraper Service             | `packages/kuron_komiktap/lib/services/`  | ⏳ Future    |
| 4  | Repository Layer            | `packages/kuron_komiktap/lib/repositories/` | ⏳ Future |
| 5  | Unit Tests                  | `packages/kuron_komiktap/test/`          | ⏳ Future    |

---

## 9. Dependencies & Prerequisites

### 9.1 External Dependencies

| Dependency Type           | Description                                              | Notes                                  |
|---------------------------|----------------------------------------------------------|----------------------------------------|
| Network Access            | Koneksi internet untuk akses `komiktap.info`             | Minimum bandwidth: 1 Mbps              |
| Target Website Stability  | Situs KomikTap harus accessible dan HTML structure stabil | Perubahan HTML = config update needed  |
| Rate Limiting Compliance  | Respect untuk rate limit server (jika ada)               | Implement throttling/cooldown          |

### 9.2 Internal Dependencies

| Component                 | Description                                              | Status       |
|---------------------------|----------------------------------------------------------|--------------|
| `kuron_core` package      | Core framework untuk scraping & parsing                  | ✅ Available |
| Config Loader module      | Module untuk load & parse JSON config                    | ✅ Available |
| Network layer             | HTTP client dengan retry & timeout support               | ✅ Available |
| Data persistence layer    | Storage mechanism (database/file) untuk scraped data     | ✅ Available |

### 9.3 Assumptions

1. **HTML Structure Stability:** Asumsi bahwa struktur HTML KomikTap relatif stabil. Jika ada breaking changes, config perlu di-update.
2. **No CAPTCHA/Bot Protection:** Asumsi bahwa situs tidak menggunakan aggressive bot protection (Cloudflare challenge, CAPTCHA). Jika ada, perlu strategi tambahan.
3. **Public Access:** Asumsi bahwa konten dapat diakses tanpa login. Jika ada konten premium, perlu auth mechanism.
4. **Consistent Pagination:** Asumsi bahwa pagination menggunakan pola URL yang konsisten (`/page/{N}/`).

---

## 10. Risks & Mitigations

### 10.1 Technical Risks

| Risk                                  | Impact | Probability | Mitigation Strategy                                              |
|---------------------------------------|--------|-------------|------------------------------------------------------------------|
| Website HTML structure berubah        | High   | Medium      | Implement config validation & monitoring; quick config update     |
| Rate limiting / IP blocking           | High   | Medium      | Implement throttling, exponential backoff, respect robots.txt     |
| Dynamic content rendering (JavaScript)| High   | Low         | Evaluate jika perlu headless browser solution                    |
| Inconsistent data format              | Medium | Medium      | Robust parsing dengan fallback & validation                      |
| Broken links / 404 errors             | Low    | High        | Implement error handling & skip mechanism                        |

### 10.2 Business Risks

| Risk                                  | Impact | Probability | Mitigation Strategy                                              |
|---------------------------------------|--------|-------------|------------------------------------------------------------------|
| Copyright/Legal issues                | High   | Low         | Clarify usage rights & terms of service compliance               |
| Data quality tidak memenuhi ekspektasi| Medium | Medium      | Implement comprehensive validation & QA process                  |
| Performa ekstraksi terlalu lambat     | Medium | Low         | Optimize scraping logic, parallel processing jika applicable     |
| Requirement changes mid-project       | Medium | Medium      | Agile approach, iterative development dengan frequent review     |

### 10.3 Operational Risks

| Risk                                  | Impact | Probability | Mitigation Strategy                                              |
|---------------------------------------|--------|-------------|------------------------------------------------------------------|
| Maintenance overhead untuk config     | Medium | Medium      | Documentation, version control untuk config changes              |
| Dependency pada struktur situs        | High   | High        | Monitoring system untuk detect HTML changes                      |
| Scalability issues saat growth        | Medium | Low         | Design untuk horizontal scaling dari awal                        |

---

## 11. Timeline & Milestones

> **Note:** Timeline ini adalah estimasi high-level untuk perencanaan bisnis.

### Phase 1: Planning & Design (Current)
- ✅ **Week 1:** BRD Creation & Review
- ⏳ **Week 1:** Config Schema Design
- ⏳ **Week 1:** Stakeholder Approval

### Phase 2: Development (Future)
- ⏳ **Week 2-3:** Package Scaffolding & Core Logic
- ⏳ **Week 3:** Scraper Implementation
- ⏳ **Week 3-4:** Data Models & Repository Layer

### Phase 3: Testing & Validation (Future)
- ⏳ **Week 4:** Unit Testing
- ⏳ **Week 4-5:** Integration Testing dengan Sample Data
- ⏳ **Week 5:** QA & Bug Fixes

### Phase 4: Deployment & Monitoring (Future)
- ⏳ **Week 6:** Production Deployment
- ⏳ **Week 6+:** Monitoring & Maintenance

---

## 12. Approval & Sign-Off

| Stakeholder         | Role                          | Approval Status | Date       | Notes |
|---------------------|-------------------------------|-----------------|------------|-------|
| Product Owner       | Business Requirements Owner   | ⏳ Pending      | -          | -     |
| Tech Lead           | Technical Architecture Review | ⏳ Pending      | -          | -     |
| Data Engineering    | Data Schema & Quality Review  | ⏳ Pending      | -          | -     |
| QA Lead             | Test Strategy Review          | ⏳ Pending      | -          | -     |

---

## 13. Appendix

### 13.1 Glossary

| Term                  | Definition                                                                 |
|-----------------------|---------------------------------------------------------------------------|
| **Parent-Child**      | Relasi hierarkis dimana Series Detail (Parent) berisi Chapter (Child)     |
| **Slug**              | URL-friendly identifier (lowercase, dash-separated)                       |
| **Scraper**           | Modul yang mengekstrak data dari HTML                                     |
| **Selector**          | CSS/XPath expression untuk locate elemen di DOM                           |
| **Pagination**        | Navigasi multi-halaman untuk list content                                 |
| **Sequence**          | Urutan numerik (1, 2, 3, ...) untuk preservasi order                      |
| **Fallback Value**    | Nilai default jika data tidak tersedia                                    |
| **Technology Agnostic**| Design yang tidak terikat pada teknologi implementasi spesifik           |

### 13.2 Reference Documents

| Document                  | Path/URL                                                   | Purpose                  |
|---------------------------|------------------------------------------------------------|--------------------------|
| Crotpedia Config          | `configs/crotpedia-config.json`                            | Reference pattern        |
| App Config                | `configs/app-config.json`                                  | Global config structure  |
| Kuron Core Package        | `packages/kuron_core/`                                     | Core framework reference |

### 13.3 Contact Information

| Role                      | Name                  | Contact                       |
|---------------------------|-----------------------|-------------------------------|
| BRD Author                | Senior Business Analyst | [Your Contact]              |
| Technical Reviewer        | [To Be Assigned]      | -                             |
| Product Owner             | [To Be Assigned]      | -                             |

---

## 14. Revision History

| Version | Date       | Author                  | Changes                                        |
|---------|------------|-------------------------|------------------------------------------------|
| 1.0.0   | 2026-01-25 | Senior Business Analyst | Initial draft untuk review                     |

---

**End of Document**
