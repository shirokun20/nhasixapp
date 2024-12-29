import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/pages/main/main_screen.dart';
import 'package:nhasixapp/presentation/pages/splash/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoute.defaultRoute,
    routes: [
      GoRoute(
        path: AppRoute.defaultRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.main,
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
