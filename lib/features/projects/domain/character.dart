class Character {
  const Character({
    required this.id,
    required this.displayName,
    required this.avatarPath,
    required this.bubbleColor,
  });

  final String id;
  final String displayName;
  final String? avatarPath;
  final String bubbleColor;

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: _readString(json['id']),
      displayName: _readString(json['displayName']),
      avatarPath: _readNullableString(json['avatarPath']),
      bubbleColor: _readString(json['bubbleColor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarPath': avatarPath,
      'bubbleColor': bubbleColor,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static String? _readNullableString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }
}
