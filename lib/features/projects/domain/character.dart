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
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarPath: json['avatarPath'] as String?,
      bubbleColor: json['bubbleColor'] as String,
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
}
