import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/utils/file_picker/file_picker.dart';
import 'package:production_chat_prop/features/projects/data/services/project_package_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

final projectJsonFilePickerProvider = Provider<TextFilePicker>((ref) {
  return pickTextFile;
});

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  ProjectType? _selectedTypeFilter;
  _ProjectSortMode _selectedSortMode = _ProjectSortMode.updatedNewest;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onImportProjectJsonPressed() async {
    final rawJson = await _showImportDialog();
    if (rawJson == null) {
      return;
    }

    final result = await ref
        .read(projectsControllerProvider.notifier)
        .importProjectFromJson(rawJson);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_importResultMessage(result))),
    );
  }

  Future<void> _onImportProjectJsonFilePressed() async {
    final rawJson = await ref.read(projectJsonFilePickerProvider)();
    if (!mounted) {
      return;
    }
    if (rawJson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No JSON file selected.')));
      return;
    }

    final result = await ref
        .read(projectsControllerProvider.notifier)
        .importProjectFromJson(rawJson);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_importResultMessage(result))),
    );
  }

  Future<String?> _showImportDialog() async {
    var draftJson = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Project JSON'),
          content: SizedBox(
            width: 560,
            child: TextField(
              key: const Key('importProjectJsonField'),
              autofocus: true,
              minLines: 10,
              maxLines: 18,
              onChanged: (value) {
                draftJson = value;
              },
              decoration: const InputDecoration(
                labelText: 'Project JSON',
                alignLabelWithHint: true,
                hintText: '{\n  "name": "My project",\n  ...\n}',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftJson),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    return result;
  }

  String _importResultMessage(ProjectJsonImportResult result) {
    return switch (result.status) {
      ProjectJsonImportStatus.success =>
        'Imported project: ${result.importedProjectName}.',
      ProjectJsonImportStatus.emptyInput =>
        'Paste project JSON before importing.',
      ProjectJsonImportStatus.invalidJson =>
        'Invalid JSON format. Please paste valid JSON.',
      ProjectJsonImportStatus.invalidProjectPayload =>
        'JSON does not match the expected Project structure.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project List'),
        actions: [
          IconButton(
            key: const Key('importProjectJsonFileButton'),
            tooltip: 'Import JSON File',
            onPressed: _onImportProjectJsonFilePressed,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            key: const Key('importProjectJsonButton'),
            tooltip: 'Import Project JSON',
            onPressed: _onImportProjectJsonPressed,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            tooltip: 'Add Demo Project',
            onPressed: () => ref
                .read(projectsControllerProvider.notifier)
                .createDemoProject(),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(projectsControllerProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newProjectFab'),
        onPressed: () =>
            ref.read(projectsControllerProvider.notifier).createProject(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
      body: SafeArea(
        child: projectsState.when(
          data: (projects) {
            if (projects.isEmpty) {
              return _EmptyProjectState(
                onCreateProject: () => ref
                    .read(projectsControllerProvider.notifier)
                    .createProject(),
                onCreateDemoProject: () => ref
                    .read(projectsControllerProvider.notifier)
                    .createDemoProject(),
              );
            }

            final normalizedQuery = _searchQuery.trim().toLowerCase();
            final typeCounts = <ProjectType, int>{
              for (final type in ProjectType.values) type: 0,
            };
            for (final project in projects) {
              typeCounts[project.type] = (typeCounts[project.type] ?? 0) + 1;
            }
            final filteredProjects =
                projects
                    .where((project) {
                      final matchesQuery =
                          normalizedQuery.isEmpty ||
                          project.name.toLowerCase().contains(normalizedQuery);
                      final matchesType =
                          _selectedTypeFilter == null ||
                          project.type == _selectedTypeFilter;
                      return matchesQuery && matchesType;
                    })
                    .toList(growable: false)
                  ..sort(_projectSortComparator(_selectedSortMode));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    key: const Key('projectSearchField'),
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Projects',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          key: const Key('projectTypeFilter_all'),
                          label: Text('All (${projects.length})'),
                          selected: _selectedTypeFilter == null,
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _selectedTypeFilter = null;
                            });
                          },
                        ),
                        for (final type in ProjectType.values)
                          ChoiceChip(
                            key: Key('projectTypeFilter_${type.name}'),
                            label: Text(
                              '${_typeLabel(type)} (${typeCounts[type] ?? 0})',
                            ),
                            selected: _selectedTypeFilter == type,
                            onSelected: (selected) {
                              if (!selected) {
                                return;
                              }
                              setState(() {
                                _selectedTypeFilter = type;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<_ProjectSortMode>(
                          key: const Key('projectSortDropdown'),
                          initialValue: _selectedSortMode,
                          decoration: const InputDecoration(
                            labelText: 'Sort Projects',
                          ),
                          items: [
                            for (final sort in _ProjectSortMode.values)
                              DropdownMenuItem(
                                value: sort,
                                child: Text(_projectSortLabel(sort)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedSortMode = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: const Key('projectResetFiltersButton'),
                        onPressed: () {
                          setState(() {
                            _selectedTypeFilter = null;
                            _selectedSortMode = _ProjectSortMode.updatedNewest;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing ${filteredProjects.length} of ${projects.length} projects',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProjects.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No projects match current filters.'),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            return _ProjectCard(project: project);
                          },
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemCount: filteredProjects.length,
                        ),
                ),
              ],
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

String _typeLabel(ProjectType type) {
  return switch (type) {
    ProjectType.ad => 'Ad',
    ProjectType.series => 'Series',
    ProjectType.other => 'Other',
  };
}

enum _ProjectSortMode {
  updatedNewest,
  updatedOldest,
  nameAscending,
  nameDescending,
}

String _projectSortLabel(_ProjectSortMode mode) {
  return switch (mode) {
    _ProjectSortMode.updatedNewest => 'Updated (Newest)',
    _ProjectSortMode.updatedOldest => 'Updated (Oldest)',
    _ProjectSortMode.nameAscending => 'Name (A-Z)',
    _ProjectSortMode.nameDescending => 'Name (Z-A)',
  };
}

int Function(Project, Project) _projectSortComparator(_ProjectSortMode mode) {
  return switch (mode) {
    _ProjectSortMode.updatedNewest => (a, b) => b.updatedAt.compareTo(
      a.updatedAt,
    ),
    _ProjectSortMode.updatedOldest => (a, b) => a.updatedAt.compareTo(
      b.updatedAt,
    ),
    _ProjectSortMode.nameAscending => (a, b) => a.name.toLowerCase().compareTo(
      b.name.toLowerCase(),
    ),
    _ProjectSortMode.nameDescending => (a, b) => b.name.toLowerCase().compareTo(
      a.name.toLowerCase(),
    ),
  };
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
                      case _ProjectMenuAction.copyJson:
                        await _copyProjectJson(context, project);
                        return;
                      case _ProjectMenuAction.downloadJson:
                        await _downloadProjectJson(context, project);
                        return;
                      case _ProjectMenuAction.setTypeAd:
                        await controller.setProjectType(
                          projectId: project.id,
                          type: ProjectType.ad,
                        );
                        return;
                      case _ProjectMenuAction.setTypeSeries:
                        await controller.setProjectType(
                          projectId: project.id,
                          type: ProjectType.series,
                        );
                        return;
                      case _ProjectMenuAction.setTypeOther:
                        await controller.setProjectType(
                          projectId: project.id,
                          type: ProjectType.other,
                        );
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
                      value: _ProjectMenuAction.copyJson,
                      child: Text('Copy JSON'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.downloadJson,
                      child: Text('Download JSON'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.setTypeAd,
                      child: Text('Set Type: Ad'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.setTypeSeries,
                      child: Text('Set Type: Series'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.setTypeOther,
                      child: Text('Set Type: Other'),
                    ),
                    PopupMenuItem(
                      value: _ProjectMenuAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (_isDemoProject(project)) ...[
              const SizedBox(height: 8),
              const Chip(
                key: Key('demoProjectBadge'),
                avatar: Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('DEMO PRESET'),
              ),
            ],
            const SizedBox(height: 8),
            Text('Type: ${project.type.name}'),
            const SizedBox(height: 4),
            Text('Updated: ${_formatDateTime(project.updatedAt)}'),
            const SizedBox(height: 4),
            Text(
              'Scenes: ${project.scenes.length} • '
              'Messages: ${_projectMessageCount(project)} • '
              'Max: ${_projectMaxSecond(project)}s',
            ),
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

  Future<void> _copyProjectJson(BuildContext context, Project project) async {
    const encoder = JsonEncoder.withIndent('  ');
    final jsonText = encoder.convert(project.toJson());
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project JSON copied to clipboard.')),
    );
  }

  Future<void> _downloadProjectJson(
    BuildContext context,
    Project project,
  ) async {
    final service = ProjectPackageExportService();
    final result = await service.exportProjectPackage(project: project);
    if (!context.mounted) {
      return;
    }

    final message = result.isSuccess
        ? 'Project package exported: ${result.filename}.'
        : 'Project package export failed: download is not available on this platform.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState({
    required this.onCreateProject,
    required this.onCreateDemoProject,
  });

  final VoidCallback onCreateProject;
  final VoidCallback onCreateDemoProject;

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
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  key: const Key('emptyCreateProjectButton'),
                  onPressed: onCreateProject,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Project'),
                ),
                OutlinedButton.icon(
                  key: const Key('emptyCreateDemoButton'),
                  onPressed: onCreateDemoProject,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Load Demo Project'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectMenuAction {
  rename,
  duplicate,
  copyJson,
  downloadJson,
  setTypeAd,
  setTypeSeries,
  setTypeOther,
  delete,
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

bool _isDemoProject(Project project) {
  return project.name.startsWith('Demo Project');
}

int _projectMessageCount(Project project) {
  var total = 0;
  for (final scene in project.scenes) {
    total += scene.messages.length;
  }
  return total;
}

int _projectMaxSecond(Project project) {
  var maxSecond = 0;
  for (final scene in project.scenes) {
    for (final message in scene.messages) {
      if (message.timestampSeconds > maxSecond) {
        maxSecond = message.timestampSeconds;
      }
    }
  }
  return maxSecond;
}
