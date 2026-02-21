import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:kuron_ads/kuron_ads.dart';
import 'package:nhasixapp/services/license_service.dart';

class AdService {
  final Logger _logger;
  final LicenseService _licenseService;

  AdService({
    required Logger logger,
    required LicenseService licenseService,
  })  : _logger = logger,
        _licenseService = licenseService;

  /// Initialize ads logic
  Future<void> initialize() async {
    // 1. Check if user is premium
    if (_licenseService.isPremiumActive) {
      _logger.i('AdService: Premium user detected. Ads logic disabled.');
      return;
    }

    try {
      // 2. Enable test mode (pass configuration to native side)
      // Setting testMode to true for development
      // TODO: Replace with your actual StartApp App ID
      const String appId = "201356049"; // Example StartApp Test ID
      await KuronAds.initialize(appId: appId, testMode: kDebugMode);

      _logger.i('AdService: Logic initialized. Native Plugin Ready.');
    } catch (e) {
      _logger.e('AdService: Failed to initialize ad logic', error: e);
    }
  }

  /// Check if ads should be shown based on premium status
  bool get shouldShowAds => !_licenseService.isPremiumActive;

  /// Show Interstitial Ad
  /// Bridges directly to Native SDK which handles caching internally
  Future<void> showInterstitial() async {
    if (!shouldShowAds) {
      _logger.d('AdService: Skipping interstitial (Premium active)');
      return;
    }

    _logger.d('AdService: Requesting Interstitial...');
    final result = await KuronAds.showInterstitial();
    if (result) {
      _logger.d('AdService: Interstitial show command sent successfully');
    } else {
      _logger.w('AdService: Interstitial failed (or not ready)');
    }
  }

  /// Show Rewarded Video Ad
  Future<bool> showRewardedVideo({VoidCallback? onRewardEarned}) async {
    if (!shouldShowAds) {
      _logger.d('AdService: Skipping rewarded video (Premium active)');
      return true;
    }

    _logger.d('AdService: Requesting Rewarded Video...');
    final result = await KuronAds.showRewardedVideo();
    if (result) {
      _logger.d('AdService: Rewarded video completed successfully');
      onRewardEarned?.call();
      return true;
    } else {
      _logger.w('AdService: Rewarded video failed or not ready');
      return false;
    }
  }

  /// Get Banner Ad Widget
  /// Returns a Widget that renders the native Android View
  Widget getBannerAdWidget() {
    if (!shouldShowAds) return const SizedBox.shrink();

    // The native view handles its own loading lifecycle
    return const KuronBannerAd();
  }

  /// Check if AdGuard DNS is active for non-premium users
  Future<bool> isAdGuardDnsActive() async {
    if (_licenseService.isPremiumActive) return false;
    final dns = await KuronAds.getPrivateDnsServer();
    return dns.toLowerCase().contains('adguard');
  }
}
