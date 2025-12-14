# 📦 Panduan Rilis Manual (Semi-Otomatis)

Dokumen ini menjelaskan alur kerja rilis aplikasi. Kita menggunakan CI (Continuous Integration) untuk build APK, namun proses rilis di GitHub dilakukan secara manual untuk kontrol penuh.

## 📋 Ringkasan Alur Kerja

1.  **Push ke Branch Release**: GitHub Actions otomatis mem-build APK (`release/*`).
2.  **Dapatkan APK**: APK dikirim ke Telegram atau tersedia di Artifacts.
3.  **Buat Rilis GitHub**: Upload APK tersebut secara manual ke halaman Release.

---

## 📝 Langkah-Langkah Rilis

### 1. Persiapan & Push Code
1.  **Update Versi** di `pubspec.yaml` (misal: `0.6.2+11`).
2.  **Update Changelog** di `CHANGELOG.md`.
3.  **Commit & Push** ke branch release.

```bash
git checkout -b release/0.6.2
git add .
git commit -m "chore(release): prepare 0.6.2"
git push origin release/0.6.2
```

### 2. Tunggu Build Selesai
Setelah push, buka tab **[Actions](https://github.com/shirokun20/nhasixapp/actions)**.
- Workflow **Build and Upload APK** akan berjalan.
- Tunggu hingga selesai (hijau ✅).
- **Hasil**:
    - APK akan terkirim ke **Telegram Bot**.
    - Atau download dari bagian **Artifacts** di halaman Actions tersebut.

### 3. Buat Release di GitHub
1.  Buka tab **[Releases](https://github.com/shirokun20/nhasixapp/releases)**.
2.  Klik **Draft a new release**.
3.  **Choose a tag**: Buat tag baru (contoh: `v0.6.2`).
4.  **Target**: Pilih branch `release/0.6.2` (atau master jika sudah merge).
5.  **Release title**: `v0.6.2` (atau judul lain).
6.  **Description**: Copy-paste dari `CHANGELOG.md`.
7.  **Attach binaries**: Drag & Drop file APK yang sudah Anda download tadi.
8.  Klik **Publish release**.

---

## ❓ FAQ

**Q: Mengapa tidak otomatis upload saat tag?**
A: Untuk mencegah build ganda (double build) dan memberikan kontrol lebih sebelum rilis dipublikasikan.

**Q: Di mana saya dapat APK-nya?**
A: Cek **Telegram** (jika bot aktif) atau download zip dari **Artifacts** di detail GitHub Action yang sukses.
