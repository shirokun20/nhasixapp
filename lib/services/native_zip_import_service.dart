import 'package:kuron_native/kuron_native.dart';
import 'dart:typed_data';

/// Native service for importing ZIP files containing doujin/manga content
///
/// This service provides a native Android file picker for selecting ZIP files
/// and returns the content URI for further processing in Dart.
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
