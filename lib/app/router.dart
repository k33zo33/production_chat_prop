import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/pages/project_list_screen.dart';

const projectsRoutePath = '/';
const editorRoutePath = '/editor';
const editorProjectRoutePath = '/editor/:projectId';
const playbackRoutePath = '/playback';
const playbackProjectRoutePath = '/playback/:projectId';

final appRouter = GoRouter(
  initialLocation: projectsRoutePath,
  routes: [
    GoRoute(
      path: projectsRoutePath,
      name: 'projects',
      builder: (context, state) => const ProjectListScreen(),
    ),
    GoRoute(
      path: editorRoutePath,
      name: 'editor',
      builder: (context, state) => const ChatEditorScreen(),
    ),
    GoRoute(
      path: editorProjectRoutePath,
      name: 'editorProject',
      builder: (context, state) => ChatEditorScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    ),
    GoRoute(
      path: playbackRoutePath,
      name: 'playback',
      builder: (context, state) => const PlaybackScreen(),
    ),
    GoRoute(
      path: playbackProjectRoutePath,
      name: 'playbackProject',
      builder: (context, state) => PlaybackScreen(
        projectId: state.pathParameters['projectId'],
        initialSceneId: state.uri.queryParameters['sceneId'],
      ),
    ),
  ],
);
