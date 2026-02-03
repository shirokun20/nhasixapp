import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  final Dio _dio;
  final Logger _logger;
  final RemoteConfigService _remoteConfigService;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // Prefs keys (Sync Cache)
  static const String _prefKeyLicenseValid = 'komiktap_license_valid';
  static const String _prefKeyMaxDevices = 'komiktap_max_devices';

  // Secure Storage Keys (Source of Truth)
  static const String _secureKeyLicenseKey = 'komiktap_license_key';
  static const String _secureKeyExpiresAt = 'komiktap_expires_at';
  static const String _secureKeyDeviceId = 'komiktap_device_id';
  static const String _secureKeyDeviceName = 'komiktap_device_name';
  static const String _secureKeyIsValid = 'komiktap_is_valid';
  static const String _secureKeyPlanName = 'komiktap_plan_name';

  // In-Memory State
  bool _isPremiumActive = false;
  DateTime? _expiresAt;
  String? _planName;
  int _maxDevices = 3;

  LicenseService({
    required Dio dio,
    required Logger logger,
    required RemoteConfigService remoteConfigService,
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _logger = logger,
        _remoteConfigService = remoteConfigService,
        _prefs = prefs,
        _secureStorage = secureStorage {
    // Optimistic Load from Prefs (Sync) to avoid flicker/race on Hot Restart
    _isPremiumActive = _prefs.getBool(_prefKeyLicenseValid) ?? false;
    _planName = _prefs.getString('komiktap_plan_name_cache');
    final expStr = _prefs.getString('komiktap_expires_at_cache');
    if (expStr != null) {
      _expiresAt = DateTime.tryParse(expStr);
    }
  }

  /// Initialize service logic: load secure state and revalidate
  Future<void> initialize() async {
    try {
      _logger.d('Initializing LicenseService...');
      
      // 1. Load from Secure Storage
      final isValidStr = await _secureStorage.read(key: _secureKeyIsValid);
      final expiresAtStr = await _secureStorage.read(key: _secureKeyExpiresAt);
      final key = await _secureStorage.read(key: _secureKeyLicenseKey);
      _planName = await _secureStorage.read(key: _secureKeyPlanName);
      
      // 2. Parse Expiry
      if (expiresAtStr != null) {
        _expiresAt = DateTime.tryParse(expiresAtStr);
      }

      // 3. Local Validation (Expiry Check)
      bool isValid = isValidStr == 'true';
      if (isValid && _expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
        _logger.w('License expired locally. Revoking.');
        isValid = false;
        await _revokeLicenseLocally();
      } else {
        _isPremiumActive = isValid;
      }
      
      // 4. Sync cache to prefs (Anti-bypass sync)
      await _syncToPrefs();

      // 5. Background Revalidation if valid
      if (isValid && key != null) {
        _revalidateInBackground(key);
      }
    } catch (e) {
      _logger.e('LicenseService init failed', error: e);
    }
  }

  Future<void> _syncToPrefs() async {
    await _prefs.setBool(_prefKeyLicenseValid, _isPremiumActive);
    if (_planName != null) {
      await _prefs.setString('komiktap_plan_name_cache', _planName!);
    } else {
      await _prefs.remove('komiktap_plan_name_cache');
    }
    
    if (_expiresAt != null) {
      await _prefs.setString('komiktap_expires_at_cache', _expiresAt!.toIso8601String());
    } else {
      await _prefs.remove('komiktap_expires_at_cache');
    }
  }

  Future<void> _revokeLicenseLocally() async {
    _isPremiumActive = false;
    await _secureStorage.write(key: _secureKeyIsValid, value: 'false');
    await _syncToPrefs();
  }

  Future<void> removeLicense() async {
    _planName = null;
    await _secureStorage.delete(key: _secureKeyPlanName);
    await _revokeLicenseLocally();
    _logger.i('License removed by user.');
  }

  Future<void> _revalidateInBackground(String key) async {
    try {
      final deviceId = await _secureStorage.read(key: _secureKeyDeviceId) ?? 'unknown';
      final deviceName = await _secureStorage.read(key: _secureKeyDeviceName) ?? 'unknown'; // fallback

      _logger.d('Revalidating license in background...');
      final result = await checkLicense(key, deviceId, deviceName, isBackground: true);
      
      if (result['valid'] == false) {
        _logger.w('License revalidation failed: ${result['message']}');
        // Revoke if server explicitly says invalid (403/200 success=false)
        // If connection error, we KEEP the local valid state (grace period)
        if (result['server_responded'] == true) {
             await _revokeLicenseLocally();
        }
      } else {
        _logger.d('License revalidated successfully.');
      }
    } catch (e) {
       _logger.e('Revalidation error', error: e);
    }
  }

  Future<Map<String, dynamic>> checkLicense(
      String licenseKey, String deviceId, String deviceName, {bool isBackground = false}) async {
    final endpoint = _remoteConfigService.appConfig?.featureFlags?['premium']
            ?['activation']?['validateEndpoint'] ??
        'http://192.168.0.7:8000/api/check-license';

    try {
      if (!isBackground) _logger.d('Checking license: $licenseKey at $endpoint');
      
      final response = await _dio.post(
        endpoint,
        data: {
          'license_key': licenseKey,
          'device_id': deviceId,
          'device_name': deviceName,
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      final dynamic responseData = response.data is String 
          ? jsonDecode(response.data as String) 
          : response.data;
      
      if (response.statusCode == 200 && responseData is Map && responseData['status'] == 'success') {
        final data = responseData['data'];
        final maxDevices = data['max_devices'] as int?;
        final expiresAt = data['expires_at'] as String?;
        final planName = data['plan_name'] as String?;

        // Update State
        _isPremiumActive = true;
        if (maxDevices != null) {
          _maxDevices = maxDevices;
          await _prefs.setInt(_prefKeyMaxDevices, maxDevices);
        }
        if (expiresAt != null) {
          _expiresAt = DateTime.tryParse(expiresAt);
        }
        _planName = planName;

        // Secure Persist
        await Future.wait([
          _secureStorage.write(key: _secureKeyLicenseKey, value: licenseKey),
          _secureStorage.write(key: _secureKeyDeviceId, value: deviceId),
          _secureStorage.write(key: _secureKeyDeviceName, value: deviceName),
          _secureStorage.write(key: _secureKeyIsValid, value: 'true'),
          if (expiresAt != null) _secureStorage.write(key: _secureKeyExpiresAt, value: expiresAt),
          if (planName != null) _secureStorage.write(key: _secureKeyPlanName, value: planName),
        ]);
        
        await _syncToPrefs();
        
        return {
          'valid': true,
          'message': data['message'] ?? 'License active',
          'max_devices': maxDevices, 
          'data': data,
          'server_responded': true,
        };
      } else {
        // Explicit failure
        if (!isBackground) await _revokeLicenseLocally();
        
        final msg = (responseData is Map) ? responseData['message'] : 'Invalid license';
        
        return {
          'valid': false,
          'message': msg ?? 'Invalid license',
          'server_responded': true,
        };
      }
    } catch (e) {
      if (!isBackground) _logger.e('License check failed', error: e);
      return {
        'valid': false,
        'message': 'Connection error: ${e.toString()}',
        'server_responded': false, // Connection issue
      };
    }
  }

  /// Verifies if a feature is accessible based on premium status
  bool isFeatureAccessible(bool requiresPremium) {
    if (!requiresPremium) return true;
    // Check purely in-memory (synced from SecureStorage on init)
    // Double check expiry just in case app has been running for days
    if (_isPremiumActive && _expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
        // Lazy revocation
        _revokeLicenseLocally(); 
        return false;
    }
    return _isPremiumActive;
  }
  
  bool get isPremiumActive => isFeatureAccessible(true);
  
  int get maxDevices => _maxDevices;
  DateTime? get expiresAt => _expiresAt;
  String? get planName => _planName;
}
