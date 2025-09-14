import 'package:flutter/services.dart';

class AppDisguiseService {
  static const platform = MethodChannel('app_disguise');

  static Future<void> setDisguiseMode(String mode) async {
    try {
      print('AppDisguiseService: Setting disguise mode to: $mode');
      final result = await platform.invokeMethod('setDisguiseMode', {'mode': mode});
      print('AppDisguiseService: Successfully set disguise mode to: $mode');
      return result;
    } catch (e) {
      print('AppDisguiseService: Error setting disguise mode: $e');
      rethrow;
    }
  }

  static Future<String> getCurrentDisguiseMode() async {
    try {
      print('AppDisguiseService: Getting current disguise mode');
      final result = await platform.invokeMethod('getCurrentDisguiseMode');
      print('AppDisguiseService: Current disguise mode: $result');
      return result ?? 'default';
    } catch (e) {
      print('AppDisguiseService: Error getting current disguise mode: $e');
      return 'default';
    }
  }
}