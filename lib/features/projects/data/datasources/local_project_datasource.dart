import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalProjectDatasource {
  const LocalProjectDatasource();

  static const _projectsStorageKey = 'projects_v1';

  Future<List<Map<String, dynamic>>> loadProjectsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_projectsStorageKey);
    if (rawJson == null || rawJson.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      final result = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }

      return result;
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveProjectsJson(List<Map<String, dynamic>> projectsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(projectsJson);
    await prefs.setString(_projectsStorageKey, encoded);
  }
}
