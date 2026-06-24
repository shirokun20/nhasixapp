import 'package:kuron_native/kuron_native.dart';
import 'dart:typed_data';

/// Native service for importing ZIP files containing doujin/manga content
///
/// This service provides native Android file pickers for selecting ZIP files
/// and returns content URIs for further processing in Dart.
class NativeZipImportService {
  /// Launches the native file picker to select a ZIP file.
  ///
  /// Returns the content URI of the selected ZIP file, or null if cancelled.
  Future<String?> pickZipFile() async {
    try {
      final result = await KuronNative.instance.pickZipFile();
      return result;
    } catch (e) {
      throw Exception('Failed to pick ZIP file: $e');
    }
  }

  /// Launches the native file picker to select multiple ZIP files.
  ///
  /// Returns the content URIs of the selected ZIP files, or null if cancelled.
  Future<List<String>?> pickZipFiles() async {
    try {
      final result = await KuronNative.instance.pickZipFiles();
      return result;
    } catch (e) {
      throw Exception('Failed to pick ZIP files: $e');
    }
  }

  /// Gets the actual file path or content from the content URI.
  ///
  /// This is needed because Android content URIs need to be read through
  /// content resolver. Returns the bytes of the ZIP file.
  Future<Uint8List?> readZipBytes(String contentUri) async {
    try {
      final result = await KuronNative.instance.readZipBytes(contentUri);
      return result;
    } catch (e) {
      throw Exception('Failed to read ZIP file: $e');
    }
  }
}
