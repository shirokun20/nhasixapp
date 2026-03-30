![Kuron](https://socialify.git.ci/shirokun20/nhasixapp/image?custom_description=&description=1&font=Source+Code+Pro&forks=1&issues=1&logo=https://github.com/shirokun20/nhasixapp/blob/master/assets/icons/logo_app.png%3Fraw%3Dtrue&name=1&owner=1&pattern=Floating+Cogs&pulls=1&stargazers=1&theme=Auto)
# 📱 Kuron - Klien tidak resmi NHentai

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)
[![18+](https://img.shields.io/badge/Batasan_Usia-18%2B-red?style=for-the-badge&logo=warning&logoColor=white)](#)
[![RELEASE](https://img.shields.io/badge/Status-RELEASE_v0.9.14-green?style=for-the-badge&logo=android&logoColor=white)](#)
[![Downloads](https://img.shields.io/github/downloads/shirokun20/nhasixapp/total?style=for-the-badge&logo=github&logoColor=white&color=007ec6)](https://github.com/shirokun20/nhasixapp/releases)
[![Hits](https://komarev.com/ghpvc/?username=shirokun20&repo=nhasixapp&style=for-the-badge&color=007ec6)](https://github.com/shirokun20/nhasixapp)
<a href="https://trakteer.id/shirokun20" target="_blank"><img src="https://img.shields.io/badge/Support_Me-Trakteer-be1e2d?style=for-the-badge&logo=ko-fi&logoColor=white" height="30"/></a>

> [!TIP]
> **[🇺🇸 Read in English](README.md)**

**Kuron** (sebelumnya NhasixApp) menghadirkan pengalaman membaca komik mobile **70% lebih cepat** dengan privasi sebagai prioritas utama. Dibangun dengan **Clean Architecture**, aplikasi ini fitur membaca offline cerdas, mode penyamaran (App Disguise), desain Material 3 yang modern, dan dukungan **multiple content providers** termasuk E-Hentai, HentaiNexus, dan Hitomi.

---

## 📥 **Download Rilis Terbaru**

[📦 **Download v0.9.14+22**](https://github.com/shirokun20/nhasixapp/releases/tag/v0.9.14)

| Varian | Ukuran | Cocok Untuk | Status |
|:-------|:----:|:---------|:------:|
| **ARM64** | 24MB | HP Modern (2019+) | ✅ Tersedia |
| **ARM32** | 22MB | HP Lama (2015-2018) | ✅ Tersedia |

---

## ✨ **Fitur Utama**

### 💬 **Dukungan Multi-Provider (BARU di v0.9.14!)**
- **E-Hentai Gallery**: Dukungan penuh dengan session adapter dan pembaca per-halaman.
- **HentaiNexus**: XOR decryption adapter dengan transformasi URL gambar.
- **Dukungan Hitomi**: Registrasi fallback-safe untuk jangkauan konten yang lebih luas.
- **Paginasi Cerdas**: Token-based & indexed pagination di semua provider.

### 💬 **Interaksi Komunitas**
- **Lihat Komentar**: Baca diskusi langsung di halaman detail.
- **Tampilan Modern**: UI komentar berbentuk kartu yang rapi di mode Terang & Gelap.
- **Data Realtime**: Menggunakan API resmi untuk data komentar yang akurat dan cepat.

### 🎯 **Membaca & Menjelajah**
- **Immersive Reader**: Mode layar penuh, transisi halus, dan rendering tajam.
- **Pencarian Cerdas**: Filter canggih berdasarkan tag, popularitas, dan tanggal.
- **Auto-Bookmark**: Lanjut baca dari halaman terakhir secara otomatis.

### 🛡️ **Privasi & Offline**
- **App Disguise**: Samarkan aplikasi menjadi Kalkulator, Catatan, atau Cuaca.
- **Download Pribadi**: Konten tersembunyi dari galeri HP (`.nomedia`).
- **Offline First**: Baca tanpa internet dengan download di latar belakang.
- **Export Library**: Backup seluruh koleksi beserta database untuk dibagikan atau dipulihkan.
- **Blur Thumbnail**: Thumbnail blur untuk privasi, aktif secara default.

### 🎨 **Performa & UX**
- **Loading Cepat**: Preloading gambar cerdas membuat bacaan 70% lebih lancar.
- **UI Adaptif**: Desain responsif dengan mode Gelap/Terang.
- **Hemat Baterai**: Penggunaan daya efisien dengan Wakelock dan caching.

---

## 📱 **Tangkapan Layar**

<details>
<summary>🖼️ Klik untuk melihat tangkapan layar (peringatan konten 18+)</summary>

<table>
  <tr>
    <td align="center"><b>Beranda & Feed</b></td>
    <td align="center"><b>Detail & Konten</b></td>
    <td align="center"><b>Mode Baca</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/flutter_02.png" width="250" alt="Layar Beranda"/></td>
    <td><img src="screenshots/flutter_13.png" width="250" alt="Layar Detail"/></td>
    <td><img src="screenshots/flutter_12.png" width="250" alt="Mode Baca"/></td>
  </tr>
  <tr>
    <td align="center"><b>Pencarian & Filter</b></td>
    <td align="center"><b>Pengaturan & Privasi</b></td>
    <td align="center"><b>Download & Offline</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/flutter_04.png" width="250" alt="Pencarian"/></td>
    <td><img src="screenshots/flutter_06.png" width="250" alt="Pengaturan"/></td>
    <td><img src="screenshots/flutter_11.png" width="250" alt="Download"/></td>
  </tr>
</table>

</details>

---

## 🛠️ **Teknologi**

| Layer | Teknologi |
|:------|:-------------|
| **Core** | Flutter 3.24+, Dart 3.5+ |
| **Arch** | Clean Architecture, BLoC Pattern, GetIt (DI) |
| **Data** | SQLite (Offline), SharedPreferences, Dio (Network) |
| **UI/UX** | CachedNetworkImage, PhotoView, Shimmer, Lottie |
| **System** | Local Notifications, Wakelock Plus, Permission Handler |

---

## 🚀 **Mulai Cepat**

### **Instalasi**
1. **Download APK** dari [Releases](https://github.com/shirokun20/nhasixapp/releases).
2. **Aktifkan Sumber Tak Dikenal** di Pengaturan > Keamanan.
3. **Install** dan nikmati!

### **Build dari Source**
```bash
git clone https://github.com/shirokun20/nhasixapp.git
cd nhasixapp
flutter pub get
flutter run
```

---

## 🆘 **Bantuan**

**FAQ**
- **Gagal Install?** Aktifkan "Sumber Tak Dikenal" dan pastikan varian CPU benar (ARM64 vs ARM32).
- **Gambar Hilang?** Cek koneksi internet atau hapus cache aplikasi.
- **Download Tidak Muncul?** Memang didesain privat agar tidak memenuhi galeri.

---

## ☕ **Dukung Pengembang**

Jika kamu menyukai **Kuron** dan ingin mendukung pengembangannya, kamu bisa mentraktir saya kopi! ☕  
Scan QRIS di bawah ini untuk berdonasi:

<p align="center">
  <img src="assets/images/donation_qris.jpeg" width="300" alt="Donasi QRIS" style="border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
</p>

> **Catatan:** Dukunganmu membantu menjaga server tetap berjalan dan update terus mengalir! 🚀

---

## 📈 **Star History**

<div align="center">
  <a href="https://www.star-history.com/#shirokun20/nhasixapp&type=date&legend=top-left">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&theme=dark&legend=top-left" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&legend=top-left" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=shirokun20/nhasixapp&type=date&legend=top-left" width="600"/>
    </picture>
  </a>
</div>

---

## 📜 **Lisensi & Legal**

**⚠️ Peringatan Konten 18+** • **Hanya Untuk Edukasi** • **Lisensi MIT**

Dilisensikan di bawah MIT License. Lihat [LICENSE](LICENSE) untuk detail.
Kami sangat mendukung kreator konten; mohon dukung rilis resmi jika memungkinkan.
