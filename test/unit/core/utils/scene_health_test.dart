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
      expect(summary.hasTimelineWarnings, isFalse);
      expect(summary.sharedTimestampCount, 0);
      expect(summary.overlappingTypingCueCount, 0);
      expect(summary.needsAttention, isTrue);
    });

    test(
      'prioritizes empty-scene recovery messaging before unused characters',
      () {
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
        expect(summary.hasTimelineWarnings, isFalse);
        expect(summary.needsAttention, isTrue);
      },
    );

    test('surfaces shared timestamp and overlapping typing QA warnings', () {
      const scene = Scene(
        id: 'scene-qa',
        title: 'Playback stack',
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
            text: 'Cue one',
            timestampSeconds: 4,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: true,
          ),
          Message(
            id: 'message-2',
            characterId: 'character-2',
            text: 'Cue two',
            timestampSeconds: 4,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: 'message-3',
            characterId: 'character-1',
            text: 'Cue three',
            timestampSeconds: 7,
            status: MessageStatus.seen,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      );

      final summary = summarizeSceneHealth(scene);

      expect(summary.hasTimelineWarnings, isTrue);
      expect(summary.sharedTimestampCount, 1);
      expect(summary.sharedTimestampMessageCount, 2);
      expect(summary.overlappingTypingCueCount, 1);
      expect(
        summary.timelineStatusLabel,
        '1 shared timestamp • 1 overlapping typing cue',
      );
      expect(
        summary.timelineDetailLabel,
        '2 messages land on the same second and can stack in playback or export. '
        'Multiple typing indicators fire together and may feel crowded in compact previews.',
      );
      expect(summary.needsAttention, isFalse);
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
      expect(summary.sharedTimestampCount, 0);
      expect(summary.overlappingTypingCueCount, 0);
      expect(summary.scenesWithTimelineWarnings, 0);
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
      expect(summary.hasTimelineWarnings, isFalse);
      expect(summary.firstAttentionSceneId, isNull);
      expect(summary.needsAttention, isFalse);
    });

    test('aggregates timeline QA warnings without flipping readiness', () {
      final project = Project(
        id: 'project-qa',
        name: 'QA pass',
        type: ProjectType.other,
        createdAt: DateTime.utc(2026, 5, 2, 9),
        updatedAt: DateTime.utc(2026, 5, 2, 10),
        scenes: const [
          Scene(
            id: 'scene-qa',
            title: 'Stacked cue',
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
                text: 'Cue one',
                timestampSeconds: 4,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: true,
              ),
              Message(
                id: 'message-2',
                characterId: 'character-2',
                text: 'Cue two',
                timestampSeconds: 4,
                status: MessageStatus.delivered,
                isIncoming: true,
                showTypingBefore: true,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.hasTimelineWarnings, isTrue);
      expect(summary.sharedTimestampCount, 1);
      expect(summary.overlappingTypingCueCount, 1);
      expect(summary.scenesWithTimelineWarnings, 1);
      expect(summary.firstSceneWithTimelineWarningsId, 'scene-qa');
      expect(summary.needsAttention, isFalse);
      expect(summary.firstAttentionSceneId, isNull);
    });
  });
}
