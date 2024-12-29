import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.primaryColor,
      appBar: AppBar(
        title: const Text('Main Screen'),
      ),
    );
  }
}
