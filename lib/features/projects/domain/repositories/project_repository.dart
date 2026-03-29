import 'package:production_chat_prop/features/projects/domain/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAll();
  Future<void> saveAll(List<Project> projects);
}
