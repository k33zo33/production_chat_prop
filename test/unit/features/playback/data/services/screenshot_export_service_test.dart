import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotExportService', () {
    test('returns missingBoundary when key has no render context', () async {
      var wasDownloaderCalled = false;
      final service = ScreenshotExportService(
        downloader:
            ({
              required bytes,
              required filename,
              required mimeType,
            }) async {
              wasDownloaderCalled = true;
              return true;
            },
      );

      final result = await service.exportBoundaryAsPng(
        boundaryKey: GlobalKey(),
        projectName: 'Demo',
        sceneTitle: 'Scene',
        aspectRatio: SceneAspectRatio.portrait9x16,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ScreenshotExportFailure.missingBoundary);
      expect(wasDownloaderCalled, isFalse);
    });

    test(
      'returns missingBoundary when key resolves without repaint boundary',
      () async {
        final key = GlobalKey();
        final service = ScreenshotExportService(
          downloader:
              ({
                required bytes,
                required filename,
                required mimeType,
              }) async => true,
        );

        final result = await service.exportBoundaryAsPng(
          boundaryKey: key,
          projectName: 'Demo Project',
          sceneTitle: 'Scene A',
          aspectRatio: SceneAspectRatio.portrait9x16,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ScreenshotExportFailure.missingBoundary);
      },
    );

    test('buildCaptureProfile targets full hd portrait export', () {
      final service = ScreenshotExportService();

      final profile = service.buildCaptureProfile(
        logicalSize: const Size(270, 480),
        aspectRatio: SceneAspectRatio.portrait9x16,
      );

      expect(
        profile.targetPixelSize,
        ScreenshotExportService.portraitTargetPixelSize,
      );
      expect(profile.pixelRatio, closeTo(4, 0.0001));
    });

    test('buildCaptureProfile targets full hd landscape export', () {
      final service = ScreenshotExportService();

      final profile = service.buildCaptureProfile(
        logicalSize: const Size(640, 360),
        aspectRatio: SceneAspectRatio.landscape16x9,
      );

      expect(
        profile.targetPixelSize,
        ScreenshotExportService.landscapeTargetPixelSize,
      );
      expect(profile.pixelRatio, closeTo(3, 0.0001));
    });

    test('buildCaptureProfile never scales below logical size', () {
      final service = ScreenshotExportService();

      final profile = service.buildCaptureProfile(
        logicalSize: const Size(1440, 2560),
        aspectRatio: SceneAspectRatio.portrait9x16,
      );

      expect(
        profile.targetPixelSize,
        ScreenshotExportService.portraitTargetPixelSize,
      );
      expect(profile.pixelRatio, 1);
    });

    test('buildCaptureProfile handles empty logical size safely', () {
      final service = ScreenshotExportService();

      final profile = service.buildCaptureProfile(
        logicalSize: Size.zero,
        aspectRatio: SceneAspectRatio.landscape16x9,
      );

      expect(
        profile.targetPixelSize,
        ScreenshotExportService.landscapeTargetPixelSize,
      );
      expect(profile.pixelRatio, 1);
    });
  });
}
