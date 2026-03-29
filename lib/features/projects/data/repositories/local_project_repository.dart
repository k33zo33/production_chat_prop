import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';

class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository(this._datasource);

  final LocalProjectDatasource _datasource;

  @override
  Future<List<Project>> getAll() async {
    final jsonList = await _datasource.loadProjectsJson();
    final projects = <Project>[];
    for (final projectJson in jsonList) {
      try {
        projects.add(Project.fromJson(projectJson));
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
}
