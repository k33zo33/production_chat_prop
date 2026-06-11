import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

Map<String, dynamic> buildProjectQaPayload(Project project) {
  final summary = summarizeProjectHealth(project);
  return {
    'totalScenes': summary.totalScenes,
    'readyScenes': summary.readyScenes,
    'emptyScenes': summary.emptyScenes,
    'totalMessages': summary.totalMessages,
    'unusedCharacterCount': summary.unusedCharacterCount,
    'scenesWithUnusedCharacters': summary.scenesWithUnusedCharacters,
    'sharedTimestampCount': summary.sharedTimestampCount,
    'overlappingTypingCueCount': summary.overlappingTypingCueCount,
    'scenesWithTimelineWarnings': summary.scenesWithTimelineWarnings,
    'hasMessages': summary.hasMessages,
    'hasTimelineWarnings': summary.hasTimelineWarnings,
    'needsAttention': summary.needsAttention,
    'firstEmptySceneId': summary.firstEmptySceneId,
    'firstSceneWithUnusedCharactersId':
        summary.firstSceneWithUnusedCharactersId,
    'firstSceneWithTimelineWarningsId':
        summary.firstSceneWithTimelineWarningsId,
    'firstAttentionSceneId': summary.firstAttentionSceneId,
  };
}

Map<String, dynamic> buildSceneQaPayload(Scene scene) {
  final summary = summarizeSceneHealth(scene);
  return {
    'id': scene.id,
    'title': scene.title,
    'messageCount': summary.messageCount,
    'hasMessages': summary.hasMessages,
    'unusedCharacterCount': summary.unusedCharacterCount,
    'unusedCharacterNames': summary.unusedCharacterNames,
    'sharedTimestampCount': summary.sharedTimestampCount,
    'sharedTimestampMessageCount': summary.sharedTimestampMessageCount,
    'sharedTimestampMessageIds': _sortedIds(summary.sharedTimestampMessageIds),
    'overlappingTypingCueCount': summary.overlappingTypingCueCount,
    'overlappingTypingCueMessageIds': _sortedIds(
      summary.overlappingTypingCueMessageIds,
    ),
    'hasTimelineWarnings': summary.hasTimelineWarnings,
    'timelineWarningMessageIds': _sortedIds(summary.timelineWarningMessageIds),
    'needsAttention': summary.needsAttention,
    'statusLabel': summary.statusLabel,
    'detailLabel': summary.detailLabel,
    'timelineStatusLabel': summary.timelineStatusLabel,
    'timelineDetailLabel': summary.timelineDetailLabel,
  };
}

List<Map<String, dynamic>> buildSceneQaPayloadList(Iterable<Scene> scenes) {
  return scenes.map(buildSceneQaPayload).toList(growable: false);
}

List<String> _sortedIds(Set<String> ids) {
  final values = ids.toList(growable: false)..sort();
  return values;
}
