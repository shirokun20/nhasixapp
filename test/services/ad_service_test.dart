import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/services/ad_service.dart';
import 'package:nhasixapp/services/license_service.dart';

class MockLogger extends Mock implements Logger {}

class MockLicenseService extends Mock implements LicenseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdService adService;
  late MockLogger mockLogger;
  late MockLicenseService mockLicenseService;

  const MethodChannel channel = MethodChannel('kuron_ads');

  setUp(() {
    mockLogger = MockLogger();
    mockLicenseService = MockLicenseService();

    // Default mock behavior for void functions
    when(() => mockLogger.d(any())).thenReturn(null);
    when(() => mockLogger.w(any())).thenReturn(null);
    when(() => mockLogger.e(any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'))).thenReturn(null);
    when(() => mockLogger.i(any())).thenReturn(null);

    // Default mock behavior for premium status
    when(() => mockLicenseService.isPremiumActive).thenReturn(false);

    adService = AdService(
      logger: mockLogger,
      licenseService: mockLicenseService,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AdService - isAdGuardDnsActive', () {
    test('returns false if user is premium, without checking DNS', () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(true);

      var methodChannelCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodChannelCalled = true;
        return '';
      });

      final result = await adService.isAdGuardDnsActive();

      expect(result, isFalse);
      expect(methodChannelCalled, isFalse); // Should not check DNS
    });

    test('returns true if non-premium and DNS contains adguard', () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(false);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'checkPrivateDns') {
          return 'dns.adguard-dns.com';
        }
        return null;
      });

      final result = await adService.isAdGuardDnsActive();

      expect(result, isTrue);
    });

    test('returns false if non-premium and DNS does not contain adguard',
        () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(false);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'checkPrivateDns') {
          return '8.8.8.8';
        }
        return null;
      });

      final result = await adService.isAdGuardDnsActive();

      expect(result, isFalse);
    });
  });

  group('AdService - showRewardedVideo', () {
    test('skips rewarded video calculation if user is premium', () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(true);

      var methodChannelCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodChannelCalled = true;
        return true;
      });

      var rewardEarned = false;
      await adService.showRewardedVideo(onRewardEarned: () {
        rewardEarned = true;
      });

      expect(rewardEarned, isFalse);
      expect(methodChannelCalled, isFalse);
    });

    test('calls onRewardEarned if rewarded video completes successfully',
        () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(false);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'showRewardedVideo') {
          return true;
        }
        return false;
      });

      var rewardEarned = false;
      await adService.showRewardedVideo(onRewardEarned: () {
        rewardEarned = true;
      });

      expect(rewardEarned, isTrue);
    });

    test('does not call onRewardEarned if rewarded video fails or early close',
        () async {
      when(() => mockLicenseService.isPremiumActive).thenReturn(false);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'showRewardedVideo') {
          return false;
        }
        return true;
      });

      var rewardEarned = false;
      await adService.showRewardedVideo(onRewardEarned: () {
        rewardEarned = true;
      });

      expect(rewardEarned, isFalse);
    });
  });
}
