import 'package:flutter/material.dart';

const String kDefaultCharacterBubbleColorHex = '#2E90FA';

class CharacterBubbleColorOption {
  const CharacterBubbleColorOption({
    required this.label,
    required this.hexColor,
  });

  final String label;
  final String hexColor;
}

const List<CharacterBubbleColorOption> kCharacterBubbleColorOptions = [
  CharacterBubbleColorOption(label: 'Azure', hexColor: '#2E90FA'),
  CharacterBubbleColorOption(label: 'Emerald', hexColor: '#12B76A'),
  CharacterBubbleColorOption(label: 'Violet', hexColor: '#9E77ED'),
  CharacterBubbleColorOption(label: 'Amber', hexColor: '#F79009'),
  CharacterBubbleColorOption(label: 'Rose', hexColor: '#F0447C'),
  CharacterBubbleColorOption(label: 'Slate', hexColor: '#667085'),
];

String normalizeCharacterBubbleColorHex(
  String rawColor, {
  String fallback = kDefaultCharacterBubbleColorHex,
}) {
  final normalizedHex = _normalizedHexOrNull(rawColor);
  return normalizedHex ?? fallback;
}

Color resolveCharacterBubbleColor(
  String rawColor, {
  Color fallback = const Color(0xFF2E90FA),
}) {
  final normalizedHex = _normalizedHexOrNull(rawColor);
  if (normalizedHex == null) {
    return fallback;
  }

  final parsedValue = int.tryParse(normalizedHex.substring(1), radix: 16);
  if (parsedValue == null) {
    return fallback;
  }

  if (normalizedHex.length == 7) {
    return Color((0xFF << 24) | parsedValue);
  }

  return Color(parsedValue);
}

Color resolveCharacterBubbleTint({
  required String rawColor,
  required Color baseColor,
  double tintOpacity = 0.24,
}) {
  final accentColor = resolveCharacterBubbleColor(rawColor);
  return Color.alphaBlend(
    accentColor.withValues(alpha: tintOpacity),
    baseColor,
  );
}

String describeCharacterBubbleColor(String rawColor) {
  final normalizedHex = normalizeCharacterBubbleColorHex(rawColor);
  for (final option in kCharacterBubbleColorOptions) {
    if (option.hexColor == normalizedHex) {
      return option.label;
    }
  }
  return normalizedHex;
}

String suggestNextCharacterBubbleColor(Iterable<String> existingColors) {
  final normalizedExistingColors = existingColors
      .map(normalizeCharacterBubbleColorHex)
      .toSet();
  for (final option in kCharacterBubbleColorOptions) {
    if (!normalizedExistingColors.contains(option.hexColor)) {
      return option.hexColor;
    }
  }

  return kCharacterBubbleColorOptions[normalizedExistingColors.length %
          kCharacterBubbleColorOptions.length]
      .hexColor;
}

String? _normalizedHexOrNull(String rawColor) {
  final trimmedColor = rawColor.trim().toUpperCase();
  if (trimmedColor.isEmpty) {
    return null;
  }

  final expandedColor = trimmedColor.startsWith('#')
      ? trimmedColor
      : '#$trimmedColor';
  final hasValidLength = expandedColor.length == 7 || expandedColor.length == 9;
  if (!hasValidLength) {
    return null;
  }
  if (!RegExp(r'^#[0-9A-F]{6}([0-9A-F]{2})?$').hasMatch(expandedColor)) {
    return null;
  }
  return expandedColor;
}
