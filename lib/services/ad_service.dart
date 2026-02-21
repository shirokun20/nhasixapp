import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:kuron_ads/kuron_ads.dart';
import 'package:nhasixapp/services/license_service.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdService {
  final Logger _logger;
  final LicenseService _licenseService;

  // --- Unity Ads Configuration ---
  // Replace with real Unity Game IDs from Unity Dashboard
  final String _androidGameId = '6049979';
  final String _iosGameId = '6049978';

  // Replace with real Placement IDs based on OS
  final String _rewardedVideoPlacementId =
      Platform.isAndroid ? 'Rewarded_Android' : 'Rewarded_iOS';
  final String _interstitialPlacementId =
      Platform.isAndroid ? 'Interstitial_Android' : 'Interstitial_iOS';
  // -------------------------------

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
      // 2. Initialize Unity Ads
      final gameId = Platform.isAndroid ? _androidGameId : _iosGameId;
      UnityAds.init(
        gameId: gameId,
        testMode: kDebugMode,
        onComplete: () => _logger.i('UnityAds: Initialization Complete'),
        onFailed: (error, message) =>
            _logger.e('UnityAds: Initialization Failed: $error - $message'),
      );

      // 3. Initialize StartApp (Fallback layer)
      const String appId = "201356049"; // Replace with actual StartApp ID
      await KuronAds.initialize(appId: appId, testMode: kDebugMode);

      _logger
          .i('AdService: Mediation Logic initialized. Unity & StartApp Ready.');
    } catch (e) {
      _logger.e('AdService: Failed to initialize ad logic', error: e);
    }
  }

  /// Check if ads should be shown based on premium status
  bool get shouldShowAds => !_licenseService.isPremiumActive;

  /// Internal helper to wait for Unity Video completion using Completer
  Future<bool> _showUnityVideoAd(String placementId) async {
    final completer = Completer<bool>();

    UnityAds.showVideoAd(
      placementId: placementId,
      onStart: (placementId) => _logger.d('UnityAds: Ad $placementId started'),
      onClick: (placementId) => _logger.d('UnityAds: Ad $placementId clicked'),
      onSkipped: (placementId) {
        _logger.w('UnityAds: Ad $placementId skipped by user');
        if (!completer.isCompleted) completer.complete(false);
      },
      onComplete: (placementId) {
        _logger.i('UnityAds: Ad $placementId completed successfully');
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        _logger.e('UnityAds: Ad $placementId failed: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }

  /// Show Interstitial Ad (Waterfall: Unity -> StartApp)
  Future<void> showInterstitial() async {
    if (!shouldShowAds) {
      _logger.d('AdService: Skipping interstitial (Premium active)');
      return;
    }

    _logger.d(
        'AdService: Requesting Unity Interstitial ($_interstitialPlacementId)...');
    bool unitySuccess = await _showUnityVideoAd(_interstitialPlacementId);

    // If Unity succeeded (completed), stop here.
    if (unitySuccess) return;

    _logger
        .w('AdService: Unity Interstitial failed. Trying StartApp Fallback...');
    final result = await KuronAds.showInterstitial();
    if (result) {
      _logger
          .d('AdService: StartApp Interstitial show command sent successfully');
    } else {
      _logger.w('AdService: Both Unity and StartApp Interstitial failed.');
    }
  }

  /// Show Rewarded Video Ad (Waterfall: Unity -> StartApp)
  Future<bool> showRewardedVideo({VoidCallback? onRewardEarned}) async {
    if (!shouldShowAds) {
      _logger.d('AdService: Skipping rewarded video (Premium active)');
      return true; // Pretend it succeeded for premium user flow
    }

    _logger.d(
        'AdService: Requesting Unity Rewarded Video ($_rewardedVideoPlacementId)...');
    bool unitySuccess = await _showUnityVideoAd(_rewardedVideoPlacementId);

    if (unitySuccess) {
      _logger.i('AdService: Unity Rewarded Video earned!');
      onRewardEarned?.call();
      return true;
    }

    _logger.w(
        'AdService: Unity Video failed/skipped. Attempting StartApp Fallback...');
    final startAppResult = await KuronAds.showRewardedVideo();

    if (startAppResult) {
      _logger.i('AdService: StartApp Rewarded Video earned!');
      onRewardEarned?.call();
      return true;
    } else {
      _logger.e(
          'AdService: Waterfall Exhausted. Unity and StartApp Rewarded Videos both failed.');
      return false;
    }
  }

  /// Get Banner Ad Widget
  /// Returns a Widget that renders the native Android View for Banners
  Widget getBannerAdWidget() {
    if (!shouldShowAds) return const SizedBox.shrink();

    // Defaulting to StartApp Banner for display persistence
    return const KuronBannerAd();
  }

  /// Check if AdGuard DNS is active for non-premium users
  Future<bool> isAdGuardDnsActive() async {
    if (_licenseService.isPremiumActive) return false;
    final dns = await KuronAds.getPrivateDnsServer();
    return dns.toLowerCase().contains('adguard');
  }
}
