import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'playback empty state offers editor and template recovery actions',
    (
      tester,
    ) async {
      final harness = await _createEmptySceneHarness();
      addTearDown(harness.dispose);

      final router = _buildRouter(
        initialLocation:
            '/playback/${harness.project.id}?sceneId=${harness.sceneId}',
      );
      addTearDown(router.dispose);

      await _pumpRouter(tester, container: harness.container, router: router);

      expect(find.byKey(const Key('playbackEmptyStateHint')), findsOneWidget);
      expect(
        find.byKey(const Key('playbackEmptyStateOpenEditorButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('playbackEmptyStateBriefingTemplateButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('playbackEmptyStateGroupAlertTemplateButton')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('playbackEmptyStateOpenEditorButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(
        find.text('Scene: ${harness.project.scenes.first.title}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('playback empty state can seed a briefing template directly', (
    tester,
  ) async {
    final harness = await _createEmptySceneHarness();
    addTearDown(harness.dispose);

    final router = _buildRouter(
      initialLocation:
          '/playback/${harness.project.id}?sceneId=${harness.sceneId}',
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, container: harness.container, router: router);

    expect(find.text('Messages: 0'), findsOneWidget);
    expect(find.text('Export readiness: No messages in scene'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('playbackEmptyStateBriefingTemplateButton')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackEmptyStateHint')), findsNothing);
    expect(find.text('Messages: 3'), findsOneWidget);
    expect(find.text('Export readiness: Ready'), findsOneWidget);
    expect(find.text('Applied template: Briefing'), findsOneWidget);
  });
}

class _EmptySceneHarness {
  _EmptySceneHarness({
    required this.container,
    required this.project,
    required this.sceneId,
  });

  final ProviderContainer container;
  final Project project;
  final String sceneId;

  void dispose() {
    container.dispose();
  }
}

Future<_EmptySceneHarness> _createEmptySceneHarness() async {
  final container = ProviderContainer();
  final projectId = await container
      .read(projectsControllerProvider.notifier)
      .createProject();
  final projects = await container.read(projectsControllerProvider.future);
  final project = projects.singleWhere(
    (candidate) => candidate.id == projectId,
  );
  final sceneId = project.scenes.first.id;

  await container
      .read(projectsControllerProvider.notifier)
      .clearSceneMessages(
        projectId: project.id,
        sceneId: sceneId,
      );

  final refreshedProjects = await container.read(
    projectsControllerProvider.future,
  );
  final refreshedProject = refreshedProjects.singleWhere(
    (candidate) => candidate.id == projectId,
  );

  return _EmptySceneHarness(
    container: container,
    project: refreshedProject,
    sceneId: sceneId,
  );
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/editor/:projectId',
        name: 'editorProject',
        builder: (context, state) => ChatEditorScreen(
          projectId: state.pathParameters['projectId'],
          initialSceneId: state.uri.queryParameters['sceneId'],
        ),
      ),
      GoRoute(
        path: '/playback/:projectId',
        name: 'playbackProject',
        builder: (context, state) => PlaybackScreen(
          projectId: state.pathParameters['projectId'],
          initialSceneId: state.uri.queryParameters['sceneId'],
        ),
      ),
      GoRoute(
        path: '/',
        name: 'projects',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}

Future<void> _pumpRouter(
  WidgetTester tester, {
  required ProviderContainer container,
  required GoRouter router,
}) async {
  await tester.binding.setSurfaceSize(const Size(960, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}
