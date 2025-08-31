import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/config/multi_bloc_provider_config.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/cubits/theme/theme_cubit.dart';
import 'package:nhasixapp/presentation/widgets/platform_not_supported_dialog.dart';
import 'package:nhasixapp/services/analytics_service.dart';
import 'package:nhasixapp/services/history_cleanup_service.dart';
import 'package:nhasixapp/utils/performance_monitor.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  
  // Initialize Performance Monitoring
  await PerformanceMonitor.initialize();
  
  // Initialize Analytics Service
  final analyticsService = getIt<AnalyticsService>();
  await analyticsService.initialize();
  
  // Initialize History Cleanup Service
  final historyCleanupService = getIt<HistoryCleanupService>();
  await historyCleanupService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: MultiBlocProviderConfig.data,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          debugPrint('🎨 MaterialApp rebuilt with theme: ${themeState.currentTheme}, mode: ${themeState.themeMode}, brightness: ${themeState.themeData.brightness}');
          return MaterialApp.router(
            title: "Nhentai Flutter App",
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            theme: themeState.themeData,
            themeMode: themeState.themeMode,
            builder: (context, child) {
              // Show platform warning for non-Android platforms
              if (kIsWeb || (!kIsWeb && !Platform.isAndroid)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  PlatformNotSupportedDialog.show(context);
                });
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
