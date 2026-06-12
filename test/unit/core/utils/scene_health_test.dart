import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('summarizeSceneHealth', () {
    test('flags staged characters that have no lines yet', () {
      const scene = Scene(
        id: 'scene-1',
        title: 'Blocking Pass',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Taylor',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: 'character-2',
            displayName: 'Jordan',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
        ],
        messages: [
          Message(
            id: 'message-1',
            characterId: 'character-1',
            text: 'Lead line is blocked in.',
            timestampSeconds: 0,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      );

      final summary = summarizeSceneHealth(scene);

      expect(summary.messageCount, 1);
      expect(summary.hasMessages, isTrue);
      expect(summary.unusedCharacterNames, ['Jordan']);
      expect(summary.statusLabel, '1 character waiting for lines');
      expect(summary.detailLabel, 'Jordan has no lines in this scene yet.');
      expect(summary.badgeState, SceneHealthBadgeState.needsLines);
      expect(summary.badgeLabel, 'Needs lines');
      expect(
        summary.badgeTooltip,
        '1 character waiting for lines • Jordan has no lines in this scene yet.',
      );
      expect(summary.hasTimelineWarnings, isFalse);
      expect(summary.sharedTimestampCount, 0);
      expect(summary.overlappingTypingCueCount, 0);
      expect(summary.needsAttention, isTrue);
    });

    test(
      'prioritizes empty-scene recovery messaging before unused characters',
      () {
        const scene = Scene(
          id: 'scene-2',
          title: 'Empty setup',
          styleId: 'studio_slate',
          aspectRatio: SceneAspectRatio.portrait9x16,
          characters: [
            Character(
              id: 'character-1',
              displayName: 'Mia',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
          ],
          messages: [],
        );

        final summary = summarizeSceneHealth(scene);

        expect(summary.hasMessages, isFalse);
        expect(summary.unusedCharacterCount, 1);
        expect(summary.statusLabel, 'No messages yet');
        expect(summary.badgeState, SceneHealthBadgeState.noMessages);
        expect(summary.badgeLabel, 'No messages');
        expect(
          summary.badgeTooltip,
          'No messages yet • Add at least one message before preview or export.',
        );
        expect(
          summary.detailLabel,
          'Add at least one message before preview or export.',
        );
        expect(summary.hasTimelineWarnings, isFalse);
        expect(summary.needsAttention, isTrue);
      },
    );

    test('surfaces shared timestamp and overlapping typing QA warnings', () {
      const scene = Scene(
        id: 'scene-qa',
        title: 'Playback stack',
        styleId: 'studio_slate',
        aspectRatio: SceneAspectRatio.portrait9x16,
        characters: [
          Character(
            id: 'character-1',
            displayName: 'Taylor',
            avatarPath: null,
            bubbleColor: '#2E90FA',
          ),
          Character(
            id: 'character-2',
            displayName: 'Jordan',
            avatarPath: null,
            bubbleColor: '#12B76A',
          ),
        ],
        messages: [
          Message(
            id: 'message-1',
            characterId: 'character-1',
            text: 'Cue one',
            timestampSeconds: 4,
            status: MessageStatus.sent,
            isIncoming: false,
            showTypingBefore: true,
          ),
          Message(
            id: 'message-2',
            characterId: 'character-2',
            text: 'Cue two',
            timestampSeconds: 4,
            status: MessageStatus.delivered,
            isIncoming: true,
            showTypingBefore: true,
          ),
          Message(
            id: 'message-3',
            characterId: 'character-1',
            text: 'Cue three',
            timestampSeconds: 7,
            status: MessageStatus.seen,
            isIncoming: false,
            showTypingBefore: false,
          ),
        ],
      );

      final summary = summarizeSceneHealth(scene);

      expect(summary.hasTimelineWarnings, isTrue);
      expect(summary.sharedTimestampCount, 1);
      expect(summary.sharedTimestampMessageCount, 2);
      expect(summary.sharedTimestampMessageIds, {'message-1', 'message-2'});
      expect(summary.overlappingTypingCueCount, 1);
      expect(
        summary.overlappingTypingCueMessageIds,
        {'message-1', 'message-2'},
      );
      expect(summary.timelineWarningMessageIds, {'message-1', 'message-2'});
      expect(summary.hasTimelineWarningForMessage('message-1'), isTrue);
      expect(summary.hasTimelineWarningForMessage('message-3'), isFalse);
      expect(
        summary.timelineWarningLabelForMessage('message-1'),
        'shared timestamp • overlapping typing cue',
      );
      expect(summary.timelineWarningLabelForMessage('message-3'), isNull);
      expect(
        summary.timelineStatusLabel,
        '1 shared timestamp • 1 overlapping typing cue',
      );
      expect(
        summary.timelineDetailLabel,
        '2 messages land on the same second and can stack in playback or export. '
        'Multiple typing indicators fire together and may feel crowded in compact previews.',
      );
      expect(summary.badgeState, SceneHealthBadgeState.timelineQa);
      expect(summary.badgeLabel, 'Timeline QA');
      expect(
        summary.badgeTooltip,
        '1 shared timestamp • 1 overlapping typing cue • '
        '2 messages land on the same second and can stack in playback or export. '
        'Multiple typing indicators fire together and may feel crowded in compact previews.',
      );
      expect(summary.needsAttention, isFalse);
    });

    test(
      'marks fully covered scenes as ready in the compact badge summary',
      () {
        const scene = Scene(
          id: 'scene-ready',
          title: 'Ready cue',
          styleId: 'studio_slate',
          aspectRatio: SceneAspectRatio.portrait9x16,
          characters: [
            Character(
              id: 'character-1',
              displayName: 'Taylor',
              avatarPath: null,
              bubbleColor: '#2E90FA',
            ),
          ],
          messages: [
            Message(
              id: 'message-1',
              characterId: 'character-1',
              text: 'Ready to export.',
              timestampSeconds: 2,
              status: MessageStatus.seen,
              isIncoming: false,
              showTypingBefore: false,
            ),
          ],
        );

        final summary = summarizeSceneHealth(scene);

        expect(summary.badgeState, SceneHealthBadgeState.ready);
        expect(summary.badgeLabel, 'Ready');
        expect(summary.badgeTooltip, 'Ready for playback and export.');
      },
    );
  });

  group('summarizeProjectHealth', () {
    test(
      'classifies project readiness for attention, timeline QA, and ready',
      () {
        final needsAttentionProject = Project(
          id: 'project-attention',
          name: 'Attention Project',
          type: ProjectType.other,
          createdAt: DateTime.utc(2026, 5, 6, 9),
          updatedAt: DateTime.utc(2026, 5, 6, 10),
          scenes: const [
            Scene(
              id: 'scene-empty',
              title: 'Empty Scene',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Mia',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
              ],
              messages: [],
            ),
          ],
        );

        final timelineQaProject = Project(
          id: 'project-timeline',
          name: 'Timeline Project',
          type: ProjectType.series,
          createdAt: DateTime.utc(2026, 5, 6, 11),
          updatedAt: DateTime.utc(2026, 5, 6, 12),
          scenes: const [
            Scene(
              id: 'scene-qa',
              title: 'Stacked Cue',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Taylor',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
                Character(
                  id: 'character-2',
                  displayName: 'Jordan',
                  avatarPath: null,
                  bubbleColor: '#12B76A',
                ),
              ],
              messages: [
                Message(
                  id: 'message-1',
                  characterId: 'character-1',
                  text: 'Cue one',
                  timestampSeconds: 4,
                  status: MessageStatus.sent,
                  isIncoming: false,
                  showTypingBefore: true,
                ),
                Message(
                  id: 'message-2',
                  characterId: 'character-2',
                  text: 'Cue two',
                  timestampSeconds: 4,
                  status: MessageStatus.delivered,
                  isIncoming: true,
                  showTypingBefore: true,
                ),
              ],
            ),
          ],
        );

        final readyProject = Project(
          id: 'project-ready',
          name: 'Ready Project',
          type: ProjectType.ad,
          createdAt: DateTime.utc(2026, 5, 6, 13),
          updatedAt: DateTime.utc(2026, 5, 6, 14),
          scenes: const [
            Scene(
              id: 'scene-ready',
              title: 'Ready Scene',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Taylor',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
              ],
              messages: [
                Message(
                  id: 'message-1',
                  characterId: 'character-1',
                  text: 'Ready to export.',
                  timestampSeconds: 2,
                  status: MessageStatus.seen,
                  isIncoming: false,
                  showTypingBefore: false,
                ),
              ],
            ),
          ],
        );

        expect(
          summarizeProjectReadiness(needsAttentionProject),
          ProjectReadinessState.needsAttention,
        );
        expect(
          summarizeProjectReadiness(timelineQaProject),
          ProjectReadinessState.timelineQa,
        );
        expect(
          summarizeProjectReadiness(readyProject),
          ProjectReadinessState.ready,
        );
      },
    );

    test('aggregates empty scenes and staged characters across a project', () {
      final project = Project(
        id: 'project-1',
        name: 'Launch Spot',
        type: ProjectType.ad,
        createdAt: DateTime.utc(2026, 5, 1, 9),
        updatedAt: DateTime.utc(2026, 5, 1, 10),
        scenes: const [
          Scene(
            id: 'scene-empty',
            title: 'Cold open',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Mia',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
            ],
            messages: [],
          ),
          Scene(
            id: 'scene-staged',
            title: 'Reply cue',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Mia',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
              Character(
                id: 'character-2',
                displayName: 'Jordan',
                avatarPath: null,
                bubbleColor: '#12B76A',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'Camera is rolling.',
                timestampSeconds: 2,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: false,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.totalScenes, 2);
      expect(summary.readyScenes, 0);
      expect(summary.emptyScenes, 1);
      expect(summary.totalMessages, 1);
      expect(summary.unusedCharacterCount, 1);
      expect(summary.scenesWithUnusedCharacters, 1);
      expect(summary.sharedTimestampCount, 0);
      expect(summary.overlappingTypingCueCount, 0);
      expect(summary.scenesWithTimelineWarnings, 0);
      expect(summary.firstEmptySceneId, 'scene-empty');
      expect(summary.firstSceneWithUnusedCharactersId, 'scene-staged');
      expect(summary.firstAttentionSceneId, 'scene-empty');
      expect(summary.needsAttention, isTrue);

      final attention = summarizeProjectAttention(project);
      expect(attention.kind, ProjectAttentionKind.emptyScenes);
      expect(attention.label, 'Has empty scenes');
      expect(attention.ctaLabel, 'Finish Empty Scenes');
      expect(attention.intent, ProjectAttentionIntent.openEditor);
    });

    test('marks fully covered projects as ready', () {
      final project = Project(
        id: 'project-2',
        name: 'Ready Scene',
        type: ProjectType.series,
        createdAt: DateTime.utc(2026, 5, 1, 9),
        updatedAt: DateTime.utc(2026, 5, 1, 10),
        scenes: const [
          Scene(
            id: 'scene-ready',
            title: 'Take one',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Taylor',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'We are good to go.',
                timestampSeconds: 0,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: false,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.readyScenes, 1);
      expect(summary.emptyScenes, 0);
      expect(summary.unusedCharacterCount, 0);
      expect(summary.hasTimelineWarnings, isFalse);
      expect(summary.firstAttentionSceneId, isNull);
      expect(summary.needsAttention, isFalse);

      final attention = summarizeProjectAttention(project);
      expect(attention.kind, ProjectAttentionKind.ready);
      expect(attention.label, 'Ready for playback');
      expect(attention.ctaLabel, 'Open Playback');
      expect(attention.intent, ProjectAttentionIntent.openPlayback);
    });

    test('aggregates timeline QA warnings without flipping readiness', () {
      final project = Project(
        id: 'project-qa',
        name: 'QA pass',
        type: ProjectType.other,
        createdAt: DateTime.utc(2026, 5, 2, 9),
        updatedAt: DateTime.utc(2026, 5, 2, 10),
        scenes: const [
          Scene(
            id: 'scene-qa',
            title: 'Stacked cue',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Taylor',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
              Character(
                id: 'character-2',
                displayName: 'Jordan',
                avatarPath: null,
                bubbleColor: '#12B76A',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'Cue one',
                timestampSeconds: 4,
                status: MessageStatus.sent,
                isIncoming: false,
                showTypingBefore: true,
              ),
              Message(
                id: 'message-2',
                characterId: 'character-2',
                text: 'Cue two',
                timestampSeconds: 4,
                status: MessageStatus.delivered,
                isIncoming: true,
                showTypingBefore: true,
              ),
            ],
          ),
        ],
      );

      final summary = summarizeProjectHealth(project);

      expect(summary.readyScenes, 1);
      expect(summary.hasTimelineWarnings, isTrue);
      expect(summary.sharedTimestampCount, 1);
      expect(summary.overlappingTypingCueCount, 1);
      expect(summary.scenesWithTimelineWarnings, 1);
      expect(summary.firstSceneWithTimelineWarningsId, 'scene-qa');
      expect(summary.needsAttention, isFalse);
      expect(summary.firstAttentionSceneId, isNull);

      final attention = summarizeProjectAttention(project);
      expect(attention.kind, ProjectAttentionKind.ready);
      expect(attention.label, 'Ready for playback');
      expect(attention.intent, ProjectAttentionIntent.openPlayback);
    });

    test(
      'prioritizes empty scenes over staged characters for project attention',
      () {
        final project = Project(
          id: 'project-empty-scenes',
          name: 'Staging pass',
          type: ProjectType.other,
          createdAt: DateTime.utc(2026, 5, 4, 9),
          updatedAt: DateTime.utc(2026, 5, 4, 10),
          scenes: const [
            Scene(
              id: 'scene-empty',
              title: 'Empty scene',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Mia',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
              ],
              messages: [],
            ),
            Scene(
              id: 'scene-staged',
              title: 'Staged scene',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Mia',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
                Character(
                  id: 'character-2',
                  displayName: 'Jordan',
                  avatarPath: null,
                  bubbleColor: '#12B76A',
                ),
              ],
              messages: [
                Message(
                  id: 'message-1',
                  characterId: 'character-1',
                  text: 'Waiting on response.',
                  timestampSeconds: 3,
                  status: MessageStatus.sent,
                  isIncoming: false,
                  showTypingBefore: false,
                ),
              ],
            ),
          ],
        );

        final attention = summarizeProjectAttention(project);

        expect(attention.kind, ProjectAttentionKind.emptyScenes);
        expect(attention.label, 'Has empty scenes');
        expect(attention.ctaLabel, 'Finish Empty Scenes');
        expect(attention.intent, ProjectAttentionIntent.openEditor);
      },
    );

    test('surfaces staged characters when that is the main blocking issue', () {
      final project = Project(
        id: 'project-staged-characters',
        name: 'Character pass',
        type: ProjectType.other,
        createdAt: DateTime.utc(2026, 5, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 5, 10),
        scenes: const [
          Scene(
            id: 'scene-staged',
            title: 'Reply cue',
            styleId: 'studio_slate',
            aspectRatio: SceneAspectRatio.portrait9x16,
            characters: [
              Character(
                id: 'character-1',
                displayName: 'Mia',
                avatarPath: null,
                bubbleColor: '#2E90FA',
              ),
              Character(
                id: 'character-2',
                displayName: 'Jordan',
                avatarPath: null,
                bubbleColor: '#12B76A',
              ),
            ],
            messages: [
              Message(
                id: 'message-1',
                characterId: 'character-1',
                text: 'Holding for the reply.',
                timestampSeconds: 6,
                status: MessageStatus.delivered,
                isIncoming: false,
                showTypingBefore: false,
              ),
            ],
          ),
        ],
      );

      final attention = summarizeProjectAttention(project);

      expect(attention.kind, ProjectAttentionKind.needsLines);
      expect(attention.label, 'Characters need lines');
      expect(attention.ctaLabel, 'Review Scene Setup');
      expect(attention.intent, ProjectAttentionIntent.openEditor);
    });
  });

  group('summarizePortfolioHealth', () {
    test(
      'aggregates readiness, attention, and timeline QA across projects',
      () {
        final attentionProject = Project(
          id: 'project-attention',
          name: 'Attention Project',
          type: ProjectType.ad,
          createdAt: DateTime.utc(2026, 5, 6, 9),
          updatedAt: DateTime.utc(2026, 5, 6, 10),
          scenes: const [
            Scene(
              id: 'scene-empty',
              title: 'Empty Scene',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Mia',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
              ],
              messages: [],
            ),
          ],
        );

        final timelineProject = Project(
          id: 'project-timeline',
          name: 'Timeline Project',
          type: ProjectType.series,
          createdAt: DateTime.utc(2026, 5, 6, 11),
          updatedAt: DateTime.utc(2026, 5, 6, 12),
          scenes: const [
            Scene(
              id: 'scene-qa',
              title: 'Stacked Cue',
              styleId: 'studio_slate',
              aspectRatio: SceneAspectRatio.portrait9x16,
              characters: [
                Character(
                  id: 'character-1',
                  displayName: 'Taylor',
                  avatarPath: null,
                  bubbleColor: '#2E90FA',
                ),
                Character(
                  id: 'character-2',
                  displayName: 'Jordan',
                  avatarPath: null,
                  bubbleColor: '#12B76A',
                ),
              ],
              messages: [
                Message(
                  id: 'message-1',
                  characterId: 'character-1',
                  text: 'Cue one',
                  timestampSeconds: 4,
                  status: MessageStatus.sent,
                  isIncoming: false,
                  showTypingBefore: true,
                ),
                Message(
                  id: 'message-2',
                  characterId: 'character-2',
                  text: 'Cue two',
                  timestampSeconds: 4,
                  status: MessageStatus.delivered,
                  isIncoming: true,
                  showTypingBefore: true,
                ),
              ],
            ),
          ],
        );

        final summary = summarizePortfolioHealth([
          attentionProject,
          timelineProject,
        ]);

        expect(summary.totalProjects, 2);
        expect(summary.totalScenes, 2);
        expect(summary.readyScenes, 1);
        expect(summary.emptyScenes, 1);
        expect(summary.totalMessages, 2);
        expect(summary.unusedCharacterCount, 0);
        expect(summary.readyProjectCount, 1);
        expect(summary.needsAttentionProjectCount, 1);
        expect(summary.timelineWarningProjectCount, 1);
        expect(summary.sharedTimestampCount, 1);
        expect(summary.overlappingTypingCueCount, 1);
        expect(summary.scenesWithTimelineWarnings, 1);
        expect(summary.firstReadyProjectId, 'project-timeline');
        expect(summary.firstNeedsAttentionProjectId, 'project-attention');
        expect(summary.firstTimelineWarningProjectId, 'project-timeline');
        expect(summary.primaryProjectId, 'project-attention');
        expect(summary.hasProjects, isTrue);
        expect(summary.hasMessages, isTrue);
        expect(summary.needsAttention, isTrue);
        expect(summary.hasTimelineWarnings, isTrue);
      },
    );

    test('returns stable empty-state values for an empty portfolio', () {
      final summary = summarizePortfolioHealth(const <Project>[]);

      expect(summary.totalProjects, 0);
      expect(summary.totalScenes, 0);
      expect(summary.readyScenes, 0);
      expect(summary.emptyScenes, 0);
      expect(summary.totalMessages, 0);
      expect(summary.readyProjectCount, 0);
      expect(summary.needsAttentionProjectCount, 0);
      expect(summary.timelineWarningProjectCount, 0);
      expect(summary.firstReadyProjectId, isNull);
      expect(summary.firstNeedsAttentionProjectId, isNull);
      expect(summary.firstTimelineWarningProjectId, isNull);
      expect(summary.primaryProjectId, isNull);
      expect(summary.hasProjects, isFalse);
      expect(summary.hasMessages, isFalse);
      expect(summary.needsAttention, isTrue);
      expect(summary.hasTimelineWarnings, isFalse);
    });
  });
}
