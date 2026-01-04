import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Persistent storage for cookies and login state
class CrotpediaCookieStore implements Storage {
  static const String _cookieFileName = 'crotpedia_cookies.json';
  static const String _loginStateFileName = 'crotpedia_login_state.json';

  String? _storagePath;

  // ============ Cookie Storage (implements Storage interface) ============

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    _storagePath = await _getStoragePath();
  }

  @override
  Future<void> write(String key, String value) async {
    final file = File('$_storagePath/$_cookieFileName');

    Map<String, dynamic> data = {};
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        try {
          data = json.decode(content);
        } catch (_) {
          data = {};
        }
      }
    }

    data[key] = value;
    await file.writeAsString(json.encode(data));
  }

  @override
  Future<String?> read(String key) async {
    final file = File('$_storagePath/$_cookieFileName');

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        try {
          final data = json.decode(content);
          return data[key];
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  @override
  Future<void> delete(String key) async {
    final file = File('$_storagePath/$_cookieFileName');

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        try {
          final data = json.decode(content);
          data.remove(key);
          await file.writeAsString(json.encode(data));
        } catch (_) {
          // Ignore errors
        }
      }
    }
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    final file = File('$_storagePath/$_cookieFileName');

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        try {
          final data = json.decode(content);
          for (final key in keys) {
            data.remove(key);
          }
          await file.writeAsString(json.encode(data));
        } catch (_) {
          // Ignore errors
        }
      }
    }
  }

  // ============ Login State Storage ============

  /// Save login state (username, isLoggedIn, loginTime)
  Future<void> saveLoginState(Map<String, dynamic> state) async {
    final path = await _getStoragePath();
    final file = File('$path/$_loginStateFileName');
    await file.writeAsString(json.encode(state));
  }

  /// Load login state
  Future<Map<String, dynamic>?> loadLoginState() async {
    try {
      final path = await _getStoragePath();
      final file = File('$path/$_loginStateFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          return json.decode(content);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Clear login state
  Future<void> clearLoginState() async {
    final path = await _getStoragePath();
    final file = File('$path/$_loginStateFileName');

    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============ Private Methods ============

  Future<String> _getStoragePath() async {
    if (_storagePath != null) return _storagePath!;

    final directory = await getApplicationDocumentsDirectory();
    final cookieDir = Directory('${directory.path}/crotpedia');

    if (!await cookieDir.exists()) {
      await cookieDir.create(recursive: true);
    }

    _storagePath = cookieDir.path;
    return _storagePath!;
  }
}
