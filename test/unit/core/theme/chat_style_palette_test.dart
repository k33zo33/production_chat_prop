import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';

void main() {
  group('normalizeChatStyleId', () {
    test('maps legacy style ids to the current preset id', () {
      expect(normalizeChatStyleId('studio_slate'), kDefaultChatStyleId);
    });

    test('falls back to the default preset for unknown style ids', () {
      expect(normalizeChatStyleId('unknown_style'), kDefaultChatStyleId);
    });
  });

  group('resolveChatStylePalette', () {
    test('returns matching preset for known style id', () {
      final palette = resolveChatStylePalette('night_shift');
      expect(palette.id, 'night_shift');
      expect(palette.name, 'Night Shift');
    });

    test('falls back to default for unknown style id', () {
      final palette = resolveChatStylePalette('unknown_style');
      expect(palette.id, kDefaultChatStyleId);
    });

    test('returns the aliased preset for legacy style ids', () {
      final palette = resolveChatStylePalette('studio_slate');
      expect(palette.id, kDefaultChatStyleId);
    });
  });
}
