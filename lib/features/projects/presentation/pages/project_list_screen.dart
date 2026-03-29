import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/widgets/screen_scaffold.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Project List',
      description:
          'MVP placeholder za listu projekata, kreiranje i otvaranje projekta.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.goNamed('editor'),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Open Chat Editor'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('playback'),
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text('Go to Playback'),
        ),
      ],
    );
  }
}
