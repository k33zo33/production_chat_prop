import 'package:production_chat_prop/features/projects/domain/scene.dart';

enum ProjectType { ad, series, other }

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.scenes,
  });

  final String id;
  final String name;
  final ProjectType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Scene> scenes;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ProjectType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ProjectType.other,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      scenes: (json['scenes'] as List<dynamic>)
          .map((sceneJson) => Scene.fromJson(sceneJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
    };
  }
}
