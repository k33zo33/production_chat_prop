import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    testWidgets(
      'returns missingBoundary when key resolves without repaint boundary',
      (tester) async {
        final key = GlobalKey();
        final service = ScreenshotExportService(
          downloader:
              ({
                required bytes,
                required filename,
                required mimeType,
              }) async => true,
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(key: key, width: 120, height: 80),
          ),
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

    testWidgets(
      'exports captured png bytes from a rendered repaint boundary',
      (tester) async {
        final boundaryKey = GlobalKey();
        List<int>? capturedBytes;
        String? capturedFilename;
        String? capturedMimeType;
        const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];
        final service = ScreenshotExportService(
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
          waitForEndOfFrame: () async {},
          capturePngBytes: (boundary, pixelRatio) async {
            expect(boundary, isA<RenderRepaintBoundary>());
            expect(pixelRatio, greaterThan(0));
            return ByteData.view(Uint8List.fromList(pngSignature).buffer);
          },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: const SizedBox(
                  width: 270,
                  height: 480,
                  child: ColoredBox(color: Color(0xFF00AA88)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final result = await service.exportBoundaryAsPng(
          boundaryKey: boundaryKey,
          projectName: 'Demo Project',
          sceneTitle: 'Hero Scene',
          aspectRatio: SceneAspectRatio.portrait9x16,
        );

        expect(result.isSuccess, isTrue);
        expect(result.filename, endsWith('.png'));
        expect(capturedFilename, equals(result.filename));
        expect(capturedMimeType, 'image/png');
        expect(capturedBytes, pngSignature);
      },
    );

    testWidgets(
      'returns downloadUnavailable when png capture cannot be saved',
      (tester) async {
        final boundaryKey = GlobalKey();
        List<int>? capturedBytes;
        String? capturedMimeType;
        const fakePngBytes = <int>[137, 80, 78, 71, 13, 10, 26, 10, 9, 8, 7];
        final service = ScreenshotExportService(
          downloader:
              ({
                required bytes,
                required filename,
                required mimeType,
              }) async {
                capturedBytes = bytes;
                capturedMimeType = mimeType;
                return false;
              },
          waitForEndOfFrame: () async {},
          capturePngBytes: (boundary, pixelRatio) async {
            expect(boundary, isA<RenderRepaintBoundary>());
            expect(pixelRatio, greaterThan(0));
            return ByteData.view(Uint8List.fromList(fakePngBytes).buffer);
          },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: const SizedBox(
                  width: 640,
                  height: 360,
                  child: ColoredBox(color: Color(0xFF155EEF)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final result = await service.exportBoundaryAsPng(
          boundaryKey: boundaryKey,
          projectName: 'Demo Project',
          sceneTitle: 'Landscape Scene',
          aspectRatio: SceneAspectRatio.landscape16x9,
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.failure,
          ScreenshotExportFailure.downloadUnavailable,
        );
        expect(capturedMimeType, 'image/png');
        expect(capturedBytes, fakePngBytes);
      },
    );

    testWidgets(
      'returns captureFailed when png capture bytes are null',
      (tester) async {
        final boundaryKey = GlobalKey();
        final service = ScreenshotExportService(
          waitForEndOfFrame: () async {},
          capturePngBytes: (boundary, pixelRatio) async {
            expect(boundary, isA<RenderRepaintBoundary>());
            expect(pixelRatio, greaterThan(0));
            return null;
          },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundaryKey,
              child: const SizedBox(width: 180, height: 320),
            ),
          ),
        );
        await tester.pump();

        final result = await service.exportBoundaryAsPng(
          boundaryKey: boundaryKey,
          projectName: 'Demo Project',
          sceneTitle: 'Null Capture',
          aspectRatio: SceneAspectRatio.portrait9x16,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ScreenshotExportFailure.captureFailed);
      },
    );

    testWidgets(
      'returns captureFailed when png capture throws',
      (tester) async {
        final boundaryKey = GlobalKey();
        final service = ScreenshotExportService(
          waitForEndOfFrame: () async {},
          capturePngBytes: (boundary, pixelRatio) async {
            expect(boundary, isA<RenderRepaintBoundary>());
            expect(pixelRatio, greaterThan(0));
            throw Exception('capture failed');
          },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundaryKey,
              child: const SizedBox(width: 180, height: 320),
            ),
          ),
        );
        await tester.pump();

        final result = await service.exportBoundaryAsPng(
          boundaryKey: boundaryKey,
          projectName: 'Demo Project',
          sceneTitle: 'Throwing Capture',
          aspectRatio: SceneAspectRatio.portrait9x16,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ScreenshotExportFailure.captureFailed);
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
