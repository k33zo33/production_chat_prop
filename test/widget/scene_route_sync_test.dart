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

  testWidgets('chat editor keeps selected scene in the route query', (
    tester,
  ) async {
    final harness = await _createDemoProjectHarness();
    addTearDown(harness.dispose);

    final firstScene = harness.project.scenes.first;
    final secondScene = harness.project.scenes[1];
    final router = _buildRouter(
      initialLocation: '/editor/${harness.project.id}?sceneId=${firstScene.id}',
      builder: (state) => ChatEditorScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, container: harness.container, router: router);

    await _pumpUntilRouteSceneId(tester, router, firstScene.id);

    await tester.tap(find.byKey(const Key('editorSceneDropdown')));
    await _pumpRouteSyncFrames(tester);
    await tester.tap(find.text(secondScene.title).last);
    await _pumpRouteSyncFrames(tester);

    await _pumpUntilRouteSceneId(tester, router, secondScene.id);
    expect(find.text('Scene: ${secondScene.title}'), findsOneWidget);
  });

  testWidgets('chat editor normalizes stale scene query ids after load', (
    tester,
  ) async {
    final harness = await _createDemoProjectHarness();
    addTearDown(harness.dispose);

    final firstScene = harness.project.scenes.first;
    final router = _buildRouter(
      initialLocation: '/editor/${harness.project.id}?sceneId=missing-scene',
      builder: (state) => ChatEditorScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, container: harness.container, router: router);

    await _pumpUntilRouteSceneId(tester, router, firstScene.id);
    expect(find.text('Scene: ${firstScene.title}'), findsOneWidget);
  });

  testWidgets('playback keeps selected scene in the route query', (
    tester,
  ) async {
    final harness = await _createDemoProjectHarness();
    addTearDown(harness.dispose);

    final firstScene = harness.project.scenes.first;
    final secondScene = harness.project.scenes[1];
    final router = _buildRouter(
      initialLocation:
          '/playback/${harness.project.id}?sceneId=${firstScene.id}',
      builder: (state) => PlaybackScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, container: harness.container, router: router);

    await _pumpUntilRouteSceneId(tester, router, firstScene.id);

    await tester.tap(find.byKey(const Key('playbackSceneDropdown')));
    await _pumpRouteSyncFrames(tester);
    await tester.tap(find.text(secondScene.title).last);
    await _pumpRouteSyncFrames(tester);

    await _pumpUntilRouteSceneId(tester, router, secondScene.id);
    expect(find.text('Scene: ${secondScene.title}'), findsOneWidget);
  });

  testWidgets('playback normalizes stale scene query ids after load', (
    tester,
  ) async {
    final harness = await _createDemoProjectHarness();
    addTearDown(harness.dispose);

    final firstScene = harness.project.scenes.first;
    final router = _buildRouter(
      initialLocation: '/playback/${harness.project.id}?sceneId=missing-scene',
      builder: (state) => PlaybackScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, container: harness.container, router: router);

    await _pumpUntilRouteSceneId(tester, router, firstScene.id);
    expect(find.text('Scene: ${firstScene.title}'), findsOneWidget);
  });
}

class _DemoProjectHarness {
  _DemoProjectHarness({required this.container, required this.project});

  final ProviderContainer container;
  final Project project;

  void dispose() {
    container.dispose();
  }
}

Future<_DemoProjectHarness> _createDemoProjectHarness() async {
  final container = ProviderContainer();
  final projectId = await container
      .read(projectsControllerProvider.notifier)
      .createDemoProject();
  final projects = await container.read(projectsControllerProvider.future);
  final project = projects.singleWhere((candidate) => candidate.id == projectId);
  return _DemoProjectHarness(container: container, project: project);
}

GoRouter _buildRouter({
  required String initialLocation,
  required Widget Function(GoRouterState state) builder,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/editor/:projectId',
        name: 'editorProject',
        builder: (context, state) => builder(state),
      ),
      GoRoute(
        path: '/playback/:projectId',
        name: 'playbackProject',
        builder: (context, state) => builder(state),
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
  await _pumpRouteSyncFrames(tester);
}

Future<void> _pumpRouteSyncFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

Future<void> _pumpUntilRouteSceneId(
  WidgetTester tester,
  GoRouter router,
  String expectedSceneId,
) async {
  for (var index = 0; index < 20; index++) {
    if (router.routeInformationProvider.value.uri.queryParameters['sceneId'] ==
        expectedSceneId) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  expect(
    router.routeInformationProvider.value.uri.queryParameters['sceneId'],
    expectedSceneId,
  );
}
