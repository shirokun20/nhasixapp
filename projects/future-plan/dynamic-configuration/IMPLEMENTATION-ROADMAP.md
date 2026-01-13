# 🗺️ **Comprehensive Implementation Roadmap**

Strategi implementasi untuk transisi dari **Static Configuration** ke **Dynamic Remote-First Configuration**.

---

## 🏗️ **Strategic Approach**

Kami memilih **Gradual Hybrid Migration (Option B)**:
1.  **Safety First**: Selalu simpan bundled asset JSON di dalam APK sebagai fallback terakhir.
2.  **Staged Rollout**: Migrasikan nhentai dulu (paling kritikal), baru kemudian Crotpedia dan App Constants.
3.  **Low Impact**: Konfigurasi UI dan Durations diaplikasikan secara reaktif jika memungkinkan.

---

## 📅 **Timeline & Phase Breakdown**

### **Phase 1: Foundation & Infrastructure (Week 1-2)**
Fokus pada pembuatan "pipa" pengiriman data.
- [ ] **RemoteConfigService Implementation**: Singleton service menggunakan Dio.
- [ ] **Cache Layer**: Implementasi Hive/SharedPrefs untuk menyimpan JSON yang diunduh.
- [ ] **Version Checking**: Logika perbandingan `localVersion` vs `remoteVersion` (dari `version.json`).
- [ ] **Silent Sync**: Sinkronisasi dilakukan secara background saat startup tanpa mengunci UI.

### **Phase 2: Models & Type-Safe Access (Week 2-3)**
Pencegahan error runtime akibat salah baca JSON.
- [ ] **JsonSerializable Models**: Class Dart untuk setiap file config.
- [ ] **Schema Validation**: Validasi wajib sebelum data di-persist ke cache.
- [ ] **GetIt Integration**: Menyediakan instance config secara global via Dependency Injection.

### **Phase 3: Network & Scraper Integration (Week 3-4)**
Ini adalah fase yang memberikan nilai paling tinggi bagi stabilitas app.
- [ ] **Dynamic API Endpoints**: Migrasi `nhentaiApiBase` dan `mirrors` di `api_config.dart`.
- [ ] **Dynamic Selectors**: Update `kuron_nhentai` dan `kuron_crotpedia` untuk membaca selektor dari service.
- [ ] **Mirror Failover Logic**: Jika domain utama mati (404/503), otomatis coba mirror berikutnya dari config.

### **Phase 4: Constants & Tag Optimization (Week 4-5)**
Finalisasi dan optimasi performa.
- [ ] **Constant Replacement**: Ganti nilai statis di `AppLimits`, `AppDurations`, dll.
- [ ] **Tag Sync (The Big Win)**: Pindah `tags.json` ke remote. Gunakan Gzip compression.
    - *Guna*: Mengurangi ukuran download aplikasi sebesar ~4MB.
- [ ] **Cleanup**: Hapus class-class konstanta yang sudah tidak digunakan.

---

## 📉 **Success Metrics & KPIs**

### **SLA (Service Level Agreement)**
- **Sync Latency**: Pengecekan versi harus < 500ms.
- **Payload Size**: `version.json` harus < 1KB, configs lain < 5KB (gzipped).
- **Graceful Failure**: Jika CDN down, user tidal boleh menyadari isu apapun (auto-fallback to bundled).

### **User Experience Metrics**
- **App Update Frequency**: Target pengurangan update aplikasi sebesar 50% karena perbaikan bug scraper/URL bisa dilakukan via OTA.
- **Install Size**: Penurunan ukuran APK (karena tag data tidak lagi dibundel secara paksa).

---

## 🛠️ **Testing Protocol**

1.  **Scenario: Offline Launch**
    - Tutup internet, buka aplikasi.
    - Pastikan app menggunakan cache terakhir atau bundled asset.
2.  **Scenario: Invalid JSON Update**
    - Sengaja buat error di GitHub (e.g. hapus tanda kutip).
    - Pastikan app me-reject update tersebut dan tidak crash.
3.  **Scenario: Heavy Load Sync**
    - Pastikan sync background tidak menyebabkan lag pada frame UI (60 FPS maintained).
