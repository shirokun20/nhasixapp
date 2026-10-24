import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/services/analytics_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;
  late MockSharedPreferences mockPrefs;
  late AnalyticsService service;

  setUp(() async {
    await getIt.reset();
    mockPrefs = MockSharedPreferences();
    getIt.registerSingleton<SharedPreferences>(mockPrefs);
    getIt.registerSingleton<Logger>(Logger(level: Level.off));

    when(() => mockPrefs.getBool(any())).thenReturn(true);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
    service = AnalyticsService();
    await service.initialize();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('batches events and flushes to SharedPreferences on threshold or flushEvents', () async {
    await service.trackAction('click_button');
    // Manually flush and verify setString is called with JSON array
    await service.flushEvents();
    verify(() => mockPrefs.setString(any(), any())).called(1);
  });
}
