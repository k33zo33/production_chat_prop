import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';

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

    return Tooltip(
      message: summary.badgeTooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        label: 'Scene status: ${summary.badgeLabel}. ${summary.badgeTooltip}',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: presentation.backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: presentation.borderColor),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: presentation.foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
