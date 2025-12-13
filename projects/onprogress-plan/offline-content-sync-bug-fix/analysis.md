# Investigasi & Analisis Bug Kritis: Offline Content, Downloads, Sync Flow

## Tanggal Investigasi
2025-12-13

---

## 🔍 Ringkasan Masalah

Terdapat **3 bug kritis** yang saling berkaitan pada alur offline content, sync, dan data persistence:

1. **BUG 1**: Delete tidak berfungsi di `offline_content_screen.dart` ketika file ada di filesystem tapi tidak ada di DB
2. **BUG 2**: Data sync tidak konsisten (offline = 219 item, downloads = ~20 item)
3. **BUG 3**: Clear app data → State rusak (folder lokal masih ada, DB kosong, sync tidak rebuild)

---

## 📊 Hasil Analisis Root Cause

### Data Sources Overview

| Screen | Data Source | Query Method |
|--------|-------------|--------------|
| `offline_content_screen.dart` | **DB first**, fallback filesystem | `OfflineSearchCubit.getAllOfflineContent()` → `UserDataRepository.getAllDownloads(state: completed, limit: 1000)` |
| `downloads_screen.dart` | **DB only** | `DownloadBloc._onRefresh()` → `UserDataRepository.getAllDownloads()` (no limit, all states) |

### 🐛 BUG 1: Delete Tidak Jalan

**Root Cause yang Teridentifikasi:**

1. **`deleteOfflineContent()` di `offline_content_manager.dart` (line 1117-1165)**:
   ```dart
   Future<bool> deleteOfflineContent(String contentId, {String? contentPath}) async {
     // Line 1126-1129: EARLY RETURN jika path tidak ditemukan
     if (pathToDelete == null) {
       _logger.w('Content path not found for $contentId');
       return false;  // ⚠️ MASALAH: Return false tanpa coba hapus filesystem
     }
   }
   ```

2. **`getOfflineContentPath()` bergantung pada DB**:
   - Jika content ID tidak ada di DB, path tidak ditemukan
   - Delete tidak akan terjadi meskipun file fisik ada

3. **Flow Delete dari UI:**
   ```
   _deleteContent() 
   → extract contentPath dari imageUrls 
   → deleteOfflineContent(contentId, contentPath: contentPath)
   ```
   - **Masalah**: Jika `content.imageUrls` kosong atau path extraction gagal, delete juga gagal

**Solusi yang Diperlukan:**
- Scan filesystem untuk menemukan folder berdasarkan contentId sebagai fallback
- Jangan return false hanya karena DB record tidak ada
- Implementasi idempotent delete: DB ada → hapus DB + file, DB tidak ada → tetap hapus file

---

### 🐛 BUG 2: Data Sync Tidak Konsisten

**Root Cause yang Teridentifikasi:**

1. **Query Berbeda:**
   - `OfflineSearchCubit.getAllOfflineContent()`:
     ```dart
     final downloads = await _userDataRepository.getAllDownloads(
       state: DownloadState.completed,  // ✅ Filter completed only
       limit: 1000,                      // ⚠️ Ada limit
     );
     ```
   - `DownloadBloc._onRefresh()`:
     ```dart
     final downloads = await _userDataRepository.getAllDownloads();  // ❌ No state filter, no limit
     ```

2. **Perbedaan State Filter:**
   - Offline screen: hanya `completed`
   - Downloads screen: **semua state** (queued, downloading, paused, failed, completed, cancelled)

3. **`syncBackupToDatabase()` hanya menambahkan completed items:**
   ```dart
   final status = DownloadStatus.completed(
     content.id,
     content.pageCount,
     contentDir ?? '',
     fileSize,
   );
   ```

**Solusi yang Diperlukan:**
- Pastikan kedua screen menggunakan filter yang sama untuk perbandingan
- Downloads screen filter "Completed" tab = Offline screen count
- Sync harus memastikan semua item filesystem masuk DB dengan status `completed`

---

### 🐛 BUG 3: Clear App Data → State Rusak

**Root Cause yang Teridentifikasi:**

1. **Tidak ada mekanisme auto-rebuild DB dari filesystem saat startup**
2. **`offline_content_screen.dart` initState:**
   ```dart
   @override
   void initState() {
     super.initState();
     _offlineSearchCubit = getIt<OfflineSearchCubit>();
     // Load from database (database-first approach)
     _offlineSearchCubit.getAllOfflineContent();
   }
   ```
   - Jika DB kosong → fallback ke filesystem di `_loadFromFileSystem()`
   - **TAPI** data tidak di-sync ke DB secara otomatis

3. **Sync Button hanya dipanggil manual:**
   - User harus klik sync manually
   - Tidak ada auto-detect DB kosong + folder ada

4. **`getAllOfflineContent()` fallback logic:**
   ```dart
   if (downloads.isEmpty) {
     // Fallback to file scan if database is empty
     await _loadFromFileSystem(backupPath);  // ✅ Load tampil di UI
     return;  // ❌ TAPI tidak sync ke DB!
   }
   ```

**Solusi yang Diperlukan:**
- Auto-detect: jika DB kosong tapi filesystem ada → auto re-index
- Setelah `_loadFromFileSystem()`, otomatis sync ke DB
- Atau: di app start, panggil `syncBackupToDatabase()` jika DB empty

---

## 📁 File-File Kunci yang Terlibat

| File | Peran |
|------|-------|
| `lib/presentation/pages/offline/offline_content_screen.dart` | UI offline content, flow delete |
| `lib/presentation/pages/downloads/downloads_screen.dart` | UI downloads, TabBar dengan filter states |
| `lib/presentation/cubits/offline_search/offline_search_cubit.dart` | Cubit untuk search/load offline content |
| `lib/core/utils/offline_content_manager.dart` | Manager untuk scan, delete, sync |
| `lib/presentation/blocs/download/download_bloc.dart` | BLoC untuk download queue dan state |
| `lib/domain/repositories/user_data_repository.dart` | Interface repository |
| `lib/data/repositories/user_data_repository_impl.dart` | Implementasi repository |
| `lib/data/datasources/local/local_data_source.dart` | Query database |
| `lib/core/utils/directory_utils.dart` | Utility untuk path detection |

---

## 🎯 Action Items untuk Perbaikan

### BUG 1 Fix:
1. Modifikasi `deleteOfflineContent()`:
   - Jika `contentPath` null, coba scan filesystem berdasarkan contentId
   - Hapus folder filesystem terlebih dahulu, baru coba hapus DB
   - Return true jika salah satu berhasil (filesystem atau DB)

### BUG 2 Fix:
1. Verifikasi bahwa `syncBackupToDatabase()` benar-benar insert semua item
2. Pastikan tidak ada duplikasi yang di-skip
3. Setelah sync, `downloads_screen.dart` harus refresh dan menampilkan completed count yang sama

### BUG 3 Fix:
1. Tambahkan auto-sync setelah `_loadFromFileSystem()` di cubit
2. Atau: di app startup (splash), detect DB empty + folder ada → auto sync
3. Pastikan sync tidak silent failure

---

## 📋 Dependency Analysis

```
[Filesystem: Download/nhasix/[folder-id]]
       ↓ scan
[OfflineContentManager.scanBackupFolder()]
       ↓ sync
[Database: downloads table]
       ↓ query
[OfflineSearchCubit / DownloadBloc]
       ↓ emit
[UI: offline_content_screen / downloads_screen]
```

**Source of Truth yang Diharapkan:**
```
Filesystem → DB → UI
(sync otomatis saat DB empty atau manual trigger)
```

---

## ⚠️ Catatan Penting

- **Jangan buat workaround sementara**
- **Setiap fix harus menjelaskan root cause**
- **Test case harus mencakup edge case: DB empty, filesystem empty, mismatch state**
