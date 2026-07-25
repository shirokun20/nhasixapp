import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
// BLoCs (Complex State Management)
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';

// Cubits (Simple State Management)
import 'package:nhasixapp/presentation/cubits/cubits.dart';
import 'package:nhasixapp/presentation/cubits/theme/theme_cubit.dart';

class MultiBlocProviderConfig {
  static List<BlocProvider> data = [
    // Complex State Management (BLoCs)
    BlocProvider<SplashBloc>(
      create: (context) => getIt<SplashBloc>(),
    ),
    BlocProvider<HomeBloc>(
      create: (context) => getIt<HomeBloc>(),
    ),
    BlocProvider<SearchBloc>(
      create: (context) => getIt<SearchBloc>(),
    ),
    BlocProvider<DownloadBloc>(
      create: (context) => getIt<DownloadBloc>(),
    ),

    // Simple State Management (Cubits)
    BlocProvider<NetworkCubit>(
      create: (context) => getIt<NetworkCubit>(),
    ),
    BlocProvider<SettingsCubit>(
      create: (context) => getIt<SettingsCubit>(),
    ),

    BlocProvider<ThemeCubit>(
      create: (context) => getIt<ThemeCubit>(),
    ),

    BlocProvider<SourceCubit>(
      create: (context) => getIt<SourceCubit>(),
    ),

    BlocProvider<DetailCubit>(
      create: (context) => getIt<DetailCubit>(),
    ),

    BlocProvider<FilterDataCubit>(
      create: (context) => getIt<FilterDataCubit>(),
    ),

    BlocProvider<CrotpediaAuthCubit>(
      create: (context) => getIt<CrotpediaAuthCubit>(),
    ),

    // AppLockCubit for app lock gate + settings
    BlocProvider<AppLockCubit>(
      create: (context) => getIt<AppLockCubit>(),
    ),

    // Note: DetailCubit, ReaderCubit, FavoriteCubit akan di-provide secara lokal
    // di screen masing-masing karena mereka screen-specific, bukan app-wide
  ];
}
