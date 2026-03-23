import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

import 'hentainexus_decryptor.dart';

/// HentaiNexus adapter that decrypts reader payload from initReader().
class HentaiNexusDecryptAdapter implements GenericAdapter {
  final Dio _dio;
  final GenericScraperAdapter _delegate;

  HentaiNexusDecryptAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericHtmlParser parser,
    required Logger logger,
    required String sourceId,
  })  : _dio = dio,
        _delegate = GenericScraperAdapter(
          dio: dio,
          urlBuilder: urlBuilder,
          parser: parser,
          logger: logger,
          sourceId: sourceId,
        );

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.search(filter, rawConfig);
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final base = await _delegate.fetchDetail(contentId, rawConfig);

    try {
      final baseUrl = (rawConfig['baseUrl'] as String?) ?? '';
      if (baseUrl.isEmpty) return base;

      final decryption =
          (rawConfig['decryption'] as Map<String, dynamic>?) ?? {};
      final readerPath = (decryption['readerPath'] as String?) ?? '/read/{id}';
      final encryptedPattern =
          (decryption['encryptedDataPattern'] as String?) ??
              r'initReader\(\s*"([^"]+)"';

      final readerUrl = '$baseUrl${readerPath.replaceAll('{id}', contentId)}';
      final response = await _dio.get<String>(
        readerUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';

      final encrypted = RegExp(encryptedPattern).firstMatch(html)?.group(1);
      if (encrypted == null || encrypted.isEmpty) {
        return base;
      }

      final decrypted = HentaiNexusDecryptor.decrypt(
        encrypted: encrypted,
      );
      final imageUrls = HentaiNexusDecryptor.extractImageUrls(decrypted);
      if (imageUrls.isEmpty) {
        return base;
      }

      final updated = base.content.copyWith(
        imageUrls: imageUrls,
        pageCount: imageUrls.length,
      );

      return AdapterDetailResult(content: updated, imageUrls: imageUrls);
    } catch (_) {
      return base;
    }
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchRelated(contentId, rawConfig);
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchComments(contentId, rawConfig);
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchChapterImages(chapterId, rawConfig);
  }
}
