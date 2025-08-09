# Requirements Document

## Introduction

Aplikasi NhentaiApp adalah sebuah aplikasi mobile Flutter yang berfungsi sebagai clone dari website nhentai.net. Aplikasi ini dirancang untuk memberikan pengalaman browsing yang lebih baik dan user-friendly untuk mengakses konten manga/doujinshi dengan fitur-fitur seperti pencarian, bookmark, download offline, dan manajemen koleksi personal.

## Requirements

### Requirement 1

**User Story:** Sebagai pengguna, saya ingin dapat mengakses konten dari nhentai.net melalui aplikasi mobile, sehingga saya dapat browsing dengan lebih nyaman di perangkat mobile.

#### Acceptance Criteria

1. WHEN aplikasi dibuka THEN sistem SHALL menampilkan splash screen dengan proses initial loading
2. WHEN proses initial loading berhasil THEN sistem SHALL mengarahkan pengguna ke main screen
3. IF proses initial loading gagal THEN sistem SHALL menampilkan pesan error dan opsi untuk mencoba lagi
4. WHEN pengguna berada di main screen THEN sistem SHALL menampilkan daftar konten terbaru dari nhentai.net dengan tema hitam default

### Requirement 2

**User Story:** Sebagai pengguna, saya ingin dapat mencari konten berdasarkan berbagai kriteria seperti tag, artist, language dengan alur pencarian yang tidak langsung mengirim request, sehingga saya dapat menyusun filter dengan tenang sebelum melakukan pencarian.

#### Acceptance Criteria

1. WHEN pengguna mengakses fitur pencarian THEN sistem SHALL menampilkan form pencarian dengan opsi filter tanpa langsung mengirim API request
2. WHEN pengguna memasukkan kata kunci pencarian THEN sistem SHALL menyimpan input di state tanpa memicu API call
3. WHEN pengguna memilih filter tag, artist, character, parody, atau group THEN sistem SHALL menampilkan interface pencarian untuk data tersebut dari assets/json/tags.json dengan halaman terpisah yang modern
4. WHEN pengguna memilih multiple filter THEN sistem SHALL menyimpan semua filter di state dengan opsi include/exclude menggunakan FilterItem
5. WHEN pengguna memilih filter language atau category THEN sistem SHALL hanya mengizinkan satu pilihan
6. WHEN pengguna menekan tombol "Search" atau "Apply" THEN sistem SHALL mengirim API request, menyimpan state pencarian ke local datasource, dan kembali ke MainScreen dengan hasil pencarian
7. WHEN aplikasi dibuka ulang THEN sistem SHALL memuat state pencarian terakhir dari local datasource dan menampilkan hasil di MainScreen
8. WHEN pengguna mengakses filter data THEN sistem SHALL menampilkan halaman terpisah dengan pencarian untuk Tags, Artists, Characters, Parodies, dan Groups dengan UI yang modern
9. WHEN pengguna melakukan pencarian filter data THEN sistem SHALL menggunakan data dari assets/json/tags.json untuk memberikan hasil yang akurat

### Requirement 3

**User Story:** Sebagai pengguna, saya ingin dapat melihat detail konten dan membaca manga/doujinshi, sehingga saya dapat menikmati konten yang saya pilih.

#### Acceptance Criteria

1. WHEN pengguna memilih sebuah konten THEN sistem SHALL menampilkan halaman detail dengan informasi lengkap
2. WHEN pengguna berada di halaman detail THEN sistem SHALL menampilkan cover, title, tags, artist, language, dan jumlah halaman
3. WHEN pengguna menekan tombol "Read" THEN sistem SHALL membuka reader mode untuk membaca konten
4. WHEN pengguna berada di reader mode THEN sistem SHALL menampilkan halaman-halaman manga dengan navigasi yang mudah
5. WHEN pengguna swipe atau tap THEN sistem SHALL berpindah ke halaman selanjutnya atau sebelumnya

### Requirement 4

**User Story:** Sebagai pengguna, saya ingin dapat menyimpan konten favorit saya, sehingga saya dapat dengan mudah mengaksesnya kembali di kemudian hari.

#### Acceptance Criteria

1. WHEN pengguna berada di halaman detail konten THEN sistem SHALL menampilkan tombol bookmark/favorite
2. WHEN pengguna menekan tombol bookmark THEN sistem SHALL menyimpan konten ke daftar favorit
3. WHEN pengguna mengakses halaman favorit THEN sistem SHALL menampilkan semua konten yang telah di-bookmark
4. WHEN pengguna ingin menghapus bookmark THEN sistem SHALL menyediakan opsi untuk menghapus dari favorit
5. WHEN konten sudah di-bookmark THEN sistem SHALL menampilkan indikator visual bahwa konten tersebut sudah difavoritkan

### Requirement 5

**User Story:** Sebagai pengguna, saya ingin dapat mendownload konten untuk dibaca secara offline, sehingga saya dapat mengakses konten tanpa koneksi internet.

#### Acceptance Criteria

1. WHEN pengguna berada di halaman detail konten THEN sistem SHALL menampilkan tombol download
2. WHEN pengguna menekan tombol download THEN sistem SHALL memulai proses download dengan progress indicator
3. WHEN proses download selesai THEN sistem SHALL menyimpan konten di storage lokal dan memberikan notifikasi
4. WHEN pengguna mengakses halaman download THEN sistem SHALL menampilkan daftar konten yang telah didownload
5. WHEN pengguna tidak memiliki koneksi internet THEN sistem SHALL tetap dapat mengakses konten yang telah didownload

### Requirement 6

**User Story:** Sebagai pengguna, saya ingin aplikasi memiliki interface yang intuitif dan responsif dengan navigasi sederhana, sehingga saya dapat menggunakan aplikasi dengan mudah dan nyaman.

#### Acceptance Criteria

1. WHEN aplikasi dibuka THEN sistem SHALL menampilkan UI dengan tema hitam default dan design yang konsisten
2. WHEN pengguna berinteraksi dengan elemen UI THEN sistem SHALL memberikan feedback visual yang jelas
3. WHEN aplikasi digunakan di berbagai ukuran layar THEN sistem SHALL menyesuaikan layout secara responsif
4. WHEN pengguna melakukan navigasi THEN sistem SHALL menggunakan tombol next/previous untuk pagination tanpa infinite scroll
5. WHEN terjadi loading data THEN sistem SHALL menampilkan loading indicator yang informatif
6. WHEN pengguna mengakses drawer menu THEN sistem SHALL menampilkan menu dengan fitur: Downloaded galleries, Random gallery, Favorite galleries, dan View history
7. WHEN pengguna berada di MainScreen THEN sistem SHALL menampilkan opsi sorting (newest, popular, etc.) yang dapat digunakan baik untuk konten normal maupun hasil pencarian
8. WHEN pengguna mengubah sorting di MainScreen THEN sistem SHALL menerapkan sorting tersebut pada konten yang sedang ditampilkan (normal atau hasil pencarian)

### Requirement 7

**User Story:** Sebagai pengguna, saya ingin dapat mengatur preferensi aplikasi seperti tema, bahasa default, dan kualitas gambar, sehingga saya dapat menyesuaikan aplikasi sesuai kebutuhan saya.

#### Acceptance Criteria

1. WHEN pengguna mengakses halaman settings THEN sistem SHALL menampilkan berbagai opsi pengaturan
2. WHEN pengguna mengubah tema aplikasi THEN sistem SHALL menerapkan tema yang dipilih secara real-time
3. WHEN pengguna mengatur bahasa default untuk pencarian THEN sistem SHALL menyimpan preferensi tersebut
4. WHEN pengguna mengatur kualitas gambar THEN sistem SHALL menerapkan setting tersebut untuk semua gambar yang dimuat
5. WHEN pengguna mengubah pengaturan THEN sistem SHALL menyimpan perubahan secara persisten

### Requirement 8

**User Story:** Sebagai pengguna, saya ingin aplikasi dapat menangani error dengan baik dan memberikan informasi yang jelas, sehingga saya dapat memahami masalah yang terjadi dan cara mengatasinya.

#### Acceptance Criteria

1. WHEN terjadi error koneksi internet THEN sistem SHALL menampilkan pesan error yang informatif dengan opsi retry
2. WHEN terjadi error saat loading konten THEN sistem SHALL menampilkan placeholder error dengan tombol refresh
3. WHEN terjadi error saat download THEN sistem SHALL memberikan notifikasi error dan opsi untuk mencoba lagi
4. WHEN aplikasi crash atau force close THEN sistem SHALL menyimpan state terakhir dan restore saat dibuka kembali
5. WHEN terjadi error parsing data THEN sistem SHALL log error untuk debugging dan menampilkan fallback UI
6. WHEN aplikasi menggunakan HTTP client THEN sistem SHALL tidak dispose dio/httpClient untuk menghindari error koneksi

### Requirement 9

**User Story:** Sebagai pengguna, saya ingin dapat mengakses filter data yang lengkap dengan interface yang modern dan mudah digunakan, sehingga saya dapat menemukan konten yang spesifik dengan mudah.

#### Acceptance Criteria

1. WHEN pengguna mengakses advanced filters THEN sistem SHALL menyediakan opsi untuk membuka halaman filter data terpisah
2. WHEN pengguna berada di halaman filter data THEN sistem SHALL menampilkan interface modern untuk mencari Tags, Artists, Characters, Parodies, dan Groups
3. WHEN pengguna mencari dalam filter data THEN sistem SHALL menggunakan data dari assets/json/tags.json untuk memberikan hasil yang akurat dan cepat
4. WHEN pengguna memilih item dari filter data THEN sistem SHALL memberikan opsi include/exclude dengan visual yang jelas
5. WHEN pengguna selesai memilih filter THEN sistem SHALL dapat kembali ke SearchScreen dengan filter yang telah dipilih
6. WHEN _buildAdvancedFilters terlalu kompleks THEN sistem SHALL memindahkan fungsi tersebut ke halaman terpisah untuk meningkatkan UX
7. WHEN pengguna menggunakan filter data THEN sistem SHALL menyimpan pilihan filter dengan format FilterItem yang mendukung include/exclude

### Requirement 10

**User Story:** Sebagai developer, saya ingin semua fitur aplikasi ditest tidak hanya melalui analisis kode tetapi juga pada perangkat nyata, sehingga saya dapat memastikan aplikasi berfungsi dengan baik di lingkungan produksi.

#### Acceptance Criteria

1. WHEN melakukan testing fitur THEN sistem SHALL ditest pada perangkat Android fisik untuk memverifikasi performa
2. WHEN testing UI components THEN sistem SHALL ditest pada berbagai ukuran layar perangkat nyata
3. WHEN testing download functionality THEN sistem SHALL ditest dengan koneksi internet yang bervariasi pada perangkat nyata
4. WHEN testing offline functionality THEN sistem SHALL ditest dengan benar-benar memutus koneksi internet pada perangkat fisik
5. WHEN testing reader mode THEN sistem SHALL ditest dengan gesture navigation pada perangkat nyata
6. WHEN testing performance THEN sistem SHALL dimonitor penggunaan memory dan CPU pada perangkat fisik
7. WHEN testing background tasks THEN sistem SHALL diverifikasi berjalan dengan benar saat aplikasi di background pada perangkat nyata