# 🔄 Perubahan Alur Search - NhentaiApp

## 🎯 Tujuan
Mengubah alur fitur pencarian agar:
- Input dari pengguna **tidak langsung mengirim API request**
- Semua filter dan query ditampung dulu di state
- API dipanggil **hanya saat pengguna menekan tombol "Search"**
- State pencarian (query dan filter) disimpan di local datasource agar bisa dipulihkan saat aplikasi dibuka ulang

---

## 🚧 Alur Lama (Sebelum)
1. User mengetik query → langsung trigger debounce API call
2. Filter berubah → langsung trigger API call
3. Tidak ada tombol "Search", hasil muncul otomatis

---

## ✅ Alur Baru (Sesudah)
1. User mengetik query atau memilih filter → nilai disimpan di state `SearchBloc`
2. Tidak ada permintaan ke API saat input/ubah filter
3. Ada pencarian untuk kumpulan data `Filter Tags, Artists, Characters, Parodies dan Groups` yang dipindahkan ke halaman baru [Filter Data](./filter-data.md) (ini terserah bentuknya gimana yang penting modern) karena datanya banyak, bisa di check di `assets/json/tags.json` 
4. Saat user menekan tombol "Search atau Apply":
   - Semua query dan filter digabung
   - Disimpan di `local datasource`
   - Kembali ke halaman `MainScreen`
   - Hasil pencarian ditampilkan
5. State pencarian (query dan filter) disimpan di local datasource agar bisa dipulihkan saat aplikasi dibuka ulang.

---

## 🧩 Perubahan Teknis

### 🔧 BLoC
- `SearchBloc`:
  - Tambahkan event `UpdateSearchFilter` → untuk mengupdate state filter dan query tanpa memicu API call
  - Tambahkan event `SearchSubmitted` → untuk memicu API call berdasarkan filter dan query yang sudah diupdate
  - Debounce hanya berlaku saat input teks di UI agar responsif, namun API call hanya dipicu saat tombol Search atau Apply ditekan

### 🖼️ UI
- Filter dan query tetap interaktif, tapi tidak langsung memicu pencarian
- Ada `input text` untuk pencarian data `Tags`, `Artists`, `Characters`, `Parodies` dan `Groups`. 
- Bedakan antara `input Search Query` dan `input Search Tags, Artists, Characters, Parodies` dan `Groups` (ini atur dengan UI Modern)
- `SearchFilterWidget` harus bisa menangani:
  - multiple select untuk beberapa tipe tag, group, character, parody dan artist (include/exclude)
  - single select untuk `language` dan `category`

### 💾 Penyimpanan State
- Simpan state `SearchFilter` yang aktif di local datasource saat tombol `Search` atau `Apply` ditekan
- Saat aplikasi dibuka ulang, load state `SearchFilter` dari local datasource dan tampilkan hasil pencarian sesuai state tersebut di MainScreen

---

## 🔢 Format URL yang Diharapkan

Contoh output query yang dihasilkan saat user menekan tombol Search:

```
search/?q=+-tag:"a1"+-artist:"b1"+-tag:"a2"+language:"english"+-tag:"a3"+-tag:"a4"+-tag:"a5"+-tag:"a6"+-tag:"a7"+-tag:"a8"+-tag:"a9"+-artist:"b2"&page=1
```

### Catatan Format
- Semua filter dikonversi menjadi bagian dari query string `q=...`
- Prefix `-` untuk menandai **exclude**
- Filter yang multiple (seperti tag, artist) boleh muncul **berulang**
- Filter seperti `language` dan `category` hanya muncul **satu kali**
- Ganti kode contoh SearchFilter dengan model baru yang menggunakan FilterItem untuk menggabungkan include/exclude.

---

## 🧪 Ubah contoh struktur `SearchFilter` menjadi seperti ini

```dart
class FilterItem {
  final String value;
  final bool isExcluded; // true = exclude, false = include

  FilterItem({required this.value, this.isExcluded = false});
}

class SearchFilter extends Equatable {
  final String? query;
  final List<FilterItem> tags;
  final List<FilterItem> artists;
  final List<FilterItem> characters;
  final List<FilterItem> parodies;
  final List<FilterItem> groups;
  final String? language;   // ❎ Single
  final String? category;   // ❎ Single
  final int page;
  final SortOption sortBy;
  final bool popular; // Popular filter
  final IntRange? pageCountRange;
}
```

---

## 📌 Matrix Filter Support

| Filter      | Multiple | Prefix Format   | Keterangan              |
|-------------|----------|------------------|--------------------------|
| Tag         | ✅       | `tag:"..."`     | Bisa include/exclude     |
| Artist      | ✅       | `artist:"..."`  | Bisa include/exclude     |
| Character   | ✅       | `character:"..."` | Bisa include/exclude     |
| Parody      | ✅       | `parody:"..."`    | Bisa include/exclude     |
| Group       | ✅       | `group:"..."`     | Bisa include/exclude     |
| Language    | ❎       | `language:"..."`  | Hanya satu boleh dipilih |
| Category    | ❎       | `category:"..."`  | Hanya satu boleh dipilih |

---

## ✅ Acceptance Criteria

- [ ] Tidak ada API call saat user mengetik atau memilih filter
- [ ] Tombol "Search" akan mengirimkan pencarian baru
- [ ] Semua filter (kecuali language & category) bisa multiple
- [ ] Format query sesuai contoh
- [ ] UI interaktif dan responsif terhadap state filter
- [ ] Ketika tombol Search ditekan, kembali ke MainScreen dan mentrigger hasil data
- [ ] Ada perbedaan perilaku saat menggunakan search dan tidak
- [ ] Isi dari search disimpan di local datasource agar bisa ditampilkan kembali saat aplikasi dibuka ulang di MainScreen (ubah baseurl nya)

---

## 📁 Referensi
- `.kiro/specs/nhentai-clone-app/components-list.md`: `SearchScreen`, `SearchBloc`, `SearchFilterWidget` ⏳
- `.kiro/specs/nhentai-clone-app/design.md`: Struktur data `SearchFilter`, arsitektur Clean Architecture
- `.kiro/specs/nhentai-clone-app/requirements.md`: Requirements #2 (filter pencarian) dan #6 (UI intuitif)

---

## 📁 Referensi Tambahan

- Data JSON untuk tags dapat ditemukan di `assets/json/tags.json`

---
