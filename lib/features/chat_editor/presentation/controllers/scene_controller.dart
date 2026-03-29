import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

class SceneSnapshot {
  const SceneSnapshot({required this.project, required this.scene});

  final Project project;
  final Scene? scene;
}

class SceneSelectionNotifier extends Notifier<String?> {
  SceneSelectionNotifier(this.projectId);

  final String projectId;

  @override
  String? build() {
    return null;
  }

  String? get selectedSceneId => state;

  set selectedSceneId(String? sceneId) {
    state = sceneId;
  }
}

// ignore: specify_nonobvious_property_types, typed via NotifierProvider.family generic args.
final sceneSelectionProvider =
    NotifierProvider.family<SceneSelectionNotifier, String?, String>(
      SceneSelectionNotifier.new,
    );

// ignore: specify_nonobvious_property_types, typed via Provider.family generic args.
final sceneSnapshotProvider =
    Provider.family<AsyncValue<SceneSnapshot?>, String>((ref, projectId) {
      final projectsState = ref.watch(projectsControllerProvider);
      final selectedSceneId = ref.watch(sceneSelectionProvider(projectId));

      return projectsState.whenData((projects) {
        Project? selectedProject;
        for (final project in projects) {
          if (project.id == projectId) {
            selectedProject = project;
            break;
          }
        }
        if (selectedProject == null) {
          return null;
        }

        if (selectedProject.scenes.isEmpty) {
          return SceneSnapshot(project: selectedProject, scene: null);
        }

        var selectedScene = selectedProject.scenes.first;
        if (selectedSceneId != null) {
          for (final scene in selectedProject.scenes) {
            if (scene.id == selectedSceneId) {
              selectedScene = scene;
              break;
            }
          }
        }

        return SceneSnapshot(project: selectedProject, scene: selectedScene);
      });
    });
