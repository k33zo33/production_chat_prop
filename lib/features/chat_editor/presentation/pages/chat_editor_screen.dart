import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/widgets/screen_scaffold.dart';

class ChatEditorScreen extends StatelessWidget {
  const ChatEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Chat Editor',
      description:
          'MVP placeholder za uređivanje scene, likova i poruka kroz vrijeme.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.goNamed('playback'),
          icon: const Icon(Icons.smart_display_rounded),
          label: const Text('Preview Playback'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('projects'),
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('Back to Projects'),
        ),
      ],
    );
  }
}
