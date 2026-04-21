import 'dart:convert';

import 'package:production_chat_prop/core/utils/file_download/file_downloader.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

enum VideoFallbackExportFailure {
  downloadUnavailable,
}

class VideoFallbackExportResult {
  const VideoFallbackExportResult._({
    required this.isSuccess,
    this.failure,
    this.filename,
  });

  const VideoFallbackExportResult.success({required String filename})
    : this._(isSuccess: true, filename: filename);

  const VideoFallbackExportResult.failure({
    required VideoFallbackExportFailure failure,
  }) : this._(isSuccess: false, failure: failure);

  final bool isSuccess;
  final VideoFallbackExportFailure? failure;
  final String? filename;
}

class VideoExportFallbackService {
  VideoExportFallbackService({BytesDownloader? downloader})
    : _downloader = downloader ?? downloadBytes;

  final BytesDownloader _downloader;

  String buildFallbackPackageJson({
    required Project project,
    required Scene scene,
    required bool includeDeviceFrame,
    required bool cleanPreview,
  }) {
    final payload = _buildPayload(
      project: project,
      scene: scene,
      includeDeviceFrame: includeDeviceFrame,
      cleanPreview: cleanPreview,
    );
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<VideoFallbackExportResult> exportFallbackPackage({
    required Project project,
    required Scene scene,
    required bool includeDeviceFrame,
    required bool cleanPreview,
  }) async {
    final encoded = utf8.encode(
      buildFallbackPackageJson(
        project: project,
        scene: scene,
        includeDeviceFrame: includeDeviceFrame,
        cleanPreview: cleanPreview,
      ),
    );
    final filename = _buildFileName(
      projectName: project.name,
      sceneTitle: scene.title,
    );

    final isDownloaded = await _downloader(
      bytes: encoded,
      filename: filename,
      mimeType: 'application/json',
    );
    if (!isDownloaded) {
      return const VideoFallbackExportResult.failure(
        failure: VideoFallbackExportFailure.downloadUnavailable,
      );
    }

    return VideoFallbackExportResult.success(filename: filename);
  }

  Map<String, dynamic> _buildPayload({
    required Project project,
    required Scene scene,
    required bool includeDeviceFrame,
    required bool cleanPreview,
  }) {
    final sortedMessages = sortMessagesByTimeline(scene.messages);
    final normalizedProject = project.toJson();
    final projectScenes =
        (normalizedProject['scenes'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
    final normalizedScenes = projectScenes.map((sceneJson) {
      if (sceneJson['id'] != scene.id) {
        return sceneJson;
      }
      return {
        ...sceneJson,
        'messages': sortedMessages.map((message) => message.toJson()).toList(),
      };
    }).toList(growable: false);

    return {
      'meta': {
        'tool': 'Production Chat Prop',
        'format': 'video_fallback_package',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'project': {
        ...normalizedProject,
        'scenes': normalizedScenes,
      },
      'selectedScene': {
        ...scene.toJson(),
        'messages': sortedMessages.map((message) => message.toJson()).toList(),
      },
      'renderHints': {
        'targetRatios': const ['9:16', '16:9'],
        'includeDeviceFrame': includeDeviceFrame,
        'cleanPreview': cleanPreview,
      },
      'workflow': {
        'steps': const [
          'Import package in video editor workflow.',
          'Map messages by timestampSeconds.',
          'Render animated bubbles using selectedScene.aspectRatio.',
          'Apply status and typing indicator metadata.',
          'Render target outputs in 9:16 and 16:9.',
        ],
      },
    };
  }

  String _buildFileName({
    required String projectName,
    required String sceneTitle,
  }) {
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final safeProject = _sanitizeSegment(projectName);
    final safeScene = _sanitizeSegment(sceneTitle);
    return 'pcp_video_fallback_${safeProject}_${safeScene}_$timestamp.json';
  }

  String _sanitizeSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final replaced = normalized.replaceAll(RegExp('[^a-z0-9]+'), '_');
    return replaced
        .replaceAll(RegExp('_+'), '_')
        .replaceFirst(RegExp('^_+'), '')
        .replaceFirst(RegExp(r'_+$'), '');
  }
}
