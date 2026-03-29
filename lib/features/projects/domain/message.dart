enum MessageStatus { sent, delivered, seen }

class Message {
  const Message({
    required this.id,
    required this.characterId,
    required this.text,
    required this.timestampSeconds,
    required this.status,
    required this.isIncoming,
    required this.showTypingBefore,
  });

  final String id;
  final String characterId;
  final String text;
  final int timestampSeconds;
  final MessageStatus status;
  final bool isIncoming;
  final bool showTypingBefore;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      text: json['text'] as String,
      timestampSeconds: json['timestampSeconds'] as int,
      status: MessageStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isIncoming: json['isIncoming'] as bool,
      showTypingBefore: json['showTypingBefore'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'text': text,
      'timestampSeconds': timestampSeconds,
      'status': status.name,
      'isIncoming': isIncoming,
      'showTypingBefore': showTypingBefore,
    };
  }
}
