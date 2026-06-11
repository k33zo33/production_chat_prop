import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/app_breakpoints.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/responsive_alert_dialog.dart';

class PortfolioPreflightBadge extends StatelessWidget {
  const PortfolioPreflightBadge({
    required this.summary,
    required this.onContinueEditing,
    required this.onPreviewReady,
    super.key,
    this.onReviewAttention,
    this.onReviewTimelineQa,
    this.attentionProjectName,
    this.readyProjectName,
    this.timelineWarningProjectName,
  });

  final PortfolioHealthSummary summary;
  final VoidCallback? onContinueEditing;
  final VoidCallback? onPreviewReady;
  final VoidCallback? onReviewAttention;
  final VoidCallback? onReviewTimelineQa;
  final String? attentionProjectName;
  final String? readyProjectName;
  final String? timelineWarningProjectName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final presentation = _presentationForState(
      colorScheme,
      _preflightState(summary),
    );
    final label = _badgeLabel(summary);

    return Semantics(
      label: 'Beta handoff pre-flight: $label. ${_summaryLine(summary)}',
      hint: 'Opens portfolio beta handoff details.',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          key: const Key('portfolioPreflightButton'),
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
          label: Text('Beta handoff pre-flight • $label'),
        ),
      ),
    );
  }

  Future<void> _showPreflightDetails(
    BuildContext context, {
    required _PortfolioPreflightPresentation presentation,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final actionButtons = _buildActionButtons(context);

    return showDialog<void>(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        key: const Key('portfolioPreflightDialog'),
        title: Row(
          children: [
            Icon(presentation.icon, color: presentation.foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Beta handoff pre-flight • ${_badgeLabel(summary)}',
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _summaryLine(summary),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _PortfolioPreflightSection(
              title: 'Portfolio checks',
              children: [
                _PortfolioPreflightDetailLine(
                  label: 'Projects in view',
                  value: '${summary.totalProjects}',
                ),
                _PortfolioPreflightDetailLine(
                  label: 'Ready projects',
                  value: '${summary.readyProjectCount}',
                ),
                _PortfolioPreflightDetailLine(
                  label: 'Projects needing attention',
                  value: '${summary.needsAttentionProjectCount}',
                ),
                _PortfolioPreflightDetailLine(
                  label: 'Ready scenes',
                  value: '${summary.readyScenes}/${summary.totalScenes}',
                ),
                _PortfolioPreflightDetailLine(
                  label: 'Total messages',
                  value: '${summary.totalMessages}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PortfolioPreflightSection(
              title: 'Attention state',
              children: [
                Text(_attentionStatusLabel(summary)),
                const SizedBox(height: 4),
                Text(_attentionDetailLabel(summary)),
                if (attentionProjectName != null) ...[
                  const SizedBox(height: 8),
                  Text('First attention project: $attentionProjectName'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _PortfolioPreflightSection(
              title: 'Timeline QA',
              children: [
                Text(_timelineStatusLabel(summary)),
                const SizedBox(height: 4),
                Text(_timelineDetailLabel(summary)),
                if (timelineWarningProjectName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'First timeline QA project: $timelineWarningProjectName',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _PortfolioPreflightSection(
              title: 'Recommended beta pass',
              children: [
                const Text(
                  'Run the export QA fixture, compact smoke pass, and full verify gate before handoff.',
                ),
                if (readyProjectName != null) ...[
                  const SizedBox(height: 8),
                  Text('Primary preview-ready project: $readyProjectName'),
                ],
              ],
            ),
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PortfolioPreflightSection(
                title: 'Quick actions',
                children: [
                  _PortfolioPreflightActionStack(buttons: actionButtons),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('portfolioPreflightCloseButton'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final navigator = Navigator.of(context);
    final buttons = <Widget>[];

    if (onContinueEditing != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const Key('portfolioPreflightContinueEditingButton'),
          onPressed: () {
            navigator.pop();
            onContinueEditing?.call();
          },
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Continue Editing'),
        ),
      );
    }
    if (onPreviewReady != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const Key('portfolioPreflightPreviewReadyButton'),
          onPressed: () {
            navigator.pop();
            onPreviewReady?.call();
          },
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text('Preview Ready Project'),
        ),
      );
    }
    if (onReviewAttention != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const Key('portfolioPreflightReviewAttentionButton'),
          onPressed: () {
            navigator.pop();
            onReviewAttention?.call();
          },
          icon: const Icon(Icons.rule_folder_outlined),
          label: const Text('Review Attention Project'),
        ),
      );
    }
    if (onReviewTimelineQa != null) {
      buttons.add(
        OutlinedButton.icon(
          key: const Key('portfolioPreflightReviewTimelineQaButton'),
          onPressed: () {
            navigator.pop();
            onReviewTimelineQa?.call();
          },
          icon: const Icon(Icons.schedule_send_outlined),
          label: const Text('Review Timeline QA'),
        ),
      );
    }

    return buttons;
  }
}

class _PortfolioPreflightSection extends StatelessWidget {
  const _PortfolioPreflightSection({
    required this.title,
    required this.children,
  });

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

class _PortfolioPreflightDetailLine extends StatelessWidget {
  const _PortfolioPreflightDetailLine({
    required this.label,
    required this.value,
  });

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

class _PortfolioPreflightActionStack extends StatelessWidget {
  const _PortfolioPreflightActionStack({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final isCompactWidth = AppBreakpoints.isCompactFilterWidth(
      MediaQuery.sizeOf(context).width,
      textScaleFactor: textScaleFactor,
    );

    if (isCompactWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buttons.length; index += 1) ...[
            buttons[index],
            if (index != buttons.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }
}

class _PortfolioPreflightPresentation {
  const _PortfolioPreflightPresentation({
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

enum _PortfolioPreflightState { noProjects, needsAttention, timelineQa, ready }

_PortfolioPreflightState _preflightState(PortfolioHealthSummary summary) {
  if (!summary.hasProjects) {
    return _PortfolioPreflightState.noProjects;
  }
  if (summary.needsAttention) {
    return _PortfolioPreflightState.needsAttention;
  }
  if (summary.hasTimelineWarnings) {
    return _PortfolioPreflightState.timelineQa;
  }
  return _PortfolioPreflightState.ready;
}

String _badgeLabel(PortfolioHealthSummary summary) {
  switch (_preflightState(summary)) {
    case _PortfolioPreflightState.noProjects:
      return 'No projects';
    case _PortfolioPreflightState.needsAttention:
      return 'Needs attention';
    case _PortfolioPreflightState.timelineQa:
      return 'Timeline QA';
    case _PortfolioPreflightState.ready:
      return 'Ready';
  }
}

String _summaryLine(PortfolioHealthSummary summary) {
  if (!summary.hasProjects) {
    return 'Create or import a project to start the beta pass.';
  }
  if (!summary.hasMessages) {
    return 'Add at least one message before playback, export, or handoff QA.';
  }
  if (summary.needsAttention) {
    return '${summary.emptyScenes} empty scene${summary.emptyScenes == 1 ? '' : 's'} • '
        '${summary.unusedCharacterCount} character${summary.unusedCharacterCount == 1 ? '' : 's'} waiting for lines';
  }
  if (summary.hasTimelineWarnings) {
    return 'Playback is ready, but timeline QA should be reviewed before beta handoff.';
  }
  return 'Portfolio looks aligned for beta handoff.';
}

String _attentionStatusLabel(PortfolioHealthSummary summary) {
  if (!summary.hasProjects) {
    return 'No projects loaded';
  }
  if (!summary.hasMessages) {
    return 'No message content yet';
  }
  if (summary.needsAttention) {
    return 'Some scenes still need setup';
  }
  return 'Ready for coverage review';
}

String _attentionDetailLabel(PortfolioHealthSummary summary) {
  if (!summary.hasProjects) {
    return 'Create a project or load the demo fixture before running the beta pass.';
  }
  if (!summary.hasMessages) {
    return 'The current filtered portfolio has no messages yet, so editor, playback, and export cannot be validated end-to-end.';
  }
  if (summary.needsAttention) {
    return '${summary.emptyScenes} empty scene${summary.emptyScenes == 1 ? '' : 's'} and '
        '${summary.unusedCharacterCount} character${summary.unusedCharacterCount == 1 ? '' : 's'} still need lines before handoff.';
  }
  return 'No empty scenes or unused character lines are blocking the current portfolio view.';
}

String _timelineStatusLabel(PortfolioHealthSummary summary) {
  if (!summary.hasTimelineWarnings) {
    return 'No timeline QA warnings detected';
  }

  final segments = <String>[];
  if (summary.sharedTimestampCount > 0) {
    segments.add(
      '${summary.sharedTimestampCount} shared timestamp${summary.sharedTimestampCount == 1 ? '' : 's'}',
    );
  }
  if (summary.overlappingTypingCueCount > 0) {
    segments.add(
      '${summary.overlappingTypingCueCount} overlapping typing cue${summary.overlappingTypingCueCount == 1 ? '' : 's'}',
    );
  }

  return '${segments.join(' • ')} across ${summary.scenesWithTimelineWarnings} scene${summary.scenesWithTimelineWarnings == 1 ? '' : 's'} in ${summary.timelineWarningProjectCount} project${summary.timelineWarningProjectCount == 1 ? '' : 's'}';
}

String _timelineDetailLabel(PortfolioHealthSummary summary) {
  if (!summary.hasTimelineWarnings) {
    return 'No shared timestamps or overlapping typing cues need review right now.';
  }

  final details = <String>[];
  if (summary.sharedTimestampCount > 0) {
    details.add(
      'Shared timestamps can stack message reveals in playback or export.',
    );
  }
  if (summary.overlappingTypingCueCount > 0) {
    details.add(
      'Overlapping typing cues can feel crowded, especially on compact previews.',
    );
  }
  return details.join(' ');
}

_PortfolioPreflightPresentation _presentationForState(
  ColorScheme colorScheme,
  _PortfolioPreflightState state,
) {
  switch (state) {
    case _PortfolioPreflightState.noProjects:
      return _PortfolioPreflightPresentation(
        icon: Icons.folder_off_outlined,
        backgroundColor: colorScheme.errorContainer,
        borderColor: colorScheme.error.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onErrorContainer,
      );
    case _PortfolioPreflightState.needsAttention:
      return _PortfolioPreflightPresentation(
        icon: Icons.error_outline_rounded,
        backgroundColor: colorScheme.errorContainer,
        borderColor: colorScheme.error.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onErrorContainer,
      );
    case _PortfolioPreflightState.timelineQa:
      return _PortfolioPreflightPresentation(
        icon: Icons.warning_amber_rounded,
        backgroundColor: colorScheme.tertiaryContainer,
        borderColor: colorScheme.tertiary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onTertiaryContainer,
      );
    case _PortfolioPreflightState.ready:
      return _PortfolioPreflightPresentation(
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: colorScheme.secondaryContainer,
        borderColor: colorScheme.secondary.withValues(alpha: 0.24),
        foregroundColor: colorScheme.onSecondaryContainer,
      );
  }
}
