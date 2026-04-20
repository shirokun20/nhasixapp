import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/utils/source_config_display_utils.dart';

class _MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  late _MockRemoteConfigService remoteConfigService;

  setUp(() {
    remoteConfigService = _MockRemoteConfigService();
  });

  test('resolves version from typed config and description from raw meta', () {
    when(() => remoteConfigService.getConfig('ehentai')).thenReturn(
      SourceConfig(
        source: 'ehentai',
        version: '1.4.2',
      ),
    );
    when(() => remoteConfigService.getRawConfig('ehentai')).thenReturn({
      'meta': {'description': 'Mirror with gallery-page resolver'},
    });

    final info = resolveSourceConfigDisplayInfo(
      remoteConfigService: remoteConfigService,
      sourceId: 'ehentai',
    );

    expect(info.version, '1.4.2');
    expect(info.description, 'Mirror with gallery-page resolver');
    expect(info.idWithVersion, 'ehentai • v1.4.2');
  });

  test('falls back to source id when version is unavailable', () {
    when(() => remoteConfigService.getConfig('komiktap')).thenReturn(null);
    when(() => remoteConfigService.getRawConfig('komiktap')).thenReturn({
      'ui': {'description': 'Bundled webtoon source'},
    });

    final info = resolveSourceConfigDisplayInfo(
      remoteConfigService: remoteConfigService,
      sourceId: 'komiktap',
    );

    expect(info.version, isNull);
    expect(info.description, 'Bundled webtoon source');
    expect(info.idWithVersion, 'komiktap');
  });
}
