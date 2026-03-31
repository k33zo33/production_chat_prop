import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/data/repositories/local_project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/repositories/project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:uuid/uuid.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return const LocalProjectRepository(LocalProjectDatasource());
});

final projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );

enum ProjectJsonImportStatus {
  success,
  emptyInput,
  invalidJson,
  invalidProjectPayload,
}

enum ProjectJsonImportPreviewStatus {
  ready,
  emptyInput,
  invalidJson,
  invalidProjectPayload,
}

class ProjectJsonImportPreviewResult {
  const ProjectJsonImportPreviewResult._({
    required this.status,
    this.projectedNames = const [],
    this.invalidCount = 0,
  });

  const ProjectJsonImportPreviewResult.ready({
    required List<String> projectedNames,
    required int invalidCount,
  }) : this._(
         status: ProjectJsonImportPreviewStatus.ready,
         projectedNames: projectedNames,
         invalidCount: invalidCount,
       );

  const ProjectJsonImportPreviewResult.emptyInput()
    : this._(status: ProjectJsonImportPreviewStatus.emptyInput);

  const ProjectJsonImportPreviewResult.invalidJson()
    : this._(status: ProjectJsonImportPreviewStatus.invalidJson);

  const ProjectJsonImportPreviewResult.invalidProjectPayload()
    : this._(status: ProjectJsonImportPreviewStatus.invalidProjectPayload);

  final ProjectJsonImportPreviewStatus status;
  final List<String> projectedNames;
  final int invalidCount;

  int get importableCount => projectedNames.length;
}

class ProjectJsonImportResult {
  const ProjectJsonImportResult._({
    required this.status,
    this.importedProjectName,
    this.importedCount = 0,
    this.skippedCount = 0,
  });

  const ProjectJsonImportResult.success({
    required int importedCount,
    String? importedProjectName,
    int skippedCount = 0,
  }) : this._(
         status: ProjectJsonImportStatus.success,
         importedProjectName: importedProjectName,
         importedCount: importedCount,
         skippedCount: skippedCount,
       );

  const ProjectJsonImportResult.emptyInput()
    : this._(status: ProjectJsonImportStatus.emptyInput);

  const ProjectJsonImportResult.invalidJson()
    : this._(status: ProjectJsonImportStatus.invalidJson);

  const ProjectJsonImportResult.invalidProjectPayload()
    : this._(status: ProjectJsonImportStatus.invalidProjectPayload);

  final ProjectJsonImportStatus status;
  final String? importedProjectName;
  final int importedCount;
  final int skippedCount;

  bool get isSuccess => status == ProjectJsonImportStatus.success;
}

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
      scenes: [_buildStarterScene()],
    );

    final next = [...current, project];
    await _persist(next);
  }

  Future<void> createDemoProject() async {
    final current = await future;
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      name: 'Demo Project ${current.length + 1}',
      type: ProjectType.ad,
      createdAt: now,
      updatedAt: now,
      scenes: _buildDemoScenes(),
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

  Future<void> setProjectType({
    required String projectId,
    required ProjectType type,
  }) async {
    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          if (project.type == type) {
            return project;
          }

          return Project(
            id: project.id,
            name: project.name,
            type: type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: project.scenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<int> setProjectTypeByIds({
    required Set<String> projectIds,
    required ProjectType type,
  }) async {
    if (projectIds.isEmpty) {
      return 0;
    }

    final current = await future;
    var updatedCount = 0;
    final now = DateTime.now();
    final next = current
        .map((project) {
          if (!projectIds.contains(project.id)) {
            return project;
          }
          if (project.type == type) {
            return project;
          }

          updatedCount++;
          return Project(
            id: project.id,
            name: project.name,
            type: type,
            createdAt: project.createdAt,
            updatedAt: now,
            scenes: project.scenes,
          );
        })
        .toList(growable: false);

    if (updatedCount == 0) {
      return 0;
    }

    await _persist(next);
    return updatedCount;
  }

  Future<void> deleteProject(String projectId) async {
    final current = await future;
    final next = current
        .where((project) => project.id != projectId)
        .toList(growable: false);

    await _persist(next);
  }

  Future<int> deleteProjectsByIds(Set<String> projectIds) async {
    if (projectIds.isEmpty) {
      return 0;
    }

    final current = await future;
    final next = current
        .where((project) => !projectIds.contains(project.id))
        .toList(growable: false);
    final removedCount = current.length - next.length;
    if (removedCount == 0) {
      return 0;
    }

    await _persist(next);
    return removedCount;
  }

  Future<int> duplicateProjectsByIds(Set<String> projectIds) async {
    if (projectIds.isEmpty) {
      return 0;
    }

    final current = await future;
    final now = DateTime.now();
    final existingNames = current
        .map((project) => project.name.toLowerCase())
        .toSet();
    final duplicates = <Project>[];

    for (final project in current) {
      if (!projectIds.contains(project.id)) {
        continue;
      }
      final duplicateName = _buildDuplicateProjectName(
        existingNames: existingNames,
        sourceName: project.name,
      );
      existingNames.add(duplicateName.toLowerCase());
      duplicates.add(
        Project(
          id: _uuid.v4(),
          name: duplicateName,
          type: project.type,
          createdAt: now,
          updatedAt: now,
          scenes: project.scenes,
        ),
      );
    }

    if (duplicates.isEmpty) {
      return 0;
    }

    final next = [...current, ...duplicates];
    await _persist(next);
    return duplicates.length;
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

  Future<ProjectJsonImportPreviewResult> previewProjectImportFromJson(
    String rawJson,
  ) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      return const ProjectJsonImportPreviewResult.emptyInput();
    }

    Object? decodedPayload;
    try {
      decodedPayload = jsonDecode(trimmed);
    } on FormatException {
      return const ProjectJsonImportPreviewResult.invalidJson();
    }

    final projectJsonList = _extractProjectJsonList(decodedPayload);
    if (projectJsonList.isEmpty) {
      return const ProjectJsonImportPreviewResult.invalidProjectPayload();
    }

    final current = await future;
    final existingNames = current
        .map((project) => project.name.toLowerCase())
        .toSet();
    final projectedNames = <String>[];
    var invalidCount = 0;

    for (final projectJson in projectJsonList) {
      Project importedSource;
      try {
        importedSource = Project.fromJson(projectJson);
      } catch (error) {
        final isRecoverableDataError =
            error is FormatException || error is TypeError;
        if (!isRecoverableDataError) {
          rethrow;
        }
        invalidCount++;
        continue;
      }

      final importedName = _buildImportedProjectName(
        existingNames: existingNames,
        sourceName: importedSource.name,
      );
      existingNames.add(importedName.toLowerCase());
      projectedNames.add(importedName);
    }

    if (projectedNames.isEmpty) {
      return const ProjectJsonImportPreviewResult.invalidProjectPayload();
    }

    return ProjectJsonImportPreviewResult.ready(
      projectedNames: projectedNames,
      invalidCount: invalidCount,
    );
  }

  Future<ProjectJsonImportResult> importProjectFromJson(String rawJson) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      return const ProjectJsonImportResult.emptyInput();
    }

    Object? decodedPayload;
    try {
      decodedPayload = jsonDecode(trimmed);
    } on FormatException {
      return const ProjectJsonImportResult.invalidJson();
    }

    final projectJsonList = _extractProjectJsonList(decodedPayload);
    if (projectJsonList.isEmpty) {
      return const ProjectJsonImportResult.invalidProjectPayload();
    }
    final current = await future;
    final now = DateTime.now();
    final existingNames = current
        .map((project) => project.name.toLowerCase())
        .toSet();
    final importedProjects = <Project>[];
    var skippedCount = 0;

    for (final projectJson in projectJsonList) {
      Project importedSource;
      try {
        importedSource = Project.fromJson(projectJson);
      } catch (error) {
        final isRecoverableDataError =
            error is FormatException || error is TypeError;
        if (!isRecoverableDataError) {
          rethrow;
        }
        skippedCount++;
        continue;
      }

      final importedName = _buildImportedProjectName(
        existingNames: existingNames,
        sourceName: importedSource.name,
      );
      existingNames.add(importedName.toLowerCase());
      importedProjects.add(
        Project(
          id: _uuid.v4(),
          name: importedName,
          type: importedSource.type,
          createdAt: now,
          updatedAt: now,
          scenes: importedSource.scenes.isEmpty
              ? [_buildEmptyScene(title: 'Scene 1')]
              : importedSource.scenes,
        ),
      );
    }

    if (importedProjects.isEmpty) {
      return const ProjectJsonImportResult.invalidProjectPayload();
    }

    final next = [...current, ...importedProjects];
    await _persist(next);
    return ProjectJsonImportResult.success(
      importedCount: importedProjects.length,
      importedProjectName: importedProjects.length == 1
          ? importedProjects.first.name
          : null,
      skippedCount: skippedCount,
    );
  }

  Future<void> addMessage({
    required String projectId,
    required String sceneId,
    required String characterId,
    required String text,
    required int timestampSeconds,
    required MessageStatus status,
    required bool isIncoming,
    required bool showTypingBefore,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedMessages =
                    [
                      ...scene.messages,
                      Message(
                        id: _uuid.v4(),
                        characterId: characterId,
                        text: trimmedText,
                        timestampSeconds: timestampSeconds,
                        status: status,
                        isIncoming: isIncoming,
                        showTypingBefore: showTypingBefore,
                      ),
                    ]..sort(
                      (a, b) =>
                          a.timestampSeconds.compareTo(b.timestampSeconds),
                    );

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: updatedMessages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> addCharacter({
    required String projectId,
    required String sceneId,
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedCharacters = [
                  ...scene.characters,
                  Character(
                    id: _uuid.v4(),
                    displayName: trimmedName,
                    avatarPath: null,
                    bubbleColor: '#9E77ED',
                  ),
                ];

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: updatedCharacters,
                  messages: scene.messages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> renameCharacter({
    required String projectId,
    required String sceneId,
    required String characterId,
    required String newDisplayName,
  }) async {
    final trimmedName = newDisplayName.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedCharacters = scene.characters
                    .map((character) {
                      if (character.id != characterId) {
                        return character;
                      }

                      return Character(
                        id: character.id,
                        displayName: trimmedName,
                        avatarPath: character.avatarPath,
                        bubbleColor: character.bubbleColor,
                      );
                    })
                    .toList(growable: false);

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: updatedCharacters,
                  messages: scene.messages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> deleteCharacter({
    required String projectId,
    required String sceneId,
    required String characterId,
  }) async {
    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedCharacters = scene.characters
                    .where((character) => character.id != characterId)
                    .toList(growable: false);
                final updatedMessages = scene.messages
                    .where((message) => message.characterId != characterId)
                    .toList(growable: false);

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: updatedCharacters,
                  messages: updatedMessages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> deleteMessage({
    required String projectId,
    required String sceneId,
    required String messageId,
  }) async {
    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedMessages = scene.messages
                    .where((message) => message.id != messageId)
                    .toList(growable: false);

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: updatedMessages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> updateMessageText({
    required String projectId,
    required String sceneId,
    required String messageId,
    required String newText,
  }) async {
    final current = await future;
    Project? selectedProject;
    for (final project in current) {
      if (project.id == projectId) {
        selectedProject = project;
        break;
      }
    }
    if (selectedProject == null) {
      return;
    }

    Scene? selectedScene;
    for (final scene in selectedProject.scenes) {
      if (scene.id == sceneId) {
        selectedScene = scene;
        break;
      }
    }
    if (selectedScene == null) {
      return;
    }

    Message? selectedMessage;
    for (final message in selectedScene.messages) {
      if (message.id == messageId) {
        selectedMessage = message;
        break;
      }
    }
    if (selectedMessage == null) {
      return;
    }

    await updateMessage(
      projectId: projectId,
      sceneId: sceneId,
      messageId: messageId,
      characterId: selectedMessage.characterId,
      text: newText,
      timestampSeconds: selectedMessage.timestampSeconds,
      status: selectedMessage.status,
      isIncoming: selectedMessage.isIncoming,
      showTypingBefore: selectedMessage.showTypingBefore,
    );
  }

  Future<void> updateMessage({
    required String projectId,
    required String sceneId,
    required String messageId,
    required String characterId,
    required String text,
    required int timestampSeconds,
    required MessageStatus status,
    required bool isIncoming,
    required bool showTypingBefore,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedMessages =
                    scene.messages
                        .map((message) {
                          if (message.id != messageId) {
                            return message;
                          }

                          return Message(
                            id: message.id,
                            characterId: characterId,
                            text: trimmedText,
                            timestampSeconds: timestampSeconds,
                            status: status,
                            isIncoming: isIncoming,
                            showTypingBefore: showTypingBefore,
                          );
                        })
                        .toList(growable: false)
                      ..sort(
                        (a, b) =>
                            a.timestampSeconds.compareTo(b.timestampSeconds),
                      );

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: updatedMessages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> updateSceneSettings({
    required String projectId,
    required String sceneId,
    required String title,
    required String styleId,
    required SceneAspectRatio aspectRatio,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedStyleId = styleId.trim();
    if (trimmedTitle.isEmpty || trimmedStyleId.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                return Scene(
                  id: scene.id,
                  title: trimmedTitle,
                  characters: scene.characters,
                  messages: scene.messages,
                  styleId: trimmedStyleId,
                  aspectRatio: aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<String?> addScene({
    required String projectId,
    String? title,
  }) async {
    final current = await future;
    String? addedSceneId;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final nextSceneIndex = project.scenes.length + 1;
          final scene = _buildEmptyScene(
            title: title?.trim().isNotEmpty == true
                ? title!.trim()
                : 'Scene $nextSceneIndex',
          );
          addedSceneId = scene.id;
          final updatedScenes = [...project.scenes, scene];

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
    return addedSceneId;
  }

  Future<void> renameScene({
    required String projectId,
    required String sceneId,
    required String newTitle,
  }) async {
    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    final current = await future;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                return Scene(
                  id: scene.id,
                  title: trimmedTitle,
                  characters: scene.characters,
                  messages: scene.messages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    await _persist(next);
  }

  Future<bool> deleteScene({
    required String projectId,
    required String sceneId,
  }) async {
    final current = await future;
    var deleted = false;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }
          if (project.scenes.length <= 1) {
            return project;
          }

          final updatedScenes = project.scenes
              .where((scene) => scene.id != sceneId)
              .toList(growable: false);
          deleted = updatedScenes.length != project.scenes.length;
          if (!deleted) {
            return project;
          }

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (!deleted) {
      return false;
    }

    await _persist(next);
    return true;
  }

  Future<bool> moveScene({
    required String projectId,
    required String sceneId,
    required int direction,
  }) async {
    if (direction != -1 && direction != 1) {
      return false;
    }

    final current = await future;
    var moved = false;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final scenes = [...project.scenes];
          final fromIndex = scenes.indexWhere((scene) => scene.id == sceneId);
          if (fromIndex < 0) {
            return project;
          }

          final toIndex = fromIndex + direction;
          if (toIndex < 0 || toIndex >= scenes.length) {
            return project;
          }

          final picked = scenes.removeAt(fromIndex);
          scenes.insert(toIndex, picked);
          moved = true;

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: scenes,
          );
        })
        .toList(growable: false);

    if (!moved) {
      return false;
    }

    await _persist(next);
    return true;
  }

  Future<String?> duplicateScene({
    required String projectId,
    required String sceneId,
  }) async {
    final current = await future;
    String? duplicatedSceneId;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = <Scene>[];
          for (final scene in project.scenes) {
            updatedScenes.add(scene);
            if (scene.id == sceneId) {
              final duplicated = _duplicateScene(scene);
              duplicatedSceneId = duplicated.id;
              updatedScenes.add(duplicated);
            }
          }
          if (duplicatedSceneId == null) {
            return project;
          }

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (duplicatedSceneId == null) {
      return null;
    }

    await _persist(next);
    return duplicatedSceneId;
  }

  Future<bool> moveMessageInOrder({
    required String projectId,
    required String sceneId,
    required String messageId,
    required int direction,
  }) async {
    if (direction != -1 && direction != 1) {
      return false;
    }

    final current = await future;
    var moved = false;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final orderedMessages = [...scene.messages]
                  ..sort(
                    (a, b) => a.timestampSeconds != b.timestampSeconds
                        ? a.timestampSeconds.compareTo(b.timestampSeconds)
                        : a.id.compareTo(b.id),
                  );
                final fromIndex = orderedMessages.indexWhere(
                  (message) => message.id == messageId,
                );
                if (fromIndex < 0) {
                  return scene;
                }

                final toIndex = fromIndex + direction;
                if (toIndex < 0 || toIndex >= orderedMessages.length) {
                  return scene;
                }

                final movedMessage = orderedMessages.removeAt(fromIndex);
                orderedMessages.insert(toIndex, movedMessage);
                moved = true;

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: _reindexMessagesByOrder(orderedMessages),
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (!moved) {
      return false;
    }

    await _persist(next);
    return true;
  }

  Future<int> deleteMessagesByIds({
    required String projectId,
    required String sceneId,
    required Set<String> messageIds,
  }) async {
    if (messageIds.isEmpty) {
      return 0;
    }

    final current = await future;
    var removedCount = 0;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                final updatedMessages = scene.messages
                    .where((message) {
                      final shouldRemove = messageIds.contains(message.id);
                      if (shouldRemove) {
                        removedCount++;
                      }
                      return !shouldRemove;
                    })
                    .toList(growable: false);

                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: updatedMessages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (removedCount == 0) {
      return 0;
    }

    await _persist(next);
    return removedCount;
  }

  Future<int> clearSceneMessages({
    required String projectId,
    required String sceneId,
  }) async {
    final current = await future;
    var removedCount = 0;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }

                removedCount += scene.messages.length;
                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: scene.characters,
                  messages: const [],
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (removedCount == 0) {
      return 0;
    }

    await _persist(next);
    return removedCount;
  }

  Future<bool> applySceneTemplate({
    required String projectId,
    required String sceneId,
    required String templateId,
  }) async {
    final templateData = _buildTemplateData(templateId);
    if (templateData == null) {
      return false;
    }

    final current = await future;
    var applied = false;
    final next = current
        .map((project) {
          if (project.id != projectId) {
            return project;
          }

          final updatedScenes = project.scenes
              .map((scene) {
                if (scene.id != sceneId) {
                  return scene;
                }
                applied = true;
                return Scene(
                  id: scene.id,
                  title: scene.title,
                  characters: templateData.characters,
                  messages: templateData.messages,
                  styleId: scene.styleId,
                  aspectRatio: scene.aspectRatio,
                );
              })
              .toList(growable: false);

          return Project(
            id: project.id,
            name: project.name,
            type: project.type,
            createdAt: project.createdAt,
            updatedAt: DateTime.now(),
            scenes: updatedScenes,
          );
        })
        .toList(growable: false);

    if (!applied) {
      return false;
    }

    await _persist(next);
    return true;
  }

  List<Map<String, dynamic>> _extractProjectJsonList(Object? decodedPayload) {
    final directList = _asJsonList(decodedPayload);
    if (directList.isNotEmpty) {
      return directList;
    }

    final directMap = _asJsonMap(decodedPayload);
    if (directMap != null) {
      final nestedProjects = _asJsonList(directMap['projects']);
      if (nestedProjects.isNotEmpty) {
        return nestedProjects;
      }
      final nestedProject = _asJsonMap(directMap['project']);
      if (nestedProject != null) {
        return [nestedProject];
      }
      return [directMap];
    }

    return const [];
  }

  List<Map<String, dynamic>> _asJsonList(Object? value) {
    if (value is! List) {
      return const [];
    }

    final maps = <Map<String, dynamic>>[];
    for (final item in value) {
      final map = _asJsonMap(item);
      if (map == null) {
        continue;
      }
      maps.add(map);
    }
    return maps;
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is! Map) {
      return null;
    }

    final casted = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      casted[key] = entry.value;
    }
    return casted;
  }

  String _buildImportedProjectName({
    required Set<String> existingNames,
    required String sourceName,
  }) {
    final normalizedBaseName = sourceName.trim().isEmpty
        ? 'Imported Project'
        : sourceName.trim();

    if (!existingNames.contains(normalizedBaseName.toLowerCase())) {
      return normalizedBaseName;
    }

    var suffix = 1;
    while (true) {
      final candidate = suffix == 1
          ? '$normalizedBaseName (Imported)'
          : '$normalizedBaseName (Imported $suffix)';
      if (!existingNames.contains(candidate.toLowerCase())) {
        return candidate;
      }
      suffix++;
    }
  }

  String _buildDuplicateProjectName({
    required Set<String> existingNames,
    required String sourceName,
  }) {
    final normalizedBaseName = sourceName.trim().isEmpty
        ? 'Project'
        : sourceName.trim();
    final copyBase = '$normalizedBaseName Copy';

    if (!existingNames.contains(copyBase.toLowerCase())) {
      return copyBase;
    }

    var suffix = 2;
    while (true) {
      final candidate = '$copyBase $suffix';
      if (!existingNames.contains(candidate.toLowerCase())) {
        return candidate;
      }
      suffix++;
    }
  }

  Future<void> _persist(List<Project> projects) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveAll(projects);
      return projects;
    });
  }

  Scene _buildStarterScene() {
    final firstCharacterId = _uuid.v4();
    final secondCharacterId = _uuid.v4();

    return Scene(
      id: _uuid.v4(),
      title: 'Scene 1',
      styleId: 'studio_slate',
      aspectRatio: SceneAspectRatio.portrait9x16,
      characters: [
        Character(
          id: firstCharacterId,
          displayName: 'Alex',
          avatarPath: null,
          bubbleColor: '#2E90FA',
        ),
        Character(
          id: secondCharacterId,
          displayName: 'Mia',
          avatarPath: null,
          bubbleColor: '#12B76A',
        ),
      ],
      messages: [
        Message(
          id: _uuid.v4(),
          characterId: firstCharacterId,
          text: 'Ready for set in 10?',
          timestampSeconds: 0,
          status: MessageStatus.sent,
          isIncoming: false,
          showTypingBefore: false,
        ),
        Message(
          id: _uuid.v4(),
          characterId: secondCharacterId,
          text: 'Yes, prop phone is prepared.',
          timestampSeconds: 4,
          status: MessageStatus.delivered,
          isIncoming: true,
          showTypingBefore: true,
        ),
        Message(
          id: _uuid.v4(),
          characterId: firstCharacterId,
          text: 'Great, rolling in 3 minutes.',
          timestampSeconds: 9,
          status: MessageStatus.seen,
          isIncoming: false,
          showTypingBefore: true,
        ),
      ],
    );
  }

  Scene _buildEmptyScene({required String title}) {
    final firstCharacterId = _uuid.v4();
    final secondCharacterId = _uuid.v4();
    return Scene(
      id: _uuid.v4(),
      title: title,
      styleId: 'studio_slate',
      aspectRatio: SceneAspectRatio.portrait9x16,
      characters: [
        Character(
          id: firstCharacterId,
          displayName: 'Alex',
          avatarPath: null,
          bubbleColor: '#2E90FA',
        ),
        Character(
          id: secondCharacterId,
          displayName: 'Mia',
          avatarPath: null,
          bubbleColor: '#12B76A',
        ),
      ],
      messages: const [],
    );
  }

  Scene _duplicateScene(Scene source) {
    final characterIdMap = <String, String>{};
    final duplicatedCharacters = source.characters
        .map((character) {
          final newId = _uuid.v4();
          characterIdMap[character.id] = newId;
          return Character(
            id: newId,
            displayName: character.displayName,
            avatarPath: character.avatarPath,
            bubbleColor: character.bubbleColor,
          );
        })
        .toList(growable: false);

    final duplicatedMessages = source.messages
        .map((message) {
          final mappedCharacterId = characterIdMap[message.characterId];
          return Message(
            id: _uuid.v4(),
            characterId: mappedCharacterId ?? message.characterId,
            text: message.text,
            timestampSeconds: message.timestampSeconds,
            status: message.status,
            isIncoming: message.isIncoming,
            showTypingBefore: message.showTypingBefore,
          );
        })
        .toList(growable: false);

    return Scene(
      id: _uuid.v4(),
      title: '${source.title} Copy',
      characters: duplicatedCharacters,
      messages: duplicatedMessages,
      styleId: source.styleId,
      aspectRatio: source.aspectRatio,
    );
  }

  List<Message> _reindexMessagesByOrder(List<Message> orderedMessages) {
    if (orderedMessages.isEmpty) {
      return const [];
    }

    final reindexed = <Message>[];
    for (var i = 0; i < orderedMessages.length; i++) {
      final message = orderedMessages[i];
      reindexed.add(
        Message(
          id: message.id,
          characterId: message.characterId,
          text: message.text,
          timestampSeconds: i,
          status: message.status,
          isIncoming: message.isIncoming,
          showTypingBefore: message.showTypingBefore,
        ),
      );
    }
    return reindexed;
  }

  _SceneTemplateData? _buildTemplateData(String templateId) {
    switch (templateId) {
      case 'briefing':
        final producerId = _uuid.v4();
        final propLeadId = _uuid.v4();
        return _SceneTemplateData(
          characters: [
            Character(
              id: producerId,
              displayName: 'Producer',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
            Character(
              id: propLeadId,
              displayName: 'Prop Lead',
              avatarPath: null,
              bubbleColor: '#12B76A',
            ),
          ],
          messages: [
            Message(
              id: _uuid.v4(),
              characterId: producerId,
              text: 'Call time shifted to 08:30.',
              timestampSeconds: 0,
              status: MessageStatus.sent,
              isIncoming: false,
              showTypingBefore: false,
            ),
            Message(
              id: _uuid.v4(),
              characterId: propLeadId,
              text: 'Copy. Updating prop handoff list now.',
              timestampSeconds: 2,
              status: MessageStatus.delivered,
              isIncoming: true,
              showTypingBefore: true,
            ),
            Message(
              id: _uuid.v4(),
              characterId: producerId,
              text: 'Thanks. Share final checklist before rollout.',
              timestampSeconds: 5,
              status: MessageStatus.seen,
              isIncoming: false,
              showTypingBefore: true,
            ),
          ],
        );
      case 'group_alert':
        final adId = _uuid.v4();
        final cameraId = _uuid.v4();
        final soundId = _uuid.v4();
        return _SceneTemplateData(
          characters: [
            Character(
              id: adId,
              displayName: '1st AD',
              avatarPath: null,
              bubbleColor: '#F79009',
            ),
            Character(
              id: cameraId,
              displayName: 'Camera',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
            Character(
              id: soundId,
              displayName: 'Sound',
              avatarPath: null,
              bubbleColor: '#12B76A',
            ),
          ],
          messages: [
            Message(
              id: _uuid.v4(),
              characterId: adId,
              text: 'Stand by for rehearsal in 90 seconds.',
              timestampSeconds: 0,
              status: MessageStatus.sent,
              isIncoming: false,
              showTypingBefore: false,
            ),
            Message(
              id: _uuid.v4(),
              characterId: cameraId,
              text: 'Camera locked. Ready on A.',
              timestampSeconds: 1,
              status: MessageStatus.delivered,
              isIncoming: true,
              showTypingBefore: false,
            ),
            Message(
              id: _uuid.v4(),
              characterId: soundId,
              text: 'Boom clear. Rolling tone.',
              timestampSeconds: 3,
              status: MessageStatus.delivered,
              isIncoming: true,
              showTypingBefore: true,
            ),
            Message(
              id: _uuid.v4(),
              characterId: adId,
              text: 'Great. Go for rehearsal.',
              timestampSeconds: 5,
              status: MessageStatus.seen,
              isIncoming: false,
              showTypingBefore: true,
            ),
          ],
        );
      default:
        return null;
    }
  }

  List<Scene> _buildDemoScenes() {
    final sceneOneProducerId = _uuid.v4();
    final sceneOneTalentId = _uuid.v4();
    final sceneOneDirectorId = _uuid.v4();

    final sceneTwoProducerId = _uuid.v4();
    final sceneTwoCameraId = _uuid.v4();

    return [
      Scene(
        id: _uuid.v4(),
        title: 'Scene 1 - Prep Chat',
        styleId: 'studio_default',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: sceneOneProducerId,
            displayName: 'Producer',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: sceneOneTalentId,
            displayName: 'Talent',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
          Character(
            id: sceneOneDirectorId,
            displayName: 'Director',
            avatarPath: null,
            bubbleColor: '#F79009',
          ),
        ],
        messages: [
          Message(
            id: _uuid.v4(),
            characterId: sceneOneProducerId,
            text: 'Call time confirmed for 08:30.',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: _uuid.v4(),
            characterId: sceneOneTalentId,
            text: 'Arriving in 20 minutes.',
            timestampSeconds: 3,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: _uuid.v4(),
            characterId: sceneOneDirectorId,
            text: 'We start with close-up, then hallway walk.',
            timestampSeconds: 7,
            status: MessageStatus.seen,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: _uuid.v4(),
            characterId: sceneOneProducerId,
            text: 'Copy that, props are already on set.',
            timestampSeconds: 11,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      ),
      Scene(
        id: _uuid.v4(),
        title: 'Scene 2 - Rolling',
        styleId: 'night_shift',
        aspectRatio: SceneAspectRatio.landscape16x9,
        characters: [
          Character(
            id: sceneTwoProducerId,
            displayName: 'Producer',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: sceneTwoCameraId,
            displayName: 'Camera Op',
            avatarPath: null,
            bubbleColor: '#7A5AF8',
          ),
        ],
        messages: [
          Message(
            id: _uuid.v4(),
            characterId: sceneTwoProducerId,
            text: 'Rolling in 5, stand by.',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: _uuid.v4(),
            characterId: sceneTwoCameraId,
            text: 'Frame locked. Exposure set.',
            timestampSeconds: 4,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: _uuid.v4(),
            characterId: sceneTwoProducerId,
            text: 'Action on my mark.',
            timestampSeconds: 8,
            status: MessageStatus.seen,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      ),
    ];
  }
}

class _SceneTemplateData {
  const _SceneTemplateData({
    required this.characters,
    required this.messages,
  });

  final List<Character> characters;
  final List<Message> messages;
}
