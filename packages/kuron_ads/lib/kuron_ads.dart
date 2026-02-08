import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KuronAds {
  static const MethodChannel _channel = MethodChannel('kuron_ads');

  /// Initialize the SDK with App ID
  static Future<void> initialize({required String appId, bool testMode = false}) async {
    await _channel.invokeMethod('initialize', {
      'appId': appId,
      'testMode': testMode,
    });
  }

  /// Trigger an Interstitial Ad
  /// Returns true if command was sent successfully
  static Future<bool> showInterstitial() async {
    try {
      final result = await _channel.invokeMethod('showInterstitial');
      return result == true;
    } catch (e) {
      debugPrint("KuronAds: Failed to show interstitial: $e");
      return false;
    }
  }
}

/// Widget that renders the Native Android Banner View
class KuronBannerAd extends StatelessWidget {
  const KuronBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    // Only Android is supported for now
    if (Theme.of(context).platform != TargetPlatform.android) {
        return const SizedBox.shrink();
    }

    return const SizedBox(
      height: 50,
      width: 320, // Standard banner width
      child: AndroidView(
        viewType: 'kuron_ads/banner',
        creationParams: <String, dynamic>{},
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}
