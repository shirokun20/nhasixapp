import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';

// BLoCs (Complex State Management)
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';

// Cubits (Simple State Management)
import 'package:nhasixapp/presentation/cubits/cubits.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_cubit.dart';
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
    BlocProvider<ContentBloc>(
      create: (context) => getIt<ContentBloc>(),
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
    ), // SettingsCubit for settings screen

    BlocProvider<ThemeCubit>(
      create: (context) => getIt<ThemeCubit>(),
    ), // ThemeCubit for reactive theme management

    BlocProvider<DetailCubit>(
      create: (context) => getIt<DetailCubit>(),
    ),

    BlocProvider<FilterDataCubit>(
      create: (context) => getIt<FilterDataCubit>(),
    ),

    BlocProvider<ReaderCubit>(
      create: (context) => getIt<ReaderCubit>(),
    ),

    BlocProvider<RandomGalleryCubit>(
      create: (context) => getIt<RandomGalleryCubit>(),
    ),

    // Note: DetailCubit, ReaderCubit, FavoriteCubit akan di-provide secara lokal
    // di screen masing-masing karena mereka screen-specific, bukan app-wide
  ];
}
