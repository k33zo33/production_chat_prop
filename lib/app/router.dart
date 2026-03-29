import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/pages/chat_editor_screen.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';
import 'package:production_chat_prop/features/projects/presentation/pages/project_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'projects',
      builder: (context, state) => const ProjectListScreen(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) => const ChatEditorScreen(),
    ),
    GoRoute(
      path: '/playback',
      name: 'playback',
      builder: (context, state) => const PlaybackScreen(),
    ),
  ],
);
