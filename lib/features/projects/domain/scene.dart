import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';

enum SceneAspectRatio { portrait9x16, landscape16x9 }

class Scene {
  const Scene({
    required this.id,
    required this.title,
    required this.characters,
    required this.messages,
    required this.styleId,
    required this.aspectRatio,
  });

  final String id;
  final String title;
  final List<Character> characters;
  final List<Message> messages;
  final String styleId;
  final SceneAspectRatio aspectRatio;

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      title: json['title'] as String,
      characters: (json['characters'] as List<dynamic>)
          .map(
            (characterJson) =>
                Character.fromJson(characterJson as Map<String, dynamic>),
          )
          .toList(),
      messages: (json['messages'] as List<dynamic>)
          .map(
            (messageJson) =>
                Message.fromJson(messageJson as Map<String, dynamic>),
          )
          .toList(),
      styleId: json['styleId'] as String,
      aspectRatio: SceneAspectRatio.values.firstWhere(
        (value) => value.name == json['aspectRatio'],
        orElse: () => SceneAspectRatio.portrait9x16,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'characters': characters.map((character) => character.toJson()).toList(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'styleId': styleId,
      'aspectRatio': aspectRatio.name,
    };
  }
}
