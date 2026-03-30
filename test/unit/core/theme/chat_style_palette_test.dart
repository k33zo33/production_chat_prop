import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';

void main() {
  group('resolveChatStylePalette', () {
    test('returns matching preset for known style id', () {
      final palette = resolveChatStylePalette('night_shift');
      expect(palette.id, 'night_shift');
      expect(palette.name, 'Night Shift');
    });

    test('falls back to default for unknown style id', () {
      final palette = resolveChatStylePalette('unknown_style');
      expect(palette.id, 'studio_default');
    });
  });
}
