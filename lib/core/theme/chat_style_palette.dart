import 'package:flutter/material.dart';

const String kDefaultChatStyleId = 'studio_default';

const Map<String, String> kLegacyChatStyleIdAliases = {
  'studio_slate': kDefaultChatStyleId,
};

class ChatStylePalette {
  const ChatStylePalette({
    required this.id,
    required this.name,
    required this.surfaceColor,
    required this.incomingBubbleColor,
    required this.outgoingBubbleColor,
    required this.typingColor,
    required this.chipColor,
    required this.textColor,
  });

  final String id;
  final String name;
  final Color surfaceColor;
  final Color incomingBubbleColor;
  final Color outgoingBubbleColor;
  final Color typingColor;
  final Color chipColor;
  final Color textColor;
}

const List<ChatStylePalette> kChatStylePalettes = [
  ChatStylePalette(
    id: kDefaultChatStyleId,
    name: 'Studio Default',
    surfaceColor: Color(0xFFF8F9FC),
    incomingBubbleColor: Color(0xFFEAF0FF),
    outgoingBubbleColor: Color(0xFFE9F9F0),
    typingColor: Color(0xFFEDEFF5),
    chipColor: Color(0xFFE4E8F2),
    textColor: Color(0xFF1F2430),
  ),
  ChatStylePalette(
    id: 'cleanroom_day',
    name: 'Cleanroom Day',
    surfaceColor: Color(0xFFF6FAFF),
    incomingBubbleColor: Color(0xFFDCEBFF),
    outgoingBubbleColor: Color(0xFFDDF7EE),
    typingColor: Color(0xFFE6EEF8),
    chipColor: Color(0xFFD8E3F0),
    textColor: Color(0xFF162030),
  ),
  ChatStylePalette(
    id: 'night_shift',
    name: 'Night Shift',
    surfaceColor: Color(0xFF101822),
    incomingBubbleColor: Color(0xFF1D2D42),
    outgoingBubbleColor: Color(0xFF173629),
    typingColor: Color(0xFF1A2433),
    chipColor: Color(0xFF243346),
    textColor: Color(0xFFE7EDF6),
  ),
  ChatStylePalette(
    id: 'warm_paper',
    name: 'Warm Paper',
    surfaceColor: Color(0xFFFFF8EE),
    incomingBubbleColor: Color(0xFFFDE6CF),
    outgoingBubbleColor: Color(0xFFE7F4DB),
    typingColor: Color(0xFFF3E7D4),
    chipColor: Color(0xFFE8D9C1),
    textColor: Color(0xFF3A2F23),
  ),
];

String normalizeChatStyleId(String styleId) {
  final trimmedStyleId = styleId.trim();
  if (trimmedStyleId.isEmpty) {
    return kDefaultChatStyleId;
  }

  final aliasedStyleId =
      kLegacyChatStyleIdAliases[trimmedStyleId] ?? trimmedStyleId;
  final hasKnownPreset = kChatStylePalettes.any(
    (style) => style.id == aliasedStyleId,
  );
  if (!hasKnownPreset) {
    return kDefaultChatStyleId;
  }

  return aliasedStyleId;
}

ChatStylePalette resolveChatStylePalette(String styleId) {
  final normalizedStyleId = normalizeChatStyleId(styleId);
  return kChatStylePalettes.firstWhere(
    (style) => style.id == normalizedStyleId,
    orElse: () => kChatStylePalettes.first,
  );
}
