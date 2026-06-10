import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('Project domain serialization', () {
    test('project toJson/fromJson round-trips nested scenes', () {
      final project = Project(
        id: 'project-1',
        name: 'Launch Spot',
        type: ProjectType.ad,
        createdAt: DateTime.utc(2026, 4, 20, 18),
        updatedAt: DateTime.utc(2026, 4, 20, 19),
        scenes: [
          const Scene(
            id: 'scene-1',
            title: 'Opening Chat',
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
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'Ready for the first take?',
                timestampSeconds: 3,
                status: MessageStatus.seen,
                isIncoming: false,
                showTypingBefore: true,
              ),
            ],
          ),
        ],
      );

      final roundTrip = Project.fromJson(project.toJson());

      expect(roundTrip.toJson(), project.toJson());
      expect(roundTrip.scenes.single.characters.single.displayName, 'Mia');
      expect(
        roundTrip.scenes.single.messages.single.status,
        MessageStatus.seen,
      );
    });

    test('fromJson falls back to safe enum defaults for invalid values', () {
      final project = Project.fromJson({
        'id': 'project-2',
        'name': 'Fallback Project',
        'type': 'unknown',
        'createdAt': DateTime.utc(2026, 4, 20, 18).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 4, 20, 19).toIso8601String(),
        'scenes': [
          {
            'id': 'scene-2',
            'title': 'Fallback Scene',
            'styleId': 'night_shift',
            'aspectRatio': 'unexpected',
            'characters': [
              {
                'id': 'character-2',
                'displayName': 'Noa',
                'avatarPath': null,
                'bubbleColor': '#12B76A',
              },
            ],
            'messages': [
              {
                'id': 'message-2',
                'characterId': 'character-2',
                'text': 'Defaults keep imports resilient.',
                'timestampSeconds': 8,
                'status': 'mystery',
                'isIncoming': true,
                'showTypingBefore': false,
              },
            ],
          },
        ],
      });

      expect(project.type, ProjectType.other);
      expect(project.scenes.single.aspectRatio, SceneAspectRatio.portrait9x16);
      expect(project.scenes.single.messages.single.status, MessageStatus.sent);
    });
  });

  group('sortMessagesByTimeline', () {
    test('orders messages by timestamp ascending', () {
      const messages = [
        Message(
          id: 'message-3',
          characterId: 'character-1',
          text: 'Third',
          timestampSeconds: 12,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        Message(
          id: 'message-1',
          characterId: 'character-1',
          text: 'First',
          timestampSeconds: 1,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        Message(
          id: 'message-2',
          characterId: 'character-1',
          text: 'Second',
          timestampSeconds: 7,
          status: MessageStatus.delivered,
          isIncoming: true,
          showTypingBefore: true,
        ),
      ];

      final sorted = sortMessagesByTimeline(messages);

      expect(sorted.map((message) => message.id), [
        'message-1',
        'message-2',
        'message-3',
      ]);
    });

    test('uses id as deterministic tiebreaker for equal timestamps', () {
      const messages = [
        Message(
          id: 'message-c',
          characterId: 'character-1',
          text: 'Later id',
          timestampSeconds: 5,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        Message(
          id: 'message-a',
          characterId: 'character-1',
          text: 'Earlier id',
          timestampSeconds: 5,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
      ];

      final sorted = sortMessagesByTimeline(messages);

      expect(sorted.map((message) => message.id), ['message-a', 'message-c']);
    });

    test('returns a new list without mutating the input iterable', () {
      const original = [
        Message(
          id: 'message-b',
          characterId: 'character-1',
          text: 'Second in source',
          timestampSeconds: 4,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        Message(
          id: 'message-a',
          characterId: 'character-1',
          text: 'First in timeline',
          timestampSeconds: 1,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
      ];

      final sorted = sortMessagesByTimeline(original);

      expect(original.map((message) => message.id), ['message-b', 'message-a']);
      expect(sorted.map((message) => message.id), ['message-a', 'message-b']);
      expect(identical(sorted, original), isFalse);
    });
  });
}
