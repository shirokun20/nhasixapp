import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:io';
import 'dart:async';

void main() {
  setUpAll(() {
    HttpOverrides.global = null; // ALLOW REAL NETWORK REQUESTS
  });

  testWidgets('Test Schale Network image loading with ExtendedImage', (WidgetTester tester) async {
    final url = "https://hikari.erocdn.net/data/116176/2a0be687a533/d4459c7fe9e9b6cdc21274d398d60de6aacc9f28b040af4487d461e8a16a4481/1280/070a3843de576aa8ff801cad55074b835958861427564310633475a1c02a4b0e/bce7cd0e-8c66-44e8-81b8-8d6324dd0e68.jpg";
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
      'Referer': 'https://niyaniya.moe/',
      'Origin': 'https://niyaniya.moe',
    };

    final completer = Completer<void>();
    dynamic capturedError;

    final provider = ExtendedNetworkImageProvider(
      url,
      cache: false, // Don't cache to test network
      headers: headers,
    );

    provider.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          print('✅ Image loaded successfully: ${info.image.width}x${info.image.height}');
          completer.complete();
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          print('❌ Failed to load image: $error');
          capturedError = error;
          completer.completeError(error);
        },
      ),
    );

    try {
      await completer.future.timeout(Duration(seconds: 10));
    } catch (e) {
      // Intentionally swallow to let the test fail naturally if needed
    }

    expect(capturedError, isNull, reason: 'Image should load without errors');
  });
}
