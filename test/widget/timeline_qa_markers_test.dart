import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'chat editor shows inline timeline QA markers for stacked cue messages',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;
      final scene = project.scenes.single;
      final sceneHealth = summarizeSceneHealth(scene);
      final nonWarningMessageId = scene.messages
          .firstWhere(
            (message) => !sceneHealth.hasTimelineWarningForMessage(message.id),
          )
          .id;

      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 900)),
              child: ChatEditorScreen(
                projectId: project.id,
                forceCompactLayout: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sceneSummaryLine')), findsOneWidget);
      expect(find.byKey(const Key('sceneTimingQaSummaryLine')), findsOneWidget);
      expect(
        find.textContaining(
          'Timeline QA: 1 shared timestamp • 1 overlapping typing cue',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Cue one'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(sceneHealth.timelineWarningMessageIds, hasLength(2));
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
      expect(
        find.text(
          scene.messages
              .firstWhere((message) => message.id == nonWarningMessageId)
              .text,
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Timeline QA warning: shared timestamp • overlapping typing cue',
        ),
        findsNWidgets(2),
      );
    },
  );
}

String _buildTimelineQaProjectImportPayload() {
  return jsonEncode({
    'id': 'timeline-qa-marker-project',
    'name': 'Timeline QA Marker Project',
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
