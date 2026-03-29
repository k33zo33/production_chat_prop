import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app renders root router', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Project List'), findsOneWidget);
  });

  testWidgets('create project and navigate to chat editor from project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Chat Editor'), findsOneWidget);
    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    expect(find.text('Add Message'), findsWidgets);
  });

  testWidgets('duplicate and delete project from popup menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsNothing);
    expect(find.text('New Project 1'), findsOneWidget);
  });

  testWidgets('rename project from popup menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Renamed Project');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Renamed Project'), findsOneWidget);
    expect(find.text('New Project 1'), findsNothing);
  });

  testWidgets('create project and navigate to playback from project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.text('Open Playback'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Playback'), findsOneWidget);
    expect(
      find.textContaining('Playback Timeline (read-only)'),
      findsOneWidget,
    );
    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
  });

  testWidgets('add message in chat editor and see it in playback', (
    tester,
  ) async {
    const newMessageText = 'Widget flow: newly added message';

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Text'),
      newMessageText,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Timestamp (seconds)'),
      '15',
    );
    final addMessageButton = find.widgetWithText(FilledButton, 'Add Message');
    await tester.ensureVisible(addMessageButton);
    await tester.pumpAndSettle();
    await tester.tap(addMessageButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(newMessageText), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Projects').first);
    await tester.pumpAndSettle();

    final openPlaybackButton = find.text('Open Playback');
    await tester.ensureVisible(openPlaybackButton);
    await tester.pumpAndSettle();
    await tester.tap(openPlaybackButton);
    await tester.pumpAndSettle();

    expect(find.text('Playback'), findsOneWidget);
    expect(find.text(newMessageText), findsOneWidget);
  });

  testWidgets('character add rename delete flow in chat editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pumpAndSettle();

    final addCharacterButton = find.widgetWithText(FilledButton, 'Add');
    await tester.ensureVisible(addCharacterButton);
    await tester.pumpAndSettle();
    await tester.tap(addCharacterButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Character Name'),
      'Zara',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Zara'), findsWidgets);

    final renameZaraButton = find.widgetWithText(OutlinedButton, 'Rename Zara');
    await tester.ensureVisible(renameZaraButton);
    await tester.pumpAndSettle();
    await tester.tap(renameZaraButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Character Name'),
      'Zed',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Zed'), findsOneWidget);

    final zedChip = find.widgetWithText(Chip, 'Zed');
    final zedDeleteIcon = find.descendant(
      of: zedChip,
      matching: find.byIcon(Icons.person_remove_rounded),
    );
    await tester.ensureVisible(zedChip);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(zedDeleteIcon));
    await tester.pumpAndSettle();

    expect(find.text('Rename Zed'), findsNothing);
    expect(find.text('Zed'), findsNothing);
  });

  testWidgets('edit message updates timeline metadata in chat editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final messageMenuButton = find.byIcon(Icons.more_horiz_rounded).first;
    await tester.tap(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Message'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Text'),
      ),
      'Edited from dialog',
    );
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Timestamp (seconds)'),
      ),
      '1',
    );

    final incomingTile = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(SwitchListTile, 'Incoming'),
    );
    await tester.tap(incomingTile);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edited from dialog'), findsOneWidget);
    expect(find.textContaining('t=1s'), findsOneWidget);
  });

  testWidgets('warns when adding message with backward timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Text'),
      'This timestamp is behind',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Timestamp (seconds)'),
      '1',
    );

    final addMessageButton = find.widgetWithText(FilledButton, 'Add Message');
    await tester.ensureVisible(addMessageButton);
    await tester.pumpAndSettle();
    await tester.tap(addMessageButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Warning: timestamp goes backward'),
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
