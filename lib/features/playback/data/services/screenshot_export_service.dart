import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:production_chat_prop/core/utils/file_download/file_downloader.dart';

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

class ScreenshotExportService {
  Future<ScreenshotExportResult> exportBoundaryAsPng({
    required GlobalKey boundaryKey,
    required String projectName,
    required String sceneTitle,
    double pixelRatio = 2,
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

    await SchedulerBinding.instance.endOfFrame;
    if (renderObject.debugNeedsPaint) {
      return const ScreenshotExportResult.failure(
        failure: ScreenshotExportFailure.captureFailed,
      );
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
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
    final isDownloaded = await downloadBytes(
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
    return 'pcp_${safeProject}_${safeScene}_$timestamp.png';
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
