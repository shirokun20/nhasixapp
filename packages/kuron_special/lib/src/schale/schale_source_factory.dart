import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

import 'schale_clearance_service.dart';

class SchaleSourceFactory implements SourceFactory {
  final Dio _dio;
  final Logger _logger;
  final FlutterSecureStorage _secureStorage;
  final String _sourceId;

  SchaleSourceFactory({
    required Dio dio,
    required Logger logger,
    required FlutterSecureStorage secureStorage,
    String sourceId = 'schale-network',
  })  : _dio = dio,
        _logger = logger,
        _secureStorage = secureStorage,
        _sourceId = sourceId;

  @override
  String get sourceId => _sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) {
    final schaleDio = Dio(_dio.options);
    for (final interceptor in _dio.interceptors) {
      try { schaleDio.interceptors.add(interceptor); } catch (_) {}
    }
    final domainUrl = switch (_sourceId) {
      'hdoujin' => 'https://hdoujin.org/',
      _ => 'https://niyaniya.moe/',
    };
    // ponytail: switch catch-all masks typos in sourceId. Add a map/registry
    // when mapping grows beyond 2 sources so unknown IDs fail loudly at
    // construction instead of silently routing to schale.
    final clearance = SchaleClearanceService(
      secureStorage: _secureStorage,
      logger: _logger,
      sourceId: _sourceId,
      domainUrl: domainUrl,
    );
    schaleDio.interceptors.add(clearance.createInterceptor());
    unawaited(clearance.init());
    return GenericHttpSource(rawConfig: config, dio: schaleDio, logger: _logger);
  }
}
