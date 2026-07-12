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

  SchaleSourceFactory({
    required Dio dio,
    required Logger logger,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _logger = logger,
        _secureStorage = secureStorage;

  @override
  String get sourceId => 'schale-network';

  @override
  ContentSource create(Map<String, dynamic> config) {
    final schaleDio = Dio(_dio.options);
    for (final interceptor in _dio.interceptors) {
      try { schaleDio.interceptors.add(interceptor); } catch (_) {}
    }
    final clearance = SchaleClearanceService(
      secureStorage: _secureStorage,
      logger: _logger,
    );
    schaleDio.interceptors.add(clearance.createInterceptor());
    unawaited(clearance.init());
    return GenericHttpSource(rawConfig: config, dio: schaleDio, logger: _logger);
  }
}
