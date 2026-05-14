import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

// LayoutBuilder sees the inner action row width after padding, so this
// threshold maps to roughly a ~408 px viewport with the current shell.
const _kProjectNotFoundCompactActionsBreakpoint = 360.0;

class ProjectNotFoundRecoveryState extends ConsumerWidget {
  const ProjectNotFoundRecoveryState({
    required this.openRouteName,
    super.key,
  });

  final String openRouteName;

  Future<void> _createAndOpenProject(
    BuildContext context,
    WidgetRef ref, {
    required Future<String> Function() createProject,
  }) async {
    final projectId = await createProject();
    if (!context.mounted) {
      return;
    }

    context.goNamed(
      openRouteName,
      pathParameters: {'projectId': projectId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_off_outlined, size: 32),
              const SizedBox(height: 12),
              const Text('Project not found.'),
              const SizedBox(height: 8),
              Text(
                'This link points to a project that is missing or was deleted.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxWidth <
                      _kProjectNotFoundCompactActionsBreakpoint;
                  final buttons = <Widget>[
                    FilledButton.icon(
                      key: const Key('projectNotFoundCreateStarterButton'),
                      onPressed: () => _createAndOpenProject(
                        context,
                        ref,
                        createProject: ref
                            .read(projectsControllerProvider.notifier)
                            .createProject,
                      ),
                      icon: const Icon(Icons.add_comment_rounded),
                      label: const Text('Create Starter Project'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('projectNotFoundCreateDemoButton'),
                      onPressed: () => _createAndOpenProject(
                        context,
                        ref,
                        createProject: ref
                            .read(projectsControllerProvider.notifier)
                            .createDemoProject,
                      ),
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('Add Demo Project'),
                    ),
                    TextButton.icon(
                      key: const Key('projectNotFoundBackButton'),
                      onPressed: () => context.goNamed('projects'),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Back to Projects'),
                    ),
                  ];

                  if (isCompact) {
                    return Column(
                      key: const Key('projectNotFoundCompactActions'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < buttons.length;
                          index++
                        ) ...[
                          buttons[index],
                          if (index < buttons.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return Wrap(
                    key: const Key('projectNotFoundWrapActions'),
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: buttons,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
