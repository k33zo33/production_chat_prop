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

  testWidgets('add demo project action seeds prefilled project', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Demo Project 1'), findsOneWidget);
    expect(find.text('Type: ad'), findsOneWidget);
    expect(
      find.textContaining('Scenes: 2 • Messages: 7 • Max: 11s'),
      findsOneWidget,
    );
  });

  testWidgets('empty state shows quick start action buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.byKey(const Key('emptyCreateProjectButton')), findsOneWidget);
    expect(find.byKey(const Key('emptyCreateDemoButton')), findsOneWidget);
  });

  testWidgets('empty state demo button seeds demo project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('emptyCreateDemoButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Demo Project 1'), findsOneWidget);
    expect(find.text('Type: ad'), findsOneWidget);
  });

  testWidgets('create project and navigate to chat editor from project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await _openChatEditorFromProjectList(tester);

    expect(find.text('Chat Editor'), findsOneWidget);
    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    expect(
      find.textContaining('Scene summary: 2 characters • 3 messages • max 9s'),
      findsOneWidget,
    );
  });

  testWidgets('duplicate and delete project from popup menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsOneWidget);

    final copyTitle = find.text('New Project 1 Copy');
    final copyCard = find.ancestor(of: copyTitle, matching: find.byType(Card));
    final copyMenuButton = find.descendant(
      of: copyCard,
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.tap(copyMenuButton);
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

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Project Name'),
      ),
      'Renamed Project',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Renamed Project'), findsOneWidget);
    expect(find.text('New Project 1'), findsNothing);
  });

  testWidgets('project list search filters cards by name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);
    expect(find.text('New Project 2'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectSearchField')), '2');
    await tester.pumpAndSettle();

    expect(find.text('New Project 2'), findsOneWidget);
    expect(find.text('New Project 1'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('projectSearchField')),
      'not-found',
    );
    await tester.pumpAndSettle();

    expect(find.text('No projects match current filters.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectSearchField')), '');
    await tester.pumpAndSettle();

    expect(find.text('New Project 1'), findsOneWidget);
    expect(find.text('New Project 2'), findsOneWidget);
  });

  testWidgets('project list type chips filter result set', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectTypeFilter_ad')));
    await tester.pumpAndSettle();
    expect(find.text('No projects match current filters.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectTypeFilter_other')));
    await tester.pumpAndSettle();
    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectTypeFilter_all')));
    await tester.pumpAndSettle();
    expect(find.text('New Project 1'), findsOneWidget);
  });

  testWidgets('project type chips show per-type counts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Other (2)'), findsOneWidget);
    expect(find.text('Ad (0)'), findsOneWidget);
    expect(find.text('Series (0)'), findsOneWidget);
  });

  testWidgets('project popup type actions update card and chip counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Type: other'), findsOneWidget);
    expect(find.text('Ad (0)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Type: Ad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Type: ad'), findsOneWidget);
    expect(find.text('Ad (1)'), findsOneWidget);
    expect(find.text('Other (0)'), findsOneWidget);
  });

  testWidgets('project sort dropdown changes card ordering by name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final sortDropdown = find.byKey(const Key('projectSortDropdown'));
    await tester.ensureVisible(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (Z-A)').last);
    await tester.pumpAndSettle();

    final yNewProject2Desc = tester.getTopLeft(find.text('New Project 2')).dy;
    final yNewProject1Desc = tester.getTopLeft(find.text('New Project 1')).dy;
    expect(yNewProject2Desc, lessThan(yNewProject1Desc));

    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (A-Z)').last);
    await tester.pumpAndSettle();

    final yNewProject2Asc = tester.getTopLeft(find.text('New Project 2')).dy;
    final yNewProject1Asc = tester.getTopLeft(find.text('New Project 1')).dy;
    expect(yNewProject1Asc, lessThan(yNewProject2Asc));
  });

  testWidgets('project sort dropdown supports updated oldest ordering', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final sortDropdown = find.byKey(const Key('projectSortDropdown'));
    await tester.ensureVisible(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Updated (Oldest)').last);
    await tester.pumpAndSettle();

    final yNewProject1 = tester.getTopLeft(find.text('New Project 1')).dy;
    final yNewProject2 = tester.getTopLeft(find.text('New Project 2')).dy;
    expect(yNewProject1, lessThan(yNewProject2));
  });

  testWidgets('project reset button clears search and filter state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byKey(const Key('projectSearchField')), '2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('projectTypeFilter_ad')));
    await tester.pumpAndSettle();

    final sortDropdown = find.byKey(const Key('projectSortDropdown'));
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (A-Z)').last);
    await tester.pumpAndSettle();

    expect(find.text('No projects match current filters.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectResetFiltersButton')));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('projectSearchField')),
    );
    expect(searchField.controller?.text ?? '', isEmpty);

    final allChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('projectTypeFilter_all')),
    );
    expect(allChip.selected, isTrue);
    expect(find.text('New Project 1'), findsOneWidget);
    expect(find.text('New Project 2'), findsOneWidget);
  });

  testWidgets('project list shows result summary count', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectSearchField')), '2');
    await tester.pumpAndSettle();

    expect(find.text('Showing 1 of 2 projects'), findsOneWidget);
  });

  testWidgets('project card shows scene and message summary stats', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Scenes: 1 • Messages: 3 • Max: 9s'),
      findsOneWidget,
    );
  });

  testWidgets('create project and navigate to playback from project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await _openPlaybackFromProjectList(tester);

    expect(find.text('Playback'), findsOneWidget);
    expect(find.text('No project selected.'), findsNothing);
    expect(
      find.textContaining('Scene: Scene 1', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Messages: 3', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('add message in chat editor and see it in playback', (
    tester,
  ) async {
    const newMessageText = 'Widget flow: newly added message';

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);
    await _ensureMessageComposerVisible(tester);

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

    await _openPlaybackFromProjectList(tester);

    expect(find.text('Playback'), findsOneWidget);
    expect(
      find.textContaining('t=0s / 15 s', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Messages: 4', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('character add rename delete flow in chat editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    final addCharacterButton = find
        .widgetWithText(FilledButton, 'Add', skipOffstage: false)
        .first;
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

  testWidgets('edit scene settings updates scene header info', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    await tester.tap(find.text('Edit Scene Settings'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Scene Title'),
      ),
      'Act 2',
    );
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Style ID'),
      ),
      'cleanroom_day',
    );

    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Act 2'), findsOneWidget);
    expect(
      find.textContaining('Style: cleanroom_day'),
      findsOneWidget,
    );
  });

  testWidgets('scene settings preset selection updates style id', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    await tester.tap(find.text('Edit Scene Settings'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    final presetDropdown = find.descendant(
      of: dialogFinder,
      matching: find.byType(DropdownButtonFormField<String>).first,
    );
    expect(
      find.descendant(
        of: dialogFinder,
        matching: find.byKey(const Key('sceneStylePreviewRow')),
      ),
      findsOneWidget,
    );
    await tester.tap(presetDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Night Shift (night_shift)').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: dialogFinder, matching: find.text('Night Shift')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Style: night_shift'),
      findsOneWidget,
    );
  });

  testWidgets('scene add rename delete flow in chat editor', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add Scene'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Scene Title'),
      'Scene B',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene B'), findsOneWidget);
    expect(find.text('Scenes: 2', skipOffstage: false), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rename Scene'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Scene Title'),
      'Scene C',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene C'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete Scene'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    expect(find.text('Scenes: 1'), findsOneWidget);
  });

  testWidgets('scene move up changes selected scene position', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    Future<void> addSceneNamed(String name) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Add Scene'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Scene Title'),
        name,
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await addSceneNamed('Scene B');
    await addSceneNamed('Scene C');

    expect(find.textContaining('Scene: Scene C'), findsOneWidget);

    final moveDownBefore = tester.widget<OutlinedButton>(
      find.byKey(const Key('moveSceneDownButton')),
    );
    expect(moveDownBefore.onPressed, isNull);

    await tester.tap(find.byKey(const Key('moveSceneUpButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final moveDownAfter = tester.widget<OutlinedButton>(
      find.byKey(const Key('moveSceneDownButton')),
    );
    expect(moveDownAfter.onPressed, isNotNull);
    expect(find.textContaining('Scene: Scene C'), findsOneWidget);
  });

  testWidgets('duplicate scene creates and selects copied scene', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    final duplicateSceneButton = find.byKey(const Key('duplicateSceneButton'));
    await tester.ensureVisible(duplicateSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(duplicateSceneButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene 1 Copy'), findsOneWidget);
  });

  testWidgets('apply scene template updates editor content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    final templateButton = find.byKey(const Key('applyTemplateBriefingButton'));
    await tester.ensureVisible(templateButton);
    await tester.pumpAndSettle();
    await tester.tap(templateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Applied template: Briefing'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Call time shifted to 08:30.'), findsOneWidget);
  });

  testWidgets('edit message updates timeline metadata in chat editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

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

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);
    await _ensureMessageComposerVisible(tester);

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

  testWidgets('shows add-message validation snackbars for invalid input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);
    await _ensureMessageComposerVisible(tester);

    final messageTextField = find.widgetWithText(TextField, 'Message Text');
    final timestampField = find.widgetWithText(
      TextField,
      'Timestamp (seconds)',
    );
    final addMessageButton = find.widgetWithText(FilledButton, 'Add Message');

    await tester.enterText(messageTextField, 'Validation case');
    await tester.enterText(timestampField, 'abc');
    await tester.ensureVisible(addMessageButton);
    await tester.pumpAndSettle();
    await tester.tap(addMessageButton);
    await tester.pumpAndSettle();

    expect(find.text('Timestamp must be a valid number.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(timestampField, '-1');
    await tester.ensureVisible(addMessageButton);
    await tester.pumpAndSettle();
    await tester.tap(addMessageButton);
    await tester.pumpAndSettle();

    expect(find.text('Timestamp cannot be negative.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(messageTextField, '');
    await tester.enterText(timestampField, '12');
    await tester.ensureVisible(addMessageButton);
    await tester.pumpAndSettle();
    await tester.tap(addMessageButton);
    await tester.pumpAndSettle();

    expect(find.text('Message text cannot be empty.'), findsOneWidget);
  });

  testWidgets('message move up reorders visible timeline rows', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final yesFinder = find.text('Yes, prop phone is prepared.');
    final greatFinder = find.text('Great, rolling in 3 minutes.');
    final beforeYes = tester.getTopLeft(yesFinder).dy;
    final beforeGreat = tester.getTopLeft(greatFinder).dy;
    expect(beforeGreat, greaterThan(beforeYes));

    final moveUpButton = find.byIcon(Icons.arrow_upward_rounded).last;
    await tester.ensureVisible(moveUpButton);
    await tester.pumpAndSettle();
    await tester.tap(moveUpButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final afterYes = tester.getTopLeft(yesFinder).dy;
    final afterGreat = tester.getTopLeft(greatFinder).dy;
    expect(afterGreat, lessThan(afterYes));
  });

  testWidgets('bulk select deletes multiple messages in chat editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleMessageSelectionModeButton')));
    await tester.pumpAndSettle();

    final firstCheckbox = find.byType(Checkbox).at(0);
    await tester.ensureVisible(firstCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();
    final secondCheckbox = find.byType(Checkbox).at(1);
    await tester.ensureVisible(secondCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(secondCheckbox);
    await tester.pumpAndSettle();

    final deleteSelectedButton = find.byKey(
      const Key('deleteSelectedMessagesButton'),
    );
    await tester.ensureVisible(deleteSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteSelectedButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Deleted 2 selected messages.'), findsOneWidget);
    expect(find.text('Ready for set in 10?'), findsNothing);
    expect(find.text('Yes, prop phone is prepared.'), findsNothing);
  });

  testWidgets('clear scene chat removes all messages in editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final clearSceneButton = find.byKey(const Key('clearSceneMessagesButton'));
    await tester.ensureVisible(clearSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(clearSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Cleared 3 messages from scene.'),
      findsOneWidget,
    );
    expect(find.text('No messages in this scene yet.'), findsOneWidget);
  });

  testWidgets('playback step controls update timecode and typing indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    expect(find.textContaining('(00:00 / 00:09)'), findsOneWidget);

    final plusOneButton = find.widgetWithText(FilledButton, '+1s');
    await tester.ensureVisible(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        't=3s / 9 s (00:03 / 00:09)',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Mia is typing...', skipOffstage: false), findsOneWidget);

    final endButton = find.widgetWithText(OutlinedButton, 'End');
    await tester.ensureVisible(endButton);
    await tester.pumpAndSettle();
    await tester.tap(endButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Status: finished', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
    'playback progress summary reflects current time and visibility',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      expect(
        find.textContaining('Progress: 0% • Visible messages: 1/3'),
        findsOneWidget,
      );

      final plusFiveButton = find.byKey(const Key('seekForward5Button'));
      await tester.ensureVisible(plusFiveButton);
      await tester.pumpAndSettle();
      await tester.tap(plusFiveButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Progress: 56% • Visible messages: 2/3'),
        findsOneWidget,
      );
    },
  );

  testWidgets('playback timeline shows polished status and direction chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -180));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('OUTGOING', skipOffstage: false), findsWidgets);
    expect(find.text('SENT', skipOffstage: false), findsWidgets);
    expect(find.text('TYPING BEFORE', skipOffstage: false), findsWidgets);
  });

  testWidgets('playback cue buttons jump between message timestamps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    final nextCueButton = find.byKey(
      const Key('nextCueButton'),
      skipOffstage: false,
    );
    await tester.ensureVisible(nextCueButton);
    await tester.pumpAndSettle();
    await tester.tap(nextCueButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=4s / 9 s', skipOffstage: false),
      findsOneWidget,
    );

    final prevCueButton = find.byKey(const Key('prevCueButton'));
    await tester.ensureVisible(prevCueButton);
    await tester.pumpAndSettle();
    await tester.tap(prevCueButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=0s / 9 s', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('playback quick seek +/-5 buttons update timecode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    final plusFiveButton = find.byKey(const Key('seekForward5Button'));
    await tester.ensureVisible(plusFiveButton);
    await tester.pumpAndSettle();
    await tester.tap(plusFiveButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=5s / 9 s', skipOffstage: false),
      findsOneWidget,
    );

    final minusFiveButton = find.byKey(const Key('seekBackward5Button'));
    await tester.ensureVisible(minusFiveButton);
    await tester.pumpAndSettle();
    await tester.tap(minusFiveButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=0s / 9 s', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
    'playback resets stale progress after scene messages are cleared',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      final plusOneButton = find.widgetWithText(FilledButton, '+1s');
      await tester.ensureVisible(plusOneButton);
      await tester.pumpAndSettle();
      await tester.tap(plusOneButton);
      await tester.pumpAndSettle();
      await tester.tap(plusOneButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('t=2s / 9 s', skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Back to Projects').first);
      await tester.pumpAndSettle();
      await _openChatEditorFromProjectList(tester);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -220));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final clearSceneButton = find.byKey(
        const Key('clearSceneMessagesButton'),
      );
      await tester.ensureVisible(clearSceneButton);
      await tester.pumpAndSettle();
      await tester.tap(clearSceneButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Clear').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back to Projects').first);
      await tester.pumpAndSettle();
      await _openPlaybackFromProjectList(tester);

      expect(
        find.textContaining('Status: idle', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('t=0s / 0 s', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets('playback preview toggles affect screenshot export feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

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

    final hasScreenshotFeedback =
        find.textContaining('Export: Screenshot OK').evaluate().isNotEmpty ||
        find.textContaining('Export: Screenshot Error').evaluate().isNotEmpty ||
        find.textContaining('Export: Running').evaluate().isNotEmpty;
    expect(hasScreenshotFeedback, isTrue);
  });

  testWidgets('video export button shows fallback package feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    final exportVideoButton = find.byKey(const Key('exportVideoButton'));
    await tester.ensureVisible(exportVideoButton);
    await tester.pumpAndSettle();
    await tester.tap(exportVideoButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Video export failed: download is not available on this platform.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Export: Video Error'),
      findsOneWidget,
    );
  });

  testWidgets('playback aspect ratio chips update selected scene ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    expect(
      find.textContaining('Scene ratio: 9:16', skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('aspectRatioLandscapeChip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Scene ratio: 16:9', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('playback export buttons are disabled for empty scenes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final clearSceneButton = find.byKey(const Key('clearSceneMessagesButton'));
    await tester.ensureVisible(clearSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(clearSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Projects').first);
    await tester.pumpAndSettle();
    await _openPlaybackFromProjectList(tester);

    final screenshotButton = tester.widget<FilledButton>(
      find.byKey(const Key('exportScreenshotButton')),
    );
    final videoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('exportVideoButton')),
    );

    expect(screenshotButton.onPressed, isNull);
    expect(videoButton.onPressed, isNull);
    expect(
      find.textContaining('Export readiness: No messages in scene'),
      findsOneWidget,
    );
  });

  testWidgets('long chat scene keeps playback controls and export available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openChatEditorFromProjectList(tester);
    await _ensureMessageComposerVisible(tester);

    final addMessageButton = find.widgetWithText(FilledButton, 'Add Message');
    for (var i = 0; i < 12; i++) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Message Text'),
        'Load test message $i',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Timestamp (seconds)'),
        '${20 + i}',
      );
      await tester.ensureVisible(addMessageButton);
      await tester.pumpAndSettle();
      await tester.tap(addMessageButton);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Projects').first);
    await tester.pumpAndSettle();
    await _openPlaybackFromProjectList(tester);

    expect(find.textContaining('Messages: 15'), findsOneWidget);

    final screenshotButton = tester.widget<FilledButton>(
      find.byKey(const Key('exportScreenshotButton')),
    );
    final videoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('exportVideoButton')),
    );
    expect(screenshotButton.onPressed, isNotNull);
    expect(videoButton.onPressed, isNotNull);
    expect(find.textContaining('Export readiness: Ready'), findsOneWidget);

    final nextCueButton = find.byKey(const Key('nextCueButton'));
    await tester.ensureVisible(nextCueButton);
    await tester.pumpAndSettle();
    await tester.tap(nextCueButton);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('t=4s /', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('changing aspect ratio keeps playback progress stable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    final plusOneButton = find.widgetWithText(FilledButton, '+1s');
    await tester.ensureVisible(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=2s / 9 s', skipOffstage: false),
      findsOneWidget,
    );

    final aspectRatioLandscapeChip = find.byKey(
      const Key('aspectRatioLandscapeChip'),
      skipOffstage: false,
    );
    await tester.ensureVisible(aspectRatioLandscapeChip);
    await tester.pumpAndSettle();
    await tester.tap(aspectRatioLandscapeChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Scene ratio: 16:9', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('t=2s / 9 s', skipOffstage: false),
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

Future<void> _ensureMessageComposerVisible(WidgetTester tester) async {
  var messageTextFinder = find.widgetWithText(
    TextField,
    'Message Text',
    skipOffstage: false,
  );
  if (messageTextFinder.evaluate().isEmpty) {
    final scrollable = find.byType(ListView).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -220));
      await tester.pumpAndSettle();
      messageTextFinder = find.widgetWithText(
        TextField,
        'Message Text',
        skipOffstage: false,
      );
      if (messageTextFinder.evaluate().isNotEmpty) {
        break;
      }
    }
  }

  final messageTextField = messageTextFinder.first;
  await tester.ensureVisible(messageTextField);
  await tester.pumpAndSettle();
}

Future<void> _openChatEditorFromProjectList(WidgetTester tester) async {
  final openEditorButton = find.text('Open Chat Editor').first;
  await tester.ensureVisible(openEditorButton);
  await tester.pumpAndSettle();
  await tester.tap(openEditorButton);
  await tester.pumpAndSettle();
  if (find.text('Chat Editor').evaluate().isNotEmpty) {
    return;
  }

  final retryButton = find.text('Open Chat Editor');
  if (retryButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(retryButton.first);
    await tester.pumpAndSettle();
    await tester.tap(retryButton.first);
    await tester.pumpAndSettle();
  }
}

Future<void> _openPlaybackFromProjectList(WidgetTester tester) async {
  final openPlaybackButton = find.text('Open Playback').first;
  await tester.ensureVisible(openPlaybackButton);
  await tester.pumpAndSettle();
  await tester.tap(openPlaybackButton);
  await tester.pumpAndSettle();
}
