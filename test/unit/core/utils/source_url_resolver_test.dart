import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/utils/source_url_resolver.dart';

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  group('SourceUrlResolver', () {
    late MockRemoteConfigService remoteConfigService;

    setUp(() {
      remoteConfigService = MockRemoteConfigService();
    });

    test('buildContentUrl supports endpoint object path schema', () {
      when(() => remoteConfigService.getRawConfig('komikcast')).thenReturn({
        'source': 'komikcast',
        'api': {
          'url': 'https://be.komikcast.cc',
          'endpoints': {
            'detail': {'path': '/series/{id}'},
          },
        },
      });

      final url = SourceUrlResolver.buildContentUrl(
        remoteConfigService: remoteConfigService,
        sourceId: 'komikcast',
        contentId: 'atm-ojisan-isekai-de-mote-ki-ga-tomaranai/17',
      );

      expect(
        url,
        'https://be.komikcast.cc/series/atm-ojisan-isekai-de-mote-ki-ga-tomaranai/17',
      );
    });

    test('resolveBaseUrl prioritizes api.url over baseUrl', () {
      when(() => remoteConfigService.getRawConfig('komikcast')).thenReturn({
        'source': 'komikcast',
        'baseUrl': 'https://v2.komikcast.fit',
        'api': {
          'url': 'https://be.komikcast.cc',
        },
      });

      final baseUrl = SourceUrlResolver.resolveBaseUrl(
        remoteConfigService: remoteConfigService,
        sourceId: 'komikcast',
      );

      expect(baseUrl, 'https://be.komikcast.cc');
    });
  });
}
