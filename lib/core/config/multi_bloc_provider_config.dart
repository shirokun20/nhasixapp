import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';

class MultiBlocProviderConfig {
  static List<BlocProvider> data = [
    BlocProvider<SplashBloc>(
      create: (context) => getIt<SplashBloc>(),
    ),
    BlocProvider<HomeBloc>(
      create: (context) => getIt<HomeBloc>(),
    ),
  ];
}
