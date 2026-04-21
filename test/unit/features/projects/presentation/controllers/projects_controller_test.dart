import 'dart:convert';

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

    test('addMessage ignores negative timestamps', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .addMessage(
            projectId: 'p1',
            sceneId: 's1',
            characterId: 'c1',
            text: 'Should not be added',
            timestampSeconds: -1,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final messages = projects.first.scenes.first.messages;

      expect(messages, hasLength(2));
      expect(messages.map((message) => message.id), ['m1', 'm2']);
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

    test('updateMessage ignores negative timestamps', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .updateMessage(
            projectId: 'p1',
            sceneId: 's1',
            messageId: 'm2',
            characterId: 'c1',
            text: 'Should not apply',
            timestampSeconds: -1,
            status: MessageStatus.seen,
            isIncoming: true,
            showTypingBefore: true,
          );

      final projects = await container.read(projectsControllerProvider.future);
      final message = projects.first.scenes.first.messages.firstWhere(
        (item) => item.id == 'm2',
      );

      expect(message.text, 'Message B');
      expect(message.timestampSeconds, 5);
      expect(message.status, MessageStatus.delivered);
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

    test('duplicateScene creates copy with cloned structure', () async {
      await container.read(projectsControllerProvider.future);

      final duplicatedSceneId = await container
          .read(projectsControllerProvider.notifier)
          .duplicateScene(projectId: 'p1', sceneId: 's1');

      final projects = await container.read(projectsControllerProvider.future);
      final scenes = projects.first.scenes;
      final duplicate = scenes.firstWhere(
        (scene) => scene.id == duplicatedSceneId,
      );

      expect(duplicatedSceneId, isNotNull);
      expect(scenes.length, 2);
      expect(duplicate.title, 'Scene 1 Copy');
      expect(duplicate.characters.length, 1);
      expect(duplicate.messages.length, 2);
      expect(duplicate.characters.first.id, isNot('c1'));
      expect(duplicate.messages.first.id, isNot('m1'));
    });

    test('moveScene returns false at boundaries', () async {
      await container.read(projectsControllerProvider.future);

      final moved = await container
          .read(projectsControllerProvider.notifier)
          .moveScene(projectId: 'p1', sceneId: 's1', direction: -1);

      expect(moved, isFalse);
    });

    test('moveMessageInOrder swaps neighboring timestamps without flattening scene timing', () async {
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
      expect(messages.map((message) => message.timestampSeconds), [0, 5]);
      expect(messages.first.text, 'Message B');
      expect(messages.last.text, 'Message A');
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

    test('deleteMessagesByIds removes all selected messages', () async {
      await container.read(projectsControllerProvider.future);

      final removed = await container
          .read(projectsControllerProvider.notifier)
          .deleteMessagesByIds(
            projectId: 'p1',
            sceneId: 's1',
            messageIds: {'m1', 'm2'},
          );

      final projects = await container.read(projectsControllerProvider.future);
      expect(removed, 2);
      expect(projects.first.scenes.first.messages, isEmpty);
    });

    test('clearSceneMessages removes all scene messages', () async {
      await container.read(projectsControllerProvider.future);

      final removed = await container
          .read(projectsControllerProvider.notifier)
          .clearSceneMessages(projectId: 'p1', sceneId: 's1');

      final projects = await container.read(projectsControllerProvider.future);
      expect(removed, 2);
      expect(projects.first.scenes.first.messages, isEmpty);
    });

    test('applySceneTemplate replaces scene characters and messages', () async {
      await container.read(projectsControllerProvider.future);

      final applied = await container
          .read(projectsControllerProvider.notifier)
          .applySceneTemplate(
            projectId: 'p1',
            sceneId: 's1',
            templateId: 'group_alert',
          );

      final projects = await container.read(projectsControllerProvider.future);
      final scene = projects.first.scenes.first;

      expect(applied, isTrue);
      expect(scene.characters.length, 3);
      expect(scene.messages.length, 4);
      expect(
        scene.messages.first.text,
        'Stand by for rehearsal in 90 seconds.',
      );
    });

    test('setProjectType updates selected project type', () async {
      await container.read(projectsControllerProvider.future);

      await container
          .read(projectsControllerProvider.notifier)
          .setProjectType(projectId: 'p1', type: ProjectType.ad);

      final projects = await container.read(projectsControllerProvider.future);
      expect(projects.first.type, ProjectType.ad);
    });

    test(
      'setProjectTypeByIds updates selected projects and returns count',
      () async {
        await container.read(projectsControllerProvider.future);
        final notifier = container.read(projectsControllerProvider.notifier);

        await notifier.createProject();
        final projectsBeforeUpdate = await container.read(
          projectsControllerProvider.future,
        );
        final secondProjectId = projectsBeforeUpdate.last.id;

        final updatedCount = await notifier.setProjectTypeByIds(
          projectIds: {'p1', secondProjectId},
          type: ProjectType.series,
        );

        final projectsAfterUpdate = await container.read(
          projectsControllerProvider.future,
        );
        expect(updatedCount, 2);
        expect(
          projectsAfterUpdate
              .map((project) => project.type)
              .every((type) => type == ProjectType.series),
          isTrue,
        );
      },
    );

    test(
      'setProjectTypeByIds returns zero when selected type is unchanged',
      () async {
        await container.read(projectsControllerProvider.future);
        final notifier = container.read(projectsControllerProvider.notifier);

        final updatedCount = await notifier.setProjectTypeByIds(
          projectIds: {'p1'},
          type: ProjectType.other,
        );

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        expect(updatedCount, 0);
        expect(projects.first.type, ProjectType.other);
      },
    );

    test(
      'deleteProjectsByIds removes selected projects and returns count',
      () async {
        await container.read(projectsControllerProvider.future);
        final notifier = container.read(projectsControllerProvider.notifier);

        await notifier.createProject();
        final projectsBeforeDelete = await container.read(
          projectsControllerProvider.future,
        );
        final secondProjectId = projectsBeforeDelete.last.id;

        final removedCount = await notifier.deleteProjectsByIds({
          'p1',
          secondProjectId,
        });

        final projectsAfterDelete = await container.read(
          projectsControllerProvider.future,
        );
        expect(removedCount, 2);
        expect(projectsAfterDelete, isEmpty);
      },
    );

    test('deleteProjectsByIds returns zero when selection is empty', () async {
      await container.read(projectsControllerProvider.future);
      final notifier = container.read(projectsControllerProvider.notifier);

      final removedCount = await notifier.deleteProjectsByIds(<String>{});
      final projects = await container.read(projectsControllerProvider.future);

      expect(removedCount, 0);
      expect(projects, hasLength(1));
    });

    test(
      'duplicateProjectsByIds creates copies for selected projects',
      () async {
        await container.read(projectsControllerProvider.future);
        final notifier = container.read(projectsControllerProvider.notifier);

        await notifier.createProject();
        final projectsBeforeDuplicate = await container.read(
          projectsControllerProvider.future,
        );
        final secondProjectId = projectsBeforeDuplicate.last.id;

        final duplicatedCount = await notifier.duplicateProjectsByIds({
          'p1',
          secondProjectId,
        });

        final projectsAfterDuplicate = await container.read(
          projectsControllerProvider.future,
        );
        final names = projectsAfterDuplicate
            .map((project) => project.name)
            .toList(growable: false);
        expect(duplicatedCount, 2);
        expect(projectsAfterDuplicate, hasLength(4));
        expect(names, contains('Project One Copy'));
        expect(names, contains('New Project 2 Copy'));
      },
    );

    test('duplicateProject assigns unique copy names on repeated duplication', () async {
      await container.read(projectsControllerProvider.future);
      final notifier = container.read(projectsControllerProvider.notifier);

      await notifier.duplicateProject('p1');
      await notifier.duplicateProject('p1');

      final projects = await container.read(projectsControllerProvider.future);
      final names = projects.map((project) => project.name).toList();

      expect(names, contains('Project One Copy'));
      expect(names, contains('Project One Copy 2'));
    });

    test('duplicateProjectsByIds returns zero for empty selection', () async {
      await container.read(projectsControllerProvider.future);
      final notifier = container.read(projectsControllerProvider.notifier);

      final duplicatedCount = await notifier.duplicateProjectsByIds(
        <String>{},
      );
      final projects = await container.read(projectsControllerProvider.future);
      expect(duplicatedCount, 0);
      expect(projects, hasLength(1));
    });

    test('setProjectType keeps scenes and messages unchanged', () async {
      await container.read(projectsControllerProvider.future);
      final before = await container.read(projectsControllerProvider.future);
      final beforeScene = before.first.scenes.first;

      await container
          .read(projectsControllerProvider.notifier)
          .setProjectType(projectId: 'p1', type: ProjectType.series);

      final after = await container.read(projectsControllerProvider.future);
      final afterScene = after.first.scenes.first;

      expect(after.first.type, ProjectType.series);
      expect(afterScene.title, beforeScene.title);
      expect(afterScene.characters.length, beforeScene.characters.length);
      expect(afterScene.messages.length, beforeScene.messages.length);
      expect(
        afterScene.messages
            .map((message) => message.text)
            .toList(
              growable: false,
            ),
        beforeScene.messages
            .map((message) => message.text)
            .toList(
              growable: false,
            ),
      );
    });

    test(
      'createDemoProject appends prefilled ad project with scene variety',
      () async {
        await container.read(projectsControllerProvider.future);

        await container
            .read(projectsControllerProvider.notifier)
            .createDemoProject();

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        expect(projects, hasLength(2));

        final demo = projects.last;
        final messageCount = demo.scenes.fold<int>(
          0,
          (count, scene) => count + scene.messages.length,
        );

        expect(demo.name, startsWith('Demo Project'));
        expect(demo.type, ProjectType.ad);
        expect(demo.scenes, hasLength(2));
        expect(messageCount, greaterThanOrEqualTo(7));
        expect(
          demo.scenes.any(
            (scene) => scene.aspectRatio == SceneAspectRatio.landscape16x9,
          ),
          isTrue,
        );
      },
    );

    test(
      'previewProjectImportFromJson returns projected names for batch payload',
      () async {
        await container.read(projectsControllerProvider.future);

        final payload = jsonEncode({
          'projects': [
            _sampleProject().toJson(),
            {
              ..._sampleProject().toJson(),
              'id': 'p2',
              'name': 'Project Two',
            },
            {'invalid': true},
          ],
        });

        final result = await container
            .read(projectsControllerProvider.notifier)
            .previewProjectImportFromJson(payload);

        expect(result.status, ProjectJsonImportPreviewStatus.ready);
        expect(result.importableCount, 2);
        expect(result.invalidCount, 1);
        expect(result.projectedNames, contains('Project One (Imported)'));
        expect(result.projectedNames, contains('Project Two'));
      },
    );

    test(
      'previewProjectImportFromJson returns invalidJson for malformed payload',
      () async {
        await container.read(projectsControllerProvider.future);

        final result = await container
            .read(projectsControllerProvider.notifier)
            .previewProjectImportFromJson('{broken');

        expect(result.status, ProjectJsonImportPreviewStatus.invalidJson);
      },
    );

    test(
      'importProjectFromJson appends imported project with unique name',
      () async {
        await container.read(projectsControllerProvider.future);

        final payload = jsonEncode(_sampleProject().toJson());
        final result = await container
            .read(projectsControllerProvider.notifier)
            .importProjectFromJson(payload);

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        final imported = projects.last;

        expect(result.status, ProjectJsonImportStatus.success);
        expect(result.importedCount, 1);
        expect(result.skippedCount, 0);
        expect(result.importedProjectName, 'Project One (Imported)');
        expect(imported.id, isNot('p1'));
        expect(imported.name, 'Project One (Imported)');
        expect(imported.scenes, isNotEmpty);
      },
    );

    test(
      'importProjectFromJson returns invalidJson for malformed payload',
      () async {
        await container.read(projectsControllerProvider.future);

        final result = await container
            .read(projectsControllerProvider.notifier)
            .importProjectFromJson('{broken');

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        expect(result.status, ProjectJsonImportStatus.invalidJson);
        expect(projects, hasLength(1));
      },
    );

    test(
      'importProjectFromJson adds fallback scene when payload has none',
      () async {
        await container.read(projectsControllerProvider.future);

        final payload = jsonEncode({
          'id': 'incoming-id',
          'name': 'Imported Empty',
          'type': 'other',
          'createdAt': DateTime.utc(2026).toIso8601String(),
          'updatedAt': DateTime.utc(2026).toIso8601String(),
          'scenes': <Object>[],
        });

        final result = await container
            .read(projectsControllerProvider.notifier)
            .importProjectFromJson(payload);

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        final imported = projects.last;

        expect(result.status, ProjectJsonImportStatus.success);
        expect(result.importedCount, 1);
        expect(imported.name, 'Imported Empty');
        expect(imported.scenes, hasLength(1));
        expect(imported.scenes.first.title, 'Scene 1');
      },
    );

    test(
      'importProjectFromJson accepts wrapped project payload from package export',
      () async {
        await container.read(projectsControllerProvider.future);

        final payload = jsonEncode({
          'meta': {'format': 'project_package', 'version': 1},
          'project': _sampleProject().toJson(),
        });

        final result = await container
            .read(projectsControllerProvider.notifier)
            .importProjectFromJson(payload);

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        expect(result.status, ProjectJsonImportStatus.success);
        expect(result.importedCount, 1);
        expect(projects, hasLength(2));
        expect(projects.last.name, 'Project One (Imported)');
      },
    );

    test(
      'importProjectFromJson supports multi-project payload and reports skipped entries',
      () async {
        await container.read(projectsControllerProvider.future);

        final payload = jsonEncode({
          'meta': {'format': 'project_package_batch', 'version': 1},
          'projects': [
            _sampleProject().toJson(),
            {
              ..._sampleProject().toJson(),
              'id': 'p2',
              'name': 'Project Two',
            },
            {'invalid': true},
          ],
        });

        final result = await container
            .read(projectsControllerProvider.notifier)
            .importProjectFromJson(payload);

        final projects = await container.read(
          projectsControllerProvider.future,
        );
        final names = projects.map((project) => project.name).toList();

        expect(result.status, ProjectJsonImportStatus.success);
        expect(result.importedCount, 2);
        expect(result.skippedCount, 1);
        expect(projects, hasLength(3));
        expect(names, contains('Project One (Imported)'));
        expect(names, contains('Project Two'));
      },
    );
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
