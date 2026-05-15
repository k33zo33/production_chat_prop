import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

bool showsTypingIndicatorAtSecond({
  required Message message,
  required int currentSecond,
}) {
  if (!message.showTypingBefore) {
    return false;
  }

  final typingSecond = message.timestampSeconds - 1;
  if (typingSecond < 0) {
    return false;
  }

  return currentSecond == typingSecond;
}

int maxSecondForScene(Scene? scene) {
  if (scene == null || scene.messages.isEmpty) {
    return 0;
  }

  final sortedMessages = sortMessagesByTimeline(scene.messages);
  return sortedMessages.last.timestampSeconds;
}

int countVisibleMessagesAtSecond({
  required List<Message> sortedMessages,
  required int currentSecond,
}) {
  if (sortedMessages.isEmpty) {
    return 0;
  }

  var low = 0;
  var high = sortedMessages.length;
  while (low < high) {
    final mid = low + ((high - low) >> 1);
    if (sortedMessages[mid].timestampSeconds <= currentSecond) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low;
}

int? findNextCueSecond({
  required List<Message> sortedMessages,
  required int currentSecond,
}) {
  for (final message in sortedMessages) {
    if (message.timestampSeconds > currentSecond) {
      return message.timestampSeconds;
    }
  }
  return null;
}

int? findPreviousCueSecond({
  required List<Message> sortedMessages,
  required int currentSecond,
}) {
  int? candidate;
  for (final message in sortedMessages) {
    if (message.timestampSeconds < currentSecond) {
      candidate = message.timestampSeconds;
    } else {
      break;
    }
  }
  return candidate;
}
