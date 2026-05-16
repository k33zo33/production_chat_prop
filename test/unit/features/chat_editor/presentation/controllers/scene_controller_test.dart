import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

void main() {
  group('sceneSnapshotProvider', () {
    late _InMemoryProjectRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _InMemoryProjectRepository(projects: [_sampleProject()]);
      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('returns null for missing project ids', () async {
      await container.read(projectsControllerProvider.future);

      final snapshot = container.read(sceneSnapshotProvider('missing-project'));

      expect(snapshot.hasValue, isTrue);
      expect(snapshot.value, isNull);
    });

    test('defaults to the first scene when no selection is set', () async {
      await container.read(projectsControllerProvider.future);

      final snapshot = container.read(sceneSnapshotProvider('project-1')).value;

      expect(snapshot, isNotNull);
      expect(snapshot!.project.id, 'project-1');
      expect(snapshot.scene?.id, 'scene-1');
      expect(snapshot.scene?.title, 'Scene 1');
    });

    test('resolves the explicitly selected scene when it exists', () async {
      await container.read(projectsControllerProvider.future);

      container.read(sceneSelectionProvider('project-1').notifier).selectedSceneId =
          'scene-2';

      final snapshot = container.read(sceneSnapshotProvider('project-1')).value;

      expect(snapshot, isNotNull);
      expect(snapshot!.scene?.id, 'scene-2');
      expect(snapshot.scene?.title, 'Scene 2');
    });

    test('falls back to the first scene when selection is stale', () async {
      await container.read(projectsControllerProvider.future);

      container.read(sceneSelectionProvider('project-1').notifier).selectedSceneId =
          'missing-scene';

      final snapshot = container.read(sceneSnapshotProvider('project-1')).value;

      expect(snapshot, isNotNull);
      expect(snapshot!.scene?.id, 'scene-1');
      expect(snapshot.scene?.title, 'Scene 1');
    });

    test('falls back to a surviving scene after the selected scene is deleted', () async {
      await container.read(projectsControllerProvider.future);
      final notifier = container.read(projectsControllerProvider.notifier);

      container.read(sceneSelectionProvider('project-1').notifier).selectedSceneId =
          'scene-2';

      final deleted = await notifier.deleteScene(
        projectId: 'project-1',
        sceneId: 'scene-2',
      );
      final snapshot = container.read(sceneSnapshotProvider('project-1')).value;

      expect(deleted, isTrue);
      expect(snapshot, isNotNull);
      expect(snapshot!.scene?.id, 'scene-1');
      expect(snapshot.scene?.title, 'Scene 1');
    });
  });

  group('sceneSnapshotProvider with empty-scene projects', () {
    late _InMemoryProjectRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _InMemoryProjectRepository(projects: [_emptyProject()]);
      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('returns a null scene when the project has no scenes yet', () async {
      await container.read(projectsControllerProvider.future);

      final snapshot = container.read(sceneSnapshotProvider('project-empty')).value;

      expect(snapshot, isNotNull);
      expect(snapshot!.project.id, 'project-empty');
      expect(snapshot.scene, isNull);
    });

    test('recovers to the newly added scene after an empty project is updated', () async {
      await container.read(projectsControllerProvider.future);

      final addedSceneId = await container
          .read(projectsControllerProvider.notifier)
          .addScene(projectId: 'project-empty', title: 'Recovered Scene');
      final snapshot = container.read(sceneSnapshotProvider('project-empty')).value;

      expect(addedSceneId, isNotNull);
      expect(snapshot, isNotNull);
      expect(snapshot!.scene?.id, addedSceneId);
      expect(snapshot.scene?.title, 'Recovered Scene');
    });
  });
}

class _InMemoryProjectRepository implements ProjectRepository {
  _InMemoryProjectRepository({required List<Project> projects})
    : _projects = List<Project>.from(projects);

  List<Project> _projects;

  @override
  Future<List<Project>> getAll() async {
    return List<Project>.from(_projects);
  }

  @override
  Future<void> saveAll(List<Project> projects) async {
    _projects = List<Project>.from(projects);
  }
}

Project _sampleProject() {
  final createdAt = DateTime.utc(2026, 5, 15, 16);

  return Project(
    id: 'project-1',
    name: 'Scene Selection Project',
    type: ProjectType.ad,
    createdAt: createdAt,
    updatedAt: createdAt,
    scenes: const [
      Scene(
        id: 'scene-1',
        title: 'Scene 1',
        styleId: 'studio_default',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Alex',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [
          Message(
            id: 'message-1',
            characterId: 'character-1',
            text: 'Opening line',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      ),
      Scene(
        id: 'scene-2',
        title: 'Scene 2',
        styleId: 'night_shift',
        aspectRatio: SceneAspectRatio.landscape16x9,
        characters: [
          Character(
            id: 'character-2',
            displayName: 'Mia',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
        ],
        messages: [
          Message(
            id: 'message-2',
            characterId: 'character-2',
            text: 'Second scene line',
            timestampSeconds: 2,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
        ],
      ),
    ],
  );
}

Project _emptyProject() {
  final createdAt = DateTime.utc(2026, 5, 15, 16);

  return Project(
    id: 'project-empty',
    name: 'Empty Scene Project',
    type: ProjectType.other,
    createdAt: createdAt,
    updatedAt: createdAt,
    scenes: const [],
  );
}
