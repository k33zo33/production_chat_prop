import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/scene_status_badge.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'compact chat editor app bar keeps scene status badge visible for empty scenes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildEmptySceneProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 900)),
              child: ChatEditorScreen(
                projectId: projectId,
                forceCompactLayout: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(SceneStatusBadge), findsOneWidget);
      expect(
        find.byTooltip(
          'No messages yet • Add at least one message before preview or export.',
        ),
        findsOneWidget,
      );
      expect(find.text('No messages'), findsNothing);

      await tester.tap(find.byKey(const Key('chatEditorSceneStatusBadge')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sceneStatusDetailsDialog')), findsOneWidget);
      expect(find.text('Scene status • No messages'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Add at least one message before preview or export.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('sceneStatusDetailsCloseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sceneStatusDetailsDialog')), findsNothing);
    },
  );

  testWidgets(
    'scene status dialog covers needs-lines details without redundant sections',
    (tester) async {
      final summary = summarizeSceneHealth(
        const Scene(
          id: 'scene-needs-lines',
          title: 'Needs lines',
          styleId: 'studio_slate',
          aspectRatio: SceneAspectRatio.portrait9x16,
          characters: [
            Character(
              id: 'character-1',
              displayName: 'Taylor',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
            Character(
              id: 'character-2',
              displayName: 'Jordan',
              avatarPath: null,
              bubbleColor: '#12B76A',
            ),
          ],
          messages: [
            Message(
              id: 'message-1',
              characterId: 'character-1',
              text: 'Locked.',
              timestampSeconds: 1,
              status: MessageStatus.sent,
              isIncoming: false,
              showTypingBefore: false,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _buildBadgeHarness(summary: summary, compact: false),
      );

      await tester.tap(find.byType(SceneStatusBadge));
      await tester.pumpAndSettle();

      expect(find.text('Scene status • Needs lines'), findsOneWidget);
      expect(find.text('1 character waiting for lines'), findsOneWidget);
      expect(
        find.text('Jordan has no lines in this scene yet.'),
        findsOneWidget,
      );
      expect(find.text('Waiting characters'), findsNothing);
    },
  );

  testWidgets(
    'scene status dialog covers ready details',
    (tester) async {
      final summary = summarizeSceneHealth(
        const Scene(
          id: 'scene-ready',
          title: 'Ready',
          styleId: 'studio_slate',
          aspectRatio: SceneAspectRatio.portrait9x16,
          characters: [
            Character(
              id: 'character-1',
              displayName: 'Taylor',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
          ],
          messages: [
            Message(
              id: 'message-1',
              characterId: 'character-1',
              text: 'Ready to roll.',
              timestampSeconds: 2,
              status: MessageStatus.seen,
              isIncoming: false,
              showTypingBefore: false,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _buildBadgeHarness(summary: summary, compact: false),
      );

      await tester.tap(find.byType(SceneStatusBadge));
      await tester.pumpAndSettle();

      expect(find.text('Scene status • Ready'), findsOneWidget);
      expect(find.text('Ready for playback'), findsOneWidget);
      expect(
        find.text('All active characters appear in the timeline.'),
        findsOneWidget,
      );
      expect(find.text('Ready for playback and export.'), findsOneWidget);
    },
  );

  testWidgets(
    'compact playback app bar keeps timeline QA status badge visible on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 900)),
              child: PlaybackScreen(projectId: projectId),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('playbackSceneStatusBadge')), findsOneWidget);
      expect(find.byKey(const Key('playbackOverflowMenuButton')), findsOneWidget);
      expect(find.text('Timeline QA'), findsNothing);
      expect(
        find.byTooltip(
          '1 shared timestamp • 1 overlapping typing cue • '
          '2 messages land on the same second and can stack in playback or export. '
          'Multiple typing indicators fire together and may feel crowded in compact previews.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('playbackSceneStatusBadge')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sceneStatusDetailsDialog')), findsOneWidget);
      expect(find.text('Scene status • Timeline QA'), findsOneWidget);
      expect(
        find.text('1 shared timestamp • 1 overlapping typing cue'),
        findsOneWidget,
      );
      expect(
        find.text(
          '2 messages land on the same second and can stack in playback or export. '
          'Multiple typing indicators fire together and may feel crowded in compact previews.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'playback app bar shows timeline QA status badge on wide layouts',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 900)),
              child: PlaybackScreen(projectId: projectId),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('playbackSceneStatusBadge')), findsOneWidget);
      expect(find.text('Timeline QA'), findsOneWidget);
      expect(
        find.byTooltip(
          '1 shared timestamp • 1 overlapping typing cue • '
          '2 messages land on the same second and can stack in playback or export. '
          'Multiple typing indicators fire together and may feel crowded in compact previews.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('playbackSceneStatusBadge')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sceneStatusDetailsDialog')), findsOneWidget);
      expect(find.text('Scene status • Timeline QA'), findsOneWidget);
      expect(
        find.text('1 shared timestamp • 1 overlapping typing cue'),
        findsOneWidget,
      );
      expect(
        find.text(
          '2 messages land on the same second and can stack in playback or export. '
          'Multiple typing indicators fire together and may feel crowded in compact previews.',
        ),
        findsOneWidget,
      );
    },
  );
}

Widget _buildBadgeHarness({
  required SceneHealthSummary summary,
  required bool compact,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SceneStatusBadge(summary: summary, compact: compact),
      ),
    ),
  );
}

String _buildEmptySceneProjectImportPayload() {
  return jsonEncode({
    'id': 'scene-status-empty-project',
    'name': 'Scene Status Empty Project',
    'type': 'other',
    'createdAt': '2026-06-10T12:00:00.000Z',
    'updatedAt': '2026-06-10T12:05:00.000Z',
    'scenes': [
      {
        'id': 'empty-scene',
        'title': 'Empty scene',
        'styleId': 'studio_slate',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'character-1',
            'displayName': 'Taylor',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
        ],
        'messages': <Object>[],
      },
    ],
  });
}

String _buildTimelineQaProjectImportPayload() {
  return jsonEncode({
    'id': 'scene-status-badge-project',
    'name': 'Scene Status Badge Project',
    'type': 'other',
    'createdAt': '2026-06-10T12:00:00.000Z',
    'updatedAt': '2026-06-10T12:05:00.000Z',
    'scenes': [
      {
        'id': 'timeline-qa-scene',
        'title': 'Stacked cues',
        'styleId': 'studio_slate',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'character-1',
            'displayName': 'Taylor',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
          {
            'id': 'character-2',
            'displayName': 'Jordan',
            'avatarPath': null,
            'bubbleColor': '#12B76A',
          },
        ],
        'messages': [
          {
            'id': 'message-1',
            'characterId': 'character-1',
            'text': 'Cue one',
            'timestampSeconds': 4,
            'status': 'sent',
            'isIncoming': false,
            'showTypingBefore': true,
          },
          {
            'id': 'message-2',
            'characterId': 'character-2',
            'text': 'Cue two',
            'timestampSeconds': 4,
            'status': 'delivered',
            'isIncoming': true,
            'showTypingBefore': true,
          },
          {
            'id': 'message-3',
            'characterId': 'character-1',
            'text': 'Cue three',
            'timestampSeconds': 7,
            'status': 'seen',
            'isIncoming': false,
            'showTypingBefore': false,
          },
        ],
      },
    ],
  });
}
