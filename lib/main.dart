import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/config/multi_bloc_provider_config.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: MultiBlocProviderConfig.data,
      child: MaterialApp.router(
        title: "Nhentai Flutter App",
        debugShowCheckedModeBanner: true,
        routerConfig: AppRouter.router,
        theme: ThemeData(
          primaryColor: ColorsConst.primaryColor,
        ),
      ),
    );
  }
}
