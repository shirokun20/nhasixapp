import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_config.dart';

void main() {
  group('MangaFireVRFConfig', () {
    group('fromConfigMap', () {
      test('parses VRF-enabled config', () {
        final config = MangaFireVRFConfig.fromConfigMap({
          'network': {
            'auth': {
              'enabled': true,
              'authType': 'vrf',
              'captureUrl': 'https://mangafire.to/',
              'vrfParam': 'vrf',
              'ttlSeconds': 300,
              'interceptEndpoints': ['/api/titles', '/api/chapters'],
            },
          },
        });

        expect(config.enabled, isTrue);
        expect(config.authType, equals('vrf'));
        expect(config.vrfParam, equals('vrf'));
        expect(config.ttlSeconds, equals(300));
        expect(config.interceptEndpoints, contains('/api/titles'));
      });

      test('disables when authType not vrf', () {
        final config = MangaFireVRFConfig.fromConfigMap({
          'network': {
            'auth': {
              'enabled': true,
              'authType': 'cloudflare',
            },
          },
        });
        expect(config.enabled, isFalse);
      });

      test('disables when auth block missing', () {
        final config = MangaFireVRFConfig.fromConfigMap({
          'network': {},
        });
        expect(config.enabled, isFalse);
      });

      test('disables when network block missing', () {
        final config = MangaFireVRFConfig.fromConfigMap({});
        expect(config.enabled, isFalse);
      });
    });

    group('shouldIntercept', () {
      test('returns true for VRF-protected endpoints', () {
        final config = MangaFireVRFConfig(
          enabled: true,
          interceptEndpoints: ['/api/titles', '/api/chapters'],
          vrfFreeEndpoints: [
            '/api/filter-options',
            '/api/top-titles',
            '/api/me'
          ],
        );
        expect(config.shouldIntercept('/api/titles'), isTrue);
        expect(config.shouldIntercept('/api/titles/rwl3q'), isTrue);
        expect(config.shouldIntercept('/api/chapters/123'), isTrue);
      });

      test('returns false for VRF-free endpoints', () {
        final config = MangaFireVRFConfig(
          enabled: true,
          interceptEndpoints: ['/api/titles'],
          vrfFreeEndpoints: ['/api/filter-options', '/api/top-titles'],
        );
        expect(config.shouldIntercept('/api/filter-options'), isFalse);
        expect(config.shouldIntercept('/api/top-titles'), isFalse);
        expect(config.shouldIntercept('/api/me'), isFalse);
      });

      test('returns false when disabled', () {
        final config = MangaFireVRFConfig(
          enabled: false,
          interceptEndpoints: ['/api/titles'],
        );
        expect(config.shouldIntercept('/api/titles'), isFalse);
      });
    });
  });
}
