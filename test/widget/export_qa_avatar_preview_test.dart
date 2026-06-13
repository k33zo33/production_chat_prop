import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/widgets/character_avatar.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'export QA hero portrait keeps embedded avatar visible in playback and focus preview',
    (tester) async {
      final harness = await _createExportQaHarness();
      addTearDown(harness.dispose);

      await _pumpPlaybackScreen(
        tester,
        container: harness.container,
        projectId: harness.project.id,
      );

      expect(find.text('Scene: Scene 1 - Hero Portrait'), findsOneWidget);
      final playbackPreview = find.byKey(const Key('playbackPreviewAspectRatio'));
      await _ensureFinderVisibleInPrimaryListView(tester, playbackPreview);
      _expectEmbeddedAvatarVisible(tester, scope: playbackPreview);

      final cleanPreviewSwitch = find.byKey(
        const Key('playbackCleanPreviewSwitch'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, cleanPreviewSwitch);
      await tester.tap(cleanPreviewSwitch);
      await tester.pumpAndSettle();

      await _ensureFinderVisibleInPrimaryListView(tester, playbackPreview);
      _expectEmbeddedAvatarVisible(tester, scope: playbackPreview);

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsOneWidget);
      _expectEmbeddedAvatarVisible(
        tester,
        scope: find.byKey(const Key('playbackFocusPreviewScreen')),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectEmbeddedAvatarVisible(
  WidgetTester tester, {
  required Finder scope,
}) {
  final avatarWidgets = tester
      .widgetList<CharacterAvatar>(
        find.descendant(
          of: scope,
          matching: find.byType(CharacterAvatar),
          skipOffstage: false,
        ),
      )
      .where(
        (avatar) =>
            (avatar.avatarPath ?? '').startsWith('data:image/png;base64,'),
      )
      .toList(growable: false);
  expect(avatarWidgets, isNotEmpty);

  final avatarTooltips = tester
      .widgetList<Tooltip>(
        find.descendant(
          of: scope,
          matching: find.byType(Tooltip),
          skipOffstage: false,
        ),
      )
      .where(
        (tooltip) => tooltip.message == 'Avatar source: embedded image data',
      )
      .toList(growable: false);
  expect(avatarTooltips, isNotEmpty);

  final memoryAvatars = tester
      .widgetList<CircleAvatar>(
        find.descendant(
          of: scope,
          matching: find.byType(CircleAvatar),
          skipOffstage: false,
        ),
      )
      .where((avatar) => avatar.foregroundImage is MemoryImage)
      .toList(growable: false);
  expect(memoryAvatars, isNotEmpty);
}

Future<void> _pumpPlaybackScreen(
  WidgetTester tester, {
  required ProviderContainer container,
  required String projectId,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: PlaybackScreen(projectId: projectId)),
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

class _ExportQaHarness {
  _ExportQaHarness({required this.container, required this.project});

  final ProviderContainer container;
  final Project project;

  void dispose() {
    container.dispose();
  }
}

Future<_ExportQaHarness> _createExportQaHarness() async {
  final container = ProviderContainer();
  final rawJson = _resolveFixtureFile().readAsStringSync();
  await container
      .read(projectsControllerProvider.notifier)
      .importProjectFromJson(rawJson);
  final projects = await container.read(projectsControllerProvider.future);
  final project = projects.singleWhere(
    (candidate) => candidate.name == 'Export QA Project',
  );
  return _ExportQaHarness(container: container, project: project);
}

File _resolveFixtureFile() {
  var currentDirectory = Directory.current.absolute;

  while (true) {
    final candidate = File(
      '${currentDirectory.path}${Platform.pathSeparator}docs${Platform.pathSeparator}fixtures${Platform.pathSeparator}export-qa-project.json',
    );
    if (candidate.existsSync()) {
      return candidate;
    }

    final parentDirectory = currentDirectory.parent;
    if (parentDirectory.path == currentDirectory.path) {
      throw StateError(
        'Could not locate docs/fixtures/export-qa-project.json from ${Directory.current.path}.',
      );
    }
    currentDirectory = parentDirectory;
  }
}
