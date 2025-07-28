import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Data Sources
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/anti_detection.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';

// BLoCs
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> setupLocator() async {
  await _setupExternalDependencies();
  _setupCore();
  _setupDataSources();
  _setupRepositories();
  _setupUseCases();
  _setupBlocs();
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

  // HTTP Client (Dio)
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    dio.options.followRedirects = true;
    dio.options.maxRedirects = 5;

    // Default headers to mimic real browser
    dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
    };

    // Add interceptors for logging and error handling
    dio.interceptors.add(LogInterceptor(
      requestBody: false, // Don't log request body for privacy
      responseBody: false, // Don't log response body for performance
      logPrint: (obj) => getIt<Logger>().d(obj),
    ));

    return dio;
  });

  // Cache Manager
  getIt.registerLazySingleton<CacheManager>(() => DefaultCacheManager());
}

/// Setup data sources (Remote and Local)
void _setupDataSources() {
  // Anti-Detection
  getIt.registerLazySingleton<AntiDetection>(() => AntiDetection(
        logger: getIt<Logger>(),
      ));

  // Cloudflare Bypass
  getIt.registerLazySingleton<CloudflareBypass>(() => CloudflareBypass(
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
        cloudflareBypass: getIt<CloudflareBypass>(),
        antiDetection: getIt<AntiDetection>(),
        logger: getIt<Logger>(),
      ));

  // TODO: Register local data source when implemented
  // getIt.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(getIt()));
}

/// Setup repository implementations
void _setupRepositories() {
  // TODO: Register repositories when implemented
  // Content Repository
  // getIt.registerLazySingleton<ContentRepository>(() => ContentRepositoryImpl(
  //   remoteDataSource: getIt(),
  //   localDataSource: getIt(),
  //   logger: getIt(),
  // ));

  // User Data Repository
  // getIt.registerLazySingleton<UserDataRepository>(() => UserDataRepositoryImpl(
  //   localDataSource: getIt(),
  //   logger: getIt(),
  // ));

  // Settings Repository
  // getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
  //   sharedPreferences: getIt(),
  //   logger: getIt(),
  // ));
}

/// Setup use cases
void _setupUseCases() {
  // TODO: Register use cases when implemented

  // Content Use Cases
  // getIt.registerLazySingleton<GetContentListUseCase>(() => GetContentListUseCase(getIt()));
  // getIt.registerLazySingleton<GetContentDetailUseCase>(() => GetContentDetailUseCase(getIt()));
  // getIt.registerLazySingleton<SearchContentUseCase>(() => SearchContentUseCase(getIt()));
  // getIt.registerLazySingleton<GetRandomContentUseCase>(() => GetRandomContentUseCase(getIt()));

  // Favorites Use Cases
  // getIt.registerLazySingleton<AddToFavoritesUseCase>(() => AddToFavoritesUseCase(getIt()));
  // getIt.registerLazySingleton<RemoveFromFavoritesUseCase>(() => RemoveFromFavoritesUseCase(getIt()));
  // getIt.registerLazySingleton<GetFavoritesUseCase>(() => GetFavoritesUseCase(getIt()));

  // Download Use Cases
  // getIt.registerLazySingleton<DownloadContentUseCase>(() => DownloadContentUseCase(getIt()));
  // getIt.registerLazySingleton<GetDownloadStatusUseCase>(() => GetDownloadStatusUseCase(getIt()));

  // History Use Cases
  // getIt.registerLazySingleton<AddToHistoryUseCase>(() => AddToHistoryUseCase(getIt()));
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

  // TODO: Register other BLoCs when implemented
  // getIt.registerFactory<ContentBloc>(() => ContentBloc(getIt()));
  // getIt.registerFactory<SearchBloc>(() => SearchBloc(getIt()));
  // getIt.registerFactory<FavoriteBloc>(() => FavoriteBloc(getIt()));
  // getIt.registerFactory<DownloadBloc>(() => DownloadBloc(getIt()));
  // getIt.registerFactory<SettingsBloc>(() => SettingsBloc(getIt()));
}

/// Clean up all registered dependencies
void cleanupLocator() {
  getIt.reset();
}
