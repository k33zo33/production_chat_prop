import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/pages/project_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'missing editor route can recover by creating a starter project',
    (tester) async {
      await _pumpWithInitialLocation(
        tester,
        initialLocation: '/editor/missing-project',
      );

      expect(find.text('Project not found.'), findsOneWidget);
      expect(
        find.text(
          'This link points to a project that is missing or was deleted.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('projectNotFoundCreateStarterButton')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('New Project 1'), findsOneWidget);
      expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    },
  );

  testWidgets('missing playback route can recover by opening a demo project', (
    tester,
  ) async {
    await _pumpWithInitialLocation(
      tester,
      initialLocation: '/playback/missing-project',
    );

    expect(find.text('Project not found.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectNotFoundCreateDemoButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Playback'), findsOneWidget);
    expect(find.text('Demo Project 1'), findsOneWidget);
    expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
  });

  testWidgets('missing project recovery can return to the project list', (
    tester,
  ) async {
    await _pumpWithInitialLocation(
      tester,
      initialLocation: '/editor/missing-project',
    );

    expect(find.text('Project not found.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectNotFoundBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('Project List'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
  });
}

Future<void> _pumpWithInitialLocation(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        name: 'projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/editor/:projectId',
        name: 'editorProject',
        builder: (context, state) =>
            ChatEditorScreen(projectId: state.pathParameters['projectId']),
      ),
      GoRoute(
        path: '/playback/:projectId',
        name: 'playbackProject',
        builder: (context, state) =>
            PlaybackScreen(projectId: state.pathParameters['projectId']),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}
