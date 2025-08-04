# 📱 NhentaiApp - Flutter Clone
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![18+](https://img.shields.io/badge/Pembatasan_Usia-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

> **⚠️ PERINGATAN PEMBATASAN USIA**  
> **Aplikasi ini hanya ditujukan untuk pengguna berusia 18 tahun ke atas.**  
> **Konten yang diakses melalui aplikasi ini mungkin mengandung tema dewasa dan tidak cocok untuk anak di bawah umur.**  
> **Dengan menggunakan aplikasi ini, Anda mengkonfirmasi bahwa Anda berusia minimal 18 tahun dan diizinkan secara hukum untuk mengakses konten tersebut di wilayah hukum Anda.**

Aplikasi Android Flutter yang komprehensif yang berfungsi sebagai clone dari nhentai.net, dibangun dengan **Clean Architecture** dan praktik pengembangan Flutter modern. Aplikasi ini menyediakan pengalaman mobile yang ditingkatkan untuk browsing, membaca, dan mengelola konten manga/doujinshi dengan kemampuan offline.

## 🚀 Fitur

### 📖 Pengalaman Membaca Inti
- **Browsing Konten** - Jelajahi konten terbaru, populer, dan acak
- **Pencarian Lanjutan** - Filter berdasarkan tag, artis, karakter, bahasa, dan lainnya
- **Pembaca Manga** - Pengalaman membaca yang lancar dengan zoom, pan, dan navigasi
- **Mode Membaca Beragam** - Halaman tunggal, scroll berkelanjutan, dukungan halaman ganda
- **Progress Membaca** - Lacak riwayat dan progress membaca secara otomatis

### 💾 Offline & Penyimpanan
- **Sistem Favorit** - Atur favorit dengan kategori kustom
- **Download Manager** - Download konten untuk membaca offline dengan manajemen antrian
- **Riwayat Membaca** - Lacak progress dan statistik membaca
- **Membaca Offline** - Akses konten yang didownload tanpa internet

### 🎨 Kustomisasi
- **Tema Beragam** - Tema Terang, Gelap, dan AMOLED dengan skema warna kustom
- **Pengaturan Pembaca** - Kustomisasi arah baca, transisi halaman, dan kontrol
- **Layout Grid** - Kolom grid yang dapat disesuaikan untuk orientasi layar berbeda
- **Filter Konten** - Blacklist tag dan kustomisasi visibilitas konten

### 🔧 Fitur Lanjutan
- **Bypass Cloudflare** - Bypass otomatis perlindungan website
- **Web Scraping** - Ekstraksi konten langsung dari HTML
- **Download Background** - Lanjutkan download di background
- **Dashboard Statistik** - Statistik dan analitik membaca
- **Backup & Sync** - Export/import data pengguna dan pengaturan

## 🏗️ Arsitektur

Proyek ini mengikuti prinsip **Clean Architecture** dengan pemisahan yang jelas:

```
lib/
├── 📁 core/                    # Utilitas inti dan konfigurasi
│   ├── config/                 # Konfigurasi aplikasi
│   ├── constants/              # Konstanta dan tema aplikasi
│   ├── di/                     # Setup dependency injection
│   ├── routing/                # Navigasi dan routing
│   └── utils/                  # Fungsi utilitas
├── 📁 data/                    # Layer data
│   ├── datasources/            # Sumber data remote dan lokal
│   ├── models/                 # Model data dan DTO
│   └── repositories/           # Implementasi repository
├── 📁 domain/                  # Layer domain (Business Logic)
│   ├── entities/               # Entitas bisnis inti
│   ├── repositories/           # Interface repository
│   ├── usecases/               # Use case bisnis
│   └── value_objects/          # Value object untuk type safety
├── 📁 presentation/            # Layer presentasi
│   ├── blocs/                  # Manajemen state BLoC
│   ├── pages/                  # Implementasi layar
│   └── widgets/                # Komponen UI yang dapat digunakan ulang
└── main.dart                   # Entry point aplikasi
```

## 🗄️ Implementasi Layer Data

### **Pola Repository**
- **ContentRepositoryImpl** - Manajemen konten offline-first dengan caching cerdas
- **UserDataRepositoryImpl** - Manajemen data pengguna lokal (favorit, download, riwayat)
- **SettingsRepositoryImpl** - Manajemen pengaturan berbasis SharedPreferences

### **Sumber Data**
- **LocalDataSource** - Operasi database SQLite dengan CRUD komprehensif
- **RemoteDataSource** - Web scraping dengan anti-deteksi dan bypass Cloudflare
- **DatabaseHelper** - Manajemen skema database dan migrasi

### **Strategi Offline-First**
- **Caching Cerdas** - Ekspirasi cache 6 jam dengan refresh otomatis
- **Mekanisme Fallback** - Pola fallback Cache → Remote → Cache
- **Error Handling** - Error handling komprehensif dengan degradasi yang elegan
- **Optimisasi Performa** - Transaksi database dan manajemen memori

### **Model Data**
- **ContentModel** - Entitas konten dengan serialisasi database
- **TagModel** - Entitas tag dengan manajemen relasi
- **DownloadStatusModel** - Pelacakan progress download
- **HistoryModel** - Riwayat membaca dengan statistik

## 🎯 Implementasi Terbaru: ContentBloc dengan Fitur Lanjutan

### **Fitur Utama yang Diimplementasikan**
- **🔄 Manajemen State Lanjutan** - Loading, loaded, error state dengan dukungan pagination
- **📱 Pull-to-Refresh** - Integrasi SmartRefresher untuk update konten yang seamless
- **♾️ Infinite Scrolling** - Load more otomatis dengan optimisasi performa
- **🎯 Manajemen Konten** - Browsing konten lengkap dengan strategi caching
- **🛡️ Error Handling** - Error handling komprehensif dengan mekanisme retry
- **💾 Integrasi LocalDataSource** - Operasi database SQLite lengkap siap pakai
- **🧪 Testing Komprehensif** - 10/10 unit test + 8/8 integration test passing

### **Alur State ContentBloc**
```
ContentInitial → ContentLoading → ContentLoaded (dengan pagination)
                              ↘ ContentError (dengan retry)
ContentRefreshing → ContentLoaded (pull-to-refresh)
ContentLoadingMore → ContentLoaded (infinite scroll)
```

### **Kemampuan LocalDataSource**
- **Operasi Konten**: Cache, get, search dengan pagination
- **Manajemen Tag**: Relasi tag dan filtering
- **Sistem Favorit**: Kategori dan operasi batch
- **Pelacakan Download**: Monitoring status dan manajemen antrian
- **Manajemen Riwayat**: Progress membaca dan statistik
- **Preferensi Pengguna**: Penyimpanan pengaturan dan kustomisasi
- **Optimisasi Database**: Transaksi, index, dan cleanup

## 🛠️ Tech Stack

### **Framework Inti**
- **Flutter** - Pengembangan mobile cross-platform
- **Dart** - Bahasa pemrograman

### **Arsitektur & Manajemen State**
- **Clean Architecture** - Pemisahan concerns
- **Pola BLoC** - Manajemen state reaktif dengan `flutter_bloc`
- **Get It** - Dependency injection
- **Equatable** - Kesetaraan nilai dan immutability

### **Navigasi & Routing**
- **Go Router** - Routing deklaratif dengan dukungan deep linking

### **Data & Penyimpanan**
- **SQLite** (`sqflite`) - Database lokal untuk caching dan data offline
- **SharedPreferences** - Penyimpanan key-value sederhana untuk pengaturan
- **Path Provider** - Akses sistem file
- **Arsitektur Offline-First** - Caching cerdas dengan mekanisme fallback

### **Networking & Web Scraping**
- **Dio** - HTTP client untuk panggilan API
- **HTML Parser** - Parsing HTML untuk web scraping
- **WebView Flutter** - Integrasi bypass Cloudflare
- **Connectivity Plus** - Monitoring konektivitas jaringan

### **Penanganan Gambar**
- **Cached Network Image** - Caching dan loading gambar
- **Photo View** - Fungsi zoom dan pan gambar
- **Image** - Pemrosesan dan manipulasi gambar

### **UI & User Experience**
- **Flutter Staggered Grid View** - Layout grid masonry
- **Pull to Refresh** - Fungsi pull-to-refresh
- **Flutter Slidable** - Aksi swipe
- **Badges** - Badge notifikasi
- **Shimmer** - Animasi loading skeleton
- **Lottie** - Animasi lanjutan

### **Background & Notifikasi**
- **Flutter Local Notifications** - Notifikasi push lokal
- **Wakelock Plus** - Jaga layar tetap menyala saat membaca

### **Manajemen File**
- **File Picker** - Pemilihan file untuk import/export
- **Share Plus** - Fungsi berbagi konten
- **Open File** - Buka file yang didownload

### **Utilitas**
- **Logger** - Sistem logging komprehensif
- **Permission Handler** - Izin runtime
- **Crypto** - Operasi kriptografi
- **Intl** - Dukungan internasionalisasi
- **Package Info Plus** - Informasi aplikasi
- **Device Info Plus** - Informasi perangkat

### **Testing & Development**
- **BLoC Test** - Utilitas testing untuk manajemen state BLoC
- **Mockito** - Generasi mock untuk unit testing
- **Build Runner** - Code generation untuk mock dan build task lainnya
- **Flutter Test** - Framework testing inti
- **Flutter Lints** - Penegakan kualitas dan style kode

## 📋 Progress Pengembangan

### ✅ **Tugas Selesai**
- [x] **Tugas 1**: Setup struktur proyek dan dependensi inti
- [x] **Tugas 2**: Implementasi layer domain inti
  - [x] Entitas domain dan value object
  - [x] Interface repository
  - [x] Use case dengan logika bisnis komprehensif
- [x] **Tugas 3**: Fondasi layer data (Minggu 1)
  - [x] Implementasi repository dengan arsitektur offline-first
  - [x] Sumber data lokal dengan integrasi SQLite (implementasi EXCELLENT!)
  - [x] Sumber data remote dengan kemampuan web scraping
  - [x] Model data dengan konversi entitas
  - [x] Strategi caching dan error handling
- [x] **Tugas 4.1**: Implementasi SplashBloc yang ditingkatkan ✨
  - [x] Manajemen state komprehensif untuk inisialisasi aplikasi
  - [x] Integrasi bypass Cloudflare dengan error handling yang tepat
  - [x] Validasi konektivitas jaringan dan mekanisme retry
  - [x] UI yang ditingkatkan dengan loading state dan indikator progress
  - [x] Unit testing komprehensif dengan mocking
- [x] **Tugas 4.2**: ContentBloc untuk manajemen konten ✨
  - [x] Pagination lanjutan dengan infinite scrolling
  - [x] Fungsi pull-to-refresh dengan SmartRefresher
  - [x] Manajemen state komprehensif (loading, loaded, error)
  - [x] Integrasi LocalDataSource siap pakai
  - [x] Suite testing lengkap (10 unit + 8 integration test)
  - [x] Verifikasi koneksi real nhentai.net
- [x] **Tugas 4.3**: SearchBloc untuk fungsi pencarian lanjutan ✨
  - [x] Pencarian lanjutan dengan dukungan filter komprehensif (query, tag, artis, bahasa, kategori)
  - [x] Manajemen riwayat pencarian dengan penyimpanan persisten (maks 50 item, FIFO)
  - [x] Pencarian debounced dengan delay 500ms untuk optimisasi performa
  - [x] Saran tag real-time dengan request debounced
  - [x] Kombinasi filter kompleks dan manajemen state
  - [x] Suite testing komprehensif (38+ test meliputi unit, real API, dan integration)

- [x] **Tugas 4**: Manajemen state BLoC inti (Minggu 2) - 🚧 SEDANG BERLANGSUNG
  - [x] **Tugas 4.1**: SplashBloc untuk initial loading ✅
    - [x] Logika bypass Cloudflare dengan alur komprehensif
    - [x] Loading state dan error handling dengan mekanisme retry
    - [x] Navigasi setelah bypass berhasil
    - [x] Validasi konektivitas jaringan
  - [x] **Tugas 4.2**: ContentBloc untuk manajemen konten ✅
    - [x] Dukungan pagination dengan infinite scrolling
    - [x] Loading, loaded, error state dengan transisi yang tepat
    - [x] Fungsi pull-to-refresh dengan SmartRefresher
    - [x] Manajemen konten lanjutan (sort, search, popular, random, tags)
  - [x] **Tugas 4.3**: SearchBloc untuk pencarian lanjutan ✅
    - [x] Pencarian lanjutan dengan dukungan filter komprehensif
    - [x] Fungsi riwayat pencarian dengan penyimpanan persisten
    - [x] Pencarian debounced dengan optimisasi delay 500ms
    - [x] Saran tag real-time dengan optimisasi performa

### 🚧 **Sedang Berlangsung**
- [ ] **Tugas 4.4**: Cubit sederhana untuk manajemen state dasar
  - [ ] NetworkCubit untuk pelacakan status koneksi
  - [ ] DetailCubit untuk detail konten dan toggle favorit
  - [ ] Kelas Cubit dasar dengan fungsi umum
  - [ ] Setup provider Cubit dalam MultiBlocProviderConfig

### 📅 **Selanjutnya**
- [ ] **Tugas 5**: Komponen UI inti (Minggu 3)

### 📅 **Tugas Mendatang** (roadmap 12 minggu)
- [ ] **Tugas 6**: Fungsi pembaca (Minggu 4)
- [ ] **Tugas 7**: Sistem favorit & download (Minggu 5)
- [ ] **Tugas 8**: Pengaturan & preferensi (Minggu 6)
- [ ] **Tugas 9**: Fitur lanjutan (Minggu 7)
- [ ] **Tugas 10**: Optimisasi performa & testing (Minggu 8)
- [ ] **Tugas 11**: Polish & persiapan deployment (Minggu 9)
- [ ] **Tugas 12**: Dokumentasi & sumber belajar (Minggu 10)

## 🚀 Memulai

### Prasyarat
- Flutter SDK (>=3.5.4)
- Dart SDK (>=3.5.4)
- Android Studio / VS Code
- Android SDK

### Instalasi

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd nhasixapp
   ```

2. **Install dependensi**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

### Build untuk Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (untuk Google Play Store)
flutter build appbundle --release
```

## 🧪 Testing

Proyek ini mencakup testing komprehensif dengan mocking untuk unit test yang reliable:

```bash
# Jalankan semua test
flutter test

# Jalankan file test spesifik
flutter test test/presentation/blocs/splash/splash_bloc_test.dart

# Jalankan test dengan coverage
flutter test --coverage

# Generate file mock
flutter packages pub run build_runner build

# Analisis kode
flutter analyze
```

### **Cakupan Test**
- **Test SplashBloc** - Testing manajemen state lengkap dengan dependensi yang di-mock
- **Test ContentBloc** - 10/10 unit test + 8/8 integration test passing
- **Test Repository** - Testing layer data dengan skenario offline-first
- **Test Use Case** - Validasi logika bisnis
- **Integration Test** - Testing end-to-end untuk alur kritis
- **Test Koneksi Real** - Verifikasi konektivitas nhentai.net

## 📱 Screenshot

*Screenshot akan ditambahkan seiring progress pengembangan*

## 🤝 Kontribusi

Proyek ini mengikuti prinsip Clean Architecture dan menggunakan BLoC untuk manajemen state. Saat berkontribusi:

1. Ikuti pola arsitektur yang telah ditetapkan
2. Tulis test komprehensif untuk fitur baru
3. Update dokumentasi untuk perubahan signifikan
4. Ikuti panduan style Dart/Flutter

## ⚖️ Pemberitahuan Hukum

**PEMBATASAN USIA:** Aplikasi ini secara khusus ditujukan untuk pengguna berusia 18 tahun ke atas. Konten yang diakses melalui aplikasi ini mengandung tema dewasa dan materi dewasa yang tidak cocok untuk anak di bawah umur.

Aplikasi ini dibuat untuk tujuan edukasi dan penggunaan pribadi saja. Ini mendemonstrasikan praktik pengembangan Flutter modern dan implementasi Clean Architecture. Pengguna bertanggung jawab untuk:
- Memverifikasi bahwa mereka memenuhi persyaratan usia minimum (18+) di wilayah hukum mereka
- Mematuhi hukum yang berlaku dan ketentuan layanan sumber konten
- Menggunakan aplikasi secara bertanggung jawab dan legal

Dengan mengunduh, menginstal, atau menggunakan aplikasi ini, Anda mengakui dan mengkonfirmasi bahwa Anda berusia minimal 18 tahun dan diizinkan secara hukum untuk mengakses konten dewasa di lokasi Anda.

## 📄 Lisensi

Proyek ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detail.

## 🙏 Penghargaan

- Tim Flutter untuk framework yang luar biasa
- Maintainer library BLoC untuk manajemen state yang excellent
- Prinsip Clean Architecture oleh Robert C. Martin
- Komunitas open source untuk package-package fantastis yang digunakan

---

## 📊 Statistik Proyek

- **Arsitektur**: Clean Architecture dengan 3 layer
- **Manajemen State**: Pola BLoC dengan testing komprehensif
- **Dependensi**: 45+ package yang dipilih dengan hati-hati
- **Cakupan Test**: Unit test dengan mocking untuk komponen kritis
- **Progress Pengembangan**: 42% selesai (5/12 tugas)
- **Estimasi Waktu Pengembangan**: 12 minggu (1 tugas per minggu)
- **Platform Target**: Android
- **SDK Minimum**: Android API 21+ (Android 5.0)
- **Pencapaian Terbaru**: Sistem manajemen state BLoC lengkap dengan SplashBloc, ContentBloc, dan SearchBloc ✨

---

**Dibangun dengan ❤️ menggunakan Flutter dan Clean Architecture**

---

## 🌐 Bahasa Lain

- [English](README.md)
- [Bahasa Indonesia](README_ID.md) ← Anda di sini