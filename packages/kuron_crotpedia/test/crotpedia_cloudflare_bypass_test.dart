import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_crotpedia/src/crotpedia_cloudflare_bypass.dart';
import 'package:kuron_native/kuron_native_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKuronNativePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements KuronNativePlatform {
  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
  }) {
    return super.noSuchMethod(
      Invocation.method(#showLoginWebView, null, {
        #url: url,
        #successUrlFilters: successUrlFilters,
        #initialCookie: initialCookie,
        #userAgent: userAgent,
      }),
      returnValue: Future.value(null),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockKuronNativePlatform mockPlatform;
  late Dio dio;
  late GlobalKey<NavigatorState> navigatorKey;
  late CrotpediaCloudflareBypass bypass;

  setUp(() {
    mockPlatform = MockKuronNativePlatform();
    KuronNativePlatform.instance = mockPlatform;
    dio = Dio();
    navigatorKey = GlobalKey<NavigatorState>();
    bypass = CrotpediaCloudflareBypass(
      httpClient: dio,
      navigatorKey: navigatorKey,
    );
  });

  group('CrotpediaCloudflareBypass', () {
    test('attemptBypass calls showLoginWebView with correct url', () async {
      // Arrange
      final successResult = {
        'success': true,
        'cookies': ['key=value; Path=/'],
        'userAgent': 'MockUA',
      };
      
      // Use specific arguments matchers to satisfy non-nullable types
      when(mockPlatform.showLoginWebView(
        url: 'https://crotpedia.net', 
        successUrlFilters: anyNamed('successUrlFilters'),
        initialCookie: anyNamed('initialCookie'),
        userAgent: anyNamed('userAgent'),
      )).thenAnswer((_) async => successResult);

      // Act
      try {
        await bypass.attemptBypass(targetUrl: 'https://crotpedia.net');
      } catch (_) {}

      // Assert
      verify(mockPlatform.showLoginWebView(
        url: 'https://crotpedia.net',
        successUrlFilters: anyNamed('successUrlFilters'),
        initialCookie: anyNamed('initialCookie'),
        userAgent: anyNamed('userAgent'),
      )).called(1);
    });

    test('attemptLogin calls showLoginWebView with correct login url', () async {
       // Arrange
      final successResult = {
        'success': true,
        'cookies': ['session=123'],
        'userAgent': 'MockUA',
      };
       
       // Using generic argument matcher for url if we want, but explicit is safer for null safety without code gen
       when(mockPlatform.showLoginWebView(
        url: 'https://crotpedia.net/login/',
        successUrlFilters: anyNamed('successUrlFilters'),
        initialCookie: anyNamed('initialCookie'),
        userAgent: anyNamed('userAgent'),
      )).thenAnswer((_) async => successResult);

      // Act
      final result = await bypass.attemptLogin(email: 'test', password: 'pass');

      // Assert
      verify(mockPlatform.showLoginWebView(
        url: 'https://crotpedia.net/login/',
        successUrlFilters: anyNamed('successUrlFilters'),
        initialCookie: anyNamed('initialCookie'),
        userAgent: anyNamed('userAgent'),
      )).called(1);

      expect(result, isNotNull);
      expect(result!.first.name, 'session');
      expect(result.first.value, '123');
    });
  });
}
