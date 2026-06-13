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
    'empty project state stays scroll-safe on short mobile heights',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 280));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProjectListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('emptyProjectStateScrollView')),
        findsOneWidget,
      );

      await tester.dragUntilVisible(
        find.byKey(const Key('emptyLoadExportQaButton')),
        find.byKey(const Key('emptyProjectStateScrollView')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyLoadExportQaButton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing-project recovery stays scroll-safe on short mobile heights',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 280));
      await _pumpWithInitialLocation(
        tester,
        initialLocation: '/playback/missing-project',
      );

      expect(
        find.byKey(const Key('projectNotFoundRecoveryScrollView')),
        findsOneWidget,
      );

      await tester.dragUntilVisible(
        find.byKey(const Key('projectNotFoundCreateDemoButton')),
        find.byKey(const Key('projectNotFoundRecoveryScrollView')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('projectNotFoundCreateDemoButton')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Demo Project 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat editor no-project placeholder uses the short-height scroll shell',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 280));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ChatEditorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('chatEditorNoProjectScrollView')),
        findsOneWidget,
      );
      expect(find.text('No project selected.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'playback no-project placeholder uses the short-height scroll shell',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 280));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PlaybackScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('playbackNoProjectScrollView')),
        findsOneWidget,
      );
      expect(find.text('No project selected.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
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
