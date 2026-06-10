import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/app/app.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScreenshotExportService extends ScreenshotExportService {
  _FakeScreenshotExportService(this._result);

  final ScreenshotExportResult _result;

  @override
  Future<ScreenshotExportResult> exportBoundaryAsPng({
    required GlobalKey boundaryKey,
    required String projectName,
    required String sceneTitle,
    required SceneAspectRatio aspectRatio,
    double? pixelRatio,
  }) async {
    return _result;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('playback preview toggles affect screenshot export feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotExportServiceProvider.overrideWithValue(
            _FakeScreenshotExportService(
              const ScreenshotExportResult.success(
                filename: 'fake_capture.png',
              ),
            ),
          ),
        ],
        child: const ProductionChatPropApp(),
      ),
    );

    await _openPlaybackWithNewProject(tester);

    await tester.tap(find.byKey(const Key('playbackDeviceFrameSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('playbackCleanPreviewSwitch')));
    await tester.pumpAndSettle();

    final exportScreenshotButton = find.byKey(
      const Key('exportScreenshotButton'),
    );
    await tester.ensureVisible(exportScreenshotButton);
    await tester.pumpAndSettle();
    await tester.tap(exportScreenshotButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Export: Screenshot OK'), findsOneWidget);
    expect(
      find.text('Screenshot exported as fake_capture.png.'),
      findsOneWidget,
    );
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('cleanPreviewHeader')),
    );
    expect(find.text('Playback Timeline (read-only)'), findsNothing);
    expect(find.text('INCOMING'), findsNothing);
    expect(find.text('OUTGOING'), findsNothing);
  });

  testWidgets('playback screenshot export shows failure feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotExportServiceProvider.overrideWithValue(
            _FakeScreenshotExportService(
              const ScreenshotExportResult.failure(
                failure: ScreenshotExportFailure.downloadUnavailable,
              ),
            ),
          ),
        ],
        child: const ProductionChatPropApp(),
      ),
    );

    await _openPlaybackWithNewProject(tester);

    final exportScreenshotButton = find.byKey(
      const Key('exportScreenshotButton'),
    );
    await tester.ensureVisible(exportScreenshotButton);
    await tester.pumpAndSettle();
    await tester.tap(exportScreenshotButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Export: Screenshot Error'), findsOneWidget);
    expect(
      find.text(
        'Screenshot export failed: download is not available on this platform.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'video export button copies fallback package to clipboard when download is unavailable',
    (tester) async {
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                clipboardText =
                    (methodCall.arguments as Map)['text'] as String?;
              }
              return null;
            });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );

      await _openPlaybackWithNewProject(tester);

      final exportVideoButton = find.byKey(const Key('exportVideoButton'));
      await tester.ensureVisible(exportVideoButton);
      await tester.pumpAndSettle();
      await tester.tap(exportVideoButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Download unavailable. Video fallback JSON copied to clipboard.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Export: Video OK'), findsOneWidget);
      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('"format": "video_fallback_package"'));
    },
  );

  testWidgets(
    'video export button shows failure when clipboard fallback fails',
    (
      tester,
    ) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                throw PlatformException(code: 'clipboard-failed');
              }
              return null;
            });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );

      await _openPlaybackWithNewProject(tester);

      final exportVideoButton = find.byKey(const Key('exportVideoButton'));
      await tester.ensureVisible(exportVideoButton);
      await tester.pumpAndSettle();
      await tester.tap(exportVideoButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Export: Video Error'), findsOneWidget);
      expect(
        find.text(
          'Video export failed: download is not available on this platform.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('copy handoff button copies fallback package to clipboard', (
    tester,
  ) async {
    String? clipboardText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardText = (methodCall.arguments as Map)['text'] as String?;
            }
            return null;
          });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );

    await _openPlaybackWithNewProject(tester);

    final copyHandoffButton = find.byKey(const Key('copyVideoFallbackButton'));
    await tester.ensureVisible(copyHandoffButton);
    await tester.pumpAndSettle();
    await tester.tap(copyHandoffButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Video fallback JSON copied to clipboard.'),
      findsOneWidget,
    );
    expect(find.textContaining('Export: Video OK'), findsOneWidget);
    expect(clipboardText, isNotNull);
    expect(clipboardText, contains('"format": "video_fallback_package"'));
  });

  testWidgets('copy handoff button shows clipboard failure feedback', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              throw PlatformException(code: 'clipboard-failed');
            }
            return null;
          });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );

    await _openPlaybackWithNewProject(tester);

    final copyHandoffButton = find.byKey(const Key('copyVideoFallbackButton'));
    await tester.ensureVisible(copyHandoffButton);
    await tester.pumpAndSettle();
    await tester.tap(copyHandoffButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Export: Video Error'), findsOneWidget);
    expect(
      find.text(
        'Video handoff copy failed: clipboard is not available on this platform.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _ensureOnProjectList(WidgetTester tester) async {
  await tester.pumpAndSettle();

  if (find.text('Project List').evaluate().isNotEmpty) {
    return;
  }

  if (find.text('Back to Projects').evaluate().isNotEmpty) {
    await tester.tap(find.text('Back to Projects').first);
    await tester.pumpAndSettle();
  }
}

Future<void> _openPlaybackWithNewProject(WidgetTester tester) async {
  await _ensureOnProjectList(tester);

  await tester.tap(find.byKey(const Key('newProjectFab')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  final projectId = _projectIdForName(tester, 'New Project 1');
  final openPlaybackButton = find.byKey(Key('projectOpenPlayback_$projectId'));
  await _prepareProjectActionTap(tester, openPlaybackButton);
  await tester.tap(openPlaybackButton.hitTestable().first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

String _projectIdForName(WidgetTester tester, String projectName) {
  final projectCard = find
      .ancestor(of: find.text(projectName).first, matching: find.byType(Card))
      .first;
  final cardWidget = tester.widget<Card>(projectCard);
  return (cardWidget.key! as ValueKey<String>).value.replaceFirst(
    'projectCard_',
    '',
  );
}

Future<void> _prepareProjectActionTap(
  WidgetTester tester,
  Finder actionButton,
) async {
  await tester.ensureVisible(actionButton);
  await tester.pumpAndSettle();

  if (actionButton.hitTestable().evaluate().isNotEmpty ||
      find.byType(SnackBar).evaluate().isEmpty) {
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -180));
  await tester.pumpAndSettle();
}

Future<void> _ensureFinderVisibleInPrimaryListView(
  WidgetTester tester,
  Finder finder,
) async {
  if (finder.evaluate().isEmpty) {
    final listView = find.byType(ListView).first;
    for (var i = 0; i < 16 && finder.evaluate().isEmpty; i += 1) {
      await tester.drag(listView, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 16 && finder.evaluate().isEmpty; i += 1) {
      await tester.drag(listView, const Offset(0, 220));
      await tester.pumpAndSettle();
    }
  }

  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
