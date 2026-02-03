import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/services/license_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseCheckDialog extends StatefulWidget {
  const LicenseCheckDialog({super.key});

  @override
  State<LicenseCheckDialog> createState() => _LicenseCheckDialogState();
}

class _LicenseCheckDialogState extends State<LicenseCheckDialog> {
  final _licenseController = TextEditingController();
  final _licenseService = getIt<LicenseService>();
  bool _isLoading = false;
  String? _message;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLicense();
  }

  Future<void> _loadSavedLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('komiktap_license_key');
    if (savedKey != null) {
      _licenseController.text = savedKey;
    }
    
    // Check if already active
    if (_licenseService.isPremiumActive) {
      if (mounted) {
        setState(() {
          _isValid = true;
          final exp = _licenseService.expiresAt;
          final plan = _licenseService.planName ?? 'Premium';
          final l10n = AppLocalizations.of(context)!;
          
          if (exp != null) {
            final dateStr = DateFormat('dd MMM yyyy').format(exp);
            _message = l10n.currentSubscription(plan, dateStr);
          } else {
            _message = l10n.currentSubscriptionLifetime(plan);
          }
        });
      }
    }
  }

  Future<void> _checkLicense() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      String deviceId = 'unknown';
      String deviceName = 'Generic Android Device';

      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      }

      final result = await _licenseService.checkLicense(key, deviceId, deviceName);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValid = result['valid'] == true;
          
          if (_isValid) {
             final exp = _licenseService.expiresAt;
             final plan = _licenseService.planName ?? 'Premium';
             final l10n = AppLocalizations.of(context)!;
             
             if (exp != null) {
               final dateStr = DateFormat('dd MMM yyyy').format(exp);
               _message = l10n.currentSubscription(plan, dateStr);
             } else {
               _message = l10n.currentSubscriptionLifetime(plan);
             }
          } else {
             _message = result['message'];
          }
        });

        if (_isValid) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('komiktap_license_key', key);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValid = false;
          _message = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cek Lisensi KomikTap'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _licenseController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
              UpperCaseTextFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'License Key',
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_message != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isValid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _isValid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_isValid)
          TextButton(
            onPressed: () async {
              await _licenseService.removeLicense();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('komiktap_license_key');
              
              if (mounted) {
                setState(() {
                  _isValid = false;
                  _message = 'License removed. You are now on Standard plan.';
                  _licenseController.clear();
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove License'),
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _checkLicense,
          child: const Text('Check'),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
