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
        downloader:
            ({
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
            avatarPath: 'https://example.com/lead.png',
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

      final payload =
          jsonDecode(
                utf8.decode(capturedBytes!),
              )
              as Map<String, dynamic>;
      final selectedScene = payload['selectedScene'] as Map<String, dynamic>;
      final messages = selectedScene['messages'] as List<dynamic>;
      expect((messages.first as Map<String, dynamic>)['timestampSeconds'], 1);
      expect((messages.last as Map<String, dynamic>)['timestampSeconds'], 4);

      final projectPayload = payload['project'] as Map<String, dynamic>;
      final projectScenes = projectPayload['scenes'] as List<dynamic>;
      final exportedScene = projectScenes.single as Map<String, dynamic>;
      final exportedCharacter =
          (exportedScene['characters'] as List<dynamic>).single
              as Map<String, dynamic>;
      final projectMessages = exportedScene['messages'] as List<dynamic>;
      expect(
        (projectMessages.first as Map<String, dynamic>)['timestampSeconds'],
        1,
      );
      expect(
        (projectMessages.last as Map<String, dynamic>)['timestampSeconds'],
        4,
      );
      expect(exportedCharacter['avatarPath'], 'https://example.com/lead.png');

      final renderHints = payload['renderHints'] as Map<String, dynamic>;
      expect(renderHints['includeDeviceFrame'], isFalse);
      expect(renderHints['cleanPreview'], isTrue);

      final qa = payload['qa'] as Map<String, dynamic>;
      final projectQa = qa['project'] as Map<String, dynamic>;
      final selectedSceneQa = qa['selectedScene'] as Map<String, dynamic>;
      final sceneQaList = qa['scenes'] as List<dynamic>;
      expect(projectQa['totalScenes'], 1);
      expect(projectQa['readyScenes'], 1);
      expect(projectQa['needsAttention'], isFalse);
      expect(selectedSceneQa['messageCount'], 2);
      expect(selectedSceneQa['hasTimelineWarnings'], isFalse);
      expect(selectedSceneQa['unusedCharacterNames'], isEmpty);
      expect(sceneQaList, hasLength(1));
      expect(
        (sceneQaList.single as Map<String, dynamic>)['id'],
        scene.id,
      );
    });

    test('returns failure when downloader is unavailable', () async {
      final service = VideoExportFallbackService(
        downloader:
            ({
              required bytes,
              required filename,
              required mimeType,
            }) async => false,
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

    test(
      'uses safe fallback filename segments for blank export labels',
      () async {
        String? capturedFilename;

        final service = VideoExportFallbackService(
          downloader:
              ({
                required bytes,
                required filename,
                required mimeType,
              }) async {
                capturedFilename = filename;
                return true;
              },
        );

        const scene = Scene(
          id: 's1',
          title: '###',
          styleId: 'style',
          aspectRatio: SceneAspectRatio.landscape16x9,
          characters: [],
          messages: [],
        );
        final project = Project(
          id: 'p1',
          name: '***',
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

        expect(result.isSuccess, isTrue);
        expect(
          capturedFilename,
          startsWith('pcp_video_fallback_project_scene_'),
        );
      },
    );

    test(
      'buildFallbackPackageJson returns readable payload for clipboard fallback',
      () {
        final service = VideoExportFallbackService();
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

        final jsonText = service.buildFallbackPackageJson(
          project: project,
          scene: scene,
          includeDeviceFrame: true,
          cleanPreview: false,
        );

        final payload = jsonDecode(jsonText) as Map<String, dynamic>;
        expect(
          (payload['meta'] as Map<String, dynamic>)['format'],
          'video_fallback_package',
        );
        expect(
          (payload['renderHints']
              as Map<String, dynamic>)['includeDeviceFrame'],
          isTrue,
        );
        expect(
          (payload['selectedScene'] as Map<String, dynamic>)['title'],
          'Scene',
        );
      },
    );

    test(
      'buildFallbackPackageJson keeps the selected scene synchronized inside the project payload',
      () {
        final service = VideoExportFallbackService();
        const selectedScene = Scene(
          id: 'scene-selected',
          title: 'Selected Scene',
          styleId: 'studio_default',
          aspectRatio: SceneAspectRatio.landscape16x9,
          characters: [
            Character(
              id: 'c1',
              displayName: 'Lead',
              avatarPath: 'data:image/png;base64,Zm9jdXM=',
              bubbleColor: '#00AA88',
            ),
          ],
          messages: [
            Message(
              id: 'm-late',
              characterId: 'c1',
              text: 'Later',
              timestampSeconds: 6,
              status: MessageStatus.seen,
              isIncoming: true,
              showTypingBefore: false,
            ),
            Message(
              id: 'm-early',
              characterId: 'c1',
              text: 'Earlier',
              timestampSeconds: 2,
              status: MessageStatus.sent,
              isIncoming: false,
              showTypingBefore: true,
            ),
          ],
        );
        const untouchedScene = Scene(
          id: 'scene-untouched',
          title: 'Untouched Scene',
          styleId: 'night_shift',
          aspectRatio: SceneAspectRatio.portrait9x16,
          characters: [],
          messages: [
            Message(
              id: 'm-untouched',
              characterId: 'c2',
              text: 'Keep original order',
              timestampSeconds: 9,
              status: MessageStatus.delivered,
              isIncoming: false,
              showTypingBefore: false,
            ),
          ],
        );
        final project = Project(
          id: 'p-sync',
          name: 'Sync Project',
          type: ProjectType.series,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          scenes: const [untouchedScene, selectedScene],
        );

        final payload =
            jsonDecode(
                  service.buildFallbackPackageJson(
                    project: project,
                    scene: selectedScene,
                    includeDeviceFrame: true,
                    cleanPreview: false,
                  ),
                )
                as Map<String, dynamic>;

        final selectedScenePayload =
            payload['selectedScene'] as Map<String, dynamic>;
        final projectScenes =
            (payload['project'] as Map<String, dynamic>)['scenes']
                as List<dynamic>;
        final syncedScenePayload = projectScenes
            .cast<Map<String, dynamic>>()
            .singleWhere((scene) => scene['id'] == selectedScene.id);
        final untouchedScenePayload = projectScenes
            .cast<Map<String, dynamic>>()
            .singleWhere((scene) => scene['id'] == untouchedScene.id);

        expect(selectedScenePayload['aspectRatio'], 'landscape16x9');
        expect(
          ((selectedScenePayload['characters'] as List<dynamic>).single
              as Map<String, dynamic>)['avatarPath'],
          'data:image/png;base64,Zm9jdXM=',
        );
        expect(
          (selectedScenePayload['messages'] as List<dynamic>)
              .map((message) => (message as Map<String, dynamic>)['id'])
              .toList(),
          ['m-early', 'm-late'],
        );
        expect(
          (syncedScenePayload['messages'] as List<dynamic>)
              .map((message) => (message as Map<String, dynamic>)['id'])
              .toList(),
          ['m-early', 'm-late'],
        );
        expect(
          ((syncedScenePayload['characters'] as List<dynamic>).single
              as Map<String, dynamic>)['avatarPath'],
          'data:image/png;base64,Zm9jdXM=',
        );
        expect(
          (untouchedScenePayload['messages'] as List<dynamic>)
              .map((message) => (message as Map<String, dynamic>)['id'])
              .toList(),
          ['m-untouched'],
        );
        expect(
          (payload['renderHints'] as Map<String, dynamic>)['targetRatios'],
          ['9:16', '16:9'],
        );

        final qa = payload['qa'] as Map<String, dynamic>;
        final projectQa = qa['project'] as Map<String, dynamic>;
        final selectedSceneQa = qa['selectedScene'] as Map<String, dynamic>;
        final sceneQaList = qa['scenes'] as List<dynamic>;
        expect(projectQa['scenesWithTimelineWarnings'], 0);
        expect(projectQa['firstAttentionSceneId'], isNull);
        expect(selectedSceneQa['id'], selectedScene.id);
        expect(selectedSceneQa['timelineWarningMessageIds'], isEmpty);
        expect(sceneQaList, hasLength(2));
      },
    );

    test('buildFallbackPackageJson includes export QA summaries', () {
      final service = VideoExportFallbackService();
      const scene = Scene(
        id: 'scene-qa',
        title: 'QA Scene',
        styleId: 'studio_default',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'c1',
            displayName: 'Lead',
            avatarPath: null,
            bubbleColor: '#00AA88',
          ),
          Character(
            id: 'c2',
            displayName: 'Support',
            avatarPath: null,
            bubbleColor: '#FFAA00',
          ),
        ],
        messages: [
          Message(
            id: 'm2',
            characterId: 'c1',
            text: 'Shared timestamp follow-up',
            timestampSeconds: 2,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: 'm1',
            characterId: 'c1',
            text: 'Shared timestamp opener',
            timestampSeconds: 2,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: true,
          ),
        ],
      );
      final project = Project(
        id: 'project-qa',
        name: 'QA Project',
        type: ProjectType.ad,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        scenes: const [scene],
      );

      final payload =
          jsonDecode(
                service.buildFallbackPackageJson(
                  project: project,
                  scene: scene,
                  includeDeviceFrame: true,
                  cleanPreview: false,
                ),
              )
              as Map<String, dynamic>;

      final qa = payload['qa'] as Map<String, dynamic>;
      final projectQa = qa['project'] as Map<String, dynamic>;
      final selectedSceneQa = qa['selectedScene'] as Map<String, dynamic>;
      final exportedSceneQa =
          (qa['scenes'] as List<dynamic>).single as Map<String, dynamic>;

      expect(projectQa['needsAttention'], isTrue);
      expect(projectQa['unusedCharacterCount'], 1);
      expect(projectQa['sharedTimestampCount'], 1);
      expect(projectQa['scenesWithTimelineWarnings'], 1);
      expect(projectQa['firstAttentionSceneId'], scene.id);
      expect(projectQa['firstSceneWithTimelineWarningsId'], scene.id);

      expect(selectedSceneQa['unusedCharacterNames'], ['Support']);
      expect(selectedSceneQa['sharedTimestampCount'], 1);
      expect(selectedSceneQa['sharedTimestampMessageCount'], 2);
      expect(selectedSceneQa['sharedTimestampMessageIds'], ['m1', 'm2']);
      expect(selectedSceneQa['overlappingTypingCueCount'], 1);
      expect(selectedSceneQa['overlappingTypingCueMessageIds'], ['m1', 'm2']);
      expect(selectedSceneQa['timelineWarningMessageIds'], ['m1', 'm2']);
      expect(selectedSceneQa['statusLabel'], '1 character waiting for lines');
      expect(
        selectedSceneQa['timelineDetailLabel'],
        contains('2 messages land on the same second'),
      );
      expect(exportedSceneQa, selectedSceneQa);
    });

    test('exports package with 500+ scene messages intact', () async {
      List<int>? capturedBytes;
      final service = VideoExportFallbackService(
        downloader:
            ({
              required bytes,
              required filename,
              required mimeType,
            }) async {
              capturedBytes = bytes;
              return true;
            },
      );

      final messages = List<Message>.generate(
        520,
        (index) => Message(
          id: 'm${520 - index}',
          characterId: 'c1',
          text: 'Message $index',
          timestampSeconds: index,
          status: MessageStatus.sent,
          isIncoming: index.isOdd,
          showTypingBefore: index.isEven,
        ),
        growable: false,
      );
      final scene = Scene(
        id: 's-large',
        title: 'Large Scene',
        styleId: 'studio_default',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: const [
          Character(
            id: 'c1',
            displayName: 'Lead',
            avatarPath: null,
            bubbleColor: '#00AA88',
          ),
        ],
        messages: messages,
      );
      final project = Project(
        id: 'p-large',
        name: 'Large Project',
        type: ProjectType.series,
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

      expect(result.isSuccess, isTrue);
      expect(capturedBytes, isNotNull);

      final payload =
          jsonDecode(
                utf8.decode(capturedBytes!),
              )
              as Map<String, dynamic>;
      final selectedScene = payload['selectedScene'] as Map<String, dynamic>;
      final exportedMessages = selectedScene['messages'] as List<dynamic>;
      expect(exportedMessages, hasLength(520));
      expect(
        (exportedMessages.first as Map<String, dynamic>)['timestampSeconds'],
        0,
      );
      expect(
        (exportedMessages.last as Map<String, dynamic>)['timestampSeconds'],
        519,
      );
    });
  });
}
