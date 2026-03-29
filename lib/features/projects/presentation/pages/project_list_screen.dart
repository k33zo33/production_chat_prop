import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(projectsControllerProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(projectsControllerProvider.notifier).createProject(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
      body: SafeArea(
        child: projectsState.when(
          data: (projects) {
            if (projects.isEmpty) {
              return const _EmptyProjectState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectCard(project: project);
              },
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemCount: projects.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded),
                    const SizedBox(height: 12),
                    const Text('Unable to load projects.'),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(projectsControllerProvider),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectsControllerProvider.notifier);

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
                    project.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PopupMenuButton<_ProjectMenuAction>(
                  onSelected: (action) async {
                    switch (action) {
                      case _ProjectMenuAction.rename:
                        final newName = await _showRenameDialog(
                          context,
                          project,
                        );
                        if (newName == null) {
                          return;
                        }

                        await controller.renameProject(
                          projectId: project.id,
                          newName: newName,
                        );
                        return;
                      case _ProjectMenuAction.duplicate:
                        await controller.duplicateProject(project.id);
                        return;
                      case _ProjectMenuAction.delete:
                        await controller.deleteProject(project.id);
                        return;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ProjectMenuAction.rename,
                      child: Text('Rename'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.duplicate,
                      child: Text('Duplicate'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: ${project.type.name}'),
            const SizedBox(height: 4),
            Text('Updated: ${_formatDateTime(project.updatedAt)}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.goNamed(
                    'editorProject',
                    pathParameters: {'projectId': project.id},
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Open Chat Editor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    'playbackProject',
                    pathParameters: {'projectId': project.id},
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Open Playback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    Project project,
  ) async {
    final controller = TextEditingController(text: project.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Project'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Project Name'),
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

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspaces_outline,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('No projects yet'),
            const SizedBox(height: 4),
            const Text(
              'Create your first project to start editing a chat scene.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectMenuAction { rename, duplicate, delete }

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
