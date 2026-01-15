# 🏗️ **Dynamic Configuration System: Deep Technical Analysis & Design**

## 1. **Executive Summary**
Project NhasixApp saat ini menghadapi tantangan skalabilitas dan pemeliharaan karena banyaknya konfigurasi kritikal yang di-hardcode di dalam binary aplikasi. Setiap kali nhentai mengubah selektor HTML, API endpoint, atau ketika mirror server baru muncul, aplikasi harus melalui siklus rebuild, testing, dan deployment ke App Store/Play Store yang memakan waktu (2-7 hari).

Dokumen ini mengusulkan transisi ke **Dynamic Configuration System** berbasis JSON yang dihosting di GitHub dan disajikan melalui CDN, memungkinkan update konfigurasi secara "Over-The-Air" (OTA) tanpa update aplikasi.

---

## 2. **Current State: The "Hardcode" Bottleneck**
Berdasarkan audit mendalam terhadap codebase, ditemukan ketergantungan statis pada area berikut:
- **API Endpoints**: `nhentaiApiBase`, `crotpediaBaseUrl` di `api_config.dart`.
- **Scraper Selectors**: Selektor CSS di `kuron_nhentai` dan `kuron_crotpedia`.
- **Image URL Patterns**: Logika penyusunan URL gambar yang kaku.
- **App Constants**: `AppLimits`, `AppDurations`, dan `AppUI` di `app_constants.dart`.
- **Tag Data**: `tags.json` seberat 5.17MB yang dipaketkan sebagai asset statis.

---

## 3. **Proposed Architecture: GitHub-Based Remote Config**

Sistem ini akan memanfaatkan ekosistem open-source untuk reliabilitas tinggi tanpa biaya operasional.

### **3.1 Backend: GitHub + jsdelivr CDN**
- **Repository**: `shirokun20/nhasixapp` (atau repo config terpisah).
- **Storage**: Konfigurasi disimpan sebagai file `.json`.
- **Delivery**: Akses melalui `https://cdn.jsdelivr.net/gh/{user}/{repo}@{branch}/configs/{file}.json`.
- **Keuntungan**:
    - **Global Cache**: CDN jsdelivr memiliki 100+ lokasi edge.
    - **Compression**: Otomatis mendukung Gzip/Brotli.
    - **Versioned**: Bisa mem-pin versi config ke branch atau commit hash tertentu.
    - **Free**: Tidak ada biaya hosting.

### **3.2 Frontend: RemoteConfigService (Flutter)**
Service baru di `lib/core/services/` yang mengatur siklus hidup konfigurasi:
1. **Sync Phase**: Mengunduh `version.json` saat startup untuk cek beda versi.
2. **Download Phase**: Mengunduh file config yang berubah (diff-based).
3. **Persist Phase**: Menyimpan JSON di `ApplicationDocumentsDirectory`.
4. **Load Phase**: Menyediakan data ke UI dan Logic melalui model Dart yang type-safe.
5. **Fallback Phase**: Jika gagal sync (offline), gunakan cache lokal. Jika cache tidak ada, gunakan bundled asset "Safe Defaults".

---

## 4. **Detailed Config Schema Definitions**

### **4.1 version.json (The Manifest)**
```json
{
  "version": "1.0.0",
  "minimumAppVersion": "0.7.0",
  "configs": {
    "nhentai": { "version": "1.0.2", "path": "nhentai-config.json" },
    "crotpedia": { "version": "1.0.0", "path": "crotpedia-config.json" },
    "app": { "version": "1.0.5", "path": "app-config.json" }
  },
  "forceUpdate": false,
  "changelog": [
    { "version": "1.0.2", "changes": ["Fix nhentai cover selector", "Add mirror support"] }
  ]
}
```

### **4.2 nhentai-config.json**
Mengintegrasikan meta-data untuk API dan Scraper.
```json
{
  "api": {
    "baseUrl": "https://nhentai.net",
    "apiBase": "https://nhentai.net/api",
    "endpoints": {
      "galleryDetail": "/api/gallery/{id}",
      "search": "/api/galleries/search?query={q}&page={page}"
    },
    "mirrors": ["https://nhentai.xxx", "https://nhentai.to"],
    "extensionMapping": { "j": "jpg", "p": "png", "w": "webp" }
  },
  "scraper": {
    "selectors": {
      "homepage": ".index-container .gallery",
      "detailTitle": "#info h1"
    }
  }
}
```

---

## 5. **Implementation Guide: Step-by-Step**

### **Step 1: GitHub Repository Setup**
1. Buat folder `configs/` di branch `master`.
2. Push semua file JSON (nhentai, crotpedia, app, version).
3. Pastikan repo publik agar bisa diakses CDN.

### **Step 2: Flutter Infrastructure**
Implementasikan `RemoteConfigService` menggunakan `Dio` untuk download dan `SharedPreference` atau `Hive` untuk version tracking.

### **Step 3: Model Generation**
Gunakan `json_serializable` untuk membuat class model dari JSON agar akses data tidak melalui `Map<String, dynamic>` yang rawan typo.

---

## 6. **Mirror Server Strategy**
Jika domain utama (`nhentai.net`) diblokir di wilayah tertentu:
1. Admin update `nhentai-config.json` → tambahkan mirror baru di array `mirrors`.
2. Admin set `useMirrors: true`.
3. Aplikasi akan sync config secara background.
4. Request berikutnya otomatis menggunakan mirror server tanpa intervensi user.

---

## 7. **Security & Validation**
- **MITM Attack**: Selalu gunakan HTTPS (Enforced by jsdelivr).
- **Validation**: Lakukan `try-catch` saat parsing JSON. Jika struktur tidak valid (akibat typo saat editing di GitHub), aplikasi **WAJIB** menolak config tersebut dan tetap menggunakan cache lama atau bundled asset.
- **Checksum**: Opsional, tambahkan field `sha256` di `version.json` untuk verifikasi integritas file.

---

## 8. **Cost & Performance Analysis**
- **Hosting Cost**: $0 (GitHub + jsdelivr).
- **Latency**: 50ms - 200ms (Edge caching).
- **User Impact**: Mengurangi konsumsi data dengan Gzip compression pada file `tags.json` di masa depan (dari 5MB menjadi <1MB).

---

## 9. **Monitoring & Analytics**
Tambahkan event tracking untuk memonitor:
- `config_sync_success`
- `config_sync_failed` (dengan error message)
- `config_version_mismatch`
- `fallback_activated`

---

## 10. **Troubleshooting Flow**
1. User melapor "Search nhentai error".
2. Admin cek selektor HTML di nhentai web.
3. Admin update selektor di `nhentai-config.json` via GitHub Web.
4. Admin naikkan versi di `version.json`.
5. User reload app → Config tersync → Search berfungsi kembali secara ajaib.
