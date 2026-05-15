import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

class SceneHealthSummary {
  const SceneHealthSummary({
    required this.messageCount,
    required this.unusedCharacterNames,
  });

  final int messageCount;
  final List<String> unusedCharacterNames;

  bool get hasMessages => messageCount > 0;
  int get unusedCharacterCount => unusedCharacterNames.length;
  bool get hasUnusedCharacters => unusedCharacterNames.isNotEmpty;
  bool get needsAttention => !hasMessages || hasUnusedCharacters;

  String get statusLabel {
    if (!hasMessages) {
      return 'No messages yet';
    }
    if (!hasUnusedCharacters) {
      return 'Ready for playback';
    }
    return '${_formatCount(unusedCharacterCount, singular: 'character', plural: 'characters')} waiting for lines';
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
}

SceneHealthSummary summarizeSceneHealth(Scene scene) {
  final usedCharacterIds = <String>{
    for (final message in scene.messages) message.characterId,
  };
  final unusedCharacterNames = <String>[
    for (final character in scene.characters)
      if (!usedCharacterIds.contains(character.id)) character.displayName,
  ];

  return SceneHealthSummary(
    messageCount: scene.messages.length,
    unusedCharacterNames: unusedCharacterNames,
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
    required this.firstEmptySceneId,
    required this.firstSceneWithUnusedCharactersId,
  });

  final int totalScenes;
  final int readyScenes;
  final int emptyScenes;
  final int totalMessages;
  final int unusedCharacterCount;
  final int scenesWithUnusedCharacters;
  final String? firstEmptySceneId;
  final String? firstSceneWithUnusedCharactersId;

  bool get hasMessages => totalMessages > 0;
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
  String? firstEmptySceneId;
  String? firstSceneWithUnusedCharactersId;

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
  }

  return ProjectHealthSummary(
    totalScenes: project.scenes.length,
    readyScenes: readyScenes,
    emptyScenes: emptyScenes,
    totalMessages: totalMessages,
    unusedCharacterCount: unusedCharacterCount,
    scenesWithUnusedCharacters: scenesWithUnusedCharacters,
    firstEmptySceneId: firstEmptySceneId,
    firstSceneWithUnusedCharactersId: firstSceneWithUnusedCharactersId,
  );
}

String _formatCount(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}
