import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/playback/domain/playback_timeline.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('showsTypingIndicatorAtSecond', () {
    test('returns true exactly one second before a typing-enabled message', () {
      const message = Message(
        id: 'message-1',
        characterId: 'character-1',
        text: 'Cue incoming',
        timestampSeconds: 6,
        status: MessageStatus.sent,
        isIncoming: true,
        showTypingBefore: true,
      );

      expect(
        showsTypingIndicatorAtSecond(message: message, currentSecond: 5),
        isTrue,
      );
      expect(
        showsTypingIndicatorAtSecond(message: message, currentSecond: 4),
        isFalse,
      );
      expect(
        showsTypingIndicatorAtSecond(message: message, currentSecond: 6),
        isFalse,
      );
    });

    test('handles first-second and invalid typing indicator boundaries', () {
      const noTyping = Message(
        id: 'message-2',
        characterId: 'character-1',
        text: 'No typing cue',
        timestampSeconds: 4,
        status: MessageStatus.sent,
        isIncoming: false,
        showTypingBefore: false,
      );
      const firstSecondTyping = Message(
        id: 'message-3',
        characterId: 'character-1',
        text: 'Starts after one beat',
        timestampSeconds: 1,
        status: MessageStatus.sent,
        isIncoming: false,
        showTypingBefore: true,
      );
      const zeroSecondTyping = Message(
        id: 'message-4',
        characterId: 'character-1',
        text: 'Starts immediately',
        timestampSeconds: 0,
        status: MessageStatus.sent,
        isIncoming: false,
        showTypingBefore: true,
      );

      expect(
        showsTypingIndicatorAtSecond(message: noTyping, currentSecond: 3),
        isFalse,
      );
      expect(
        showsTypingIndicatorAtSecond(
          message: firstSecondTyping,
          currentSecond: 0,
        ),
        isTrue,
      );
      expect(
        showsTypingIndicatorAtSecond(
          message: zeroSecondTyping,
          currentSecond: 0,
        ),
        isFalse,
      );
    });
  });

  group('maxSecondForScene', () {
    test('returns zero for null or empty scenes', () {
      expect(maxSecondForScene(null), 0);
      expect(
        maxSecondForScene(
          const Scene(
            id: 'scene-empty',
            title: 'Empty',
            styleId: 'studio_default',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [],
            messages: [],
          ),
        ),
        0,
      );
    });

    test('returns the latest timestamp after sorting messages', () {
      const scene = Scene(
        id: 'scene-1',
        title: 'Out of order',
        styleId: 'studio_default',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Alex',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [
          Message(
            id: 'message-3',
            characterId: 'character-1',
            text: 'Later cue',
            timestampSeconds: 9,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: 'message-1',
            characterId: 'character-1',
            text: 'Earlier cue',
            timestampSeconds: 2,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: 'message-2',
            characterId: 'character-1',
            text: 'Middle cue',
            timestampSeconds: 5,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      );

      expect(maxSecondForScene(scene), 9);
    });
  });

  group('timeline cue helpers', () {
    final sortedMessages = sortMessagesByTimeline(const [
      Message(
        id: 'message-2',
        characterId: 'character-1',
        text: 'Second',
        timestampSeconds: 5,
        status: MessageStatus.delivered,
        isIncoming: true,
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
        id: 'message-4',
        characterId: 'character-1',
        text: 'Also third',
        timestampSeconds: 7,
        status: MessageStatus.sent,
        isIncoming: false,
        showTypingBefore: false,
      ),
      Message(
        id: 'message-3',
        characterId: 'character-1',
        text: 'Third',
        timestampSeconds: 7,
        status: MessageStatus.seen,
        isIncoming: false,
        showTypingBefore: true,
      ),
    ]);

    test(
      'countVisibleMessagesAtSecond counts cues up to the current second',
      () {
        expect(
          countVisibleMessagesAtSecond(
            sortedMessages: sortedMessages,
            currentSecond: 0,
          ),
          0,
        );
        expect(
          countVisibleMessagesAtSecond(
            sortedMessages: sortedMessages,
            currentSecond: 1,
          ),
          1,
        );
        expect(
          countVisibleMessagesAtSecond(
            sortedMessages: sortedMessages,
            currentSecond: 7,
          ),
          4,
        );
        expect(
          countVisibleMessagesAtSecond(
            sortedMessages: sortedMessages,
            currentSecond: 99,
          ),
          4,
        );
      },
    );

    test('findNextCueSecond returns the next future cue', () {
      expect(
        findNextCueSecond(
          sortedMessages: const <Message>[],
          currentSecond: 0,
        ),
        isNull,
      );
      expect(
        findNextCueSecond(sortedMessages: sortedMessages, currentSecond: 0),
        1,
      );
      expect(
        findNextCueSecond(sortedMessages: sortedMessages, currentSecond: 5),
        7,
      );
      expect(
        findNextCueSecond(sortedMessages: sortedMessages, currentSecond: 7),
        isNull,
      );
    });

    test('findPreviousCueSecond returns the latest past cue only', () {
      expect(
        findPreviousCueSecond(
          sortedMessages: const <Message>[],
          currentSecond: 0,
        ),
        isNull,
      );
      expect(
        findPreviousCueSecond(sortedMessages: sortedMessages, currentSecond: 0),
        isNull,
      );
      expect(
        findPreviousCueSecond(sortedMessages: sortedMessages, currentSecond: 5),
        1,
      );
      expect(
        findPreviousCueSecond(sortedMessages: sortedMessages, currentSecond: 7),
        5,
      );
      expect(
        findPreviousCueSecond(sortedMessages: sortedMessages, currentSecond: 8),
        7,
      );
    });
  });
}
