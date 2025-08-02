import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:nhasixapp/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nHentai Crawler',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String result = 'Press the button to fetch nhentai.net';

  Future<void> fetchNhentai() async {
    const url = 'https://nhentai.net';
    final dio = getIt<Dio>();

    try {
      final response = await dio.get(url);

      setState(() {
        result = '✅ Status: ${response.statusCode}\n'
            'Content-Type: ${response.headers.value('content-type')}\n'
            'Length: ${response.data.toString().length} characters';
      });
    } catch (e) {
      setState(() {
        result = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nHentai Fetch Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: fetchNhentai,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Fetch nhentai.net'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
