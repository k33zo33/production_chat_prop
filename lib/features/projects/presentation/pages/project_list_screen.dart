import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/utils/display_labels.dart';
import 'package:production_chat_prop/core/utils/file_picker/file_picker.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/app_content_frame.dart';
import 'package:production_chat_prop/core/widgets/responsive_alert_dialog.dart';
import 'package:production_chat_prop/features/projects/data/services/project_package_export_service.dart';
import 'package:production_chat_prop/features/projects/data/services/project_portfolio_export_service.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

final projectJsonFilePickerProvider = Provider<TextFilePicker>((ref) {
  return pickTextFile;
});

const _kExportQaFixtureAssetPath = 'docs/fixtures/export-qa-project.json';

final exportQaFixtureLoaderProvider = Provider<Future<String> Function()>((
  ref,
) {
  return () => rootBundle.loadString(_kExportQaFixtureAssetPath);
});

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key, this.forceCompactAppBar});

  final bool? forceCompactAppBar;

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

  void _showProjectListSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      _showProjectListSnackBar('No JSON file selected.');
      return;
    }
    await _runJsonImportFlow(rawJson);
  }

  Future<void> _onLoadExportQaProjectPressed() async {
    String rawJson;
    try {
      rawJson = await ref.read(exportQaFixtureLoaderProvider)();
    } on Object {
      if (!mounted) {
        return;
      }
      _showProjectListSnackBar('Unable to load the bundled export QA project.');
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final result = await ref
          .read(projectsControllerProvider.notifier)
          .importProjectFromJson(rawJson);
      if (!mounted) {
        return;
      }
      _showProjectListSnackBar(_importResultMessage(result));
    } on Object {
      if (!mounted) {
        return;
      }
      _showProjectListSnackBar(
        'Bundled export QA project could not be imported.',
      );
    }
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
      _showProjectListSnackBar(
        copied
            ? 'Download unavailable. Project portfolio JSON copied to clipboard.'
            : _portfolioExportResultMessage(result),
      );
      return;
    }

    _showProjectListSnackBar(_portfolioExportResultMessage(result));
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
      _showProjectListSnackBar('No selected projects to export.');
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
      _showProjectListSnackBar(
        copied
            ? 'Download unavailable. Selected project JSON copied to clipboard.'
            : _selectedPortfolioExportResultMessage(result),
      );
      return;
    }
    _showProjectListSnackBar(_selectedPortfolioExportResultMessage(result));
  }

  Future<bool> _copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } on PlatformException {
      return false;
    }
  }

  void _openProjectEditor(
    Project project, {
    bool preferAttentionScene = false,
  }) {
    final targetSceneId = preferAttentionScene
        ? _projectAttentionSceneId(project)
        : null;

    context.goNamed(
      'editorProject',
      pathParameters: {'projectId': project.id},
      queryParameters: targetSceneId == null
          ? const <String, String>{}
          : {'sceneId': targetSceneId},
    );
  }

  void _openProjectPlayback(Project project) {
    _goToProjectPlayback(context, project);
  }

  Future<void> _onDeleteSelectedProjectsPressed(List<Project> projects) async {
    final selectedIds = _selectedIdsForProjects(projects);
    if (selectedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      _showProjectListSnackBar('No selected projects to delete.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ResponsiveAlertDialog(
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
      _showProjectListSnackBar('No selected projects were deleted.');
      return;
    }

    _showProjectListSnackBar(
      'Deleted $removedCount selected project${removedCount == 1 ? '' : 's'}.',
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
      _showProjectListSnackBar('No selected projects to duplicate.');
      return;
    }

    final duplicatedCount = await ref
        .read(projectsControllerProvider.notifier)
        .duplicateProjectsByIds(selectedIds);
    if (!mounted) {
      return;
    }
    if (duplicatedCount == 0) {
      _showProjectListSnackBar('No selected projects were duplicated.');
      return;
    }
    _showProjectListSnackBar(
      'Duplicated $duplicatedCount selected project${duplicatedCount == 1 ? '' : 's'}.',
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
      _showProjectListSnackBar('No selected projects to update.');
      return;
    }

    final updatedCount = await ref
        .read(projectsControllerProvider.notifier)
        .setProjectTypeByIds(projectIds: selectedIds, type: type);
    if (!mounted) {
      return;
    }
    if (updatedCount == 0) {
      _showProjectListSnackBar(
        'Selected projects are already type ${type.label}.',
      );
      return;
    }

    _showProjectListSnackBar(
      'Updated $updatedCount selected project${updatedCount == 1 ? '' : 's'} to type ${type.label}.',
    );
  }

  Future<String?> _showImportDialog() async {
    var draftJson = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return ResponsiveAlertDialog(
          title: const Text('Import Project JSON'),
          content: TextField(
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
      _showProjectListSnackBar(_importPreviewErrorMessage(preview));
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
    _showProjectListSnackBar(_importResultMessage(result));
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
        return ResponsiveAlertDialog(
          title: Text(
            'Import ${preview.importableCount} project${preview.importableCount == 1 ? '' : 's'}?',
          ),
          content: Column(
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

  List<Widget> _buildDefaultAppBarActions({
    required BuildContext context,
    required List<Project> loadedProjects,
    required bool isCompactAppBar,
  }) {
    if (!isCompactAppBar) {
      return [
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
          onPressed: () =>
              ref.read(projectsControllerProvider.notifier).createDemoProject(),
          icon: const Icon(Icons.auto_awesome_rounded),
        ),
        IconButton(
          key: const Key('loadExportQaProjectButton'),
          tooltip: 'Load Export QA Project',
          onPressed: _onLoadExportQaProjectPressed,
          icon: const Icon(Icons.fact_check_outlined),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(projectsControllerProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ];
    }

    return [
      PopupMenuButton<_ProjectListAppBarAction>(
        key: const Key('projectListOverflowMenuButton'),
        tooltip: 'More project actions',
        onSelected: (action) async {
          switch (action) {
            case _ProjectListAppBarAction.selectProjects:
              _toggleSelectionMode(loadedProjects);
            case _ProjectListAppBarAction.exportAll:
              await _onExportAllProjectsPressed();
            case _ProjectListAppBarAction.importFile:
              await _onImportProjectJsonFilePressed();
            case _ProjectListAppBarAction.importJson:
              await _onImportProjectJsonPressed();
            case _ProjectListAppBarAction.loadExportQa:
              await _onLoadExportQaProjectPressed();
            case _ProjectListAppBarAction.addDemo:
              await ref
                  .read(projectsControllerProvider.notifier)
                  .createDemoProject();
            case _ProjectListAppBarAction.refresh:
              ref.invalidate(projectsControllerProvider);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ProjectListAppBarAction.selectProjects,
            enabled: loadedProjects.isNotEmpty,
            child: const Text('Select Projects'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.exportAll,
            child: Text('Export All Projects JSON'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.importFile,
            child: Text('Import JSON File'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.importJson,
            child: Text('Import Project JSON'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.loadExportQa,
            child: Text('Load Export QA Project'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.addDemo,
            child: Text('Add Demo Project'),
          ),
          const PopupMenuItem(
            value: _ProjectListAppBarAction.refresh,
            child: Text('Refresh'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSelectionModeActions({
    required BuildContext context,
    required List<Project> loadedProjects,
    required int selectedCount,
    required bool isCompactAppBar,
  }) {
    if (!isCompactAppBar) {
      return [
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
              : () => _onDuplicateSelectedProjectsPressed(loadedProjects),
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
      ];
    }

    return [
      PopupMenuButton<_ProjectSelectionAction>(
        key: const Key('projectSelectionOverflowMenuButton'),
        tooltip: 'Selected project actions',
        onSelected: (action) async {
          switch (action) {
            case _ProjectSelectionAction.selectAll:
              _selectAllProjects(loadedProjects);
            case _ProjectSelectionAction.clear:
              _clearProjectSelection(exitMode: false);
            case _ProjectSelectionAction.duplicate:
              await _onDuplicateSelectedProjectsPressed(loadedProjects);
            case _ProjectSelectionAction.setTypeAd:
              await _onSetSelectedProjectsType(
                projects: loadedProjects,
                type: ProjectType.ad,
              );
            case _ProjectSelectionAction.setTypeSeries:
              await _onSetSelectedProjectsType(
                projects: loadedProjects,
                type: ProjectType.series,
              );
            case _ProjectSelectionAction.setTypeOther:
              await _onSetSelectedProjectsType(
                projects: loadedProjects,
                type: ProjectType.other,
              );
            case _ProjectSelectionAction.exportSelected:
              await _onExportSelectedProjectsPressed(loadedProjects);
            case _ProjectSelectionAction.deleteSelected:
              await _onDeleteSelectedProjectsPressed(loadedProjects);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ProjectSelectionAction.selectAll,
            enabled: selectedCount != loadedProjects.length,
            child: const Text('Select All Projects'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.clear,
            enabled: selectedCount > 0,
            child: const Text('Clear Selection'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.duplicate,
            enabled: selectedCount > 0,
            child: const Text('Duplicate Selected Projects'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.setTypeAd,
            enabled: selectedCount > 0,
            child: const Text('Set Type: Ad'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.setTypeSeries,
            enabled: selectedCount > 0,
            child: const Text('Set Type: Series'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.setTypeOther,
            enabled: selectedCount > 0,
            child: const Text('Set Type: Other'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.exportSelected,
            enabled: selectedCount > 0,
            child: const Text('Export Selected Projects JSON'),
          ),
          PopupMenuItem(
            value: _ProjectSelectionAction.deleteSelected,
            enabled: selectedCount > 0,
            child: const Text('Delete Selected Projects'),
          ),
        ],
      ),
    ];
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
    final isCompactAppBar =
        widget.forceCompactAppBar ?? MediaQuery.sizeOf(context).width < 720;

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
            ? _buildSelectionModeActions(
                context: context,
                loadedProjects: loadedProjects,
                selectedCount: selectedCount,
                isCompactAppBar: isCompactAppBar,
              )
            : _buildDefaultAppBarActions(
                context: context,
                loadedProjects: loadedProjects,
                isCompactAppBar: isCompactAppBar,
              ),
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
        child: AppContentFrame(
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
                  onLoadExportQaProject: _onLoadExportQaProjectPressed,
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
                            project.name.toLowerCase().contains(
                              normalizedQuery,
                            );
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

              Project? findProjectById(String? projectId) {
                if (projectId == null) {
                  return null;
                }
                for (final project in filteredProjects) {
                  if (project.id == projectId) {
                    return project;
                  }
                }
                return null;
              }

              final primaryProject = findProjectById(
                readinessSummary.primaryProjectId,
              );
              final previewReadyProject = findProjectById(
                readinessSummary.firstReadyProjectId,
              );
              final attentionProject = findProjectById(
                readinessSummary.firstNeedsAttentionProjectId,
              );

              final headerContent = <Widget>[
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
                  child: MediaQuery.sizeOf(context).width < 560
                      ? KeyedSubtree(
                          key: const Key('projectTypeFilterDropdown'),
                          child: DropdownButtonFormField<ProjectType?>(
                            key: ValueKey<String>(
                              'projectTypeFilterField_${_selectedTypeFilter?.name ?? 'all'}',
                            ),
                            isExpanded: true,
                            initialValue: _selectedTypeFilter,
                            decoration: const InputDecoration(
                              labelText: 'Project Type',
                            ),
                            items: [
                              DropdownMenuItem<ProjectType?>(
                                child: Text('All (${projects.length})'),
                              ),
                              for (final type in ProjectType.values)
                                DropdownMenuItem<ProjectType?>(
                                  value: type,
                                  child: Text(
                                    '${type.label} (${typeCounts[type] ?? 0})',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeFilter = value;
                              });
                            },
                          ),
                        )
                      : Align(
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
                                    '${type.label} (${typeCounts[type] ?? 0})',
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompactControls = constraints.maxWidth < 480;
                      final sortDropdown =
                          DropdownButtonFormField<_ProjectSortMode>(
                            key: const Key('projectSortDropdown'),
                            isExpanded: isCompactControls,
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
                          );
                      final resetButton = OutlinedButton(
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
                      );

                      if (isCompactControls) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            sortDropdown,
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: resetButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: sortDropdown),
                          const SizedBox(width: 8),
                          resetButton,
                        ],
                      );
                    },
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
                            'Messages: ${readinessSummary.totalMessages}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            key: const Key('projectPortfolioHealthSummary'),
                            _portfolioHealthSummaryLabel(readinessSummary),
                            style: Theme.of(context).textTheme.bodySmall,
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompactActionStack =
                                  constraints.maxWidth < 560;
                              final actionButtons = <Widget>[
                                OutlinedButton.icon(
                                  key: const Key(
                                    'portfolioContinueEditingButton',
                                  ),
                                  onPressed: primaryProject == null
                                      ? null
                                      : () => _openProjectEditor(
                                          primaryProject,
                                          preferAttentionScene:
                                              primaryProject.id ==
                                              readinessSummary
                                                  .firstNeedsAttentionProjectId,
                                        ),
                                  icon: const Icon(Icons.edit_note_rounded),
                                  label: const Text('Continue Editing'),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('portfolioPreviewReadyButton'),
                                  onPressed: previewReadyProject == null
                                      ? null
                                      : () => _openProjectPlayback(
                                          previewReadyProject,
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
                                  onPressed: attentionProject == null
                                      ? null
                                      : () => _openProjectEditor(
                                          attentionProject,
                                          preferAttentionScene: true,
                                        ),
                                  icon: const Icon(
                                    Icons.rule_folder_outlined,
                                  ),
                                  label: const Text('Review Attention Project'),
                                ),
                              ];

                              if (isCompactActionStack) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var index = 0;
                                      index < actionButtons.length;
                                      index += 1
                                    ) ...[
                                      actionButtons[index],
                                      if (index != actionButtons.length - 1)
                                        const SizedBox(height: 8),
                                    ],
                                  ],
                                );
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: actionButtons,
                              );
                            },
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
              ];

              Widget buildProjectCard(Project project) {
                return _ProjectCard(
                  project: project,
                  selectionMode: _isSelectionMode,
                  isSelected: selectedIdsForCurrentProjects.contains(
                    project.id,
                  ),
                  onSelectionChanged: (isSelected) {
                    _setProjectSelected(
                      projectId: project.id,
                      isSelected: isSelected,
                    );
                  },
                );
              }

              final projectsList = filteredProjects.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No projects match current filters.'),
                      ),
                    )
                  : ListView.separated(
                      key: const Key('projectCardsListView'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                      itemBuilder: (context, index) =>
                          buildProjectCard(filteredProjects[index]),
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemCount: filteredProjects.length,
                    );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final useSingleScrollColumn = constraints.maxWidth < 720;

                  if (useSingleScrollColumn) {
                    return CustomScrollView(
                      key: const Key('projectListScrollView'),
                      slivers: [
                        for (final header in headerContent)
                          SliverToBoxAdapter(child: header),
                        if (filteredProjects.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No projects match current filters.',
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index.isOdd) {
                                    return const SizedBox(height: 12);
                                  }
                                  final projectIndex = index ~/ 2;
                                  return buildProjectCard(
                                    filteredProjects[projectIndex],
                                  );
                                },
                                childCount: filteredProjects.length * 2 - 1,
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      ...headerContent,
                      Expanded(child: projectsList),
                    ],
                  );
                },
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
      ),
    );
  }
}

enum _ProjectSortMode {
  updatedNewest,
  updatedOldest,
  nameAscending,
  nameDescending,
}

enum _ProjectListAppBarAction {
  selectProjects,
  exportAll,
  importFile,
  importJson,
  loadExportQa,
  addDemo,
  refresh,
}

enum _ProjectSelectionAction {
  selectAll,
  clear,
  duplicate,
  setTypeAd,
  setTypeSeries,
  setTypeOther,
  exportSelected,
  deleteSelected,
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
    final isCompactLayout = MediaQuery.sizeOf(context).width < 720;
    final projectHealth = summarizeProjectHealth(project);
    final attentionState = _projectAttentionState(project);

    return Card(
      key: Key('projectCard_${project.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompactLayout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    _ProjectMenuButton(
                      project: project,
                      controller: controller,
                    ),
                ],
              )
            else
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
                    _ProjectMenuButton(
                      project: project,
                      controller: controller,
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
            Text('Type: ${project.type.label}'),
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
              '${projectHealth.readyScenes}/${project.scenes.length} ready • '
              '${projectHealth.emptyScenes} empty • '
              '${_projectStyleCount(project)} style${_projectStyleCount(project) == 1 ? '' : 's'}',
            ),
            if (projectHealth.unusedCharacterCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                key: Key('projectHealthSummary_${project.id}'),
                'Scene health: '
                '${projectHealth.unusedCharacterCount} character${projectHealth.unusedCharacterCount == 1 ? '' : 's'} waiting for lines '
                'across ${projectHealth.scenesWithUnusedCharacters} scene${projectHealth.scenesWithUnusedCharacters == 1 ? '' : 's'}',
              ),
            ],
            const SizedBox(height: 8),
            Chip(
              key: Key('projectAttentionReason_${project.id}'),
              avatar: Icon(attentionState.icon, size: 18),
              label: Text(attentionState.label),
            ),
            const SizedBox(height: 8),
            if (isCompactLayout)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('projectAttentionCta_${project.id}'),
                  onPressed: selectionMode
                      ? null
                      : () => _openProjectAttentionAction(context, project),
                  icon: Icon(attentionState.ctaIcon),
                  label: Text(attentionState.ctaLabel),
                ),
              )
            else
              OutlinedButton.icon(
                key: Key('projectAttentionCta_${project.id}'),
                onPressed: selectionMode
                    ? null
                    : () => _openProjectAttentionAction(context, project),
                icon: Icon(attentionState.ctaIcon),
                label: Text(attentionState.ctaLabel),
              ),
            const SizedBox(height: 16),
            if (isCompactLayout)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: Key('projectOpenPlayback_${project.id}'),
                    onPressed: selectionMode
                        ? null
                        : () => _goToProjectPlayback(context, project),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Open Playback'),
                  ),
                ],
              )
            else
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
                        : () => _goToProjectPlayback(context, project),
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
}

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState({
    required this.onCreateProject,
    required this.onCreateDemoProject,
    required this.onLoadExportQaProject,
  });

  final VoidCallback onCreateProject;
  final VoidCallback onCreateDemoProject;
  final VoidCallback onLoadExportQaProject;

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
                OutlinedButton.icon(
                  key: const Key('emptyLoadExportQaButton'),
                  onPressed: onLoadExportQaProject,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Load Export QA Project'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showRenameDialog(
  BuildContext context,
  Project project,
) async {
  return _showValidatedSingleTextDialog(
    context,
    title: 'Rename Project',
    labelText: 'Project Name',
    initialValue: project.name,
    emptyErrorText: 'Project name cannot be empty.',
  );
}

Future<String?> _showValidatedSingleTextDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required String emptyErrorText,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  String? errorText;

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submit() {
            final trimmedValue = controller.text.trim();
            if (trimmedValue.isEmpty) {
              setState(() {
                errorText = emptyErrorText;
              });
              return;
            }
            Navigator.of(context).pop(trimmedValue);
          }

          return ResponsiveAlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              onSubmitted: (_) => submit(),
              onChanged: (value) {
                if (errorText != null && value.trim().isNotEmpty) {
                  setState(() {
                    errorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: labelText,
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: submit, child: const Text('Save')),
            ],
          );
        },
      );
    },
  );

  return result;
}

Future<bool> _confirmDeleteProject(
  BuildContext context,
  Project project,
) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return ResponsiveAlertDialog(
        title: Text('Delete ${project.name}?'),
        content: const Text(
          'This action removes the project from local storage.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelDeleteProjectButton'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteProjectButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return shouldDelete ?? false;
}

Future<void> _copyProjectJson(BuildContext context, Project project) async {
  const encoder = JsonEncoder.withIndent('  ');
  final jsonText = encoder.convert(project.toJson());

  try {
    await Clipboard.setData(ClipboardData(text: jsonText));
  } on PlatformException {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project JSON copy failed: clipboard is unavailable.'),
      ),
    );
    return;
  }

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

  if (result.failure == ProjectPackageExportFailure.downloadUnavailable) {
    try {
      await Clipboard.setData(ClipboardData(text: result.jsonText));
    } on PlatformException {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Project package export failed: download and clipboard are unavailable on this platform.',
          ),
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Download unavailable. Project package JSON copied to clipboard.',
        ),
      ),
    );
    return;
  }

  final message = result.isSuccess
      ? 'Project package exported: ${result.filename}.'
      : 'Project package export failed.';
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ProjectMenuButton extends StatelessWidget {
  const _ProjectMenuButton({
    required this.project,
    required this.controller,
  });

  final Project project;
  final ProjectsController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProjectMenuAction>(
      tooltip: 'Project Menu',
      onSelected: (action) async {
        switch (action) {
          case _ProjectMenuAction.rename:
            final newName = await _showRenameDialog(context, project);
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
            final shouldDelete = await _confirmDeleteProject(context, project);
            if (!shouldDelete) {
              return;
            }
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

int _projectStyleCount(Project project) {
  final styleIds = <String>{};
  for (final scene in project.scenes) {
    styleIds.add(scene.styleId);
  }
  return styleIds.length;
}

String? _projectAttentionSceneId(Project project) {
  final projectHealth = summarizeProjectHealth(project);
  if (projectHealth.firstAttentionSceneId != null) {
    return projectHealth.firstAttentionSceneId;
  }

  if (project.scenes.isEmpty) {
    return null;
  }

  return project.scenes.first.id;
}

String? _projectPlaybackSceneId(Project project) {
  for (final scene in project.scenes) {
    if (scene.messages.isNotEmpty) {
      return scene.id;
    }
  }

  if (project.scenes.isEmpty) {
    return null;
  }

  return project.scenes.first.id;
}

void _goToProjectPlayback(BuildContext context, Project project) {
  final targetSceneId = _projectPlaybackSceneId(project);
  context.goNamed(
    'playbackProject',
    pathParameters: {'projectId': project.id},
    queryParameters: targetSceneId == null
        ? const <String, String>{}
        : {'sceneId': targetSceneId},
  );
}

void _openProjectAttentionAction(BuildContext context, Project project) {
  final attentionState = _projectAttentionState(project);
  switch (attentionState.intent) {
    case _ProjectAttentionIntent.openEditor:
      final targetSceneId = _projectAttentionSceneId(project);
      context.goNamed(
        'editorProject',
        pathParameters: {'projectId': project.id},
        queryParameters: targetSceneId == null
            ? const <String, String>{}
            : {'sceneId': targetSceneId},
      );
      return;
    case _ProjectAttentionIntent.openPlayback:
      _goToProjectPlayback(context, project);
      return;
  }
}

_ProjectAttentionState _projectAttentionState(Project project) {
  final projectHealth = summarizeProjectHealth(project);

  if (!projectHealth.hasMessages) {
    return const _ProjectAttentionState(
      label: 'No messages yet',
      icon: Icons.chat_bubble_outline_rounded,
      ctaLabel: 'Add First Message',
      ctaIcon: Icons.edit_note_rounded,
      intent: _ProjectAttentionIntent.openEditor,
    );
  }

  if (projectHealth.emptyScenes > 0) {
    return const _ProjectAttentionState(
      label: 'Has empty scenes',
      icon: Icons.error_outline_rounded,
      ctaLabel: 'Finish Empty Scenes',
      ctaIcon: Icons.build_circle_outlined,
      intent: _ProjectAttentionIntent.openEditor,
    );
  }

  if (projectHealth.unusedCharacterCount > 0) {
    return const _ProjectAttentionState(
      label: 'Characters need lines',
      icon: Icons.record_voice_over_outlined,
      ctaLabel: 'Review Scene Setup',
      ctaIcon: Icons.playlist_add_check_circle_outlined,
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
  var unusedCharacterCount = 0;
  String? firstReadyProjectId;
  String? firstNeedsAttentionProjectId;

  for (final project in projects) {
    final projectHealth = summarizeProjectHealth(project);
    totalScenes += projectHealth.totalScenes;
    readyScenes += projectHealth.readyScenes;
    emptyScenes += projectHealth.emptyScenes;
    totalMessages += projectHealth.totalMessages;
    unusedCharacterCount += projectHealth.unusedCharacterCount;

    if (projectHealth.needsAttention) {
      needsAttentionProjectCount++;
      firstNeedsAttentionProjectId ??= project.id;
    } else {
      readyProjectCount++;
      firstReadyProjectId ??= project.id;
    }
  }

  return _ProjectPortfolioReadinessSummary(
    totalScenes: totalScenes,
    readyScenes: readyScenes,
    emptyScenes: emptyScenes,
    totalMessages: totalMessages,
    unusedCharacterCount: unusedCharacterCount,
    readyProjectCount: readyProjectCount,
    needsAttentionProjectCount: needsAttentionProjectCount,
    primaryProjectId: firstNeedsAttentionProjectId ?? firstReadyProjectId,
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
    required this.unusedCharacterCount,
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
  final int unusedCharacterCount;
  final int readyProjectCount;
  final int needsAttentionProjectCount;
  final String? primaryProjectId;
  final String? firstReadyProjectId;
  final String? firstNeedsAttentionProjectId;

  bool get needsAttention => emptyScenes > 0 || unusedCharacterCount > 0;
}

String _portfolioHealthSummaryLabel(
  _ProjectPortfolioReadinessSummary summary,
) {
  if (!summary.needsAttention) {
    return 'Ready: no empty scenes • all active characters have lines';
  }

  return 'Attention: ${summary.emptyScenes} empty scene${summary.emptyScenes == 1 ? '' : 's'} • '
      '${summary.unusedCharacterCount} character${summary.unusedCharacterCount == 1 ? '' : 's'} waiting for lines';
}
