import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotExportService', () {
    test('returns missingBoundary when key has no render context', () async {
      var wasDownloaderCalled = false;
      final service = ScreenshotExportService(
        downloader: ({
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
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ScreenshotExportFailure.missingBoundary);
      expect(wasDownloaderCalled, isFalse);
    });

    test('returns missingBoundary when key resolves without repaint boundary', () async {
      final key = GlobalKey();
      final service = ScreenshotExportService(
        downloader: ({
          required bytes,
          required filename,
          required mimeType,
        }) async => true,
      );

      final result = await service.exportBoundaryAsPng(
        boundaryKey: key,
        projectName: 'Demo Project',
        sceneTitle: 'Scene A',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ScreenshotExportFailure.missingBoundary);
    });
  });
}
