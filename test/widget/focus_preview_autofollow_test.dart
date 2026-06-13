import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/presentation/controllers/playback_controller.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('focus preview auto-follows deep cues in long scenes', (
    tester,
  ) async {
    final harness = await _createLongPlaybackHarness();
    addTearDown(harness.dispose);

    await _pumpPlaybackScreen(
      tester,
      container: harness.container,
      projectId: harness.projectId,
    );

    await _openFocusPreview(tester);

    final previewScrollViewFinder = _focusPreviewDescendant(
      find.byKey(const Key('playbackPreviewScrollView'), skipOffstage: false),
    );
    final initialPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(initialPreviewScrollView.controller, isNotNull);
    expect(initialPreviewScrollView.controller!.position.pixels, 0);

    harness.container
        .read(playbackControllerProvider(harness.projectId).notifier)
        .scrubTo(second: 480, maxSecond: 519);
    await tester.pumpAndSettle();

    final updatedPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(
      updatedPreviewScrollView.controller!.position.pixels,
      greaterThan(0),
    );
    expect(
      _focusPreviewDescendant(
        find.byKey(const Key('activePreviewCue'), skipOffstage: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('focus preview re-follows earlier cues after backward scrub', (
    tester,
  ) async {
    final harness = await _createLongPlaybackHarness();
    addTearDown(harness.dispose);

    await _pumpPlaybackScreen(
      tester,
      container: harness.container,
      projectId: harness.projectId,
    );

    await _openFocusPreview(tester);

    final previewScrollViewFinder = _focusPreviewDescendant(
      find.byKey(const Key('playbackPreviewScrollView'), skipOffstage: false),
    );

    harness.container
        .read(playbackControllerProvider(harness.projectId).notifier)
        .scrubTo(second: 480, maxSecond: 519);
    await tester.pumpAndSettle();

    final deepPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    final deepOffset = deepPreviewScrollView.controller!.position.pixels;
    expect(deepOffset, greaterThan(0));

    harness.container
        .read(playbackControllerProvider(harness.projectId).notifier)
        .scrubTo(second: 60, maxSecond: 519);
    await tester.pumpAndSettle();

    final rewoundPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(
      rewoundPreviewScrollView.controller!.position.pixels,
      lessThan(deepOffset),
    );
    expect(
      _focusPreviewDescendant(
        find.byKey(const Key('activePreviewCue'), skipOffstage: false),
      ),
      findsOneWidget,
    );
  });
}

Finder _focusPreviewDescendant(Finder matching) {
  return find.descendant(
    of: find.byKey(const Key('playbackFocusPreviewScreen')),
    matching: matching,
    skipOffstage: false,
  );
}

Future<void> _pumpPlaybackScreen(
  WidgetTester tester, {
  required ProviderContainer container,
  required String projectId,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: PlaybackScreen(projectId: projectId)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openFocusPreview(WidgetTester tester) async {
  final focusPreviewButton = find.byKey(
    const Key('openPlaybackFocusPreviewButton'),
  );
  await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
  await tester.tap(focusPreviewButton);
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsOneWidget);
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

class _LongPlaybackHarness {
  _LongPlaybackHarness({required this.container, required this.projectId});

  final ProviderContainer container;
  final String projectId;

  void dispose() {
    container.dispose();
  }
}

Future<_LongPlaybackHarness> _createLongPlaybackHarness() async {
  final container = ProviderContainer();
  await container
      .read(projectsControllerProvider.notifier)
      .importProjectFromJson(
        _buildLargeProjectImportPayload(messageCount: 520),
      );
  final projects = await container.read(projectsControllerProvider.future);
  return _LongPlaybackHarness(
    container: container,
    projectId: projects.single.id,
  );
}

String _buildLargeProjectImportPayload({required int messageCount}) {
  final messages = List<Map<String, Object?>>.generate(
    messageCount,
    (index) => {
      'id': 'm_$index',
      'characterId': index.isEven ? 'c_alex' : 'c_mia',
      'text': 'Stress message $index',
      'timestampSeconds': index,
      'status': index % 3 == 0
          ? 'sent'
          : index % 3 == 1
          ? 'delivered'
          : 'seen',
      'isIncoming': index.isOdd,
      'showTypingBefore': index % 5 == 0,
    },
    growable: false,
  );

  return jsonEncode({
    'id': 'stress-project-source',
    'name': 'Stress Playback Project',
    'type': 'series',
    'createdAt': DateTime.utc(2026, 3, 31, 12).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 3, 31, 12).toIso8601String(),
    'scenes': [
      {
        'id': 'scene-stress',
        'title': 'Stress Scene',
        'styleId': 'studio_default',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'c_alex',
            'displayName': 'Alex',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
          {
            'id': 'c_mia',
            'displayName': 'Mia',
            'avatarPath': null,
            'bubbleColor': '#12B76A',
          },
        ],
        'messages': messages,
      },
    ],
  });
}
