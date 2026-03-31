import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';

void main() {
  group('sortMessagesByTimeline', () {
    test('sorts by timestamp then message id for stable order', () {
      final messages = [
        const Message(
          id: 'm3',
          characterId: 'c1',
          text: 'third',
          timestampSeconds: 2,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        const Message(
          id: 'm2',
          characterId: 'c1',
          text: 'second',
          timestampSeconds: 1,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        const Message(
          id: 'm1',
          characterId: 'c1',
          text: 'first',
          timestampSeconds: 1,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
      ];

      final sorted = sortMessagesByTimeline(messages);

      expect(sorted.map((message) => message.id), ['m1', 'm2', 'm3']);
      expect(
        sorted.map((message) => message.timestampSeconds),
        [1, 1, 2],
      );
    });
  });
}
