import 'dart:math' as math;

import 'package:flutter/material.dart';
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

    test('keeps preset names and ids brand-neutral', () {
      const forbiddenLabels = <String>[
        'whatsapp',
        'messenger',
        'telegram',
        'instagram',
        'signal',
        'imessage',
      ];

      for (final palette in kChatStylePalettes) {
        final normalizedId = palette.id.toLowerCase();
        final normalizedName = palette.name.toLowerCase();

        for (final forbiddenLabel in forbiddenLabels) {
          expect(normalizedId, isNot(contains(forbiddenLabel)));
          expect(normalizedName, isNot(contains(forbiddenLabel)));
        }
      }
    });

    test('keeps text contrast readable across every chat surface', () {
      for (final palette in kChatStylePalettes) {
        final contrastPairs = <String, Color>{
          'surface': palette.surfaceColor,
          'incoming bubble': palette.incomingBubbleColor,
          'outgoing bubble': palette.outgoingBubbleColor,
          'typing cue': palette.typingColor,
          'chip': palette.chipColor,
        };

        for (final entry in contrastPairs.entries) {
          final ratio = _contrastRatio(entry.value, palette.textColor);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${palette.name} ${entry.key} contrast should stay beta-readable.',
          );
        }
      }
    });
  });
}

double _contrastRatio(Color background, Color foreground) {
  final backgroundLuminance = background.computeLuminance();
  final foregroundLuminance = foreground.computeLuminance();
  final lighter = math.max(backgroundLuminance, foregroundLuminance);
  final darker = math.min(backgroundLuminance, foregroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
