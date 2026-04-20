import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/utils/file_picker/file_picker.dart';
import 'package:production_chat_prop/features/projects/data/services/project_package_export_service.dart';
import 'package:production_chat_prop/features/projects/data/services/project_portfolio_export_service.dart';
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
  bool _isSelectionMode = false;
  Set<String> _selectedProjectIds = <String>{};

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

  Set<String> _selectedIdsForProjects(List<Project> projects) {
    final availableIds = projects.map((project) => project.id).toSet();
    return _selectedProjectIds.where(availableIds.contains).toSet();
  }

  void _toggleSelectionMode(List<Project> projects) {
    if (projects.isEmpty) {
      return;
    }
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProjectIds = <String>{};
      }
    });
  }

  void _clearProjectSelection({required bool exitMode}) {
    setState(() {
      _selectedProjectIds = <String>{};
      if (exitMode) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllProjects(List<Project> projects) {
    if (projects.isEmpty) {
      return;
    }
    setState(() {
      _isSelectionMode = true;
      _selectedProjectIds = projects.map((project) => project.id).toSet();
    });
  }

  void _setProjectSelected({
    required String projectId,
    required bool isSelected,
  }) {
    setState(() {
      final nextSelection = <String>{..._selectedProjectIds};
      if (isSelected) {
        nextSelection.add(projectId);
      } else {
        nextSelection.remove(projectId);
      }
      _selectedProjectIds = nextSelection;
      if (_selectedProjectIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _onImportProjectJsonPressed() async {
    final rawJson = await _showImportDialog();
    if (rawJson == null) {
      return;
    }
    await _runJsonImportFlow(rawJson);
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
    await _runJsonImportFlow(rawJson);
  }

  Future<void> _onExportAllProjectsPressed() async {
    final projects = await ref.read(projectsControllerProvider.future);
    if (!mounted) {
      return;
    }

    final service = ProjectPortfolioExportService();
    final result = await service.exportPortfolio(projects: projects);
    if (!mounted) {
      return;
    }
    if (result.failure == ProjectPortfolioExportFailure.downloadUnavailable) {
      final copied = await _copyTextToClipboard(
        service.buildPortfolioJson(projects: projects),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? 'Download unavailable. Project portfolio JSON copied to clipboard.'
                : _portfolioExportResultMessage(result),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_portfolioExportResultMessage(result))),
    );
  }

  Future<void> _onExportSelectedProjectsPressed(List<Project> projects) async {
    final selectedIds = _selectedIdsForProjects(projects);
    final selectedProjects = projects
        .where((project) => selectedIds.contains(project.id))
        .toList(growable: false);
    if (selectedProjects.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects to export.')),
      );
      return;
    }

    final service = ProjectPortfolioExportService();
    final result = await service.exportPortfolio(projects: selectedProjects);
    if (!mounted) {
      return;
    }
    if (result.failure == ProjectPortfolioExportFailure.downloadUnavailable) {
      final copied = await _copyTextToClipboard(
        service.buildPortfolioJson(projects: selectedProjects),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? 'Download unavailable. Selected project JSON copied to clipboard.'
                : _selectedPortfolioExportResultMessage(result),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_selectedPortfolioExportResultMessage(result))),
    );
  }

  Future<bool> _copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _onDeleteSelectedProjectsPressed(List<Project> projects) async {
    final selectedIds = _selectedIdsForProjects(projects);
    if (selectedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects to delete.')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete ${selectedIds.length} selected project${selectedIds.length == 1 ? '' : 's'}?',
          ),
          content: const Text(
            'This action removes selected projects from local storage.',
          ),
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
    if (!mounted || shouldDelete != true) {
      return;
    }

    final removedCount = await ref
        .read(projectsControllerProvider.notifier)
        .deleteProjectsByIds(selectedIds);
    if (!mounted) {
      return;
    }

    _clearProjectSelection(exitMode: true);
    if (removedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects were deleted.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $removedCount selected project${removedCount == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  Future<void> _onDuplicateSelectedProjectsPressed(
    List<Project> projects,
  ) async {
    final selectedIds = _selectedIdsForProjects(projects);
    if (selectedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects to duplicate.')),
      );
      return;
    }

    final duplicatedCount = await ref
        .read(projectsControllerProvider.notifier)
        .duplicateProjectsByIds(selectedIds);
    if (!mounted) {
      return;
    }
    if (duplicatedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects were duplicated.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Duplicated $duplicatedCount selected project${duplicatedCount == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  Future<void> _onSetSelectedProjectsType({
    required List<Project> projects,
    required ProjectType type,
  }) async {
    final selectedIds = _selectedIdsForProjects(projects);
    if (selectedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected projects to update.')),
      );
      return;
    }

    final updatedCount = await ref
        .read(projectsControllerProvider.notifier)
        .setProjectTypeByIds(projectIds: selectedIds, type: type);
    if (!mounted) {
      return;
    }
    if (updatedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected projects are already type ${type.name}.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated $updatedCount selected project${updatedCount == 1 ? '' : 's'} to type ${type.name}.',
        ),
      ),
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

  Future<void> _runJsonImportFlow(String rawJson) async {
    final controller = ref.read(projectsControllerProvider.notifier);
    final preview = await controller.previewProjectImportFromJson(rawJson);
    if (!mounted) {
      return;
    }
    if (preview.status != ProjectJsonImportPreviewStatus.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_importPreviewErrorMessage(preview))),
      );
      return;
    }

    final shouldImport = await _showImportPreviewDialog(preview);
    if (!mounted || !shouldImport) {
      return;
    }

    final result = await controller.importProjectFromJson(rawJson);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_importResultMessage(result))),
    );
  }

  Future<bool> _showImportPreviewDialog(
    ProjectJsonImportPreviewResult preview,
  ) async {
    final projectedNames = preview.projectedNames;
    final previewNames = projectedNames.take(5).toList(growable: false);
    final hasMore = projectedNames.length > previewNames.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Import ${preview.importableCount} project${preview.importableCount == 1 ? '' : 's'}?',
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Projects that will be imported:'),
                const SizedBox(height: 8),
                for (final name in previewNames)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $name'),
                  ),
                if (hasMore)
                  Text(
                    '• +${projectedNames.length - previewNames.length} more',
                  ),
                if (preview.invalidCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Invalid entries to skip: ${preview.invalidCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmImportFromJsonButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _importPreviewErrorMessage(ProjectJsonImportPreviewResult preview) {
    return switch (preview.status) {
      ProjectJsonImportPreviewStatus.emptyInput =>
        'Paste project JSON before importing.',
      ProjectJsonImportPreviewStatus.invalidJson =>
        'Invalid JSON format. Please paste valid JSON.',
      ProjectJsonImportPreviewStatus.invalidProjectPayload =>
        'JSON does not match the expected Project structure.',
      ProjectJsonImportPreviewStatus.ready => '',
    };
  }

  String _importResultMessage(ProjectJsonImportResult result) {
    return switch (result.status) {
      ProjectJsonImportStatus.success => _buildImportSuccessMessage(result),
      ProjectJsonImportStatus.emptyInput =>
        'Paste project JSON before importing.',
      ProjectJsonImportStatus.invalidJson =>
        'Invalid JSON format. Please paste valid JSON.',
      ProjectJsonImportStatus.invalidProjectPayload =>
        'JSON does not match the expected Project structure.',
    };
  }

  String _buildImportSuccessMessage(ProjectJsonImportResult result) {
    final importedCount = result.importedCount;
    final skippedCount = result.skippedCount;
    if (importedCount == 1 && result.importedProjectName != null) {
      if (skippedCount == 0) {
        return 'Imported project: ${result.importedProjectName}.';
      }
      return 'Imported project: ${result.importedProjectName}. Skipped $skippedCount invalid entr${skippedCount == 1 ? 'y' : 'ies'}.';
    }
    if (skippedCount == 0) {
      return 'Imported $importedCount projects.';
    }
    return 'Imported $importedCount projects and skipped $skippedCount invalid entr${skippedCount == 1 ? 'y' : 'ies'}.';
  }

  String _portfolioExportResultMessage(ProjectPortfolioExportResult result) {
    if (result.isSuccess) {
      return 'Project portfolio exported: ${result.filename}.';
    }

    return switch (result.failure) {
      ProjectPortfolioExportFailure.noProjects =>
        'No projects available to export.',
      ProjectPortfolioExportFailure.downloadUnavailable =>
        'Project portfolio export failed: download is not available on this platform.',
      null => 'Project portfolio export failed.',
    };
  }

  String _selectedPortfolioExportResultMessage(
    ProjectPortfolioExportResult result,
  ) {
    if (result.isSuccess) {
      return 'Selected projects exported: ${result.filename}.';
    }

    return switch (result.failure) {
      ProjectPortfolioExportFailure.noProjects =>
        'No selected projects to export.',
      ProjectPortfolioExportFailure.downloadUnavailable =>
        'Selected project export failed: download is not available on this platform.',
      null => 'Selected project export failed.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsControllerProvider);
    final loadedProjects = projectsState.when(
      data: (projects) => projects,
      loading: () => const <Project>[],
      error: (_, _) => const <Project>[],
    );
    final selectedIds = _selectedIdsForProjects(loadedProjects);
    final selectedCount = selectedIds.length;
    final showSelectionMode = _isSelectionMode && loadedProjects.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: showSelectionMode
            ? IconButton(
                key: const Key('exitProjectSelectionModeButton'),
                tooltip: 'Exit Selection',
                onPressed: () => _clearProjectSelection(exitMode: true),
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        title: Text(
          showSelectionMode
              ? selectedCount == 0
                    ? 'Select Projects'
                    : '$selectedCount selected'
              : 'Project List',
        ),
        actions: showSelectionMode
            ? [
                IconButton(
                  key: const Key('selectAllProjectsButton'),
                  tooltip: 'Select All Projects',
                  onPressed: selectedCount == loadedProjects.length
                      ? null
                      : () => _selectAllProjects(loadedProjects),
                  icon: const Icon(Icons.select_all_rounded),
                ),
                IconButton(
                  key: const Key('clearProjectSelectionButton'),
                  tooltip: 'Clear Selection',
                  onPressed: selectedCount == 0
                      ? null
                      : () => _clearProjectSelection(exitMode: false),
                  icon: const Icon(Icons.deselect_rounded),
                ),
                IconButton(
                  key: const Key('duplicateSelectedProjectsButton'),
                  tooltip: 'Duplicate Selected Projects',
                  onPressed: selectedCount == 0
                      ? null
                      : () => _onDuplicateSelectedProjectsPressed(
                          loadedProjects,
                        ),
                  icon: const Icon(Icons.copy_all_rounded),
                ),
                PopupMenuButton<ProjectType>(
                  key: const Key('setSelectedProjectsTypeButton'),
                  tooltip: 'Set Selected Type',
                  enabled: selectedCount > 0,
                  onSelected: (type) async {
                    await _onSetSelectedProjectsType(
                      projects: loadedProjects,
                      type: type,
                    );
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ProjectType.ad,
                      child: Text('Set Type: Ad'),
                    ),
                    PopupMenuItem(
                      value: ProjectType.series,
                      child: Text('Set Type: Series'),
                    ),
                    PopupMenuItem(
                      value: ProjectType.other,
                      child: Text('Set Type: Other'),
                    ),
                  ],
                  icon: const Icon(Icons.label_rounded),
                ),
                IconButton(
                  key: const Key('exportSelectedProjectsJsonButton'),
                  tooltip: 'Export Selected Projects JSON',
                  onPressed: selectedCount == 0
                      ? null
                      : () => _onExportSelectedProjectsPressed(loadedProjects),
                  icon: const Icon(Icons.download_rounded),
                ),
                IconButton(
                  key: const Key('deleteSelectedProjectsButton'),
                  tooltip: 'Delete Selected Projects',
                  onPressed: selectedCount == 0
                      ? null
                      : () => _onDeleteSelectedProjectsPressed(loadedProjects),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ]
            : [
                IconButton(
                  key: const Key('toggleProjectSelectionModeButton'),
                  tooltip: 'Select Projects',
                  onPressed: loadedProjects.isEmpty
                      ? null
                      : () => _toggleSelectionMode(loadedProjects),
                  icon: const Icon(Icons.checklist_rounded),
                ),
                IconButton(
                  key: const Key('exportAllProjectsJsonButton'),
                  tooltip: 'Export All Projects JSON',
                  onPressed: _onExportAllProjectsPressed,
                  icon: const Icon(Icons.download_for_offline_outlined),
                ),
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
      floatingActionButton: showSelectionMode
          ? null
          : FloatingActionButton.extended(
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
            final selectedIdsForCurrentProjects = _selectedIdsForProjects(
              projects,
            );
            final readinessSummary = _buildProjectPortfolioReadinessSummary(
              filteredProjects,
            );

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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio Readiness',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            key: const Key('projectPortfolioReadinessSummary'),
                            'Projects: ${filteredProjects.length} • '
                            'Ready scenes: ${readinessSummary.readyScenes}/${readinessSummary.totalScenes} • '
                            'Empty scenes: ${readinessSummary.emptyScenes} • '
                            'Messages: ${readinessSummary.totalMessages}',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                key: const Key('projectPortfolioReadyChip'),
                                avatar: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  '${readinessSummary.readyProjectCount} ready projects',
                                ),
                              ),
                              Chip(
                                key: const Key(
                                  'projectPortfolioNeedsAttentionChip',
                                ),
                                avatar: const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  '${readinessSummary.needsAttentionProjectCount} need attention',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                key: const Key(
                                  'portfolioContinueEditingButton',
                                ),
                                onPressed:
                                    readinessSummary.primaryProjectId == null
                                    ? null
                                    : () => context.goNamed(
                                        'editorProject',
                                        pathParameters: {
                                          'projectId': readinessSummary
                                              .primaryProjectId!,
                                        },
                                      ),
                                icon: const Icon(Icons.edit_note_rounded),
                                label: const Text('Continue Editing'),
                              ),
                              OutlinedButton.icon(
                                key: const Key('portfolioPreviewReadyButton'),
                                onPressed:
                                    readinessSummary.firstReadyProjectId == null
                                    ? null
                                    : () => context.goNamed(
                                        'playbackProject',
                                        pathParameters: {
                                          'projectId': readinessSummary
                                              .firstReadyProjectId!,
                                        },
                                      ),
                                icon: const Icon(
                                  Icons.play_circle_outline_rounded,
                                ),
                                label: const Text('Preview Ready Project'),
                              ),
                              OutlinedButton.icon(
                                key: const Key(
                                  'portfolioReviewAttentionButton',
                                ),
                                onPressed:
                                    readinessSummary
                                            .firstNeedsAttentionProjectId ==
                                        null
                                    ? null
                                    : () => context.goNamed(
                                        'editorProject',
                                        pathParameters: {
                                          'projectId': readinessSummary
                                              .firstNeedsAttentionProjectId!,
                                        },
                                      ),
                                icon: const Icon(Icons.rule_folder_outlined),
                                label: const Text('Review Attention Project'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isSelectionMode
                          ? 'Selected ${selectedIdsForCurrentProjects.length} of ${projects.length} projects'
                          : 'Showing ${filteredProjects.length} of ${projects.length} projects',
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            return _ProjectCard(
                              project: project,
                              selectionMode: _isSelectionMode,
                              isSelected: selectedIdsForCurrentProjects
                                  .contains(project.id),
                              onSelectionChanged: (isSelected) {
                                _setProjectSelected(
                                  projectId: project.id,
                                  isSelected: isSelected,
                                );
                              },
                            );
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

class _ProjectCard extends ConsumerStatefulWidget {
  const _ProjectCard({
    required this.project,
    required this.selectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  final Project project;
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  ConsumerState<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends ConsumerState<_ProjectCard> {
  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final selectionMode = widget.selectionMode;
    final isSelected = widget.isSelected;
    final onSelectionChanged = widget.onSelectionChanged;
    final controller = ref.read(projectsControllerProvider.notifier);

    return Card(
      key: Key('projectCard_${project.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    key: Key('projectSelectionCheckbox_${project.id}'),
                    value: isSelected,
                    onChanged: (value) {
                      onSelectionChanged(value ?? false);
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!selectionMode)
                  PopupMenuButton<_ProjectMenuAction>(
                    tooltip: 'Project Menu',
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
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        key: Key('projectMenuRename_${project.id}'),
                        value: _ProjectMenuAction.rename,
                        child: const ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Rename'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuDuplicate_${project.id}'),
                        value: _ProjectMenuAction.duplicate,
                        child: const ListTile(
                          leading: Icon(Icons.copy_rounded),
                          title: Text('Duplicate'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuCopyJson_${project.id}'),
                        value: _ProjectMenuAction.copyJson,
                        child: const ListTile(
                          leading: Icon(Icons.content_copy_rounded),
                          title: Text('Copy JSON'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuDownloadJson_${project.id}'),
                        value: _ProjectMenuAction.downloadJson,
                        child: const ListTile(
                          leading: Icon(Icons.download_rounded),
                          title: Text('Download JSON'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuSetTypeAd_${project.id}'),
                        value: _ProjectMenuAction.setTypeAd,
                        child: const ListTile(
                          leading: Icon(Icons.campaign_rounded),
                          title: Text('Set Type: Ad'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuSetTypeSeries_${project.id}'),
                        value: _ProjectMenuAction.setTypeSeries,
                        child: const ListTile(
                          leading: Icon(Icons.live_tv_rounded),
                          title: Text('Set Type: Series'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuSetTypeOther_${project.id}'),
                        value: _ProjectMenuAction.setTypeOther,
                        child: const ListTile(
                          leading: Icon(Icons.category_rounded),
                          title: Text('Set Type: Other'),
                        ),
                      ),
                      PopupMenuItem(
                        key: Key('projectMenuDelete_${project.id}'),
                        value: _ProjectMenuAction.delete,
                        child: const ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      key: Key('projectMenuButton_${project.id}'),
                    ),
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
            const SizedBox(height: 4),
            Text(
              key: Key('projectPlaybackSummary_${project.id}'),
              'Playback: '
              '${_projectReadySceneCount(project)}/${project.scenes.length} ready • '
              '${_projectEmptySceneCount(project)} empty • '
              '${_projectStyleCount(project)} style${_projectStyleCount(project) == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            Chip(
              key: Key('projectAttentionReason_${project.id}'),
              avatar: Icon(
                _projectAttentionState(project).icon,
                size: 18,
              ),
              label: Text(_projectAttentionState(project).label),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: Key('projectAttentionCta_${project.id}'),
              onPressed: selectionMode
                  ? null
                  : () => _projectAttentionState(
                      project,
                    ).onPressed(context, project),
              icon: Icon(_projectAttentionState(project).ctaIcon),
              label: Text(_projectAttentionState(project).ctaLabel),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: Key('projectOpenEditor_${project.id}'),
                  onPressed: selectionMode
                      ? null
                      : () => context.goNamed(
                          'editorProject',
                          pathParameters: {'projectId': project.id},
                        ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Open Chat Editor'),
                ),
                OutlinedButton.icon(
                  key: Key('projectOpenPlayback_${project.id}'),
                  onPressed: selectionMode
                      ? null
                      : () => context.goNamed(
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

int _projectReadySceneCount(Project project) {
  var count = 0;
  for (final scene in project.scenes) {
    if (scene.messages.isNotEmpty) {
      count++;
    }
  }
  return count;
}

int _projectEmptySceneCount(Project project) {
  var count = 0;
  for (final scene in project.scenes) {
    if (scene.messages.isEmpty) {
      count++;
    }
  }
  return count;
}

int _projectStyleCount(Project project) {
  final styleIds = <String>{};
  for (final scene in project.scenes) {
    styleIds.add(scene.styleId);
  }
  return styleIds.length;
}

_ProjectAttentionState _projectAttentionState(Project project) {
  final totalMessages = _projectMessageCount(project);
  final emptySceneCount = _projectEmptySceneCount(project);

  if (totalMessages == 0) {
    return const _ProjectAttentionState(
      label: 'No messages yet',
      icon: Icons.chat_bubble_outline_rounded,
      ctaLabel: 'Add First Message',
      ctaIcon: Icons.edit_note_rounded,
      intent: _ProjectAttentionIntent.openEditor,
    );
  }

  if (emptySceneCount > 0) {
    return const _ProjectAttentionState(
      label: 'Has empty scenes',
      icon: Icons.error_outline_rounded,
      ctaLabel: 'Finish Empty Scenes',
      ctaIcon: Icons.build_circle_outlined,
      intent: _ProjectAttentionIntent.openEditor,
    );
  }

  return const _ProjectAttentionState(
    label: 'Ready for playback',
    icon: Icons.check_circle_outline_rounded,
    ctaLabel: 'Open Playback',
    ctaIcon: Icons.play_circle_outline_rounded,
    intent: _ProjectAttentionIntent.openPlayback,
  );
}

class _ProjectAttentionState {
  const _ProjectAttentionState({
    required this.label,
    required this.icon,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.intent,
  });

  final String label;
  final IconData icon;
  final String ctaLabel;
  final IconData ctaIcon;
  final _ProjectAttentionIntent intent;

  void onPressed(BuildContext context, Project project) {
    switch (intent) {
      case _ProjectAttentionIntent.openEditor:
        context.goNamed(
          'editorProject',
          pathParameters: {'projectId': project.id},
        );
        return;
      case _ProjectAttentionIntent.openPlayback:
        context.goNamed(
          'playbackProject',
          pathParameters: {'projectId': project.id},
        );
        return;
    }
  }
}

enum _ProjectAttentionIntent {
  openEditor,
  openPlayback,
}

_ProjectPortfolioReadinessSummary _buildProjectPortfolioReadinessSummary(
  List<Project> projects,
) {
  var totalScenes = 0;
  var readyScenes = 0;
  var emptyScenes = 0;
  var totalMessages = 0;
  var readyProjectCount = 0;
  var needsAttentionProjectCount = 0;
  String? primaryProjectId;
  String? firstReadyProjectId;
  String? firstNeedsAttentionProjectId;

  for (final project in projects) {
    var projectHasEmptyScene = false;
    var projectHasMessages = false;
    totalScenes += project.scenes.length;
    for (final scene in project.scenes) {
      totalMessages += scene.messages.length;
      if (scene.messages.isEmpty) {
        emptyScenes++;
        projectHasEmptyScene = true;
      } else {
        readyScenes++;
        projectHasMessages = true;
      }
    }

    if (projectHasMessages && !projectHasEmptyScene) {
      readyProjectCount++;
      firstReadyProjectId ??= project.id;
    } else {
      needsAttentionProjectCount++;
      firstNeedsAttentionProjectId ??= project.id;
    }

    if (primaryProjectId == null) {
      if (projectHasEmptyScene || !projectHasMessages) {
        primaryProjectId = project.id;
      } else {
        primaryProjectId = project.id;
      }
    }
  }

  return _ProjectPortfolioReadinessSummary(
    totalScenes: totalScenes,
    readyScenes: readyScenes,
    emptyScenes: emptyScenes,
    totalMessages: totalMessages,
    readyProjectCount: readyProjectCount,
    needsAttentionProjectCount: needsAttentionProjectCount,
    primaryProjectId: primaryProjectId,
    firstReadyProjectId: firstReadyProjectId,
    firstNeedsAttentionProjectId: firstNeedsAttentionProjectId,
  );
}

class _ProjectPortfolioReadinessSummary {
  const _ProjectPortfolioReadinessSummary({
    required this.totalScenes,
    required this.readyScenes,
    required this.emptyScenes,
    required this.totalMessages,
    required this.readyProjectCount,
    required this.needsAttentionProjectCount,
    required this.primaryProjectId,
    required this.firstReadyProjectId,
    required this.firstNeedsAttentionProjectId,
  });

  final int totalScenes;
  final int readyScenes;
  final int emptyScenes;
  final int totalMessages;
  final int readyProjectCount;
  final int needsAttentionProjectCount;
  final String? primaryProjectId;
  final String? firstReadyProjectId;
  final String? firstNeedsAttentionProjectId;
}
