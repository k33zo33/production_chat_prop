import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('summarizeSceneHealth', () {
    test('flags staged characters that have no lines yet', () {
      const scene = Scene(
        id: 'scene-1',
        title: 'Blocking Pass',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Taylor',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: 'character-2',
            displayName: 'Jordan',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
        ],
        messages: [
          Message(
            id: 'message-1',
            characterId: 'character-1',
            text: 'Lead line is blocked in.',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      );

      final summary = summarizeSceneHealth(scene);

      expect(summary.messageCount, 1);
      expect(summary.hasMessages, isTrue);
      expect(summary.unusedCharacterNames, ['Jordan']);
      expect(summary.statusLabel, '1 character waiting for lines');
      expect(summary.detailLabel, 'Jordan has no lines in this scene yet.');
      expect(summary.needsAttention, isTrue);
    });

    test('prioritizes empty-scene recovery messaging before unused characters', () {
      const scene = Scene(
        id: 'scene-2',
        title: 'Empty setup',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Mia',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [],
      );

      final summary = summarizeSceneHealth(scene);

      expect(summary.hasMessages, isFalse);
      expect(summary.unusedCharacterCount, 1);
      expect(summary.statusLabel, 'No messages yet');
      expect(
        summary.detailLabel,
        'Add at least one message before preview or export.',
      );
      expect(summary.needsAttention, isTrue);
    });
  });

  group('summarizeProjectHealth', () {
    test('aggregates empty scenes and staged characters across a project', () {
      final project = Project(
        id: 'project-1',
        name: 'Launch Spot',
        type: ProjectType.ad,
        createdAt: DateTime.utc(2026, 5, 1, 9),
        updatedAt: DateTime.utc(2026, 5, 1, 10),
        scenes: const [
          Scene(
            id: 'scene-empty',
            title: 'Cold open',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Mia',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
            ],
            messages: [],
          ),
          Scene(
            id: 'scene-staged',
            title: 'Reply cue',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Mia',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
              Character(
                id: 'character-2',
                displayName: 'Jordan',
                avatarPath: null,
                bubbleColor: '#12B76A',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'Camera is rolling.',
                timestampSeconds: 2,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: false,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.totalScenes, 2);
      expect(summary.readyScenes, 1);
      expect(summary.emptyScenes, 1);
      expect(summary.totalMessages, 1);
      expect(summary.unusedCharacterCount, 1);
      expect(summary.scenesWithUnusedCharacters, 1);
      expect(summary.firstEmptySceneId, 'scene-empty');
      expect(summary.firstSceneWithUnusedCharactersId, 'scene-staged');
      expect(summary.firstAttentionSceneId, 'scene-empty');
      expect(summary.needsAttention, isTrue);
    });

    test('marks fully covered projects as ready', () {
      final project = Project(
        id: 'project-2',
        name: 'Ready Scene',
        type: ProjectType.series,
        createdAt: DateTime.utc(2026, 5, 1, 9),
        updatedAt: DateTime.utc(2026, 5, 1, 10),
        scenes: const [
          Scene(
            id: 'scene-ready',
            title: 'Take one',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Taylor',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'We are good to go.',
                timestampSeconds: 0,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: false,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.readyScenes, 1);
      expect(summary.emptyScenes, 0);
      expect(summary.unusedCharacterCount, 0);
      expect(summary.firstAttentionSceneId, isNull);
      expect(summary.needsAttention, isFalse);
    });
  });
}
