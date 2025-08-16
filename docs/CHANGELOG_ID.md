# Changelog

Semua perubahan penting pada proyek ini akan didokumentasikan dalam file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
dan proyek ini mengikuti [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Ditambahkan
- Setup dependency injection komprehensif menggunakan get_it untuk skalabilitas lebih baik
- Menambahkan dependensi eksternal seperti SharedPreferences dan Connectivity
- Konfigurasi utilitas inti: Logger, Dio HTTP client, CacheManager, TagDataManager
- Data source untuk scraping remote, anti-detection, bypass cloudflare, dan database lokal
- Implementasi repository untuk konten, data pengguna, pengaturan pembaca, dan konten offline
- Use case untuk konten, favorit, unduhan, dan manajemen riwayat
- BLoC untuk splash, home, konten, pencarian, dan fitur unduhan
- Cubit untuk network, pengaturan, detail, filter data, pembaca, pencarian offline, dan favorit
- Konfigurasi MultiBlocProvider diperbarui untuk semua BLoC dan Cubit
- Dependensi di pubspec.yaml diperbarui untuk mendukung fitur baru


## [0.7.0] - 2024-12-15

### Ditambahkan
- **Implementasi Sistem Reader Lengkap** 📖
  - ReaderScreen dengan 3 mode baca: single page, vertical page, continuous scroll
  - ReaderCubit untuk manajemen state sederhana dengan persistensi pengaturan
  - Fitur lanjutan: pelacakan progress, timer baca, lompat halaman, keep screen on
  - Navigasi gesture dengan tap zone untuk previous/next/toggle UI
  - Modal pengaturan dengan pemilihan mode baca dan fungsi reset
  - Sinkronisasi controller untuk perpindahan mode yang smooth
  - Error handling komprehensif dengan AppErrorWidget

- **Sistem Pencarian & Filter Lanjutan** 🔍
  - FilterDataScreen dengan UI modern untuk pemilihan filter lanjutan
  - FilterDataCubit untuk manajemen state data filter
  - Integrasi TagDataManager dengan aset lokal (assets/json/tags.json)
  - Matrix Filter Support dengan fungsi include/exclude
  - Persistensi state pencarian antar restart aplikasi
  - Widget FilterItemCard, SelectedFiltersWidget, FilterTypeTabBar
  - SearchQueryBuilder untuk format query yang tepat

- **Framework UI Komprehensif** 🎨
  - ColorsConst yang diperbarui dengan tema gelap yang nyaman mata dan warna semantik
  - TextStyleConst yang ditingkatkan dengan style semantik dan utility method
  - ContentListWidget dengan pendekatan pagination-first dan infinite scroll yang dapat dikonfigurasi
  - PaginationWidget dengan progress bar, lompat halaman, dan dukungan aksesibilitas
  - SortingWidget untuk MainScreen dengan desain modern
  - AppProgressIndicator dan AppErrorWidget untuk UX yang konsisten

### Ditingkatkan
- **Integrasi MainScreen**
  - Integrasi HomeBloc untuk manajemen state level screen
  - Tampilan hasil pencarian dengan header filter aktif
  - Fungsi sorting dipindah dari SearchScreen ke MainScreen
  - Loading state pencarian dari local storage saat startup aplikasi
  - Fungsi clear hasil pencarian dengan pembersihan database

- **Navigasi & Routing**
  - Konfigurasi Go Router dengan route FilterDataScreen
  - Parameter passing untuk tipe filter dan filter yang dipilih
  - Dukungan deep linking dengan navigasi balik yang tepat
  - Method AppRouter untuk navigasi FilterDataScreen

- **Database & Persistensi**
  - Tabel state filter pencarian untuk persistensi
  - Model pengaturan reader untuk penyimpanan preferensi
  - Skema database yang disederhanakan dengan 6 tabel
  - Serialisasi/deserialisasi state pencarian

### Perbaikan Teknis
- **Arsitektur Manajemen State**
  - Pemisahan BLoC vs Cubit yang tepat (Fitur Kompleks vs Sederhana)
  - ContentBloc untuk pagination kompleks dan hasil pencarian
  - SearchBloc untuk pencarian lanjutan dengan persistensi state
  - HomeBloc untuk inisialisasi main screen
  - DetailCubit, ReaderCubit, FilterDataCubit untuk manajemen state sederhana

- **Optimisasi Performa**
  - Pendekatan pagination-first untuk performa yang lebih baik
  - Image caching dengan CachedNetworkImage
  - Manajemen memori dengan disposal yang tepat
  - Optimisasi database dengan query yang efisien

### Testing
- **Persyaratan Testing Perangkat Nyata**
  - Semua fitur harus ditest pada perangkat Android fisik
  - Monitoring performa pada hardware nyata
  - Testing konektivitas jaringan dengan berbagai kondisi
  - Validasi UI/UX pada berbagai ukuran layar dan orientasi

## [0.6.0] - 2024-12-01

### Ditambahkan
- **Implementasi Alur Pencarian Lengkap** 🔍
  - SearchScreen dengan interface pencarian komprehensif
  - Dukungan filter lanjutan tanpa API call langsung
  - Tombol search untuk memicu SearchSubmitted event
  - Integrasi navigasi dengan FilterDataScreen
  - Filter single select (bahasa, kategori) dengan validasi
  - Tampilan hasil pencarian dengan dukungan pagination

- **Komponen UI Inti** 🎨
  - AppMainDrawerWidget dengan 4 item menu utama
  - AppMainHeaderWidget dengan navigasi search dan menu
  - ContentListWidget dengan grid layout dan dukungan pagination
  - Implementasi desain modern dengan ColorsConst dan TextStyleConst
  - Layout responsif dengan SliverGrid dan widget adaptif

### Ditingkatkan
- **Fitur Lanjutan ContentBloc**
  - Integrasi hasil pencarian dengan tampilan konten normal
  - Fungsi sorting dengan ContentSortChangedEvent
  - Dukungan pagination dengan overlay loading untuk perubahan halaman
  - Fungsi pull-to-refresh dengan SmartRefresher
  - Error handling dengan mekanisme retry dan fallback konten cache

- **Integrasi Database**
  - Persistensi state pencarian dengan LocalDataSource
  - Penyimpanan preferensi sorting dengan UserDataRepository
  - Update skema database untuk fungsi pencarian
  - Dukungan migrasi untuk tabel baru

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

- ✅ **Tugas 1-7**: Fitur inti selesai (70% dari proyek)
  - ✅ Struktur proyek dan dependensi
  - ✅ Implementasi layer domain dan data
  - ✅ Sistem manajemen state BLoC/Cubit
  - ✅ Komponen UI inti dan widget
  - ✅ Sistem pencarian dan filter lanjutan
  - ✅ Fungsi reader lengkap
- 🎯 **Tugas 8**: Sistem favorit dan download (prioritas berikutnya)
- 📅 **Tugas 9**: Pengaturan dan preferensi
- 📅 **Tugas 10**: Fitur lanjutan dan manajemen jaringan
- 📅 **Tugas 11**: Optimisasi performa dan testing
- 📅 **Tugas 12**: Polish UI dan aksesibilitas
- 📅 **Tugas 13**: Persiapan deployment

---

**Status Saat Ini**: 70% Selesai (7/13 tugas)  
**Status Implementasi**: Fitur inti operasional  
**Milestone Berikutnya**: Implementasi Sistem Favorit dan Download