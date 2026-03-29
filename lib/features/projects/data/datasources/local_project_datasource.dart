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

    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> saveProjectsJson(List<Map<String, dynamic>> projectsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(projectsJson);
    await prefs.setString(_projectsStorageKey, encoded);
  }
}
