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
      id: _readString(json['id']),
      characterId: _readString(json['characterId']),
      text: _readString(json['text']),
      timestampSeconds: _readInt(json['timestampSeconds']),
      status: MessageStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isIncoming: _readBool(json['isIncoming']),
      showTypingBefore: _readBool(json['showTypingBefore']),
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

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }
}
