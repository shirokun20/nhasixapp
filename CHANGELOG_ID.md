# Changelog

Semua perubahan penting pada proyek ini akan didokumentasikan dalam file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
dan proyek ini mengikuti [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-01-30

### Ditambahkan
- **Implementasi SearchBloc Lanjutan** 🔍
  - Fungsi pencarian komprehensif dengan kemampuan filter lanjutan
  - Pencarian debounced dengan delay 500ms untuk performa optimal
  - Manajemen riwayat pencarian dengan integrasi penyimpanan lokal
  - Saran tag dan fungsi autocomplete
  - Pelacakan dan tampilan pencarian populer
  - Preset pencarian untuk menyimpan dan memuat konfigurasi filter kustom
  - Toggle mode pencarian lanjutan untuk pengguna power
  - Aplikasi filter cepat untuk tag, artis, bahasa, dan kategori
  - Dukungan pagination dengan fungsi load more
  - Kemampuan pull-to-refresh untuk hasil pencarian
  - Mekanisme retry cerdas dengan deteksi tipe error

### Ditingkatkan
- **Manajemen State Pencarian**
  - Multiple state khusus: `SearchInitial`, `SearchLoading`, `SearchLoaded`, `SearchEmpty`, `SearchError`
  - State loading lanjutan: `SearchLoadingMore`, `SearchRefreshing`
  - Error handling komprehensif dengan tipe error spesifik (network, server, cloudflare, rate limit, parsing)
  - State saran pencarian dengan pencocokan query real-time
  - State riwayat pencarian dengan integrasi pencarian populer

- **Fitur Pencarian**
  - Saran pencarian real-time dari riwayat dan pencarian populer
  - Autocomplete berbasis tag dengan integrasi database
  - Persistensi dan manajemen filter pencarian
  - Opsi sort dengan re-searching dinamis
  - Caching dan optimisasi hasil pencarian
  - Maksimal 50 item riwayat dengan pembersihan otomatis
  - Maksimal 10 saran per query untuk performa

- **Error Handling & UX**
  - Deteksi tipe error cerdas dan kategorisasi
  - Fungsi retry dengan pesan error yang context-aware
  - Degradasi yang elegan untuk skenario error berbeda
  - Loading state dengan pesan deskriptif
  - Penanganan empty state dengan saran pencarian

### Testing
- **Unit Test Komprehensif**
  - Suite testing SearchBloc lengkap dengan `flutter_test`
  - Implementasi mock untuk use case dan data source
  - Testing transisi state untuk semua skenario pencarian
  - Testing error handling dan edge case
  - Testing riwayat pencarian dan saran
  - Integration test untuk skenario dunia nyata

### Perbaikan Teknis
- **Manajemen Stream**
  - Custom debounce transformer untuk search event
  - Penanganan subscription stream yang tepat dan cleanup
  - Pencegahan memory leak dengan pembatalan timer
  - Pemrosesan event efisien dengan pola async/await

- **Integrasi Data Layer**
  - Integrasi LocalDataSource yang ditingkatkan untuk riwayat pencarian
  - Fungsi pencarian tag dengan query database
  - Serialisasi dan persistensi filter pencarian
  - Operasi database yang dioptimalkan untuk performa pencarian

### Dependencies
- Integrasi yang ditingkatkan dengan package `logger`, `equatable`, dan `bloc` yang ada
- Kompatibilitas yang diperbaiki dengan implementasi local data source
- Integrasi error handling yang lebih baik dengan exception domain layer

## [0.2.0] - 2025-01-28

### Ditambahkan
- **Implementasi SplashBloc yang Ditingkatkan** 🎯
  - Manajemen state komprehensif untuk proses inisialisasi aplikasi
  - Integrasi bypass Cloudflare dengan dependency injection yang tepat
  - Validasi konektivitas jaringan sebelum mencoba bypass
  - Verifikasi bypass untuk memastikan koneksi berhasil
  - Mekanisme retry cerdas dengan error handling yang tepat
  - UI yang ditingkatkan dengan loading state dan indikator progress
  - Integrasi WebView yang diperbaiki dengan pelacakan status yang lebih baik

### Ditingkatkan
- **Manajemen State**
  - Menambahkan multiple state: `SplashInitializing`, `SplashBypassInProgress`, `SplashSuccess`, `SplashError`
  - Implementasi transisi state yang tepat dengan feedback pengguna
  - Menambahkan fungsi retry dengan `SplashRetryBypassEvent`

- **User Experience**
  - Indikator loading dengan pesan progress
  - State error dengan tombol retry yang dapat ditindaklanjuti
  - Snackbar informatif dengan feedback sukses/error
  - Modal WebView yang tidak dapat dibatalkan selama proses bypass

- **Error Handling**
  - Validasi konektivitas jaringan
  - Pesan error detail dengan solusi yang disarankan
  - Degradasi yang elegan untuk skenario error berbeda
  - Presentasi error yang user-friendly

### Testing
- **Unit Test Komprehensif**
  - Menambahkan testing BLoC dengan package `bloc_test`
  - Implementasi mocking dengan `mockito` untuk test yang reliable
  - Membuat skenario test untuk semua transisi state
  - Menambahkan testing konektivitas dan verifikasi bypass

### Dependencies
- Menambahkan `bloc_test: ^10.0.0` untuk utilitas testing BLoC
- Menambahkan `mockito: ^5.4.4` untuk generasi mock
- Memperbarui service locator dengan dependency injection yang tepat

### Perbaikan Teknis
- Meningkatkan dependency injection di `service_locator.dart`
- Memperbaiki widget WebView dengan pelacakan status yang lebih baik
- Memperbarui splash screen dengan penanganan state komprehensif
- Memperbaiki penggunaan `withOpacity` yang deprecated ke `withValues`
- Menyelesaikan masalah kompatibilitas API connectivity

## [0.1.0] - 2025-01-20

### Ditambahkan
- **Fondasi Proyek**
  - Setup Clean Architecture dengan 3 layer (data, domain, presentation)
  - Dependensi inti dan struktur proyek
  - Routing dasar dengan GoRouter

- **Layer Domain**
  - Entitas inti dan value object
  - Interface repository
  - Use case dengan logika bisnis komprehensif

- **Layer Data**
  - Implementasi repository dengan arsitektur offline-first
  - Sumber data lokal dengan integrasi SQLite
  - Sumber data remote dengan kemampuan web scraping
  - Model data dengan konversi entitas
  - Strategi caching dan error handling
  - Implementasi bypass Cloudflare

### Tech Stack
- Flutter SDK (>=3.5.4)
- Pola Clean Architecture
- BLoC untuk manajemen state
- SQLite untuk penyimpanan lokal
- Dio untuk HTTP request
- WebView untuk bypass Cloudflare
- 40+ dependensi yang dipilih dengan hati-hati

---

## Progress Pengembangan

- ✅ **Tugas 1**: Setup struktur proyek dan dependensi inti
- ✅ **Tugas 2**: Implementasi layer domain inti
- ✅ **Tugas 3**: Fondasi layer data
- ✅ **Tugas 4**: Manajemen state BLoC inti ← **Terbaru**
  - ✅ **Tugas 4.1**: Implementasi SplashBloc yang ditingkatkan
  - ✅ **Tugas 4.2**: Implementasi ContentBloc
  - ✅ **Tugas 4.3**: Implementasi SearchBloc lanjutan
- 📅 **Tugas 5**: Komponen UI inti (berikutnya)

---

**Status Saat Ini**: 33% Selesai (4/12 tugas)  
**Milestone Berikutnya**: Memulai pengembangan komponen UI inti