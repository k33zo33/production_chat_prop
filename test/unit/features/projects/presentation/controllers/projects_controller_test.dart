import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

void main() {
  group('ProjectsController message mutations', () {
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

    test('addMessage appends and sorts by timestamp', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .addMessage(
            projectId: 'p1',
            sceneId: 's1',
            characterId: 'c1',
            text: 'Inserted earlier than last message',
            timestampSeconds: 3,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;

      expect(messages, hasLength(3));
      expect(messages.map((message) => message.timestampSeconds), [0, 3, 5]);
      expect(messages[1].text, 'Inserted earlier than last message');
    });

    test('updateMessageText changes only targeted message', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .updateMessageText(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm2',
            newText: 'Updated text from test',
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;

      expect(messages[1].text, 'Updated text from test');
      expect(messages[0].text, 'Message A');
    });

    test('updateMessage can change metadata and keep sorted order', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .updateMessage(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm2',
            characterId: 'c1',
            text: 'Moved earlier',
            timestampSeconds: 1,
            status: MessageStatus.seen,
            isIncoming: true,
            showTypingBefore: true,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;
      final updated = messages.firstWhere((message) => message.id == 'm2');

      expect(messages.map((message) => message.timestampSeconds), [0, 1]);
      expect(updated.text, 'Moved earlier');
      expect(updated.status, MessageStatus.seen);
      expect(updated.isIncoming, isTrue);
      expect(updated.showTypingBefore, isTrue);
    });

    test('deleteMessage removes targeted message', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .deleteMessage(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm1',
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;

      expect(messages, hasLength(1));
      expect(messages.first.id, 'm2');
    });

    test('addCharacter appends a new character', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .addCharacter(
            projectId: 'p1',
            sceneId: 's1',
            displayName: 'Mia',
          );

      final projects = await container.read(projectsControllerProvider.future);
      final characters = projects.first.scenes.first.characters;

      expect(characters, hasLength(2));
      expect(characters.map((character) => character.displayName), [
        'Alex',
        'Mia',
      ]);
    });

    test('renameCharacter updates only selected character', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .addCharacter(
            projectId: 'p1',
            sceneId: 's1',
            displayName: 'Mia',
          );

      final beforeRename = await container.read(
        projectsControllerProvider.future,
      );
      final mia = beforeRename.first.scenes.first.characters.firstWhere(
        (character) => character.displayName == 'Mia',
      );

      await container
          .read(projectsControllerProvider.notifier)
          .renameCharacter(
            projectId: 'p1',
            sceneId: 's1',
            characterId: mia.id,
            newDisplayName: 'Mia Updated',
          );

      final projects = await container.read(projectsControllerProvider.future);
      final names = projects.first.scenes.first.characters
          .map((character) => character.displayName)
          .toList(growable: false);

      expect(names, ['Alex', 'Mia Updated']);
    });

    test('deleteCharacter removes character and its messages', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .addCharacter(
            projectId: 'p1',
            sceneId: 's1',
            displayName: 'Mia',
          );

      final withMia = await container.read(projectsControllerProvider.future);
      final mia = withMia.first.scenes.first.characters.firstWhere(
        (character) => character.displayName == 'Mia',
      );

      await container
          .read(projectsControllerProvider.notifier)
          .addMessage(
            projectId: 'p1',
            sceneId: 's1',
            characterId: mia.id,
            text: 'Mia message',
            timestampSeconds: 9,
            status: MessageStatus.sent,
            isIncoming: true,
            showTypingBefore: false,
          );

      await container
          .read(projectsControllerProvider.notifier)
          .deleteCharacter(
            projectId: 'p1',
            sceneId: 's1',
            characterId: mia.id,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final scene = projects.first.scenes.first;

      expect(
        scene.characters.where((character) => character.id == mia.id),
        isEmpty,
      );
      expect(
        scene.messages.where((message) => message.characterId == mia.id),
        isEmpty,
      );
    });

    test('updateSceneSettings updates title style and aspect ratio', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .updateSceneSettings(
            projectId: 'p1',
            sceneId: 's1',
            title: 'Scene Updated',
            styleId: 'editorial_light',
            aspectRatio: SceneAspectRatio.landscape16x9,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final scene = projects.first.scenes.first;

      expect(scene.title, 'Scene Updated');
      expect(scene.styleId, 'editorial_light');
      expect(scene.aspectRatio, SceneAspectRatio.landscape16x9);
    });

    test('addScene appends new scene with provided title', () async {
      await container.read(projectsControllerProvider.future);

      final addedSceneId = await container
          .read(projectsControllerProvider.notifier)
          .addScene(projectId: 'p1', title: 'Scene Extra');

      final projects = await container.read(projectsControllerProvider.future);
      final scenes = projects.first.scenes;

      expect(addedSceneId, isNotNull);
      expect(scenes, hasLength(2));
      expect(scenes.last.title, 'Scene Extra');
      expect(scenes.last.messages, isEmpty);
    });

    test('renameScene updates selected scene title', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .renameScene(
            projectId: 'p1',
            sceneId: 's1',
            newTitle: 'Renamed Scene',
          );

      final projects = await container.read(projectsControllerProvider.future);
      expect(projects.first.scenes.first.title, 'Renamed Scene');
    });

    test('deleteScene removes scene when there are multiple', () async {
      await container.read(projectsControllerProvider.future);

      final notifier = container.read(projectsControllerProvider.notifier);
      await notifier.addScene(projectId: 'p1', title: 'To Delete');
      final withSecondScene = await container.read(
        projectsControllerProvider.future,
      );
      final sceneToDelete = withSecondScene.first.scenes.last;

      final deleted = await notifier.deleteScene(
        projectId: 'p1',
        sceneId: sceneToDelete.id,
      );

      final projects = await container.read(projectsControllerProvider.future);
      expect(deleted, isTrue);
      expect(projects.first.scenes, hasLength(1));
      expect(
        projects.first.scenes.where((scene) => scene.id == sceneToDelete.id),
        isEmpty,
      );
    });

    test(
      'deleteScene returns false when trying to remove last scene',
      () async {
        await container.read(projectsControllerProvider.future);

        final deleted = await container
            .read(projectsControllerProvider.notifier)
            .deleteScene(projectId: 'p1', sceneId: 's1');

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        expect(deleted, isFalse);
        expect(projects.first.scenes, hasLength(1));
      },
    );

    test('moveScene reorders scenes when neighbor exists', () async {
      await container.read(projectsControllerProvider.future);
      final notifier = container.read(projectsControllerProvider.notifier);
      await notifier.addScene(projectId: 'p1', title: 'Scene 2');
      await notifier.addScene(projectId: 'p1', title: 'Scene 3');

      final before = await container.read(projectsControllerProvider.future);
      final scene3 = before.first.scenes.last;

      final moved = await notifier.moveScene(
        projectId: 'p1',
        sceneId: scene3.id,
        direction: -1,
      );

      final after = await container.read(projectsControllerProvider.future);
      expect(moved, isTrue);
      expect(after.first.scenes.map((scene) => scene.title), [
        'Scene 1',
        'Scene 3',
        'Scene 2',
      ]);
    });

    test('moveScene returns false at boundaries', () async {
      await container.read(projectsControllerProvider.future);

      final moved = await container
          .read(projectsControllerProvider.notifier)
          .moveScene(projectId: 'p1', sceneId: 's1', direction: -1);

      expect(moved, isFalse);
    });

    test('moveMessageInOrder moves message and reindexes timestamps', () async {
      await container.read(projectsControllerProvider.future);

      final moved = await container
          .read(projectsControllerProvider.notifier)
          .moveMessageInOrder(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm2',
            direction: -1,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;

      expect(moved, isTrue);
      expect(messages.map((message) => message.id), ['m2', 'm1']);
      expect(messages.map((message) => message.timestampSeconds), [0, 1]);
    });

    test('moveMessageInOrder returns false when already at edge', () async {
      await container.read(projectsControllerProvider.future);

      final moved = await container
          .read(projectsControllerProvider.notifier)
          .moveMessageInOrder(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm1',
            direction: -1,
          );

      expect(moved, isFalse);
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
  final now = DateTime.utc(2026, 3, 29);

  return Project(
    id: 'p1',
    name: 'Project One',
    type: ProjectType.other,
    createdAt: now,
    updatedAt: now,
    scenes: const [
      Scene(
        id: 's1',
        title: 'Scene 1',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'c1',
            displayName: 'Alex',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [
          Message(
            id: 'm1',
            characterId: 'c1',
            text: 'Message A',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: 'm2',
            characterId: 'c1',
            text: 'Message B',
            timestampSeconds: 5,
            status: MessageStatus.delivered,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      ),
    ],
  );
}
