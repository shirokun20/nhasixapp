/// Template-based URL builder for [GenericHttpSource].
///
/// Resolves URL templates with named placeholders:
///   `https://example.com/api/gallery/{contentId}?page={page}`
///
/// Supported placeholder names:
/// - `{contentId}` — content/gallery ID
/// - `{page}` — pagination page number (1-indexed)
/// - `{query}` — URL-encoded search query
/// - `{sort}` — sort parameter value
/// - `{tagId}` — tag ID for tag-based searches
/// - `{mediaId}` — media/image server ID
/// - `{ext}` — file extension
/// Any additional custom placeholders defined in the config are also supported.
library;

import 'package:kuron_core/kuron_core.dart';

class GenericUrlBuilder {
  final String baseUrl;

  const GenericUrlBuilder({required this.baseUrl});

  /// Resolve a URL template by substituting [params].
  String resolve(String template, Map<String, String> params) {
    // If template is already a full URL, don't prepend baseUrl.
    final base = template.startsWith('http') ? '' : baseUrl;
    var url = '$base$template';
    for (final entry in params.entries) {
      url = url.replaceAll('{${entry.key}}', entry.value);
    }
    return url;
  }

  /// Build a search URL from a [SearchFilter].
  String buildSearchUrl(
    String template,
    SearchFilter filter, {
    String sortValue = '',
    String queryParam = 'query',
    Map<String, String> extraParams = const {},
  }) {
    final params = <String, String>{
      'page': filter.page.toString(),
      'sort': sortValue,
      queryParam: Uri.encodeQueryComponent(filter.query),
      ...extraParams,
    };
    return resolve(template, params);
  }

  /// Build a content detail URL.
  /// Supports both {contentId} and {id} placeholders for backward compatibility.
  String buildDetailUrl(String template, String contentId) =>
      resolve(template, {
        'contentId': contentId,
        'id': contentId, // Legacy support for configs using {id}
      });

  /// Build a paginated gallery-of-pages URL.
  /// Supports both {contentId} and {id} placeholders for backward compatibility.
  String buildPagesUrl(String template, String contentId, {int page = 1}) =>
      resolve(template, {
        'contentId': contentId,
        'id': contentId, // Legacy support for configs using {id}
        'page': page.toString(),
      });

  /// Build an image URL for a specific page.
  String buildImageUrl(
    String template, {
    required String mediaId,
    required String page,
    required String ext,
  }) =>
      resolve(template, {'mediaId': mediaId, 'page': page, 'ext': ext});
}
