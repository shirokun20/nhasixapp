# 🚀 Panduan Otomatisasi Rilis (GitHub Actions)

Dokumen ini menjelaskan cara kerja sistem rilis otomatis yang telah dipasang di repository ini.

## 📋 Ringkasan Alur Kerja

Sistem ini menggunakan **GitHub Actions** (`.github/workflows/build.yml`) untuk secara otomatis:
1.  Membangun APK (Release Optimized).
2.  Membuat "Release" baru di halaman GitHub.
3.  Mengunggah file APK ke rilis tersebut.

Semua ini terjadi otomatis ketika Anda melakukan **Push Tag** (contoh: `v0.6.1`).

---

## 🛠️ Persiapan (One-Time Setup)

Workflow ini sudah dikonfigurasi. Pastikan file `.github/workflows/build.yml` memiliki bagian ini:

```yaml
on:
  push:
    branches: [ master, 'release/*' ]
    tags: [ 'v*' ] # <- PENTING: Memicu saat tag v... di-push

jobs:
  build:
    # ... step build standar ...
    
    steps:
      # ... steps sebelumnya ...

      # Upload ke GitHub Release
      - name: Release to GitHub
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v1
        with:
          files: apk-output/*.apk
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

> **Catatan**: `GITHUB_TOKEN` disediakan otomatis oleh GitHub, Anda tidak perlu setting secret tambahan untuk ini.

---

## 📝 Langkah-Langkah Rilis (Tutorial)

Berikut adalah urutan langkah yang harus dilakukan setiap kali ingin merilis versi baru (misal: `0.6.2`).

### 1. Persiapan Kode Lokal
Lakukan di laptop Anda:
1.  **Update Versi** di `pubspec.yaml` (misal: `0.6.2+11`).
2.  **Update Changelog** di `CHANGELOG.md`.
3.  **Commit** perubahan tersebut.

```bash
git add .
git commit -m "chore(release): prepare 0.6.2"
```

### 2. Membuat Tag
Buat tag git yang diawali dengan huruf `v` (sesuai config `'v*'`).

```bash
git tag v0.6.2
```

### 3. Push ke GitHub
Push commit dan tag ke repository.

```bash
git push origin master  # atau nama branch Anda
git push origin v0.6.2
```

### 4. Selesai! (Otomatis)
Setelah Anda melakukan `git push origin v...`:
1.  Buka tab **[Actions](https://github.com/shirokun20/nhasixapp/actions)** di GitHub.
2.  Anda akan melihat workflow berjalan dengan nama tag tersebut.
3.  Tunggu hingga selesai (biasanya 5-10 menit).
4.  Setelah hijau (sukses), buka tab **[Releases](https://github.com/shirokun20/nhasixapp/releases)**.
5.  Rilis baru akan muncul dengan APK yang sudah terlampir.

---

## ❓ FAQ

**Q: Apakah saya perlu build APK manual di laptop?**
A: **Tidak perlu**. GitHub Actions yang akan mem-build APK dari kode yang ada di tag tersebut.

**Q: Bagaimana jika build gagal?**
A: Cek tab **Actions** untuk melihat log error. Biasanya notifikasi juga masuk ke Telegram jika sudah disetting.

**Q: Apakah release note-nya otomatis terisi?**
A: Ya, karena kita pasang `generate_release_notes: true`, GitHub akan otomatis melisting Pull Request yang masuk ke rilis ini. Anda bisa mengedit deskripsinya secara manual di GitHub jika ingin lebih rapi (copy-paste dari CHANGELOG.md).
