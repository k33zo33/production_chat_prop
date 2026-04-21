import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/core/widgets/app_content_frame.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
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
        child: AppContentFrame(
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
    final selectedSceneMaxSecond = selectedScene == null
        ? 0
        : _sceneMaxSecond(selectedScene);
    final selectedSceneIndex = selectedScene == null
        ? -1
        : project.scenes.indexWhere((scene) => scene.id == selectedScene.id);

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
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('sceneSummaryLine'),
                    'Scene summary: '
                    '${selectedScene.characters.length} characters • '
                    '${selectedScene.messages.length} messages • '
                    'max ${selectedSceneMaxSecond}s',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('scenePlaybackSummaryLine'),
                    'Playback summary: '
                    '${_sceneCueCount(selectedScene)} cues • '
                    '${_sceneTypingCueCount(selectedScene)} typing cues • '
                    '${_formatSceneDuration(selectedSceneMaxSecond)} total duration',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final sceneName = await _showSceneNameDialog(
                            context,
                            title: 'Add Scene',
                            initialValue: 'Scene ${project.scenes.length + 1}',
                          );
                          if (sceneName == null) {
                            return;
                          }

                          final addedSceneId = await ref
                              .read(projectsControllerProvider.notifier)
                              .addScene(
                                projectId: project.id,
                                title: sceneName,
                              );
                          if (addedSceneId != null) {
                            onSceneSelected(addedSceneId);
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Scene'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('duplicateSceneButton'),
                        onPressed: () async {
                          final duplicatedSceneId = await ref
                              .read(projectsControllerProvider.notifier)
                              .duplicateScene(
                                projectId: project.id,
                                sceneId: selectedScene.id,
                              );
                          if (duplicatedSceneId != null) {
                            onSceneSelected(duplicatedSceneId);
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Duplicate Scene'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('applyTemplateBriefingButton'),
                        onPressed: () async {
                          final applied = await ref
                              .read(projectsControllerProvider.notifier)
                              .applySceneTemplate(
                                projectId: project.id,
                                sceneId: selectedScene.id,
                                templateId: 'briefing',
                              );
                          if (!context.mounted || !applied) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Applied template: Briefing'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Template: Briefing'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('applyTemplateGroupAlertButton'),
                        onPressed: () async {
                          final applied = await ref
                              .read(projectsControllerProvider.notifier)
                              .applySceneTemplate(
                                projectId: project.id,
                                sceneId: selectedScene.id,
                                templateId: 'group_alert',
                              );
                          if (!context.mounted || !applied) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Applied template: Group Alert'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.groups_rounded),
                        label: const Text('Template: Group Alert'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final updatedName = await _showSceneNameDialog(
                            context,
                            title: 'Rename Scene',
                            initialValue: selectedScene.title,
                          );
                          if (updatedName == null) {
                            return;
                          }

                          await ref
                              .read(projectsControllerProvider.notifier)
                              .renameScene(
                                projectId: project.id,
                                sceneId: selectedScene.id,
                                newTitle: updatedName,
                              );
                        },
                        icon: const Icon(
                          Icons.drive_file_rename_outline_rounded,
                        ),
                        label: const Text('Rename Scene'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('moveSceneUpButton'),
                        onPressed: selectedSceneIndex <= 0
                            ? null
                            : () async {
                                final moved = await ref
                                    .read(projectsControllerProvider.notifier)
                                    .moveScene(
                                      projectId: project.id,
                                      sceneId: selectedScene.id,
                                      direction: -1,
                                    );
                                if (moved) {
                                  onSceneSelected(selectedScene.id);
                                }
                              },
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        label: const Text('Move Scene Up'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('moveSceneDownButton'),
                        onPressed:
                            selectedSceneIndex < 0 ||
                                selectedSceneIndex >= project.scenes.length - 1
                            ? null
                            : () async {
                                final moved = await ref
                                    .read(projectsControllerProvider.notifier)
                                    .moveScene(
                                      projectId: project.id,
                                      sceneId: selectedScene.id,
                                      direction: 1,
                                    );
                                if (moved) {
                                  onSceneSelected(selectedScene.id);
                                }
                              },
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: const Text('Move Scene Down'),
                      ),
                      OutlinedButton.icon(
                        onPressed: project.scenes.length <= 1
                            ? null
                            : () async {
                                final confirmed = await _showDeleteSceneDialog(
                                  context,
                                  sceneTitle: selectedScene.title,
                                );
                                if (!confirmed) {
                                  return;
                                }

                                final deleted = await ref
                                    .read(projectsControllerProvider.notifier)
                                    .deleteScene(
                                      projectId: project.id,
                                      sceneId: selectedScene.id,
                                    );
                                if (!deleted) {
                                  return;
                                }

                                for (final scene in project.scenes) {
                                  if (scene.id != selectedScene.id) {
                                    onSceneSelected(scene.id);
                                    break;
                                  }
                                }
                              },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete Scene'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final input = await _showSceneSettingsDialog(
                            context,
                            scene: selectedScene,
                          );
                          if (input == null) {
                            return;
                          }

                          await ref
                              .read(projectsControllerProvider.notifier)
                              .updateSceneSettings(
                                projectId: project.id,
                                sceneId: selectedScene.id,
                                title: input.title,
                                styleId: input.styleId,
                                aspectRatio: input.aspectRatio,
                              );
                        },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Edit Scene Settings'),
                      ),
                    ],
                  ),
                  if (project.scenes.length <= 1) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'At least one scene should remain in the project.',
                    ),
                  ],
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
          _MessageTimelineCard(
            projectId: project.id,
            sceneId: selectedScene.id,
            sceneStyleId: selectedScene.styleId,
            sceneMessages: selectedScene.messages,
            sceneCharacters: selectedScene.characters,
            sceneProject: project,
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

  Future<String?> _showSceneNameDialog(
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
            decoration: const InputDecoration(labelText: 'Scene Title'),
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

  Future<bool> _showDeleteSceneDialog(
    BuildContext context, {
    required String sceneTitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Scene'),
          content: Text('Delete "$sceneTitle"? This removes all its messages.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<_SceneSettingsInput?> _showSceneSettingsDialog(
    BuildContext context, {
    required Scene scene,
  }) async {
    final titleController = TextEditingController(text: scene.title);
    final styleIdController = TextEditingController(text: scene.styleId);
    var selectedStyleId = scene.styleId;
    var selectedAspectRatio = scene.aspectRatio;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<_SceneSettingsInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedPalette = resolveChatStylePalette(selectedStyleId);
            return AlertDialog(
              title: const Text('Edit Scene Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Scene Title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: styleIdController,
                      decoration: const InputDecoration(labelText: 'Style ID'),
                      onChanged: (value) {
                        selectedStyleId = value.trim();
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          kChatStylePalettes.any(
                            (style) => style.id == selectedStyleId,
                          )
                          ? selectedStyleId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Style Preset',
                      ),
                      items: [
                        for (final style in kChatStylePalettes)
                          DropdownMenuItem(
                            value: style.id,
                            child: Text('${style.name} (${style.id})'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStyleId = value;
                            styleIdController.text = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      key: const Key('sceneStylePreviewRow'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedPalette.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _StyleDot(
                            color: selectedPalette.incomingBubbleColor,
                          ),
                          const SizedBox(width: 8),
                          _StyleDot(
                            color: selectedPalette.outgoingBubbleColor,
                          ),
                          const SizedBox(width: 8),
                          _StyleDot(color: selectedPalette.typingColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedPalette.name,
                              style: TextStyle(
                                color: selectedPalette.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SceneAspectRatio>(
                      initialValue: selectedAspectRatio,
                      decoration: const InputDecoration(
                        labelText: 'Aspect Ratio',
                      ),
                      items: SceneAspectRatio.values
                          .map(
                            (ratio) => DropdownMenuItem(
                              value: ratio,
                              child: Text(ratio.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedAspectRatio = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final trimmedTitle = titleController.text.trim();
                    final trimmedStyleId = styleIdController.text.trim();
                    if (trimmedTitle.isEmpty || trimmedStyleId.isEmpty) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Scene title and style are required.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop(
                      _SceneSettingsInput(
                        title: trimmedTitle,
                        styleId: trimmedStyleId,
                        aspectRatio: selectedAspectRatio,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }
}

class _SceneSettingsInput {
  const _SceneSettingsInput({
    required this.title,
    required this.styleId,
    required this.aspectRatio,
  });

  final String title;
  final String styleId;
  final SceneAspectRatio aspectRatio;
}

class _StyleDot extends StatelessWidget {
  const _StyleDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessageTimelineCard extends ConsumerStatefulWidget {
  const _MessageTimelineCard({
    required this.projectId,
    required this.sceneId,
    required this.sceneStyleId,
    required this.sceneMessages,
    required this.sceneCharacters,
    required this.sceneProject,
  });

  final String projectId;
  final String sceneId;
  final String sceneStyleId;
  final List<Message> sceneMessages;
  final List<Character> sceneCharacters;
  final Project sceneProject;

  @override
  ConsumerState<_MessageTimelineCard> createState() =>
      _MessageTimelineCardState();
}

class _MessageTimelineCardState extends ConsumerState<_MessageTimelineCard> {
  bool _selectionMode = false;
  final Set<String> _selectedMessageIds = <String>{};

  @override
  void didUpdateWidget(covariant _MessageTimelineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final availableIds = widget.sceneMessages
        .map((message) => message.id)
        .toSet();
    _selectedMessageIds.removeWhere((id) => !availableIds.contains(id));
    if (_selectedMessageIds.isEmpty && _selectionMode) {
      _selectionMode = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = resolveChatStylePalette(widget.sceneStyleId);
    final speakerNameById = _buildSpeakerNameById(widget.sceneProject);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('toggleMessageSelectionModeButton'),
                  onPressed: () {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      if (!_selectionMode) {
                        _selectedMessageIds.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _selectionMode
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                  ),
                  label: Text(
                    _selectionMode ? 'Selection On' : 'Select Multiple',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('clearSceneMessagesButton'),
                  onPressed: widget.sceneMessages.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await _showClearMessagesDialog(
                            context,
                          );
                          if (!confirmed) {
                            return;
                          }

                          final removed = await ref
                              .read(projectsControllerProvider.notifier)
                              .clearSceneMessages(
                                projectId: widget.projectId,
                                sceneId: widget.sceneId,
                              );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _selectedMessageIds.clear();
                            _selectionMode = false;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cleared $removed messages from scene.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear Scene Chat'),
                ),
                OutlinedButton.icon(
                  key: const Key('deleteSelectedMessagesButton'),
                  onPressed: !_selectionMode || _selectedMessageIds.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await _showDeleteSelectedMessagesDialog(
                            context,
                            selectedCount: _selectedMessageIds.length,
                          );
                          if (!context.mounted || !confirmed) {
                            return;
                          }

                          final removed = await ref
                              .read(projectsControllerProvider.notifier)
                              .deleteMessagesByIds(
                                projectId: widget.projectId,
                                sceneId: widget.sceneId,
                                messageIds: _selectedMessageIds,
                              );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _selectedMessageIds.clear();
                            _selectionMode = false;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Deleted $removed selected messages.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text(
                    'Delete Selected (${_selectedMessageIds.length})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.sceneMessages.isEmpty) ...[
              const Text('No messages in this scene yet.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('emptySceneTemplateBriefingButton'),
                    onPressed: () async {
                      final applied = await ref
                          .read(projectsControllerProvider.notifier)
                          .applySceneTemplate(
                            projectId: widget.projectId,
                            sceneId: widget.sceneId,
                            templateId: 'briefing',
                          );
                      if (!context.mounted || !applied) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Applied template: Briefing'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Load Briefing Template'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('emptySceneTemplateGroupAlertButton'),
                    onPressed: () async {
                      final applied = await ref
                          .read(projectsControllerProvider.notifier)
                          .applySceneTemplate(
                            projectId: widget.projectId,
                            sceneId: widget.sceneId,
                            templateId: 'group_alert',
                          );
                      if (!context.mounted || !applied) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Applied template: Group Alert'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Load Group Alert Template'),
                  ),
                ],
              ),
            ] else
              for (var i = 0; i < widget.sceneMessages.length; i++) ...[
                _MessageRow(
                  projectId: widget.projectId,
                  sceneId: widget.sceneId,
                  message: widget.sceneMessages[i],
                  messages: widget.sceneMessages,
                  palette: palette,
                  characters: widget.sceneCharacters,
                  speakerName: _resolveSpeakerName(
                    characterId: widget.sceneMessages[i].characterId,
                    speakerNameById: speakerNameById,
                  ),
                  canMoveEarlier: i > 0,
                  canMoveLater: i < widget.sceneMessages.length - 1,
                  selectionMode: _selectionMode,
                  isSelected: _selectedMessageIds.contains(
                    widget.sceneMessages[i].id,
                  ),
                  onSelectedChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMessageIds.add(widget.sceneMessages[i].id);
                      } else {
                        _selectedMessageIds.remove(widget.sceneMessages[i].id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  String _resolveSpeakerName({
    required String characterId,
    required Map<String, String> speakerNameById,
  }) {
    return speakerNameById[characterId] ?? 'Unknown';
  }

  Map<String, String> _buildSpeakerNameById(Project sceneProject) {
    final map = <String, String>{};
    for (final scene in sceneProject.scenes) {
      for (final character in scene.characters) {
        map[character.id] = character.displayName;
      }
    }
    return map;
  }

  Future<bool> _showClearMessagesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Scene Messages'),
          content: const Text('Delete all messages in this scene?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _showDeleteSelectedMessagesDialog(
    BuildContext context, {
    required int selectedCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Selected Messages'),
          content: Text('Delete $selectedCount selected messages?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDeleteSelectedMessagesButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.projectId,
    required this.sceneId,
    required this.message,
    required this.messages,
    required this.palette,
    required this.characters,
    required this.speakerName,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.selectionMode,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  final String projectId;
  final String sceneId;
  final Message message;
  final List<Message> messages;
  final ChatStylePalette palette;
  final List<Character> characters;
  final String speakerName;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: message.isIncoming
            ? palette.incomingBubbleColor
            : palette.outgoingBubbleColor,
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: palette.textColor),
                ),
              ),
              if (selectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectedChanged(value ?? false),
                ),
              _MessageActions(
                projectId: projectId,
                sceneId: sceneId,
                message: message,
                messages: messages,
                characters: characters,
                canMoveEarlier: canMoveEarlier,
                canMoveLater: canMoveLater,
                selectionMode: selectionMode,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textColor),
          ),
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
    if (timestamp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timestamp must be a valid number.')),
        );
      }
      return;
    }
    if (timestamp < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timestamp cannot be negative.')),
        );
      }
      return;
    }
    if (_selectedCharacterId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a character before adding a message.'),
          ),
        );
      }
      return;
    }
    if (_textController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message text cannot be empty.')),
        );
      }
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
    required this.messages,
    required this.characters,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.selectionMode,
  });

  final String projectId;
  final String sceneId;
  final Message message;
  final List<Message> messages;
  final List<Character> characters;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectionMode) {
      return const SizedBox.shrink();
    }

    final currentMessages = messages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('moveMessageUp_${message.id}'),
          tooltip: 'Move Message Up',
          onPressed: !canMoveEarlier
              ? null
              : () => ref
                    .read(projectsControllerProvider.notifier)
                    .moveMessageInOrder(
                      projectId: projectId,
                      sceneId: sceneId,
                      messageId: message.id,
                      direction: -1,
                    ),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
        IconButton(
          key: Key('moveMessageDown_${message.id}'),
          tooltip: 'Move Message Down',
          onPressed: !canMoveLater
              ? null
              : () => ref
                    .read(projectsControllerProvider.notifier)
                    .moveMessageInOrder(
                      projectId: projectId,
                      sceneId: sceneId,
                      messageId: message.id,
                      direction: 1,
                    ),
          icon: const Icon(Icons.arrow_downward_rounded),
        ),
        PopupMenuButton<_MessageAction>(
          key: Key('messageActions_${message.id}'),
          onSelected: (action) async {
            switch (action) {
              case _MessageAction.editMessage:
                final updatedMessage = await _showEditMessageDialog(
                  context,
                  message: message,
                );
                if (updatedMessage == null) {
                  return;
                }

                final previousTimestamp = _previousSceneTimestamp(
                  currentMessages,
                );
                if (previousTimestamp != null &&
                    updatedMessage.timestampSeconds < previousTimestamp &&
                    context.mounted) {
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
                    .updateMessage(
                      projectId: projectId,
                      sceneId: sceneId,
                      messageId: message.id,
                      characterId: updatedMessage.characterId,
                      text: updatedMessage.text,
                      timestampSeconds: updatedMessage.timestampSeconds,
                      status: updatedMessage.status,
                      isIncoming: updatedMessage.isIncoming,
                      showTypingBefore: updatedMessage.showTypingBefore,
                    );
                return;
              case _MessageAction.delete:
                final confirmed = await _showDeleteMessageDialog(
                  context,
                  message: message,
                );
                if (!context.mounted || !confirmed) {
                  return;
                }

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
              value: _MessageAction.editMessage,
              child: Text('Edit Message'),
            ),
            PopupMenuItem(
              value: _MessageAction.delete,
              child: Text('Delete'),
            ),
          ],
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  Future<bool> _showDeleteMessageDialog(
    BuildContext context, {
    required Message message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: Text(
            'Delete this message? "${message.text}"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDeleteMessageButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  int? _previousSceneTimestamp(List<Message> currentMessages) {
    final currentIndex = currentMessages.indexWhere(
      (item) => item.id == message.id,
    );
    if (currentIndex <= 0) {
      return null;
    }

    return currentMessages[currentIndex - 1].timestampSeconds;
  }

  Future<_EditedMessageInput?> _showEditMessageDialog(
    BuildContext context, {
    required Message message,
  }) async {
    final textController = TextEditingController(text: message.text);
    final timestampController = TextEditingController(
      text: message.timestampSeconds.toString(),
    );
    var selectedCharacterId = message.characterId;
    var selectedStatus = message.status;
    var isIncoming = message.isIncoming;
    var showTypingBefore = message.showTypingBefore;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<_EditedMessageInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Message'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCharacterId,
                      decoration: const InputDecoration(labelText: 'Character'),
                      items: [
                        for (final character in characters)
                          DropdownMenuItem(
                            value: character.id,
                            child: Text(character.displayName),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCharacterId = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Text'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timestampController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Timestamp (seconds)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MessageStatus>(
                      initialValue: selectedStatus,
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
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isIncoming,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incoming'),
                      onChanged: (value) {
                        setState(() {
                          isIncoming = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      value: showTypingBefore,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show typing before'),
                      onChanged: (value) {
                        setState(() {
                          showTypingBefore = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsedTimestamp = int.tryParse(
                      timestampController.text.trim(),
                    );
                    final trimmedText = textController.text.trim();

                    if (parsedTimestamp == null) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Timestamp must be a valid number.'),
                        ),
                      );
                      return;
                    }

                    if (parsedTimestamp < 0) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Timestamp cannot be negative.'),
                        ),
                      );
                      return;
                    }

                    if (trimmedText.isEmpty) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Message text cannot be empty.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop(
                      _EditedMessageInput(
                        characterId: selectedCharacterId,
                        text: trimmedText,
                        timestampSeconds: parsedTimestamp,
                        status: selectedStatus,
                        isIncoming: isIncoming,
                        showTypingBefore: showTypingBefore,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }
}

enum _MessageAction { editMessage, delete }

class _EditedMessageInput {
  const _EditedMessageInput({
    required this.characterId,
    required this.text,
    required this.timestampSeconds,
    required this.status,
    required this.isIncoming,
    required this.showTypingBefore,
  });

  final String characterId;
  final String text;
  final int timestampSeconds;
  final MessageStatus status;
  final bool isIncoming;
  final bool showTypingBefore;
}

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

int _sceneMaxSecond(Scene scene) {
  if (scene.messages.isEmpty) {
    return 0;
  }

  var maxSecond = 0;
  for (final message in scene.messages) {
    if (message.timestampSeconds > maxSecond) {
      maxSecond = message.timestampSeconds;
    }
  }
  return maxSecond;
}

int _sceneCueCount(Scene scene) {
  if (scene.messages.isEmpty) {
    return 0;
  }

  final cueSeconds = <int>{};
  for (final message in scene.messages) {
    cueSeconds.add(message.timestampSeconds);
  }
  return cueSeconds.length;
}

int _sceneTypingCueCount(Scene scene) {
  var count = 0;
  for (final message in scene.messages) {
    if (message.showTypingBefore && message.timestampSeconds > 0) {
      count++;
    }
  }
  return count;
}

String _formatSceneDuration(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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
