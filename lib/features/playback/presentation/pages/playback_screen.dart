import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';

class PlaybackScreen extends ConsumerWidget {
  const PlaybackScreen({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playback')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No project selected.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.goNamed('projects'),
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('Back to Projects'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeProjectId = projectId!;
    final snapshotState = ref.watch(sceneSnapshotProvider(activeProjectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback'),
        actions: [
          IconButton(
            tooltip: 'Back to Projects',
            onPressed: () => context.goNamed('projects'),
            icon: const Icon(Icons.list_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: snapshotState.when(
          data: (snapshot) {
            if (snapshot == null) {
              return const _ProjectNotFoundState();
            }

            return _PlaybackTimeline(
              snapshot: snapshot,
              onSceneSelected: (sceneId) {
                ref
                        .read(sceneSelectionProvider(activeProjectId).notifier)
                        .selectedSceneId =
                    sceneId;
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded),
                  const SizedBox(height: 12),
                  const Text('Unable to open playback.'),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackTimeline extends StatelessWidget {
  const _PlaybackTimeline({
    required this.snapshot,
    required this.onSceneSelected,
  });

  final SceneSnapshot snapshot;
  final ValueChanged<String> onSceneSelected;

  @override
  Widget build(BuildContext context) {
    final project = snapshot.project;
    final scene = snapshot.scene;
    final sortedMessages = scene == null ? <Message>[] : [...scene.messages]
      ..sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Scene: ${scene?.title ?? 'No scene'}'),
                const SizedBox(height: 4),
                Text('Messages: ${sortedMessages.length}'),
                if (project.scenes.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: scene?.id,
                    decoration: const InputDecoration(
                      labelText: 'Selected Scene',
                    ),
                    items: [
                      for (final item in project.scenes)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.title),
                        ),
                    ],
                    onChanged: (sceneId) {
                      if (sceneId != null) {
                        onSceneSelected(sceneId);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback Timeline (read-only)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sprint 1 placeholder for Play/Pause/Restart and scrubber.',
                ),
                const SizedBox(height: 12),
                if (sortedMessages.isEmpty)
                  const Text('No messages available for playback.')
                else
                  for (final message in sortedMessages) ...[
                    _TimelineItem(
                      message: message,
                      speakerName: _resolveSpeakerName(
                        characterId: message.characterId,
                        project: project,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => context.goNamed(
                'editorProject',
                pathParameters: {'projectId': project.id},
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Open Chat Editor'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.goNamed('projects'),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Back to Projects'),
            ),
          ],
        ),
      ],
    );
  }

  String _resolveSpeakerName({
    required String characterId,
    required Project project,
  }) {
    for (final item in project.scenes) {
      for (final character in item.characters) {
        if (character.id == characterId) {
          return character.displayName;
        }
      }
    }
    return 'Unknown';
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.message, required this.speakerName});

  final Message message;
  final String speakerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: message.isIncoming
            ? const Color(0xFFEFF4FF)
            : const Color(0xFFEFFAF4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('t=${message.timestampSeconds}s'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$speakerName • ${message.status.name}'),
                const SizedBox(height: 2),
                Text(message.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectNotFoundState extends StatelessWidget {
  const _ProjectNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined),
            const SizedBox(height: 12),
            const Text('Project not found.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.goNamed('projects'),
              child: const Text('Back to Projects'),
            ),
          ],
        ),
      ),
    );
  }
}
