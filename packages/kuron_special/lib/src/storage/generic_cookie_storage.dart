import 'dart:io' show Directory, File;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// A reusable [Storage] implementation for [PersistCookieJar] that stores
/// cookies under `{appDocsDir}/{sourceId}/` on disk.
///
/// This replaces per-source cookie stores (e.g. CrotpediaCookieStore) with
/// a single generic implementation usable by any provider.
class GenericCookieStorage implements Storage {
  final String sourceId;
  String? _storagePath;

  GenericCookieStorage(this.sourceId);

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    _storagePath = await _getStoragePath();
  }

  @override
  Future<String?> read(String key) async {
    final path = await _getStoragePath();
    final file = File('$path/$key');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    final path = await _getStoragePath();
    final file = File('$path/$key');
    await file.writeAsString(value);
  }

  @override
  Future<void> delete(String key) async {
    final path = await _getStoragePath();
    final file = File('$path/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }

  Future<String> _getStoragePath() async {
    if (_storagePath != null) return _storagePath!;
    final directory = await getApplicationDocumentsDirectory();
    final cookieDir = Directory('${directory.path}/$sourceId');
    if (!await cookieDir.exists()) {
      await cookieDir.create(recursive: true);
    }
    _storagePath = cookieDir.path;
    return _storagePath!;
  }
}
