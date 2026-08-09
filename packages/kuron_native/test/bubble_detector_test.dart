import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:kuron_native/kuron_native_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('kuron_native');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'detectBubbles') {
        return [
          {
            'x': 10,
            'y': 20,
            'w': 100,
            'h': 50,
            'confidence': 0.87,
            'kind': 'balloon',
            'shape': [
              [10, 20],
              [110, 20],
              [110, 70],
              [10, 70],
            ],
          },
          {'x': 200, 'y': 300, 'w': 80, 'h': 60, 'confidence': 0.31},
        ];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('detectBubbles returns List<Map> with correct fields', () async {
    final methodChannel = MethodChannelKuronNative();
    final result = await methodChannel.detectBubbles(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 1000,
      imageHeight: 1500,
    );

    expect(result, isNotNull);
    expect(result!.length, 2);
    expect(result.first['x'], 10);
    expect(result.first['y'], 20);
    expect(result.first['w'], 100);
    expect(result.first['h'], 50);
    expect(result.first['confidence'], 0.87);
  });

  test('KuronNative.detectBubbles parses maps into BubbleBox objects',
      () async {
    final result = await KuronNative.instance.detectBubbles(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageWidth: 1000,
      imageHeight: 1500,
    );

    expect(result, isNotNull);
    expect(result, isA<List<BubbleBox>>());
    expect(result![1].confidence, 0.31);
    expect(result[1].toString(), contains('BubbleBox'));

    // shape + kind parsed (task 3.1)
    expect(result[0].kind, 'balloon');
    expect(result[0].shape, isNotNull);
    expect(result[0].shape!.length, 4);
    expect(result[0].shapeOffsets, isNotNull);
    expect(result[0].shapeOffsets!.length, 4);
    expect(result[1].shape, isNull); // no shape → null (box fallback)
  });

  test('detectBubbles returns null on platform null response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    final result = await KuronNative.instance.detectBubbles(
      imageBytes: Uint8List.fromList([1]),
      imageWidth: 10,
      imageHeight: 10,
    );

    expect(result, isNull);
  });
}
