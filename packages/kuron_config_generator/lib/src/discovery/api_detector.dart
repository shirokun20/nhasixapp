/// Probe JSON API endpoints and infer REST structure.
library;

/// Inferred REST API structure from probing.
class ApiInference {
  ApiInference({
    required this.baseUrl,
    this.hasList = false,
    this.hasDetail = false,
    this.listEndpoint,
    this.detailEndpoint,
    this.listIsPaginated = false,
    this.pageParam,
    this.queryParam,
    this.listItemsPath,
    this.confidence = 0.0,
  });

  final String baseUrl;
  final bool hasList;
  final bool hasDetail;
  final String? listEndpoint;
  final String? detailEndpoint;
  final bool listIsPaginated;
  final String? pageParam;
  final String? queryParam;
  final String? listItemsPath;
  final double confidence;
}

/// Try to infer REST structure from probed JSON data.
ApiInference inferApi(String url, dynamic json) {
  final uri = Uri.tryParse(url);
  final base = '${uri?.scheme}://${uri?.host}${uri?.port == 80 || uri?.port == 443 ? '' : ':${uri?.port}'}';
  final path = uri?.path ?? '';

  if (json is List) {
    // Direct array response - likely a list endpoint
    return ApiInference(
      baseUrl: base,
      hasList: true,
      hasDetail: false,
      listEndpoint: path.isEmpty ? '/' : path,
      listIsPaginated: json.length == 20 || json.length == 50 || json.length == 100,
      listItemsPath: '',
      confidence: 0.8,
    );
  }

  if (json is Map) {
    // Check common paginated list patterns
    if (json.containsKey('data') && json['data'] is List) {
      final pageParam = _detectPageParam(json);
      return ApiInference(
        baseUrl: base,
        hasList: true,
        listEndpoint: path,
        listIsPaginated: pageParam != null,
        pageParam: pageParam,
        listItemsPath: 'data',
        queryParam: _detectQueryParam(json),
        confidence: 0.7,
      );
    }
    if (json.containsKey('results') && json['results'] is List) {
      return ApiInference(
        baseUrl: base,
        hasList: true,
        listEndpoint: path,
        listItemsPath: 'results',
        queryParam: _detectQueryParam(json),
        confidence: 0.6,
      );
    }
    if (json.containsKey('items') && json['items'] is List) {
      return ApiInference(
        baseUrl: base,
        hasList: true,
        listEndpoint: path,
        listItemsPath: 'items',
        queryParam: _detectQueryParam(json),
        confidence: 0.6,
      );
    }
    // Single object with common manga fields → likely detail
    if (_looksLikeDetail(json)) {
      return ApiInference(
        baseUrl: base,
        hasList: false,
        hasDetail: true,
        detailEndpoint: path,
        confidence: 0.7,
      );
    }
    // Generic map with some keys (could be list wrapper or detail)
    if (json.keys.length > 2) {
      // ponytail: assume detail for rich maps
      return ApiInference(
        baseUrl: base,
        hasList: false,
        hasDetail: true,
        detailEndpoint: path,
        confidence: 0.4,
      );
    }
  }

  return ApiInference(
    baseUrl: base,
    confidence: 0.0,
  );
}

String? _detectPageParam(Map json) {
  for (final key in ['page', 'offset', 'p', 'pageNumber']) {
    if (json.containsKey(key)) return key;
  }
  return null;
}

String? _detectQueryParam(Map json) {
  for (final key in ['q', 'query', 'search', 's']) {
    if (json.containsKey(key)) return key;
  }
  return null;
}

bool _looksLikeDetail(Map json) {
  final titleKeys = ['title', 'name', 'name_en', 'english_title', 'japanese_title'];
  final hasTitle = titleKeys.any((k) => json.containsKey(k));
  final hasId = json.containsKey('id') || json.containsKey('_id') || json.containsKey('slug');
  final hasCover = ['cover', 'thumbnail', 'image', 'poster'].any((k) => json.containsKey(k));
  return hasTitle && (hasId || hasCover);
}
