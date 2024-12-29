import 'package:get_it/get_it.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';

final getIt = GetIt.instance;
void setupLocator() {
  setupBlocCubit();
  setupRepository();
  setupService();
}

void setupBlocCubit() {
  getIt.registerLazySingleton<SplashBloc>(() => SplashBloc());
}

void setupRouter() {}

void setupRepository() {}

void setupService() {}
