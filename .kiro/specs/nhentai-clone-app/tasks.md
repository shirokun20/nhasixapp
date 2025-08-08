# Implementation Plan

## ⚠️ IMPORTANT REMINDER
**Before implementing any task, ALWAYS check `.kiro/specs/nhentai-clone-app/components-list.md` for:**
- Component status (✅ Implemented, 🚧 In Progress, ⏳ Planned)
- File paths and structure
- Dependencies and integration points
- Architecture decisions (BLoC vs Cubit, app-wide vs screen-specific)
- Implementation details and requirements

**This ensures consistency and prevents duplication of work!**

---

- [x] 1. Setup project structure dan core dependencies
  - Setup Clean Architecture folder structure (presentation, domain, data)
  - Add semua dependencies yang diperlukan ke pubspec.yaml
  - Setup service locator dengan GetIt
  - Configure Go Router untuk navigation
  - _Requirements: 1.1, 6.1_

- [x] 2. Implement core domain layer
  - [x] 2.1 Create domain entities dan value objects
    - Implement Content, Tag, SearchFilter, UserPreferences entities
    - Create value objects untuk type safety
    - Add Equatable untuk object comparison
    - _Requirements: 1.1, 2.1, 3.1_

  - [x] 2.2 Define repository interfaces
    - Create ContentRepository interface
    - Create UserDataRepository interface  
    - Create SettingsRepository interface
    - Define method signatures untuk semua operations
    - _Requirements: 1.1, 2.1, 4.1, 7.1_

  - [x] 2.3 Implement use cases
    - Create GetContentListUseCase
    - Create SearchContentUseCase
    - Create AddToFavoritesUseCase
    - Create DownloadContentUseCase
    - Add comprehensive error handling
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1_

- [x] 3. Setup data layer foundation (SIMPLIFIED)
  - [x] 3.1 Create simplified database schema dan local data source
    - Setup SQLite database dengan sqflite (5 tables only)
    - Create simplified database schema (favorites, downloads, history, preferences, search_history)
    - Implement LocalDataSource dengan simplified CRUD operations
    - Add database indexes untuk performance
    - Remove complex content caching and tag management
    - _Requirements: 4.1, 5.1, 7.1_

  - [x] 3.2 Implement web scraping remote data source
    - Create RemoteDataSource dengan Dio HTTP client
    - Implement HTML parsing dengan html package
    - Create NhentaiScraper dengan CSS selectors
    - Integrate existing TagResolver for tag resolution
    - Implement anti-detection measures
    - Ensure HTTP client is not disposed to prevent connection errors
    - _Requirements: 1.1, 2.1, 3.1, 8.1_

  - [x] 3.3 Implement simplified repository implementations
    - Create ContentRepositoryImpl dengan basic functionality
    - Create UserDataRepositoryImpl untuk simplified local data
    - Remove complex caching strategy and tag management
    - Add basic offline support untuk favorites dan history
    - _Requirements: 1.1, 2.1, 4.1, 5.1, 7.1_

  - [x] 3.4 Fix HTTP client lifecycle management
    - Review dan fix disposal of Dio HTTP client
    - Ensure singleton pattern untuk HTTP client
    - Add proper error handling untuk connection issues
    - Test HTTP client persistence across app lifecycle
    - _Requirements: 8.1_

- [x] 4. Create core BLoC dan Cubit state management (COMPLETED)
  - [x] 4.1 Implement SplashBloc untuk initial loading (Complex - tetap BLoC)
    - Create SplashBloc dengan initial loading logic
    - Add loading states dan error handling
    - Implement navigation setelah loading success
    - _Requirements: 1.1, 8.1_

  - [x] 4.2 Implement ContentBloc untuk content management (Complex - tetap BLoC)
    - Create ContentBloc dengan pagination support
    - Add loading, loaded, error states
    - Implement pull-to-refresh functionality
    - Add simple pagination dengan next/previous buttons
    - _Requirements: 1.1, 2.1, 6.1_

  - [x] 4.3 Implement SearchBloc untuk advanced search (Complex - tetap BLoC)
    - Create SearchBloc dengan filter support tanpa langsung mengirim API request
    - Add UpdateSearchFilter event untuk menyimpan state filter tanpa API call
    - Add SearchSubmitted event untuk memicu API call saat tombol Search ditekan
    - Implement search history functionality
    - Add tag suggestions dari assets/json/tags.json
    - _Requirements: 2.1, 6.1_

  - [x] 4.4 Implement simple Cubits untuk basic state management
    - Create NetworkCubit untuk connection status tracking
    - Implement DetailCubit untuk content detail dan favorite toggle
    - Add base Cubit classes dengan common functionality
    - Setup Cubit providers dalam MultiBlocProviderConfig
    - _Requirements: 6.1, 8.1_

- [x] 4.5 Database and Repository Simplification (COMPLETED)
  - [x] Simplify database schema (remove contents, tags, content_tags, favorite_categories, pagination_cache)
  - [x] Update LocalDataSource to match simplified schema
  - [x] Simplify UserDataRepository interface (remove complex result wrappers)
  - [x] Update all use cases (favorites, downloads, history) to work with simplified interface
  - [x] Update models (DownloadStatusModel, HistoryModel) with new fields
  - [x] Fix search bloc compatibility with simplified LocalDataSource
  - [x] Update documentation (design.md, components-list.md)
  - _Requirements: All simplified for better maintainability_

- [x] 5. Build core UI components
💡 *Remember to check components-list.md first*
  - [x] 5.1 Update AppMainDrawerWidget dengan menu yang sesuai
    - Update drawer dengan 4 menu utama: Downloaded galleries, Random gallery, Favorite galleries, View history
    - Implement navigation untuk setiap menu item
    - Maintain black theme consistency
    - Add proper icons dan styling
    - _Requirements: 6.1_

  - [x] 5.2 Create reusable widgets
    - Implement ContentCard dengan image caching
    - Create SearchFilter widget dengan advanced options yang tidak langsung trigger API
    - Build ProgressIndicator dan ErrorWidget dengan black theme
    - Create PaginationWidget dengan next/previous buttons
    - Add SearchFilterWidget dengan support untuk FilterItem (include/exclude)
    - _Requirements: 6.1_

  - [x] 5.3 Implement main screens dengan tema hitam
    - Update SplashScreen dengan initial loading progress
    - Fix MainScreen dengan content grid dan tema hitam default, support untuk menampilkan hasil pencarian
    - Implement SearchScreen dengan filters yang tidak langsung trigger API, dengan tombol Search/Apply
    - Create DetailScreen dengan content metadata
    - Replace infinite scroll dengan simple pagination buttons
    - Add search state persistence untuk MainScreen
    - _Requirements: 1.1, 2.1, 3.1, 6.1_

  - [x] 5.4 Add image loading dan caching
    - Implement progressive image loading
    - Add CachedNetworkImage dengan custom cache
    - Create thumbnail generation
    - Add image compression untuk storage
    - _Requirements: 3.1, 5.1, 6.1_

- [x] 6. Update search flow sesuai perubahan-alur-search.md
💡 *Remember to check components-list.md first*
  - [x] 6.1 Update SearchBloc dengan alur baru
    - Modify SearchBloc untuk tidak langsung mengirim API request saat input berubah
    - Add UpdateSearchFilter event untuk menyimpan state filter tanpa API call
    - Add SearchSubmitted event untuk memicu API call saat tombol Search ditekan
    - Update SearchFilter model untuk menggunakan FilterItem dengan include/exclude
    - Implement search state persistence ke local datasource
    - _Requirements: 2.1_

  - [x] 6.2 Update SearchScreen UI dengan alur baru
    - Modify SearchScreen untuk tidak langsung trigger API saat input berubah
    - Add tombol "Search" atau "Apply" untuk memicu pencarian
    - Implement interface pencarian untuk Tags, Artists, Characters, Parodies, Groups dari assets/json/tags.json
    - Update SearchFilterWidget untuk support FilterItem dengan include/exclude
    - Add UI untuk membedakan single select (language, category) dan multiple select (tags, artists, dll)
    - _Requirements: 2.1, 6.1_

  - [x] 6.3 Update MainScreen untuk menampilkan hasil pencarian
    - Modify MainScreen untuk bisa menampilkan hasil pencarian dari SearchScreen
    - Load search state dari local datasource saat aplikasi dibuka ulang
    - Update ContentBloc untuk handle search results dan normal content list
    - Implement navigation dari SearchScreen kembali ke MainScreen dengan hasil
    - _Requirements: 2.1, 6.1_

  - [x] 6.4 Update local datasource untuk search state persistence
    - Add search_filter_state table ke database schema
    - Implement saveSearchFilter, getLastSearchFilter, clearSearchFilter methods
    - Update LocalDataSource untuk handle SearchFilter serialization/deserialization
    - Add migration untuk table baru jika diperlukan
    - _Requirements: 2.1_

- [ ] 7. Implement reader functionality
💡 *Remember to check components-list.md first*
  - [ ] 7.1 Create basic reader screen dengan ReaderCubit
    - Build ReaderScreen dengan page navigation
    - Implement ReaderCubit untuk simple state management
    - Add zoom dan pan functionality dengan PhotoView
    - Implement reading progress tracking
    - Add reading modes (single page, continuous)
    - _Requirements: 3.1_

  - [ ] 7.2 Add advanced reader features
    - Implement page preloading untuk smooth reading
    - Add reading timer dan statistics
    - Create page bookmarks functionality
    - Add gesture controls untuk navigation
    - _Requirements: 3.1, 7.1_

  - [ ] 7.3 Implement reader settings
    - Add reading direction options
    - Implement brightness control
    - Create auto-hide UI functionality
    - Add keep screen on option
    - _Requirements: 3.1, 7.1_

- [ ] 8. Build favorites dan download system
💡 *Remember to check components-list.md first*
  - [ ] 8.1 Implement favorites management dengan FavoriteCubit
    - Create FavoriteCubit untuk simple CRUD operations
    - Build FavoritesScreen dengan category tabs
    - Add favorite categories management
    - Implement batch favorite operations
    - _Requirements: 4.1_

  - [ ] 8.2 Create download manager dengan DownloadBloc
    - Implement DownloadBloc dengan queue system (Complex - tetap BLoC)
    - Build DownloadsScreen dengan status tracking
    - Add concurrent download support
    - Create download progress notifications
    - _Requirements: 5.1_

  - [ ] 8.3 Add offline reading capabilities
    - Implement offline content detection
    - Create offline reader mode
    - Add offline search dalam downloaded content
    - Build offline content management
    - _Requirements: 5.1_

- [ ] 9. Implement settings dan preferences
💡 *Remember to check components-list.md first*
  - [ ] 9.1 Create settings screen dengan SettingsCubit
    - Build SettingsScreen dengan organized sections
    - Implement SettingsCubit untuk simple state management
    - Add theme selection (light/dark/AMOLED)
    - Implement language preferences
    - Create image quality settings
    - _Requirements: 7.1_

  - [ ] 9.2 Add advanced customization
    - Implement custom theme creation
    - Add grid layout customization
    - Create gesture customization
    - Build backup dan restore functionality
    - _Requirements: 7.1_

- [ ] 10. Add advanced features
💡 *Remember to check components-list.md first*
  - [ ] 10.1 Implement tag management
    - Create TagScreen dengan tag statistics using existing TagResolver
    - Add tag blacklisting functionality
    - Implement popular tags display with TagResolver.getTagsByType()
    - Build tag-based content discovery using TagResolver.searchTags()
    - Integrate TagResolver cache management features
    - _Requirements: 2.1_

  - [ ] 10.2 Create history dan statistics
    - Implement HistoryScreen dengan reading history
    - Add reading statistics dashboard
    - Create reading streaks tracking
    - Build content recommendations
    - _Requirements: 7.1_

  - [ ] 10.3 Add community features
    - Implement comment system (if supported)
    - Add rating dan review functionality
    - Create user interaction tracking
    - Build recommendation engine
    - _Requirements: 2.1, 3.1_

- [ ] 11. Performance optimization dan real device testing
💡 *Remember to check components-list.md first*
  - [ ] 11.1 Optimize performance dan test pada perangkat nyata
    - Implement memory management untuk images dan test pada perangkat Android fisik
    - Add database query optimization dan verify performance pada real device
    - Create background task management dan test background execution pada perangkat nyata
    - Optimize app startup time dan measure pada berbagai perangkat Android
    - Test aplikasi dengan berbagai kondisi jaringan pada perangkat fisik
    - Monitor penggunaan CPU dan memory pada perangkat nyata
    - _Requirements: 6.1, 8.1, 9.1_

  - [ ] 11.2 Hapus semua file test yang tidak diperlukan
    - Remove folder test/ dan semua isinya
    - Clean up pubspec.yaml dari test dependencies yang tidak diperlukan
    - Verify project structure tetap bersih setelah penghapusan
    - Update .gitignore jika diperlukan
    - _Requirements: 8.1_

  - [ ] 11.3 Create tutorial Clean Architecture berbahasa Indonesia
    - Buat docs/TUTORIAL_CLEAN_ARCHITECTURE.md
    - Jelaskan konsep Clean Architecture dengan contoh dari project
    - Sertakan diagram layer dan dependency flow
    - Tambahkan contoh implementasi entities, use cases, dan repositories
    - Berikan tips best practices dan common pitfalls
    - _Requirements: Learning objectives_

  - [ ] 11.4 Create tutorial BLoC dan Cubit State Management berbahasa Indonesia
    - Buat docs/TUTORIAL_BLOC_CUBIT_STATE_MANAGEMENT.md
    - Jelaskan perbedaan BLoC vs Cubit dan kapan menggunakan masing-masing
    - Sertakan implementasi ContentBloc (complex) dan SettingsCubit (simple)
    - Tambahkan penjelasan tentang states, events, dan direct method calls
    - Berikan contoh testing BLoC dan Cubit dengan bloc_test
    - _Requirements: Learning objectives_

  - [ ] 11.5 Create tutorial Web Scraping dan Caching berbahasa Indonesia
    - Update docs/TUTORIAL_SCRAPER_CACHE.md dengan konten yang lebih lengkap
    - Jelaskan strategi web scraping dengan Dio dan HTML parsing
    - Sertakan implementasi anti-detection measures
    - Tambahkan penjelasan caching strategy dan offline-first approach
    - Berikan troubleshooting common issues
    - _Requirements: Learning objectives_

  - [ ] 11.6 Add monitoring dan analytics dengan real device testing
    - Implement error tracking dan test error scenarios pada perangkat nyata
    - Add performance monitoring dan verify metrics pada perangkat Android fisik
    - Create usage analytics (optional) dan test data collection pada real device
    - Build crash reporting system dan test crash recovery pada perangkat nyata
    - Test aplikasi stability dengan extended usage pada perangkat fisik
    - _Requirements: 8.1, 9.1_

- [ ] 12. Polish dan deployment preparation dengan real device validation
💡 *Remember to check components-list.md first*
  - [ ] 12.1 UI/UX polish dan real device testing
    - Add animations dan transitions dan test smoothness pada perangkat Android fisik
    - Implement loading skeletons dan verify performance pada berbagai perangkat
    - Create empty states dan error screens dan test user experience pada real device
    - Add haptic feedback dan test responsiveness pada perangkat nyata
    - Test UI responsiveness pada berbagai ukuran layar perangkat fisik
    - _Requirements: 6.1, 9.1_

  - [ ] 12.2 Add accessibility features dengan real device testing
    - Implement screen reader support dan test dengan TalkBack pada perangkat Android
    - Add semantic labels dan verify accessibility pada perangkat nyata
    - Create high contrast mode dan test visibility pada berbagai perangkat
    - Build keyboard navigation support dan test pada perangkat dengan keyboard fisik
    - Test accessibility features dengan pengguna nyata pada perangkat fisik
    - _Requirements: 6.1, 9.1_

  - [ ] 12.3 Prepare for deployment dengan real device validation
    - Setup app icons dan splash screens dan test tampilan pada berbagai perangkat
    - Configure build flavors (dev/prod) dan test kedua build pada perangkat nyata
    - Add code obfuscation dan verify aplikasi tetap berfungsi pada perangkat fisik
    - Create release build configuration dan test performa release build pada real device
    - Test installation dan uninstallation process pada berbagai perangkat Android
    - _Requirements: 8.1, 9.1_

- [ ] 13. Comprehensive real device testing dan validation
💡 *Remember to check components-list.md first*
  - [ ] 13.1 Core functionality testing pada perangkat nyata
    - Test splash screen dan initial loading pada berbagai perangkat Android
    - Verify content browsing dan pagination pada perangkat dengan RAM terbatas
    - Test search functionality dengan keyboard fisik dan virtual pada real device
    - Validate content detail view dan image loading pada berbagai ukuran layar
    - Test reader mode dengan gesture navigation pada perangkat touchscreen
    - _Requirements: 9.1_

  - [ ] 13.2 Network dan offline testing pada perangkat fisik
    - Test aplikasi dengan koneksi WiFi, 4G, dan 3G pada perangkat nyata
    - Verify offline functionality dengan benar-benar memutus koneksi internet
    - Test download functionality dengan berbagai kecepatan internet pada real device
    - Validate sync behavior saat koneksi internet kembali tersedia
    - Test aplikasi behavior saat koneksi internet tidak stabil
    - _Requirements: 9.1_

  - [ ] 13.3 Performance dan resource usage testing
    - Monitor memory usage selama extended usage pada perangkat fisik
    - Test aplikasi dengan storage hampir penuh pada perangkat nyata
    - Verify battery usage optimization pada berbagai perangkat Android
    - Test aplikasi performance pada perangkat dengan spesifikasi rendah
    - Monitor CPU usage dan thermal behavior pada perangkat fisik
    - _Requirements: 9.1_

  - [ ] 13.4 User experience testing pada perangkat nyata
    - Test aplikasi dengan berbagai orientasi layar pada perangkat fisik
    - Verify gesture navigation dan touch responsiveness pada real device
    - Test aplikasi dengan berbagai ukuran font sistem pada perangkat nyata
    - Validate dark theme appearance pada berbagai jenis layar perangkat
    - Test aplikasi behavior saat menerima notifikasi pada perangkat fisik
    - _Requirements: 9.1_

- [ ] 14. Documentation dan learning resources
💡 *Remember to check components-list.md first*
  - [ ] 14.1 Create tutorial Database Operations berbahasa Indonesia
    - Buat docs/TUTORIAL_DATABASE_OPERATIONS.md
    - Jelaskan implementasi SQLite dengan sqflite
    - Sertakan contoh CRUD operations dan migrations
    - Tambahkan penjelasan tentang database schema design
    - Berikan tips optimasi query dan indexing
    - _Requirements: Learning objectives_

  - [ ] 14.2 Create tutorial UI Components dan Navigation berbahasa Indonesia
    - Buat docs/TUTORIAL_UI_NAVIGATION.md
    - Jelaskan implementasi custom widgets dan theming
    - Sertakan contoh Go Router configuration
    - Tambahkan penjelasan tentang responsive design
    - Berikan tips untuk dark theme implementation
    - _Requirements: Learning objectives_

  - [ ] 14.3 Create tutorial Offline Functionality berbahasa Indonesia
    - Buat docs/TUTORIAL_OFFLINE_FUNCTIONALITY.md
    - Jelaskan implementasi offline-first architecture
    - Sertakan contoh download manager dan background tasks
    - Tambahkan penjelasan tentang data synchronization
    - Berikan troubleshooting untuk offline scenarios
    - _Requirements: Learning objectives_

  - [ ] 14.4 Create tutorial Real Device Testing berbahasa Indonesia
    - Buat docs/TUTORIAL_REAL_DEVICE_TESTING.md
    - Jelaskan metodologi testing pada perangkat fisik vs emulator
    - Sertakan checklist untuk testing berbagai aspek aplikasi
    - Tambahkan panduan monitoring performance pada perangkat nyata
    - Berikan tips troubleshooting issues yang hanya muncul pada real device
    - _Requirements: 9.1_

  - [ ] 14.5 Create comprehensive documentation index
    - Buat docs/README.md sebagai index semua tutorial
    - Organize tutorial berdasarkan kategori dan difficulty level
    - Add navigation links antar tutorial
    - Sertakan prerequisites dan learning path
    - _Requirements: Learning objectives_