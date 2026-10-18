import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/services/native_backup_service.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/repositories/settings_repository_impl.dart';
import 'package:nhasixapp/domain/entities/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNativeBackupService extends Mock implements NativeBackupService {}

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SettingsRepositoryImpl repo;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SettingsRepositoryImpl(
      sharedPreferences: prefs,
      nativeBackupService: _MockNativeBackupService(),
      databaseHelper: _MockDatabaseHelper(),
    );
  });

  test('migrates legacy plaintext proxy password to secure storage and strips from prefs', () async {
    await prefs.setString(
      'proxy_settings',
      jsonEncode({
        'enabled': true,
        'host': '1.2.3.4',
        'port': 8080,
        'username': 'user',
        'password': 'secret_password_123',
        'type': 'HTTP',
      }),
    );

    final settings = await repo.getProxySettings();
    expect(settings.password, 'secret_password_123');

    // Verify prefs no longer has 'password'
    final rawInPrefs = jsonDecode(prefs.getString('proxy_settings')!) as Map<String, dynamic>;
    expect(rawInPrefs.containsKey('password'), isFalse);
    expect(rawInPrefs['host'], '1.2.3.4');

    // Verify secure storage has it
    const secureStorage = FlutterSecureStorage();
    final storedSecure = await secureStorage.read(key: 'proxy_password');
    expect(storedSecure, 'secret_password_123');
  });

  test('updateProxySettings saves password in secure storage and not in prefs', () async {
    await repo.updateProxySettings(const ProxySettings(
      enabled: true,
      host: 'proxy.domain.com',
      port: 3128,
      username: 'admin',
      password: 'super_secret_proxy_pass',
      type: 'SOCKS5',
    ));

    final rawInPrefs = jsonDecode(prefs.getString('proxy_settings')!) as Map<String, dynamic>;
    expect(rawInPrefs.containsKey('password'), isFalse);
    expect(rawInPrefs['host'], 'proxy.domain.com');

    const secureStorage = FlutterSecureStorage();
    final storedSecure = await secureStorage.read(key: 'proxy_password');
    expect(storedSecure, 'super_secret_proxy_pass');

    final loaded = await repo.getProxySettings();
    expect(loaded.password, 'super_secret_proxy_pass');
    expect(loaded.host, 'proxy.domain.com');
  });
}
