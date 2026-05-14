import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/data/services/project_sanitizer.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';

class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository(this._datasource);

  static final _projectSanitizer = ProjectSanitizer();

  final LocalProjectDatasource _datasource;

  @override
  Future<List<Project>> getAll() async {
    final jsonList = await _datasource.loadProjectsJson();
    final projects = <Project>[];
    for (final projectJson in jsonList) {
      if (!_looksLikePersistedProjectPayload(projectJson)) {
        continue;
      }

      try {
        projects.add(
          _projectSanitizer.sanitizeProject(Project.fromJson(projectJson)),
        );
      } catch (error) {
        final isRecoverableDataError =
            error is FormatException || error is TypeError;
        if (isRecoverableDataError) {
          // Skip malformed persisted payloads and continue loading the rest.
          continue;
        }
        rethrow;
      }
    }
    return projects;
  }

  @override
  Future<void> saveAll(List<Project> projects) {
    final payload = projects.map((project) => project.toJson()).toList();
    return _datasource.saveProjectsJson(payload);
  }

  bool _looksLikePersistedProjectPayload(Map<String, dynamic> projectJson) {
    return projectJson['scenes'] is List;
  }
}
