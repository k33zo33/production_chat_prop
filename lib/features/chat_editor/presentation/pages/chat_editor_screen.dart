import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';

class ChatEditorScreen extends ConsumerWidget {
  const ChatEditorScreen({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Editor')),
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
        title: const Text('Chat Editor'),
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

            return _ProjectEditorPlaceholder(
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
                  const Text('Unable to open project.'),
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

class _ProjectEditorPlaceholder extends StatelessWidget {
  const _ProjectEditorPlaceholder({
    required this.snapshot,
    required this.onSceneSelected,
  });

  final SceneSnapshot snapshot;
  final ValueChanged<String> onSceneSelected;

  @override
  Widget build(BuildContext context) {
    final project = snapshot.project;
    final selectedScene = snapshot.scene;

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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Project type: ${project.type.name}'),
                const SizedBox(height: 4),
                Text('Scenes: ${project.scenes.length}'),
                if (project.scenes.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedScene?.id,
                    decoration: const InputDecoration(
                      labelText: 'Selected Scene',
                    ),
                    items: [
                      for (final scene in project.scenes)
                        DropdownMenuItem(
                          value: scene.id,
                          child: Text(scene.title),
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
        if (selectedScene == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('This project has no scenes yet.'),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scene: ${selectedScene.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Style: ${selectedScene.styleId} • Aspect: ${selectedScene.aspectRatio.name}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Characters',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final character in selectedScene.characters)
                        Chip(label: Text(character.displayName)),
                    ],
                  ),
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
                    'Messages (read-only)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  if (selectedScene.messages.isEmpty)
                    const Text('No messages in this scene yet.')
                  else
                    for (final message in selectedScene.messages) ...[
                      _MessageRow(
                        message: message,
                        speakerName: _resolveSpeakerName(
                          characterId: message.characterId,
                          sceneProject: project,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => context.goNamed(
                'playbackProject',
                pathParameters: {'projectId': project.id},
              ),
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Open Playback'),
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
    required Project sceneProject,
  }) {
    for (final scene in sceneProject.scenes) {
      for (final character in scene.characters) {
        if (character.id == characterId) {
          return character.displayName;
        }
      }
    }
    return 'Unknown';
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.speakerName});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$speakerName • t=${message.timestampSeconds}s • ${message.status.name}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(message.text),
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
