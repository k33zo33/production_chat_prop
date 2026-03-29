import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/projects/data/datasources/local_project_datasource.dart';
import 'package:production_chat_prop/features/projects/data/repositories/local_project_repository.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalProjectRepository', () {
    late LocalProjectRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const LocalProjectRepository(LocalProjectDatasource());
    });

    test('returns empty list when nothing is stored', () async {
      final projects = await repository.getAll();

      expect(projects, isEmpty);
    });

    test('saves and loads projects using shared preferences', () async {
      final project = _sampleProject();

      await repository.saveAll([project]);
      final loaded = await repository.getAll();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, project.id);
      expect(loaded.first.name, project.name);
      expect(loaded.first.type, project.type);
      expect(loaded.first.scenes, hasLength(1));
      expect(loaded.first.scenes.first.characters, hasLength(2));
      expect(loaded.first.scenes.first.messages, hasLength(2));
      expect(loaded.first.scenes.first.messages.first.text, 'Message one');
    });
  });
}

Project _sampleProject() {
  final createdAt = DateTime.utc(2026, 3, 29, 12);

  return Project(
    id: 'project-1',
    name: 'Sample Project',
    type: ProjectType.ad,
    createdAt: createdAt,
    updatedAt: createdAt,
    scenes: const [
      Scene(
        id: 'scene-1',
        title: 'Intro',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'c1',
            displayName: 'Alex',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: 'c2',
            displayName: 'Mia',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
        ],
        messages: [
          Message(
            id: 'm1',
            characterId: 'c1',
            text: 'Message one',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          Message(
            id: 'm2',
            characterId: 'c2',
            text: 'Message two',
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
