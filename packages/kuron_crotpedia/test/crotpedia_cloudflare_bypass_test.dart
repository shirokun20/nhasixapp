import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_crotpedia/src/crotpedia_cloudflare_bypass.dart';

void main() {
  group('CrotpediaCloudflareBypass Headers', () {
    test('Should be able to instantiate', () {
      final dio = Dio();
      final key = GlobalKey<NavigatorState>();
      
      final bypass = CrotpediaCloudflareBypass(
        httpClient: dio,
        navigatorKey: key,
      );
      
      expect(bypass.currentUserAgent, isNull); // Should be null initially
    });
  });
}
