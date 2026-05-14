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
      id: _readString(json['id']),
      title: _readString(json['title']),
      characters: _readJsonList(json['characters'])
          .map(Character.fromJson)
          .toList(),
      messages: _readJsonList(json['messages'])
          .map(Message.fromJson)
          .toList(),
      styleId: _readString(json['styleId']),
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

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static List<Map<String, dynamic>> _readJsonList(Object? value) {
    if (value is! List) {
      return const [];
    }

    final items = <Map<String, dynamic>>[];
    for (final entry in value) {
      final map = _readJsonMap(entry);
      if (map != null) {
        items.add(map);
      }
    }
    return items;
  }

  static Map<String, dynamic>? _readJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is! Map) {
      return null;
    }

    final casted = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      casted[key] = entry.value;
    }
    return casted;
  }
}
