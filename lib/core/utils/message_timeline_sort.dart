import 'package:production_chat_prop/features/projects/domain/message.dart';

int compareMessagesByTimeline(Message a, Message b) {
  final byTimestamp = a.timestampSeconds.compareTo(b.timestampSeconds);
  if (byTimestamp != 0) {
    return byTimestamp;
  }
  return a.id.compareTo(b.id);
}

List<Message> sortMessagesByTimeline(Iterable<Message> messages) {
  final sorted = [...messages]..sort(compareMessagesByTimeline);
  return sorted;
}
