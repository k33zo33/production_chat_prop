import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/features/projects/data/services/project_sanitizer.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('ProjectSanitizer', () {
    final sanitizer = ProjectSanitizer();

    test('adds fallback scene and project name when source is blank', () {
      final sanitized = sanitizer.sanitizeProject(
        Project(
          id: '   ',
          name: '   ',
          type: ProjectType.other,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          scenes: const [],
        ),
      );

      expect(sanitized.id, isNotEmpty);
      expect(sanitized.name, 'Imported Project');
      expect(sanitized.scenes, hasLength(1));
      expect(sanitized.scenes.first.id, isNotEmpty);
      expect(sanitized.scenes.first.title, 'Scene 1');
      expect(sanitized.scenes.first.styleId, kDefaultChatStyleId);
      expect(sanitized.scenes.first.aspectRatio, SceneAspectRatio.portrait9x16);
      expect(sanitized.scenes.first.characters, hasLength(1));
      expect(
        sanitized.scenes.first.characters.first.displayName,
        'Character 1',
      );
      expect(sanitized.scenes.first.messages, isEmpty);
    });

    test('normalizes duplicate ids and orphaned messages inside a scene', () {
      final sanitized = sanitizer.sanitizeProject(
        Project(
          id: 'project-1',
          name: ' Imported ',
          type: ProjectType.ad,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          scenes: const [
            Scene(
              id: '   ',
              title: '   ',
              styleId: 'unknown_style',
              aspectRatio: SceneAspectRatio.landscape16x9,
              characters: [
                Character(
                  id: 'dup-character',
                  displayName: '   ',
                  avatarPath: null,
                  bubbleColor: '   ',
                ),
                Character(
                  id: 'dup-character',
                  displayName: 'Mia',
                  avatarPath: null,
                  bubbleColor: '#12B76A',
                ),
              ],
              messages: [
                Message(
                  id: 'dup-message',
                  characterId: 'dup-character',
                  text: ' Later ',
                  timestampSeconds: 4,
                  status: MessageStatus.delivered,
                  isIncoming: true,
                  showTypingBefore: false,
                ),
                Message(
                  id: 'dup-message',
                  characterId: 'missing-character',
                  text: ' Early ',
                  timestampSeconds: -1,
                  status: MessageStatus.sent,
                  isIncoming: false,
                  showTypingBefore: true,
                ),
                Message(
                  id: 'blank-text',
                  characterId: 'dup-character',
                  text: '   ',
                  timestampSeconds: 9,
                  status: MessageStatus.seen,
                  isIncoming: false,
                  showTypingBefore: false,
                ),
              ],
            ),
          ],
        ),
      );

      final scene = sanitized.scenes.first;
      final characterIds = scene.characters
          .map((character) => character.id)
          .toList();
      final messageIds = scene.messages.map((message) => message.id).toList();

      expect(sanitized.name, 'Imported');
      expect(scene.id, isNotEmpty);
      expect(scene.title, 'Scene 1');
      expect(scene.styleId, kDefaultChatStyleId);
      expect(scene.aspectRatio, SceneAspectRatio.landscape16x9);
      expect(scene.characters, hasLength(2));
      expect(characterIds.toSet(), hasLength(2));
      expect(scene.characters.first.displayName, 'Character 1');
      expect(scene.characters.first.bubbleColor, '#2E90FA');
      expect(scene.characters.last.displayName, 'Mia');
      expect(scene.messages, hasLength(2));
      expect(scene.messages.map((message) => message.text), ['Early', 'Later']);
      expect(scene.messages.map((message) => message.timestampSeconds), [0, 4]);
      expect(messageIds.toSet(), hasLength(2));
      expect(
        scene.messages.every(
          (message) => characterIds.contains(message.characterId),
        ),
        isTrue,
      );
    });

    test('assigns unique scene ids across imported scenes', () {
      final sanitized = sanitizer.sanitizeProject(
        Project(
          id: 'project-1',
          name: 'Imported',
          type: ProjectType.other,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          scenes: const [
            Scene(
              id: 'scene-dup',
              title: 'Scene A',
              styleId: 'studio_default',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [],
              messages: [],
            ),
            Scene(
              id: 'scene-dup',
              title: 'Scene B',
              styleId: 'night_shift',
              aspectRatio: SceneAspectRatio.landscape16x9,
              characters: [],
              messages: [],
            ),
            Scene(
              id: '   ',
              title: 'Scene C',
              styleId: 'studio_default',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [],
              messages: [],
            ),
          ],
        ),
      );

      final sceneIds = sanitized.scenes.map((scene) => scene.id).toList();

      expect(sceneIds, hasLength(3));
      expect(sceneIds.toSet(), hasLength(3));
      expect(sceneIds.first, 'scene-dup');
      expect(sceneIds.skip(1).every((id) => id.isNotEmpty), isTrue);
    });

    test('maps legacy style ids to the current preset id', () {
      final sanitized = sanitizer.sanitizeProject(
        Project(
          id: 'project-legacy-style',
          name: 'Imported',
          type: ProjectType.other,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          scenes: const [
            Scene(
              id: 'scene-1',
              title: 'Scene 1',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [],
              messages: [],
            ),
          ],
        ),
      );

      expect(sanitized.scenes.first.styleId, kDefaultChatStyleId);
    });
  });
}
