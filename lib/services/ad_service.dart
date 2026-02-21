import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  final String _bannerPlacementId =
      Platform.isAndroid ? 'Banner_Android' : 'Banner_iOS';

  // Internal state: whether Unity Ads SDK is ready
  bool _isUnityInitialized = false;
  Completer<void>? _initCompleter;

  // Random instance untuk ad network selection
  final _random = Random();

  /// Returns true ~50% of the time, hanya jika Unity sudah siap.
  /// Digunakan untuk randomize antara Unity dan StartApp.
  bool _useUnity() => _isUnityInitialized && _random.nextBool();
  // -------------------------------

  AdService({
    required Logger logger,
    required LicenseService licenseService,
  })  : _logger = logger,
        _licenseService = licenseService;

  /// Initialize ads logic — dipanggil di main() sebelum runApp()
  /// Hanya menginisialisasi StartApp (KuronAds). Unity diinit terpisah
  /// via [initUnity()] setelah widget tree terbentuk (post-frame).
  Future<void> initialize() async {
    // 1. Check if user is premium
    if (_licenseService.isPremiumActive) {
      _logger.i('AdService: Premium user detected. Ads logic disabled.');
      return;
    }

    try {
      // Initialize StartApp (Fallback layer)
      const String appId = "201356049"; // Replace with actual StartApp ID
      await KuronAds.initialize(appId: appId, testMode: kDebugMode);
      _logger.i('AdService: StartApp (KuronAds) initialized.');
    } catch (e) {
      _logger.e('AdService: Failed to initialize StartApp', error: e);
    }
  }

  /// Initialize Unity Ads — HARUS dipanggil setelah widget tree terbentuk
  /// (misalnya dari initState() atau addPostFrameCallback), bukan dari main().
  /// Unity Ads membutuhkan Android Activity context yang hanya tersedia
  /// setelah runApp() selesai.
  Future<void> initUnity() async {
    if (_licenseService.isPremiumActive) return;
    if (_isUnityInitialized) return;
    if (_initCompleter != null && !_initCompleter!.isCompleted) return;

    try {
      final gameId = Platform.isAndroid ? _androidGameId : _iosGameId;
      _initCompleter = Completer<void>();

      _logger.i('UnityAds: Starting initialization with gameId=$gameId...');

      UnityAds.init(
        gameId: gameId,
        testMode: kDebugMode,
        onComplete: () {
          _isUnityInitialized = true;
          _logger.i('UnityAds: Initialization Complete ✅');
          if (!_initCompleter!.isCompleted) _initCompleter!.complete();
        },
        onFailed: (error, message) {
          _logger.e('UnityAds: Initialization Failed: $error - $message');
          // Tetap complete agar tidak hang, tapi _isUnityInitialized = false
          if (!_initCompleter!.isCompleted) _initCompleter!.complete();
        },
      );

      // Tunggu Unity selesai init, maks 30 detik
      await _initCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('UnityAds: Initialization timed out after 30s');
          if (!_initCompleter!.isCompleted) _initCompleter!.complete();
        },
      );

      if (_isUnityInitialized) {
        _logger.i('AdService: Unity Ads ready ✅');
      } else {
        _logger.w('AdService: Unity Ads not available, StartApp will be used.');
      }
    } catch (e) {
      _logger.e('AdService: Unity init error', error: e);
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    }
  }

  /// Check if ads should be shown based on premium status
  bool get shouldShowAds => !_licenseService.isPremiumActive;

  /// Internal helper to wait for Unity Video completion using Completer
  Future<bool> _showUnityVideoAd(String placementId) async {
    // Guard: jika SDK belum siap, coba tunggu init selesai dulu
    if (!_isUnityInitialized) {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _logger
            .w('UnityAds: SDK still initializing, waiting for $placementId...');
        try {
          await _initCompleter!.future.timeout(const Duration(seconds: 15));
        } catch (_) {
          _logger.e('UnityAds: Init wait timed out, skipping $placementId');
          return false;
        }
      }
      // Setelah tunggu, cek lagi apakah berhasil initialized
      if (!_isUnityInitialized) {
        _logger.e('UnityAds: SDK failed to initialize, skipping $placementId');
        return false;
      }
    }

    final completer = Completer<bool>();

    _logger.d('UnityAds: Loading ad for $placementId...');

    // ✅ Step 1: LOAD the ad first (Unity Ads v4 requires explicit load before show)
    UnityAds.load(
      placementId: placementId,
      onComplete: (id) {
        _logger.d('UnityAds: Load complete for $id, now showing...');

        // ✅ Step 2: SHOW the ad after it's loaded
        UnityAds.showVideoAd(
          placementId: id,
          onStart: (id) => _logger.d('UnityAds: Ad $id started'),
          onClick: (id) => _logger.d('UnityAds: Ad $id clicked'),
          onSkipped: (id) {
            _logger.w('UnityAds: Ad $id skipped by user');
            if (!completer.isCompleted) completer.complete(false);
          },
          onComplete: (id) {
            _logger.i('UnityAds: Ad $id completed successfully ✅');
            if (!completer.isCompleted) completer.complete(true);
          },
          onFailed: (id, error, message) {
            _logger.e('UnityAds: Show failed $id: $error - $message');
            if (!completer.isCompleted) completer.complete(false);
          },
        );
      },
      onFailed: (id, error, message) {
        _logger.e('UnityAds: Load failed $id: $error - $message');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }

  /// Show Interstitial Ad — Random 50/50 antara Unity dan StartApp.
  /// Jika network yang dipilih gagal, fallback ke network lainnya.
  Future<void> showInterstitial() async {
    if (!shouldShowAds) {
      _logger.d('AdService: Skipping interstitial (Premium active)');
      return;
    }

    final useUnityFirst = _useUnity();
    _logger.d(
        'AdService: Interstitial — picked ${useUnityFirst ? "Unity" : "StartApp"} (random)');

    if (useUnityFirst) {
      // Unity first, fallback StartApp
      final success = await _showUnityVideoAd(_interstitialPlacementId);
      if (success) return;

      _logger.w(
          'AdService: Unity Interstitial failed, falling back to StartApp...');
      final result = await KuronAds.showInterstitial();
      if (!result) {
        _logger.w('AdService: Both Unity and StartApp Interstitial failed.');
      }
    } else {
      // StartApp first, fallback Unity
      _logger.d('AdService: Trying StartApp Interstitial...');
      final result = await KuronAds.showInterstitial();
      if (result) {
        _logger.d('AdService: StartApp Interstitial shown successfully.');
        return;
      }

      _logger.w(
          'AdService: StartApp Interstitial failed, falling back to Unity...');
      final success = await _showUnityVideoAd(_interstitialPlacementId);
      if (!success) {
        _logger.w('AdService: Both StartApp and Unity Interstitial failed.');
      }
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

  /// Get Banner Ad Widget — Random 50/50 antara Unity Banner dan StartApp Banner.
  /// Jika Unity belum siap, otomatis pakai StartApp.
  Widget getBannerAdWidget() {
    if (!shouldShowAds) return const SizedBox.shrink();

    final useUnity = _useUnity();
    _logger.d(
        'AdService: Banner — picked ${useUnity ? "Unity" : "StartApp"} (random)');

    if (useUnity) {
      return UnityBannerAd(
        placementId: _bannerPlacementId,
        size: BannerSize.standard,
        onLoad: (id) => _logger.d('UnityBanner: Loaded $id'),
        onShown: (id) => _logger.d('UnityBanner: Shown $id'),
        onClick: (id) => _logger.d('UnityBanner: Clicked $id'),
        onFailed: (id, error, message) {
          _logger.w('UnityBanner: Failed $id ($error: $message)');
          // Widget sudah rendered, tidak bisa fallback in-place.
          // StartApp akan dipilih di pemanggilan getBannerAdWidget() berikutnya.
        },
      );
    }

    _logger.d('AdService: Using StartApp Banner');
    return const KuronBannerAd();
  }

  /// Check if AdGuard DNS is active for non-premium users
  Future<bool> isAdGuardDnsActive() async {
    if (_licenseService.isPremiumActive) return false;
    final dns = await KuronAds.getPrivateDnsServer();
    return dns.toLowerCase().contains('adguard');
  }
}
