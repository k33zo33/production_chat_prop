import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/app/app.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/core/utils/character_bubble_colors.dart';
import 'package:production_chat_prop/core/utils/file_picker/file_picker.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/character_avatar.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/playback/presentation/controllers/playback_controller.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';
import 'package:production_chat_prop/features/projects/presentation/pages/project_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScreenshotExportService extends ScreenshotExportService {
  _FakeScreenshotExportService(this._result);

  final ScreenshotExportResult _result;

  @override
  Future<ScreenshotExportResult> exportBoundaryAsPng({
    required GlobalKey boundaryKey,
    required String projectName,
    required String sceneTitle,
    required SceneAspectRatio aspectRatio,
    double? pixelRatio,
  }) async {
    return _result;
  }
}

const _exportQaFixtureJson = '''
{
  "id": "qa-export-project",
  "name": "Export QA Project",
  "type": "ad",
  "createdAt": "2026-05-14T21:00:00.000Z",
  "updatedAt": "2026-05-14T21:00:00.000Z",
  "scenes": [
    {
      "id": "qa-scene-hero-portrait",
      "title": "Scene 1 - Hero Portrait",
      "styleId": "studio_default",
      "aspectRatio": "portrait9x16",
      "characters": [
        {
          "id": "qa-hero-producer",
          "displayName": "Producer",
          "avatarPath": null,
          "bubbleColor": "#2E90FA"
        }
      ],
      "messages": [
        {
          "id": "qa-hero-message-1",
          "characterId": "qa-hero-producer",
          "text": "Hero phone is framed for the close-up.",
          "timestampSeconds": 0,
          "status": "sent",
          "isIncoming": false,
          "showTypingBefore": false
        }
      ]
    }
  ]
}
''';

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
    expect(find.text('Type: Ad'), findsOneWidget);
    expect(find.byKey(const Key('demoProjectBadge')), findsOneWidget);
    expect(
      find.textContaining('Scenes: 2 • Messages: 7 • Max: 11s'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Playback: 2/2 ready • 0 empty • 2 styles'),
      findsOneWidget,
    );
    expect(find.text('Ready for playback'), findsOneWidget);
    expect(find.text('Open Playback'), findsAtLeastNWidgets(1));
  });

  testWidgets('empty state shows quick start action buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.byKey(const Key('emptyCreateProjectButton')), findsOneWidget);
    expect(find.byKey(const Key('emptyCreateDemoButton')), findsOneWidget);
    expect(find.byKey(const Key('emptyLoadExportQaButton')), findsOneWidget);
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
    expect(find.text('Type: Ad'), findsOneWidget);
  });

  testWidgets('empty state create button creates starter project', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('emptyCreateProjectButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);
    expect(find.text('Type: Other'), findsOneWidget);
  });

  testWidgets('load export QA project action imports bundled QA fixture', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportQaFixtureLoaderProvider.overrideWithValue(
            () async => _exportQaFixtureJson,
          ),
        ],
        child: const ProductionChatPropApp(),
      ),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Load Export QA Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Export QA Project'), findsOneWidget);
    expect(find.text('Scene 1 - Hero Portrait'), findsNothing);
    expect(find.text('Imported project: Export QA Project.'), findsOneWidget);
  });

  testWidgets(
    'load export QA project action does not duplicate bundled QA fixture',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportQaFixtureLoaderProvider.overrideWithValue(
              () async => _exportQaFixtureJson,
            ),
          ],
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byTooltip('Load Export QA Project'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Load Export QA Project'));
      await tester.pumpAndSettle();

      expect(find.text('Export QA Project'), findsOneWidget);
      expect(find.textContaining('(Imported)'), findsNothing);
      expect(find.text('Export QA Project is already loaded.'), findsOneWidget);
    },
  );

  testWidgets('export all projects action shows empty portfolio feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('exportAllProjectsJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No projects available to export.'), findsOneWidget);
  });

  testWidgets('export all projects action shows download fallback feedback', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('exportAllProjectsJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text(
        'Download unavailable. Project portfolio JSON copied to clipboard.',
      ),
      findsOneWidget,
    );
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

    await _scrollProjectListToCards(tester);

    expect(find.text('New Project 1'), findsOneWidget);

    await _openProjectMenuForProject(tester, 'New Project 1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsOneWidget);

    await _openProjectMenuForProject(
      tester,
      'New Project 1 Copy',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete Project'), findsOneWidget);
    expect(
      find.text(
        'Delete "New Project 1 Copy"? This action removes the project from local storage.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirmDeleteProjectButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsNothing);
    expect(find.text('New Project 1'), findsOneWidget);
  });

  testWidgets(
    'compact project delete confirmation stays usable on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container.read(projectsControllerProvider.notifier).createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      await _openProjectMenuForProject(tester, 'New Project 1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Project'), findsOneWidget);
      expect(
        find.text(
          'Delete "New Project 1"? This action removes the project from local storage.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('cancelDeleteProjectButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirmDeleteProjectButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('confirmDeleteProjectButton')));
      await tester.pumpAndSettle();

      expect(find.text('New Project 1'), findsNothing);
      expect(find.text('No projects yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact project delete confirmation keeps long project names readable on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();
      const longProjectName =
          'Production Chat Prop Beta Hand-off Project With Extra Long Client Review Name 01';
      await container
          .read(projectsControllerProvider.notifier)
          .renameProject(
            projectId: projectId,
            newName: longProjectName,
          );

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      await _ensureProjectCardVisibleByName(tester, longProjectName);
      final projectTitle = tester.widget<Text>(
        find.text(longProjectName).first,
      );
      expect(projectTitle.maxLines, 2);
      expect(projectTitle.overflow, TextOverflow.ellipsis);

      await _openProjectMenuForProject(tester, longProjectName);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Project'), findsOneWidget);
      expect(
        find.text(
          'Delete "$longProjectName"? This action removes the project from local storage.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('cancelDeleteProjectButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirmDeleteProjectButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact editor and playback headers clamp long project names without exceptions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);
      const longProjectName =
          'Production Chat Prop Mobile Beta Review Project With Very Long Approval Label';
      await container
          .read(projectsControllerProvider.notifier)
          .renameProject(
            projectId: projectId,
            newName: longProjectName,
          );

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final editorTitle = tester.widget<Text>(find.text(longProjectName).first);
      expect(editorTitle.maxLines, 2);
      expect(editorTitle.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      final playbackTitle = tester.widget<Text>(
        find.text(longProjectName).first,
      );
      expect(playbackTitle.maxLines, 2);
      expect(playbackTitle.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bulk project selection exports selected projects payload', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('toggleProjectSelectionModeButton')));
    await tester.pumpAndSettle();

    final selectionCheckbox = find.byType(Checkbox).first;
    await tester.ensureVisible(selectionCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(selectionCheckbox, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exportSelectedProjectsJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text(
        'Download unavailable. Selected project JSON copied to clipboard.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('bulk project selection shows unchanged-type feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('toggleProjectSelectionModeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setSelectedProjectsTypeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Type: Other').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Selected projects are already type Other.'),
      findsOneWidget,
    );
  });

  testWidgets('bulk project selection deletes multiple projects', (
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

    await _scrollProjectListToCards(tester);

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleProjectSelectionModeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Select Projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('deleteSelectedProjectsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Deleted 2 selected projects.'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets(
    'bulk project selection prunes hidden matches before destructive actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();
      await container.read(projectsControllerProvider.notifier).createProject();

      final initialProjects = await container.read(
        projectsControllerProvider.future,
      );
      final sortedProjects = [...initialProjects]
        ..sort((left, right) => left.name.compareTo(right.name));
      final adProject = sortedProjects.first;
      final otherProject = sortedProjects.last;

      await container
          .read(projectsControllerProvider.notifier)
          .setProjectType(
            projectId: adProject.id,
            type: ProjectType.ad,
          );

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      await tester.tap(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectTypeFilter_ad')));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Selected 1 of 1 projects'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteSelectedProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Deleted 1 selected project.'),
        findsOneWidget,
      );
      expect(find.byKey(Key('projectCard_${adProject.id}')), findsNothing);
      expect(find.byKey(Key('projectCard_${otherProject.id}')), findsNothing);
      expect(find.text('No projects match current filters.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectTypeFilter_all')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('projectCard_${otherProject.id}')), findsOneWidget);
      expect(find.text('Type: Other'), findsOneWidget);
      expect(
        container
            .read(projectsControllerProvider)
            .asData!
            .value
            .any((project) => project.id == otherProject.id),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bulk project selection prunes hidden search matches before destructive actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();
      await container.read(projectsControllerProvider.notifier).createProject();

      final projects = await container.read(projectsControllerProvider.future);
      final sortedProjects = [...projects]
        ..sort((left, right) => left.name.compareTo(right.name));
      final firstProject = sortedProjects.first;
      final secondProject = sortedProjects.last;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      await tester.tap(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        secondProject.name,
      );
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Selected 1 of 1 projects'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteSelectedProjectsButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Deleted 1 selected project.'),
        findsOneWidget,
      );
      expect(find.byKey(Key('projectCard_${secondProject.id}')), findsNothing);

      await tester.tap(find.byKey(const Key('projectResetFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('projectCard_${firstProject.id}')), findsOneWidget);
      expect(find.byKey(Key('projectCard_${secondProject.id}')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bulk project selection exits when filters hide every visible project',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      await tester.tap(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectTypeFilter_ad')));
      await tester.pumpAndSettle();

      expect(find.text('Project List'), findsOneWidget);
      expect(find.byKey(const Key('newProjectFab')), findsOneWidget);
      expect(
        find.byKey(const Key('exitProjectSelectionModeButton')),
        findsNothing,
      );
      expect(find.text('No projects match current filters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bulk project selection exits when search hides every visible project',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      await tester.tap(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'missing project',
      );
      await tester.pumpAndSettle();

      expect(find.text('Project List'), findsOneWidget);
      expect(find.byKey(const Key('newProjectFab')), findsOneWidget);
      expect(
        find.byKey(const Key('exitProjectSelectionModeButton')),
        findsNothing,
      );
      expect(find.text('No projects match current filters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bulk project selection exits cleanly when type filter removes updated results',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();
      await container.read(projectsControllerProvider.notifier).createProject();

      final initialProjects = await container.read(
        projectsControllerProvider.future,
      );
      final sortedProjects = [...initialProjects]
        ..sort((left, right) => left.name.compareTo(right.name));
      final adProject = sortedProjects.first;

      await container
          .read(projectsControllerProvider.notifier)
          .setProjectType(
            projectId: adProject.id,
            type: ProjectType.ad,
          );

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      await tester.tap(find.byKey(const Key('projectTypeFilter_ad')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('setSelectedProjectsTypeButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set Type: Series').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Updated 1 selected project to type Series.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('toggleProjectSelectionModeButton')),
        findsOneWidget,
      );
      expect(find.text('Project List'), findsOneWidget);
      expect(find.text('No projects match current filters.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectTypeFilter_all')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('projectCard_${adProject.id}')), findsOneWidget);
      expect(find.text('Type: Series'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bulk project selection sets type for selected projects', (
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

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleProjectSelectionModeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Select Projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('setSelectedProjectsTypeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Type: Ad').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Updated 2 selected projects to type Ad.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('exitProjectSelectionModeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);
    expect(find.text('Ad (2)'), findsOneWidget);
  });

  testWidgets('bulk project selection duplicates selected projects', (
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

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleProjectSelectionModeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Select Projects'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectAllProjectsButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('duplicateSelectedProjectsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Duplicated 2 selected projects.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('exitProjectSelectionModeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 4 of 4 projects'), findsOneWidget);
  });

  testWidgets('project popup copy json writes clipboard and shows feedback', (
    tester,
  ) async {
    String? clipboardText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              final arguments = methodCall.arguments;
              if (arguments is Map) {
                clipboardText = arguments['text'] as String?;
              }
            }
            return null;
          });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _scrollProjectListToCards(tester);

    await _openProjectMenuForProject(tester, 'New Project 1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy JSON').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Project JSON copied to clipboard.'), findsOneWidget);
    expect(clipboardText, isNotNull);
    expect(clipboardText, contains('"name": "New Project 1"'));
  });

  testWidgets(
    'project popup download json copies fallback payload on unsupported platform',
    (tester) async {
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                final arguments = methodCall.arguments;
                if (arguments is Map) {
                  clipboardText = arguments['text'] as String?;
                }
              }
              return null;
            });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _scrollProjectListToCards(tester);

      await _openProjectMenuForProject(
        tester,
        'New Project 1',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download JSON').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text(
          'Download unavailable. Project package JSON copied to clipboard.',
        ),
        findsOneWidget,
      );
      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('"format": "project_package"'));
      expect(clipboardText, contains('"name": "New Project 1"'));
    },
  );

  testWidgets(
    'project popup download json shows error when clipboard fallback also fails',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                throw PlatformException(code: 'clipboard-unavailable');
              }
              return null;
            });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _scrollProjectListToCards(tester);

      await _openProjectMenuForProject(
        tester,
        'New Project 1',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download JSON').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text(
          'Project package export failed: download and clipboard are unavailable on this platform.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('import project json dialog adds new project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    final payload = jsonEncode({
      'id': 'import-source-id',
      'name': 'Imported Via JSON',
      'type': 'ad',
      'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'scenes': [
        {
          'id': 'scene-1',
          'title': 'Scene A',
          'styleId': 'studio_slate',
          'aspectRatio': 'portrait9x16',
          'characters': [
            {
              'id': 'char-1',
              'displayName': 'Jordan',
              'avatarPath': null,
              'bubbleColor': '#2E90FA',
            },
          ],
          'messages': [
            {
              'id': 'msg-1',
              'characterId': 'char-1',
              'text': 'Imported hello',
              'timestampSeconds': 0,
              'status': 'sent',
              'isIncoming': false,
              'showTypingBefore': false,
            },
          ],
        },
      ],
    });

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Imported Via JSON'), findsOneWidget);
    expect(find.text('Type: Ad'), findsOneWidget);
    expect(find.text('Imported project: Imported Via JSON.'), findsOneWidget);
  });

  testWidgets('import project json dialog supports batch payload', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    final payload = jsonEncode({
      'projects': [
        {
          'id': 'batch-import-1',
          'name': 'Batch Import 1',
          'type': 'other',
          'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
          'scenes': [
            {
              'id': 'batch-scene-1',
              'title': 'Scene Batch 1',
              'styleId': 'studio_slate',
              'aspectRatio': 'portrait9x16',
              'characters': [
                {
                  'id': 'batch-char-1',
                  'displayName': 'Taylor',
                  'avatarPath': null,
                  'bubbleColor': '#2E90FA',
                },
              ],
              'messages': <Object>[],
            },
          ],
        },
        {
          'id': 'batch-import-2',
          'name': 'Batch Import 2',
          'type': 'series',
          'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
          'scenes': [
            {
              'id': 'batch-scene-2',
              'title': 'Scene Batch 2',
              'styleId': 'studio_slate',
              'aspectRatio': 'portrait9x16',
              'characters': [
                {
                  'id': 'batch-char-2',
                  'displayName': 'Jordan',
                  'avatarPath': null,
                  'bubbleColor': '#12B76A',
                },
              ],
              'messages': <Object>[],
            },
          ],
        },
        {'invalid': true},
      ],
    });

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);
    expect(
      find.text('Imported 2 projects and skipped 1 invalid entry.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'import project json preview lists projected projects and skipped invalid entries',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      final payload = jsonEncode({
        'projects': [
          for (var index = 1; index <= 6; index++)
            {
              'id': 'preview-import-$index',
              'name': 'Preview Import $index',
              'type': index.isEven ? 'series' : 'other',
              'createdAt': DateTime.utc(2026, 1, index).toIso8601String(),
              'updatedAt': DateTime.utc(2026, 1, index).toIso8601String(),
              'scenes': [
                {
                  'id': 'preview-scene-$index',
                  'title': 'Preview Scene $index',
                  'styleId': 'studio_slate',
                  'aspectRatio': 'portrait9x16',
                  'characters': [
                    {
                      'id': 'preview-char-$index',
                      'displayName': 'Taylor $index',
                      'avatarPath': null,
                      'bubbleColor': '#2E90FA',
                    },
                  ],
                  'messages': <Object>[],
                },
              ],
            },
          {'invalid': true},
          {'alsoInvalid': true},
        ],
      });

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        payload,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Import 6 projects?'), findsOneWidget);
      expect(find.text('Projects that will be imported:'), findsOneWidget);
      for (var index = 1; index <= 5; index++) {
        expect(find.text('• Preview Import $index'), findsOneWidget);
      }
      expect(find.text('• Preview Import 6'), findsNothing);
      expect(find.text('• +1 more'), findsOneWidget);
      expect(find.text('Invalid entries to skip: 2'), findsOneWidget);
      expect(
        find.byKey(const Key('confirmImportFromJsonButton')),
        findsOneWidget,
      );
    },
  );

  testWidgets('import project json preview cancel keeps projects unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    final payload = jsonEncode({
      'id': 'cancel-import-project',
      'name': 'Cancelled Import Project',
      'type': 'other',
      'createdAt': DateTime.utc(2026, 1, 4).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 4).toIso8601String(),
      'scenes': [
        {
          'id': 'cancel-scene-1',
          'title': 'Cancelled Scene',
          'styleId': 'studio_slate',
          'aspectRatio': 'portrait9x16',
          'characters': [
            {
              'id': 'cancel-char-1',
              'displayName': 'Casey',
              'avatarPath': null,
              'bubbleColor': '#12B76A',
            },
          ],
          'messages': <Object>[],
        },
      ],
    });

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Import 1 project?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelled Import Project'), findsNothing);
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('import project json shows validation for malformed json', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      '{broken',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('Invalid JSON format. Please paste valid JSON.'),
      findsOneWidget,
    );
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets(
    'import json file button shows fallback when no file is selected',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('importProjectJsonFileButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No JSON file selected.'), findsOneWidget);
    },
  );

  testWidgets(
    'import json file button imports project from picker payload',
    (
      tester,
    ) async {
      final payload = jsonEncode({
        'id': 'import-file-source-id',
        'name': 'Imported From File',
        'type': 'series',
        'createdAt': DateTime.utc(2026, 1, 3).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 3).toIso8601String(),
        'scenes': [
          {
            'id': 'scene-file-1',
            'title': 'Scene File',
            'styleId': 'studio_slate',
            'aspectRatio': 'portrait9x16',
            'characters': [
              {
                'id': 'char-file-1',
                'displayName': 'Casey',
                'avatarPath': null,
                'bubbleColor': '#12B76A',
              },
            ],
            'messages': [
              {
                'id': 'msg-file-1',
                'characterId': 'char-file-1',
                'text': 'Loaded from file picker',
                'timestampSeconds': 1,
                'status': 'delivered',
                'isIncoming': true,
                'showTypingBefore': true,
              },
            ],
          },
        ],
      });
      Future<String?> picker({
        String accept = '.json,application/json',
      }) async {
        return payload;
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectJsonFilePickerProvider.overrideWithValue(picker),
          ],
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('importProjectJsonFileButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Imported From File'), findsOneWidget);
      expect(find.text('Type: Series'), findsOneWidget);
      expect(
        find.text('Imported project: Imported From File.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('rename project from popup menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _scrollProjectListToCards(tester);

    expect(find.text('New Project 1'), findsOneWidget);

    await _openProjectMenuForProject(tester, 'New Project 1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename').last);
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

  testWidgets('rename project dialog rejects blank names', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _scrollProjectListToCards(tester);
    await _openProjectMenuForProject(tester, 'New Project 1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    final nameField = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(TextField, 'Project Name'),
    );
    await tester.enterText(nameField, '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Project name cannot be empty.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('New Project 1'), findsOneWidget);
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

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectSearchField')), '2');
    await tester.pumpAndSettle();

    expect(find.text('Showing 1 of 2 projects'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('projectSearchField')),
      'not-found',
    );
    await tester.pumpAndSettle();

    expect(find.text('No projects match current filters.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectSearchField')), '');
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);
  });

  testWidgets(
    'project list search also matches scene titles and character names',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container.read(projectsControllerProvider.notifier).createProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'prep chat',
      );
      await tester.pumpAndSettle();

      expect(find.text('Showing 1 of 2 projects'), findsOneWidget);
      expect(find.text('No projects match current filters.'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'alex',
      );
      await tester.pumpAndSettle();

      expect(find.text('Showing 1 of 2 projects'), findsOneWidget);
      expect(find.text('No projects match current filters.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

    await _scrollProjectListToCards(tester);

    expect(find.text('Type: Other'), findsOneWidget);
    expect(find.text('Ad (0)', skipOffstage: false), findsOneWidget);

    await _openProjectMenuForProject(tester, 'New Project 1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Type: Ad').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Type: Ad'), findsOneWidget);
    expect(find.text('Ad (1)', skipOffstage: false), findsOneWidget);
    expect(find.text('Other (0)', skipOffstage: false), findsOneWidget);
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

    expect(find.text('Name (Z-A)'), findsOneWidget);
    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);

    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (A-Z)').last);
    await tester.pumpAndSettle();

    expect(find.text('Name (A-Z)'), findsOneWidget);
    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);
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

    await _scrollProjectListToCards(tester);

    final sortDropdown = find.byKey(
      const Key('projectSortDropdown'),
      skipOffstage: false,
    );
    await tester.ensureVisible(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Updated (Oldest)').last);
    await tester.pumpAndSettle();

    final orderedProjectTitles = find
        .byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data == 'New Project 1' ||
                  widget.data == 'New Project 2'),
          skipOffstage: false,
        )
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .toList();

    expect(
      orderedProjectTitles,
      containsAllInOrder(const ['New Project 1', 'New Project 2']),
    );
  });

  testWidgets('compact project list app bar uses overflow menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProjectListScreen(forceCompactAppBar: true)),
      ),
    );
    await _ensureOnProjectList(tester);

    expect(
      find.byKey(const Key('projectListOverflowMenuButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('toggleProjectSelectionModeButton')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Demo Project'));
    await tester.pumpAndSettle();

    expect(find.text('Demo Project 1'), findsOneWidget);
  });

  testWidgets('project list switches to compact app bar at larger text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(760, 844),
              textScaler: TextScaler.linear(1.2),
            ),
            child: ProjectListScreen(),
          ),
        ),
      ),
    );
    await _ensureOnProjectList(tester);

    expect(
      find.byKey(const Key('projectListOverflowMenuButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('toggleProjectSelectionModeButton')),
      findsNothing,
    );
  });

  testWidgets('project list treats short landscape viewports as compact', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(844, 390)),
            child: ProjectListScreen(),
          ),
        ),
      ),
    );
    await _ensureOnProjectList(tester);

    expect(
      find.byKey(const Key('projectListOverflowMenuButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('toggleProjectSelectionModeButton')),
      findsNothing,
    );
  });

  testWidgets('compact project list overflow can load export QA project', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportQaFixtureLoaderProvider.overrideWithValue(
            () async => _exportQaFixtureJson,
          ),
        ],
        child: const MaterialApp(
          home: ProjectListScreen(forceCompactAppBar: true),
        ),
      ),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load Export QA Project').last);
    await tester.pumpAndSettle();

    expect(find.text('Export QA Project'), findsOneWidget);
  });

  testWidgets(
    'compact project list overflow does not duplicate export QA project',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportQaFixtureLoaderProvider.overrideWithValue(
              () async => _exportQaFixtureJson,
            ),
          ],
          child: const MaterialApp(
            home: ProjectListScreen(forceCompactAppBar: true),
          ),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load Export QA Project').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load Export QA Project').last);
      await tester.pumpAndSettle();

      expect(find.text('Export QA Project'), findsOneWidget);
      expect(find.textContaining('(Imported)'), findsNothing);
      expect(find.text('Export QA Project is already loaded.'), findsOneWidget);
    },
  );

  testWidgets('compact selection app bar uses overflow menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProjectListScreen(forceCompactAppBar: true)),
      ),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('emptyCreateProjectButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select Projects'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('projectSelectionOverflowMenuButton')),
      findsOneWidget,
    );

    final visibleCheckbox = find.byType(Checkbox).last;
    await tester.ensureVisible(visibleCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(visibleCheckbox);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('projectSelectionOverflowMenuButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Selection'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('projectSelectionOverflowMenuButton')),
      findsOneWidget,
    );
    expect(find.text('Select Projects'), findsOneWidget);
  });

  testWidgets(
    'compact chat editor app bar uses overflow navigation actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('chatEditorOverflowMenuButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('chatEditorAppBarOpenPlaybackButton')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('chatEditorOverflowMenuButton')));
      await tester.pumpAndSettle();

      expect(find.text('Open Playback'), findsOneWidget);
      expect(find.text('Back to Projects'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact playback app bar uses overflow navigation actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('playbackOverflowMenuButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('playbackAppBarOpenEditorButton')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('playbackOverflowMenuButton')));
      await tester.pumpAndSettle();

      expect(find.text('Open Chat Editor'), findsOneWidget);
      expect(find.text('Back to Projects'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short landscape playback uses compact overflow navigation actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(844, 390),
        child: PlaybackScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('playbackOverflowMenuButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('playbackAppBarOpenEditorButton')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'playback app bar disables open editor when the project is missing',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlaybackScreen(projectId: 'missing-project'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project not found.'), findsOneWidget);

      final openEditorButton = tester.widget<IconButton>(
        find.byKey(const Key('playbackAppBarOpenEditorButton')),
      );
      expect(openEditorButton.onPressed, isNull);
    },
  );

  testWidgets(
    'compact playback overflow disables open editor when the project is missing',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const PlaybackScreen(projectId: 'missing-project'),
      );

      expect(find.text('Project not found.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('playbackOverflowMenuButton')));
      await tester.pumpAndSettle();

      expect(find.text('Open Chat Editor'), findsOneWidget);

      await tester.tap(find.text('Open Chat Editor'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(PlaybackScreen), findsOneWidget);
      expect(find.text('Project not found.'), findsOneWidget);
      expect(find.text('Open Chat Editor'), findsOneWidget);
    },
  );

  testWidgets('compact import project dialog stays usable on narrow screens', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: const ProjectListScreen(forceCompactAppBar: true),
    );

    final payload = jsonEncode({
      'id': 'compact-import-project',
      'name': 'Compact Import Project',
      'type': 'series',
      'createdAt': DateTime.utc(2026, 4, 30).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 4, 30).toIso8601String(),
      'scenes': [
        {
          'id': 'compact-scene-1',
          'title': 'Compact Scene',
          'styleId': 'studio_slate',
          'aspectRatio': 'portrait9x16',
          'characters': [
            {
              'id': 'compact-char-1',
              'displayName': 'Taylor',
              'avatarPath': null,
              'bubbleColor': '#2E90FA',
            },
          ],
          'messages': [
            {
              'id': 'compact-message-1',
              'characterId': 'compact-char-1',
              'text': 'Compact dialog import',
              'timestampSeconds': 2,
              'isIncoming': true,
              'status': 'sent',
              'showTypingBefore': false,
            },
          ],
        },
      ],
    });

    await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Project JSON'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('confirmImportFromJsonButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Compact Import Project'), findsOneWidget);
  });

  testWidgets(
    'compact project list search, filters, and sort controls stay usable on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildAttentionProjectImportPayload());

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Showing 2 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'prep chat',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('No projects match current filters.'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'taylor',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('No projects match current filters.'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('projectSearchField')),
        'Compact Attention Project',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('No projects match current filters.'), findsNothing);

      await tester.enterText(find.byKey(const Key('projectSearchField')), '');
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 2 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );

      final compactTypeFilter = find.descendant(
        of: find.byKey(const Key('projectTypeFilterDropdown')),
        matching: find.byType(DropdownButtonFormField<ProjectType?>),
      );
      expect(compactTypeFilter, findsOneWidget);
      expect(find.byKey(const Key('projectTypeFilter_ad')), findsNothing);

      final compactReadinessFilter = find.descendant(
        of: find.byKey(const Key('projectReadinessFilterDropdown')),
        matching: find.byType(DropdownButtonFormField<ProjectReadinessState?>),
      );
      expect(compactReadinessFilter, findsOneWidget);
      expect(
        find.byKey(const Key('projectReadinessFilter_ready')),
        findsNothing,
      );

      await tester.tap(compactReadinessFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Needs Attention (1)').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('No projects match current filters.'), findsNothing);

      await tester.tap(find.byKey(const Key('projectResetFiltersButton')));
      await tester.pumpAndSettle();

      await tester.tap(compactTypeFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ad (1)').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('No projects match current filters.'), findsNothing);

      final sortDropdown = find.byKey(const Key('projectSortDropdown'));
      await tester.ensureVisible(sortDropdown);
      await tester.pumpAndSettle();
      await tester.tap(sortDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Updated (Oldest)').last);
      await tester.pumpAndSettle();

      expect(find.text('Updated (Oldest)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectResetFiltersButton')));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byKey(
        const Key('projectSearchField'),
        skipOffstage: false,
      );
      await tester.ensureVisible(searchFieldFinder);
      await tester.pumpAndSettle();

      final searchField = tester.widget<TextField>(searchFieldFinder);
      expect(searchField.controller!.text, isEmpty);
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('All statuses (2)'), findsOneWidget);
      expect(find.text('Updated (Newest)'), findsOneWidget);
      expect(
        find.text('Showing 2 of 2 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ultra-compact project list uses one scroll and keeps lower cards reachable',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      for (var index = 0; index < 4; index += 1) {
        await container
            .read(projectsControllerProvider.notifier)
            .createProject();
      }

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      expect(find.byKey(const Key('projectListScrollView')), findsOneWidget);
      expect(find.byKey(const Key('projectCardsListView')), findsNothing);
      expect(find.text('Portfolio Readiness'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('projectListScrollView')),
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Project 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact selection overflow keeps bulk actions reachable on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();
      await container.read(projectsControllerProvider.notifier).createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      await tester.tap(find.byKey(const Key('projectListOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select Projects'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('projectSelectionOverflowMenuButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select All Projects'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('projectSelectionOverflowMenuButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Selected Projects JSON'), findsOneWidget);

      await tester.tap(find.text('Set Type: Series'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Updated 2 selected projects to type Series.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('exitProjectSelectionModeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Type: Series'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact portfolio readiness stacks summary actions on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildAttentionProjectImportPayload());
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      final continueButton = find.byKey(
        const Key('portfolioContinueEditingButton'),
      );
      final previewButton = find.byKey(
        const Key('portfolioPreviewReadyButton'),
      );
      final reviewButton = find.byKey(
        const Key('portfolioReviewAttentionButton'),
      );
      final timelineQaButton = find.byKey(
        const Key('portfolioReviewTimelineQaButton'),
      );

      await tester.ensureVisible(timelineQaButton);
      await tester.pumpAndSettle();

      final continuePosition = tester.getTopLeft(continueButton);
      final previewPosition = tester.getTopLeft(previewButton);
      final reviewPosition = tester.getTopLeft(reviewButton);
      final timelineQaPosition = tester.getTopLeft(timelineQaButton);
      final continueSize = tester.getSize(continueButton);
      final previewSize = tester.getSize(previewButton);
      final reviewSize = tester.getSize(reviewButton);
      final timelineQaSize = tester.getSize(timelineQaButton);

      expect(previewPosition.dy, greaterThan(continuePosition.dy));
      expect(reviewPosition.dy, greaterThan(previewPosition.dy));
      expect(timelineQaPosition.dy, greaterThan(reviewPosition.dy));
      expect(previewPosition.dx, closeTo(continuePosition.dx, 1));
      expect(reviewPosition.dx, closeTo(previewPosition.dx, 1));
      expect(timelineQaPosition.dx, closeTo(reviewPosition.dx, 1));
      expect(previewSize.width, closeTo(continueSize.width, 1));
      expect(reviewSize.width, closeTo(previewSize.width, 1));
      expect(timelineQaSize.width, closeTo(reviewSize.width, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact portfolio readiness attention action opens editor on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildAttentionProjectImportPayload());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final reviewButton = find.byKey(
        const Key('portfolioReviewAttentionButton'),
      );
      await tester.ensureVisible(reviewButton);
      await tester.pumpAndSettle();
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
    },
  );

  testWidgets(
    'compact portfolio preview ready action opens playback on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final previewButton = find.byKey(
        const Key('portfolioPreviewReadyButton'),
      );
      await tester.ensureVisible(previewButton);
      await tester.pumpAndSettle();
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
      expect(find.text('Messages: 4'), findsOneWidget);
    },
  );

  testWidgets(
    'compact portfolio continue editing focuses first empty scene for attention projects',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(
            _buildMixedReadinessProjectImportPayload(
              projectName: 'Compact Portfolio Attention Project',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final continueEditingButton = find.byKey(
        const Key('portfolioContinueEditingButton'),
      );
      await tester.ensureVisible(continueEditingButton);
      await tester.pumpAndSettle();
      await tester.tap(continueEditingButton);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Compact Portfolio Attention Project'), findsOneWidget);
      expect(find.textContaining('Scene: Empty Scene'), findsOneWidget);
      expect(
        find.textContaining('Scene summary: 1 characters • 0 messages'),
        findsOneWidget,
      );
    },
  );

  testWidgets('compact playback hides keyboard shortcut hint', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PlaybackScreen(projectId: 'project_1')),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();

    expect(
      find.text('Keyboard: Space play/pause • ←/→ seek • R restart'),
      findsNothing,
    );
  });

  testWidgets('compact chat editor keeps scene actions in overflow menu', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final projectId = await _createStarterProjectInContainer(container);

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: ChatEditorScreen(
        projectId: projectId,
        forceCompactLayout: true,
      ),
    );

    expect(find.byKey(const Key('compactAddSceneButton')), findsOneWidget);
    expect(
      find.byKey(const Key('sceneActionsOverflowMenuButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('sceneActionsOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate Scene'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene 1 Copy'), findsOneWidget);
    expect(find.text('Scenes: 2'), findsOneWidget);
  });

  testWidgets(
    'short landscape chat editor uses compact scene actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(844, 390),
        child: ChatEditorScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('chatEditorOverflowMenuButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('chatEditorAppBarOpenPlaybackButton')),
        findsNothing,
      );
      expect(find.byKey(const Key('compactAddSceneButton')), findsOneWidget);
      expect(
        find.byKey(const Key('sceneActionsOverflowMenuButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact chat editor scene selector shows current scene context on narrow screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      expect(
        find.byKey(const Key('compactEditorSceneDropdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('compactEditorSceneSummary')),
        findsOneWidget,
      );
      expect(
        find.text('Scene 1 of 2 • 4 messages • 11s max'),
        findsOneWidget,
      );
      expect(find.textContaining('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      await tester.tap(find.byKey(const Key('compactEditorSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Scene 2 of 2 • 3 messages • 8s max'),
        findsOneWidget,
      );
      expect(find.textContaining('Scene: Scene 2 - Rolling'), findsOneWidget);
    },
  );

  testWidgets(
    'wide chat editor scene selector switches demo scenes with desktop controls intact',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(960, 900),
        child: ChatEditorScreen(projectId: projectId),
      );

      expect(find.byKey(const Key('editorSceneDropdown')), findsOneWidget);
      expect(
        find.byKey(const Key('compactEditorSceneDropdown')),
        findsNothing,
      );
      expect(find.byKey(const Key('duplicateSceneButton')), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editorSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        find.textContaining(
          'Scene summary: 2 characters • 3 messages • max 8s',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('duplicateSceneButton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide chat editor scene selector stays synced after external scene changes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;
      final projectId = project.id;
      final secondSceneId = project.scenes[1].id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(960, 900),
        child: ChatEditorScreen(projectId: projectId),
      );

      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
      expect(
        _dropdownFieldValue(tester, const Key('editorSceneDropdown')),
        project.scenes.first.id,
      );

      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          secondSceneId;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        _dropdownFieldValue(tester, const Key('editorSceneDropdown')),
        secondSceneId,
      );
    },
  );

  testWidgets(
    'chat editor open playback action keeps the currently selected scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);
      await _openChatEditorFromProjectList(
        tester,
        projectName: 'Demo Project 1',
      );

      await tester.tap(find.byKey(const Key('editorSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('chatEditorAppBarOpenPlaybackButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(find.text('Messages: 3'), findsOneWidget);
    },
  );

  testWidgets(
    'chat editor app bar playback action normalizes stale deep-link scene ids',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final project = (await container.read(
        projectsControllerProvider.future,
      )).singleWhere((candidate) => candidate.id == projectId);
      final primarySceneId = project.scenes.first.id;
      String? playbackSceneId;

      final router = GoRouter(
        initialLocation: '/editor/$projectId?sceneId=missing-scene',
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
            builder: (context, state) {
              playbackSceneId = state.uri.queryParameters['sceneId'];
              return const Scaffold(body: Text('Playback Stub'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('chatEditorAppBarOpenPlaybackButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Playback Stub'), findsOneWidget);
      expect(playbackSceneId, primarySceneId);
    },
  );

  testWidgets(
    'compact editor overflow playback action normalizes stale deep-link scene ids',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final project = (await container.read(
        projectsControllerProvider.future,
      )).singleWhere((candidate) => candidate.id == projectId);
      final primarySceneId = project.scenes.first.id;
      String? playbackSceneId;

      final router = GoRouter(
        initialLocation: '/editor/$projectId?sceneId=missing-scene',
        routes: [
          GoRoute(
            path: '/editor/:projectId',
            name: 'editorProject',
            builder: (context, state) => MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: ChatEditorScreen(
                projectId: state.pathParameters['projectId'],
                initialSceneId: state.uri.queryParameters['sceneId'],
                forceCompactLayout: true,
              ),
            ),
          ),
          GoRoute(
            path: '/playback/:projectId',
            name: 'playbackProject',
            builder: (context, state) {
              playbackSceneId = state.uri.queryParameters['sceneId'];
              return const Scaffold(body: Text('Playback Stub'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chatEditorOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Playback').last);
      await tester.pumpAndSettle();

      expect(find.text('Playback Stub'), findsOneWidget);
      expect(playbackSceneId, primarySceneId);
    },
  );

  testWidgets('compact scene settings dialog stays usable on narrow screens', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final projectId = await _createStarterProjectInContainer(container);

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: ChatEditorScreen(
        projectId: projectId,
        forceCompactLayout: true,
      ),
    );

    await tester.tap(find.byKey(const Key('sceneActionsOverflowMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Scene Settings'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final dialogFinder = find.byType(AlertDialog);
    final presetDropdown = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(InputDecorator, 'Style Preset'),
    );
    await tester.tap(presetDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warm Paper (warm_paper)').last);
    await tester.pumpAndSettle();

    final aspectRatioDropdown = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(InputDecorator, 'Aspect Ratio'),
    );
    await tester.tap(aspectRatioDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('landscape16x9').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Style: Warm Paper • Aspect: 16:9'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact scene settings keep manual style entry preview in sync',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      await tester.tap(find.byKey(const Key('sceneActionsOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Scene Settings'));
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(AlertDialog);
      final styleIdField = find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Style ID'),
      );
      await tester.enterText(styleIdField, 'night_shift');
      await tester.pump();

      expect(
        find.descendant(of: dialogFinder, matching: find.text('Night Shift')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Night Shift (night_shift)'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: dialogFinder, matching: find.text('Save')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Style: Night Shift • Aspect: 9:16'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'compact scene settings keep legacy style aliases in sync',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      await tester.tap(find.byKey(const Key('sceneActionsOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Scene Settings'));
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(AlertDialog);
      final styleIdField = find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Style ID'),
      );
      await tester.enterText(styleIdField, 'studio_slate');
      await tester.pump();

      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Studio Default'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Studio Default (studio_default)'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: dialogFinder, matching: find.text('Save')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Style: Studio Default • Aspect: 9:16'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'compact chat editor bulk message delete keeps stacked actions usable',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final toggleSelectionButton = find.byKey(
        const Key('toggleMessageSelectionModeButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        toggleSelectionButton,
      );
      await tester.tap(toggleSelectionButton);
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

      expect(find.text('Delete (2)'), findsOneWidget);

      final deleteSelectedButton = find.byKey(
        const Key('deleteSelectedMessagesButton'),
      );
      await tester.ensureVisible(deleteSelectedButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteSelectedButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('confirmDeleteSelectedMessagesButton')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Deleted 2 selected messages.'),
        findsOneWidget,
      );
      expect(find.text('Ready for set in 10?'), findsNothing);
      expect(find.text('Yes, prop phone is prepared.'), findsNothing);
    },
  );

  testWidgets(
    'ultra-compact chat editor stacks bulk actions vertically on phone-width screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final toggleSelectionButton = find.byKey(
        const Key('toggleMessageSelectionModeButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        toggleSelectionButton,
      );
      await tester.tap(toggleSelectionButton);
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(Checkbox).at(0);
      await tester.ensureVisible(firstCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final clearButton = find.byKey(const Key('clearSceneMessagesButton'));
      final deleteButton = find.byKey(
        const Key('deleteSelectedMessagesButton'),
      );
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();

      final selectionPosition = tester.getTopLeft(toggleSelectionButton);
      final clearPosition = tester.getTopLeft(clearButton);
      final deletePosition = tester.getTopLeft(deleteButton);
      final clearSize = tester.getSize(clearButton);
      final deleteSize = tester.getSize(deleteButton);

      expect(clearPosition.dy, greaterThan(selectionPosition.dy));
      expect(deletePosition.dy, greaterThan(clearPosition.dy));
      expect(deletePosition.dx, closeTo(clearPosition.dx, 1));
      expect(deleteSize.width, closeTo(clearSize.width, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ultra-compact chat editor footer actions stack on phone-width screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final openPlaybackButton = find.byKey(
        const Key('chatEditorOpenPlaybackButton'),
      );
      final backButton = find.byKey(
        const Key('chatEditorBackToProjectsButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, openPlaybackButton);
      await _ensureFinderVisibleInPrimaryListView(tester, backButton);

      final openPlaybackPosition = tester.getTopLeft(openPlaybackButton);
      final backPosition = tester.getTopLeft(backButton);
      final openPlaybackSize = tester.getSize(openPlaybackButton);
      final backSize = tester.getSize(backButton);

      expect(backPosition.dy, greaterThan(openPlaybackPosition.dy));
      expect(backPosition.dx, closeTo(openPlaybackPosition.dx, 1));
      expect(backSize.width, closeTo(openPlaybackSize.width, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ultra-compact chat editor composer stays usable on phone-width screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final statusDropdown = find.byKey(const Key('messageStatusDropdown'));
      await _ensureFinderVisibleInPrimaryListView(tester, statusDropdown);
      expect(statusDropdown, findsOneWidget);

      final addCharacterButton = find.widgetWithText(
        FilledButton,
        'Add Character',
      );
      await _ensureFinderVisibleInPrimaryListView(tester, addCharacterButton);
      expect(addCharacterButton, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact character manager keeps actions usable through overflow menu',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);
      final snapshot = container.read(sceneSnapshotProvider(projectId)).value!;
      final scene = snapshot.scene!;
      final alex = scene.characters.first;
      await container
          .read(projectsControllerProvider.notifier)
          .addCharacter(
            projectId: projectId,
            sceneId: scene.id,
            displayName: 'Blair',
          );

      final sceneAfterCharacterAdd = container
          .read(sceneSnapshotProvider(projectId))
          .value!
          .scene!;
      final blair = sceneAfterCharacterAdd.characters.last;
      await container
          .read(projectsControllerProvider.notifier)
          .addMessage(
            projectId: projectId,
            sceneId: scene.id,
            characterId: blair.id,
            text: 'I am covering the mobile pass.',
            timestampSeconds: 4,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          );
      await container
          .read(projectsControllerProvider.notifier)
          .addMessage(
            projectId: projectId,
            sceneId: scene.id,
            characterId: blair.id,
            text: 'And I have one more line to clear.',
            timestampSeconds: 6,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: false,
          );

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      final alexMenuButton = find.byKey(
        Key('characterActionsOverflowMenu_${alex.id}'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, alexMenuButton);
      expect(find.widgetWithText(OutlinedButton, 'Rename'), findsNothing);

      await tester.tap(alexMenuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename ${alex.displayName}'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Character Name'),
        'Alex Prime',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Alex Prime'), findsWidgets);

      final renamedSnapshot = container
          .read(sceneSnapshotProvider(projectId))
          .value!
          .scene!;
      final renamedAlex = renamedSnapshot.characters.firstWhere(
        (character) => character.id == alex.id,
      );
      final renamedAlexMenuButton = find.byKey(
        Key('characterActionsOverflowMenu_${renamedAlex.id}'),
      );

      await _ensureFinderVisibleInPrimaryListView(
        tester,
        renamedAlexMenuButton,
      );
      await tester.tap(renamedAlexMenuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Avatar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Avatar URL or path'),
        _testAvatarDataUri,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final avatarUpdatedSnapshot = container
          .read(sceneSnapshotProvider(projectId))
          .value!
          .scene!;
      final avatarUpdatedAlex = avatarUpdatedSnapshot.characters.firstWhere(
        (character) => character.id == alex.id,
      );
      expect(avatarUpdatedAlex.avatarPath, _testAvatarDataUri);
      expect(
        find.textContaining('Avatar: data:image/png;base64,'),
        findsOneWidget,
      );

      await tester.tap(renamedAlexMenuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bubble Color:'));
      await tester.pumpAndSettle();
      final roseColorOption = find.byKey(
        Key('characterBubbleColorOption_${renamedAlex.id}_#F0447C'),
      );
      await tester.ensureVisible(roseColorOption);
      await tester.pumpAndSettle();
      await tester.tap(roseColorOption);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final updatedSnapshot = container
          .read(sceneSnapshotProvider(projectId))
          .value!;
      final updatedAlex = updatedSnapshot.scene!.characters.firstWhere(
        (character) => character.id == alex.id,
      );
      expect(updatedAlex.displayName, 'Alex Prime');
      expect(updatedAlex.avatarPath, _testAvatarDataUri);
      expect(updatedAlex.bubbleColor, '#F0447C');

      final blairMenuButton = find.byKey(
        Key('characterActionsOverflowMenu_${blair.id}'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, blairMenuButton);
      await tester.tap(blairMenuButton);
      await tester.pumpAndSettle();
      expect(find.text('Rename Alex Prime'), findsNothing);
      expect(find.text('Bubble Color: Rose'), findsNothing);
      expect(find.text('Remove Character'), findsOneWidget);
      await tester.tap(find.text('Remove Character'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Character'), findsOneWidget);
      expect(
        find.text(
          'Remove Blair from this scene? This also deletes 2 messages assigned to them.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirmDeleteCharacterButton')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('confirmDeleteCharacterButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Removed Blair and deleted 2 messages.'),
        findsOneWidget,
      );
      expect(find.text('Blair'), findsNothing);
      expect(find.text('I am covering the mobile pass.'), findsNothing);
      expect(find.text('And I have one more line to clear.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('character avatar dialog can pick an image file', (tester) async {
    Future<String?> picker({
      String accept = 'image/png,image/jpeg,image/webp,image/gif',
    }) async {
      return _testAvatarDataUri;
    }

    final container = ProviderContainer(
      overrides: [
        characterAvatarFilePickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);

    final projectId = await _createStarterProjectInContainer(container);
    final scene = container
        .read(sceneSnapshotProvider(projectId))
        .value!
        .scene!;
    final alex = scene.characters.first;

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      size: const Size(1200, 900),
      child: ChatEditorScreen(projectId: projectId),
    );

    final editAvatarButton = find.byKey(Key('editCharacterAvatar_${alex.id}'));
    await _ensureFinderVisibleInPrimaryListView(tester, editAvatarButton);
    await tester.tap(editAvatarButton);
    await tester.pumpAndSettle();

    final pickButton = find.byKey(
      Key('pickCharacterAvatarFileButton_${alex.id}'),
    );
    expect(pickButton, findsOneWidget);

    await tester.tap(pickButton);
    await tester.pumpAndSettle();

    final avatarField = tester.widget<TextField>(
      find.byKey(Key('characterAvatarField_${alex.id}')),
    );
    expect(avatarField.controller!.text, _testAvatarDataUri);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final updatedSnapshot = container
        .read(sceneSnapshotProvider(projectId))
        .value!
        .scene!;
    final updatedAlex = updatedSnapshot.characters.firstWhere(
      (character) => character.id == alex.id,
    );

    expect(updatedAlex.avatarPath, _testAvatarDataUri);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'character avatar dialog shows feedback for oversized image files',
    (
      tester,
    ) async {
      Future<String?> picker({
        String accept = 'image/png,image/jpeg,image/webp,image/gif',
      }) async {
        throw const FilePickerSizeException(
          maxBytes: kEmbeddedImageFileSizeLimitBytes,
          actualBytes: kEmbeddedImageFileSizeLimitBytes + 1,
        );
      }

      final container = ProviderContainer(
        overrides: [
          characterAvatarFilePickerProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);

      final projectId = await _createStarterProjectInContainer(container);
      final scene = container
          .read(sceneSnapshotProvider(projectId))
          .value!
          .scene!;
      final alex = scene.characters.first;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(1200, 900),
        child: ChatEditorScreen(projectId: projectId),
      );

      final editAvatarButton = find.byKey(
        Key('editCharacterAvatar_${alex.id}'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, editAvatarButton);
      await tester.tap(editAvatarButton);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(Key('pickCharacterAvatarFileButton_${alex.id}')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Selected image is too large. Keep embedded avatars under 2 MB.',
        ),
        findsOneWidget,
      );

      final avatarField = tester.widget<TextField>(
        find.byKey(Key('characterAvatarField_${alex.id}')),
      );
      expect(avatarField.controller!.text, isEmpty);
      expect(
        find.widgetWithText(OutlinedButton, 'Choose Image File'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact playback export and transport controls remain usable', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        screenshotExportServiceProvider.overrideWithValue(
          _FakeScreenshotExportService(
            const ScreenshotExportResult.success(
              filename: 'compact_capture.png',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final projectId = await _createStarterProjectInContainer(container);

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: PlaybackScreen(projectId: projectId),
    );

    expect(
      find.text('Keyboard: Space play/pause • ←/→ seek • R restart'),
      findsNothing,
    );
    expect(find.byKey(const Key('videoExportWorkflowHint')), findsOneWidget);
    expect(
      find.textContaining('documented .json handoff package'),
      findsOneWidget,
    );

    final exportScreenshotButton = find.byKey(
      const Key('exportScreenshotButton'),
    );
    expect(exportScreenshotButton, findsOneWidget);
    await tester.ensureVisible(exportScreenshotButton);
    await tester.pumpAndSettle();
    await tester.tap(exportScreenshotButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Export: Screenshot OK'), findsOneWidget);
    expect(
      find.text('Screenshot exported as compact_capture.png.'),
      findsOneWidget,
    );

    final plusOneButton = find.byKey(const Key('seekForward1Button'));
    await _ensureFinderVisibleInPrimaryListView(tester, plusOneButton);
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=1s / 9 s', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('character avatar renders embedded image data safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CharacterAvatar(
              displayName: '🤖 Robot',
              bubbleColor: '#2E90FA',
              avatarPath: _testAvatarDataUri,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CharacterAvatar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ultra-compact playback actions stay usable on phone-width screens',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          screenshotExportServiceProvider.overrideWithValue(
            _FakeScreenshotExportService(
              const ScreenshotExportResult.success(
                filename: 'ultra_compact_capture.png',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: PlaybackScreen(projectId: projectId),
      );

      expect(tester.takeException(), isNull);

      final playButton = find.byKey(const Key('playButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, playButton);
      expect(find.byKey(const Key('pauseButton')), findsNothing);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('playButton')), findsNothing);
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('pauseButton')),
      );

      final restartButton = find.byKey(const Key('restartButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, restartButton);
      await tester.tap(restartButton);
      await tester.pumpAndSettle();

      final plusFiveButton = find.byKey(const Key('seekForward5Button'));
      await _ensureFinderVisibleInPrimaryListView(tester, plusFiveButton);
      await tester.tap(plusFiveButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('t=5s / 9 s', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact playback scene selector switches demo scenes and resets progress',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('compactPlaybackSceneDropdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('compactPlaybackSceneSummary')),
        findsOneWidget,
      );
      expect(find.text('Scene 1 of 2 • 4 messages • 11s max'), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      container
          .read(playbackControllerProvider(projectId).notifier)
          .seekBy(delta: 5, maxSecond: 11);
      await tester.pumpAndSettle();

      final playbackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(playbackState.currentSecond, 5);

      await tester.tap(find.byKey(const Key('compactPlaybackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(find.text('Scene 2 of 2 • 3 messages • 8s max'), findsOneWidget);
      expect(
        find.textContaining('Scene ratio: 16:9', skipOffstage: false),
        findsOneWidget,
      );
      final switchedPlaybackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(switchedPlaybackState.currentSecond, 0);
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackStatusSummary')),
      );
      final switchedStatusSummary = tester.widget<Text>(
        find.byKey(const Key('playbackStatusSummary')),
      );
      expect(switchedStatusSummary.data, contains('t=0s / 8 s'));
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackProgressSummary')),
      );
      final progressSummary = tester.widget<Text>(
        find.byKey(const Key('playbackProgressSummary')),
      );
      expect(
        progressSummary.data,
        contains('Progress: 0% • Visible messages: 1/3'),
      );
    },
  );

  testWidgets(
    'wide playback scene selector switches demo scenes and resets progress',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(960, 900),
        child: PlaybackScreen(projectId: projectId),
      );

      expect(find.byKey(const Key('playbackSceneDropdown')), findsOneWidget);
      expect(
        find.byKey(const Key('compactPlaybackSceneDropdown')),
        findsNothing,
      );
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);

      container
          .read(playbackControllerProvider(projectId).notifier)
          .seekBy(delta: 5, maxSecond: 11);
      await tester.pumpAndSettle();

      final playbackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(playbackState.currentSecond, 5);

      await tester.tap(find.byKey(const Key('playbackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        find.textContaining('Scene ratio: 16:9', skipOffstage: false),
        findsOneWidget,
      );
      final switchedPlaybackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(switchedPlaybackState.currentSecond, 0);
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackStatusSummary')),
      );
      final switchedStatusSummary = tester.widget<Text>(
        find.byKey(const Key('playbackStatusSummary')),
      );
      expect(switchedStatusSummary.data, contains('t=0s / 8 s'));
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackProgressSummary')),
      );
      final progressSummary = tester.widget<Text>(
        find.byKey(const Key('playbackProgressSummary')),
      );
      expect(
        progressSummary.data,
        contains('Progress: 0% • Visible messages: 1/3'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide playback scene selector stays synced after external scene changes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;
      final projectId = project.id;
      final secondSceneId = project.scenes[1].id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(960, 900),
        child: PlaybackScreen(projectId: projectId),
      );

      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
      expect(
        _dropdownFieldValue(tester, const Key('playbackSceneDropdown')),
        project.scenes.first.id,
      );

      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          secondSceneId;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        _dropdownFieldValue(tester, const Key('playbackSceneDropdown')),
        secondSceneId,
      );
    },
  );

  testWidgets(
    'playback app bar navigation keeps the currently selected scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);
      await _openPlaybackFromProjectList(tester, projectName: 'Demo Project 1');

      await tester.tap(find.byKey(const Key('playbackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('playbackAppBarOpenEditorButton')));
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        find.textContaining(
          'Scene summary: 2 characters • 3 messages • max 8s',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'playback open editor defaults to the first scene before manual selection',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);
      await _openPlaybackFromProjectList(tester, projectName: 'Demo Project 1');

      final openEditorButton = find.byKey(
        const Key('playbackOpenEditorButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, openEditorButton);
      await tester.tap(openEditorButton);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
    },
  );

  testWidgets(
    'compact playback overflow open editor keeps the currently selected scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final router = GoRouter(
        initialLocation: '/playback/$projectId',
        routes: [
          GoRoute(
            path: '/playback/:projectId',
            name: 'playbackProject',
            builder: (context, state) => MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: PlaybackScreen(
                projectId: state.pathParameters['projectId'],
              ),
            ),
          ),
          GoRoute(
            path: '/editor/:projectId',
            name: 'editorProject',
            builder: (context, state) => MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: ChatEditorScreen(
                projectId: state.pathParameters['projectId'],
                initialSceneId: state.uri.queryParameters['sceneId'],
                forceCompactLayout: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactPlaybackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('playbackOverflowMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Chat Editor').last);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        find.textContaining(
          'Scene summary: 2 characters • 3 messages • max 8s',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'playback footer open editor keeps the currently selected scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);
      await _openPlaybackFromProjectList(tester, projectName: 'Demo Project 1');

      await tester.tap(find.byKey(const Key('playbackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Rolling').last);
      await tester.pumpAndSettle();

      final openEditorButton = find.byKey(
        const Key('playbackOpenEditorButton'),
        skipOffstage: false,
      );
      await tester.dragUntilVisible(
        openEditorButton,
        find.byKey(const Key('playbackPageScrollView')),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      await tester.tap(openEditorButton.last);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Scene: Scene 2 - Rolling'), findsOneWidget);
      expect(
        find.textContaining(
          'Scene summary: 2 characters • 3 messages • max 8s',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'compact playback scene switch resets deep preview scroll in long scenes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildLargeMultiSceneImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      expect(
        find.byKey(const Key('compactPlaybackSceneDropdown')),
        findsOneWidget,
      );

      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackPreviewAspectRatio')),
      );

      final previewScrollViewFinder = find.byKey(
        const Key('playbackPreviewScrollView'),
        skipOffstage: false,
      );
      expect(
        tester
            .widget<SingleChildScrollView>(previewScrollViewFinder)
            .controller!
            .position
            .pixels,
        0,
      );

      container
          .read(playbackControllerProvider(projectId).notifier)
          .scrubTo(second: 480, maxSecond: 519);
      await tester.pumpAndSettle();
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackPreviewAspectRatio')),
      );

      expect(
        tester
            .widget<SingleChildScrollView>(previewScrollViewFinder)
            .controller!
            .position
            .pixels,
        greaterThan(0),
      );

      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactPlaybackSceneDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scene 2 - Reset Check').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Scene ratio: 16:9', skipOffstage: false),
        findsOneWidget,
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackPreviewAspectRatio')),
      );
      expect(
        tester
            .widget<SingleChildScrollView>(previewScrollViewFinder)
            .controller!
            .position
            .pixels,
        0,
      );
      expect(
        find.textContaining('t=0s / 7 s', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'compact demo flow stays usable across project list, editor, and playback',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          screenshotExportServiceProvider.overrideWithValue(
            _FakeScreenshotExportService(
              const ScreenshotExportResult.success(
                filename: 'compact_demo_flow.png',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: const ProjectListScreen(forceCompactAppBar: true),
      );

      expect(
        find.byKey(const Key('projectListOverflowMenuButton')),
        findsOneWidget,
      );
      await _ensureProjectCardVisibleByName(tester, 'Demo Project 1');
      expect(find.text('Demo Project 1'), findsOneWidget);
      expect(find.byKey(Key('projectOpenEditor_$projectId')), findsOneWidget);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: ChatEditorScreen(
          projectId: projectId,
          forceCompactLayout: true,
        ),
      );

      expect(find.byKey(const Key('compactAddSceneButton')), findsOneWidget);
      expect(
        find.byKey(const Key('sceneActionsOverflowMenuButton')),
        findsOneWidget,
      );

      final openPlaybackButton = find.widgetWithText(
        FilledButton,
        'Open Playback',
      );
      await _ensureFinderVisibleInPrimaryListView(tester, openPlaybackButton);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      expect(find.byKey(const Key('exportScreenshotButton')), findsOneWidget);
      expect(
        find.text('Keyboard: Space play/pause • ←/→ seek • R restart'),
        findsNothing,
      );

      final exportScreenshotButton = find.byKey(
        const Key('exportScreenshotButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        exportScreenshotButton,
      );
      await tester.tap(exportScreenshotButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Screenshot exported as compact_demo_flow.png.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ultra-compact playback footer actions stack on phone-width screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: PlaybackScreen(projectId: projectId),
      );

      final openEditorButton = find.byKey(
        const Key('playbackOpenEditorButton'),
      );
      final backButton = find.byKey(const Key('playbackBackToProjectsButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, openEditorButton);
      await _ensureFinderVisibleInPrimaryListView(tester, backButton);

      final openEditorPosition = tester.getTopLeft(openEditorButton);
      final backPosition = tester.getTopLeft(backButton);
      final openEditorSize = tester.getSize(openEditorButton);
      final backSize = tester.getSize(backButton);

      expect(backPosition.dy, greaterThan(openEditorPosition.dy));
      expect(backPosition.dx, closeTo(openEditorPosition.dx, 1));
      expect(backSize.width, closeTo(openEditorSize.width, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ultra-compact playback footer actions expose navigation actions on phone-width screens',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectId = await _createStarterProjectInContainer(container);

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: PlaybackScreen(projectId: projectId),
      );

      final openEditorButton = find.byKey(
        const Key('playbackOpenEditorButton'),
      );
      final backButton = find.byKey(const Key('playbackBackToProjectsButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, openEditorButton);
      await _ensureFinderVisibleInPrimaryListView(tester, backButton);

      expect(
        tester.widget<FilledButton>(openEditorButton).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<OutlinedButton>(backButton).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(find.text('Updated (Newest)'), findsOneWidget);
    expect(find.text('Showing 2 of 2 projects'), findsOneWidget);
  });

  testWidgets(
    'project readiness filter chips segment projects by beta status',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(
            _buildAttentionProjectImportPayload(
              projectName: 'Attention Project',
            ),
          );
      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(800, 900),
        child: const ProjectListScreen(),
      );

      expect(find.text('All statuses (3)'), findsOneWidget);
      expect(
        find.byKey(const Key('projectReadinessFilter_ready')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('projectReadinessFilter_timelineQa')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('projectReadinessFilter_needsAttention')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('projectReadinessFilter_needsAttention')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 3 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Attention Project', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Demo Project 1', skipOffstage: false), findsNothing);
      expect(
        find.text('Timeline QA Project', skipOffstage: false),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('projectReadinessFilter_timelineQa')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 3 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Timeline QA Project', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Attention Project', skipOffstage: false), findsNothing);

      await tester.tap(find.byKey(const Key('projectReadinessFilter_ready')));
      await tester.pumpAndSettle();

      expect(
        find.text('Showing 1 of 3 projects', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Demo Project 1', skipOffstage: false), findsOneWidget);
    },
  );

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
    expect(
      find.textContaining('Playback: 1/1 ready • 0 empty • 1 style'),
      findsOneWidget,
    );
    expect(find.text('Ready for playback'), findsOneWidget);
    expect(
      find.byKey(const Key('projectPortfolioReadinessSummary')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Projects: 1 • Ready scenes: 1/1 • Messages: 3'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Ready: no empty scenes • all active characters have lines',
      ),
      findsOneWidget,
    );
    expect(find.text('1 ready projects'), findsOneWidget);
    expect(find.text('0 need attention'), findsOneWidget);
    expect(find.text('Continue Editing'), findsOneWidget);
    expect(find.text('Preview Ready Project'), findsOneWidget);
    expect(find.text('Review Attention Project'), findsOneWidget);
  });

  testWidgets('project list readiness summary reflects demo portfolio totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Projects: 1 • Ready scenes: 2/2 • Messages: 7'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Ready: no empty scenes • all active characters have lines',
      ),
      findsOneWidget,
    );
    expect(find.text('1 ready projects'), findsOneWidget);
    expect(find.text('0 need attention'), findsOneWidget);
  });

  testWidgets('portfolio preview ready CTA opens playback from summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('portfolioPreviewReadyButton')));
    await tester.pumpAndSettle();

    expect(find.text('Playback'), findsOneWidget);
  });

  testWidgets(
    'portfolio preview ready CTA resets stale scene selection to the primary ready scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.singleWhere(
        (candidate) => candidate.id == projectId,
      );
      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          project.scenes.last.id;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final previewReadyButton = find.byKey(
        const Key('portfolioPreviewReadyButton'),
      );
      await tester.ensureVisible(previewReadyButton);
      await tester.pumpAndSettle();
      await tester.tap(previewReadyButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Scene: Scene 1 - Prep Chat'), findsOneWidget);
      expect(find.text('Messages: 4'), findsOneWidget);
    },
  );

  testWidgets(
    'portfolio review timeline QA CTA opens playback from summary card',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byTooltip('Import Project JSON'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        _buildTimelineQaProjectImportPayload(),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const Key('projectPortfolioTimelineQaChip')),
        findsOneWidget,
      );
      expect(find.text('1 timeline QA project'), findsOneWidget);

      final reviewTimelineQaButton = find.byKey(
        const Key('portfolioReviewTimelineQaButton'),
      );
      await tester.ensureVisible(reviewTimelineQaButton);
      await tester.pumpAndSettle();
      await tester.tap(reviewTimelineQaButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Timeline QA Project'), findsOneWidget);
      expect(find.textContaining('Scene: Stacked Cue Scene'), findsOneWidget);
    },
  );

  testWidgets('portfolio continue editing CTA opens editor from summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('portfolioContinueEditingButton')));
    await tester.pumpAndSettle();

    expect(find.text('Chat Editor'), findsOneWidget);
  });

  testWidgets(
    'portfolio continue editing prioritizes projects that need attention',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byTooltip('Add Demo Project'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final attentionPayload = jsonEncode(<String, Object?>{
        'id': 'attention-project-priority-id',
        'name': 'Attention Project',
        'type': 'other',
        'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'scenes': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'attention-scene-priority-1',
            'title': 'Needs Timing Pass',
            'styleId': 'studio_slate',
            'aspectRatio': 'portrait9x16',
            'characters': <Map<String, Object?>>[
              <String, Object?>{
                'id': 'attention-char-priority-1',
                'displayName': 'Taylor',
                'avatarPath': null,
                'bubbleColor': '#2E90FA',
              },
            ],
            'messages': <Map<String, Object?>>[],
          },
        ],
      });

      await tester.tap(find.byTooltip('Import Project JSON'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        attentionPayload,
      );
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolioContinueEditingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Attention Project'), findsOneWidget);
      expect(
        find.textContaining('Scene summary: 1 characters • 0 messages'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'portfolio continue editing focuses first empty scene for attention projects',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byTooltip('Add Demo Project'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byTooltip('Import Project JSON'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        _buildMixedReadinessProjectImportPayload(
          projectName: 'Portfolio Attention Project',
        ),
      );
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolioContinueEditingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.text('Portfolio Attention Project'), findsOneWidget);
      expect(find.textContaining('Scene: Empty Scene'), findsOneWidget);
      expect(
        find.textContaining('Scene summary: 1 characters • 0 messages'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'portfolio review attention CTA opens editor for attention project',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      final payload = jsonEncode({
        'id': 'attention-project-id',
        'name': 'Attention Project',
        'type': 'other',
        'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'scenes': [
          {
            'id': 'attention-scene-1',
            'title': 'Empty Scene',
            'styleId': 'studio_slate',
            'aspectRatio': 'portrait9x16',
            'characters': [
              {
                'id': 'attention-char-1',
                'displayName': 'Taylor',
                'avatarPath': null,
                'bubbleColor': '#2E90FA',
              },
            ],
            'messages': <Object>[],
          },
        ],
      });

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        payload,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final portfolioReviewAttentionButton = find.byKey(
        const Key('portfolioReviewAttentionButton'),
      );
      await tester.ensureVisible(portfolioReviewAttentionButton);
      await tester.pumpAndSettle();
      final reviewButton = tester.widget<OutlinedButton>(
        portfolioReviewAttentionButton,
      );
      reviewButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
    },
  );

  testWidgets(
    'project card shows no messages attention state for empty project',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      final payload = jsonEncode({
        'id': 'empty-project-source-id',
        'name': 'Empty Project',
        'type': 'other',
        'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'scenes': [
          {
            'id': 'empty-scene-1',
            'title': 'Empty Scene',
            'styleId': 'studio_slate',
            'aspectRatio': 'portrait9x16',
            'characters': [
              {
                'id': 'empty-char-1',
                'displayName': 'Taylor',
                'avatarPath': null,
                'bubbleColor': '#2E90FA',
              },
            ],
            'messages': <Object>[],
          },
        ],
      });

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        payload,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Add First Message'), findsOneWidget);
    },
  );

  testWidgets(
    'project card shows empty-scene attention state when partially ready',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      final payload = jsonEncode({
        'id': 'mixed-project-source-id',
        'name': 'Mixed Readiness Project',
        'type': 'series',
        'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'scenes': [
          {
            'id': 'mixed-scene-1',
            'title': 'Ready Scene',
            'styleId': 'studio_slate',
            'aspectRatio': 'portrait9x16',
            'characters': [
              {
                'id': 'mixed-char-1',
                'displayName': 'Taylor',
                'avatarPath': null,
                'bubbleColor': '#2E90FA',
              },
            ],
            'messages': [
              {
                'id': 'mixed-msg-1',
                'characterId': 'mixed-char-1',
                'text': 'Scene one is ready',
                'timestampSeconds': 0,
                'status': 'sent',
                'isIncoming': false,
                'showTypingBefore': false,
              },
            ],
          },
          {
            'id': 'mixed-scene-2',
            'title': 'Empty Scene',
            'styleId': 'night_shift',
            'aspectRatio': 'landscape16x9',
            'characters': [
              {
                'id': 'mixed-char-2',
                'displayName': 'Jordan',
                'avatarPath': null,
                'bubbleColor': '#12B76A',
              },
            ],
            'messages': <Object>[],
          },
        ],
      });

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        payload,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Has empty scenes'), findsOneWidget);
      expect(find.text('Finish Empty Scenes'), findsOneWidget);
      expect(
        find.textContaining('Playback: 1/2 ready • 1 empty • 2 styles'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'project card shows staged-character attention state when a character has no lines yet',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        _buildStagedCharacterProjectImportPayload(),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Characters need lines'), findsOneWidget);
      expect(find.text('Review Scene Setup'), findsOneWidget);
      expect(
        find.textContaining(
          'Scene health: 1 character waiting for lines across 1 scene',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Playback: 0/1 ready • 0 empty • 1 style'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Projects: 1 • Ready scenes: 0/1 • Messages: 2'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Attention: 0 empty scenes • 1 character waiting for lines',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'staged-character attention surfaces scene health in editor and playback',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildStagedCharacterProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final reviewSceneSetupCta = _projectCardDescendant(
        projectName: 'Staged Character Project',
        matching: find.widgetWithText(OutlinedButton, 'Review Scene Setup'),
      );
      await tester.ensureVisible(reviewSceneSetupCta);
      await tester.pumpAndSettle();
      await tester.tap(reviewSceneSetupCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Scene health: 1 character waiting for lines • Jordan has no lines in this scene yet.',
        ),
        findsOneWidget,
      );

      final openPlaybackButton = find.byKey(
        const Key('chatEditorOpenPlaybackButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, openPlaybackButton);
      await tester.tap(openPlaybackButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(
        find.byKey(const Key('playbackSceneHealthLabel')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Scene health: 1 character waiting for lines • Jordan has no lines in this scene yet.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Scene: ${project.scenes.single.title}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'project card shows timeline QA summary without downgrading ready playback state',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        _buildTimelineQaProjectImportPayload(),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _ensureProjectVisibleByName(tester, 'Timeline QA Project');
      final projectId = _projectIdForName(tester, 'Timeline QA Project');

      expect(
        _projectCardDescendant(
          projectName: 'Timeline QA Project',
          matching: find.text('Ready for playback'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('projectOpenPlayback_$projectId')), findsOneWidget);
      expect(
        _projectCardDescendant(
          projectName: 'Timeline QA Project',
          matching: find.textContaining(
            'Timeline QA: 1 shared timestamp • 1 overlapping typing cue across 1 scene',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'timeline QA summary surfaces in editor and playback for stacked cues',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(_buildTimelineQaProjectImportPayload());
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);
      await _ensureProjectVisibleByName(tester, 'Timeline QA Project');

      final openEditorCta = _projectCardDescendant(
        projectName: 'Timeline QA Project',
        matching: find.widgetWithText(FilledButton, 'Open Chat Editor'),
      );
      await tester.ensureVisible(openEditorCta);
      await tester.pumpAndSettle();
      await tester.tap(openEditorCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sceneTimingQaSummaryLine')), findsOneWidget);
      expect(
        find.textContaining(
          'Timeline QA: 1 shared timestamp • 1 overlapping typing cue',
        ),
        findsOneWidget,
      );

      final openPlaybackButton = find.byKey(
        const Key('chatEditorOpenPlaybackButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, openPlaybackButton);
      await tester.tap(openPlaybackButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(
        find.byKey(const Key('playbackSceneTimingQaLabel')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Timeline QA: 1 shared timestamp • 1 overlapping typing cue',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Scene: ${project.scenes.single.title}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mixed readiness project attention CTA opens editor focused on empty scene',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('importProjectJsonButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('importProjectJsonField')),
        _buildMixedReadinessProjectImportPayload(
          projectName: 'CTA Attention Project',
        ),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final finishEmptyScenesCta = _projectCardDescendant(
        projectName: 'CTA Attention Project',
        matching: find.widgetWithText(OutlinedButton, 'Finish Empty Scenes'),
      );
      await tester.ensureVisible(finishEmptyScenesCta);
      await tester.pumpAndSettle();
      await tester.tap(finishEmptyScenesCta, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Chat Editor'), findsOneWidget);
      expect(find.textContaining('Scene: Empty Scene'), findsOneWidget);
      expect(
        find.textContaining('Scene summary: 1 characters • 0 messages'),
        findsOneWidget,
      );
    },
  );

  testWidgets('ready project attention CTA opens playback', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final openPlaybackCta = find
        .widgetWithText(OutlinedButton, 'Open Playback')
        .first;
    await tester.ensureVisible(openPlaybackCta);
    await tester.pumpAndSettle();
    await tester.tap(openPlaybackCta);
    await tester.pumpAndSettle();

    expect(find.text('Playback'), findsOneWidget);
  });

  testWidgets('empty project attention CTA opens editor', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    final payload = jsonEncode({
      'id': 'empty-project-cta-id',
      'name': 'Empty CTA Project',
      'type': 'other',
      'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'scenes': [
        {
          'id': 'empty-cta-scene-1',
          'title': 'Empty Scene',
          'styleId': 'studio_slate',
          'aspectRatio': 'portrait9x16',
          'characters': [
            {
              'id': 'empty-cta-char-1',
              'displayName': 'Taylor',
              'avatarPath': null,
              'bubbleColor': '#2E90FA',
            },
          ],
          'messages': <Object>[],
        },
      ],
    });

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final addFirstMessageCta = _projectCardDescendant(
      projectName: 'Empty CTA Project',
      matching: find.widgetWithText(OutlinedButton, 'Add First Message'),
    );
    await tester.ensureVisible(addFirstMessageCta);
    await tester.pumpAndSettle();
    await tester.tap(addFirstMessageCta, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Chat Editor'), findsOneWidget);
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

  testWidgets(
    'project card open playback prefers the first ready scene over a stale empty selection',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(
            _buildMixedReadinessProjectImportPayload(
              projectName: 'Project Card Ready Scene',
            ),
          );
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;
      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          'mixed-readiness-empty-scene';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      final openPlaybackButton = find.byKey(
        Key('projectOpenPlayback_$projectId'),
      );
      await tester.ensureVisible(openPlaybackButton);
      await tester.pumpAndSettle();
      await tester.tap(openPlaybackButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Scene: Ready Scene'), findsOneWidget);
      expect(find.text('Messages: 1'), findsOneWidget);
    },
  );

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

    final playbackStatusSummaryFinder = find.byKey(
      const Key('playbackStatusSummary'),
    );
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      playbackStatusSummaryFinder,
    );
    final playbackStatusSummary = tester.widget<Text>(
      playbackStatusSummaryFinder,
    );
    expect(playbackStatusSummary.data, contains('t=0s / 15 s'));
    final playbackMessageCountFinder = find.byKey(
      const Key('playbackMessageCountLabel'),
    );
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      playbackMessageCountFinder,
    );
    final playbackMessageCount = tester.widget<Text>(
      playbackMessageCountFinder,
    );
    expect(playbackMessageCount.data, contains('Messages: 4'));
  });

  testWidgets(
    'composer timestamp suggestion follows selected scene by default',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byTooltip('Add Demo Project'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final projectId = _projectIdForName(tester, 'Demo Project 1');

      await _openChatEditorFromProjectList(
        tester,
        projectName: 'Demo Project 1',
      );
      await _ensureMessageComposerVisible(tester);

      var timestampField = tester.widget<TextField>(
        find.byKey(const Key('messageTimestampField')),
      );
      expect(timestampField.controller?.text, '12');

      final snapshot = container.read(sceneSnapshotProvider(projectId)).value!;
      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          snapshot.project.scenes[1].id;
      await tester.pumpAndSettle();

      timestampField = tester.widget<TextField>(
        find.byKey(const Key('messageTimestampField')),
      );
      expect(timestampField.controller?.text, '9');
    },
  );

  testWidgets('composer keeps manual timestamp when switching scenes', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProductionChatPropApp(),
      ),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final projectId = _projectIdForName(tester, 'Demo Project 1');

    await _openChatEditorFromProjectList(
      tester,
      projectName: 'Demo Project 1',
    );
    await _ensureMessageComposerVisible(tester);

    final timestampFieldFinder = find.byKey(const Key('messageTimestampField'));
    await tester.enterText(timestampFieldFinder, '42');
    await tester.pumpAndSettle();

    final snapshot = container.read(sceneSnapshotProvider(projectId)).value!;
    container.read(sceneSelectionProvider(projectId).notifier).selectedSceneId =
        snapshot.project.scenes[1].id;
    await tester.pumpAndSettle();

    final timestampField = tester.widget<TextField>(timestampFieldFinder);
    expect(timestampField.controller?.text, '42');
  });

  testWidgets(
    'composer character selection follows the selected scene by default',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();
      final secondSceneId = await container
          .read(projectsControllerProvider.notifier)
          .addScene(projectId: projectId, title: 'Scene 2');
      final project = (await container.read(
        projectsControllerProvider.future,
      )).singleWhere((candidate) => candidate.id == projectId);
      final firstScene = project.scenes.first;
      final secondScene = project.scenes.singleWhere(
        (scene) => scene.id == secondSceneId,
      );
      final firstSceneCharacterId = firstScene.characters.first.id;
      final secondSceneCharacterId = secondScene.characters.first.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(960, 900),
        child: ChatEditorScreen(projectId: projectId),
      );
      await _ensureMessageComposerVisible(tester);

      expect(
        _dropdownFieldValue(tester, const Key('messageCharacterDropdown')),
        firstSceneCharacterId,
      );

      container
              .read(sceneSelectionProvider(projectId).notifier)
              .selectedSceneId =
          secondSceneId;
      await tester.pumpAndSettle();
      await _ensureMessageComposerVisible(tester);

      expect(
        _dropdownFieldValue(tester, const Key('messageCharacterDropdown')),
        secondSceneCharacterId,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Message Text'),
        'Scene 2 character sync check',
      );
      final addMessageButton = find.widgetWithText(FilledButton, 'Add Message');
      await tester.ensureVisible(addMessageButton);
      await tester.pumpAndSettle();
      await tester.tap(addMessageButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final updatedProject = (await container.read(
        projectsControllerProvider.future,
      )).singleWhere((candidate) => candidate.id == projectId);
      final updatedSecondScene = updatedProject.scenes.singleWhere(
        (scene) => scene.id == secondSceneId,
      );

      expect(updatedSecondScene.messages, hasLength(1));
      expect(
        updatedSecondScene.messages.single.characterId,
        secondSceneCharacterId,
      );
      expect(
        updatedSecondScene.messages.single.characterId,
        isNot(firstSceneCharacterId),
      );
      expect(find.text('Scene 2 character sync check'), findsOneWidget);
    },
  );

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

    expect(find.text('Delete Character'), findsOneWidget);
    expect(
      find.text(
        'Remove Zed from this scene? This character has no assigned messages yet.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('cancelDeleteCharacterButton')));
    await tester.pumpAndSettle();
    expect(find.text('Rename Zed'), findsOneWidget);

    await tester.tapAt(tester.getCenter(zedDeleteIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteCharacterButton')));
    await tester.pumpAndSettle();

    expect(find.text('Removed Zed from the scene.'), findsOneWidget);
    expect(find.text('Rename Zed'), findsNothing);
    expect(find.text('Zed'), findsNothing);
  });

  testWidgets('character bubble color updates editor and playback previews', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProductionChatPropApp(),
      ),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final projectId = _projectIdForName(tester, 'New Project 1');
    final snapshot = container.read(sceneSnapshotProvider(projectId)).value!;
    final scene = snapshot.scene!;
    final alex = scene.characters.first;
    final firstMessage = scene.messages.first;
    final palette = resolveChatStylePalette(scene.styleId);
    final expectedRoseTint = resolveCharacterBubbleTint(
      rawColor: '#F0447C',
      baseColor: palette.outgoingBubbleColor,
    );

    await _openChatEditorFromProjectList(tester);

    final editBubbleColorButton = find.byKey(
      Key('editCharacterBubbleColor_${alex.id}'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, editBubbleColorButton);
    await tester.tap(editBubbleColorButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(Key('characterBubbleColorOption_${alex.id}_#F0447C')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Bubble Color: Rose'), findsOneWidget);

    final editorBubble = tester.widget<Container>(
      find.byKey(Key('editorMessageBubble_${firstMessage.id}')),
    );
    expect(
      (editorBubble.decoration! as BoxDecoration).color,
      expectedRoseTint,
    );

    final openPlaybackButton = find.byKey(
      const Key('chatEditorOpenPlaybackButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, openPlaybackButton);
    await tester.tap(openPlaybackButton);
    await tester.pumpAndSettle();

    final playbackBubbleFinder = find.byKey(
      Key('playbackMessageBubble_${firstMessage.id}'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, playbackBubbleFinder);
    final playbackBubble = tester.widget<Container>(playbackBubbleFinder);
    expect(
      (playbackBubble.decoration! as BoxDecoration).color,
      expectedRoseTint,
    );
  });

  testWidgets('character dialog rejects blank names', (tester) async {
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
      '   ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Character name cannot be empty.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
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

    final editSceneSettingsButton = find.widgetWithText(
      OutlinedButton,
      'Edit Scene Settings',
    );
    await tester.ensureVisible(editSceneSettingsButton);
    await tester.pumpAndSettle();
    await tester.tap(editSceneSettingsButton);
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
      find.textContaining('Style: Cleanroom Day • Aspect: 9:16'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('scenePlaybackSummaryLine')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Playback summary: 3 cues • 2 typing cues • 00:09 total duration',
      ),
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

    final editSceneSettingsButton = find.widgetWithText(
      OutlinedButton,
      'Edit Scene Settings',
    );
    await tester.ensureVisible(editSceneSettingsButton);
    await tester.pumpAndSettle();
    await tester.tap(editSceneSettingsButton);
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    final presetDropdown = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(InputDecorator, 'Style Preset'),
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
      find.textContaining('Style: Night Shift • Aspect: 9:16'),
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

    final renameSceneButton = find.widgetWithText(
      OutlinedButton,
      'Rename Scene',
    );
    await _ensureFinderVisibleInPrimaryListView(tester, renameSceneButton);
    await tester.tap(renameSceneButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Scene Title'),
      'Scene C',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene C'), findsOneWidget);

    final deleteSceneButton = find.widgetWithText(
      OutlinedButton,
      'Delete Scene',
    );
    await tester.ensureVisible(deleteSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteSceneButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    expect(
      find.textContaining('Scene summary: 2 characters • 3 messages • max 9s'),
      findsOneWidget,
    );
  });

  testWidgets('scene dialog rejects blank titles', (tester) async {
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
      '   ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Scene title cannot be empty.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
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

    final moveSceneUpButton = find.byKey(const Key('moveSceneUpButton'));
    await _ensureFinderVisibleInPrimaryListView(tester, moveSceneUpButton);
    await tester.tap(moveSceneUpButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final moveDownAfter = tester.widget<OutlinedButton>(
      find.byKey(const Key('moveSceneDownButton')),
    );
    expect(moveDownAfter.onPressed, isNotNull);
    expect(find.textContaining('Scene: Scene C'), findsOneWidget);
  });

  testWidgets(
    'deleting the last scene keeps selection on the adjacent surviving scene',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProductionChatPropApp(),
        ),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

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

      final projectBeforeDelete = (await container.read(
        projectsControllerProvider.future,
      )).single;
      final expectedSelectedSceneId = projectBeforeDelete.scenes
          .singleWhere((scene) => scene.title == 'Scene B')
          .id;

      expect(find.textContaining('Scene: Scene C'), findsOneWidget);

      final deleteSceneButton = find.widgetWithText(
        OutlinedButton,
        'Delete Scene',
      );
      await tester.ensureVisible(deleteSceneButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteSceneButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Scene: Scene B'), findsOneWidget);
      expect(
        container.read(sceneSelectionProvider(projectId)),
        expectedSelectedSceneId,
      );
    },
  );

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
    await tester.ensureVisible(messageMenuButton);
    await tester.pumpAndSettle();
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

  testWidgets('compact edit message dialog stays usable on narrow screens', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectsControllerProvider.notifier)
        .createDemoProject();
    final projects = await container.read(projectsControllerProvider.future);
    final projectId = projects.single.id;

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: ChatEditorScreen(
        projectId: projectId,
        forceCompactLayout: true,
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final messageMenuButton = find.byIcon(Icons.more_horiz_rounded).first;
    await tester.ensureVisible(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Message'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final dialogFinder = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Text'),
      ),
      'Compact dialog edit',
    );
    await tester.enterText(
      find.descendant(
        of: dialogFinder,
        matching: find.widgetWithText(TextField, 'Timestamp (seconds)'),
      ),
      '11',
    );
    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Compact dialog edit'), findsOneWidget);
    expect(find.textContaining('t=11s'), findsWidgets);
  });

  testWidgets('delete message asks for confirmation before removing it', (
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

    final messageMenuButton = await _openMessageActionsForText(
      tester,
      'Ready for set in 10?',
    );
    await tester.tap(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Message'), findsOneWidget);
    expect(find.textContaining('Ready for set in 10?'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Message'), findsNothing);
    expect(find.text('Ready for set in 10?'), findsOneWidget);

    await tester.tap(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteMessageButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ready for set in 10?'), findsNothing);
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

  testWidgets('edit message dialog rejects invalid timestamps', (
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

    final messageMenuButton = await _openMessageActionsForText(
      tester,
      'Ready for set in 10?',
    );
    await tester.tap(messageMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Message'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(AlertDialog);
    final dialogTimestampField = find.descendant(
      of: dialogFinder,
      matching: find.widgetWithText(TextField, 'Timestamp (seconds)'),
    );
    final dialogSaveButton = find.descendant(
      of: dialogFinder,
      matching: find.text('Save'),
    );

    await tester.enterText(dialogTimestampField, 'abc');
    await tester.tap(dialogSaveButton);
    await tester.pumpAndSettle();

    expect(find.text('Timestamp must be a valid number.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(dialogTimestampField, '-1');
    await tester.tap(dialogSaveButton);
    await tester.pumpAndSettle();

    expect(find.text('Timestamp cannot be negative.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
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

  testWidgets(
    'bulk select delete asks for confirmation before removing messages',
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

      await _openChatEditorFromProjectList(tester);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -220));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final toggleSelectionButton = find.byKey(
        const Key('toggleMessageSelectionModeButton'),
      );
      await tester.ensureVisible(toggleSelectionButton);
      await tester.pumpAndSettle();
      await tester.tap(toggleSelectionButton);
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
      await tester.pumpAndSettle();

      expect(find.text('Delete Selected Messages'), findsOneWidget);
      expect(find.text('Delete 2 selected messages?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Selected Messages'), findsNothing);
      expect(find.text('Ready for set in 10?'), findsOneWidget);
      expect(find.text('Yes, prop phone is prepared.'), findsOneWidget);

      await tester.tap(deleteSelectedButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('confirmDeleteSelectedMessagesButton')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Deleted 2 selected messages.'),
        findsOneWidget,
      );
      expect(find.text('Ready for set in 10?'), findsNothing);
      expect(find.text('Yes, prop phone is prepared.'), findsNothing);
    },
  );

  testWidgets('bulk select shift updates selected message timestamps', (
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

    final toggleSelectionButton = find.byKey(
      const Key('toggleMessageSelectionModeButton'),
    );
    await tester.ensureVisible(toggleSelectionButton);
    await tester.pumpAndSettle();
    await tester.tap(toggleSelectionButton);
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

    final shiftSelectedButton = find.byKey(
      const Key('shiftSelectedMessagesButton'),
    );
    await tester.ensureVisible(shiftSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(shiftSelectedButton);
    await tester.pumpAndSettle();

    expect(find.text('Shift Selected Message Times'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      '3',
    );
    await tester.tap(
      find.byKey(const Key('confirmShiftSelectedMessagesButton')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Shifted 2 selected messages 3 seconds later.'),
      findsOneWidget,
    );
    expect(find.textContaining('Alex • t=3s'), findsOneWidget);
    expect(find.textContaining('Mia • t=7s'), findsOneWidget);
  });

  testWidgets('shift dialog allows valid earlier offsets above zero', (
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

    final secondCheckbox = find.byType(Checkbox).at(1);
    await tester.ensureVisible(secondCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(secondCheckbox);
    await tester.pumpAndSettle();

    final shiftSelectedButton = find.byKey(
      const Key('shiftSelectedMessagesButton'),
    );
    await tester.ensureVisible(shiftSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(shiftSelectedButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      '-2',
    );
    await tester.tap(
      find.byKey(const Key('confirmShiftSelectedMessagesButton')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shift Selected Message Times'), findsNothing);
    expect(
      find.textContaining('Shifted 1 selected message 2 seconds earlier.'),
      findsOneWidget,
    );
    expect(find.textContaining('Mia • t=2s'), findsOneWidget);
  });

  testWidgets('shift dialog validates empty and zero offsets inline', (
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

    final shiftSelectedButton = find.byKey(
      const Key('shiftSelectedMessagesButton'),
    );
    await tester.ensureVisible(shiftSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(shiftSelectedButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('confirmShiftSelectedMessagesButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a whole-second offset.'), findsOneWidget);
    expect(find.text('Shift Selected Message Times'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      '1',
    );
    await tester.pump();
    expect(find.text('Enter a whole-second offset.'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      '0',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Enter a non-zero time shift.'), findsOneWidget);
    expect(find.text('Shift Selected Message Times'), findsOneWidget);
    expect(
      find.textContaining('No selected message times were changed.'),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Shift Selected Message Times'), findsNothing);
  });

  testWidgets('shift dialog keeps invalid offsets open with inline guidance', (
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

    final shiftSelectedButton = find.byKey(
      const Key('shiftSelectedMessagesButton'),
    );
    await tester.ensureVisible(shiftSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(shiftSelectedButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      'later please',
    );
    await tester.tap(
      find.byKey(const Key('confirmShiftSelectedMessagesButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shift Selected Message Times'), findsOneWidget);
    expect(find.text('Use whole seconds, like -2 or 3.'), findsOneWidget);
    expect(
      find.textContaining('No selected message times were changed.'),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Shift Selected Message Times'), findsNothing);
  });

  testWidgets('shift dialog submits valid offsets from the keyboard', (
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

    final shiftSelectedButton = find.byKey(
      const Key('shiftSelectedMessagesButton'),
    );
    await tester.ensureVisible(shiftSelectedButton);
    await tester.pumpAndSettle();
    await tester.tap(shiftSelectedButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shiftSelectedMessagesOffsetField')),
      '2',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shift Selected Message Times'), findsNothing);
    expect(
      find.textContaining('Shifted 1 selected message 2 seconds later.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shift dialog blocks offsets that would move messages before zero',
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

      await _openChatEditorFromProjectList(tester);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -220));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('toggleMessageSelectionModeButton')),
      );
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(Checkbox).at(0);
      await tester.ensureVisible(firstCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      expect(find.textContaining('t=0s'), findsOneWidget);

      final shiftSelectedButton = find.byKey(
        const Key('shiftSelectedMessagesButton'),
      );
      await tester.ensureVisible(shiftSelectedButton);
      await tester.pumpAndSettle();
      await tester.tap(shiftSelectedButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('shiftSelectedMessagesOffsetField')),
        '-1',
      );
      await tester.tap(
        find.byKey(const Key('confirmShiftSelectedMessagesButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shift Selected Message Times'), findsOneWidget);
      expect(
        find.text('Selected messages cannot shift before 0s.'),
        findsOneWidget,
      );
      expect(find.text('-1'), findsOneWidget);
      expect(
        find.textContaining('Shifted 1 selected message'),
        findsNothing,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Shift Selected Message Times'), findsNothing);
    },
  );

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

  testWidgets('empty scene quick template action repopulates messages', (
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

    expect(find.text('No messages in this scene yet.'), findsOneWidget);

    final loadTemplateButton = find.byKey(
      const Key('emptySceneTemplateBriefingButton'),
    );
    await tester.ensureVisible(loadTemplateButton);
    await tester.pumpAndSettle();
    await tester.tap(loadTemplateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Call time shifted to 08:30.'), findsOneWidget);
    expect(find.text('No messages in this scene yet.'), findsNothing);
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

    await _expectPlaybackStatusSummaryContains(
      tester,
      '(00:00 / 00:09)',
    );

    final plusOneButton = find.widgetWithText(FilledButton, '+1s');
    await _ensureFinderVisibleInPrimaryListView(tester, plusOneButton);
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();
    await tester.tap(plusOneButton);
    await tester.pumpAndSettle();

    await _expectPlaybackStatusSummaryContains(
      tester,
      't=3s / 9 s (00:03 / 00:09)',
    );
    expect(find.text('Mia is typing...', skipOffstage: false), findsOneWidget);
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

      await _expectPlaybackProgressSummaryContains(
        tester,
        'Progress: 0% • Visible messages: 1/3',
      );

      final plusFiveButton = find.byKey(const Key('seekForward5Button'));
      await _ensureFinderVisibleInPrimaryListView(tester, plusFiveButton);
      await tester.tap(plusFiveButton);
      await tester.pumpAndSettle();

      await _expectPlaybackProgressSummaryContains(
        tester,
        'Progress: 56% • Visible messages: 2/3',
      );
    },
  );

  testWidgets('playback highlights the active cue as time advances', (
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
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final activeCueFinder = find.byKey(
      const Key('activePreviewCue'),
      skipOffstage: false,
    );
    expect(activeCueFinder, findsOneWidget);
    expect(
      find.descendant(
        of: activeCueFinder,
        matching: find.textContaining('t=0s', skipOffstage: false),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(activeCueFinder, findsOneWidget);
    expect(
      find.descendant(
        of: activeCueFinder,
        matching: find.text('Mia is typing...', skipOffstage: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('playback responds to keyboard seek and restart shortcuts', (
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    await _expectPlaybackStatusSummaryContains(tester, 't=1s / 9 s');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();

    await _expectPlaybackStatusSummaryContains(tester, 't=0s / 9 s');
  });

  testWidgets('playback space shortcut toggles play and pause', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byKey(const Key('newProjectFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 120));

    await _expectPlaybackStatusSummaryContains(tester, 'Status: playing');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    await _expectPlaybackStatusSummaryContains(tester, 'Status: paused');
  });

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

  testWidgets('playback next cue button jumps between message timestamps', (
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

    final nextCueButton = find.byKey(const Key('nextCueButton'));
    await _ensureFinderVisibleInPrimaryListView(tester, nextCueButton);
    await tester.tap(nextCueButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=4s / 9 s', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('playback quick seek +5 button updates timecode', (
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
    await _ensureFinderVisibleInPrimaryListView(tester, plusFiveButton);
    await tester.tap(plusFiveButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('t=5s / 9 s', skipOffstage: false),
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
      await _ensureFinderVisibleInPrimaryListView(tester, plusOneButton);
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

      final statusSummary = find.textContaining(
        'Status: idle',
        skipOffstage: false,
      );
      final timecodeSummary = find.textContaining(
        't=0s / 0 s',
        skipOffstage: false,
      );
      await _ensureFinderVisibleInPrimaryListView(tester, statusSummary);
      await _ensureFinderVisibleInPrimaryListView(tester, timecodeSummary);

      expect(statusSummary, findsOneWidget);
      expect(timecodeSummary, findsOneWidget);
    },
  );

  testWidgets(
    'compact playback video fallback export reflects preview toggles and aspect ratio',
    (tester) async {
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(SystemChannels.platform, (
              methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                clipboardText =
                    (methodCall.arguments as Map)['text'] as String?;
                return null;
              }
              return null;
            });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      await tester.tap(find.byKey(const Key('playbackDeviceFrameSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('playbackCleanPreviewSwitch')));
      await tester.pumpAndSettle();

      final aspectRatioLandscapeChip = find.byKey(
        const Key('aspectRatioLandscapeChip'),
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        aspectRatioLandscapeChip,
      );
      await tester.tap(aspectRatioLandscapeChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final exportVideoButton = find.byKey(const Key('exportVideoButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, exportVideoButton);
      await tester.pumpAndSettle();
      await tester.tap(exportVideoButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Download unavailable. Video fallback JSON copied to clipboard.',
        ),
        findsOneWidget,
      );
      expect(clipboardText, isNotNull);

      final payload = jsonDecode(clipboardText!) as Map<String, dynamic>;
      final renderHints = payload['renderHints'] as Map<String, dynamic>;
      final selectedScene = payload['selectedScene'] as Map<String, dynamic>;
      final messages = selectedScene['messages'] as List<dynamic>;

      expect(renderHints['includeDeviceFrame'], isFalse);
      expect(renderHints['cleanPreview'], isTrue);
      expect(selectedScene['aspectRatio'], 'landscape16x9');
      expect(messages, isNotEmpty);
      expect(
        (messages.first as Map<String, dynamic>)['timestampSeconds'],
        lessThanOrEqualTo(
          (messages.last as Map<String, dynamic>)['timestampSeconds'] as int,
        ),
      );
    },
  );

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

  testWidgets(
    'compact playback aspect ratio switch keeps active timeline state and preview toggles',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final projectId = await container
          .read(projectsControllerProvider.notifier)
          .createProject();

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        child: PlaybackScreen(projectId: projectId),
      );

      await tester.tap(find.byKey(const Key('playbackDeviceFrameSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('playbackCleanPreviewSwitch')));
      await tester.pumpAndSettle();

      final seekForwardFiveButton = find.byKey(const Key('seekForward5Button'));
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        seekForwardFiveButton,
      );
      await tester.tap(seekForwardFiveButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('t=5s / 9 s', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Preview: frameless • clean', skipOffstage: false),
        findsOneWidget,
      );

      final aspectRatioLandscapeChip = find.byKey(
        const Key('aspectRatioLandscapeChip'),
      );
      await _ensureFinderVisibleInPrimaryListView(
        tester,
        aspectRatioLandscapeChip,
      );
      await tester.tap(aspectRatioLandscapeChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Scene ratio: 16:9', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('t=5s / 9 s', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Preview: frameless • clean', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'playback preview expands on wide layouts and clarifies export scaling',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      expect(
        find.byKey(const Key('exportPreviewScaleHintLabel')),
        findsOneWidget,
      );

      final previewFinder = find.byKey(const Key('playbackPreviewAspectRatio'));
      final portraitSize = tester.getSize(previewFinder);
      expect(portraitSize.width, greaterThan(520));
      expect(portraitSize.height, greaterThan(portraitSize.width));

      await tester.tap(find.byKey(const Key('aspectRatioLandscapeChip')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final landscapeSize = tester.getSize(previewFinder);
      expect(landscapeSize.width, greaterThan(960));
      expect(landscapeSize.width, greaterThan(landscapeSize.height));
    },
  );

  testWidgets(
    'playback preview surface and export target follow aspect ratio',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      final previewFinder = find.byKey(const Key('playbackPreviewAspectRatio'));
      final portraitSize = tester.getSize(previewFinder);
      expect(portraitSize.height, greaterThan(portraitSize.width));
      final exportTargetFinder = find.byKey(
        const Key('exportTargetResolutionLabel'),
      );
      await tester.ensureVisible(exportTargetFinder);
      await tester.pumpAndSettle();
      final portraitExportTarget =
          tester.widget<Text>(exportTargetFinder).data ?? '';
      expect(portraitExportTarget, contains('1080'));
      expect(portraitExportTarget, contains('1920'));

      await tester.tap(find.byKey(const Key('aspectRatioLandscapeChip')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final landscapeSize = tester.getSize(previewFinder);
      expect(landscapeSize.width, greaterThan(landscapeSize.height));
      final landscapeExportTarget =
          tester.widget<Text>(exportTargetFinder).data ?? '';
      expect(landscapeExportTarget, contains('1920'));
      expect(landscapeExportTarget, contains('1080'));
      expect(landscapeExportTarget, isNot(equals(portraitExportTarget)));
    },
  );

  testWidgets(
    'playback focus preview opens with transport controls and closes cleanly',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('playbackFocusPreviewScreen')),
        findsOneWidget,
      );

      var focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('idle'));

      await tester.tap(
        find.byKey(const Key('focusPreviewTogglePlaybackButton')),
      );
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('playing'));

      final previewSurface = tester.widget<GestureDetector>(
        find.byKey(const Key('focusPreviewTapSurface')),
      );
      previewSurface.onTap?.call();
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('paused'));

      await tester.tap(find.byKey(const Key('focusPreviewCloseButton')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('playbackFocusPreviewScreen')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'focus preview transport controls scrub and jump between cues',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('focusPreviewNextCueButton')));
      await tester.pump();

      var focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:04 / 00:09'));
      expect(focusStatus.data, contains('paused'));

      await tester.tap(find.byKey(const Key('focusPreviewSeekBackwardButton')));
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:03 / 00:09'));

      final slider = tester.widget<Slider>(
        find.byKey(const Key('focusPreviewProgressSlider')),
      );
      slider.onChanged?.call(7);
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:07 / 00:09'));

      await tester.tap(find.byKey(const Key('focusPreviewPrevCueButton')));
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:04 / 00:09'));

      await tester.tap(find.byKey(const Key('focusPreviewRestartButton')));
      await tester.pump();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:00 / 00:09'));
    },
  );

  testWidgets('focus preview swipe gestures seek in 5 second steps', (
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

    final focusPreviewButton = find.byKey(
      const Key('openPlaybackFocusPreviewButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
    await tester.tap(focusPreviewButton);
    await tester.pumpAndSettle();

    final surface = find.byKey(const Key('focusPreviewTapSurface'));
    final surfaceWidget = tester.widget<GestureDetector>(surface);
    surfaceWidget.onHorizontalDragEnd?.call(
      DragEndDetails(
        primaryVelocity: 640,
        velocity: const Velocity(pixelsPerSecond: Offset(640, 0)),
      ),
    );
    await tester.pump();

    var focusStatus = tester.widget<Text>(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );
    expect(focusStatus.data, contains('00:05 / 00:09'));
    expect(find.textContaining('Swipe left/right for ±5s'), findsOneWidget);

    surfaceWidget.onHorizontalDragEnd?.call(
      DragEndDetails(
        primaryVelocity: -640,
        velocity: const Velocity(pixelsPerSecond: Offset(-640, 0)),
      ),
    );
    await tester.pump();

    focusStatus = tester.widget<Text>(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );
    expect(focusStatus.data, contains('00:00 / 00:09'));
  });

  testWidgets('focus preview edge double taps jump between cues', (
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

    final focusPreviewButton = find.byKey(
      const Key('openPlaybackFocusPreviewButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
    await tester.tap(focusPreviewButton);
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(
      find.byKey(const Key('focusPreviewProgressSlider')),
    );
    slider.onChanged?.call(1);
    await tester.pumpAndSettle();

    final surface = find.byKey(const Key('focusPreviewTapSurface'));
    final surfaceRect = tester.getRect(surface);
    final surfaceWidget = tester.widget<GestureDetector>(surface);

    surfaceWidget.onDoubleTapDown?.call(
      TapDownDetails(
        localPosition: Offset(surfaceRect.width - 24, surfaceRect.height / 2),
      ),
    );
    surfaceWidget.onDoubleTap?.call();
    await tester.pump();

    var focusStatus = tester.widget<Text>(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );
    expect(focusStatus.data, contains('00:04 / 00:09'));

    surfaceWidget.onDoubleTapDown?.call(
      TapDownDetails(localPosition: Offset(24, surfaceRect.height / 2)),
    );
    surfaceWidget.onDoubleTap?.call();
    await tester.pump();

    focusStatus = tester.widget<Text>(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );
    expect(focusStatus.data, contains('00:00 / 00:09'));
  });

  testWidgets(
    'focus preview preserves playback position and preview mode when opened from the main timeline',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ProductionChatPropApp()),
      );
      await _ensureOnProjectList(tester);

      await tester.tap(find.byKey(const Key('newProjectFab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _openPlaybackFromProjectList(tester);

      final cleanPreviewSwitch = find.byKey(
        const Key('playbackCleanPreviewSwitch'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, cleanPreviewSwitch);
      await tester.tap(cleanPreviewSwitch);
      await tester.pumpAndSettle();

      final plusFiveButton = find.byKey(const Key('seekForward5Button'));
      await _ensureFinderVisibleInPrimaryListView(tester, plusFiveButton);
      await tester.tap(plusFiveButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('t=5s / 9 s', skipOffstage: false),
        findsOneWidget,
      );

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      var focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:05 / 00:09'));
      expect(find.byKey(const Key('cleanPreviewHeader')), findsOneWidget);
      expect(find.text('Playback Timeline (read-only)'), findsNothing);

      await tester.tap(find.byKey(const Key('focusPreviewSeekForwardButton')));
      await tester.pumpAndSettle();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:06 / 00:09'));

      await tester.tap(find.byKey(const Key('focusPreviewCloseButton')));
      await tester.pumpAndSettle();

      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('cleanPreviewHeader')),
      );
      final cleanPreviewHeader = tester.widget<Text>(
        find.byKey(const Key('cleanPreviewHeader')),
      );
      expect(cleanPreviewHeader.data, contains('00:06 / 00:09'));
    },
  );

  testWidgets(
    'focus preview responds to keyboard play pause and restart shortcuts',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(projectsControllerProvider.notifier).createProject();
      final projects = await container.read(projectsControllerProvider.future);
      final project = projects.single;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: PlaybackScreen(projectId: project.id)),
        ),
      );
      await tester.pumpAndSettle();

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        container.read(playbackControllerProvider(project.id)).isPlaying,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        container.read(playbackControllerProvider(project.id)).isPlaying,
        isFalse,
      );

      container
          .read(playbackControllerProvider(project.id).notifier)
          .scrubTo(second: 2, maxSecond: 9);
      await tester.pumpAndSettle();

      var focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:02 / 00:09'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:03 / 00:09'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:02 / 00:09'));

      container
          .read(playbackControllerProvider(project.id).notifier)
          .scrubTo(second: 0, maxSecond: 9);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:00 / 00:09'));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pumpAndSettle();

      focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:00 / 00:09'));
    },
  );

  testWidgets('focus preview escape shortcut closes the overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester, projectName: 'Demo Project 1');

    final focusPreviewButton = find.byKey(
      const Key('openPlaybackFocusPreviewButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
    await tester.tap(focusPreviewButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsOneWidget);
    expect(
      find.text(
        'Tap to play or pause. Swipe left/right for ±5s. Double-tap the left/right edge for previous/next cue. Press Esc on desktop or long press anywhere to exit.',
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsNothing);
    expect(find.text('Playback'), findsOneWidget);
  });

  testWidgets('focus preview long press exits cleanly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byTooltip('Add Demo Project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _openPlaybackFromProjectList(tester, projectName: 'Demo Project 1');

    final focusPreviewButton = find.byKey(
      const Key('openPlaybackFocusPreviewButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
    await tester.tap(focusPreviewButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('focusPreviewTapSurface')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsNothing);
    expect(find.text('Playback'), findsOneWidget);
  });

  testWidgets('compact playback focus preview stays usable on narrow screens', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectsControllerProvider.notifier)
        .createDemoProject();
    final projects = await container.read(projectsControllerProvider.future);
    final projectId = projects.single.id;

    await _pumpNarrowScreenWithContainer(
      tester,
      container: container,
      child: PlaybackScreen(projectId: projectId),
    );

    final focusPreviewButton = find.byKey(
      const Key('openPlaybackFocusPreviewButton'),
    );
    await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
    await tester.tap(focusPreviewButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playbackFocusPreviewScreen')), findsOneWidget);
    expect(find.byKey(const Key('focusPreviewHintLabel')), findsOneWidget);
    expect(find.byKey(const Key('focusPreviewCloseButton')), findsOneWidget);
    expect(find.byKey(const Key('focusPreviewProgressSlider')), findsOneWidget);
    expect(find.byKey(const Key('focusPreviewNextCueButton')), findsOneWidget);
    expect(
      find.byKey(const Key('focusPreviewSeekForwardButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('focusPreviewSeekForwardButton')));
    await tester.pump();

    final focusStatus = tester.widget<Text>(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );
    expect(focusStatus.data, contains('00:01'));

    final previewSize = tester.getSize(
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );
    expect(previewSize.width, lessThanOrEqualTo(360));
    expect(previewSize.height, greaterThan(previewSize.width));

    await tester.tap(find.byKey(const Key('focusPreviewCloseButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('playbackFocusPreviewScreen')),
      findsNothing,
    );
  });

  testWidgets(
    'ultra-compact focus preview transport keeps icon controls reachable',
    (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await container
          .read(projectsControllerProvider.notifier)
          .createDemoProject();
      final projects = await container.read(projectsControllerProvider.future);
      final projectId = projects.single.id;

      await _pumpNarrowScreenWithContainer(
        tester,
        container: container,
        size: const Size(320, 700),
        child: PlaybackScreen(projectId: projectId),
      );

      final playButton = find.byKey(const Key('playButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, playButton);
      expect(playButton, findsOneWidget);
      expect(find.byKey(const Key('seekForward5Button')), findsOneWidget);
      expect(find.byKey(const Key('restartButton')), findsOneWidget);

      await tester.tap(playButton);
      await tester.pump();
      expect(find.byKey(const Key('pauseButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('seekForward5Button')));
      await tester.pump();

      final mainPlaybackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(mainPlaybackState.currentSecond, 5);

      final restartButton = find.byKey(const Key('restartButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, restartButton);
      await tester.tap(restartButton);
      await tester.pump();

      final resetMainPlaybackState = container.read(
        playbackControllerProvider(projectId),
      );
      expect(resetMainPlaybackState.currentSecond, 0);

      final focusPreviewButton = find.byKey(
        const Key('openPlaybackFocusPreviewButton'),
      );
      await _ensureFinderVisibleInPrimaryListView(tester, focusPreviewButton);
      await tester.tap(focusPreviewButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('playbackFocusPreviewScreen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focusPreviewTogglePlaybackButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focusPreviewRestartButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focusPreviewNextCueButton')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('focusPreviewTogglePlaybackButton')),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('focusPreviewSeekForwardButton')));
      await tester.pump();

      final focusStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(focusStatus.data, contains('00:01'));

      await tester.tap(find.byKey(const Key('focusPreviewRestartButton')));
      await tester.pump();

      final resetStatus = tester.widget<Text>(
        find.byKey(const Key('focusPreviewStatusLabel')),
      );
      expect(resetStatus.data, contains('00:00'));
      expect(tester.takeException(), isNull);
    },
  );

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
    final copyHandoffButton = tester.widget<TextButton>(
      find.byKey(const Key('copyVideoFallbackButton')),
    );

    expect(screenshotButton.onPressed, isNull);
    expect(videoButton.onPressed, isNull);
    expect(copyHandoffButton.onPressed, isNull);
    expect(find.text('Export pre-flight • No messages'), findsOneWidget);
  });

  testWidgets(
    'empty playback scene shows recovery guidance and disables transport controls',
    (tester) async {
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

      final emptyStateHint = find.byKey(const Key('playbackEmptyStateHint'));
      await _ensureFinderVisibleInPrimaryListView(tester, emptyStateHint);

      expect(emptyStateHint, findsOneWidget);
      expect(
        find.text(
          'Add at least one timed message in Chat Editor to enable playback and export.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Keyboard: Space play/pause', skipOffstage: false),
        findsNothing,
      );

      final restartButtonFinder = find.byKey(const Key('restartButton'));
      final playButtonFinder = find.byKey(const Key('playButton'));
      await _ensureFinderVisibleInPrimaryListView(tester, restartButtonFinder);
      await _ensureFinderVisibleInPrimaryListView(tester, playButtonFinder);

      final slider = tester.widget<Slider>(find.byType(Slider));
      final restartButton = tester.widget<OutlinedButton>(
        restartButtonFinder,
      );
      final playButton = tester.widget<FilledButton>(
        playButtonFinder,
      );

      expect(slider.onChanged, isNull);
      expect(restartButton.onPressed, isNull);
      expect(playButton.onPressed, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      final progressSummary = tester.widget<Text>(
        find.byKey(const Key('playbackProgressSummary')),
      );
      expect(
        progressSummary.data,
        contains('Progress: 0% • Visible messages: 0/0'),
      );
      expect(
        find.textContaining('Status: playing', skipOffstage: false),
        findsNothing,
      );

      await _ensureFinderVisibleInPrimaryListView(
        tester,
        find.byKey(const Key('playbackPreviewEmptyState')),
      );
      expect(
        find.byKey(const Key('playbackPreviewEmptyStateText')),
        findsOneWidget,
      );
    },
  );

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

    expect(
      find.textContaining('Messages: 15', skipOffstage: false),
      findsOneWidget,
    );

    final screenshotButton = tester.widget<FilledButton>(
      find.byKey(const Key('exportScreenshotButton')),
    );
    final videoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('exportVideoButton')),
    );
    expect(screenshotButton.onPressed, isNotNull);
    expect(videoButton.onPressed, isNotNull);
    expect(find.text('Export pre-flight • Ready'), findsOneWidget);

    final nextCueButton = find.byKey(const Key('nextCueButton'));
    await _ensureFinderVisibleInPrimaryListView(tester, nextCueButton);
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(projectsControllerProvider.notifier).createProject();
    final projects = await container.read(projectsControllerProvider.future);
    final project = projects.single;
    final scene = project.scenes.single;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PlaybackScreen(projectId: project.id)),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(playbackControllerProvider(project.id).notifier)
        .scrubTo(second: 2, maxSecond: 9);
    await tester.pumpAndSettle();

    final playbackSummary = find.textContaining(
      't=2s / 9 s',
      skipOffstage: false,
    );
    await _ensureFinderVisibleInPrimaryListView(tester, playbackSummary);
    expect(playbackSummary, findsOneWidget);

    await container
        .read(projectsControllerProvider.notifier)
        .updateSceneSettings(
          projectId: project.id,
          sceneId: scene.id,
          title: scene.title,
          styleId: scene.styleId,
          aspectRatio: SceneAspectRatio.landscape16x9,
        );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Scene ratio: 16:9', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('t=2s / 9 s', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('playback stays responsive with imported 500+ messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    final payload = _buildLargeProjectImportPayload(messageCount: 520);

    await tester.tap(find.byKey(const Key('importProjectJsonButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('importProjectJsonField')),
      payload,
    );
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmImportFromJsonButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Stress Playback Project'), findsOneWidget);

    await _openPlaybackFromProjectList(
      tester,
      projectName: 'Stress Playback Project',
    );

    expect(find.text('Playback'), findsOneWidget);
    expect(
      find.textContaining('Scene: Stress Scene', skipOffstage: false),
      findsOneWidget,
    );
    final playbackMessageCountFinder = find.byKey(
      const Key('playbackMessageCountLabel'),
    );
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      playbackMessageCountFinder,
    );
    final playbackMessageCount = tester.widget<Text>(
      playbackMessageCountFinder,
    );
    expect(playbackMessageCount.data, contains('Messages: 520'));
    final playbackProgressSummaryFinder = find.byKey(
      const Key('playbackProgressSummary'),
    );
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      playbackProgressSummaryFinder,
    );
    final playbackProgressSummary = tester.widget<Text>(
      playbackProgressSummaryFinder,
    );
    expect(
      playbackProgressSummary.data,
      contains('Progress: 0% • Visible messages: 1/520'),
    );

    final plusFiveButton = find.byKey(const Key('seekForward5Button'));
    await _ensureFinderVisibleInPrimaryListView(tester, plusFiveButton);
    expect(plusFiveButton, findsOneWidget);
  });

  testWidgets('playback preview auto-follows deep cues in long scenes', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectsControllerProvider.notifier)
        .importProjectFromJson(
          _buildLargeProjectImportPayload(messageCount: 520),
        );
    final projects = await container.read(projectsControllerProvider.future);
    final projectId = projects.single.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PlaybackScreen(projectId: projectId)),
      ),
    );
    await tester.pumpAndSettle();

    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final previewScrollViewFinder = find.byKey(
      const Key('playbackPreviewScrollView'),
      skipOffstage: false,
    );
    final initialPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(initialPreviewScrollView.controller, isNotNull);
    expect(initialPreviewScrollView.controller!.position.pixels, 0);

    container
        .read(playbackControllerProvider(projectId).notifier)
        .scrubTo(second: 480, maxSecond: 519);
    await tester.pumpAndSettle();
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final updatedPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(
      updatedPreviewScrollView.controller!.position.pixels,
      greaterThan(0),
    );
    expect(
      find.byKey(const Key('activePreviewCue'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('playback preview re-follows earlier cues after backward scrub', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectsControllerProvider.notifier)
        .importProjectFromJson(
          _buildLargeProjectImportPayload(messageCount: 520),
        );
    final projects = await container.read(projectsControllerProvider.future);
    final projectId = projects.single.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PlaybackScreen(projectId: projectId)),
      ),
    );
    await tester.pumpAndSettle();

    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final previewScrollViewFinder = find.byKey(
      const Key('playbackPreviewScrollView'),
      skipOffstage: false,
    );

    container
        .read(playbackControllerProvider(projectId).notifier)
        .scrubTo(second: 480, maxSecond: 519);
    await tester.pumpAndSettle();
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final deepPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    final deepOffset = deepPreviewScrollView.controller!.position.pixels;
    expect(deepOffset, greaterThan(0));

    container
        .read(playbackControllerProvider(projectId).notifier)
        .scrubTo(second: 60, maxSecond: 519);
    await tester.pumpAndSettle();
    await _ensureFinderVisibleInPrimaryListView(
      tester,
      find.byKey(const Key('playbackPreviewAspectRatio')),
    );

    final rewoundPreviewScrollView = tester.widget<SingleChildScrollView>(
      previewScrollViewFinder,
    );
    expect(
      rewoundPreviewScrollView.controller!.position.pixels,
      lessThan(deepOffset),
    );
    expect(
      find.byKey(const Key('activePreviewCue'), skipOffstage: false),
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

const _testAvatarDataUri =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9sotZ1sAAAAASUVORK5CYII=';

Future<void> _pumpNarrowScreenWithContainer(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollProjectListToCards(WidgetTester tester) async {
  final scrollable =
      find.byKey(const Key('projectCardsListView')).evaluate().isNotEmpty
      ? find.byKey(const Key('projectCardsListView'))
      : find.byKey(const Key('projectListScrollView')).evaluate().isNotEmpty
      ? find.byKey(const Key('projectListScrollView'))
      : find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -220));
  await tester.pumpAndSettle();
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

Future<void> _ensureFinderVisibleInPrimaryListView(
  WidgetTester tester,
  Finder finder,
) async {
  if (finder.evaluate().isEmpty) {
    final listView = find.byType(ListView).first;
    for (var i = 0; i < 16 && finder.evaluate().isEmpty; i += 1) {
      await tester.drag(listView, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 16 && finder.evaluate().isEmpty; i += 1) {
      await tester.drag(listView, const Offset(0, 220));
      await tester.pumpAndSettle();
    }
  }

  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

String? _dropdownFieldValue(WidgetTester tester, Key key) {
  final dropdownFinder = find.byKey(key);
  expect(dropdownFinder, findsOneWidget);
  final state = tester.state<FormFieldState<String>>(dropdownFinder);
  return state.value;
}

Future<Finder> _openMessageActionsForText(
  WidgetTester tester,
  String messageText,
) async {
  final messageFinder = find.text(messageText, skipOffstage: false);
  if (messageFinder.evaluate().isEmpty) {
    final scrollable = find.byType(ListView).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -220));
      await tester.pumpAndSettle();
      if (messageFinder.evaluate().isNotEmpty) {
        break;
      }
    }
  }

  if (messageFinder.evaluate().isEmpty) {
    fail('Message "$messageText" not found after scrolling.');
  }

  final visibleMessageFinder = find
      .text(messageText, skipOffstage: false)
      .first;
  await tester.ensureVisible(visibleMessageFinder);
  await tester.pumpAndSettle();

  final messageCard = find
      .ancestor(
        of: visibleMessageFinder,
        matching: find.byType(Card),
      )
      .first;
  final messageMenuButton = find
      .descendant(
        of: messageCard,
        matching: find.byIcon(Icons.more_horiz_rounded),
      )
      .first;
  await tester.ensureVisible(messageMenuButton);
  await tester.pumpAndSettle();
  return messageMenuButton;
}

Future<void> _ensureProjectVisibleByName(
  WidgetTester tester,
  String projectName,
) async {
  final projectNameFinder = find.text(projectName, skipOffstage: false);
  if (projectNameFinder.evaluate().isNotEmpty) {
    await tester.ensureVisible(projectNameFinder.first);
    await tester.pumpAndSettle();
    return;
  }

  final scrollable =
      find.byKey(const Key('projectCardsListView')).evaluate().isNotEmpty
      ? find.byKey(const Key('projectCardsListView'))
      : find.byKey(const Key('projectListScrollView')).evaluate().isNotEmpty
      ? find.byKey(const Key('projectListScrollView'))
      : find.byType(Scrollable).first;

  for (var i = 0; i < 12; i++) {
    if (projectNameFinder.evaluate().isNotEmpty) {
      await tester.ensureVisible(projectNameFinder.first);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
}

Finder _projectCardDescendant({
  required String projectName,
  required Finder matching,
}) {
  final projectCard = find
      .ancestor(
        of: find.text(projectName).first,
        matching: find.byType(Card),
      )
      .first;
  return find.descendant(of: projectCard, matching: matching);
}

String _projectIdForName(WidgetTester tester, String projectName) {
  final projectCard = find
      .ancestor(
        of: find.text(projectName).first,
        matching: find.byType(Card),
      )
      .first;
  final cardWidget = tester.widget<Card>(projectCard);
  return (cardWidget.key! as ValueKey<String>).value.replaceFirst(
    'projectCard_',
    '',
  );
}

Future<void> _openChatEditorFromProjectList(
  WidgetTester tester, {
  String projectName = 'New Project 1',
}) async {
  final projectId = _projectIdForName(tester, projectName);
  final openEditorButton = find.byKey(Key('projectOpenEditor_$projectId'));
  await _prepareProjectActionTap(tester, openEditorButton);
  await tester.tap(openEditorButton.hitTestable().first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _expectPlaybackStatusSummaryContains(
  WidgetTester tester,
  String snippet,
) async {
  final finder = find.byKey(const Key('playbackStatusSummary'));
  await _ensureFinderVisibleInPrimaryListView(tester, finder);
  final widget = tester.widget<Text>(finder);
  expect(widget.data, contains(snippet));
}

Future<void> _expectPlaybackProgressSummaryContains(
  WidgetTester tester,
  String snippet,
) async {
  final finder = find.byKey(const Key('playbackProgressSummary'));
  await _ensureFinderVisibleInPrimaryListView(tester, finder);
  final widget = tester.widget<Text>(finder);
  expect(widget.data, contains(snippet));
}

Future<void> _openPlaybackFromProjectList(
  WidgetTester tester, {
  String projectName = 'New Project 1',
}) async {
  final projectId = _projectIdForName(tester, projectName);
  final openPlaybackButton = find.byKey(Key('projectOpenPlayback_$projectId'));
  await _prepareProjectActionTap(tester, openPlaybackButton);
  await tester.tap(openPlaybackButton.hitTestable().first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _prepareProjectActionTap(
  WidgetTester tester,
  Finder actionButton,
) async {
  await tester.ensureVisible(actionButton);
  await tester.pumpAndSettle();

  if (actionButton.hitTestable().evaluate().isNotEmpty ||
      find.byType(SnackBar).evaluate().isEmpty) {
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -180));
  await tester.pumpAndSettle();
}

Future<void> _ensureProjectCardVisibleByName(
  WidgetTester tester,
  String projectName,
) async {
  final projectNameFinder = find.text(projectName);
  final scrollView =
      find.byKey(const Key('projectListScrollView')).evaluate().isNotEmpty
      ? find.byKey(const Key('projectListScrollView'))
      : find.byType(Scrollable).first;

  for (var i = 0; i < 8 && projectNameFinder.evaluate().isEmpty; i += 1) {
    await tester.drag(scrollView, const Offset(0, -220));
    await tester.pumpAndSettle();
  }

  expect(projectNameFinder, findsWidgets);
  await tester.ensureVisible(projectNameFinder.first);
  await tester.pumpAndSettle();
}

Future<String> _openProjectMenuForProject(
  WidgetTester tester,
  String projectName,
) async {
  await _ensureProjectCardVisibleByName(tester, projectName);

  final projectNameFinder = find.text(projectName).first;

  final projectCard = find
      .ancestor(
        of: projectNameFinder,
        matching: find.byType(Card),
      )
      .first;
  final cardWidget = tester.widget<Card>(projectCard);
  final projectId = (cardWidget.key! as ValueKey<String>).value.replaceFirst(
    'projectCard_',
    '',
  );
  final menuButton = _projectCardDescendant(
    projectName: projectName,
    matching: find.byWidgetPredicate((widget) => widget is PopupMenuButton),
  );

  await tester.ensureVisible(menuButton);
  await tester.pumpAndSettle();
  tester.state<PopupMenuButtonState<Object?>>(menuButton).showButtonMenu();
  await tester.pumpAndSettle();
  return projectId;
}

String _buildLargeProjectImportPayload({required int messageCount}) {
  final payload = _buildLargeProjectImportData(messageCount: messageCount);
  return jsonEncode(payload);
}

String _buildLargeMultiSceneImportPayload({int firstSceneMessageCount = 520}) {
  final payload = _buildLargeProjectImportData(
    messageCount: firstSceneMessageCount,
    includeResetCheckScene: true,
  );
  return jsonEncode(payload);
}

Map<String, Object?> _buildLargeProjectImportData({
  required int messageCount,
  bool includeResetCheckScene = false,
}) {
  final messages = List<Map<String, Object?>>.generate(
    messageCount,
    (index) => {
      'id': 'm_$index',
      'characterId': index.isEven ? 'c_alex' : 'c_mia',
      'text': 'Stress message $index',
      'timestampSeconds': index,
      'status': index % 3 == 0
          ? 'sent'
          : index % 3 == 1
          ? 'delivered'
          : 'seen',
      'isIncoming': index.isOdd,
      'showTypingBefore': index % 5 == 0,
    },
    growable: false,
  );

  final scenes = <Map<String, Object?>>[
    {
      'id': 'scene-stress',
      'title': 'Stress Scene',
      'styleId': 'studio_default',
      'aspectRatio': 'portrait9x16',
      'characters': [
        {
          'id': 'c_alex',
          'displayName': 'Alex',
          'avatarPath': null,
          'bubbleColor': '#2E90FA',
        },
        {
          'id': 'c_mia',
          'displayName': 'Mia',
          'avatarPath': null,
          'bubbleColor': '#12B76A',
        },
      ],
      'messages': messages,
    },
  ];

  if (includeResetCheckScene) {
    scenes.add({
      'id': 'scene-reset-check',
      'title': 'Scene 2 - Reset Check',
      'styleId': 'studio_slate',
      'aspectRatio': 'landscape16x9',
      'characters': [
        {
          'id': 'c_alex',
          'displayName': 'Alex',
          'avatarPath': null,
          'bubbleColor': '#2E90FA',
        },
        {
          'id': 'c_mia',
          'displayName': 'Mia',
          'avatarPath': null,
          'bubbleColor': '#12B76A',
        },
      ],
      'messages': [
        {
          'id': 'reset_m_0',
          'characterId': 'c_alex',
          'text': 'Reset cue 0',
          'timestampSeconds': 0,
          'status': 'sent',
          'isIncoming': false,
          'showTypingBefore': false,
        },
        {
          'id': 'reset_m_1',
          'characterId': 'c_mia',
          'text': 'Reset cue 1',
          'timestampSeconds': 3,
          'status': 'delivered',
          'isIncoming': true,
          'showTypingBefore': true,
        },
        {
          'id': 'reset_m_2',
          'characterId': 'c_alex',
          'text': 'Reset cue 2',
          'timestampSeconds': 7,
          'status': 'seen',
          'isIncoming': false,
          'showTypingBefore': false,
        },
      ],
    });
  }

  return {
    'id': 'stress-project-source',
    'name': 'Stress Playback Project',
    'type': 'series',
    'createdAt': DateTime.utc(2026, 3, 31, 12).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 3, 31, 12).toIso8601String(),
    'scenes': scenes,
  };
}

String _buildAttentionProjectImportPayload({
  String projectName = 'Compact Attention Project',
}) {
  return jsonEncode({
    'id': 'compact-attention-source-id',
    'name': projectName,
    'type': 'other',
    'createdAt': DateTime.utc(2026, 4, 30, 10).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 4, 30, 10).toIso8601String(),
    'scenes': [
      {
        'id': 'compact-attention-scene-1',
        'title': 'Needs Attention',
        'styleId': 'studio_slate',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'compact-attention-char-1',
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

String _buildStagedCharacterProjectImportPayload({
  String projectName = 'Staged Character Project',
}) {
  return jsonEncode({
    'id': 'staged-character-source-id',
    'name': projectName,
    'type': 'series',
    'createdAt': DateTime.utc(2026, 5, 1, 9).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 5, 1, 9).toIso8601String(),
    'scenes': [
      {
        'id': 'staged-character-scene-1',
        'title': 'Blocking Pass',
        'styleId': 'studio_slate',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'staged-character-char-1',
            'displayName': 'Taylor',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
          {
            'id': 'staged-character-char-2',
            'displayName': 'Jordan',
            'avatarPath': null,
            'bubbleColor': '#12B76A',
          },
        ],
        'messages': [
          {
            'id': 'staged-character-msg-1',
            'characterId': 'staged-character-char-1',
            'text': 'Lead line is blocked in.',
            'timestampSeconds': 0,
            'status': 'sent',
            'isIncoming': false,
            'showTypingBefore': false,
          },
          {
            'id': 'staged-character-msg-2',
            'characterId': 'staged-character-char-1',
            'text': 'Jordan still needs a reply cue.',
            'timestampSeconds': 5,
            'status': 'delivered',
            'isIncoming': false,
            'showTypingBefore': true,
          },
        ],
      },
    ],
  });
}

String _buildMixedReadinessProjectImportPayload({
  String projectName = 'Mixed Readiness Project',
}) {
  return jsonEncode({
    'id': 'mixed-readiness-source-id',
    'name': projectName,
    'type': 'series',
    'createdAt': DateTime.utc(2026, 4, 30, 11).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 4, 30, 11).toIso8601String(),
    'scenes': [
      {
        'id': 'mixed-readiness-ready-scene',
        'title': 'Ready Scene',
        'styleId': 'studio_slate',
        'aspectRatio': 'portrait9x16',
        'characters': [
          {
            'id': 'mixed-readiness-ready-char',
            'displayName': 'Taylor',
            'avatarPath': null,
            'bubbleColor': '#2E90FA',
          },
        ],
        'messages': [
          {
            'id': 'mixed-readiness-ready-message',
            'characterId': 'mixed-readiness-ready-char',
            'text': 'Ready scene is already blocked.',
            'timestampSeconds': 0,
            'status': 'sent',
            'isIncoming': false,
            'showTypingBefore': false,
          },
        ],
      },
      {
        'id': 'mixed-readiness-empty-scene',
        'title': 'Empty Scene',
        'styleId': 'night_shift',
        'aspectRatio': 'landscape16x9',
        'characters': [
          {
            'id': 'mixed-readiness-empty-char',
            'displayName': 'Jordan',
            'avatarPath': null,
            'bubbleColor': '#12B76A',
          },
        ],
        'messages': <Object>[],
      },
    ],
  });
}

String _buildTimelineQaProjectImportPayload({
  String projectName = 'Timeline QA Project',
}) {
  return jsonEncode({
    'id': 'timeline-qa-source-id',
    'name': projectName,
    'type': 'ad',
    'createdAt': DateTime.utc(2026, 5, 2, 9).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 5, 2, 9).toIso8601String(),
    'scenes': [
      {
        'id': 'timeline-qa-scene-1',
        'title': 'Stacked Cue Scene',
        'styleId': 'studio_slate',
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
            'id': 'timeline-qa-msg-1',
            'characterId': 'timeline-qa-char-1',
            'text': 'Taylor lands a stacked cue.',
            'timestampSeconds': 4,
            'status': 'sent',
            'isIncoming': false,
            'showTypingBefore': true,
          },
          {
            'id': 'timeline-qa-msg-2',
            'characterId': 'timeline-qa-char-2',
            'text': 'Jordan replies on the same beat.',
            'timestampSeconds': 4,
            'status': 'delivered',
            'isIncoming': true,
            'showTypingBefore': true,
          },
        ],
      },
    ],
  });
}

Future<String> _createStarterProjectInContainer(
  ProviderContainer container,
) async {
  await container.read(projectsControllerProvider.notifier).createProject();
  final projects = await container.read(projectsControllerProvider.future);
  return projects.single.id;
}
