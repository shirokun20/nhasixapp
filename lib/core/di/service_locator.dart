import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
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

// Core Network
import 'package:nhasixapp/core/network/http_client_manager.dart';

// Core Utils
import 'package:nhasixapp/core/utils/tag_data_manager.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';

// Data Sources
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/anti_detection.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';
import 'package:nhasixapp/data/datasources/local/tag_data_source.dart';

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

// Repositories
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/data/repositories/content_repository_impl.dart';
import 'package:nhasixapp/data/repositories/user_data_repository_impl.dart';
import 'package:nhasixapp/data/repositories/reader_settings_repository_impl.dart';
import 'package:nhasixapp/data/repositories/reader_repository_impl.dart';

// Use Cases
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/favorites/favorites_usecases.dart';
import 'package:nhasixapp/domain/usecases/downloads/downloads_usecases.dart';
import 'package:nhasixapp/domain/usecases/history/add_to_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/get_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/clear_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/remove_history_item_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/get_history_count_usecase.dart';
import 'package:nhasixapp/domain/usecases/settings/get_user_preferences_usecase.dart';
import 'package:nhasixapp/domain/usecases/settings/save_user_preferences_usecase.dart';

// Services
import 'package:nhasixapp/services/download_service.dart';
import 'package:nhasixapp/services/notification_service.dart';
import 'package:nhasixapp/services/pdf_service.dart';
import 'package:nhasixapp/services/pdf_conversion_service.dart';
import 'package:nhasixapp/services/history_cleanup_service.dart';
import 'package:nhasixapp/services/preferences_service.dart';
import 'package:nhasixapp/services/analytics_service.dart';
import 'package:nhasixapp/services/detail_cache_service.dart';
import 'package:nhasixapp/services/request_deduplication_service.dart';
import 'package:nhasixapp/services/app_update_service.dart';
import 'package:nhasixapp/services/image_cache_service.dart';
import 'package:nhasixapp/services/image_metadata_service.dart';
import 'package:nhasixapp/services/export_service.dart';
import 'package:nhasixapp/services/cache/cache_manager.dart' as multi_cache;
import 'package:nhasixapp/domain/entities/content.dart';
import 'package:nhasixapp/domain/entities/tag.dart';

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
  // Logger
  getIt.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      ));

  // HTTP Client (Dio) - Using singleton manager to prevent disposal issues
  getIt.registerLazySingleton<Dio>(() {
    return HttpClientManager.initializeHttpClient(logger: getIt<Logger>());
  });

  // Cache Manager
  getIt.registerLazySingleton<CacheManager>(() => DefaultCacheManager());

  // Tag Data Manager
  getIt.registerLazySingleton<TagDataManager>(
      () => TagDataManager(logger: getIt<Logger>()));
}

/// Setup services
void _setupServices() {
  // Notification Service
  getIt.registerLazySingleton<NotificationService>(
      () => NotificationService(logger: getIt<Logger>()));

  // PDF Service
  getIt.registerLazySingleton<PdfService>(
      () => PdfService(logger: getIt<Logger>()));

  // PDF Conversion Service - High-level orchestration service for background PDF processing
  getIt.registerLazySingleton<PdfConversionService>(() => PdfConversionService(
        pdfService: getIt<PdfService>(),
        notificationService: getIt<NotificationService>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
      ));

  // Download Service
  getIt.registerLazySingleton<DownloadService>(() => DownloadService(
        httpClient: getIt<Dio>(),
        notificationService: getIt<NotificationService>(),
        logger: getIt<Logger>(),
      ));

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

  // Image Metadata Service - Handles image metadata generation and validation
  getIt.registerLazySingleton<ImageMetadataService>(() => ImageMetadataService(
        getIt<OfflineContentManager>(),
        getIt<Logger>(),
      ));

  // Multi-layer Cache Manager for Content - Memory + Disk caching
  getIt.registerLazySingleton<multi_cache.CacheManager<Content>>(
    () => multi_cache.CacheManager<Content>.standard(
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
      ));

  // Remote Data Source
  getIt.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(
        httpClient: getIt<Dio>(),
        scraper: getIt<NhentaiScraper>(),
        cloudflareBypass: getIt<CloudflareBypassNoWebView>(),
        antiDetection: getIt<AntiDetection>(),
        logger: getIt<Logger>(),
      ));

  // Database Helper
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // Local Data Source
  getIt.registerLazySingleton<LocalDataSource>(
      () => LocalDataSource(getIt<DatabaseHelper>()));

  // Tag Data Source
  getIt.registerLazySingleton<TagDataSource>(
      () => TagDataSource(logger: getIt<Logger>()));
}

/// Setup repository implementations
void _setupRepositories() {
  // Content Repository with multi-layer cache integration
  getIt.registerLazySingleton<ContentRepository>(() => ContentRepositoryImpl(
        remoteDataSource: getIt<RemoteDataSource>(),
        detailCacheService: getIt<DetailCacheService>(),
        requestDeduplicationService: getIt<RequestDeduplicationService>(),
        contentCacheManager: getIt<multi_cache.CacheManager<Content>>(),
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
  // getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
  //   sharedPreferences: getIt(),
  //   logger: getIt(),
  // ));

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
}

/// Setup use cases
void _setupUseCases() {
  // Settings Use Cases
  getIt.registerLazySingleton<GetUserPreferencesUseCase>(
      () => GetUserPreferencesUseCase(getIt<SettingsRepository>()));
  getIt.registerLazySingleton<SaveUserPreferencesUseCase>(
      () => SaveUserPreferencesUseCase(getIt<SettingsRepository>()));
  // Content Use Cases
  getIt.registerLazySingleton<GetContentListUseCase>(
      () => GetContentListUseCase(getIt()));
  getIt.registerLazySingleton<GetContentDetailUseCase>(
      () => GetContentDetailUseCase(getIt()));
  getIt.registerLazySingleton<SearchContentUseCase>(
      () => SearchContentUseCase(getIt()));
  getIt.registerLazySingleton<GetRandomContentUseCase>(
      () => GetRandomContentUseCase(getIt()));

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
            getIt<DownloadService>(),
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
        remoteDataSource: getIt<RemoteDataSource>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
        connectivity: getIt<Connectivity>(),
      ));

  // Home BLoC
  getIt.registerFactory<HomeBloc>(() => HomeBloc());

  // Register ContentBloc when repositories and use cases are implemented
  getIt.registerFactory<ContentBloc>(() => ContentBloc(
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
  getIt.registerFactory<DownloadBloc>(() => DownloadBloc(
        downloadContentUseCase: getIt<DownloadContentUseCase>(),
        getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
        userDataRepository: getIt<UserDataRepository>(),
        logger: getIt<Logger>(),
        connectivity: getIt<Connectivity>(),
        notificationService: getIt<NotificationService>(),
        pdfConversionService: getIt<PdfConversionService>(),
        appLocalizations:
            null, // Will be provided via context in MultiBlocProviderConfig
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
}

/// Clean up all registered dependencies
void cleanupLocator() {
  getIt.reset();
}
