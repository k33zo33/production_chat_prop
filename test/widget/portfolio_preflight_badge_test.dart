import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/app/app.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
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

      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

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
