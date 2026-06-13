import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'focus preview switches to dense chrome on short landscape heights',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpPlaybackHarness(
        tester,
        container: container,
        size: const Size(844, 390),
        child: PlaybackScreen(projectId: projectId),
      );

      final initialException = tester.takeException();
      expect(initialException, isNull);

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      final sliderRect = tester.getRect(
        find.byKey(const Key('focusPreviewProgressSlider')),
      );
      final currentTimeRect = tester.getRect(
        find.byKey(const Key('focusPreviewCurrentTimeLabel')),
      );
      final maxTimeRect = tester.getRect(
        find.byKey(const Key('focusPreviewMaxTimeLabel')),
      );

      expect(
        find.byKey(const Key('playbackFocusPreviewScreen')),
        findsOneWidget,
      );
      expect(currentTimeRect.top, greaterThan(sliderRect.bottom));
      expect(maxTimeRect.top, greaterThan(sliderRect.bottom));
      expect(find.text('Restart'), findsNothing);
      expect(find.text('Pause'), findsNothing);
      expect(
        find.byKey(const Key('focusPreviewTogglePlaybackButton')),
        findsOneWidget,
      );

      final overlayException = tester.takeException();
      expect(overlayException, isNull);
    },
  );
}

Future<void> _pumpPlaybackHarness(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
  required Size size,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    ),
  );
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
