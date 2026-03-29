import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('Project domain serialization', () {
    test('round-trips project with nested scene/character/message data', () {
      final now = DateTime.utc(2026, 3, 29, 18, 30);
      final source = Project(
        id: 'p1',
        name: 'Serialization Project',
        type: ProjectType.series,
        createdAt: now,
        updatedAt: now,
        scenes: const [
          Scene(
            id: 's1',
            title: 'Scene 1',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.landscape16x9,
            characters: [
              Character(
                id: 'c1',
                displayName: 'Alex',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
            ],
            messages: [
              Message(
                id: 'm1',
                characterId: 'c1',
                text: 'Hello',
                timestampSeconds: 2,
                status: MessageStatus.delivered,
                isIncoming: false,
                showTypingBefore: true,
              ),
            ],
          ),
        ],
      );

      final decoded = Project.fromJson(source.toJson());

      expect(decoded.id, source.id);
      expect(decoded.name, source.name);
      expect(decoded.type, ProjectType.series);
      expect(decoded.scenes.first.aspectRatio, SceneAspectRatio.landscape16x9);
      expect(
        decoded.scenes.first.messages.first.status,
        MessageStatus.delivered,
      );
      expect(decoded.scenes.first.messages.first.showTypingBefore, isTrue);
    });

    test('falls back to safe enum defaults for unknown values', () {
      final decoded = Project.fromJson({
        'id': 'p2',
        'name': 'Fallback',
        'type': 'unknown-type',
        'createdAt': '2026-03-29T00:00:00.000Z',
        'updatedAt': '2026-03-29T00:00:00.000Z',
        'scenes': [
          {
            'id': 's2',
            'title': 'Fallback Scene',
            'styleId': 'fallback',
            'aspectRatio': 'unknown-ratio',
            'characters': [
              {
                'id': 'c2',
                'displayName': 'Mia',
                'avatarPath': null,
                'bubbleColor': '#12B76A',
              },
            ],
            'messages': [
              {
                'id': 'm2',
                'characterId': 'c2',
                'text': 'Fallback message',
                'timestampSeconds': 1,
                'status': 'unknown-status',
                'isIncoming': true,
                'showTypingBefore': false,
              },
            ],
          },
        ],
      });

      expect(decoded.type, ProjectType.other);
      expect(decoded.scenes.first.aspectRatio, SceneAspectRatio.portrait9x16);
      expect(decoded.scenes.first.messages.first.status, MessageStatus.sent);
    });
  });
}
