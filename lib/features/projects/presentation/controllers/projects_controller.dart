import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/data/repositories/local_project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';
import 'package:uuid/uuid.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return const LocalProjectRepository(LocalProjectDatasource());
});

final projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

class ProjectsController extends AsyncNotifier<List<Project>> {
  static const _uuid = Uuid();

  ProjectRepository get _repository => ref.read(projectRepositoryProvider);

  @override
  Future<List<Project>> build() async {
    final projects = await _repository.getAll();
    return projects;
  }

  Future<void> createProject() async {
    final current = await future;
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      name: 'New Project ${current.length + 1}',
      type: ProjectType.other,
      createdAt: now,
      updatedAt: now,
      scenes: const [],
    );

    final next = [...current, project];
    await _persist(next);
  }

  Future<void> renameProject({
    required String projectId,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          return Project(
            id: project.id,
            name: trimmed,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: project.scenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> deleteProject(String projectId) async {
    final current = await future;
    final next = current
        .where((project) => project.id != projectId)
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> duplicateProject(String projectId) async {
    final current = await future;
    Project? source;
    for (final project in current) {
      if (project.id == projectId) {
        source = project;
        break;
      }
    }
    if (source == null) {
      return;
    }

    final now = DateTime.now();
    final duplicate = Project(
      id: _uuid.v4(),
      name: '${source.name} Copy',
      type: source.type,
      createdAt: now,
      updatedAt: now,
      scenes: source.scenes,
    );

    final next = [...current, duplicate];
    await _persist(next);
  }

  Future<void> _persist(List<Project> projects) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveAll(projects);
      return projects;
    });
  }
}
