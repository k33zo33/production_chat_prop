import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

enum SceneHealthBadgeState {
  noMessages,
  needsLines,
  timelineQa,
  ready,
}

enum ProjectAttentionKind {
  noMessages,
  emptyScenes,
  needsLines,
  ready,
}

enum ProjectAttentionIntent {
  openEditor,
  openPlayback,
}

class ProjectAttentionState {
  const ProjectAttentionState({
    required this.kind,
    required this.label,
    required this.ctaLabel,
    required this.intent,
  });

  final ProjectAttentionKind kind;
  final String label;
  final String ctaLabel;
  final ProjectAttentionIntent intent;
}

class SceneHealthSummary {
  const SceneHealthSummary({
    required this.messageCount,
    required this.unusedCharacterNames,
    required this.sharedTimestampCount,
    required this.sharedTimestampMessageCount,
    required this.sharedTimestampMessageIds,
    required this.overlappingTypingCueCount,
    required this.overlappingTypingCueMessageIds,
  });

  final int messageCount;
  final List<String> unusedCharacterNames;
  final int sharedTimestampCount;
  final int sharedTimestampMessageCount;
  final Set<String> sharedTimestampMessageIds;
  final int overlappingTypingCueCount;
  final Set<String> overlappingTypingCueMessageIds;

  bool get hasMessages => messageCount > 0;
  int get unusedCharacterCount => unusedCharacterNames.length;
  bool get hasUnusedCharacters => unusedCharacterNames.isNotEmpty;
  bool get hasTimelineWarnings =>
      sharedTimestampCount > 0 || overlappingTypingCueCount > 0;
  Set<String> get timelineWarningMessageIds => {
    ...sharedTimestampMessageIds,
    ...overlappingTypingCueMessageIds,
  };
  bool get needsAttention => !hasMessages || hasUnusedCharacters;

  SceneHealthBadgeState get badgeState {
    if (!hasMessages) {
      return SceneHealthBadgeState.noMessages;
    }
    if (hasUnusedCharacters) {
      return SceneHealthBadgeState.needsLines;
    }
    if (hasTimelineWarnings) {
      return SceneHealthBadgeState.timelineQa;
    }
    return SceneHealthBadgeState.ready;
  }

  String get badgeLabel {
    switch (badgeState) {
      case SceneHealthBadgeState.noMessages:
        return 'No messages';
      case SceneHealthBadgeState.needsLines:
        return 'Needs lines';
      case SceneHealthBadgeState.timelineQa:
        return 'Timeline QA';
      case SceneHealthBadgeState.ready:
        return 'Ready';
    }
  }

  String get badgeTooltip {
    switch (badgeState) {
      case SceneHealthBadgeState.noMessages:
      case SceneHealthBadgeState.needsLines:
        return '$statusLabel • $detailLabel';
      case SceneHealthBadgeState.timelineQa:
        return '$timelineStatusLabel • $timelineDetailLabel';
      case SceneHealthBadgeState.ready:
        return 'Ready for playback and export.';
    }
  }

  bool hasTimelineWarningForMessage(String messageId) {
    return timelineWarningMessageIds.contains(messageId);
  }

  String? timelineWarningLabelForMessage(String messageId) {
    final labels = <String>[];
    if (sharedTimestampMessageIds.contains(messageId)) {
      labels.add('shared timestamp');
    }
    if (overlappingTypingCueMessageIds.contains(messageId)) {
      labels.add('overlapping typing cue');
    }
    if (labels.isEmpty) {
      return null;
    }
    return labels.join(' • ');
  }

  String get statusLabel {
    if (!hasMessages) {
      return 'No messages yet';
    }
    if (!hasUnusedCharacters) {
      return 'Ready for playback';
    }
    final waitingCharactersLabel = _formatCount(
      unusedCharacterCount,
      singular: 'character',
      plural: 'characters',
    );
    return '$waitingCharactersLabel waiting for lines';
  }

  String get detailLabel {
    if (!hasMessages) {
      return 'Add at least one message before preview or export.';
    }
    if (!hasUnusedCharacters) {
      return 'All active characters appear in the timeline.';
    }
    final names = unusedCharacterNames.join(', ');
    final verb = unusedCharacterCount == 1 ? 'has' : 'have';
    return '$names $verb no lines in this scene yet.';
  }

  String get timelineStatusLabel {
    final labels = <String>[];
    if (sharedTimestampCount > 0) {
      labels.add(
        _formatCount(
          sharedTimestampCount,
          singular: 'shared timestamp',
          plural: 'shared timestamps',
        ),
      );
    }
    if (overlappingTypingCueCount > 0) {
      labels.add(
        _formatCount(
          overlappingTypingCueCount,
          singular: 'overlapping typing cue',
          plural: 'overlapping typing cues',
        ),
      );
    }
    return labels.join(' • ');
  }

  String get timelineDetailLabel {
    final details = <String>[];
    if (sharedTimestampCount > 0) {
      final sharedMessageLabel = _formatCount(
        sharedTimestampMessageCount,
        singular: 'message',
        plural: 'messages',
      );
      details.add(
        '$sharedMessageLabel land on the same second and can stack in playback or export.',
      );
    }
    if (overlappingTypingCueCount > 0) {
      details.add(
        'Multiple typing indicators fire together and may feel crowded in compact previews.',
      );
    }
    return details.join(' ');
  }
}

SceneHealthSummary summarizeSceneHealth(Scene scene) {
  final usedCharacterIds = <String>{
    for (final message in scene.messages) message.characterId,
  };
  final messageIdsBySecond = <int, List<String>>{};
  final typingCueMessageIdsBySecond = <int, List<String>>{};

  for (final message in scene.messages) {
    messageIdsBySecond.update(
      message.timestampSeconds,
      (ids) => [...ids, message.id],
      ifAbsent: () => [message.id],
    );
    if (message.showTypingBefore && message.timestampSeconds > 0) {
      final typingSecond = message.timestampSeconds - 1;
      typingCueMessageIdsBySecond.update(
        typingSecond,
        (ids) => [...ids, message.id],
        ifAbsent: () => [message.id],
      );
    }
  }

  var sharedTimestampCount = 0;
  var sharedTimestampMessageCount = 0;
  final sharedTimestampMessageIds = <String>{};
  for (final messageIds in messageIdsBySecond.values) {
    if (messageIds.length > 1) {
      sharedTimestampCount++;
      sharedTimestampMessageCount += messageIds.length;
      sharedTimestampMessageIds.addAll(messageIds);
    }
  }

  var overlappingTypingCueCount = 0;
  final overlappingTypingCueMessageIds = <String>{};
  for (final messageIds in typingCueMessageIdsBySecond.values) {
    if (messageIds.length > 1) {
      overlappingTypingCueCount++;
      overlappingTypingCueMessageIds.addAll(messageIds);
    }
  }

  final unusedCharacterNames = <String>[
    for (final character in scene.characters)
      if (!usedCharacterIds.contains(character.id)) character.displayName,
  ];

  return SceneHealthSummary(
    messageCount: scene.messages.length,
    unusedCharacterNames: unusedCharacterNames,
    sharedTimestampCount: sharedTimestampCount,
    sharedTimestampMessageCount: sharedTimestampMessageCount,
    sharedTimestampMessageIds: Set.unmodifiable(sharedTimestampMessageIds),
    overlappingTypingCueCount: overlappingTypingCueCount,
    overlappingTypingCueMessageIds: Set.unmodifiable(
      overlappingTypingCueMessageIds,
    ),
  );
}

class ProjectHealthSummary {
  const ProjectHealthSummary({
    required this.totalScenes,
    required this.readyScenes,
    required this.emptyScenes,
    required this.totalMessages,
    required this.unusedCharacterCount,
    required this.scenesWithUnusedCharacters,
    required this.sharedTimestampCount,
    required this.overlappingTypingCueCount,
    required this.scenesWithTimelineWarnings,
    required this.firstEmptySceneId,
    required this.firstSceneWithUnusedCharactersId,
    required this.firstSceneWithTimelineWarningsId,
  });

  final int totalScenes;
  final int readyScenes;
  final int emptyScenes;
  final int totalMessages;
  final int unusedCharacterCount;
  final int scenesWithUnusedCharacters;
  final int sharedTimestampCount;
  final int overlappingTypingCueCount;
  final int scenesWithTimelineWarnings;
  final String? firstEmptySceneId;
  final String? firstSceneWithUnusedCharactersId;
  final String? firstSceneWithTimelineWarningsId;

  bool get hasMessages => totalMessages > 0;
  bool get hasTimelineWarnings =>
      sharedTimestampCount > 0 || overlappingTypingCueCount > 0;
  bool get needsAttention =>
      emptyScenes > 0 || unusedCharacterCount > 0 || !hasMessages;

  String? get firstAttentionSceneId =>
      firstEmptySceneId ?? firstSceneWithUnusedCharactersId;
}

class PortfolioHealthSummary {
  const PortfolioHealthSummary({
    required this.totalProjects,
    required this.totalScenes,
    required this.readyScenes,
    required this.emptyScenes,
    required this.totalMessages,
    required this.unusedCharacterCount,
    required this.readyProjectCount,
    required this.needsAttentionProjectCount,
    required this.timelineWarningProjectCount,
    required this.sharedTimestampCount,
    required this.overlappingTypingCueCount,
    required this.scenesWithTimelineWarnings,
    required this.firstReadyProjectId,
    required this.firstNeedsAttentionProjectId,
    required this.firstTimelineWarningProjectId,
  });

  final int totalProjects;
  final int totalScenes;
  final int readyScenes;
  final int emptyScenes;
  final int totalMessages;
  final int unusedCharacterCount;
  final int readyProjectCount;
  final int needsAttentionProjectCount;
  final int timelineWarningProjectCount;
  final int sharedTimestampCount;
  final int overlappingTypingCueCount;
  final int scenesWithTimelineWarnings;
  final String? firstReadyProjectId;
  final String? firstNeedsAttentionProjectId;
  final String? firstTimelineWarningProjectId;

  bool get hasProjects => totalProjects > 0;
  bool get hasMessages => totalMessages > 0;
  bool get needsAttention =>
      !hasMessages || emptyScenes > 0 || unusedCharacterCount > 0;
  bool get hasTimelineWarnings =>
      sharedTimestampCount > 0 || overlappingTypingCueCount > 0;
  String? get primaryProjectId =>
      firstNeedsAttentionProjectId ??
      firstTimelineWarningProjectId ??
      firstReadyProjectId;
}

ProjectHealthSummary summarizeProjectHealth(Project project) {
  var readyScenes = 0;
  var emptyScenes = 0;
  var totalMessages = 0;
  var unusedCharacterCount = 0;
  var scenesWithUnusedCharacters = 0;
  var sharedTimestampCount = 0;
  var overlappingTypingCueCount = 0;
  var scenesWithTimelineWarnings = 0;
  String? firstEmptySceneId;
  String? firstSceneWithUnusedCharactersId;
  String? firstSceneWithTimelineWarningsId;

  for (final scene in project.scenes) {
    final sceneHealth = summarizeSceneHealth(scene);
    totalMessages += scene.messages.length;
    if (sceneHealth.hasMessages) {
      readyScenes++;
    } else {
      emptyScenes++;
      firstEmptySceneId ??= scene.id;
    }
    if (sceneHealth.hasMessages && sceneHealth.hasUnusedCharacters) {
      unusedCharacterCount += sceneHealth.unusedCharacterCount;
      scenesWithUnusedCharacters++;
      firstSceneWithUnusedCharactersId ??= scene.id;
    }
    sharedTimestampCount += sceneHealth.sharedTimestampCount;
    overlappingTypingCueCount += sceneHealth.overlappingTypingCueCount;
    if (sceneHealth.hasTimelineWarnings) {
      scenesWithTimelineWarnings++;
      firstSceneWithTimelineWarningsId ??= scene.id;
    }
  }

  return ProjectHealthSummary(
    totalScenes: project.scenes.length,
    readyScenes: readyScenes,
    emptyScenes: emptyScenes,
    totalMessages: totalMessages,
    unusedCharacterCount: unusedCharacterCount,
    scenesWithUnusedCharacters: scenesWithUnusedCharacters,
    sharedTimestampCount: sharedTimestampCount,
    overlappingTypingCueCount: overlappingTypingCueCount,
    scenesWithTimelineWarnings: scenesWithTimelineWarnings,
    firstEmptySceneId: firstEmptySceneId,
    firstSceneWithUnusedCharactersId: firstSceneWithUnusedCharactersId,
    firstSceneWithTimelineWarningsId: firstSceneWithTimelineWarningsId,
  );
}

PortfolioHealthSummary summarizePortfolioHealth(Iterable<Project> projects) {
  var totalProjects = 0;
  var totalScenes = 0;
  var readyScenes = 0;
  var emptyScenes = 0;
  var totalMessages = 0;
  var unusedCharacterCount = 0;
  var readyProjectCount = 0;
  var needsAttentionProjectCount = 0;
  var timelineWarningProjectCount = 0;
  var sharedTimestampCount = 0;
  var overlappingTypingCueCount = 0;
  var scenesWithTimelineWarnings = 0;
  String? firstReadyProjectId;
  String? firstNeedsAttentionProjectId;
  String? firstTimelineWarningProjectId;

  for (final project in projects) {
    totalProjects += 1;
    final projectHealth = summarizeProjectHealth(project);
    totalScenes += projectHealth.totalScenes;
    readyScenes += projectHealth.readyScenes;
    emptyScenes += projectHealth.emptyScenes;
    totalMessages += projectHealth.totalMessages;
    unusedCharacterCount += projectHealth.unusedCharacterCount;
    sharedTimestampCount += projectHealth.sharedTimestampCount;
    overlappingTypingCueCount += projectHealth.overlappingTypingCueCount;
    scenesWithTimelineWarnings += projectHealth.scenesWithTimelineWarnings;

    if (projectHealth.needsAttention) {
      needsAttentionProjectCount += 1;
      firstNeedsAttentionProjectId ??= project.id;
    } else {
      readyProjectCount += 1;
      firstReadyProjectId ??= project.id;
    }

    if (projectHealth.hasTimelineWarnings) {
      timelineWarningProjectCount += 1;
      firstTimelineWarningProjectId ??= project.id;
    }
  }

  return PortfolioHealthSummary(
    totalProjects: totalProjects,
    totalScenes: totalScenes,
    readyScenes: readyScenes,
    emptyScenes: emptyScenes,
    totalMessages: totalMessages,
    unusedCharacterCount: unusedCharacterCount,
    readyProjectCount: readyProjectCount,
    needsAttentionProjectCount: needsAttentionProjectCount,
    timelineWarningProjectCount: timelineWarningProjectCount,
    sharedTimestampCount: sharedTimestampCount,
    overlappingTypingCueCount: overlappingTypingCueCount,
    scenesWithTimelineWarnings: scenesWithTimelineWarnings,
    firstReadyProjectId: firstReadyProjectId,
    firstNeedsAttentionProjectId: firstNeedsAttentionProjectId,
    firstTimelineWarningProjectId: firstTimelineWarningProjectId,
  );
}

ProjectAttentionState summarizeProjectAttention(Project project) {
  final projectHealth = summarizeProjectHealth(project);

  if (!projectHealth.hasMessages) {
    return const ProjectAttentionState(
      kind: ProjectAttentionKind.noMessages,
      label: 'No messages yet',
      ctaLabel: 'Add First Message',
      intent: ProjectAttentionIntent.openEditor,
    );
  }

  if (projectHealth.emptyScenes > 0) {
    return const ProjectAttentionState(
      kind: ProjectAttentionKind.emptyScenes,
      label: 'Has empty scenes',
      ctaLabel: 'Finish Empty Scenes',
      intent: ProjectAttentionIntent.openEditor,
    );
  }

  if (projectHealth.unusedCharacterCount > 0) {
    return const ProjectAttentionState(
      kind: ProjectAttentionKind.needsLines,
      label: 'Characters need lines',
      ctaLabel: 'Review Scene Setup',
      intent: ProjectAttentionIntent.openEditor,
    );
  }

  return const ProjectAttentionState(
    kind: ProjectAttentionKind.ready,
    label: 'Ready for playback',
    ctaLabel: 'Open Playback',
    intent: ProjectAttentionIntent.openPlayback,
  );
}

String _formatCount(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}
