import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/widgets/screen_scaffold.dart';

class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Playback',
      description:
          'MVP placeholder za Play/Pause/Restart, scrubber i export kontrole.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.goNamed('projects'),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Back to Projects'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('editor'),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Open Chat Editor'),
        ),
      ],
    );
  }
}
