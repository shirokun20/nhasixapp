import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';

void main() {
  group('AiModelOption', () {
    test('isVision null means unknown (no badge)', () {
      const opt = AiModelOption(id: 'some-model', isVision: null);
      expect(opt.isVision, isNull);
      expect(opt.displayLabel, 'some-model');
    });

    test('label falls back to id', () {
      const opt = AiModelOption(id: 'kimi-k2.6', isVision: true);
      expect(opt.displayLabel, 'kimi-k2.6');
    });
  });

  group('AiProviderType.modelsUrl', () {
    test('custom has no listing endpoint', () {
      expect(AiProviderType.custom.modelsUrl, isNull);
    });

    test('all non-custom types have listing endpoints', () {
      for (final t in AiProviderType.values) {
        if (t == AiProviderType.custom) continue;
        expect(t.modelsUrl, isNotNull, reason: t.name);
      }
    });

    test('openAi and gemini need key for listing', () {
      expect(AiProviderType.openAi.needsKeyForListing, true);
      expect(AiProviderType.gemini.needsKeyForListing, true);
      expect(AiProviderType.zen.needsKeyForListing, false);
      expect(AiProviderType.openCodeGo.needsKeyForListing, false);
      expect(AiProviderType.openRouter.needsKeyForListing, false);
    });
  });

  group('AiProviderConfig.isVisionCapable', () {
    test('empty model is never capable', () {
      const c = AiProviderConfig(
          id: 'x', displayName: 'X', type: AiProviderType.zen, model: '');
      expect(c.isVisionCapable, false);
    });

    test('stored LOV flag wins', () {
      const vision = AiProviderConfig(
          id: 'x',
          displayName: 'X',
          type: AiProviderType.zen,
          model: 'any',
          modelIsVision: true);
      const text = AiProviderConfig(
          id: 'x',
          displayName: 'X',
          type: AiProviderType.zen,
          model: 'any',
          modelIsVision: false);
      expect(vision.isVisionCapable, true);
      expect(text.isVisionCapable, false);
    });

    test('unknown flag defaults to capable', () {
      const c = AiProviderConfig(
          id: 'x', displayName: 'X', type: AiProviderType.zen, model: 'any');
      expect(c.isVisionCapable, true);
    });
  });
}
