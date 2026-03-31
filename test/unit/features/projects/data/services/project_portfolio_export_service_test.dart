import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/projects/data/services/project_portfolio_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  test('exportPortfolio encodes batch projects payload for download', () async {
    List<int>? capturedBytes;
    String? capturedFilename;
    String? capturedMimeType;

    final service = ProjectPortfolioExportService(
      downloader:
          ({required bytes, required filename, required mimeType}) async {
            capturedBytes = bytes;
            capturedFilename = filename;
            capturedMimeType = mimeType;
            return true;
          },
    );

    final result = await service.exportPortfolio(
      projects: [_sampleProject('One'), _sampleProject('Two')],
    );

    expect(result.isSuccess, isTrue);
    expect(result.filename, capturedFilename);
    expect(capturedMimeType, 'application/json');
    expect(capturedFilename, startsWith('pcp_project_portfolio_'));
    expect(capturedFilename, endsWith('.json'));

    final decoded =
        jsonDecode(utf8.decode(capturedBytes!)) as Map<String, dynamic>;
    final meta = decoded['meta'] as Map<String, dynamic>;
    final projects = decoded['projects'] as List<dynamic>;

    expect(meta['format'], 'project_portfolio');
    expect(projects, hasLength(2));
    expect((projects.first as Map<String, dynamic>)['name'], 'Project One');
    expect((projects.last as Map<String, dynamic>)['name'], 'Project Two');
  });

  test('exportPortfolio fails fast when project list is empty', () async {
    var downloaderCalled = false;
    final service = ProjectPortfolioExportService(
      downloader:
          ({required bytes, required filename, required mimeType}) async {
            downloaderCalled = true;
            return true;
          },
    );

    final result = await service.exportPortfolio(projects: const []);

    expect(result.isSuccess, isFalse);
    expect(result.failure, ProjectPortfolioExportFailure.noProjects);
    expect(downloaderCalled, isFalse);
  });

  test('buildPortfolioJson returns encoded payload without downloader', () {
    final service = ProjectPortfolioExportService();

    final jsonText = service.buildPortfolioJson(
      projects: [_sampleProject('One'), _sampleProject('Two')],
    );
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final projects = decoded['projects'] as List<dynamic>;

    expect(decoded['meta'], isA<Map<String, dynamic>>());
    expect(projects, hasLength(2));
    expect((projects.first as Map<String, dynamic>)['name'], 'Project One');
    expect((projects.last as Map<String, dynamic>)['name'], 'Project Two');
  });

  test(
    'exportPortfolio reports downloadUnavailable when downloader fails',
    () async {
      final service = ProjectPortfolioExportService(
        downloader:
            ({required bytes, required filename, required mimeType}) async {
              return false;
            },
      );

      final result = await service.exportPortfolio(
        projects: [_sampleProject('One')],
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ProjectPortfolioExportFailure.downloadUnavailable);
      expect(result.filename, isNull);
    },
  );
}

Project _sampleProject(String suffix) {
  final now = DateTime.utc(2026, 3, 31);

  return Project(
    id: 'project-$suffix',
    name: 'Project $suffix',
    type: ProjectType.other,
    createdAt: now,
    updatedAt: now,
    scenes: const [
      Scene(
        id: 'scene-1',
        title: 'Scene 1',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'char-1',
            displayName: 'Alex',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [
          Message(
            id: 'msg-1',
            characterId: 'char-1',
            text: 'Portfolio sample',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      ),
    ],
  );
}
