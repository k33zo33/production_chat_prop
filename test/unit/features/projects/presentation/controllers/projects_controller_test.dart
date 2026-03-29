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
