// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'NhasixApp';

  @override
  String get appSubtitle => 'NHentai';

  @override
  String get home => 'Beranda';

  @override
  String get search => 'Cari';

  @override
  String get favorites => 'Favorit';

  @override
  String get downloads => 'Unduhan';

  @override
  String get history => 'Riwayat Baca';

  @override
  String get randomGallery => 'Galeri Acak';

  @override
  String get offlineContent => 'Konten Offline';

  @override
  String get settings => 'Pengaturan';

  @override
  String get appearance => 'Tampilan';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Bahasa';

  @override
  String get imageQuality => 'Kualitas Gambar';

  @override
  String get gridColumns => 'Kolom Grid (Portrait)';

  @override
  String get reader => 'Pembaca';

  @override
  String get showSystemUIInReader => 'Tampilkan UI Sistem di Pembaca';

  @override
  String get historyCleanup => 'Pembersihan Riwayat';

  @override
  String get autoCleanupHistory => 'Pembersihan Otomatis Riwayat';

  @override
  String get automaticallyCleanOldReadingHistory =>
      'Otomatis membersihkan riwayat baca lama';

  @override
  String get cleanupInterval => 'Interval Pembersihan';

  @override
  String get howOftenToCleanupHistory => 'Seberapa sering membersihkan riwayat';

  @override
  String get maxHistoryDays => 'Maksimal Hari Riwayat';

  @override
  String get maximumDaysToKeepHistory =>
      'Maksimal hari menyimpan riwayat (0 = tanpa batas)';

  @override
  String get cleanupOnInactivity => 'Bersihkan saat Tidak Aktif';

  @override
  String get cleanHistoryWhenAppUnused =>
      'Bersihkan riwayat ketika aplikasi tidak digunakan beberapa hari';

  @override
  String get inactivityThreshold => 'Batas Tidak Aktif';

  @override
  String get daysOfInactivityBeforeCleanup =>
      'Hari tidak aktif sebelum pembersihan';

  @override
  String get resetToDefault => 'Reset ke Default';

  @override
  String get dark => 'Gelap';

  @override
  String get light => 'Terang';

  @override
  String get amoled => 'AMOLED';

  @override
  String get english => 'Inggris';

  @override
  String get japanese => 'Jepang';

  @override
  String get indonesian => 'Indonesia';

  @override
  String get low => 'Rendah';

  @override
  String get medium => 'Sedang';

  @override
  String get high => 'Tinggi';

  @override
  String get original => 'Asli';

  @override
  String hours(int count) {
    return '$count jam';
  }

  @override
  String days(int count) {
    return '$count hari';
  }

  @override
  String get download => 'Unduh';

  @override
  String get downloading => 'Mengunduh';

  @override
  String get downloadCompleted => 'Unduhan Selesai';

  @override
  String get downloadFailed => 'Unduhan Gagal';

  @override
  String downloadStarted(String title) {
    return 'Unduhan dimulai untuk \"$title\"';
  }

  @override
  String get downloadNewGalleries => 'Unduh Galeri Baru';

  @override
  String get clearAllHistory => 'Hapus Semua Riwayat';

  @override
  String get manualCleanup => 'Pembersihan Manual';

  @override
  String get removeFromHistory => 'Hapus dari Riwayat';

  @override
  String get loading => 'Memuat';

  @override
  String get error => 'Error';

  @override
  String get noData => 'Tidak Ada Data';

  @override
  String get unknownTitle => 'Judul Tidak Diketahui';

  @override
  String get noReadingHistory => 'Tidak Ada Riwayat Baca';

  @override
  String get errorLoadingFavorites => 'Error Memuat Favorit';

  @override
  String get errorLoadingHistory => 'Error Memuat Riwayat';

  @override
  String get offlineContentError => 'Error Konten Offline';

  @override
  String get downloadError => 'Error Unduhan';

  @override
  String get cancel => 'Batal';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Hapus';

  @override
  String get save => 'Simpan';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';
}
