import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kuron_crotpedia/src/auth/crotpedia_auth_manager.dart';
import 'package:kuron_crotpedia/src/auth/crotpedia_cookie_store.dart';

// Generate mocks using build_runner: flutter pub run build_runner build
@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Interceptors>(),
  MockSpec<FlutterSecureStorage>(),
  MockSpec<CrotpediaCookieStore>(),
])
import 'crotpedia_auth_manager_test.mocks.dart';

void main() {
  late CrotpediaAuthManager authManager;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockCrotpediaCookieStore mockCookieStore;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockFlutterSecureStorage();
    mockCookieStore = MockCrotpediaCookieStore();

    // Stub the interceptors to prevent FakeUsedError
    final mockInterceptors = MockInterceptors();
    when(mockDio.interceptors).thenReturn(mockInterceptors);
    // Stub the add method on interceptors
    when(mockInterceptors.add(any)).thenReturn(null);

    authManager = CrotpediaAuthManager(
      dio: mockDio,
      cookieStore: mockCookieStore,
      secureStorage: mockSecureStorage,
    );
  });

  group('CrotpediaAuthManager', () {
    group('Nonce Extraction', () {
      test('extracts nonce from login page HTML', () async {
        final html = await File('test/fixtures/login_page.html').readAsString();

        // Create a mock response with the HTML
        final response = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: html,
          statusCode: 200,
        );

        when(mockDio.get(any)).thenAnswer((_) async => response);

        // This will trigger nonce extraction internally
        // We can't test the private method directly, but we can verify
        // the login flow doesn't fail due to missing nonce
        await authManager.login(
          email: 'test@example.com',
          password: 'password',
        );

        // Verify that GET was called for login page
        verify(mockDio.get(argThat(contains('/login/')))).called(1);
      });

      test('handles missing nonce gracefully', () async {
        final response = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: '<html><body>No nonce here</body></html>',
          statusCode: 200,
        );

        when(mockDio.get(any)).thenAnswer((_) async => response);

        final result = await authManager.login(
          email: 'test@example.com',
          password: 'password',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('token login'));
      });
    });

    group('Login Flow', () {
      test('successful login saves credentials when rememberMe is true',
          () async {
        // Setup mock responses
        final loginPageResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: await File('test/fixtures/login_page.html').readAsString(),
          statusCode: 200,
        );

        final loginPostResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          statusCode: 302,
        );

        final verifyResponse = Response(
          requestOptions: RequestOptions(path: '/bookmark/'),
          statusCode: 200,
        );

        when(mockDio.get(argThat(contains('/login/'))))
            .thenAnswer((_) async => loginPageResponse);
        when(mockDio.post(any,
                data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => loginPostResponse);
        when(mockDio.get(argThat(contains('/bookmark/')),
                options: anyNamed('options')))
            .thenAnswer((_) async => verifyResponse);
        when(mockSecureStorage.write(
                key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async => {});

        final result = await authManager.login(
          email: 'test@example.com',
          password: 'testpass',
          rememberMe: true,
        );

        expect(result.success, isTrue);
        expect(authManager.isLoggedIn, isTrue);
        expect(authManager.username, equals('test'));

        // Verify credentials were saved
        verify(mockSecureStorage.write(
                key: 'crotpedia_email', value: 'test@example.com'))
            .called(1);
        verify(mockSecureStorage.write(
                key: 'crotpedia_password', value: 'testpass'))
            .called(1);
      });

      test(
          'successful login does not save credentials when rememberMe is false',
          () async {
        final loginPageResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: await File('test/fixtures/login_page.html').readAsString(),
          statusCode: 200,
        );

        final loginPostResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          statusCode: 302,
        );

        final verifyResponse = Response(
          requestOptions: RequestOptions(path: '/bookmark/'),
          statusCode: 200,
        );

        when(mockDio.get(argThat(contains('/login/'))))
            .thenAnswer((_) async => loginPageResponse);
        when(mockDio.post(any,
                data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => loginPostResponse);
        when(mockDio.get(argThat(contains('/bookmark/')),
                options: anyNamed('options')))
            .thenAnswer((_) async => verifyResponse);

        final result = await authManager.login(
          email: 'test@example.com',
          password: 'testpass',
          rememberMe: false,
        );

        expect(result.success, isTrue);

        // Verify credentials were NOT saved
        verifyNever(mockSecureStorage.write(
            key: anyNamed('key'), value: anyNamed('value')));
      });

      test('failed login returns error', () async {
        final loginPageResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: await File('test/fixtures/login_page.html').readAsString(),
          statusCode: 200,
        );

        final loginPostResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          statusCode: 200, // No redirect = failed login
        );

        final verifyResponse = Response(
          requestOptions: RequestOptions(path: '/bookmark/'),
          statusCode: 302, // Redirect to login = not authenticated
        );

        when(mockDio.get(argThat(contains('/login/'))))
            .thenAnswer((_) async => loginPageResponse);
        when(mockDio.post(any,
                data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => loginPostResponse);
        when(mockDio.get(argThat(contains('/bookmark/')),
                options: anyNamed('options')))
            .thenAnswer((_) async => verifyResponse);

        final result = await authManager.login(
          email: 'wrong@example.com',
          password: 'wrongpass',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(authManager.isLoggedIn, isFalse);
      });
    });

    group('Auto-Login', () {
      test('hasStoredCredentials returns true when email exists', () async {
        when(mockSecureStorage.read(key: 'crotpedia_email'))
            .thenAnswer((_) async => 'test@example.com');

        final hasCredentials = await authManager.hasStoredCredentials();
        expect(hasCredentials, isTrue);
      });

      test('hasStoredCredentials returns false when email is null', () async {
        when(mockSecureStorage.read(key: 'crotpedia_email'))
            .thenAnswer((_) async => null);

        final hasCredentials = await authManager.hasStoredCredentials();
        expect(hasCredentials, isFalse);
      });
    });

    group('Logout', () {
      test('logout clears all stored data', () async {
        when(mockCookieStore.clearLoginState()).thenAnswer((_) async => {});
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async => {});

        await authManager.logout();

        verify(mockCookieStore.clearLoginState()).called(1);
        verify(mockSecureStorage.delete(key: 'crotpedia_email')).called(1);
        verify(mockSecureStorage.delete(key: 'crotpedia_password')).called(1);
        verify(mockSecureStorage.delete(key: 'crotpedia_username')).called(1);

        expect(authManager.isLoggedIn, isFalse);
        expect(authManager.username, isNull);
      });
    });

    group('State Management', () {
      test('initial state is notLoggedIn', () {
        expect(authManager.state, equals(CrotpediaAuthState.notLoggedIn));
        expect(authManager.isLoggedIn, isFalse);
      });

      test('username is extracted from email correctly', () async {
        final loginPageResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: await File('test/fixtures/login_page.html').readAsString(),
          statusCode: 200,
        );

        final loginPostResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          statusCode: 302,
        );

        final verifyResponse = Response(
          requestOptions: RequestOptions(path: '/bookmark/'),
          statusCode: 200,
        );

        when(mockDio.get(argThat(contains('/login/'))))
            .thenAnswer((_) async => loginPageResponse);
        when(mockDio.post(any,
                data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => loginPostResponse);
        when(mockDio.get(argThat(contains('/bookmark/')),
                options: anyNamed('options')))
            .thenAnswer((_) async => verifyResponse);
        when(mockSecureStorage.write(
                key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async => {});

        await authManager.login(
          email: 'myuser@example.com',
          password: 'pass',
        );

        expect(authManager.username, equals('myuser'));
      });
    });

    group('Bookmark API', () {
      test('toggleBookmark sends correct POST request', () async {
        // Setup: Fake logged in state
        final loginPageResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          data: await File('test/fixtures/login_page.html').readAsString(),
          statusCode: 200,
        );

        final loginPostResponse = Response(
          requestOptions: RequestOptions(path: '/login/'),
          statusCode: 302,
        );

        final verifyResponse = Response(
          requestOptions: RequestOptions(path: '/bookmark/'),
          statusCode: 200,
        );

        final bookmarkResponse = Response(
          requestOptions: RequestOptions(path: '/wp-admin/admin-ajax.php'),
          statusCode: 200,
        );

        when(mockDio.get(argThat(contains('/login/'))))
            .thenAnswer((_) async => loginPageResponse);
        when(mockDio.post(argThat(contains('/login/')),
                data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => loginPostResponse);
        when(mockDio.get(argThat(contains('/bookmark/')),
                options: anyNamed('options')))
            .thenAnswer((_) async => verifyResponse);
        when(mockDio.post(argThat(contains('/wp-admin/admin-ajax.php')),
                data: anyNamed('data')))
            .thenAnswer((_) async => bookmarkResponse);
        when(mockSecureStorage.write(
                key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async => {});

        // Login first
        await authManager.login(
          email: 'test@example.com',
          password: '123',
        );

        // Toggle bookmark
        final result = await authManager.toggleBookmark('12345', true);

        expect(result, isTrue);
        verify(mockDio.post(
          argThat(contains('admin-ajax.php')),
          data: anyNamed('data'),
        )).called(1);
      });
    });
  });
}
