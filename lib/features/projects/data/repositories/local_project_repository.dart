import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';

class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository(this._datasource);

  final LocalProjectDatasource _datasource;

  @override
  Future<List<Project>> getAll() async {
    final jsonList = await _datasource.loadProjectsJson();
    return jsonList.map(Project.fromJson).toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Project> projects) {
    final payload = projects.map((project) => project.toJson()).toList();
    return _datasource.saveProjectsJson(payload);
  }
}
