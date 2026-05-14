import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:production_chat_prop/core/utils/export_file_name.dart';
import 'package:production_chat_prop/core/utils/file_download/file_downloader.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

enum ScreenshotExportFailure {
  missingBoundary,
  captureFailed,
  downloadUnavailable,
}

class ScreenshotExportResult {
  const ScreenshotExportResult._({
    required this.isSuccess,
    this.failure,
    this.filename,
  });

  const ScreenshotExportResult.success({required String filename})
    : this._(isSuccess: true, filename: filename);

  const ScreenshotExportResult.failure({
    required ScreenshotExportFailure failure,
  }) : this._(isSuccess: false, failure: failure);

  final bool isSuccess;
  final ScreenshotExportFailure? failure;
  final String? filename;
}

class ScreenshotExportProfile {
  const ScreenshotExportProfile({
    required this.pixelRatio,
    required this.targetPixelSize,
  });

  final double pixelRatio;
  final Size targetPixelSize;
}

class ScreenshotExportService {
  ScreenshotExportService({BytesDownloader? downloader})
    : _downloader = downloader ?? downloadBytes;

  final BytesDownloader _downloader;

  static const Size portraitTargetPixelSize = Size(1080, 1920);
  static const Size landscapeTargetPixelSize = Size(1920, 1080);

  Future<ScreenshotExportResult> exportBoundaryAsPng({
    required GlobalKey boundaryKey,
    required String projectName,
    required String sceneTitle,
    required SceneAspectRatio aspectRatio,
    double? pixelRatio,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.missingBoundary,
      );
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.missingBoundary,
      );
    }
    if (renderObject.size.isEmpty) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.captureFailed,
      );
    }

    await SchedulerBinding.instance.endOfFrame;
    if (renderObject.debugNeedsPaint) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.captureFailed,
      );
    }

    final captureProfile = buildCaptureProfile(
      logicalSize: renderObject.size,
      aspectRatio: aspectRatio,
    );
    final image = await renderObject.toImage(
      pixelRatio: pixelRatio ?? captureProfile.pixelRatio,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.captureFailed,
      );
    }

    final bytes = byteData.buffer.asUint8List();
    final filename = _buildFileName(
      projectName: projectName,
      sceneTitle: sceneTitle,
    );
    final isDownloaded = await _downloader(
      bytes: bytes,
      filename: filename,
      mimeType: 'image/png',
    );

    if (!isDownloaded) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.downloadUnavailable,
      );
    }

    return ScreenshotExportResult.success(filename: filename);
  }

  @visibleForTesting
  ScreenshotExportProfile buildCaptureProfile({
    required Size logicalSize,
    required SceneAspectRatio aspectRatio,
  }) {
    final targetPixelSize = targetPixelSizeForAspectRatio(aspectRatio);
    if (logicalSize.isEmpty) {
      return ScreenshotExportProfile(
        pixelRatio: 1,
        targetPixelSize: targetPixelSize,
      );
    }

    final widthRatio = targetPixelSize.width / logicalSize.width;
    final heightRatio = targetPixelSize.height / logicalSize.height;
    final pixelRatio = math.max<double>(
      1,
      math.max(widthRatio, heightRatio),
    );

    return ScreenshotExportProfile(
      pixelRatio: pixelRatio,
      targetPixelSize: targetPixelSize,
    );
  }

  static Size targetPixelSizeForAspectRatio(SceneAspectRatio aspectRatio) {
    return switch (aspectRatio) {
      SceneAspectRatio.portrait9x16 => portraitTargetPixelSize,
      SceneAspectRatio.landscape16x9 => landscapeTargetPixelSize,
    };
  }

  String _buildFileName({
    required String projectName,
    required String sceneTitle,
  }) {
    final timestamp = buildExportTimestamp();
    final safeProject = sanitizeExportFileNameSegment(
      projectName,
      fallback: 'project',
    );
    final safeScene = sanitizeExportFileNameSegment(
      sceneTitle,
      fallback: 'scene',
    );
    return 'pcp_${safeProject}_${safeScene}_$timestamp.png';
  }
}
