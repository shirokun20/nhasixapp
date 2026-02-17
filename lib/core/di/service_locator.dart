import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_cubit.dart';
import 'package:nhasixapp/presentation/cubits/favorite/favorite_cubit.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide ImageCacheManager;

import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_nhentai/kuron_nhentai.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import 'package:kuron_komiktap/kuron_komiktap.dart';
import 'package:nhasixapp/core/adapters/nhentai_scraper_adapter_impl.dart';

// Core Network
import 'package:nhasixapp/core/network/http_client_manager.dart';

// Core Utils
import 'package:nhasixapp/core/utils/tag_data_manager.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/network/dns_settings_service.dart';
import 'package:nhasixapp/core/network/dns_resolver.dart'; // NEW

// Data Sources
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/anti_detection.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';
import 'package:nhasixapp/data/datasources/remote/api/nhentai_api_client.dart';
import 'package:nhasixapp/data/datasources/local/tag_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/request_rate_manager.dart';
import 'package:nhasixapp/data/datasources/local/doujin_list_dao.dart';

// BLoCs
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';

// Cubits
import 'package:nhasixapp/presentation/cubits/cubits.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/cubits/theme/theme_cubit.dart';
import 'package:nhasixapp/presentation/cubits/update/update_cubit.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_cubit.dart';
import 'package:nhasixapp/presentation/cubits/comments/comments_cubit.dart';

// Repositories
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'package:nhasixapp/data/repositories/content_repository_impl.dart';
import 'package:nhasixapp/data/repositories/user_data_repository_impl.dart';
import 'package:nhasixapp/data/repositories/settings_repository_impl.dart';
import 'package:nhasixapp/data/repositories/reader_settings_repository_impl.dart';
import 'package:nhasixapp/data/repositories/reader_repository_impl.dart';
import 'package:nhasixapp/data/repositories/crotpedia/crotpedia_feature_repository_impl.dart';

// Use Cases
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/content/get_chapter_images_usecase.dart';
import 'package:nhasixapp/domain/usecases/content/get_comments_usecase.dart';
import 'package:nhasixapp/domain/usecases/favorites/favorites_usecases.dart';
import 'package:nhasixapp/domain/usecases/downloads/downloads_usecases.dart';
import 'package:nhasixapp/domain/usecases/history/add_to_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/get_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/clear_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/remove_history_item_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/get_history_count_usecase.dart';
import 'package:nhasixapp/domain/usecases/settings/get_user_preferences_usecase.dart';
import 'package:nhasixapp/domain/usecases/settings/save_user_preferences_usecase.dart';
import 'package:nhasixapp/domain/usecases/crotpedia/get_genre_list_usecase.dart';
import 'package:nhasixapp/domain/usecases/crotpedia/get_doujin_list_usecase.dart';
import 'package:nhasixapp/domain/usecases/crotpedia/get_request_list_usecase.dart';

// Services
import 'package:nhasixapp/services/native_download_service.dart';
import 'package:nhasixapp/services/native_pdf_service.dart';
import 'package:nhasixapp/services/native_backup_service.dart';
import 'package:nhasixapp/services/native_pdf_reader_service.dart';
import 'package:nhasixapp/services/download_service.dart';

import 'package:nhasixapp/core/services/update_service.dart';
import 'package:nhasixapp/services/notification_service.dart';
import 'package:nhasixapp/services/pdf_service.dart';
import 'package:nhasixapp/services/pdf_conversion_service.dart';
import 'package:nhasixapp/services/pdf_conversion_queue_manager.dart';
import 'package:nhasixapp/services/history_cleanup_service.dart';
import 'package:nhasixapp/services/preferences_service.dart';
import 'package:nhasixapp/services/analytics_service.dart';
import 'package:nhasixapp/services/detail_cache_service.dart';
import 'package:nhasixapp/services/request_deduplication_service.dart';
import 'package:nhasixapp/services/app_update_service.dart';
import 'package:nhasixapp/services/image_cache_service.dart';
import 'package:nhasixapp/services/image_metadata_service.dart';
import 'package:nhasixapp/services/export_service.dart';
import 'package:nhasixapp/services/legal_content_service.dart';
import 'package:nhasixapp/services/cache/cache_manager.dart' as multi_cache;

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> setupLocator() async {
  await _setupExternalDependencies();
  _setupCore();
  _setupServices();
  _setupDataSources();
  _setupRepositories();
  _setupUseCases();
  _setupBlocs();
  _setupCubits();
}

/// Setup external dependencies that require async initialization
Future<void> _setupExternalDependencies() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // PreferencesService - Wrapper for SharedPreferences
  getIt.registerLazySingleton<PreferencesService>(() => PreferencesService(
        getIt<SharedPreferences>(),
      ));

  // Connectivity
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
}

/// Setup core utilities and services
void _setupCore() {
  // Logger - Using Singleton (not LazySingleton) to ensure it's immediately available
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  getIt.registerSingleton<Logger>(logger);

  // HTTP Client (Dio) - Using singleton manager
  // DNS-over-HTTPS is DISABLED because it's incompatible with HTTPS/SSL
  // (SNI and certificate validation fail when using IP addresses)
  final dio = HttpClientManager.initializeHttpClient(
    logger: logger,
    // dnsResolver: getIt<DnsResolver>(),  // DISABLED - incompatible with HTTPS
  );
  getIt.registerSingleton<Dio>(dio);

  // Cache Manager
  getIt.registerLazySingleton<CacheManager>(() => DefaultCacheManager());

  // Tag Data Manager
  getIt.registerLazySingleton<TagDataManager>(
      () => TagDataManager(logger: getIt<Logger>(), dio: getIt<Dio>()));

  // Remote Config Service (Assets-based configs, Remote tags download)
  getIt.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService(
        dio: getIt<Dio>(),
        logger: getIt<Logger>(),
      ));

  // DNS Settings Service
  getIt.registerLazySingleton<DnsSettingsService>(() => DnsSettingsService(
        prefs: getIt<SharedPreferences>(),
        logger: getIt<Logger>(),
      ));

  // DNS Resolver (NEW)
  getIt.registerLazySingleton<DnsResolver>(() => DnsResolver(
        settingsService: getIt<DnsSettingsService>(),
        logger: getIt<Logger>(),
      ));

  // Request Rate Manager
  getIt.registerLazySingleton<RequestRateManager>(() => RequestRateManager(
        remoteConfigService: getIt<RemoteConfigService>(),
        logger: getIt<Logger>(),
      ));
}

/// Setup services
void _setupServices() {
  // Notification Service
  getIt.registerLazySingleton<NotificationService>(
      () => NotificationService(logger: getIt<Logger>()));

  // PDF Service
  getIt.registerLazySingleton<PdfService>(
      () => PdfService(logger: getIt<Logger>()));

  // Native PDF Service
  getIt.registerLazySingleton<NativePdfService>(() => NativePdfService());

  // Native Services
  getIt.registerLazySingleton<NativeBackupService>(() => NativeBackupService());
  getIt.registerLazySingleton<NativePdfReaderService>(
    () => NativePdfReaderService(),
  );

  // PDF Conversion Service - High-level orchestration service for background PDF processing
  getIt.registerLazySingleton<PdfConversionService>(() => PdfConversionService(
        notificationService: getIt<NotificationService>(),
        nativePdfService: getIt<NativePdfService>(),
        logger: getIt<Logger>(),
      ));

  // PDF Conversion Queue Manager - Sequential queue for PDF conversions
  getIt.registerLazySingleton<PdfConversionQueueManager>(
    () => PdfConversionQueueManager()
      ..initialize(
        conversionService: getIt<PdfConversionService>(),
        notificationService: getIt<NotificationService>(),
        logger: getIt<Logger>(),
      ),
  );

  // Download Service - Core download logic with MediaStore support
  getIt.registerLazySingleton<DownloadService>(() => DownloadService(
        httpClient: getIt<Dio>(),
        notificationService: getIt<NotificationService>(),
        sourceRegistry: getIt<ContentSourceRegistry>(), // NEW
        logger: getIt<Logger>(),
      ));

  // Native Download Service
  getIt.registerLazySingleton<NativeDownloadService>(
      () => NativeDownloadService());

  // History Cleanup Service
  getIt
      .registerLazySingleton<HistoryCleanupService>(() => HistoryCleanupService(
            preferencesService: getIt<PreferencesService>(),
            clearHistoryUseCase: getIt<ClearHistoryUseCase>(),
            getHistoryCountUseCase: getIt<GetHistoryCountUseCase>(),
            logger: getIt<Logger>(),
          ));

  // Analytics Service - Privacy-first local analytics tracking
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Detail Cache Service - Performance optimization for content details
  getIt.registerLazySingleton<DetailCacheService>(() => DetailCacheService());

  // Request Deduplication Service - Prevents redundant API calls
  getIt.registerLazySingleton<RequestDeduplicationService>(
      () => RequestDeduplicationService());

  // App Update Service - Handles cache clearing on app updates
  getIt.registerLazySingleton<AppUpdateService>(() => AppUpdateService());

  // Image Cache Service - Advanced image caching with TTL and size management
  getIt.registerLazySingleton<ImageCacheService>(() => ImageCacheService());

  // Github Update Service
  getIt.registerLazySingleton<UpdateService>(() => UpdateService(
        logger: getIt<Logger>(),
      ));

  // Image Metadata Service - Handles image metadata generation and validation
  getIt.registerLazySingleton<ImageMetadataService>(() => ImageMetadataService(
        getIt<OfflineContentManager>(),
        getIt<Logger>(),
      ));

  // Multi-layer Cache Manager for Content - Memory + Disk caching -- USING MAP to prevent serialization issues
  getIt.registerLazySingleton<multi_cache.CacheManager<Map<String, dynamic>>>(
    () => multi_cache.CacheManager<Map<String, dynamic>>.standard(
      namespace: 'content',
      memoryMaxEntries: 50,
      diskMaxSizeMB: 30,
      memoryTTL: const Duration(hours: 1),
      diskTTL: const Duration(days: 1),
    )..initialize(),
  );

  // Multi-layer Cache Manager for Tag Lists
  getIt.registerLazySingleton<multi_cache.CacheManager<List<Tag>>>(
    () => multi_cache.CacheManager<List<Tag>>.standard(
      namespace: 'tags',
      memoryMaxEntries: 20,
      diskMaxSizeMB: 10,
      memoryTTL: const Duration(hours: 2),
      diskTTL: const Duration(days: 7),
    )..initialize(),
  );

  // Legal Content Service - Fetch legal docs from GitHub with local fallback
  getIt.registerLazySingleton<LegalContentService>(() => LegalContentService(
        dio: getIt<Dio>(),
        prefs: getIt<SharedPreferences>(),
      ));
}

/// Setup data sources (Remote and Local)
void _setupDataSources() {
  // Anti-Detection
  getIt.registerLazySingleton<AntiDetection>(() => AntiDetection(
        logger: getIt<Logger>(),
      ));

  // Cloudflare Bypass
  getIt.registerLazySingleton<CloudflareBypassNoWebView>(
      () => CloudflareBypassNoWebView(
            httpClient: getIt<Dio>(),
            logger: getIt<Logger>(),
          ));

  // Nhentai Scraper
  getIt.registerLazySingleton<NhentaiScraper>(() => NhentaiScraper(
        logger: getIt<Logger>(),
        remoteConfigService: getIt<RemoteConfigService>(),
      ));

  // nhentai API Client (for API-first approach)
  getIt.registerLazySingleton<NhentaiApiClient>(() => NhentaiApiClient(
        rateManager: getIt<RequestRateManager>(),
        remoteConfigService: getIt<RemoteConfigService>(),
      ));

  // Remote Data Source (with API client for fallback support)
  getIt.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(
        httpClient: getIt<Dio>(),
        scraper: getIt<NhentaiScraper>(),
        cloudflareBypass: getIt<CloudflareBypassNoWebView>(),
        antiDetection: getIt<AntiDetection>(),
        rateManager: getIt<RequestRateManager>(),
        remoteConfigService: getIt<RemoteConfigService>(),
        apiClient: getIt<NhentaiApiClient>(),
        logger: getIt<Logger>(),
      ));

  // Nhentai Scraper Adapter
  getIt.registerLazySingleton<NhentaiScraperAdapter>(
      () => NhentaiScraperAdapterImpl(getIt<RemoteDataSource>()));

  // Nhentai Source
  getIt.registerLazySingleton<NhentaiSource>(() => NhentaiSource(
        scraper: getIt<NhentaiScraperAdapter>(),
        displayName:
            getIt<RemoteConfigService>().getConfig('nhentai')?.ui?.displayName,
      ));

  // Crotpedia Cookie Store
  getIt.registerLazySingleton<CrotpediaCookieStore>(
      () => CrotpediaCookieStore());

  // Crotpedia Auth Manager
  getIt.registerLazySingleton<CrotpediaAuthManager>(() => CrotpediaAuthManager(
        dio: getIt<Dio>(),
        cookieStore: getIt<CrotpediaCookieStore>(),
      ));

  // Crotpedia Scraper
  getIt.registerLazySingleton<CrotpediaScraper>(() => CrotpediaScraper(
        customSelectors: getIt<RemoteConfigService>()
            .getConfig('crotpedia')
            ?.scraper
            ?.selectors,
      ));

  // Crotpedia Source
  getIt.registerLazySingleton<CrotpediaSource>(() => CrotpediaSource(
        scraper: getIt<CrotpediaScraper>(),
        authManager: getIt<CrotpediaAuthManager>(),
        dio: getIt<Dio>(),
        navigatorKey: AppRouter.navigatorKey,
        logger: getIt<Logger>(),
        baseUrl:
            getIt<RemoteConfigService>().getConfig('crotpedia')?.api?.baseUrl,
        displayName: getIt<RemoteConfigService>()
            .getConfig('crotpedia')
            ?.ui
            ?.displayName,
      ));

  // KomikTap Scraper
  getIt.registerLazySingleton<KomiktapScraper>(() => KomiktapScraper(
        customSelectors: getIt<RemoteConfigService>()
            .getConfig('komiktap')
            ?.scraper
            ?.selectors,
      ));

  // KomikTap Source
  getIt.registerLazySingleton<KomiktapSource>(() => KomiktapSource(
        scraper: getIt<KomiktapScraper>(),
        dio: getIt<Dio>(),
        logger: getIt<Logger>(),
        baseUrl: getIt<RemoteConfigService>().getConfig('komiktap')?.baseUrl,
        displayName:
            getIt<RemoteConfigService>().getConfig('komiktap')?.ui?.displayName,
      ));

  // Content Source Registry
  getIt.registerLazySingleton<ContentSourceRegistry>(() {
    final registry = ContentSourceRegistry();
    registry.register(getIt<NhentaiSource>());
    registry.register(getIt<CrotpediaSource>());
    registry.register(getIt<KomiktapSource>()); // NEW
    return registry;
  });

  // Database Helper
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // Local Data Source
  getIt.registerLazySingleton<LocalDataSource>(
      () => LocalDataSource(getIt<DatabaseHelper>()));

  // Tag Data Source
  getIt.registerLazySingleton<TagDataSource>(
      () => TagDataSource(logger: getIt<Logger>()));

  // Crotpedia Doujin List DAO
  getIt.registerLazySingleton<DoujinListDao>(
      () => DoujinListDao(getIt<DatabaseHelper>()));
}

/// Setup repository implementations
void _setupRepositories() {
  // Content Repository with multi-layer cache integration
  getIt.registerLazySingleton<ContentRepository>(() => ContentRepositoryImpl(
        contentSourceRegistry: getIt<ContentSourceRegistry>(),
        remoteDataSource: getIt<RemoteDataSource>(),
        detailCacheService: getIt<DetailCacheService>(),
        requestDeduplicationService: getIt<RequestDeduplicationService>(),
        contentCacheManager:
            getIt<multi_cache.CacheManager<Map<String, dynamic>>>(),
        tagCacheManager: getIt<multi_cache.CacheManager<List<Tag>>>(),
        // localDataSource: getIt<LocalDataSource>(),
        logger: getIt<Logger>(),
      ));

  // User Data Repository
  getIt.registerLazySingleton<UserDataRepository>(() => UserDataRepositoryImpl(
        localDataSource: getIt(),
        logger: getIt(),
      ));

  // Reader Settings Repository
  getIt.registerLazySingleton<ReaderSettingsRepository>(
      () => ReaderSettingsRepositoryImpl(
            getIt<SharedPreferences>(),
          ));

  // Reader Repository
  getIt.registerLazySingleton<ReaderRepository>(() => ReaderRepositoryImpl(
        localDataSource: getIt<LocalDataSource>(),
      ));

  // Settings Repository
  // Settings Repository
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
        sharedPreferences: getIt(),
        nativeBackupService: getIt(),
        databaseHelper: DatabaseHelper.instance,
        logger: getIt(),
      ));

  // Offline Content Manager (depends on UserDataRepository)
  getIt
      .registerLazySingleton<OfflineContentManager>(() => OfflineContentManager(
            userDataRepository: getIt<UserDataRepository>(),
            logger: getIt<Logger>(),
          ));

  // Export Service (depends on UserDataRepository, OfflineContentManager)
  getIt.registerLazySingleton<ExportService>(() => ExportService(
        userDataRepository: getIt<UserDataRepository>(),
        offlineContentManager: getIt<OfflineContentManager>(),
        logger: getIt<Logger>(),
      ));

  // Crotpedia Feature Repository
  getIt.registerLazySingleton<CrotpediaFeatureRepository>(
      () => CrotpediaFeatureRepositoryImpl(
            crotpediaSource: getIt<CrotpediaSource>(),
            scraper: getIt<CrotpediaScraper>(),
            doujinListDao: getIt<DoujinListDao>(),
            sharedPreferences: getIt<SharedPreferences>(), // INJECTED
            logger: getIt<Logger>(),
          ));
}

/// Setup use cases
void _setupUseCases() {
  // Settings Use Cases
  getIt.registerLazySingleton<GetUserPreferencesUseCase>(
      () => GetUserPreferencesUseCase(getIt<SettingsRepository>()));
  getIt.registerLazySingleton<SaveUserPreferencesUseCase>(
      () => SaveUserPreferencesUseCase(getIt<SettingsRepository>()));

  // Crotpedia Use Cases
  getIt.registerLazySingleton<GetGenreListUseCase>(
      () => GetGenreListUseCase(getIt<CrotpediaFeatureRepository>()));
  getIt.registerLazySingleton<GetDoujinListUseCase>(
      () => GetDoujinListUseCase(getIt<CrotpediaFeatureRepository>()));
  getIt.registerLazySingleton<GetRequestListUseCase>(
      () => GetRequestListUseCase(getIt<CrotpediaFeatureRepository>()));

  // Content Use Cases
  getIt.registerLazySingleton<GetContentListUseCase>(
      () => GetContentListUseCase(getIt()));
  getIt.registerLazySingleton<GetContentDetailUseCase>(
      () => GetContentDetailUseCase(getIt()));
  getIt.registerLazySingleton<SearchContentUseCase>(
      () => SearchContentUseCase(getIt()));
  getIt.registerLazySingleton<GetRandomContentUseCase>(
      () => GetRandomContentUseCase(getIt()));
  getIt.registerLazySingleton<GetChapterImagesUseCase>(
      () => GetChapterImagesUseCase(getIt()));
  getIt.registerLazySingleton<GetCommentsUseCase>(
      () => GetCommentsUseCase(getIt()));

  // Favorites Use Cases
  getIt.registerLazySingleton<AddToFavoritesUseCase>(
      () => AddToFavoritesUseCase(getIt()));
  getIt.registerLazySingleton<RemoveFromFavoritesUseCase>(
      () => RemoveFromFavoritesUseCase(getIt()));
  getIt.registerLazySingleton<GetFavoritesUseCase>(
      () => GetFavoritesUseCase(getIt()));

  // Download Use Cases
  getIt.registerLazySingleton<DownloadContentUseCase>(
      () => DownloadContentUseCase(
            getIt<UserDataRepository>(),
            getIt<NativeDownloadService>(),
            getIt<PdfService>(),
            logger: getIt<Logger>(),
          ));
  getIt.registerLazySingleton<GetDownloadStatusUseCase>(
      () => GetDownloadStatusUseCase(getIt()));
  getIt.registerLazySingleton<GetAllDownloadsUseCase>(
      () => GetAllDownloadsUseCase(getIt()));

  // History Use Cases
  getIt.registerLazySingleton<AddToHistoryUseCase>(
      () => AddToHistoryUseCase(getIt()));
  getIt.registerLazySingleton<GetHistoryUseCase>(
      () => GetHistoryUseCase(getIt()));
  getIt.registerLazySingleton<ClearHistoryUseCase>(
      () => ClearHistoryUseCase(getIt()));
  getIt.registerLazySingleton<RemoveHistoryItemUseCase>(
      () => RemoveHistoryItemUseCase(getIt()));
  getIt.registerLazySingleton<GetHistoryCountUseCase>(
      () => GetHistoryCountUseCase(getIt()));
}

/// Setup BLoCs
void _setupBlocs() {
  // Splash BLoC
  getIt.registerFactory<SplashBloc>(() => SplashBloc(
        remoteConfigService: getIt<RemoteConfigService>(),
        remoteDataSource: getIt<RemoteDataSource>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
        connectivity: getIt<Connectivity>(),
        tagDataManager: getIt<TagDataManager>(),
        contentSourceRegistry: getIt<ContentSourceRegistry>(),
      ));

  // Home BLoC
  getIt.registerFactory<HomeBloc>(() => HomeBloc());

  // Register ContentBloc as singleton to preserve state across widget rebuilds
  // IMPORTANT: Changed from registerFactory to registerLazySingleton
  // to fix pagination retry bug where state was reset on widget rebuild
  getIt.registerLazySingleton<ContentBloc>(() => ContentBloc(
        getContentListUseCase: getIt<GetContentListUseCase>(),
        searchContentUseCase: getIt<SearchContentUseCase>(),
        getRandomContentUseCase: getIt<GetRandomContentUseCase>(),
        contentRepository: getIt<ContentRepository>(),
        logger: getIt<Logger>(),
      ));

  // Register SearchBloc
  getIt.registerFactory<SearchBloc>(() => SearchBloc(
        searchContentUseCase: getIt<SearchContentUseCase>(),
        localDataSource: getIt<LocalDataSource>(),
        tagDataSource: getIt<TagDataSource>(),
        logger: getIt<Logger>(),
      ));

  // Register DownloadBloc
  getIt.registerLazySingleton<DownloadBloc>(() => DownloadBloc(
        downloadContentUseCase: getIt<DownloadContentUseCase>(),
        getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
        getChapterImagesUseCase: getIt<GetChapterImagesUseCase>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
        connectivity: getIt<Connectivity>(),
        notificationService: getIt<NotificationService>(),
        pdfConversionService: getIt<PdfConversionService>(),
        pdfConversionQueueManager: getIt<PdfConversionQueueManager>(),
        remoteConfigService: getIt<RemoteConfigService>(),
        appLocalizations: null, // Initialized during main setup
        crotpediaAuthManager:
            getIt<CrotpediaAuthManager>(), // NEW: Inject for cookie extraction
      ));

  // Register other BLoCs when implemented
  // getIt.registerFactory<FavoriteBloc>(() => FavoriteBloc(getIt()));
  // getIt.registerFactory<SettingsBloc>(() => SettingsBloc(getIt()));
}

/// Setup Cubits (Simple State Management)
void _setupCubits() {
  // NetworkCubit - App-wide connectivity monitoring
  getIt.registerLazySingleton<NetworkCubit>(() => NetworkCubit(
        connectivity: getIt<Connectivity>(),
        logger: getIt<Logger>(),
      ));

  // SourceCubit - Content Source Management
  getIt.registerFactory<SourceCubit>(() => SourceCubit(
        registry: getIt<ContentSourceRegistry>(),
        prefs: getIt<SharedPreferences>(),
        logger: getIt<Logger>(),
      ));

  // SettingsCubit - App-wide settings management
  getIt.registerLazySingleton<SettingsCubit>(() => SettingsCubit(
        preferencesService: getIt<PreferencesService>(),
        logger: getIt<Logger>(),
      ));

  // ThemeCubit - App-wide theme management
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(
        settingsCubit: getIt<SettingsCubit>(),
        logger: getIt<Logger>(),
      ));

  // DetailCubit - Content detail management
  getIt.registerFactory<DetailCubit>(() => DetailCubit(
        getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
        addToFavoritesUseCase: getIt<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: getIt<RemoveFromFavoritesUseCase>(),
        userDataRepository: getIt<UserDataRepository>(),
        imageMetadataService: getIt<ImageMetadataService>(),
        contentRepository: getIt<ContentRepository>(),
        contentSourceRegistry: getIt<ContentSourceRegistry>(),
        offlineContentManager: getIt<OfflineContentManager>(),
        logger: getIt<Logger>(),
      ));

  // CrotpediaAuthCubit - Crotpedia login management
  getIt.registerLazySingleton<CrotpediaAuthCubit>(() => CrotpediaAuthCubit(
        source: getIt<CrotpediaSource>(),
        logger: getIt<Logger>(),
      ));

  // CrotpediaFeatureCubit - Crotpedia features (Genre, Doujin, Request lists)
  getIt.registerFactory<CrotpediaFeatureCubit>(() => CrotpediaFeatureCubit(
        getGenreListUseCase: getIt<GetGenreListUseCase>(),
        getDoujinListUseCase: getIt<GetDoujinListUseCase>(),
        getRequestListUseCase: getIt<GetRequestListUseCase>(),
        logger: getIt<Logger>(),
      ));

  // FilterDataCubit - Filter data screen management
  getIt.registerFactory<FilterDataCubit>(() => FilterDataCubit(
        tagDataManager: getIt<TagDataManager>(),
        logger: getIt<Logger>(),
      ));

  // ReaderCubit - Reader screen management
  getIt.registerFactory<ReaderCubit>(() => ReaderCubit(
        getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
        getChapterImagesUseCase: getIt<GetChapterImagesUseCase>(),
        addToHistoryUseCase: getIt<AddToHistoryUseCase>(),
        readerSettingsRepository: getIt<ReaderSettingsRepository>(),
        readerRepository: getIt<ReaderRepository>(),
        offlineContentManager: getIt<OfflineContentManager>(),
        networkCubit: getIt<NetworkCubit>(),
        imageMetadataService: getIt<ImageMetadataService>(),
      ));

  // OfflineSearchCubit - Offline content search (Singleton to persist state)
  getIt.registerLazySingleton<OfflineSearchCubit>(() => OfflineSearchCubit(
        offlineContentManager: getIt<OfflineContentManager>(),
        userDataRepository: getIt<UserDataRepository>(),
        prefs: getIt<SharedPreferences>(),
        logger: getIt<Logger>(),
      ));

  // RandomGalleryCubit - Random gallery management
  getIt.registerFactory<RandomGalleryCubit>(() => RandomGalleryCubit(
        getRandomContentUseCase: getIt<GetRandomContentUseCase>(),
        addToFavoritesUseCase: getIt<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: getIt<RemoveFromFavoritesUseCase>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
      ));

  // FavoriteCubit - Favorites management
  getIt.registerFactory<FavoriteCubit>(() => FavoriteCubit(
        addToFavoritesUseCase: getIt<AddToFavoritesUseCase>(),
        getFavoritesUseCase: getIt<GetFavoritesUseCase>(),
        removeFromFavoritesUseCase: getIt<RemoveFromFavoritesUseCase>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
      ));

  // HistoryCubit - History management (using static factory)
  getIt.registerFactory<HistoryCubit>(() => HistoryCubitFactory.create());

  // UpdateCubit - App update checking
  getIt.registerFactory<UpdateCubit>(() => UpdateCubit(
        updateService: getIt<UpdateService>(),
        logger: getIt<Logger>(),
      ));

  // CommentsCubit
  getIt.registerFactory<CommentsCubit>(() => CommentsCubit(
        getIt<GetCommentsUseCase>(),
      ));
}

/// Clean up all registered dependencies
void cleanupLocator() {
  getIt.reset();
}
