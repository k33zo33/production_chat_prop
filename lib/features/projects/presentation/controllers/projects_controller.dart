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
    final trimmedText = newText.trim();
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

                final updatedMessages = scene.messages
                    .map((message) {
                      if (message.id != messageId) {
                        return message;
                      }

                      return Message(
                        id: message.id,
                        characterId: message.characterId,
                        text: trimmedText,
                        timestampSeconds: message.timestampSeconds,
                        status: message.status,
                        isIncoming: message.isIncoming,
                        showTypingBefore: message.showTypingBefore,
                      );
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

    await _persist(next);
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
}
