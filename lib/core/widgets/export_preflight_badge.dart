import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/display_labels.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/responsive_alert_dialog.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

class ExportPreflightBadge extends StatelessWidget {
  const ExportPreflightBadge({
    required this.project,
    required this.scene,
    required this.sceneHealth,
    required this.exportTargetPixelSize,
    required this.includeDeviceFrame,
    required this.cleanPreview,
    super.key,
  });

  final Project project;
  final Scene scene;
  final SceneHealthSummary sceneHealth;
  final Size exportTargetPixelSize;
  final bool includeDeviceFrame;
  final bool cleanPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final presentation = _presentationForState(
      colorScheme,
      sceneHealth.badgeState,
    );
    final label = sceneHealth.badgeLabel;

    return Semantics(
      label: 'Export pre-flight: $label. ${_summaryLine()}',
      hint: 'Opens export pre-flight details.',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          key: const Key('exportPreflightButton'),
          style: FilledButton.styleFrom(
            alignment: Alignment.centerLeft,
            backgroundColor: presentation.backgroundColor,
            foregroundColor: presentation.foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: presentation.borderColor),
          ),
          onPressed: () => _showPreflightDetails(
            context,
            presentation: presentation,
          ),
          icon: Icon(presentation.icon),
          label: Text('Export pre-flight • $label'),
        ),
      ),
    );
  }

  Future<void> _showPreflightDetails(
    BuildContext context, {
    required _ExportPreflightPresentation presentation,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final projectHealth = summarizeProjectHealth(project);

    return showDialog<void>(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        key: const Key('exportPreflightDialog'),
        title: Row(
          children: [
            Icon(presentation.icon, color: presentation.foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Export pre-flight • ${sceneHealth.badgeLabel}'),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${scene.title} in ${project.name}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(_summaryLine()),
            const SizedBox(height: 16),
            _PreflightSection(
              title: 'Scene checks',
              children: [
                Text(sceneHealth.statusLabel),
                const SizedBox(height: 4),
                Text(sceneHealth.detailLabel),
                if (!sceneHealth.hasTimelineWarnings) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No timeline QA warnings detected for this scene.',
                  ),
                ],
              ],
            ),
            if (sceneHealth.hasTimelineWarnings) ...[
              const SizedBox(height: 12),
              _PreflightSection(
                title: 'Timeline QA',
                children: [
                  Text(sceneHealth.timelineStatusLabel),
                  const SizedBox(height: 4),
                  Text(sceneHealth.timelineDetailLabel),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _PreflightSection(
              title: 'Export sync',
              children: [
                _PreflightDetailLine(
                  label: 'Scene ratio',
                  value: scene.aspectRatio.label,
                ),
                _PreflightDetailLine(
                  label: 'Screenshot target',
                  value:
                      '${exportTargetPixelSize.width.toInt()}×${exportTargetPixelSize.height.toInt()} PNG',
                ),
                _PreflightDetailLine(
                  label: 'Device frame',
                  value: includeDeviceFrame ? 'On' : 'Off',
                ),
                _PreflightDetailLine(
                  label: 'Preview mode',
                  value: cleanPreview ? 'Clean' : 'Full',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PreflightSection(
              title: 'Project context',
              children: [
                _PreflightDetailLine(
                  label: 'Ready scenes',
                  value:
                      '${projectHealth.readyScenes}/${projectHealth.totalScenes}',
                ),
                _PreflightDetailLine(
                  label: 'Total messages',
                  value: '${projectHealth.totalMessages}',
                ),
                _PreflightDetailLine(
                  label: 'Empty scenes',
                  value: '${projectHealth.emptyScenes}',
                ),
                _PreflightDetailLine(
                  label: 'Unused character lines',
                  value: '${projectHealth.unusedCharacterCount}',
                ),
                _PreflightDetailLine(
                  label: 'Timeline warnings',
                  value:
                      '${projectHealth.sharedTimestampCount + projectHealth.overlappingTypingCueCount}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _PreflightSection(
              title: 'Video export beta workflow',
              children: [
                Text(
                  'Export Video stays on the documented JSON handoff workflow during beta.',
                ),
                SizedBox(height: 4),
                Text(
                  'The package keeps the selected scene, sorted messages, render hints, and QA summaries aligned for downstream render.',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('exportPreflightCloseButton'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _summaryLine() {
    if (!sceneHealth.hasMessages) {
      return 'Add at least one message before export.';
    }
    if (sceneHealth.hasUnusedCharacters) {
      return 'Some characters still need lines before export.';
    }
    if (sceneHealth.hasTimelineWarnings) {
      return 'Export is available, but review timeline QA before handoff.';
    }
    return 'This scene is aligned for screenshot export and beta video handoff.';
  }
}

class _PreflightSection extends StatelessWidget {
  const _PreflightSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}

class _PreflightDetailLine extends StatelessWidget {
  const _PreflightDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}

class _ExportPreflightPresentation {
  const _ExportPreflightPresentation({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}

_ExportPreflightPresentation _presentationForState(
  ColorScheme colorScheme,
  SceneHealthBadgeState badgeState,
) {
  switch (badgeState) {
    case SceneHealthBadgeState.noMessages:
    case SceneHealthBadgeState.needsLines:
      return _ExportPreflightPresentation(
        icon: Icons.error_outline_rounded,
        backgroundColor: colorScheme.errorContainer,
        borderColor: colorScheme.error.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onErrorContainer,
      );
    case SceneHealthBadgeState.timelineQa:
      return _ExportPreflightPresentation(
        icon: Icons.warning_amber_rounded,
        backgroundColor: colorScheme.tertiaryContainer,
        borderColor: colorScheme.tertiary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onTertiaryContainer,
      );
    case SceneHealthBadgeState.ready:
      return _ExportPreflightPresentation(
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: colorScheme.secondaryContainer,
        borderColor: colorScheme.secondary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onSecondaryContainer,
      );
  }
}
