import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

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
              projectId: activeProjectId,
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

class _ProjectEditorPlaceholder extends ConsumerWidget {
  const _ProjectEditorPlaceholder({
    required this.projectId,
    required this.snapshot,
    required this.onSceneSelected,
  });

  final String projectId;
  final SceneSnapshot snapshot;
  final ValueChanged<String> onSceneSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CharacterManagerCard(
            projectId: project.id,
            sceneId: selectedScene.id,
            characters: selectedScene.characters,
          ),
          const SizedBox(height: 12),
          _MessageComposerCard(
            projectId: project.id,
            sceneId: selectedScene.id,
            characters: selectedScene.characters,
            latestTimestamp: selectedScene.messages.isEmpty
                ? 0
                : selectedScene.messages.last.timestampSeconds,
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
                        projectId: project.id,
                        sceneId: selectedScene.id,
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
  const _MessageRow({
    required this.projectId,
    required this.sceneId,
    required this.message,
    required this.speakerName,
  });

  final String projectId;
  final String sceneId;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$speakerName • t=${message.timestampSeconds}s • ${message.status.name}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              _MessageActions(
                projectId: projectId,
                sceneId: sceneId,
                message: message,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.text),
        ],
      ),
    );
  }
}

class _MessageComposerCard extends ConsumerStatefulWidget {
  const _MessageComposerCard({
    required this.projectId,
    required this.sceneId,
    required this.characters,
    required this.latestTimestamp,
  });

  final String projectId;
  final String sceneId;
  final List<Character> characters;
  final int latestTimestamp;

  @override
  ConsumerState<_MessageComposerCard> createState() =>
      _MessageComposerCardState();
}

class _MessageComposerCardState extends ConsumerState<_MessageComposerCard> {
  late final TextEditingController _textController;
  late final TextEditingController _timestampController;
  String? _selectedCharacterId;
  MessageStatus _status = MessageStatus.sent;
  bool _isIncoming = false;
  bool _showTypingBefore = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _timestampController = TextEditingController(
      text: (widget.latestTimestamp + 1).toString(),
    );
    if (widget.characters.isNotEmpty) {
      _selectedCharacterId = widget.characters.first.id;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _timestampController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MessageComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasCurrentCharacter = widget.characters.any(
      (character) => character.id == _selectedCharacterId,
    );
    if (!hasCurrentCharacter) {
      _selectedCharacterId = widget.characters.isEmpty
          ? null
          : widget.characters.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Message',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCharacterId,
              decoration: const InputDecoration(labelText: 'Character'),
              items: [
                for (final character in widget.characters)
                  DropdownMenuItem(
                    value: character.id,
                    child: Text(character.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCharacterId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Message Text'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timestampController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Timestamp (seconds)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MessageStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: MessageStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isIncoming,
              contentPadding: EdgeInsets.zero,
              title: const Text('Incoming'),
              onChanged: (value) {
                setState(() {
                  _isIncoming = value;
                });
              },
            ),
            SwitchListTile(
              value: _showTypingBefore,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show typing before'),
              onChanged: (value) {
                setState(() {
                  _showTypingBefore = value;
                });
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _selectedCharacterId == null ? null : _addMessage,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Add Message'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMessage() async {
    final timestamp = int.tryParse(_timestampController.text.trim());
    if (timestamp == null || _selectedCharacterId == null) {
      return;
    }

    if (timestamp < widget.latestTimestamp && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Warning: timestamp goes backward compared to the current scene order.',
          ),
        ),
      );
    }

    await ref
        .read(projectsControllerProvider.notifier)
        .addMessage(
          projectId: widget.projectId,
          sceneId: widget.sceneId,
          characterId: _selectedCharacterId!,
          text: _textController.text,
          timestampSeconds: timestamp,
          status: _status,
          isIncoming: _isIncoming,
          showTypingBefore: _showTypingBefore,
        );

    if (!mounted) {
      return;
    }

    _textController.clear();
    _timestampController.text = (timestamp + 1).toString();
    setState(() {
      _showTypingBefore = false;
    });
  }
}

class _MessageActions extends ConsumerWidget {
  const _MessageActions({
    required this.projectId,
    required this.sceneId,
    required this.message,
  });

  final String projectId;
  final String sceneId;
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MessageAction>(
      onSelected: (action) async {
        switch (action) {
          case _MessageAction.editText:
            final updatedText = await _showEditMessageDialog(
              context,
              message.text,
            );
            if (updatedText == null) {
              return;
            }
            await ref
                .read(projectsControllerProvider.notifier)
                .updateMessageText(
                  projectId: projectId,
                  sceneId: sceneId,
                  messageId: message.id,
                  newText: updatedText,
                );
            return;
          case _MessageAction.delete:
            await ref
                .read(projectsControllerProvider.notifier)
                .deleteMessage(
                  projectId: projectId,
                  sceneId: sceneId,
                  messageId: message.id,
                );
            return;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _MessageAction.editText,
          child: Text('Edit Text'),
        ),
        PopupMenuItem(
          value: _MessageAction.delete,
          child: Text('Delete'),
        ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }

  Future<String?> _showEditMessageDialog(
    BuildContext context,
    String currentText,
  ) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message Text'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result;
  }
}

enum _MessageAction { editText, delete }

class _CharacterManagerCard extends ConsumerWidget {
  const _CharacterManagerCard({
    required this.projectId,
    required this.sceneId,
    required this.characters,
  });

  final String projectId;
  final String sceneId;
  final List<Character> characters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Characters',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final newName = await _showCharacterNameDialog(
                      context,
                      title: 'Add Character',
                    );
                    if (newName == null) {
                      return;
                    }

                    await ref
                        .read(projectsControllerProvider.notifier)
                        .addCharacter(
                          projectId: projectId,
                          sceneId: sceneId,
                          displayName: newName,
                        );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (characters.isEmpty)
              const Text('No characters in this scene.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final character in characters)
                    Chip(
                      label: Text(character.displayName),
                      onDeleted: () async {
                        if (characters.length == 1) {
                          return;
                        }

                        await ref
                            .read(projectsControllerProvider.notifier)
                            .deleteCharacter(
                              projectId: projectId,
                              sceneId: sceneId,
                              characterId: character.id,
                            );
                      },
                      deleteIcon: const Icon(Icons.person_remove_rounded),
                    ),
                ],
              ),
            if (characters.length <= 1) ...[
              const SizedBox(height: 8),
              const Text(
                'At least one character should remain in the scene.',
              ),
            ],
            if (characters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final character in characters)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final updatedName = await _showCharacterNameDialog(
                          context,
                          title: 'Rename Character',
                          initialValue: character.displayName,
                        );
                        if (updatedName == null) {
                          return;
                        }

                        await ref
                            .read(projectsControllerProvider.notifier)
                            .renameCharacter(
                              projectId: projectId,
                              sceneId: sceneId,
                              characterId: character.id,
                              newDisplayName: updatedName,
                            );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: Text('Rename ${character.displayName}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _showCharacterNameDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Character Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result;
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
