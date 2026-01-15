---
name: scraper-debug
description: Panduan diagnosa dan perbaikan parser/scraper (Crotpedia/Nhentai) saat terjadi perubahan struktur website target.
---

# Scraper Debug Skill

Skill ini digunakan ketika fitur scraping (Nhentai/Crotpedia) rusak karena target website mengubah struktur HTML atau CSS selector mereka.

## 🕵️‍♂️ Diagnosis Phase

Sebelum mengubah kode, lakukan ini dulu:

1.  **Reproduksi Isu**: Konfirmasi URL spesifik yang gagal (misal: "Chapter list kosong" atau "Image 404").
2.  **Cek Response Mentah**: Dapatkan HTML mentah dari website.
    *   Bisa pakai `curl -A "Mozilla/5.0 ..."` atau browser Inspect Element.
    *   **PENTING**: Pastikan User-Agent yang dipakai sama dengan yang ada di `AppConstants` atau `Dio` config.
3.  **Bandingkan Struktur**: Bandingkan HTML baru dengan `test/fixtures` lama.
    *   Apakah nama class CSS berubah? (misal `.gallery-item` jadi `.g-item`)
    *   Apakah struktur DOM berubah? (misal `div > a` jadi `div > span > a`)

## 🛠️ Repair Phase

### 1. Update Fixture (Wajib!)
Jangan coding scraper dulu sebelum test case diperbarui.
*   Simpan HTML baru yang bikin error ke `test/fixtures/crotpedia/` atau `test/fixtures/nhentai/`.
*   Namakan file dengan jelas, misal `detail_page_new_layout.html`.

### 2. Update Element Selector
Buka file scraper terkait (`lib/data/datasources/remote/scraper/...`).
*   Update `querySelector` atau `getElementsByClassName` sesuai temuan di Diagnosis Phase.
*   Gunakan [Selector Gadget](https://selectorgadget.com/) atau Chrome DevTools untuk validasi selector baru.

### 3. Handle Edge Cases
*   Pastikan scraper tidak crash jika elemen tidak ditemukan (pakai `?` nullable check).
*   Berikan default value atau throw exception yang deskriptif jika elemen kritikal hilang.

### 4. Run Targeted Test
Jalankan test hanya untuk varian yang sedang diperbaiki.
```bash
flutter test test/data/datasources/remote/scraper/crotpedia_scraper_test.dart
```
**JANGAN PROCEED** sampai test pass.

## 📦 Verifikasi Akhir
1.  Pastikan tidak ada regresi pada halaman/konten tipe lama (Backward Compatibility).
2.  Cek log aplikasi (`flutter run`) untuk memastikan tidak ada warning parsing berlebihan.

---
**Contoh Prompt Penggunaan:**
> "Crotpedia ganti layout lagi. Chapter list sekarang pakai `ul.chapter-list` bukan `div.chapters`. Perbaiki scrapernya pakai skill `scraper-debug`."
