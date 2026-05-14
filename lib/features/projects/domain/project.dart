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
      id: _readString(json['id']),
      name: _readString(json['name']),
      type: ProjectType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ProjectType.other,
      ),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      scenes: _readJsonList(json['scenes'])
          .map(Scene.fromJson)
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

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static DateTime _readDateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }

      final numericValue = num.tryParse(value);
      if (numericValue != null) {
        return _dateTimeFromNumericValue(numericValue);
      }
    }

    if (value is num) {
      return _dateTimeFromNumericValue(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime _dateTimeFromNumericValue(num value) {
    // Legacy payloads may serialize epoch timestamps as seconds or millis.
    final milliseconds = value.abs() >= 100000000000
        ? value.toInt()
        : (value * 1000).toInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
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
