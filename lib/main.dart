import 'package:flutter/material.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Nhentai Flutter App",
      debugShowCheckedModeBanner: true,
      routerConfig: AppRouter.router,
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
    );
  }
}
