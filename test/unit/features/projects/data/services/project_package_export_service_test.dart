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
    expect(capturedMimeType, 'application/json');
    expect(capturedFilename, startsWith('pcp_project_export_project_'));
    expect(capturedFilename, endsWith('.json'));

    final decoded =
        jsonDecode(utf8.decode(capturedBytes!)) as Map<String, dynamic>;
    final meta = decoded['meta'] as Map<String, dynamic>;
    final project = decoded['project'] as Map<String, dynamic>;

    expect(meta['format'], 'project_package');
    expect(meta['tool'], 'Production Chat Prop');
    expect(project['name'], 'Export Project');
    expect(project['type'], 'series');
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
      expect(result.filename, isNull);
    },
  );
}

Project _sampleProject() {
  final now = DateTime.utc(2026, 3, 30);

  return Project(
    id: 'project-export-1',
    name: 'Export Project',
    type: ProjectType.series,
    createdAt: now,
    updatedAt: now,
    scenes: const [
      Scene(
        id: 'scene-export-1',
        title: 'Scene Export',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'char-export-1',
            displayName: 'Taylor',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
        ],
        messages: [
          Message(
            id: 'msg-export-1',
            characterId: 'char-export-1',
            text: 'Export-ready line',
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
