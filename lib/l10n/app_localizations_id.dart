// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'NhentaiApp';

  @override
  String get appSubtitle => 'Pengalaman Membaca yang Ditingkatkan';

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
  String get offline => 'Offline';

  @override
  String get searchHint => 'Cari konten...';

  @override
  String get searchPlaceholder => 'Masukkan kata kunci pencarian';

  @override
  String get noResults => 'Tidak ada hasil ditemukan';

  @override
  String get searchSuggestions => 'Saran Pencarian';

  @override
  String get suggestions => 'Saran:';

  @override
  String get tapToLoadContent => 'Ketuk untuk memuat konten';

  @override
  String get checkInternetConnection => 'Periksa koneksi internet Anda';

  @override
  String get trySwitchingNetwork => 'Coba beralih antara WiFi dan data seluler';

  @override
  String get restartRouter => 'Restart router jika menggunakan WiFi';

  @override
  String get checkWebsiteStatus => 'Periksa apakah situs web sedang down';

  @override
  String get cloudflareBypassMessage =>
      'Situs web dilindungi oleh Cloudflare. Kami sedang mencoba untuk melewati proteksi.';

  @override
  String get forceBypass => 'Paksa Bypass';

  @override
  String get unableToProcessData =>
      'Tidak dapat memproses data yang diterima. Struktur situs mungkin telah berubah.';

  @override
  String get reportIssue => 'Laporkan Masalah';

  @override
  String serverReturnedError(int statusCode) {
    return 'Server mengembalikan kesalahan $statusCode. Layanan mungkin sedang tidak tersedia.';
  }

  @override
  String get searchResults => 'Hasil Pencarian';

  @override
  String get failedToOpenBrowser => 'Gagal membuka browser';

  @override
  String get viewDownloads => 'Lihat Unduhan';

  @override
  String get clearSearch => 'Bersihkan Pencarian';

  @override
  String get clearFilters => 'Bersihkan Filter';

  @override
  String get anyLanguage => 'Bahasa Apa Saja';

  @override
  String get anyCategory => 'Kategori Apa Saja';

  @override
  String get errorOpeningFilter => 'Error membuka pilihan filter';

  @override
  String get errorBrowsingTag => 'Error menjelajahi tag';

  @override
  String get shuffleToNextGallery => 'Acak ke galeri berikutnya';

  @override
  String get contentHidden => 'Konten Disembunyikan';

  @override
  String get tapToViewAnyway => 'Ketuk untuk tetap melihat';

  @override
  String get checkOutThisGallery => 'Lihat galeri ini!';

  @override
  String galleriesPreloaded(int count) {
    return '$count galeri dimuat sebelumnya';
  }

  @override
  String get oopsSomethingWentWrong => 'Ups! Ada yang salah';

  @override
  String get cleanupInfo => 'Info Pembersihan';

  @override
  String get loadingHistory => 'Memuat riwayat...';

  @override
  String get clearingHistory => 'Menghapus riwayat...';

  @override
  String get areYouSureClearHistory =>
      'Apakah Anda yakin ingin menghapus semua riwayat bacaan? Tindakan ini tidak dapat dibatalkan.';

  @override
  String get justNow => 'Baru saja';

  @override
  String get artistCg => 'artist cg';

  @override
  String get gameCg => 'game cg';

  @override
  String get manga => 'manga';

  @override
  String get doujinshi => 'doujinshi';

  @override
  String get imageSet => 'image set';

  @override
  String get cosplay => 'cosplay';

  @override
  String get artistcg => 'artistcg';

  @override
  String get gamecg => 'gamecg';

  @override
  String get bigBreasts => 'big breasts';

  @override
  String get soleFemale => 'sole female';

  @override
  String get soleMale => 'sole male';

  @override
  String get fullColor => 'full color';

  @override
  String get schoolgirlUniform => 'schoolgirl uniform';

  @override
  String get tryADifferentSearchTerm => 'Coba istilah pencarian yang berbeda';

  @override
  String get unknownError => 'Error tidak diketahui';

  @override
  String get loadingOfflineContent => 'Memuat konten offline...';

  @override
  String get excludeTags => 'Kecualikan Tag';

  @override
  String get excludeGroups => 'Kecualikan Grup';

  @override
  String get excludeCharacters => 'Kecualikan Karakter';

  @override
  String get excludeParodies => 'Kecualikan Parodi';

  @override
  String get excludeArtists => 'Kecualikan Artis';

  @override
  String get noResultsFound => 'Tidak ada hasil ditemukan';

  @override
  String get tryAdjustingFilters =>
      'Coba sesuaikan filter pencarian atau istilah pencarian Anda.';

  @override
  String get tryDifferentKeywords => 'Coba kata kunci berbeda';

  @override
  String get networkError =>
      'Error jaringan. Silakan periksa koneksi Anda dan coba lagi.';

  @override
  String get serverError => 'Kesalahan server';

  @override
  String get accessBlocked => 'Akses diblokir. Mencoba melewati proteksi...';

  @override
  String get tooManyRequests =>
      'Terlalu banyak permintaan. Silakan tunggu sebentar dan coba lagi.';

  @override
  String get errorProcessingResults =>
      'Error memproses hasil pencarian. Silakan coba lagi.';

  @override
  String get invalidSearchParameters =>
      'Parameter pencarian tidak valid. Silakan periksa input Anda.';

  @override
  String get unexpectedError =>
      'Terjadi error yang tidak terduga. Silakan coba lagi.';

  @override
  String get retryBypass => 'Coba Bypass Lagi';

  @override
  String get retryConnection => 'Coba Koneksi Lagi';

  @override
  String get retrySearch => 'Coba Cari Lagi';

  @override
  String get networkErrorTitle => 'Error Jaringan';

  @override
  String get serverErrorTitle => 'Error Server';

  @override
  String get unknownErrorTitle => 'Error Tidak Diketahui';

  @override
  String get loadingContent => 'Memuat konten...';

  @override
  String get refreshingContent => 'Menyegarkan konten...';

  @override
  String get loadingMoreContent => 'Memuat konten lainnya...';

  @override
  String get latestContent => 'Konten Terbaru';

  @override
  String get noInternetConnection => 'Tidak ada koneksi internet';

  @override
  String get serverTemporarilyUnavailable =>
      'Server sementara tidak tersedia. Silakan coba lagi nanti.';

  @override
  String get failedToLoadContent => 'Gagal memuat konten';

  @override
  String get cloudflareProtectionDetected =>
      'Proteksi Cloudflare terdeteksi. Silakan tunggu dan coba lagi.';

  @override
  String get tooManyRequestsWait =>
      'Terlalu banyak permintaan. Silakan tunggu sebentar sebelum mencoba lagi.';

  @override
  String get noContentFoundMatching =>
      'Tidak ada konten yang ditemukan sesuai kriteria pencarian Anda. Coba sesuaikan filter Anda.';

  @override
  String noContentFoundForTag(String tagName) {
    return 'Tidak ada konten ditemukan untuk tag \"$tagName\".';
  }

  @override
  String get removeSomeFilters => 'Hapus beberapa filter';

  @override
  String get checkSpelling => 'Periksa ejaan';

  @override
  String get useGeneralTerms => 'Gunakan istilah pencarian yang lebih umum';

  @override
  String get browsePopularContent => 'Jelajahi konten populer';

  @override
  String get tryBrowsingOtherTags => 'Coba jelajahi tag lain';

  @override
  String get checkPopularContent => 'Periksa konten populer';

  @override
  String get useSearchFunction => 'Gunakan fungsi pencarian';

  @override
  String get checkInternetConnectionSuggestion =>
      'Periksa koneksi internet Anda';

  @override
  String get tryRefreshingPage => 'Coba muat ulang halaman';

  @override
  String get browsePopularContentSuggestion => 'Jelajahi konten populer';

  @override
  String get failedToInitializeSearch => 'Gagal menginisialisasi pencarian';

  @override
  String noResultsFoundFor(String query) {
    return 'Tidak ada hasil ditemukan untuk \"$query\"';
  }

  @override
  String get searchingWithFilters => 'Mencari dengan filter...';

  @override
  String get noResultsFoundWithCurrentFilters =>
      'Tidak ada hasil ditemukan dengan filter saat ini';

  @override
  String invalidFilter(String errors) {
    return 'Filter tidak valid: $errors';
  }

  @override
  String invalidSearchFilter(String errors) {
    return 'Filter pencarian tidak valid: $errors';
  }

  @override
  String get pages => 'Halaman';

  @override
  String get tags => 'Tag';

  @override
  String get language => 'Bahasa';

  @override
  String get uploadedOn => 'Diunggah pada';

  @override
  String get readNow => 'Baca Sekarang';

  @override
  String get confirmDownload => 'Konfirmasi Download';

  @override
  String get downloadConfirmation => 'Apakah Anda yakin ingin mendownload?';

  @override
  String get confirmButton => 'Konfirmasi';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Mengunduh';

  @override
  String get downloadCompleted => 'Unduhan Selesai';

  @override
  String get downloadFailed => 'Unduhan Gagal';

  @override
  String get initializing => 'Memulai...';

  @override
  String get noContentToBrowse => 'Tidak ada konten untuk dibuka di browser';

  @override
  String get addToFavorites => 'Tambah ke Favorit';

  @override
  String get removeFromFavorites => 'Hapus dari Favorit';

  @override
  String get content => 'Konten';

  @override
  String get view => 'Lihat';

  @override
  String get clearAll => 'Bersihkan Semua';

  @override
  String get exportList => 'Ekspor Daftar';

  @override
  String get unableToCheck => 'Tidak dapat memeriksa koneksi.';

  @override
  String get noContentAvailable => 'Tidak ada konten tersedia';

  @override
  String get noContentToDownload => 'Tidak ada konten untuk diunduh';

  @override
  String get noGalleriesFound => 'Tidak ada galeri ditemukan di halaman ini';

  @override
  String get noContentLoadedToBrowse =>
      'Tidak ada konten dimuat untuk dibuka di browser';

  @override
  String get showCachedContent => 'Tampilkan Konten Cache';

  @override
  String get openedInBrowser => 'Dibuka di browser';

  @override
  String get foundGalleries => 'Galeri Ditemukan';

  @override
  String get checkingDownloadStatus => 'Memeriksa Status Unduhan...';

  @override
  String get allGalleriesDownloaded => 'Semua Galeri Telah Diunduh';

  @override
  String downloadStarted(String title) {
    return 'Unduhan dimulai: $title';
  }

  @override
  String get downloadNewGalleries => 'Unduh Galeri Baru';

  @override
  String get downloadProgress => 'Progres Unduhan';

  @override
  String get downloadComplete => 'Unduhan Selesai';

  @override
  String get downloadError => 'Error Unduhan';

  @override
  String get initializingDownloads => 'Memulai unduhan...';

  @override
  String get loadingDownloads => 'Memuat unduhan...';

  @override
  String get pauseAll => 'Pause Semua';

  @override
  String get resumeAll => 'Resume Semua';

  @override
  String get cancelAll => 'Batal Semua';

  @override
  String get clearCompleted => 'Bersihkan Selesai';

  @override
  String get cleanupStorage => 'Bersihkan Storage';

  @override
  String get all => 'Semua';

  @override
  String get active => 'Aktif';

  @override
  String get completed => 'Selesai';

  @override
  String get noDownloadsYet => 'Belum ada unduhan';

  @override
  String get noActiveDownloads => 'Tidak ada unduhan aktif';

  @override
  String get noQueuedDownloads => 'Tidak ada unduhan antrian';

  @override
  String get noCompletedDownloads => 'Tidak ada unduhan selesai';

  @override
  String get noFailedDownloads => 'Tidak ada unduhan gagal';

  @override
  String get pdfConversionStarted => 'Konversi PDF dimulai';

  @override
  String get cancelAllDownloads => 'Batalkan Semua Unduhan';

  @override
  String get cancelAllConfirmation =>
      'Yakin ingin membatalkan semua unduhan aktif? Tindakan ini tidak bisa dibatalkan.';

  @override
  String get cancelDownload => 'Batalkan Unduhan';

  @override
  String get cancelDownloadConfirmation =>
      'Yakin ingin membatalkan unduhan ini? Progress akan hilang.';

  @override
  String get removeDownload => 'Hapus Unduhan';

  @override
  String get removeDownloadConfirmation =>
      'Yakin ingin menghapus unduhan ini dari daftar? File yang telah diunduh akan dihapus.';

  @override
  String get cleanupConfirmation =>
      'Ini akan menghapus file yatim dan membersihkan unduhan yang gagal. Lanjutkan?';

  @override
  String get downloadDetails => 'Detail Unduhan';

  @override
  String get status => 'Status';

  @override
  String get progress => 'Progress';

  @override
  String get progressPercent => 'Progress %';

  @override
  String get speed => 'Kecepatan';

  @override
  String get size => 'Ukuran';

  @override
  String get started => 'Dimulai';

  @override
  String get ended => 'Selesai';

  @override
  String get duration => 'Durasi';

  @override
  String get eta => 'ETA';

  @override
  String get queued => 'Antri';

  @override
  String get downloaded => 'Terunduh';

  @override
  String get resume => 'Lanjutkan';

  @override
  String get failed => 'Gagal';

  @override
  String get downloadListExported => 'Daftar unduhan diekspor';

  @override
  String get downloadAll => 'Unduh Semua';

  @override
  String get downloadRange => 'Unduh Rentang';

  @override
  String get selectDownloadRange => 'Pilih Rentang Unduhan';

  @override
  String get totalPages => 'Total Halaman';

  @override
  String get useSliderToSelectRange => 'Gunakan slider untuk memilih rentang:';

  @override
  String get orEnterManually => 'Atau masukkan secara manual:';

  @override
  String get startPage => 'Halaman Awal';

  @override
  String get endPage => 'Halaman Akhir';

  @override
  String get quickSelections => 'Pilihan cepat:';

  @override
  String get allPages => 'Semua Halaman';

  @override
  String get firstHalf => 'Setengah Pertama';

  @override
  String get secondHalf => 'Setengah Kedua';

  @override
  String get first10 => '10 Pertama';

  @override
  String get last10 => '10 Terakhir';

  @override
  String countAlreadyDownloaded(int count) {
    return 'Dilewati $count yang sudah diunduh';
  }

  @override
  String newGalleriesToDownload(int count) {
    return '• $count galeri baru untuk didownload';
  }

  @override
  String alreadyDownloaded(int count) {
    return '• $count sudah didownload (akan dilewati)';
  }

  @override
  String downloadNew(int count) {
    return 'Download $count Baru';
  }

  @override
  String queuedDownloads(int count) {
    return 'Mengantri $count download baru';
  }

  @override
  String downloadInfo(int count) {
    return 'Download $count galeri baru?\\n\\nIni mungkin memerlukan waktu dan ruang penyimpanan yang signifikan.';
  }

  @override
  String get failedToDownload => 'Gagal mendownload galeri';

  @override
  String selectedPagesTo(int start, int end) {
    return 'Dipilih: Halaman $start hingga $end';
  }

  @override
  String pagesPercentage(int count, String percentage) {
    return '$count halaman ($percentage%)';
  }

  @override
  String rangeDownloadStarted(String title, String pageText) {
    return 'Unduhan rentang dimulai: $title ($pageText)';
  }

  @override
  String opening(String title) {
    return 'Membuka: $title';
  }

  @override
  String get lastUpdatedLabel => 'Diperbarui:';

  @override
  String get rangeLabel => 'Rentang:';

  @override
  String get ofWord => 'dari';

  @override
  String waitAndTry(int minutes) {
    return 'Tunggu $minutes menit dan coba lagi';
  }

  @override
  String get serviceUnderMaintenance =>
      'Layanan mungkin sedang dalam pemeliharaan';

  @override
  String get waitForBypass => 'Tunggu bypass otomatis selesai';

  @override
  String get tryUsingVpn => 'Coba gunakan VPN jika tersedia';

  @override
  String get checkBackLater => 'Periksa kembali beberapa menit lagi';

  @override
  String get tryRefreshingContent => 'Coba muat ulang konten';

  @override
  String get checkForAppUpdate => 'Periksa apakah aplikasi perlu diperbarui';

  @override
  String get reportIfPersists => 'Laporkan masalah jika terus berlanjut';

  @override
  String get maintenanceTakesHours =>
      'Pemeliharaan biasanya memakan waktu beberapa jam';

  @override
  String get checkSocialMedia => 'Periksa media sosial untuk pembaruan';

  @override
  String get tryAgainLater => 'Coba lagi nanti';

  @override
  String get serverUnavailable =>
      'Server saat ini tidak tersedia. Silakan coba lagi nanti.';

  @override
  String get useBroaderSearchTerms =>
      'Gunakan istilah pencarian yang lebih luas';

  @override
  String get loadingFavorites => 'Memuat favorit...';

  @override
  String get errorLoadingFavorites => 'Error Memuat Favorit';

  @override
  String get removeFavorite => 'Hapus Favorit';

  @override
  String get removeFavoriteConfirmation =>
      'Yakin ingin menghapus konten ini dari favorit?';

  @override
  String get removeAction => 'Hapus';

  @override
  String get deleteFavorites => 'Hapus Favorit';

  @override
  String deleteFavoritesConfirmation(int count, String s) {
    return 'Yakin ingin menghapus $count favorit$s?';
  }

  @override
  String get exportFavorites => 'Ekspor Favorit';

  @override
  String get exportingFavorites => 'Mengekspor favorit...';

  @override
  String get exportComplete => 'Ekspor Selesai';

  @override
  String exportedFavoritesCount(int count) {
    return 'Berhasil mengekspor $count favorit.';
  }

  @override
  String exportFailed(String error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get selectFavorites => 'Pilih favorit';

  @override
  String get exportAction => 'Ekspor';

  @override
  String get refreshAction => 'Segarkan';

  @override
  String get deleteSelected => 'Hapus yang dipilih';

  @override
  String get searchFavorites => 'Cari favorit...';

  @override
  String get selectAll => 'Pilih Semua';

  @override
  String get clearSelection => 'Bersihkan';

  @override
  String get removingFromFavorites => 'Menghapus dari favorit...';

  @override
  String get removedFromFavorites => 'Dihapus dari favorit';

  @override
  String failedToRemoveFavorite(String error) {
    return 'Gagal menghapus favorit: $error';
  }

  @override
  String removedFavoritesCount(int count) {
    return 'Menghapus $count favorit';
  }

  @override
  String failedToRemoveFavorites(String error) {
    return 'Gagal menghapus favorit: $error';
  }

  @override
  String get appearance => 'Tampilan';

  @override
  String get theme => 'Tema';

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
  String get resetToDefaults => 'Reset ke Default';

  @override
  String get generalSettings => 'Pengaturan Umum';

  @override
  String get displaySettings => 'Tampilan';

  @override
  String get darkMode => 'Mode Gelap';

  @override
  String get lightMode => 'Mode Terang';

  @override
  String get systemMode => 'Mengikuti Sistem';

  @override
  String get appLanguage => 'Bahasa Aplikasi';

  @override
  String get allowAnalytics => 'Izinkan Analytics';

  @override
  String get privacyAnalytics => 'Privasi Analytics';

  @override
  String get resetSettings => 'Reset Pengaturan';

  @override
  String get resetReaderSettings => 'Reset Pengaturan Reader';

  @override
  String get resetReaderSettingsConfirmation =>
      'Ini akan mengatur ulang semua pengaturan pembaca ke nilai default:\n\n';

  @override
  String get readingModeLabel => 'Mode Membaca: Halaman Horizontal';

  @override
  String get keepScreenOnLabel => 'Jaga Layar Hidup: Mati';

  @override
  String get showUILabel => 'Tampilkan UI: Hidup';

  @override
  String get areYouSure => 'Apakah Anda yakin ingin melanjutkan?';

  @override
  String get readerSettingsResetSuccess =>
      'Pengaturan pembaca telah direset ke default.';

  @override
  String failedToResetSettings(Object error) {
    return 'Gagal mengatur ulang pengaturan: $error';
  }

  @override
  String get readingHistory => 'Riwayat Baca';

  @override
  String get clearAllHistory => 'Bersihkan Semua Riwayat';

  @override
  String get manualCleanup => 'Pembersihan Manual';

  @override
  String get cleanupSettings => 'Pengaturan Pembersihan';

  @override
  String get removeFromHistory => 'Hapus dari Riwayat';

  @override
  String get removeFromHistoryQuestion => 'Hapus item ini dari riwayat baca?';

  @override
  String get cleanup => 'Bersihkan';

  @override
  String get failedToLoadCleanupStatus => 'Gagal memuat status pembersihan';

  @override
  String get manualCleanupConfirmation =>
      'Ini akan melakukan pembersihan berdasarkan pengaturan Anda saat ini. Lanjutkan?';

  @override
  String get noReadingHistory => 'Tidak Ada Riwayat Baca';

  @override
  String get errorLoadingHistory => 'Error Memuat Riwayat';

  @override
  String get nextPage => 'Halaman Berikutnya';

  @override
  String get previousPage => 'Halaman Sebelumnya';

  @override
  String get pageOf => 'dari';

  @override
  String get fullscreen => 'Layar Penuh';

  @override
  String get exitFullscreen => 'Keluar Layar Penuh';

  @override
  String get checkingConnection => 'Memeriksa koneksi...';

  @override
  String get backOnline => 'Kembali online! Semua fitur tersedia.';

  @override
  String get stillNoInternet => 'Masih tidak ada koneksi internet.';

  @override
  String get unableToCheckConnection => 'Tidak dapat memeriksa koneksi.';

  @override
  String get connectionError => 'Kesalahan koneksi';

  @override
  String get low => 'Rendah';

  @override
  String get medium => 'Sedang';

  @override
  String get high => 'Tinggi';

  @override
  String get original => 'Asli';

  @override
  String get lowFaster => 'Rendah (Lebih Cepat)';

  @override
  String get highBetterQuality => 'Tinggi (Kualitas Lebih Baik)';

  @override
  String get originalLargest => 'Asli (Terbesar)';

  @override
  String get lowQuality => 'Rendah (Lebih Cepat)';

  @override
  String get mediumQuality => 'Sedang';

  @override
  String get highQuality => 'Tinggi (Kualitas Lebih Baik)';

  @override
  String get originalQuality => 'Asli (Terbesar)';

  @override
  String get dark => 'Gelap';

  @override
  String get light => 'Terang';

  @override
  String get amoled => 'AMOLED';

  @override
  String get english => 'Bahasa Inggris';

  @override
  String get japanese => 'Bahasa Jepang';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get sortBy => 'Urutkan berdasarkan';

  @override
  String get filterBy => 'Filter berdasarkan';

  @override
  String get recent => 'Terbaru';

  @override
  String get popular => 'Populer';

  @override
  String get oldest => 'Terlama';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batalkan';

  @override
  String get delete => 'Hapus';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get loading => 'Memuat...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get tryAgain => 'Coba Lagi';

  @override
  String get save => 'Simpan';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Tutup';

  @override
  String get clear => 'Bersihkan';

  @override
  String get remove => 'Hapus';

  @override
  String get share => 'Bagikan';

  @override
  String get goBack => 'Kembali';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get next => 'Selanjutnya';

  @override
  String get goToDownloads => 'Ke Unduhan';

  @override
  String get retryAction => 'Coba Lagi';

  @override
  String hours(int count) {
    return '$count jam';
  }

  @override
  String days(int count) {
    return '$count hari';
  }

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String daysAgo(int count, String s) {
    return '${days}h yang lalu';
  }

  @override
  String hoursAgo(int count, String s) {
    return '${hours}j yang lalu';
  }

  @override
  String minutesAgo(int count, String s) {
    return '${count}m yang lalu';
  }

  @override
  String get noData => 'Tidak Ada Data';

  @override
  String get unknownTitle => 'Judul Tidak Diketahui';

  @override
  String get offlineContentError => 'Error Konten Offline';

  @override
  String get other => 'Lainnya';

  @override
  String get confirmResetSettings =>
      'Yakin ingin mengembalikan semua pengaturan ke default?';

  @override
  String get reset => 'Reset';

  @override
  String get manageAutoCleanupDescription =>
      'Kelola pembersihan otomatis riwayat baca untuk menghemat ruang penyimpanan.';

  @override
  String get nextCleanup => 'Pembersihan berikutnya';

  @override
  String get historyStatistics => 'Statistik Riwayat';

  @override
  String get totalItems => 'Total item';

  @override
  String get lastCleanup => 'Pembersihan terakhir';

  @override
  String get lastAppAccess => 'Akses aplikasi terakhir';

  @override
  String get oneDay => '1 hari';

  @override
  String get twoDays => '2 hari';

  @override
  String get oneWeek => '1 minggu';

  @override
  String get privacyInfoText =>
      '• Data disimpan di device Anda\n• Tidak dikirim ke server eksternal\n• Hanya untuk meningkatkan performa app\n• Dapat dimatikan kapan saja';

  @override
  String get unlimited => 'Tanpa batas';

  @override
  String daysValue(int days) {
    return '$days hari';
  }

  @override
  String get analyticsSubtitle =>
      'Membantu pengembangan app dengan data lokal (tidak dibagikan)';

  @override
  String get loadingError => 'Kesalahan Memuat';

  @override
  String get jumpToPage => 'Loncat ke Halaman';

  @override
  String pageInputLabel(int maxPages) {
    return 'Halaman (1-$maxPages)';
  }

  @override
  String pageOfPages(int current, int total) {
    return 'Halaman $current dari $total';
  }

  @override
  String get jump => 'Loncat';

  @override
  String get readerSettings => 'Pengaturan Pembaca';

  @override
  String get readingMode => 'Mode Baca';

  @override
  String get horizontalPages => 'Halaman Horizontal';

  @override
  String get verticalPages => 'Halaman Vertikal';

  @override
  String get continuousScroll => 'Gulir Terus Menerus';

  @override
  String get keepScreenOn => 'Jaga Layar Hidup';

  @override
  String get keepScreenOnDescription => 'Mencegah layar mati saat membaca';

  @override
  String get platformNotSupported => 'Platform Tidak Didukung';

  @override
  String get platformNotSupportedBody =>
      'NhasixApp dirancang khusus untuk perangkat Android.';

  @override
  String get platformNotSupportedInstall =>
      'Silakan pasang dan jalankan aplikasi ini di perangkat Android.';

  @override
  String get storagePermissionRequired => 'Izin Penyimpanan Diperlukan';

  @override
  String get storagePermissionExplanation =>
      'Aplikasi ini membutuhkan izin penyimpanan untuk mengunduh file ke perangkat Anda. File akan disimpan di folder Downloads/nhasix.';

  @override
  String get grantPermission => 'Berikan Izin';

  @override
  String get permissionRequired => 'Izin Diperlukan';

  @override
  String get storagePermissionSettingsPrompt =>
      'Izin penyimpanan diperlukan untuk mengunduh file. Silakan berikan izin penyimpanan di pengaturan aplikasi.';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String get readingHistoryMessage =>
      'Riwayat bacaan Anda akan muncul di sini saat Anda membaca konten.';

  @override
  String get startReading => 'Mulai Membaca';

  @override
  String get searchSomethingInteresting => 'Cari sesuatu yang menarik';

  @override
  String get checkOutFeaturedItems => 'Lihat item unggulan';

  @override
  String get appSubtitleDescription => 'Klien tidak resmi Nhentai';

  @override
  String get downloadedGalleries => 'Galeri yang diunduh';

  @override
  String get favoriteGalleries => 'Galeri favorit';

  @override
  String get viewHistory => 'Lihat riwayat';

  @override
  String get openInBrowser => 'Buka di browser';

  @override
  String get downloadAllGalleries => 'Unduh semua galeri di halaman ini';

  @override
  String enterPageNumber(int totalPages) {
    return 'Masukkan nomor halaman (1 - $totalPages)';
  }

  @override
  String get pageNumber => 'Nomor halaman';

  @override
  String get go => 'Pergi';

  @override
  String validPageNumberError(int totalPages) {
    return 'Silakan masukkan nomor halaman yang valid antara 1 dan $totalPages';
  }

  @override
  String get tapToJump => 'Ketuk untuk loncat';

  @override
  String get goToPage => 'Pergi ke Halaman';

  @override
  String get previousPageTooltip => 'Halaman sebelumnya';

  @override
  String get nextPageTooltip => 'Halaman berikutnya';

  @override
  String get tapToJumpToPage => 'Ketuk untuk lompat ke halaman';

  @override
  String get loadingContentTitle => 'Memuat Konten';

  @override
  String get loadingContentDetails => 'Memuat Detail Konten';

  @override
  String get fetchingMetadata => 'Mengambil metadata dan gambar...';

  @override
  String get thisMayTakeMoments => 'Ini mungkin memerlukan beberapa saat';

  @override
  String get youAreOffline =>
      'Anda sedang offline. Beberapa fitur mungkin terbatas.';

  @override
  String get goOnline => 'Buka Online';

  @override
  String get youAreOfflineTapToGoOnline =>
      'Anda sedang offline. Ketuk untuk online.';

  @override
  String get contentInformation => 'Informasi Konten';

  @override
  String get copyLink => 'Salin Link';

  @override
  String get moreOptions => 'Opsi Lainnya';

  @override
  String get moreLikeThis => 'Lebih Seperti Ini';

  @override
  String get statistics => 'Statistik';

  @override
  String get shareContent => 'Bagikan Konten';

  @override
  String get sharePanelOpened => 'Panel berbagi berhasil dibuka!';

  @override
  String get shareFailed =>
      'Berbagi gagal, tetapi link telah disalin ke clipboard';

  @override
  String downloadStartedFor(String title) {
    return 'Unduhan dimulai untuk \"$title\"';
  }

  @override
  String get viewDownloadsAction => 'Lihat';

  @override
  String get failedToStartDownload =>
      'Gagal memulai unduhan. Silakan coba lagi.';

  @override
  String get linkCopiedToClipboard => 'Link telah disalin ke clipboard';

  @override
  String get failedToCopyLink => 'Gagal menyalin link. Silakan coba lagi.';

  @override
  String get copiedLink => 'Link Disalin';

  @override
  String get linkCopiedToClipboardDescription =>
      'Link berikut telah disalin ke clipboard Anda:';

  @override
  String get closeDialog => 'Tutup';

  @override
  String get goOnlineDialogTitle => 'Buka Online';

  @override
  String get goOnlineDialogContent =>
      'Anda saat ini dalam mode offline. Apakah Anda ingin online untuk mengakses konten terbaru?';

  @override
  String get goingOnline => 'Membuka online...';

  @override
  String get idLabel => 'ID';

  @override
  String get pagesLabel => 'Halaman';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get artistLabel => 'Artis';

  @override
  String get charactersLabel => 'Karakter';

  @override
  String get parodiesLabel => 'Parodi';

  @override
  String get groupsLabel => 'Grup (dipisahkan koma)';

  @override
  String get uploadedLabel => 'Diunggah';

  @override
  String get favoritesLabel => 'Favorit';

  @override
  String get tagsLabel => 'Tag';

  @override
  String get artistsLabel => 'Artis (dipisahkan koma)';

  @override
  String get relatedLabel => 'Terkait';

  @override
  String yearAgo(int count, String plural) {
    return '$count tahun$plural lalu';
  }

  @override
  String monthAgo(int count, String plural) {
    return '$count bulan$plural lalu';
  }

  @override
  String dayAgo(int count, String plural) {
    return '$count hari$plural lalu';
  }

  @override
  String hourAgo(int count, String plural) {
    return '$count jam$plural lalu';
  }

  @override
  String get selectFavoritesTooltip => 'Pilih favorit';

  @override
  String get deleteSelectedTooltip => 'Hapus yang dipilih';

  @override
  String get selectAllAction => 'Pilih Semua';

  @override
  String get clearAction => 'Bersihkan';

  @override
  String selectedCountFormat(int selected, int total) {
    return '$selected / $total';
  }

  @override
  String get loadingFavoritesMessage => 'Memuat favorit...';

  @override
  String get deletingFavoritesMessage => 'Menghapus favorit...';

  @override
  String get removingFromFavoritesMessage => 'Menghapus dari favorit...';

  @override
  String get favoritesDeletedMessage => 'Favorit berhasil dihapus';

  @override
  String get failedToDeleteFavoritesMessage => 'Gagal menghapus favorit';

  @override
  String get confirmDeleteFavoritesTitle => 'Hapus Favorit';

  @override
  String confirmDeleteFavoritesMessage(int count, String plural) {
    return 'Apakah Anda yakin ingin menghapus $count favorit?';
  }

  @override
  String get exportFavoritesTitle => 'Ekspor Favorit';

  @override
  String get exportingFavoritesMessage => 'Mengekspor favorit...';

  @override
  String get favoritesExportedMessage => 'Favorit berhasil diekspor';

  @override
  String get failedToExportFavoritesMessage => 'Gagal mengekspor favorit';

  @override
  String get searchFavoritesHint => 'Cari favorit...';

  @override
  String get searchOfflineContentHint => 'Cari konten offline...';

  @override
  String failedToLoadPage(int pageNumber) {
    return 'Gagal memuat halaman $pageNumber';
  }

  @override
  String get failedToLoad => 'Gagal memuat';

  @override
  String get offlineContentTitle => 'Konten Offline';

  @override
  String get favorited => 'Difavoritkan';

  @override
  String get favorite => 'Favorit';

  @override
  String get errorLoadingFavoritesTitle => 'Kesalahan Memuat Favorit';

  @override
  String get filterDataTitle => 'Filter Data';

  @override
  String get clearAllAction => 'Bersihkan Semua';

  @override
  String searchFilterHint(String filterType) {
    return 'Cari $filterType...';
  }

  @override
  String selectedCountFormat2(int count) {
    return 'Dipilih ($count)';
  }

  @override
  String get errorLoadingFilterDataTitle => 'Kesalahan memuat data filter';

  @override
  String noFilterTypeAvailable(String filterType) {
    return 'Tidak ada $filterType tersedia';
  }

  @override
  String noResultsFoundForQuery(String query) {
    return 'Tidak ada hasil untuk \"$query\"';
  }

  @override
  String get contentNotFoundTitle => 'Konten Tidak Ditemukan';

  @override
  String contentNotFoundMessage(String contentId) {
    return 'Konten dengan ID \"$contentId\" tidak ditemukan.';
  }

  @override
  String get filterCategoriesTitle => 'Kategori Filter';

  @override
  String get searchTitle => 'Cari';

  @override
  String get advancedSearchTitle => 'Pencarian Lanjutan';

  @override
  String get enterSearchQueryHint =>
      'Masukkan kata kunci pencarian (contoh: \"big breasts english\")';

  @override
  String get popularSearchesTitle => 'Pencarian Populer';

  @override
  String get recentSearchesTitle => 'Pencarian Terbaru';

  @override
  String get pressSearchButtonMessage =>
      'Tekan tombol Cari untuk menemukan konten dengan filter saat ini';

  @override
  String get searchingMessage => 'Mencari...';

  @override
  String resultsCountFormat(String count) {
    return '$count hasil';
  }

  @override
  String get viewInMainAction => 'Lihat di Utama';

  @override
  String get searchErrorTitle => 'Kesalahan Pencarian';

  @override
  String get noResultsFoundTitle => 'Tidak ada hasil';

  @override
  String pageText(int pageNumber) {
    return 'halaman $pageNumber';
  }

  @override
  String pagesText(int startPage, int endPage) {
    return 'halaman $startPage-$endPage';
  }

  @override
  String get offlineStatus => 'OFFLINE';

  @override
  String get onlineStatus => 'ONLINE';

  @override
  String get errorOccurred => 'Terjadi kesalahan';

  @override
  String get tapToRetry => 'Ketuk untuk mencoba lagi';

  @override
  String get helpTitle => 'Bantuan';

  @override
  String get helpNoResults => 'Tidak ada hasil ditemukan untuk pencarian Anda';

  @override
  String get helpTryDifferent =>
      'Coba gunakan kata kunci yang berbeda atau periksa ejaan';

  @override
  String get helpUseFilters => 'Gunakan filter untuk mempersempit pencarian';

  @override
  String get helpCheckConnection => 'Periksa koneksi internet Anda';

  @override
  String get sendReportText => 'Kirim Laporan';

  @override
  String get technicalDetailsTitle => 'Detail Teknis';

  @override
  String get reportSentText => 'Laporan terkirim!';

  @override
  String get suggestionCheckConnection => 'Periksa koneksi internet Anda';

  @override
  String get suggestionTryWifiMobile =>
      'Coba beralih antara WiFi dan data seluler';

  @override
  String get suggestionRestartRouter => 'Restart router jika menggunakan WiFi';

  @override
  String get suggestionCheckWebsite => 'Periksa apakah situs web sedang down';

  @override
  String noContentFoundWithQuery(String query) {
    return 'Tidak ada konten ditemukan untuk \"$query\". Coba sesuaikan istilah pencarian atau filter.';
  }

  @override
  String get noContentFound =>
      'Tidak ada konten ditemukan. Coba sesuaikan istilah pencarian atau filter.';

  @override
  String get suggestionTryDifferentKeywords => 'Coba kata kunci yang berbeda';

  @override
  String get suggestionRemoveFilters => 'Hapus beberapa filter';

  @override
  String get suggestionCheckSpelling => 'Periksa ejaan';

  @override
  String get suggestionUseBroaderTerms =>
      'Gunakan istilah pencarian yang lebih luas';

  @override
  String get underMaintenanceTitle => 'Sedang Maintenance';

  @override
  String get underMaintenanceMessage =>
      'Layanan sedang dalam pemeliharaan. Silakan coba lagi nanti.';

  @override
  String get suggestionMaintenanceHours =>
      'Maintenance biasanya memakan waktu beberapa jam';

  @override
  String get suggestionCheckSocial => 'Periksa media sosial untuk update';

  @override
  String get suggestionTryLater => 'Coba lagi nanti';

  @override
  String get includeFilter => 'Sertakan';

  @override
  String get excludeFilter => 'Kecualikan';

  @override
  String get overallProgress => 'Progress Keseluruhan';

  @override
  String get total => 'Total';

  @override
  String get done => 'Selesai';

  @override
  String downloadsFailed(int count, String plural) {
    return '$count unduhan gagal';
  }

  @override
  String get processing => 'Memproses...';

  @override
  String get readingCompleted => 'Selesai';

  @override
  String get readAgain => 'Baca Lagi';

  @override
  String get continueReading => 'Lanjutkan Membaca';

  @override
  String get lessThanOneMinute => 'Kurang dari 1 menit';

  @override
  String get readingTime => 'waktu baca';

  @override
  String get downloadActions => 'Tindakan Download';

  @override
  String get pause => 'Jeda';

  @override
  String get convertToPdf => 'Ubah ke PDF';

  @override
  String get details => 'Detail';

  @override
  String get downloadActionPause => 'Jeda';

  @override
  String get downloadActionResume => 'Lanjutkan';

  @override
  String get downloadActionCancel => 'Batalkan';

  @override
  String get downloadActionRetry => 'Coba Lagi';

  @override
  String get downloadActionConvertToPdf => 'Ubah ke PDF';

  @override
  String get downloadActionDetails => 'Detail';

  @override
  String get downloadActionRemove => 'Hapus';

  @override
  String downloadPagesRangeFormat(
      int downloaded, int total, int start, int end, int totalPages) {
    return '$downloaded/$total (Halaman $start-$end dari $totalPages)';
  }

  @override
  String downloadPagesFormat(int downloaded, int total) {
    return '$downloaded/$total';
  }

  @override
  String downloadContentTitle(String contentId) {
    return 'Konten $contentId';
  }

  @override
  String downloadEtaLabel(String duration) {
    return 'Perkiraan: $duration';
  }

  @override
  String get downloadSettingsTitle => 'Pengaturan Download';

  @override
  String get performanceSection => 'Performa';

  @override
  String get maxConcurrentDownloads => 'Maks Download Bersamaan';

  @override
  String get concurrentDownloadsWarning =>
      'Nilai tinggi mungkin menggunakan lebih banyak bandwidth dan resource perangkat';

  @override
  String get imageQualityLabel => 'Kualitas Gambar';

  @override
  String get autoRetrySection => 'Ulangi Otomatis';

  @override
  String get autoRetryFailedDownloads => 'Ulangi Download Gagal Otomatis';

  @override
  String get autoRetryDescription => 'Otomatis ulangi download yang gagal';

  @override
  String get maxRetryAttempts => 'Maks Percobaan Ulang';

  @override
  String get networkSection => 'Jaringan';

  @override
  String get wifiOnlyLabel => 'Hanya WiFi';

  @override
  String get wifiOnlyDescription => 'Hanya download saat terhubung ke WiFi';

  @override
  String get downloadTimeoutLabel => 'Timeout Download';

  @override
  String get notificationsSection => 'Notifikasi';

  @override
  String get enableNotificationsLabel => 'Aktifkan Notifikasi';

  @override
  String get enableNotificationsDescription =>
      'Tampilkan notifikasi untuk progress download';

  @override
  String get minutesUnit => 'mnt';

  @override
  String get searchContentHint => 'Cari konten...';

  @override
  String get hideFiltersTooltip => 'Sembunyikan filter';

  @override
  String get showMoreFiltersTooltip => 'Tampilkan lebih banyak filter';

  @override
  String get advancedFiltersTitle => 'Filter Lanjutan';

  @override
  String get sortByLabel => 'Urutkan berdasarkan';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get includeTagsLabel => 'Sertakan tag (dipisahkan koma)';

  @override
  String get includeTagsHint => 'contoh: romansa, komedi, sekolah';

  @override
  String get excludeTagsLabel => 'Kecualikan tag (dipisahkan koma)';

  @override
  String get excludeTagsHint => 'contoh: horor, kekerasan';

  @override
  String get artistsHint => 'contoh: artis1, artis2';

  @override
  String get pageCountRangeTitle => 'Rentang Jumlah Halaman';

  @override
  String get minPagesLabel => 'Halaman minimal';

  @override
  String get maxPagesLabel => 'Halaman maksimal';

  @override
  String get rangeToSeparator => 'hingga';

  @override
  String get popularTagsTitle => 'Tag Populer';

  @override
  String get filtersActiveLabel => 'aktif';

  @override
  String get clearAllFilters => 'Hapus Semua';

  @override
  String get initializingApp => 'Menginisialisasi Aplikasi...';

  @override
  String get settingUpComponents =>
      'Menyiapkan komponen dan memeriksa koneksi...';

  @override
  String get bypassingProtection => 'Melewati proteksi dan membuat koneksi...';

  @override
  String get connectionFailed => 'Koneksi Gagal';

  @override
  String get readyToGo => 'Siap Digunakan!';

  @override
  String get launchingApp => 'Meluncurkan aplikasi utama...';

  @override
  String get imageNotAvailable => 'Gambar tidak tersedia';

  @override
  String loadingPage(int pageNumber) {
    return 'Memuat halaman $pageNumber...';
  }

  @override
  String selectedItemsCount(int count) {
    return '$count terpilih';
  }

  @override
  String get noImage => 'Tidak ada gambar';

  @override
  String get youAreOfflineShort => 'Anda sedang offline';

  @override
  String get someFeaturesLimited =>
      'Beberapa fitur terbatas. Sambungkan ke internet untuk akses penuh.';

  @override
  String get wifi => 'WIFI';

  @override
  String get ethernet => 'ETHERNET';

  @override
  String get mobile => 'MOBILE';

  @override
  String get online => 'ONLINE';

  @override
  String get offlineMode => 'Mode Offline';

  @override
  String get applySearch => 'Terapkan Pencarian';

  @override
  String get addFiltersToSearch =>
      'Tambahkan filter di atas untuk mengaktifkan pencarian';

  @override
  String get startSearching => 'Mulai mencari';

  @override
  String get enterKeywordsAdvancedHint =>
      'Masukkan kata kunci, tag, atau gunakan filter lanjutan untuk menemukan konten';

  @override
  String get filtersReady => 'Filter Siap';

  @override
  String get clearAllFiltersTooltip => 'Bersihkan semua filter';

  @override
  String get offlineSomeFeaturesUnavailable =>
      'Anda sedang offline. Beberapa fitur mungkin tidak tersedia.';

  @override
  String get usingDownloadedContentOnly =>
      'Menggunakan konten yang diunduh saja';

  @override
  String get onlineModeWithNetworkAccess => 'Mode online dengan akses jaringan';

  @override
  String get tagsScreenPlaceholder => 'Layar Tag - Akan diimplementasikan';

  @override
  String get artistsScreenPlaceholder => 'Layar Artis - Akan diimplementasikan';

  @override
  String get statusScreenPlaceholder => 'Layar Status - Akan diimplementasikan';

  @override
  String get pageNotFound => 'Halaman Tidak Ditemukan';

  @override
  String pageNotFoundWithUri(String uri) {
    return 'Halaman tidak ditemukan: $uri';
  }

  @override
  String get goHome => 'Kembali ke Beranda';

  @override
  String get debugThemeInfo => 'DEBUG: Info Tema';

  @override
  String get lightTheme => 'Terang';

  @override
  String get darkTheme => 'Gelap';

  @override
  String get amoledTheme => 'AMOLED';
}
