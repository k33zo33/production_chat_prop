import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:uuid/uuid.dart';

class ProjectSanitizer {
  ProjectSanitizer({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Project sanitizeProject(Project source) {
    final sanitizedScenes = <Scene>[];
    final sourceScenes = source.scenes;
    if (sourceScenes.isEmpty) {
      sanitizedScenes.add(_buildFallbackScene(title: 'Scene 1'));
    } else {
      for (var i = 0; i < sourceScenes.length; i++) {
        sanitizedScenes.add(
          _sanitizeScene(sourceScenes[i], fallbackTitle: 'Scene ${i + 1}'),
        );
      }
    }

    final trimmedName = source.name.trim();
    return Project(
      id: _normalizeId(source.id),
      name: trimmedName.isEmpty ? 'Imported Project' : trimmedName,
      type: source.type,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      scenes: sanitizedScenes,
    );
  }

  Scene _sanitizeScene(Scene source, {required String fallbackTitle}) {
    final characterIdMap = <String, String>{};
    final usedCharacterIds = <String>{};
    final sanitizedCharacters = <Character>[];

    for (var i = 0; i < source.characters.length; i++) {
      final character = source.characters[i];
      final normalizedId = _normalizeUniqueId(
        rawId: character.id,
        usedIds: usedCharacterIds,
      );
      if (!characterIdMap.containsKey(character.id)) {
        characterIdMap[character.id] = normalizedId;
      }
      sanitizedCharacters.add(
        Character(
          id: normalizedId,
          displayName: _normalizeCharacterName(
            character.displayName,
            fallbackIndex: i + 1,
          ),
          avatarPath: character.avatarPath,
          bubbleColor: _normalizeBubbleColor(character.bubbleColor),
        ),
      );
    }

    if (sanitizedCharacters.isEmpty) {
      final fallbackCharacter = _buildFallbackCharacter(labelIndex: 1);
      sanitizedCharacters.add(fallbackCharacter);
      characterIdMap[''] = fallbackCharacter.id;
    }

    final fallbackCharacterId = sanitizedCharacters.first.id;
    final usedMessageIds = <String>{};
    final sanitizedMessages = <Message>[];

    for (final message in source.messages) {
      final trimmedText = message.text.trim();
      if (trimmedText.isEmpty) {
        continue;
      }

      sanitizedMessages.add(
        Message(
          id: _normalizeUniqueId(rawId: message.id, usedIds: usedMessageIds),
          characterId:
              characterIdMap[message.characterId] ?? fallbackCharacterId,
          text: trimmedText,
          timestampSeconds: message.timestampSeconds < 0
              ? 0
              : message.timestampSeconds,
          status: message.status,
          isIncoming: message.isIncoming,
          showTypingBefore: message.showTypingBefore,
        ),
      );
    }

    final trimmedTitle = source.title.trim();
    final trimmedStyleId = source.styleId.trim();
    return Scene(
      id: _normalizeId(source.id),
      title: trimmedTitle.isEmpty ? fallbackTitle : trimmedTitle,
      characters: sanitizedCharacters,
      messages: sortMessagesByTimeline(sanitizedMessages),
      styleId: trimmedStyleId.isEmpty ? 'studio_slate' : trimmedStyleId,
      aspectRatio: source.aspectRatio,
    );
  }

  Scene _buildFallbackScene({required String title}) {
    final fallbackCharacter = _buildFallbackCharacter(labelIndex: 1);
    return Scene(
      id: _uuid.v4(),
      title: title,
      characters: [fallbackCharacter],
      messages: const [],
      styleId: 'studio_slate',
      aspectRatio: SceneAspectRatio.portrait9x16,
    );
  }

  Character _buildFallbackCharacter({required int labelIndex}) {
    return Character(
      id: _uuid.v4(),
      displayName: 'Character $labelIndex',
      avatarPath: null,
      bubbleColor: '#2E90FA',
    );
  }

  String _normalizeCharacterName(String rawName, {required int fallbackIndex}) {
    final trimmedName = rawName.trim();
    if (trimmedName.isEmpty) {
      return 'Character $fallbackIndex';
    }
    return trimmedName;
  }

  String _normalizeBubbleColor(String rawColor) {
    final trimmedColor = rawColor.trim();
    if (trimmedColor.isEmpty) {
      return '#2E90FA';
    }
    return trimmedColor;
  }

  String _normalizeId(String rawId) {
    final trimmedId = rawId.trim();
    if (trimmedId.isEmpty) {
      return _uuid.v4();
    }
    return trimmedId;
  }

  String _normalizeUniqueId({
    required String rawId,
    required Set<String> usedIds,
  }) {
    final normalizedId = _normalizeId(rawId);
    if (usedIds.add(normalizedId)) {
      return normalizedId;
    }

    while (true) {
      final generatedId = _uuid.v4();
      if (usedIds.add(generatedId)) {
        return generatedId;
      }
    }
  }
}
