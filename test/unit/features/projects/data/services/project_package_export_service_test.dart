import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/projects/data/services/project_package_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  test('exportProjectPackage encodes project payload for download', () async {
    List<int>? capturedBytes;
    String? capturedFilename;
    String? capturedMimeType;

    final service = ProjectPackageExportService(
      downloader:
          ({required bytes, required filename, required mimeType}) async {
            capturedBytes = bytes;
            capturedFilename = filename;
            capturedMimeType = mimeType;
            return true;
          },
    );

    final result = await service.exportProjectPackage(
      project: _sampleProject(),
    );

    expect(result.isSuccess, isTrue);
    expect(result.filename, capturedFilename);
    expect(result.jsonText, utf8.decode(capturedBytes!));
    expect(capturedMimeType, 'application/json');
    expect(capturedFilename, startsWith('pcp_project_export_project_'));
    expect(capturedFilename, endsWith('.json'));

    final decoded = jsonDecode(result.jsonText) as Map<String, dynamic>;
    final meta = decoded['meta'] as Map<String, dynamic>;
    final project = decoded['project'] as Map<String, dynamic>;
    final qa = decoded['qa'] as Map<String, dynamic>;
    final projectQa = qa['project'] as Map<String, dynamic>;
    final scenesQa = qa['scenes'] as List<dynamic>;

    expect(meta['format'], 'project_package');
    expect(meta['tool'], 'Production Chat Prop');
    expect(project['name'], 'Export Project');
    expect(project['type'], 'series');
    expect(projectQa['totalScenes'], 1);
    expect(projectQa['readyScenes'], 1);
    expect(projectQa['hasTimelineWarnings'], isFalse);
    expect(scenesQa, hasLength(1));
    expect((scenesQa.single as Map<String, dynamic>)['id'], 'scene-export-1');
  });

  test(
    'exportProjectPackage reports downloadUnavailable when downloader fails',
    () async {
      final service = ProjectPackageExportService(
        downloader:
            ({required bytes, required filename, required mimeType}) async {
              return false;
            },
      );

      final result = await service.exportProjectPackage(
        project: _sampleProject(),
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ProjectPackageExportFailure.downloadUnavailable);
      expect(result.filename, startsWith('pcp_project_export_project_'));
      expect(result.jsonText, contains('"format": "project_package"'));
    },
  );

  test('exportProjectPackage falls back to a safe filename segment', () async {
    String? capturedFilename;

    final service = ProjectPackageExportService(
      downloader:
          ({required bytes, required filename, required mimeType}) async {
            capturedFilename = filename;
            return true;
          },
    );

    final result = await service.exportProjectPackage(
      project: _sampleProject(name: '###'),
    );

    expect(result.isSuccess, isTrue);
    expect(capturedFilename, startsWith('pcp_project_project_'));
  });

  test(
    'buildProjectPackageJson returns readable payload without downloader',
    () {
      final service = ProjectPackageExportService();

      final decoded =
          jsonDecode(
                service.buildProjectPackageJson(project: _sampleProject()),
              )
              as Map<String, dynamic>;

      expect(decoded['project'], isA<Map<String, dynamic>>());
      expect(
        (decoded['meta'] as Map<String, dynamic>)['format'],
        'project_package',
      );
      expect(
        ((decoded['project'] as Map<String, dynamic>)['scenes'] as List).length,
        1,
      );
      expect(decoded['qa'], isA<Map<String, dynamic>>());
    },
  );

  test('project package export includes scene QA summaries', () {
    final service = ProjectPackageExportService();

    final decoded =
        jsonDecode(
              service.buildProjectPackageJson(
                project: _sampleProject(
                  unusedCharacterName: 'Morgan',
                  includeSharedTimestamp: true,
                ),
              ),
            )
            as Map<String, dynamic>;
    final qa = decoded['qa'] as Map<String, dynamic>;
    final projectQa = qa['project'] as Map<String, dynamic>;
    final sceneQa =
        (qa['scenes'] as List<dynamic>).single as Map<String, dynamic>;

    expect(projectQa['needsAttention'], isTrue);
    expect(projectQa['unusedCharacterCount'], 1);
    expect(projectQa['sharedTimestampCount'], 1);
    expect(projectQa['firstAttentionSceneId'], 'scene-export-1');
    expect(sceneQa['unusedCharacterNames'], ['Morgan']);
    expect(sceneQa['sharedTimestampMessageIds'], [
      'msg-export-1',
      'msg-export-2',
    ]);
    expect(sceneQa['timelineWarningMessageIds'], [
      'msg-export-1',
      'msg-export-2',
    ]);
    expect(sceneQa['timelineStatusLabel'], contains('1 shared timestamp'));
  });

  test('project package export preserves character avatar references', () {
    final service = ProjectPackageExportService();

    final decoded =
        jsonDecode(
              service.buildProjectPackageJson(
                project: _sampleProject(
                  avatarPath: 'https://example.com/taylor.png',
                ),
              ),
            )
            as Map<String, dynamic>;
    final project = decoded['project'] as Map<String, dynamic>;
    final scenes = project['scenes'] as List<dynamic>;
    final characters =
        (scenes.single as Map<String, dynamic>)['characters'] as List<dynamic>;

    expect(
      (characters.single as Map<String, dynamic>)['avatarPath'],
      'https://example.com/taylor.png',
    );
  });
}

Project _sampleProject({
  String name = 'Export Project',
  String? avatarPath,
  String? unusedCharacterName,
  bool includeSharedTimestamp = false,
}) {
  final now = DateTime.utc(2026, 3, 30);

  return Project(
    id: 'project-export-1',
    name: name,
    type: ProjectType.series,
    createdAt: now,
    updatedAt: now,
    scenes: [
      Scene(
        id: 'scene-export-1',
        title: 'Scene Export',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'char-export-1',
            displayName: 'Taylor',
            avatarPath: avatarPath,
            bubbleColor: '#2E90FA',
          ),
          if (unusedCharacterName != null)
            Character(
              id: 'char-export-2',
              displayName: unusedCharacterName,
              avatarPath: null,
              bubbleColor: '#F97316',
            ),
        ],
        messages: [
          const Message(
            id: 'msg-export-1',
            characterId: 'char-export-1',
            text: 'Export-ready line',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
          if (includeSharedTimestamp)
            const Message(
              id: 'msg-export-2',
              characterId: 'char-export-1',
              text: 'Shared timestamp line',
              timestampSeconds: 0,
              status: MessageStatus.delivered,
              isIncoming: true,
              showTypingBefore: false,
            ),
        ],
      ),
    ],
  );
}
