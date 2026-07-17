import 'package:flutter/services.dart';

class AppDisguiseService {
  static const platform = MethodChannel('app_disguise');

  static Future<void> setDisguiseMode(String mode) async {
    try {
      final result =
          await platform.invokeMethod('setDisguiseMode', {'mode': mode});
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> getCurrentDisguiseMode() async {
    try {
      final result = await platform.invokeMethod('getCurrentDisguiseMode');
      return result ?? 'default';
    } catch (e) {
      return 'default';
    }
  }
}
