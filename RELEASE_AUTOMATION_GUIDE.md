# 📦 Panduan Rilis "Auto-Draft" (Recommended)

Dokumen ini menjelaskan alur kerja rilis yang paling efisien.
Sistem ini **menggabungkan Build & Upload** dalam satu langkah, tanpa build ganda.

## 📋 Ringkasan Alur Kerja

1.  **Push ke Branch Release**: Anda push kode ke branch `release/*`.
2.  **Otomatis Build & Upload**: GitHub Actions mem-build APK dan meng-uploadnya ke **Draft Release**.
3.  **Publish Manual**: Anda mengecek Draft tersebut di GitHub, lalu klik "Publish".

---

## 📝 Langkah-Langkah Rilis

### 1. Persiapan & Push
1.  **Update Versi** di `pubspec.yaml` (misal: `0.6.2+11`).
2.  **Update Changelog**.
3.  **Push ke Branch Release**.

```bash
git checkout -b release/0.6.2
# ... commit changes ...
git push origin release/0.6.2
```

### 2. Tunggu Notifikasi
GitHub Action akan berjalan (~5-10 menit).
Jika sukses, APK akan muncul di Telegram (opsional) dan **Draft Release** di GitHub.

### 3. Publish di GitHub
1.  Buka [Tab Releases](https://github.com/shirokun20/nhasixapp/releases).
2.  Anda akan melihat rilis baru dengan label **Draft** (misal: `v0.6.2`).
3.  Klik icon **Edit** (pensil).
4.  Cek APK yang sudah terlampir di bawah ("Assets").
5.  (Opsional) Rapikan deskripsi rilis dengan isi dari `CHANGELOG.md`.
6.  Klik tombol hijau **Publish release**.

Selesai! Tag `v0.6.2` akan otomatis dibuat oleh GitHub saat Anda klik Publish.

---

## ❓ FAQ

**Q: Apakah saya perlu buat tag manual `v0.6.2` di laptop?**
A: **JANGAN**. Biarkan GitHub yang membuat tag saat Anda klik "Publish". Jika Anda buat manual, nanti bisa konflik atau jadi double tag.

**Q: Apa bedanya Draft dengan Release biasa?**
A: Draft tidak bisa dilihat user lain dan tidak memicu notifikasi sampai Anda Publish.
