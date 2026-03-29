import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/data/services/video_export_fallback_service.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('VideoExportFallbackService', () {
    test('exports sorted scene payload when downloader succeeds', () async {
      List<int>? capturedBytes;
      String? capturedFilename;
      String? capturedMimeType;

      final service = VideoExportFallbackService(
        downloader: ({
          required bytes,
          required filename,
          required mimeType,
        }) async {
          capturedBytes = bytes;
          capturedFilename = filename;
          capturedMimeType = mimeType;
          return true;
        },
      );

      const scene = Scene(
        id: 's1',
        title: 'Scene One',
        styleId: 'style_a',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'c1',
            displayName: 'Lead',
            avatarPath: null,
            bubbleColor: '#00AA88',
          ),
        ],
        messages: [
          Message(
            id: 'm2',
            characterId: 'c1',
            text: 'Later message',
            timestampSeconds: 4,
            status: MessageStatus.seen,
            isIncoming: true,
            showTypingBefore: false,
          ),
          Message(
            id: 'm1',
            characterId: 'c1',
            text: 'First message',
            timestampSeconds: 1,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: true,
          ),
        ],
      );
      final project = Project(
        id: 'p1',
        name: 'Demo',
        type: ProjectType.ad,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        scenes: [scene],
      );

      final result = await service.exportFallbackPackage(
        project: project,
        scene: scene,
        includeDeviceFrame: false,
        cleanPreview: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.filename, isNotNull);
      expect(result.filename, endsWith('.json'));
      expect(capturedFilename, equals(result.filename));
      expect(capturedMimeType, equals('application/json'));
      expect(capturedBytes, isNotNull);

      final payload = jsonDecode(
        utf8.decode(capturedBytes!),
      ) as Map<String, dynamic>;
      final selectedScene = payload['selectedScene'] as Map<String, dynamic>;
      final messages = selectedScene['messages'] as List<dynamic>;
      expect((messages.first as Map<String, dynamic>)['timestampSeconds'], 1);
      expect((messages.last as Map<String, dynamic>)['timestampSeconds'], 4);

      final renderHints = payload['renderHints'] as Map<String, dynamic>;
      expect(renderHints['includeDeviceFrame'], isFalse);
      expect(renderHints['cleanPreview'], isTrue);
    });

    test('returns failure when downloader is unavailable', () async {
      final service = VideoExportFallbackService(
        downloader: ({
          required bytes,
          required filename,
          required mimeType,
        }) async =>
            false,
      );

      const scene = Scene(
        id: 's1',
        title: 'Scene',
        styleId: 'style',
        aspectRatio: SceneAspectRatio.landscape16x9,
        characters: [],
        messages: [],
      );
      final project = Project(
        id: 'p1',
        name: 'Project',
        type: ProjectType.other,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        scenes: [scene],
      );

      final result = await service.exportFallbackPackage(
        project: project,
        scene: scene,
        includeDeviceFrame: true,
        cleanPreview: false,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, VideoFallbackExportFailure.downloadUnavailable);
    });
  });
}
