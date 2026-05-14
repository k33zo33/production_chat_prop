import 'package:flutter/material.dart';

String buildCompactSceneSummary({
  required int selectedSceneIndex,
  required int totalScenes,
  required int messageCount,
  required int maxSecond,
}) {
  if (selectedSceneIndex < 0 || totalScenes <= 0) {
    return '';
  }

  final sceneNumber = selectedSceneIndex + 1;
  final messageLabel = messageCount == 1 ? 'message' : 'messages';
  return 'Scene $sceneNumber of $totalScenes • $messageCount $messageLabel • ${maxSecond}s max';
}

class CompactSceneSelector extends StatelessWidget {
  const CompactSceneSelector({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.summary,
    super.key,
    this.dropdownKey,
    this.summaryKey,
    this.label = 'Selected Scene',
  });

  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String summary;
  final Key? dropdownKey;
  final Key? summaryKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            summary,
            key: summaryKey,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: dropdownKey,
                  value: value,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
