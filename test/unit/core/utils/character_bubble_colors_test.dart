import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/character_bubble_colors.dart';

void main() {
  group('normalizeCharacterBubbleColorHex', () {
    test('normalizes trimmed lowercase values and prefixes missing hash', () {
      expect(normalizeCharacterBubbleColorHex(' 2e90fa '), '#2E90FA');
    });

    test('keeps 8-digit hex values when valid', () {
      expect(normalizeCharacterBubbleColorHex('802e90fa'), '#802E90FA');
    });

    test('falls back for empty or invalid values', () {
      expect(normalizeCharacterBubbleColorHex(''), '#2E90FA');
      expect(normalizeCharacterBubbleColorHex('#xyz123'), '#2E90FA');
      expect(
        normalizeCharacterBubbleColorHex('#xyz123', fallback: '#12B76A'),
        '#12B76A',
      );
    });
  });

  group('resolveCharacterBubbleColor', () {
    test('resolves 6-digit hex colors as opaque colors', () {
      expect(resolveCharacterBubbleColor('#12b76a'), const Color(0xFF12B76A));
    });

    test('resolves 8-digit hex colors with embedded alpha', () {
      expect(resolveCharacterBubbleColor('802E90FA'), const Color(0x802E90FA));
    });

    test('falls back when the color cannot be parsed', () {
      expect(
        resolveCharacterBubbleColor('not-a-color', fallback: Colors.orange),
        Colors.orange,
      );
    });
  });

  group('resolveCharacterBubbleTint', () {
    test('blends the normalized accent color over the provided base color', () {
      final expectedTint = Color.alphaBlend(
        const Color(0xFF12B76A).withValues(alpha: 0.5),
        Colors.black,
      );

      expect(
        resolveCharacterBubbleTint(
          rawColor: '12b76a',
          baseColor: Colors.black,
          tintOpacity: 0.5,
        ),
        expectedTint,
      );
    });
  });

  group('describeCharacterBubbleColor', () {
    test('returns the palette label for known preset colors', () {
      expect(describeCharacterBubbleColor(' #f0447c '), 'Rose');
    });

    test('returns the normalized hex when the color is custom', () {
      expect(describeCharacterBubbleColor('#123456'), '#123456');
    });
  });

  group('suggestNextCharacterBubbleColor', () {
    test('returns the first unused preset after normalizing existing values', () {
      expect(
        suggestNextCharacterBubbleColor(['2e90fa', '#12b76a', ' #9e77ed ']),
        '#F79009',
      );
    });

    test('wraps through the palette once every preset is already used', () {
      expect(
        suggestNextCharacterBubbleColor(
          kCharacterBubbleColorOptions.map((option) => option.hexColor),
        ),
        '#2E90FA',
      );
    });

    test('deduplicates normalized colors before choosing the next preset', () {
      expect(
        suggestNextCharacterBubbleColor(['#2E90FA', '2e90fa', '']),
        '#12B76A',
      );
    });
  });
}
