import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_cubit.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    hide ImageCacheManager;

// Core Network
import 'package:nhasixapp/core/network/http_client_manager.dart';

// Core Utils
import 'package:nhasixapp/core/utils/image_cache_manager.dart';
import 'package:nhasixapp/core/utils/image_preloader.dart';
import 'package:nhasixapp/core/utils/image_optimizer.dart';
import 'package:nhasixapp/core/utils/content_image_preloader.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart';

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

// Cubits
import 'package:nhasixapp/presentation/cubits/cubits.dart';

// Repositories
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/data/repositories/content_repository_impl.dart';
import 'package:nhasixapp/data/repositories/user_data_repository_impl.dart';
import 'package:nhasixapp/data/repositories/reader_settings_repository_impl.dart';

// Use Cases
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/history/add_to_history_usecase.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> setupLocator() async {
  await _setupExternalDependencies();
  _setupCore();
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

  // Image Cache Manager
  getIt.registerLazySingleton<ImageCacheManager>(
      () => ImageCacheManager.instance);

  // Image Preloader
  getIt.registerLazySingleton<ImagePreloader>(() => ImagePreloader.instance);

  // Image Optimizer
  getIt.registerLazySingleton<ImageOptimizer>(() => ImageOptimizer.instance);

  // Content Image Preloader
  getIt.registerLazySingleton<ContentImagePreloader>(
      () => ContentImagePreloader.instance);

  // Tag Data Manager
  getIt.registerLazySingleton<TagDataManager>(
      () => TagDataManager(logger: getIt<Logger>()));
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
  // Content Repository
  getIt.registerLazySingleton<ContentRepository>(() => ContentRepositoryImpl(
        remoteDataSource: getIt<RemoteDataSource>(),
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

  // Settings Repository
  // getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
  //   sharedPreferences: getIt(),
  //   logger: getIt(),
  // ));
}

/// Setup use cases
void _setupUseCases() {
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
  // getIt.registerLazySingleton<AddToFavoritesUseCase>(() => AddToFavoritesUseCase(getIt()));
  // getIt.registerLazySingleton<RemoveFromFavoritesUseCase>(() => RemoveFromFavoritesUseCase(getIt()));
  // getIt.registerLazySingleton<GetFavoritesUseCase>(() => GetFavoritesUseCase(getIt()));

  // Download Use Cases
  // getIt.registerLazySingleton<DownloadContentUseCase>(() => DownloadContentUseCase(getIt()));
  // getIt.registerLazySingleton<GetDownloadStatusUseCase>(() => GetDownloadStatusUseCase(getIt()));

  // History Use Cases
  getIt.registerLazySingleton<AddToHistoryUseCase>(
      () => AddToHistoryUseCase(getIt()));
}

/// Setup BLoCs
void _setupBlocs() {
  // Splash BLoC
  getIt.registerFactory<SplashBloc>(() => SplashBloc(
        remoteDataSource: getIt<RemoteDataSource>(),
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
        contentImagePreloader: getIt<ContentImagePreloader>(),
        logger: getIt<Logger>(),
      ));

  // Register SearchBloc
  getIt.registerFactory<SearchBloc>(() => SearchBloc(
        searchContentUseCase: getIt<SearchContentUseCase>(),
        localDataSource: getIt<LocalDataSource>(),
        tagDataSource: getIt<TagDataSource>(),
        logger: getIt<Logger>(),
      ));

  // TODO: Register other BLoCs when implemented
  // getIt.registerFactory<FavoriteBloc>(() => FavoriteBloc(getIt()));
  // getIt.registerFactory<DownloadBloc>(() => DownloadBloc(getIt()));
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
        sharedPreferences: getIt<SharedPreferences>(),
        logger: getIt<Logger>(),
      ));

  // DetailCubit - Content detail management
  getIt.registerFactory<DetailCubit>(() => DetailCubit(
        getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
        contentRepository: getIt<ContentRepository>(),
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
      ));

  // Note: FavoriteCubit will be implemented later
  // Same pattern will be used for other screen-specific cubits
}

/// Clean up all registered dependencies
void cleanupLocator() {
  getIt.reset();
}
