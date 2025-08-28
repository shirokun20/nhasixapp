# 📱 NhasixApp - Pengalaman Membaca Mobile yang Ditingkatkan

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![18+](https://img.shields.io/badge/Batasan_Usia-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Beta](https://img.shields.io/badge/Status-BETA_v0.2.0-blue?style=for-the-badge&logo=android&logoColor=white)

> **⚠️ PERINGATAN BATASAN USIA**  
> **Aplikasi ini ditujukan untuk pengguna berusia 18 tahun ke atas saja.**  
> **Konten yang diakses melalui aplikasi ini mungkin mengandung tema dewasa dan tidak sesuai untuk anak di bawah umur.**  
> **Dengan menggunakan aplikasi ini, Anda mengkonfirmasi bahwa Anda berusia minimal 18 tahun dan diizinkan secara hukum untuk mengakses konten tersebut di wilayah hukum Anda.**

## 🚀 **BETA v0.2.0 - SEKARANG TERSEDIA!**

**NhasixApp** adalah aplikasi Android Flutter yang komprehensif yang menyediakan pengalaman membaca mobile yang ditingkatkan dengan **70% pemuatan konten lebih cepat**, kemampuan offline yang cerdas, dan peningkatan UI modern. Dibangun dengan **Clean Architecture** dan dioptimalkan untuk performa.

### 📱 **Download Beta APK**

| **Jenis APK** | **Ukuran** | **Target Perangkat** | **Download** |
|--------------|----------|-------------------|--------------|
| **ARM64** ⭐ | 24MB | Perangkat modern (2019+) | `nhasix_0.2.0_20250828_release_arm64_optimized.apk` |
| **ARM32** | 22MB | Perangkat lama (2015-2019) | `nhasix_0.2.0_20250828_release_arm_optimized.apk` |
| **Universal** | 22MB | Semua perangkat | `nhasix_0.2.0_20250828_release_universal_optimized.apk` |

> **Rekomendasi**: Download APK ARM64 untuk performa terbaik di perangkat Android modern

## 🚀 Fitur

### 🆕 Pembaruan Terbaru

- [x] Setup dependency injection komprehensif menggunakan get_it untuk skalabilitas lebih baik
- [x] Menambahkan dependensi eksternal seperti SharedPreferences dan Connectivity
- [x] Konfigurasi utilitas inti: Logger, Dio HTTP client, CacheManager, TagDataManager
- [x] Data source untuk scraping remote, anti-detection, bypass cloudflare, dan database lokal
- [x] Implementasi repository untuk konten, data pengguna, pengaturan pembaca, dan konten offline
- [x] Use case untuk konten, favorit, unduhan, dan manajemen riwayat
- [x] BLoC untuk splash, home, konten, pencarian, dan fitur unduhan
- [x] Cubit untuk network, pengaturan, detail, filter data, pembaca, pencarian offline, dan favorit
- [x] Konfigurasi MultiBlocProvider diperbarui untuk semua BLoC dan Cubit
- [x] Dependensi di pubspec.yaml diperbarui untuk mendukung fitur baru
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

## 🚀 Fitur

## ✨ **BARU di BETA v0.2.0**

### � **Terobosan Performa**
- **70% pemuatan konten lebih cepat** dengan smart image preloader
- **Build APK yang dioptimalkan** - 3 varian untuk arsitektur perangkat berbeda
- **Paginasi yang ditingkatkan** dengan prefetching cerdas
- **Ukuran aplikasi berkurang** dengan optimasi kode

### 🔒 **Privasi & Keamanan**
- **Privasi download yang ditingkatkan** dengan perlindungan file `.nomedia`
- **Galeri pribadi** - download tidak akan muncul di galeri sistem
- **Penyimpanan aman** dengan manajemen file yang diperbaiki

### 📱 **Peningkatan UI/UX**
- **Highlight progress download** - feedback visual untuk download aktif
- **Pengalaman pencarian yang diperbaiki** dengan navigasi yang lebih baik
- **Paginasi modern** dengan transisi yang lebih halus
- **Interface reader yang ditingkatkan** dengan perbaikan gesture

### 🎯 **Fitur Cerdas**
- **Preloading gambar cerdas** - halaman berikutnya dimuat saat Anda membaca
- **Download berbasis rentang** - download rentang halaman tertentu
- **Manajemen download background** dengan pelacakan progress
- **Penggunaan memori yang dioptimalkan** untuk performa yang lebih baik

---

## � **Fitur Utama**

### 📚 **Pengalaman Membaca Inti**
- **Interface bersih dan modern** dioptimalkan untuk membaca mobile
- **Rendering gambar berkualitas tinggi** dengan dukungan zoom dan pan
- **Mode membaca layar penuh** untuk pengalaman yang imersif
- **Transisi halaman yang halus** dengan kontrol gesture

### 🔍 **Pencarian & Penemuan Lanjutan**
- **Mesin pencari yang kuat** dengan filter tag dan kategori
- **Filtering lanjutan** berdasarkan popularitas, tanggal, dan tag
- **Rekomendasi cerdas** berdasarkan riwayat baca
- **Manajemen bookmark** dengan akses offline

### � **Fitur Offline & Download**
- **Membaca offline penuh** - download untuk membaca tanpa internet
- **Download rentang** - download halaman atau chapter tertentu
- **Download pribadi** - konten tersembunyi dari galeri sistem
- **Pelacakan progress download** dengan indikator visual
- **Download background** - lanjutkan browsing saat mendownload

### 🎨 **Pengalaman Pengguna**
- **Desain responsif** yang bekerja di semua ukuran layar
- **Dukungan tema Gelap/Terang** dengan deteksi preferensi sistem
- **Navigasi gesture** - kontrol swipe, pinch, dan tap
- **Pelacakan progress baca** dengan bookmark otomatis

## 🏗️ Arsitektur

## 🛠️ Progres Pengembangan

- [x] Setup dependency injection komprehensif menggunakan get_it untuk skalabilitas lebih baik
- [x] Menambahkan dependensi eksternal seperti SharedPreferences dan Connectivity
- [x] Konfigurasi utilitas inti: Logger, Dio HTTP client, CacheManager, TagDataManager
- [x] Data source untuk scraping remote, anti-detection, bypass cloudflare, dan database lokal
- [x] Implementasi repository untuk konten, data pengguna, pengaturan pembaca, dan konten offline
- [x] Use case untuk konten, favorit, unduhan, dan manajemen riwayat
- [x] BLoC untuk splash, home, konten, pencarian, dan fitur unduhan
- [x] Cubit untuk network, pengaturan, detail, filter data, pembaca, pencarian offline, dan favorit
- [x] Konfigurasi MultiBlocProvider diperbarui untuk semua BLoC dan Cubit
- [x] Dependensi di pubspec.yaml diperbarui untuk mendukung fitur baru
- [x] Menambahkan fitur bypass Cloudflare dan web scraping
- [x] Implementasi dukungan download di background
- [x] Menambahkan dashboard statistik dan fungsi backup & sync

## 🛠️ **Arsitektur Teknis**

### 🏗️ **Implementasi Clean Architecture**
```
📁 lib/
├── 🎯 presentation/     # Layer UI (Widget, Page, Bloc)
├── 🏢 domain/          # Logika Bisnis (Entity, Use Case)
├── 💾 data/            # Layer Data (Repository, Data Source)
├── 🔧 core/            # Utilitas Inti (DI, Konstanta, Error)
├── 🌐 services/        # Layanan Eksternal (API, Storage)
└── 🛠️ utils/           # Fungsi Helper dan Extension
```

### � **Tech Stack**
- **Framework**: Flutter 3.24+ dengan Dart 3.5+
- **State Management**: Flutter Bloc dengan Cubit
- **Arsitektur**: Clean Architecture dengan MVVM
- **Storage**: SharedPreferences + SQLite (sqflite)
- **Network**: HTTP dengan custom interceptor
- **Image Processing**: Dioptimalkan dengan native caching
- **Performa**: Smart preloading dan pagination

### 🚀 **Optimasi Performa**
- **Smart Image Preloader**: 70% loading lebih cepat dengan prefetching cerdas
- **Build APK Dioptimalkan**: Varian terpisah ARM64/ARM32/Universal
- **Manajemen Memori**: Caching dan disposal gambar yang efisien
- **Background Processing**: Download dan operasi non-blocking

---

## 📥 **Instalasi**

### 📱 **Metode 1: Instalasi APK (Direkomendasikan)**

1. **Download APK yang sesuai**:
   - **ARM64** (perangkat modern): `nhasix_0.2.0_20250828_release_arm64_optimized.apk`
   - **ARM32** (perangkat lama): `nhasix_0.2.0_20250828_release_arm_optimized.apk`
   - **Universal** (semua perangkat): `nhasix_0.2.0_20250828_release_universal_optimized.apk`

2. **Aktifkan instalasi dari sumber tidak dikenal**:
   - Buka **Pengaturan → Keamanan → Sumber Tidak Dikenal**
   - Atau **Pengaturan → Aplikasi → Akses Khusus → Instal Aplikasi Tidak Dikenal**

3. **Instal APK**:
   - Ketuk file APK yang telah didownload
   - Ikuti petunjuk instalasi
   - Berikan izin yang diperlukan saat diminta

### 🛠️ **Metode 2: Build dari Source**

#### **Prasyarat**
- Flutter SDK 3.24+
- Android Studio dengan Android SDK 34+
- Dart 3.5+
- Git

#### **Build Cepat**
```bash
# Clone repository
git clone https://github.com/yourusername/nhasixapp.git
cd nhasixapp

# Dapatkan dependencies
flutter pub get

# Build APK release yang dioptimalkan
chmod +x build_optimized.sh
./build_optimized.sh
```

#### **Setup Development**
```bash
# Install dependencies
flutter pub get

# Jalankan dalam mode debug
flutter run

# Build untuk release
flutter build apk --release
```

---

## 🎮 **Panduan Penggunaan**

### 🔍 **Navigasi Dasar**
1. **Browse Konten**: Swipe melalui feed utama
2. **Pencarian**: Gunakan search bar dengan filter dan tag
3. **Baca**: Ketuk item mana pun untuk mulai membaca
4. **Download**: Long press atau gunakan tombol download untuk akses offline

### 📥 **Fitur Download**
- **Download Penuh**: Download seluruh konten untuk membaca offline
- **Download Rentang**: Pilih halaman tertentu untuk didownload
- **Mode Pribadi**: Download tersembunyi dari galeri sistem (`.nomedia`)
- **Pelacakan Progress**: Indikator visual menunjukkan status download

### ⚙️ **Pengaturan & Kustomisasi**
- **Tema**: Beralih antara mode terang dan gelap
- **Preferensi Membaca**: Sesuaikan zoom, efek transisi
- **Lokasi Download**: Pilih direktori penyimpanan
- **Pengaturan Privasi**: Konfigurasi visibilitas download

---

## 🧪 **Beta Testing & Feedback**

### 🐛 **Masalah yang Diketahui**
- Beberapa perangkat langka mungkin mengalami loading lebih lambat pada startup pertama
- Progress download mungkin tidak update real-time di versi Android lama
- Filter pencarian mungkin perlu penyempurnaan untuk query yang sangat spesifik

### 📝 **Feedback Beta**
Kami secara aktif mencari feedback untuk meningkatkan NhasixApp! Silakan laporkan:
- **Masalah performa** pada perangkat spesifik Anda
- **Saran UI/UX** untuk kegunaan yang lebih baik
- **Permintaan fitur** yang akan meningkatkan pengalaman Anda
- **Bug atau crash** dengan detail perangkat/versi Android

**Kontak**: Buat issue di GitHub atau hubungi melalui project discussions.

---

## 📜 **Lisensi & Legal**

### 📋 **Lisensi**
Proyek ini dilisensikan di bawah **MIT License** - lihat file [LICENSE](LICENSE) untuk detail.

### ⚖️ **Disclaimer Legal**
- Aplikasi ini untuk **penggunaan edukasi dan pribadi saja**
- Pengguna bertanggung jawab atas kepatuhan terhadap hukum dan regulasi lokal
- Developer tidak meng-host atau mendistribusikan konten melalui aplikasi ini
- Semua konten yang diakses melalui app ini berasal dari sumber yang tersedia publik
- **Batasan usia: 18+ saja** - App ini mengakses konten dewasa

### 🤝 **Menghormati Creator Konten**
- Kami mendorong pengguna untuk mendukung creator konten asli
- App ini dirancang untuk meningkatkan pengalaman membaca, bukan mengganti channel resmi
- Pertimbangkan untuk mendukung artist dan creator melalui platform resmi

---

## � **Berkontribusi**

### 🤝 **Cara Berkontribusi**
1. **Fork** repository
2. **Buat** branch fitur (`git checkout -b feature/fitur-amazing`)
3. **Commit** perubahan Anda (`git commit -m 'Tambahkan fitur amazing'`)
4. **Push** ke branch (`git push origin feature/fitur-amazing`)
5. **Buka** Pull Request

### 📋 **Panduan Kontribusi**
- Ikuti best practice Flutter/Dart
- Pertahankan prinsip clean architecture
- Tambahkan test untuk fitur baru
- Update dokumentasi sesuai kebutuhan
- Pastikan kode diformat dengan `dart format`

---

## 🆘 **Dukungan & FAQ**

### ❓ **Pertanyaan yang Sering Diajukan**

**T: Mengapa aplikasi tidak bisa diinstal?**
J: Aktifkan "Instal dari Sumber Tidak Dikenal" di pengaturan Android. Pastikan Anda mendownload APK yang benar untuk arsitektur perangkat Anda.

**T: Download tidak muncul di galeri saya?**
J: Ini disengaja! Download bersifat privat (perlindungan `.nomedia`). Akses melalui bagian download aplikasi.

**T: Aplikasi lambat di perangkat saya?**
J: Coba APK ARM32 untuk perangkat lama, atau hapus cache aplikasi di pengaturan Android.

**T: Bisakah saya menggunakan ini di iOS?**
J: Saat ini hanya Android. Dukungan iOS mungkin dipertimbangkan untuk rilis masa depan.

### 🛠️ **Troubleshooting**
- **Loading lambat**: Periksa koneksi internet dan coba restart aplikasi
- **Masalah download**: Verifikasi izin storage dan ruang yang tersedia
- **Masalah pencarian**: Hapus cache aplikasi atau coba kata pencarian berbeda
- **Crash**: Laporkan dengan model perangkat dan versi Android Anda

---

## 🔮 **Roadmap**

### 🚀 **Fitur yang Akan Datang (v0.3.0)**
- [ ] **Cloud sync** untuk bookmark dan progress baca
- [ ] **Fitur reader lanjutan** - night mode, tema baca
- [ ] **Rekomendasi yang diperbaiki** dengan saran bertenaga AI
- [ ] **Fitur sosial** - reading list dan sharing komunitas
- [ ] **Optimasi performa** - waktu loading yang bahkan lebih cepat

### 🎯 **Tujuan Jangka Panjang**
- [ ] **Dukungan iOS** - aplikasi iOS native
- [ ] **Versi web** - PWA untuk penggunaan desktop/tablet
- [ ] **Kustomisasi lanjutan** - tema, layout, gesture
- [ ] **Arsitektur offline-first** - fungsionalitas offline lengkap

---

## 📞 **Kontak & Link**

### 🔗 **Link Proyek**
- **Repository GitHub**: [NhasixApp](https://github.com/yourusername/nhasixapp)
- **Issue Tracker**: [Laporkan Bug](https://github.com/yourusername/nhasixapp/issues)
- **Diskusi**: [Forum Komunitas](https://github.com/yourusername/nhasixapp/discussions)

### 📧 **Kontak**
- **Developer**: [Nama Anda]
- **Email**: your.email@example.com
- **Diskusi Proyek**: Tab GitHub Discussions

---

## 🎉 **Ucapan Terima Kasih**

### 🙏 **Terima Kasih Khusus**
- **Tim Flutter** - untuk framework yang luar biasa
- **Kontributor Komunitas** - untuk feedback dan saran
- **Beta Tester** - untuk membantu meningkatkan aplikasi
- **Library Open Source** - yang membuat proyek ini mungkin

### 📚 **Dibangun Dengan**
- [Flutter](https://flutter.dev/) - UI framework
- [Bloc](https://bloclibrary.dev/) - State management
- [Get It](https://pub.dev/packages/get_it) - Dependency injection
- [Sqflite](https://pub.dev/packages/sqflite) - Database lokal
- [HTTP](https://pub.dev/packages/http) - Network request

---

<div align="center">

**🌟 Star repository ini jika Anda merasa terbantu! 🌟**

Dibuat dengan ❤️ menggunakan Flutter

**⚠️ Ingat: App ini untuk pengguna 18+ saja ⚠️**

</div>

### ✅ **Fitur Utama Selesai (~70%)**
- [x] **Arsitektur Inti**: Clean Architecture dengan pola BLoC/Cubit
- [x] **Sistem Pencarian**: SearchBloc, FilterDataScreen, TagDataManager, Matrix Filter Support
- [x] **Sistem Reader**: ReaderCubit dengan 3 mode baca, persistensi pengaturan, pelacakan progress
- [x] **Framework UI**: Widget komprehensif dengan desain modern (ColorsConst, TextStyleConst)
- [x] **Navigasi**: Go Router dengan deep linking dan parameter passing
- [x] **Database**: SQLite dengan persistensi state pencarian dan pengaturan reader
- [x] **Web Scraping**: NhentaiScraper dengan anti-deteksi dan TagResolver

### ✅ **Tugas Selesai (1-7)**
- [x] **Tugas 1**: Setup struktur proyek dan dependensi inti
- [x] **Tugas 2**: Implementasi layer domain inti
- [x] **Tugas 3**: Fondasi layer data (Disederhanakan)
- [x] **Tugas 4**: Manajemen state BLoC inti
  - [x] SplashBloc, ContentBloc, SearchBloc, HomeBloc
  - [x] DetailCubit, ReaderCubit, FilterDataCubit
- [x] **Tugas 5**: Komponen UI inti
  - [x] AppMainDrawerWidget, AppMainHeaderWidget, ContentListWidget
  - [x] PaginationWidget, SortingWidget, FilterDataSearchWidget
- [x] **Tugas 6**: Alur pencarian lanjutan
  - [x] SearchScreen, FilterDataScreen, TagDataManager
  - [x] Matrix Filter Support, persistensi state
- [x] **Tugas 7**: Fungsi reader
  - [x] ReaderScreen dengan 3 mode baca
  - [x] Persistensi pengaturan, pelacakan progress, navigasi gesture
- [x] **Tugas 8**: Sistem favorit dan download
  - [x] FavoritesScreen dengan FavoriteCubit
  - [x] DownloadBloc dengan sistem antrian
  - [x] Kemampuan membaca offline
### 🎯 **Fitur Prioritas Berikutnya (30% Tersisa)**
- [ ] **Tugas 9**: Pengaturan dan preferensi
  - [ ] SettingsScreen dengan SettingsCubit
  - [ ] Kustomisasi tema dan fungsi backup
- [ ] **Tugas 10**: Fitur lanjutan dan manajemen jaringan
  - [ ] NetworkCubit untuk monitoring konektivitas
  - [ ] Manajemen tag dan statistik riwayat
- [ ] **Tugas 11**: Optimisasi performa dan testing
  - [ ] Manajemen memori dan testing perangkat nyata
  - [ ] Pembersihan proyek dan dokumentasi
- [ ] **Tugas 12**: Polish UI dan aksesibilitas
  - [ ] Animasi, loading skeleton, fitur aksesibilitas
- [ ] **Tugas 13**: Persiapan deployment
  - [ ] Branding aplikasi, konfigurasi build, testing rilis

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

### 🏠 Beranda & Detail
<div align="center">
  <img src="screenshots/flutter_01.png" width="250" alt="Layar Beranda"/>
  <img src="screenshots/flutter_02.png" width="250" alt="Grid Konten"/>
  <img src="screenshots/flutter_03.png" width="250" alt="List Konten"/>
</div>

### 🔍 Halaman Baca, detail & Mode Baca
<div align="center">
  <img src="screenshots/flutter_04.png" width="250" alt="Layar Pencarian"/>
  <img src="screenshots/flutter_05.png" width="250" alt="Filter Lanjutan"/>
  <img src="screenshots/flutter_06.png" width="250" alt="Pemilihan Tag"/>
</div>

### 📖 Halaman Baca, Menu samping, Filter & Pencarian
<div align="center">
  <img src="screenshots/flutter_07.png" width="250" alt="Detail Konten"/>
  <img src="screenshots/flutter_08.png" width="250" alt="Mode Reader"/>
  <img src="screenshots/flutter_09.png" width="250" alt="Pengaturan Reader"/>
</div>

### ⚙️ Pencarian & Filter
<div align="center">
  <img src="screenshots/flutter_10.png" width="250" alt="Pengaturan Aplikasi"/>
  <img src="screenshots/flutter_11.png" width="250" alt="Opsi Tema"/>
</div>

> **Catatan**: Screenshot menampilkan progress pengembangan saat ini dengan komponen UI Material Design 3 modern dan layout responsif.

## 📚 Referensi Pengembangan

Proyek ini mencakup materi referensi komprehensif untuk pengembangan dan testing:

### **File Referensi HTML**
Terletak di direktori `references/`, file-file ini berisi struktur website asli untuk pengembangan:

- **`halaman_utama.html`** - Struktur halaman utama dan layout grid konten
- **`halaman_search.html`** - Halaman hasil pencarian dengan opsi filtering
- **`halaman_detail.html`** - Halaman detail konten dengan metadata dan tag
- **`halaman_baca.html`** - Halaman reader dengan struktur galeri gambar
- **`halaman_last_page.html`** - Struktur pagination dan navigasi

### **Referensi Data JSON**
- **`halaman_detail.json`** - Metadata konten terstruktur untuk pengembangan API

### **Penggunaan dalam Pengembangan**
File referensi ini digunakan untuk:
- **Pengembangan Web Scraping** - Memahami struktur HTML untuk parsing
- **Referensi Desain UI/UX** - Mencocokkan layout dan fungsi website asli
- **Data Testing** - Menyediakan skenario test yang realistis
- **Perencanaan Struktur API** - Mendefinisikan model data dan format response

## 🤝 Kontribusi

Proyek ini mengikuti prinsip Clean Architecture dan menggunakan BLoC untuk manajemen state. Saat berkontribusi:

1. Ikuti pola arsitektur yang telah ditetapkan
2. Tulis test komprehensif untuk fitur baru
3. Update dokumentasi untuk perubahan signifikan
4. Ikuti panduan style Dart/Flutter
5. Gunakan file referensi di `references/` untuk memahami struktur website
6. Test dengan skenario data real menggunakan sampel HTML yang disediakan

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
- **Manajemen State**: Pola BLoC/Cubit dengan pemisahan yang tepat
- **Dependensi**: 45+ package yang dipilih dengan hati-hati
- **Cakupan Test**: Unit test dengan mocking untuk komponen kritis
- **Progress Pengembangan**: 70% selesai (7/13 tugas)
- **Status Implementasi**: Fitur inti operasional
- **Platform Target**: Android
- **SDK Minimum**: Android API 21+ (Android 5.0)
- **Pencapaian Terbaru**: Sistem pencarian lengkap dan fungsi reader dengan fitur lanjutan ✨

---

**Dibangun dengan ❤️ menggunakan Flutter dan Clean Architecture**

---

## 🌐 Bahasa Lain

- [English](README.md)
- [Bahasa Indonesia](README_ID.md) ← Anda di sini