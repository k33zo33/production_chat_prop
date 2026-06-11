import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/responsive_alert_dialog.dart';

class SceneStatusBadge extends StatelessWidget {
  const SceneStatusBadge({
    required this.summary,
    required this.compact,
    super.key,
  });

  final SceneHealthSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final presentation = _statusPresentation(colorScheme, summary.badgeState);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: presentation.foregroundColor,
      fontWeight: FontWeight.w600,
    );

    return Tooltip(
      message: summary.badgeTooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        label: 'Scene status: ${summary.badgeLabel}. ${summary.badgeTooltip}',
        hint: 'Opens detailed scene status.',
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: presentation.backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: presentation.borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _showSceneStatusDetails(
                context,
                presentation: presentation,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      presentation.icon,
                      size: 18,
                      color: presentation.foregroundColor,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 124),
                        child: Text(
                          summary.badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSceneStatusDetails(
    BuildContext context, {
    required _SceneStatusPresentation presentation,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        key: const Key('sceneStatusDetailsDialog'),
        title: Row(
          children: [
            Icon(
              presentation.icon,
              color: presentation.foregroundColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Scene status • ${summary.badgeLabel}'),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(summary.statusLabel),
            const SizedBox(height: 4),
            Text(summary.detailLabel),
            if (summary.hasTimelineWarnings) ...[
              const SizedBox(height: 12),
              Text(
                'Timeline QA',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(summary.timelineStatusLabel),
              const SizedBox(height: 4),
              Text(summary.timelineDetailLabel),
            ],
            if (!summary.needsAttention && !summary.hasTimelineWarnings) ...[
              const SizedBox(height: 12),
              Text(
                'Ready for playback and export.',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('sceneStatusDetailsCloseButton'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SceneStatusPresentation {
  const _SceneStatusPresentation({
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

_SceneStatusPresentation _statusPresentation(
  ColorScheme colorScheme,
  SceneHealthBadgeState badgeState,
) {
  switch (badgeState) {
    case SceneHealthBadgeState.noMessages:
    case SceneHealthBadgeState.needsLines:
      return _SceneStatusPresentation(
        icon: Icons.error_outline_rounded,
        backgroundColor: colorScheme.errorContainer,
        borderColor: colorScheme.error.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onErrorContainer,
      );
    case SceneHealthBadgeState.timelineQa:
      return _SceneStatusPresentation(
        icon: Icons.warning_amber_rounded,
        backgroundColor: colorScheme.tertiaryContainer,
        borderColor: colorScheme.tertiary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onTertiaryContainer,
      );
    case SceneHealthBadgeState.ready:
      return _SceneStatusPresentation(
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: colorScheme.secondaryContainer,
        borderColor: colorScheme.secondary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onSecondaryContainer,
      );
  }
}
