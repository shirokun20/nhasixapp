import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Home and Main Navigation
  String get home => locale.languageCode == 'id' ? 'Beranda' : 'Home';
  String get search => locale.languageCode == 'id' ? 'Cari' : 'Search';
  String get favorites => locale.languageCode == 'id' ? 'Favorit' : 'Favorites';
  String get settings => locale.languageCode == 'id' ? 'Pengaturan' : 'Settings';
  String get offline => locale.languageCode == 'id' ? 'Offline' : 'Offline';
  String get history => locale.languageCode == 'id' ? 'Riwayat' : 'History';

  // Search Screen
  String get searchHint => locale.languageCode == 'id' ? 'Cari konten...' : 'Search content...';
  String get searchPlaceholder => locale.languageCode == 'id' ? 'Masukkan kata kunci pencarian' : 'Enter search keywords';
  String get noResults => locale.languageCode == 'id' ? 'Tidak ada hasil ditemukan' : 'No results found';
  String get searchSuggestions => locale.languageCode == 'id' ? 'Saran Pencarian' : 'Search Suggestions';
  String get suggestions => locale.languageCode == 'id' ? 'Saran:' : 'Suggestions:';
  String get tapToLoadContent => locale.languageCode == 'id' ? 'Ketuk untuk memuat konten' : 'Tap to load content';
  String get searchResults => locale.languageCode == 'id' ? 'Hasil Pencarian' : 'Search Results';
  String get failedToOpenBrowser => locale.languageCode == 'id' ? 'Gagal membuka browser' : 'Failed to open browser';
  String get viewDownloads => locale.languageCode == 'id' ? 'Lihat Unduhan' : 'View Downloads';
  String countAlreadyDownloaded(int count) => locale.languageCode == 'id' ? 'Dilewati $count yang sudah diunduh' : 'Skipped $count already downloaded';

  // Content and Gallery
  String get pages => locale.languageCode == 'id' ? 'Halaman' : 'Pages';
  String get tags => locale.languageCode == 'id' ? 'Tag' : 'Tags';
  String get language => locale.languageCode == 'id' ? 'Bahasa' : 'Language';
  String get uploadedOn => locale.languageCode == 'id' ? 'Diunggah pada' : 'Uploaded on';
  String get readNow => locale.languageCode == 'id' ? 'Baca Sekarang' : 'Read Now';
  String get confirmDownload => locale.languageCode == 'id' ? 'Konfirmasi Download' : 'Confirm Download';
  String get downloadConfirmation => locale.languageCode == 'id' ? 'Apakah Anda yakin ingin mendownload?' : 'Are you sure you want to download?';
  String get confirmButton => locale.languageCode == 'id' ? 'Konfirmasi' : 'Confirm';
  String get download => locale.languageCode == 'id' ? 'Download' : 'Download';
  String get initializing => locale.languageCode == 'id' ? 'Memulai...' : 'Initializing...';
  String get noContentToBrowse => locale.languageCode == 'id' ? 'Tidak ada konten untuk dibuka di browser' : 'No content loaded to open in browser';
  String newGalleriesToDownload(int count) => locale.languageCode == 'id' ? '• $count galeri baru untuk didownload' : '• $count new galleries to download';
  String alreadyDownloaded(int count) => locale.languageCode == 'id' ? '• $count sudah didownload (akan dilewati)' : '• $count already downloaded (will be skipped)';
  String downloadNew(int count) => locale.languageCode == 'id' ? 'Download $count Baru' : 'Download $count New';
  String queuedDownloads(int count) => locale.languageCode == 'id' ? 'Mengantri $count download baru' : 'Queued $count new downloads';
  String downloadInfo(int count) => locale.languageCode == 'id' ? 'Download $count galeri baru?\n\nIni mungkin memerlukan waktu dan ruang penyimpanan yang signifikan.' : 'Download $count new galleries?\n\nThis may take significant time and storage space.';
  String get failedToDownload => locale.languageCode == 'id' ? 'Gagal mendownload galeri' : 'Failed to download galleries';
  String get lowQuality => locale.languageCode == 'id' ? 'Rendah (Lebih Cepat)' : 'Low (Faster)';
  String get mediumQuality => locale.languageCode == 'id' ? 'Sedang' : 'Medium';
  String get highQuality => locale.languageCode == 'id' ? 'Tinggi (Kualitas Lebih Baik)' : 'High (Better Quality)';
  String get originalQuality => locale.languageCode == 'id' ? 'Asli (Terbesar)' : 'Original (Largest)';
  String get unableToCheck => locale.languageCode == 'id' ? 'Tidak dapat memeriksa koneksi.' : 'Unable to check connection.';
  String get view => locale.languageCode == 'id' ? 'Lihat' : 'View';
  String get clearAll => locale.languageCode == 'id' ? 'Bersihkan Semua' : 'Clear All';
  String get exportList => locale.languageCode == 'id' ? 'Ekspor Daftar' : 'Export List';

  String get addToFavorites => locale.languageCode == 'id' ? 'Tambah ke Favorit' : 'Add to Favorites';
  String get removeFromFavorites => locale.languageCode == 'id' ? 'Hapus dari Favorit' : 'Remove from Favorites';

  // Settings Screen
  String get generalSettings => locale.languageCode == 'id' ? 'Pengaturan Umum' : 'General Settings';
  String get displaySettings => locale.languageCode == 'id' ? 'Tampilan' : 'Display';
  String get gridColumns => locale.languageCode == 'id' ? 'Kolom Grid' : 'Grid Columns';
  String get imageQuality => locale.languageCode == 'id' ? 'Kualitas Gambar' : 'Image Quality';
  String get theme => locale.languageCode == 'id' ? 'Tema' : 'Theme';
  String get darkMode => locale.languageCode == 'id' ? 'Mode Gelap' : 'Dark Mode';
  String get lightMode => locale.languageCode == 'id' ? 'Mode Terang' : 'Light Mode';
  String get systemMode => locale.languageCode == 'id' ? 'Mengikuti Sistem' : 'Follow System';
  String get appLanguage => locale.languageCode == 'id' ? 'Bahasa Aplikasi' : 'App Language';
  String get english => locale.languageCode == 'id' ? 'Bahasa Inggris' : 'English';
  String get indonesian => locale.languageCode == 'id' ? 'Bahasa Indonesia' : 'Indonesian';
  String get allowAnalytics => locale.languageCode == 'id' ? 'Izinkan Analytics' : 'Allow Analytics';
  String get privacyAnalytics => locale.languageCode == 'id' ? 'Privasi Analytics' : 'Privacy Analytics';
  String get resetSettings => locale.languageCode == 'id' ? 'Reset Pengaturan' : 'Reset Settings';

  // Download and Offline
  String get downloadProgress => locale.languageCode == 'id' ? 'Progres Unduhan' : 'Download Progress';
  String get downloadComplete => locale.languageCode == 'id' ? 'Unduhan Selesai' : 'Download Complete';
  String get downloadFailed => locale.languageCode == 'id' ? 'Unduhan Gagal' : 'Download Failed';
  String get offlineContent => locale.languageCode == 'id' ? 'Konten Offline' : 'Offline Content';
  String get noOfflineContent => locale.languageCode == 'id' ? 'Belum ada konten offline' : 'No offline content yet';

  // Common Actions
  String get ok => locale.languageCode == 'id' ? 'OK' : 'OK';
  String get cancel => locale.languageCode == 'id' ? 'Batal' : 'Cancel';
  String get delete => locale.languageCode == 'id' ? 'Hapus' : 'Delete';
  String get confirm => locale.languageCode == 'id' ? 'Konfirmasi' : 'Confirm';
  String get loading => locale.languageCode == 'id' ? 'Memuat...' : 'Loading...';
  String get error => locale.languageCode == 'id' ? 'Error' : 'Error';
  String get retry => locale.languageCode == 'id' ? 'Coba Lagi' : 'Retry';
  String get tryAgain => locale.languageCode == 'id' ? 'Coba Lagi' : 'Try Again';
  String get save => locale.languageCode == 'id' ? 'Simpan' : 'Save';
  String get edit => locale.languageCode == 'id' ? 'Edit' : 'Edit';
  String get close => locale.languageCode == 'id' ? 'Tutup' : 'Close';
  String get clear => locale.languageCode == 'id' ? 'Bersihkan' : 'Clear';
  String get remove => locale.languageCode == 'id' ? 'Hapus' : 'Remove';
  String get share => locale.languageCode == 'id' ? 'Bagikan' : 'Share';
  String get goBack => locale.languageCode == 'id' ? 'Kembali' : 'Go Back';

  // Navigation
  String get previous => locale.languageCode == 'id' ? 'Sebelumnya' : 'Previous';
  String get next => locale.languageCode == 'id' ? 'Selanjutnya' : 'Next';
  String get goToDownloads => locale.languageCode == 'id' ? 'Ke Unduhan' : 'Go to Downloads';

  // Download Actions
  String get downloadAll => locale.languageCode == 'id' ? 'Unduh Semua' : 'Download All';
  String get downloadRange => locale.languageCode == 'id' ? 'Unduh Rentang' : 'Download Range';
  String get downloadNewGalleries => locale.languageCode == 'id' ? 'Unduh Galeri Baru' : 'Download New Galleries';
  String downloadStarted(String title) => locale.languageCode == 'id' ? 'Unduhan dimulai: $title' : 'Download started: $title';
  String rangeDownloadStarted(String title, String pageText) => locale.languageCode == 'id' ? 'Unduhan rentang dimulai: $title ($pageText)' : 'Range download started: $title ($pageText)';
  String opening(String title) => locale.languageCode == 'id' ? 'Membuka: $title' : 'Opening: $title';
  String get downloadListExported => locale.languageCode == 'id' ? 'Daftar unduhan diekspor' : 'Download list exported';
  String get queued => locale.languageCode == 'id' ? 'Antrian' : 'Queued';
  String get downloaded => locale.languageCode == 'id' ? 'Diunduh' : 'Downloaded';
  String get resume => locale.languageCode == 'id' ? 'Lanjutkan' : 'Resume';
  String get failed => locale.languageCode == 'id' ? 'Gagal' : 'Failed';
  String get selectDownloadRange => locale.languageCode == 'id' ? 'Pilih Rentang Unduhan' : 'Select Download Range';
  String get content => locale.languageCode == 'id' ? 'Konten' : 'Content';
  String get totalPages => locale.languageCode == 'id' ? 'Total Halaman' : 'Total Pages';
  String get useSliderToSelectRange => locale.languageCode == 'id' ? 'Gunakan slider untuk memilih rentang:' : 'Use slider to select range:';
  String get orEnterManually => locale.languageCode == 'id' ? 'Atau masukkan secara manual:' : 'Or enter manually:';
  String get startPage => locale.languageCode == 'id' ? 'Halaman Awal' : 'Start Page';
  String get endPage => locale.languageCode == 'id' ? 'Halaman Akhir' : 'End Page';
  String get quickSelections => locale.languageCode == 'id' ? 'Pilihan cepat:' : 'Quick selections:';
  String get allPages => locale.languageCode == 'id' ? 'Semua Halaman' : 'All Pages';
  String get firstHalf => locale.languageCode == 'id' ? 'Setengah Pertama' : 'First Half';
  String get secondHalf => locale.languageCode == 'id' ? 'Setengah Kedua' : 'Second Half';
  String get first10 => locale.languageCode == 'id' ? '10 Pertama' : 'First 10';
  String get last10 => locale.languageCode == 'id' ? '10 Terakhir' : 'Last 10';
  String selectedPagesTo(int start, int end) => locale.languageCode == 'id' ? 'Dipilih: Halaman $start hingga $end' : 'Selected: Pages $start to $end';
  String pagesPercentage(int count, String percentage) => locale.languageCode == 'id' ? '$count halaman ($percentage%)' : '$count pages ($percentage%)';
  String get manualCleanupConfirmation => locale.languageCode == 'id' ? 'Ini akan melakukan pembersihan berdasarkan pengaturan Anda saat ini. Lanjutkan?' : 'This will perform cleanup based on your current settings. Continue?';

  // Content Messages
  String get noContentAvailable => locale.languageCode == 'id' ? 'Tidak ada konten tersedia' : 'No content available';
  String get noContentToDownload => locale.languageCode == 'id' ? 'Tidak ada konten untuk diunduh' : 'No content available to download';
  String get noGalleriesFound => locale.languageCode == 'id' ? 'Tidak ada galeri ditemukan di halaman ini' : 'No galleries found on this page';
  String get noContentLoadedToBrowse => locale.languageCode == 'id' ? 'Tidak ada konten dimuat untuk dibuka di browser' : 'No content loaded to open in browser';
  String get showCachedContent => locale.languageCode == 'id' ? 'Tampilkan Konten Cache' : 'Show Cached Content';
  String get openedInBrowser => locale.languageCode == 'id' ? 'Dibuka di browser' : 'Opened in browser';

  // Search and Filters
  String get clearSearch => locale.languageCode == 'id' ? 'Bersihkan Pencarian' : 'Clear Search';
  String get clearFilters => locale.languageCode == 'id' ? 'Bersihkan Filter' : 'Clear Filters';
  String get anyLanguage => locale.languageCode == 'id' ? 'Bahasa Apa Saja' : 'Any language';
  String get anyCategory => locale.languageCode == 'id' ? 'Kategori Apa Saja' : 'Any category';
  String get errorOpeningFilter => locale.languageCode == 'id' ? 'Error membuka pilihan filter' : 'Error opening filter selection';
  String get errorBrowsingTag => locale.languageCode == 'id' ? 'Error menjelajahi tag' : 'Error browsing tag';

  // History
  String get readingHistory => locale.languageCode == 'id' ? 'Riwayat Baca' : 'Reading History';
  String get clearAllHistory => locale.languageCode == 'id' ? 'Bersihkan Semua Riwayat' : 'Clear All History';
  String get manualCleanup => locale.languageCode == 'id' ? 'Pembersihan Manual' : 'Manual Cleanup';
  String get cleanupSettings => locale.languageCode == 'id' ? 'Pengaturan Pembersihan' : 'Cleanup Settings';
  String get removeFromHistory => locale.languageCode == 'id' ? 'Hapus dari Riwayat' : 'Remove from History';
  String get removeFromHistoryQuestion => locale.languageCode == 'id' ? 'Hapus item ini dari riwayat baca?' : 'Remove this item from reading history?';
  String get cleanup => locale.languageCode == 'id' ? 'Bersihkan' : 'Cleanup';
  String get failedToLoadCleanupStatus => locale.languageCode == 'id' ? 'Gagal memuat status pembersihan' : 'Failed to load cleanup status';

  // Connection Status
  String get checkingConnection => locale.languageCode == 'id' ? 'Memeriksa koneksi...' : 'Checking connection...';
  String get backOnline => locale.languageCode == 'id' ? 'Kembali online! Semua fitur tersedia.' : 'Back online! All features available.';
  String get stillNoInternet => locale.languageCode == 'id' ? 'Masih tidak ada koneksi internet.' : 'Still no internet connection.';
  String get unableToCheckConnection => locale.languageCode == 'id' ? 'Tidak dapat memeriksa koneksi.' : 'Unable to check connection.';

  // Quality Settings
  String get lowFaster => locale.languageCode == 'id' ? 'Rendah (Lebih Cepat)' : 'Low (Faster)';
  String get medium => locale.languageCode == 'id' ? 'Sedang' : 'Medium';
  String get highBetterQuality => locale.languageCode == 'id' ? 'Tinggi (Kualitas Lebih Baik)' : 'High (Better Quality)';
  String get originalLargest => locale.languageCode == 'id' ? 'Asli (Terbesar)' : 'Original (Largest)';

  // Random
  String get randomGallery => locale.languageCode == 'id' ? 'Galeri Acak' : 'Random Gallery';

  // Reader Screen
  String get nextPage => locale.languageCode == 'id' ? 'Halaman Berikutnya' : 'Next Page';
  String get previousPage => locale.languageCode == 'id' ? 'Halaman Sebelumnya' : 'Previous Page';
  String get pageOf => locale.languageCode == 'id' ? 'dari' : 'of';
  String get fullscreen => locale.languageCode == 'id' ? 'Layar Penuh' : 'Fullscreen';
  String get exitFullscreen => locale.languageCode == 'id' ? 'Keluar Layar Penuh' : 'Exit Fullscreen';

  // Filters and Sorting
  String get sortBy => locale.languageCode == 'id' ? 'Urutkan berdasarkan' : 'Sort by';
  String get filterBy => locale.languageCode == 'id' ? 'Filter berdasarkan' : 'Filter by';
  String get recent => locale.languageCode == 'id' ? 'Terbaru' : 'Recent';
  String get popular => locale.languageCode == 'id' ? 'Populer' : 'Popular';
  String get oldest => locale.languageCode == 'id' ? 'Terlama' : 'Oldest';

  // Network and Connectivity
  String get noInternetConnection => locale.languageCode == 'id' ? 'Tidak ada koneksi internet' : 'No internet connection';
  String get connectionError => locale.languageCode == 'id' ? 'Kesalahan koneksi' : 'Connection error';
  String get serverError => locale.languageCode == 'id' ? 'Kesalahan server' : 'Server error';

  // Downloads Screen
  String get downloads => locale.languageCode == 'id' ? 'Unduhan' : 'Downloads';
  String get downloadError => locale.languageCode == 'id' ? 'Error Unduhan' : 'Download Error';
  String get initializingDownloads => locale.languageCode == 'id' ? 'Memulai unduhan...' : 'Initializing downloads...';
  String get loadingDownloads => locale.languageCode == 'id' ? 'Memuat unduhan...' : 'Loading downloads...';
  String get pauseAll => locale.languageCode == 'id' ? 'Pause Semua' : 'Pause All';
  String get resumeAll => locale.languageCode == 'id' ? 'Resume Semua' : 'Resume All';
  String get cancelAll => locale.languageCode == 'id' ? 'Batal Semua' : 'Cancel All';
  String get clearCompleted => locale.languageCode == 'id' ? 'Bersihkan Selesai' : 'Clear Completed';
  String get cleanupStorage => locale.languageCode == 'id' ? 'Bersihkan Storage' : 'Cleanup Storage';
  String get all => locale.languageCode == 'id' ? 'Semua' : 'All';
  String get active => locale.languageCode == 'id' ? 'Aktif' : 'Active';
  String get completed => locale.languageCode == 'id' ? 'Selesai' : 'Completed';
  String get noDownloadsYet => locale.languageCode == 'id' ? 'Belum ada unduhan' : 'No downloads yet';
  String get noActiveDownloads => locale.languageCode == 'id' ? 'Tidak ada unduhan aktif' : 'No active downloads';
  String get noQueuedDownloads => locale.languageCode == 'id' ? 'Tidak ada unduhan antrian' : 'No queued downloads';
  String get noCompletedDownloads => locale.languageCode == 'id' ? 'Tidak ada unduhan selesai' : 'No completed downloads';
  String get noFailedDownloads => locale.languageCode == 'id' ? 'Tidak ada unduhan gagal' : 'No failed downloads';
  String get pdfConversionStarted => locale.languageCode == 'id' ? 'Konversi PDF dimulai' : 'PDF conversion started';
  
  // Additional getters for dialogs and details
  String get cancelAllDownloads => locale.languageCode == 'id' ? 'Batalkan Semua Unduhan' : 'Cancel All Downloads';
  String get cancelAllConfirmation => locale.languageCode == 'id' ? 'Yakin ingin membatalkan semua unduhan aktif? Tindakan ini tidak bisa dibatalkan.' : 'Are you sure you want to cancel all active downloads? This action cannot be undone.';
  String get cancelDownload => locale.languageCode == 'id' ? 'Batalkan Unduhan' : 'Cancel Download';
  String get cancelDownloadConfirmation => locale.languageCode == 'id' ? 'Yakin ingin membatalkan unduhan ini? Progress akan hilang.' : 'Are you sure you want to cancel this download? Progress will be lost.';
  String get no => locale.languageCode == 'id' ? 'Tidak' : 'No';
  String get removeDownload => locale.languageCode == 'id' ? 'Hapus Unduhan' : 'Remove Download';
  String get removeDownloadConfirmation => locale.languageCode == 'id' ? 'Yakin ingin menghapus unduhan ini dari daftar? File yang telah diunduh akan dihapus.' : 'Are you sure you want to remove this download from the list? Downloaded files will be deleted.';
  String get cleanupConfirmation => locale.languageCode == 'id' ? 'Ini akan menghapus file yatim dan membersihkan unduhan yang gagal. Lanjutkan?' : 'This will remove orphaned files and clean up failed downloads. Continue?';
  String get downloadDetails => locale.languageCode == 'id' ? 'Detail Unduhan' : 'Download Details';
  String get status => locale.languageCode == 'id' ? 'Status' : 'Status';
  String get progress => locale.languageCode == 'id' ? 'Progress' : 'Progress';
  String get progressPercent => locale.languageCode == 'id' ? 'Progress %' : 'Progress %';
  String get speed => locale.languageCode == 'id' ? 'Kecepatan' : 'Speed';
  String get size => locale.languageCode == 'id' ? 'Ukuran' : 'Size';
  String get started => locale.languageCode == 'id' ? 'Dimulai' : 'Started';
  String get ended => locale.languageCode == 'id' ? 'Selesai' : 'Ended';
  String get duration => locale.languageCode == 'id' ? 'Durasi' : 'Duration';
  String get eta => locale.languageCode == 'id' ? 'ETA' : 'ETA';
  
  // Favorites Screen
  String get removedFavoritesCount => locale.languageCode == 'id' ? 'Menghapus %d favorit' : 'Removed %d favorites';
  String get failedToRemoveFavorites => locale.languageCode == 'id' ? 'Gagal menghapus favorit: %s' : 'Failed to remove favorites: %s';
  String get deleteFavorites => locale.languageCode == 'id' ? 'Hapus Favorit' : 'Delete Favorites';
  String get deleteFavoritesConfirmation => locale.languageCode == 'id' ? 'Yakin ingin menghapus %d favorit?' : 'Are you sure you want to remove %d favorite%s?';
  String get exportFavorites => locale.languageCode == 'id' ? 'Ekspor Favorit' : 'Export Favorites';
  String get exportingFavorites => locale.languageCode == 'id' ? 'Mengekspor favorit...' : 'Exporting favorites...';
  String get exportComplete => locale.languageCode == 'id' ? 'Ekspor Selesai' : 'Export Complete';
  String get exportedFavoritesCount => locale.languageCode == 'id' ? 'Berhasil mengekspor %d favorit.' : 'Exported %d favorites successfully.';
  String get exportFailed => locale.languageCode == 'id' ? 'Ekspor gagal: %s' : 'Export failed: %s';
  String get selectedCount => locale.languageCode == 'id' ? '%d dipilih' : '%d selected';
  String get selectFavorites => locale.languageCode == 'id' ? 'Pilih favorit' : 'Select favorites';
  String get exportAction => locale.languageCode == 'id' ? 'Ekspor' : 'Export';
  String get refreshAction => locale.languageCode == 'id' ? 'Segarkan' : 'Refresh';
  String get deleteSelected => locale.languageCode == 'id' ? 'Hapus yang dipilih' : 'Delete selected';
  String get searchFavorites => locale.languageCode == 'id' ? 'Cari favorit...' : 'Search favorites...';
  String get selectAll => locale.languageCode == 'id' ? 'Pilih Semua' : 'Select All';
  String get clearSelection => locale.languageCode == 'id' ? 'Bersihkan' : 'Clear';
  String get loadingFavorites => locale.languageCode == 'id' ? 'Memuat favorit...' : 'Loading favorites...';
  String get errorLoadingFavorites => locale.languageCode == 'id' ? 'Error Memuat Favorit' : 'Error Loading Favorites';
  String get removeFavorite => locale.languageCode == 'id' ? 'Hapus Favorit' : 'Remove Favorite';
  String get removeFavoriteConfirmation => locale.languageCode == 'id' ? 'Yakin ingin menghapus konten ini dari favorit?' : 'Are you sure you want to remove this content from favorites?';
  String get removeAction => locale.languageCode == 'id' ? 'Hapus' : 'Remove';
  String get unknown => locale.languageCode == 'id' ? 'Tidak diketahui' : 'Unknown';
  String get justNow => locale.languageCode == 'id' ? 'Baru saja' : 'Just now';
  String get daysAgo => locale.languageCode == 'id' ? '%dd yang lalu' : '%dd ago';
  String get hoursAgo => locale.languageCode == 'id' ? '%dj yang lalu' : '%dh ago';
  String get minutesAgo => locale.languageCode == 'id' ? '%dm yang lalu' : '%dm ago';
  String get removingFromFavorites => locale.languageCode == 'id' ? 'Menghapus dari favorit...' : 'Removing from favorites...';
  String get removedFromFavorites => locale.languageCode == 'id' ? 'Dihapus dari favorit' : 'Removed from favorites';
  String get failedToRemoveFavorite => locale.languageCode == 'id' ? 'Gagal menghapus favorit: %s' : 'Failed to remove favorite: %s';
  String get retryAction => locale.languageCode == 'id' ? 'Coba Lagi' : 'Retry';
  // From main
  String get foundGalleries => locale.languageCode == 'id' ? 'Galeri Ditemukan' : 'Found Galleries';
  String get checkingDownloadStatus => locale.languageCode == 'id' ? 'Memeriksa Status Unduhan...' : 'Checking Download Status...';
  String get allGalleriesDownloaded => locale.languageCode == 'id' ? 'Semua Galeri Telah Diunduh' : 'All Galleries Downloaded';

  // Helper functions for formatted strings
  String removedFavoritesCountFormat(int count) {
    return locale.languageCode == 'id' ? 'Menghapus $count favorit' : 'Removed $count favorites';
  }
  
  String failedToRemoveFavoritesFormat(String error) {
    return locale.languageCode == 'id' ? 'Gagal menghapus favorit: $error' : 'Failed to remove favorites: $error';
  }
  
  String deleteFavoritesConfirmationFormat(int count) {
    if (locale.languageCode == 'id') {
      return 'Yakin ingin menghapus $count favorit?';
    } else {
      final suffix = count > 1 ? 's' : '';
      return 'Are you sure you want to remove $count favorite$suffix?';
    }
  }
  
  String exportedFavoritesCountFormat(int count) {
    return locale.languageCode == 'id' ? 'Berhasil mengekspor $count favorit.' : 'Exported $count favorites successfully.';
  }
  
  String exportFailedFormat(String error) {
    return locale.languageCode == 'id' ? 'Ekspor gagal: $error' : 'Export failed: $error';
  }
  
  String selectedCountFormat(int count) {
    return locale.languageCode == 'id' ? '$count dipilih' : '$count selected';
  }
  
  String contentIdFormatFunc(String id) {
    return 'ID: $id';
  }
  
  String daysAgoFormat(int days) {
    return locale.languageCode == 'id' ? '${days}h yang lalu' : '${days}d ago';
  }
  
  String hoursAgoFormat(int hours) {
    return locale.languageCode == 'id' ? '${hours}j yang lalu' : '${hours}h ago';
  }
  
  String minutesAgoFormat(int minutes) {
    return locale.languageCode == 'id' ? '${minutes}m yang lalu' : '${minutes}m ago';
  }
  
  String failedToRemoveFavoriteFormat(String error) {
    return locale.languageCode == 'id' ? 'Gagal menghapus favorit: $error' : 'Failed to remove favorite: $error';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
