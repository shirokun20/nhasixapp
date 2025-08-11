# Requirements Document

## Introduction

Fitur Reader Settings Persistence memungkinkan pengguna untuk menyimpan dan mengelola preferensi reading mereka secara persisten. Sistem akan menyimpan pengaturan seperti reading mode, keep screen on, dan preferensi lainnya menggunakan SharedPreferences, sehingga pengaturan tetap tersimpan antar sesi aplikasi.

## Requirements

### Requirement 1

**User Story:** Sebagai pengguna, saya ingin reading mode yang saya pilih tersimpan secara otomatis, sehingga saya tidak perlu mengatur ulang setiap kali membuka konten baru.

#### Acceptance Criteria

1. WHEN pengguna mengubah reading mode dari Horizontal Pages ke Vertical Pages THEN sistem SHALL menyimpan preferensi tersebut ke SharedPreferences
2. WHEN pengguna mengubah reading mode dari Vertical Pages ke Continuous Scroll THEN sistem SHALL menyimpan preferensi tersebut ke SharedPreferences
3. WHEN pengguna membuka konten baru THEN sistem SHALL menggunakan reading mode yang tersimpan sebagai default
4. WHEN aplikasi pertama kali dijalankan THEN sistem SHALL menggunakan Horizontal Pages sebagai default reading mode
5. WHEN terjadi error saat menyimpan reading mode THEN sistem SHALL tetap menggunakan mode yang dipilih untuk sesi saat ini

### Requirement 2

**User Story:** Sebagai pengguna, saya ingin pengaturan keep screen on tersimpan, sehingga layar tidak mati saat saya sedang membaca.

#### Acceptance Criteria

1. WHEN pengguna mengaktifkan keep screen on THEN sistem SHALL menyimpan pengaturan tersebut ke SharedPreferences
2. WHEN pengguna menonaktifkan keep screen on THEN sistem SHALL menyimpan pengaturan tersebut ke SharedPreferences
3. WHEN pengguna membuka reader dengan konten baru THEN sistem SHALL menerapkan pengaturan keep screen on yang tersimpan
4. WHEN aplikasi pertama kali dijalankan THEN sistem SHALL menggunakan false sebagai default untuk keep screen on
5. WHEN pengguna keluar dari reader THEN sistem SHALL menonaktifkan wakelock jika keep screen on diaktifkan

### Requirement 3

**User Story:** Sebagai pengguna, saya ingin dapat mereset semua pengaturan reader ke default, sehingga saya dapat memulai dengan pengaturan bersih jika diperlukan.

#### Acceptance Criteria

1. WHEN pengguna mengakses settings dan memilih reset reader settings THEN sistem SHALL menampilkan dialog konfirmasi
2. WHEN pengguna mengkonfirmasi reset THEN sistem SHALL menghapus semua reader preferences dari SharedPreferences
3. WHEN reset selesai THEN sistem SHALL menggunakan nilai default untuk semua pengaturan reader
4. WHEN pengguna membatalkan reset THEN sistem SHALL mempertahankan pengaturan yang ada
5. WHEN reset berhasil THEN sistem SHALL menampilkan notifikasi bahwa pengaturan telah direset

### Requirement 4

**User Story:** Sebagai pengguna, saya ingin pengaturan reader dapat diakses dan diubah dari settings modal, sehingga saya dapat mengatur preferensi dengan mudah.

#### Acceptance Criteria

1. WHEN pengguna membuka reader settings modal THEN sistem SHALL menampilkan pengaturan yang tersimpan dengan nilai yang benar
2. WHEN pengguna mengubah reading mode dari settings modal THEN sistem SHALL menerapkan perubahan secara real-time dan menyimpannya
3. WHEN pengguna mengubah keep screen on dari settings modal THEN sistem SHALL menerapkan perubahan secara real-time dan menyimpannya
4. WHEN pengguna menutup settings modal THEN sistem SHALL mempertahankan semua perubahan yang telah disimpan
5. WHEN terjadi error saat mengubah pengaturan THEN sistem SHALL menampilkan pesan error dan mengembalikan ke nilai sebelumnya

### Requirement 5

**User Story:** Sebagai developer, saya ingin sistem reader settings dapat menangani edge cases dengan baik, sehingga aplikasi tetap stabil dalam berbagai kondisi.

#### Acceptance Criteria

1. WHEN SharedPreferences tidak dapat diakses THEN sistem SHALL menggunakan nilai default dan log error untuk debugging
2. WHEN data yang tersimpan corrupt atau invalid THEN sistem SHALL menggunakan nilai default dan membersihkan data corrupt
3. WHEN aplikasi di-upgrade dan ada perubahan struktur settings THEN sistem SHALL melakukan migrasi data dengan aman
4. WHEN memory rendah saat menyimpan settings THEN sistem SHALL menangani error dengan graceful dan tidak crash
5. WHEN multiple instance aplikasi berjalan THEN sistem SHALL menangani concurrent access ke SharedPreferences dengan aman