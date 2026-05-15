import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/data/services/video_export_fallback_service.dart';
import 'package:production_chat_prop/features/projects/data/services/project_package_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('export QA fixture', () {
    late Project fixtureProject;

    setUpAll(() {
      fixtureProject = _loadFixtureProject();
    });

    test('parses the tracked export QA project for manual beta passes', () {
      expect(fixtureProject.id, 'qa-export-project');
      expect(fixtureProject.name, 'Export QA Project');
      expect(fixtureProject.type, ProjectType.ad);
      expect(fixtureProject.scenes, hasLength(4));

      final portraitScene = fixtureProject.scenes.singleWhere(
        (scene) => scene.id == 'qa-scene-hero-portrait',
      );
      final landscapeScene = fixtureProject.scenes.singleWhere(
        (scene) => scene.id == 'qa-scene-hero-landscape',
      );
      final emptyScene = fixtureProject.scenes.singleWhere(
        (scene) => scene.id == 'qa-scene-empty-export',
      );
      final longScene = fixtureProject.scenes.singleWhere(
        (scene) => scene.id == 'qa-scene-long-run',
      );

      expect(portraitScene.aspectRatio, SceneAspectRatio.portrait9x16);
      expect(portraitScene.messages, hasLength(4));
      expect(landscapeScene.aspectRatio, SceneAspectRatio.landscape16x9);
      expect(landscapeScene.messages, hasLength(3));
      expect(emptyScene.messages, isEmpty);
      expect(longScene.messages, hasLength(16));
      expect(
        fixtureProject.scenes.fold<int>(
          0,
          (total, scene) => total + scene.messages.length,
        ),
        23,
      );
    });

    test(
      'project package export keeps all QA scenes in the handoff payload',
      () async {
        List<int>? capturedBytes;
        String? capturedFilename;

        final service = ProjectPackageExportService(
          downloader:
              ({required bytes, required filename, required mimeType}) async {
                capturedBytes = bytes;
                capturedFilename = filename;
                expect(mimeType, 'application/json');
                return true;
              },
        );

        final result = await service.exportProjectPackage(
          project: fixtureProject,
        );

        expect(result.isSuccess, isTrue);
        expect(result.filename, capturedFilename);
        expect(capturedFilename, startsWith('pcp_project_export_qa_project_'));

        final payload =
            jsonDecode(utf8.decode(capturedBytes!)) as Map<String, dynamic>;
        final projectPayload = payload['project'] as Map<String, dynamic>;
        final scenes = (projectPayload['scenes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        expect(
          (payload['meta'] as Map<String, dynamic>)['format'],
          'project_package',
        );
        expect(scenes, hasLength(4));
        expect(
          scenes.map((scene) => scene['title']),
          containsAll(<String>[
            'Scene 1 - Hero Portrait',
            'Scene 2 - Hero Landscape',
            'Scene 3 - Empty Export Check',
            'Scene 4 - Long Playback Run',
          ]),
        );
        expect(
          scenes.singleWhere(
                (scene) => scene['id'] == 'qa-scene-empty-export',
              )['messages']
              as List<dynamic>,
          isEmpty,
        );
      },
    );

    test('video fallback export keeps the selected QA scene synchronized', () {
      final service = VideoExportFallbackService();
      final selectedScene = fixtureProject.scenes.singleWhere(
        (scene) => scene.id == 'qa-scene-hero-landscape',
      );

      final jsonText = service.buildFallbackPackageJson(
        project: fixtureProject,
        scene: selectedScene,
        includeDeviceFrame: false,
        cleanPreview: true,
      );

      final payload = jsonDecode(jsonText) as Map<String, dynamic>;
      final renderHints = payload['renderHints'] as Map<String, dynamic>;
      final exportedScene = payload['selectedScene'] as Map<String, dynamic>;
      final exportedMessages = (exportedScene['messages'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final projectScenes =
          ((payload['project'] as Map<String, dynamic>)['scenes']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final synchronizedProjectScene = projectScenes.singleWhere(
        (scene) => scene['id'] == selectedScene.id,
      );
      final synchronizedMessages =
          (synchronizedProjectScene['messages'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

      expect(exportedScene['id'], selectedScene.id);
      expect(exportedScene['aspectRatio'], 'landscape16x9');
      expect(
        exportedMessages.map((message) => message['timestampSeconds']),
        orderedEquals([0, 5, 11]),
      );
      expect(
        synchronizedMessages.map((message) => message['timestampSeconds']),
        orderedEquals([0, 5, 11]),
      );
      expect(renderHints['includeDeviceFrame'], isFalse);
      expect(renderHints['cleanPreview'], isTrue);
    });
  });
}

Project _loadFixtureProject() {
  final file = _resolveFixtureFile();
  final rawJson = file.readAsStringSync();
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
  return Project.fromJson(decoded);
}

File _resolveFixtureFile() {
  var currentDirectory = Directory.current.absolute;

  while (true) {
    final candidate = File(
      '${currentDirectory.path}${Platform.pathSeparator}docs${Platform.pathSeparator}fixtures${Platform.pathSeparator}export-qa-project.json',
    );
    if (candidate.existsSync()) {
      return candidate;
    }

    final parentDirectory = currentDirectory.parent;
    if (parentDirectory.path == currentDirectory.path) {
      throw StateError(
        'Could not locate docs/fixtures/export-qa-project.json from ${Directory.current.path}.',
      );
    }
    currentDirectory = parentDirectory;
  }
}
