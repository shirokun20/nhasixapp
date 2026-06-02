import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart' show CompatibilityStatus;
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;
  late RemoteConfigService service;

  String readConfig(String fileName) {
    return File(
      p.join(Directory.current.path, 'informations', 'configs', fileName),
    ).readAsStringSync();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp(
      'remote-config-service-test',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      return switch (call.method) {
        'getApplicationDocumentsDirectory' => tempDir.path,
        'getTemporaryDirectory' => tempDir.path,
        _ => tempDir.path,
      };
    });

    service = RemoteConfigService(
      dio: Dio(),
      logger: Logger(level: Level.off),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('applySourceConfigFromJson caches validation report for imported config',
      () async {
    await service.applySourceConfigFromJson(
      sourceId: 'komikcast',
      rawJson: readConfig('komikcast-config.json'),
      sourceLabel: 'test',
    );

    final report = service.getValidationReport('komikcast');
    expect(report, isNotNull);
    expect(
      report!.overallStatus,
      anyOf(
        CompatibilityStatus.compatible,
        CompatibilityStatus.partiallyCompatible,
      ),
    );
    expect(service.getConfig('komikcast'), isNotNull);

    final cachedFile =
        File(p.join(tempDir.path, 'configs', 'komikcast-config.json'));
    expect(await cachedFile.exists(), isTrue);
  });

  test('applySourceConfigFromJson preserves needsEngineSupport status',
      () async {
    await service.applySourceConfigFromJson(
      sourceId: 'hitomi',
      rawJson: readConfig('hitomi-config.json'),
      sourceLabel: 'test',
    );

    final report = service.getValidationReport('hitomi');
    expect(report, isNotNull);
    expect(report!.overallStatus, CompatibilityStatus.needsEngineSupport);
  });

  test('uninstallSourceConfig clears cached validation report', () async {
    await service.applySourceConfigFromJson(
      sourceId: 'komikcast',
      rawJson: readConfig('komikcast-config.json'),
      sourceLabel: 'test',
    );
    await service.markSourceInstalled('komikcast');

    await service.uninstallSourceConfig('komikcast');

    expect(service.getValidationReport('komikcast'), isNull);
    expect(service.getConfig('komikcast'), isNull);
    expect(
      await File(p.join(tempDir.path, 'configs', 'komikcast-config.json'))
          .exists(),
      isFalse,
    );
  });
}
