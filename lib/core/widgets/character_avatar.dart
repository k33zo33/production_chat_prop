import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/character_bubble_colors.dart';

class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.displayName,
    required this.bubbleColor,
    super.key,
    this.avatarPath,
    this.radius = 11,
  });

  final String displayName;
  final String bubbleColor;
  final String? avatarPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarPath = _normalizedAvatarPath(avatarPath);
    final avatarImage = _resolveAvatarImage(resolvedAvatarPath);
    final outlineColor = resolveCharacterBubbleColor(bubbleColor);
    final initials = _buildInitials(displayName);
    final avatar = Container(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: outlineColor, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: outlineColor.withValues(alpha: 0.16),
        foregroundImage: avatarImage,
        onForegroundImageError: avatarImage == null
            ? null
            : (exception, stackTrace) {},
        child: Text(
          initials,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (resolvedAvatarPath == null) {
      return avatar;
    }

    return Tooltip(
      message: _avatarTooltip(resolvedAvatarPath),
      child: avatar,
    );
  }
}

String? _normalizedAvatarPath(String? avatarPath) {
  final trimmed = avatarPath?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

ImageProvider<Object>? _resolveAvatarImage(String? avatarPath) {
  if (avatarPath == null) {
    return null;
  }

  final uri = Uri.tryParse(avatarPath);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(avatarPath);
  }

  if (avatarPath.startsWith('data:image/')) {
    final commaIndex = avatarPath.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= avatarPath.length - 1) {
      return null;
    }

    final metadata = avatarPath.substring(0, commaIndex);
    if (!metadata.contains(';base64')) {
      return null;
    }

    try {
      final bytes = base64Decode(avatarPath.substring(commaIndex + 1));
      return MemoryImage(bytes);
    } on FormatException {
      return null;
    }
  }

  return null;
}

String _buildInitials(String displayName) {
  final segments = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  if (segments.isEmpty) {
    return '?';
  }

  if (segments.length == 1) {
    return _firstSymbol(segments.first).toUpperCase();
  }

  return '${_firstSymbol(segments.first)}${_firstSymbol(segments.last)}'
      .toUpperCase();
}

String _firstSymbol(String value) {
  if (value.isEmpty) {
    return '?';
  }

  return value.characters.first;
}

String _avatarTooltip(String avatarPath) {
  final uri = Uri.tryParse(avatarPath);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return 'Avatar source: remote image URL';
  }
  if (avatarPath.startsWith('data:image/')) {
    return 'Avatar source: embedded image data';
  }
  return 'Avatar reference: $avatarPath';
}
