import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';

// BLoCs (Complex State Management)
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
// import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart'; // Will be added later

// Cubits (Simple State Management)
// import 'package:nhasixapp/presentation/cubits/network/network_cubit.dart'; // Will be added later
// import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart'; // Will be added later
// import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart'; // Will be added later

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

    // Simple State Management (Cubits) - Will be uncommented as implemented
    // BlocProvider<NetworkCubit>(
    //   create: (context) => getIt<NetworkCubit>(),
    // ),
    // BlocProvider<SettingsCubit>(
    //   create: (context) => getIt<SettingsCubit>(),
    // ),

    // Note: DetailCubit, ReaderCubit, FavoriteCubit akan di-provide secara lokal
    // di screen masing-masing karena mereka screen-specific, bukan app-wide
  ];
}
