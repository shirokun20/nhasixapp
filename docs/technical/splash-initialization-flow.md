# NhasixApp Splash Screen Initialization Flow (Deep Dive)

Dokumen ini menjelaskan alur **Splash Screen** secara mendalam, termasuk URL API yang di-hit, file yang di-download, dan logika inisialisasi yang terjadi di balik layar.

## � Endpoint & Resources
*   **Base URL (Prod)**: `https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@configs/configs`
*   **Base URL (Debug)**: `https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs`

## � Flow Diagram (Step-by-Step)

### 1. 🏁 Splash Start (`SplashBloc`)
*   **Trigger**: Aplikasi dibuka.
*   **Logic**: Cek `SharedPreferences` key `config_cache_app`.
    *   **KOSONG (Cache Miss)** → Mode **Fresh Install**.
    *   **ADA (Cache Hit)** → Mode **Normal Run**.

### 2. 📥 Remote Config Sync (`RemoteConfigService`)
Jika **Fresh Install** (atau ada update di background):

1.  **Hit Manifest** (GET `.../version.json`):
    *   Mendapatkan daftar versi semua file config.
    *   *Tujuannya*: Mengetahui apakah ada config yang perlu di-update.

2.  **Hit Configs** (Parallel Download):
    *   GET `.../nhentai-config.json` → Berisi `api: { enabled: true }`.
    *   GET `.../crotpedia-config.json`
    *   GET `.../app-config.json`
    *   GET `.../tags-config.json` → Berisi mapping lokasi file tag.
    *   *Hasil*: Semua JSON disimpan ke `SharedPreferences`.

### 3. 🏷️ Tag Initialization (`TagDataManager`)
*   **Input**: `tags-config.json` (yang baru saja didownload/dicache).
*   **Path Check**: Config menunjuk ke `configs/tags/tags_nhentai.json`.
*   **Logic Load**:
    1.  Cek file di `ApplicationDocumentsDirectory/tags_nhentai.json` (Versi download).
    2.  Jika tidak ada, load dari **Asset APK**: `assets/configs/tags/tags_nhentai.json`.
        *   *Efisiensi*: Karena file ini sudah ada di dalam APK (bundling), tidak ada download 5MB yang terjadi di sini. Instant load.

### 4. 🌐 Connectivity & Bypass (`RemoteDataSource`)
1.  **Check Internet**: `Connectivity().checkConnectivity()`.
2.  **Init Data Source**:
    *   Baca `nhentai-config.json` dari memori.
    *   **IF `api.enabled` == true**:
        *   Set flag `_useApi = true`.
        *   Buat instance `NhentaiApiClient` baru.
        *   *Note*: Scraper tetap disiapkan sebagai cadangan (fallback).
3.  **Bypass Cloudflare**:
    *   **Hit**: `HEAD https://nhentai.net`
    *   **Tujuannya**: Mendapatkan cookies `csrftoken` dan `sessionid` yang valid agar image bisa di-load. Tanpa ini, gambar akan 403 Forbidden.

### 5. 🏠 Home Page Load (`ContentListWidget`)
Setelah Splash sukses:

1.  UI memanggil `ContentBloc.loadContent(page: 1)`.
2.  Repository memanggil `RemoteDataSource.getContentList(page: 1)`.
3.  **Execution Branch**:
    *   Karena `_useApi` = true dan `apiClient` != null:
    *   **Hit API**: `GET https://nhentai.net/api/galleries/all?page=1`
    *   **Response**: JSON (berisi metadata lengkap: english title, tags, page count).
    *   **Mapping**: JSON → `ContentModel`.
4.  **Display**: Halaman tampil dengan data lengkap.

---

## ⚠️ Poin Kritis

1.  **Scraper vs API**:
    *   Config di Github (`nhentai-config.json`) adalah SAKLAR UTAMA.
    *   Ubah `api: { enabled: false }` di Github -> Aplikasi otomatis pakai Scraper di restart berikutnya.
    *   Ubah `api: { enabled: true }` di Github -> Aplikasi otomatis pakai API.

2.  **Tag Asset**:
    *   Kunci keberhasilan tanpa download besar adalah file `assets/configs/tags/tags_nhentai.json` yang harus valid di dalam APK.

3.  **Fallback**:
    *   Jika API down (error 500/timeout), aplikasi akan otomatis mencoba pakai Scraper untuk request tersebut (jika fallback enabled).
