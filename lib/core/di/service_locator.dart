import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

    // Add interceptors for logging and error handling
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => getIt<Logger>().d(obj),
    ));

    return dio;
  });

  // Cache Manager
  getIt.registerLazySingleton<CacheManager>(() => DefaultCacheManager());
}

/// Setup data sources (Remote and Local)
void _setupDataSources() {
  // TODO: Register data sources when implemented
  // getIt.registerLazySingleton<RemoteDataSource>(() => RemoteDataSourceImpl(getIt()));
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
  getIt.registerFactory<SplashBloc>(() => SplashBloc());

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
