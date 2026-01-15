# 🔧 **Additional Dynamic Configuration Opportunities**

Analisis terhadap `app_constants.dart`, `ui_constants.dart`, dan file utility lainnya mengungkap ratusan nilai yang saat ini statis. Berikut list lengkap peluang eksternalisasi.

---

## 📊 **1. Limits & Performance Tuning (`AppLimits`)**
Optimalkan app performance tanpa update binary.
- `defaultPageSize`: [20] -> Bantu kurangi beban server.
- `maxBatchSize`: [1000] -> Batasan sinkronisasi tag.
- `maxConcurrentDownloads`: [3] -> Cegah pemblokiran IP oleh server.
- `searchHistoryLimit`: [50] -> UX cleanup.
- `imagePreloadBuffer`: [5] -> Seberapa banyak gambar di-preload saat reading.
- `maxCacheSizeMb`: [500] -> Auto-purge threshold.

## ⏱️ **2. Timeouts & Durations (`AppDurations`)**
Kontrol user experience dan network resilience.
- `splashDelayMs`: [1000] -> Kontrol branding time.
- `snackbarShortMs`: [2000]
- `snackbarLongMs`: [4000]
- `pageTransitionMs`: [300] -> Harmonisasi animasi.
- `searchDebounceMs`: [300] -> Kurangi beban API saat user mengetik cepat.
- `networkTimeoutMs`: [30000] -> Tingkatkan untuk regional internet lambat.
- `cacheExpirationMs`: [86400000] (24h) -> TTL untuk config sync.
- `readerAutoHideDelayMs`: [3000] -> Kontrol overlay UI di reader.

## 🎨 **3. UI & Layout Parameters (`AppUI`)**
Berikan fleksibilitas desain tanpa perlu CSS/Theme rebuild.
- `gridColumnsPortrait`: [2] -> Ubah ke 3 jika resolusi HP semakin tinggi.
- `gridColumnsLandscape`: [3] -> Ubah ke 4 atau 5.
- `minCardWidth`: [150.0] -> Threshold adaptive grid.
- `cardAspectRatio`: [0.65] -> Penting untuk uniform display.
- `cardBorderRadius`: [12.0] -> Modernize look OTA.
- `defaultPadding`: [16.0]
- `titleMaxLength`: [40] -> Pencegahan text overflow.

## 💾 **4. Storage & Filesystem (`AppStorage`)**
- `backupFolderName`: ["nhasix"]
- `metadataFileName`: ["metadata.json"]
- `imagesSubfolder`: ["images"]
- `maxImageSizeKb`: [200] -> Ambang batas kompresi otomatis.
- `pdfPartsSizePages`: [100] -> Membagi PDF besar menjadi part agar tidak OOM (Out Of Memory).

## 🛡️ **5. Privacy & Analytics Config**
- `enableAnalytics`: [false] -> Nonaktifkan secara global jika ada isu privasi.
- `anonymizeIp`: [true]
- `historyAutoClean`: [true]
- `retentionDays`: [30] -> Berapa lama history lokal disimpan.

## 🚀 **6. Download & Cache Strategy**
- `wifiOnlyDownload`: [false] -> Override user settings jika ada promo data.
- `retryOnNetworkSwitch`: [true]
- `autoResumeDownloads`: [true]
- `compressionQuality`: [85] -> Jpeg compression quality.

---

## 🏷️ **Prioritas Implementasi**

1. **High Priority (Week 3)**: `AppLimits` & `NetworkTimeouts` - Efek langsung ke stabilitas app.
2. **Medium Priority (Week 4)**: `AppUI` & `AppDurations` - Tuning kenyamanan user.
3. **Low Priority (Week 5)**: `AppStorage` & `DownloadStrategy` - Edge cases.
