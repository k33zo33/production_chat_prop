import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/app/router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:production_chat_prop/features/projects/presentation/pages/project_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'compact portfolio pre-flight dialog surfaces timeline QA details and action',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaPortfolioPayload());

      await _pumpCompactApp(tester, container: container);

      expect(find.byKey(const Key('portfolioPreflightButton')), findsOneWidget);
      expect(
        find.text('Beta handoff pre-flight • Timeline QA'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('portfolioPreflightButton')));
      await tester.pumpAndSettle();

      final dialog = find.byKey(const Key('portfolioPreflightDialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Projects in view: 1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(
            '1 shared timestamp • 1 overlapping typing cue across 1 scene in 1 project',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('First timeline QA project: Timeline QA Project'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('portfolioPreflightReviewTimelineQaButton')),
        findsOneWidget,
      );

      final reviewTimelineQaButton = find.byKey(
        const Key('portfolioPreflightReviewTimelineQaButton'),
      );
      await tester.ensureVisible(reviewTimelineQaButton);
      await tester.pumpAndSettle();
      await tester.tap(reviewTimelineQaButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('portfolioPreflightDialog')), findsNothing);
      expect(find.byKey(const Key('playbackSceneStatusBadge')), findsOneWidget);
      expect(find.text('Timeline QA'), findsOneWidget);
    },
  );

  testWidgets(
    'compact portfolio pre-flight continue editing action opens the ready project editor',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await _pumpCompactApp(tester, container: container);

      expect(find.byKey(const Key('portfolioPreflightButton')), findsOneWidget);
      expect(find.text('Beta handoff pre-flight • Ready'), findsOneWidget);

      await tester.tap(find.byKey(const Key('portfolioPreflightButton')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('portfolioPreflightContinueEditingButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('portfolioPreflightPreviewReadyButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('portfolioPreflightReviewAttentionButton')),
        findsNothing,
      );

      final continueEditingButton = find.byKey(
        const Key('portfolioPreflightContinueEditingButton'),
      );
      await tester.ensureVisible(continueEditingButton);
      await tester.pumpAndSettle();
      await tester.tap(continueEditingButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('portfolioPreflightDialog')), findsNothing);
      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Demo Project 1'), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
    },
  );

  testWidgets(
    'compact portfolio pre-flight review attention action opens the flagged project editor',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.singleWhere(
        (candidate) => candidate.id == projectId,
      );
      final scene = project.scenes.first;
      await container
          .read(projectsControllerProvider.notifier)
          .clearSceneMessages(projectId: projectId, sceneId: scene.id);

      await _pumpCompactApp(tester, container: container);

      expect(find.byKey(const Key('portfolioPreflightButton')), findsOneWidget);
      expect(
        find.text('Beta handoff pre-flight • Needs attention'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('portfolioPreflightButton')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('portfolioPreflightContinueEditingButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('portfolioPreflightReviewAttentionButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('portfolioPreflightPreviewReadyButton')),
        findsNothing,
      );

      final reviewAttentionButton = find.byKey(
        const Key('portfolioPreflightReviewAttentionButton'),
      );
      await tester.ensureVisible(reviewAttentionButton);
      await tester.pumpAndSettle();
      await tester.tap(reviewAttentionButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('portfolioPreflightDialog')), findsNothing);
      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text(project.name), findsOneWidget);
      expect(find.text('Scene: ${scene.title}'), findsOneWidget);
    },
  );
}

Future<void> _pumpCompactApp(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  final router = GoRouter(
    initialLocation: projectsRoutePath,
    routes: [
      GoRoute(
        path: projectsRoutePath,
        name: 'projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: editorProjectRoutePath,
        name: 'editorProject',
        builder: (context, state) => ChatEditorScreen(
          projectId: state.pathParameters['projectId'],
          initialSceneId: state.uri.queryParameters['sceneId'],
        ),
      ),
      GoRoute(
        path: playbackProjectRoutePath,
        name: 'playbackProject',
        builder: (context, state) => PlaybackScreen(
          projectId: state.pathParameters['projectId'],
          initialSceneId: state.uri.queryParameters['sceneId'],
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

String _buildTimelineQaPortfolioPayload() {
  final payload = <String, Object?>{
    'id': 'timeline-qa-project-id',
    'name': 'Timeline QA Project',
    'type': 'series',
    'createdAt': '2026-06-11T07:10:00.000Z',
    'updatedAt': '2026-06-11T07:15:00.000Z',
    'scenes': [
      {
        'id': 'timeline-qa-scene-id',
        'title': 'Stacked Cue Scene',
        'styleId': 'studio_default',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'timeline-qa-char-1',
            'displayName': 'Taylor',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
          {
            'id': 'timeline-qa-char-2',
            'displayName': 'Jordan',
            'avatarPath': null,
            'bubbleColor': '#12B76A',
          },
        ],
        'messages': [
          {
            'id': 'timeline-qa-message-1',
            'characterId': 'timeline-qa-char-1',
            'text': 'Cue one.',
            'timestampSeconds': 4,
            'status': 'sent',
            'isIncoming': false,
            'showTypingBefore': true,
          },
          {
            'id': 'timeline-qa-message-2',
            'characterId': 'timeline-qa-char-2',
            'text': 'Cue two.',
            'timestampSeconds': 4,
            'status': 'delivered',
            'isIncoming': true,
            'showTypingBefore': true,
          },
        ],
      },
    ],
  };

  return jsonEncode(payload);
}
