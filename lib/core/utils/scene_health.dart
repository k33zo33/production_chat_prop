import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

class SceneHealthSummary {
  const SceneHealthSummary({
    required this.messageCount,
    required this.unusedCharacterNames,
    required this.sharedTimestampCount,
    required this.sharedTimestampMessageCount,
    required this.overlappingTypingCueCount,
  });

  final int messageCount;
  final List<String> unusedCharacterNames;
  final int sharedTimestampCount;
  final int sharedTimestampMessageCount;
  final int overlappingTypingCueCount;

  bool get hasMessages => messageCount > 0;
  int get unusedCharacterCount => unusedCharacterNames.length;
  bool get hasUnusedCharacters => unusedCharacterNames.isNotEmpty;
  bool get hasTimelineWarnings =>
      sharedTimestampCount > 0 || overlappingTypingCueCount > 0;
  bool get needsAttention => !hasMessages || hasUnusedCharacters;

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
  final messageCountsBySecond = <int, int>{};
  final typingCueCountsBySecond = <int, int>{};

  for (final message in scene.messages) {
    messageCountsBySecond.update(
      message.timestampSeconds,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (message.showTypingBefore && message.timestampSeconds > 0) {
      final typingSecond = message.timestampSeconds - 1;
      typingCueCountsBySecond.update(
        typingSecond,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  var sharedTimestampCount = 0;
  var sharedTimestampMessageCount = 0;
  for (final count in messageCountsBySecond.values) {
    if (count > 1) {
      sharedTimestampCount++;
      sharedTimestampMessageCount += count;
    }
  }

  var overlappingTypingCueCount = 0;
  for (final count in typingCueCountsBySecond.values) {
    if (count > 1) {
      overlappingTypingCueCount++;
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
    overlappingTypingCueCount: overlappingTypingCueCount,
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

String _formatCount(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}
