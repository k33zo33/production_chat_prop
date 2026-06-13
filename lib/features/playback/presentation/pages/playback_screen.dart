import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/core/utils/app_breakpoints.dart';
import 'package:production_chat_prop/core/utils/character_bubble_colors.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/core/utils/scene_health.dart';
import 'package:production_chat_prop/core/widgets/app_content_frame.dart';
import 'package:production_chat_prop/core/widgets/centered_scrollable_state.dart';
import 'package:production_chat_prop/core/widgets/character_avatar.dart';
import 'package:production_chat_prop/core/widgets/compact_scene_selector.dart';
import 'package:production_chat_prop/core/widgets/export_preflight_badge.dart';
import 'package:production_chat_prop/core/widgets/project_not_found_recovery_state.dart';
import 'package:production_chat_prop/core/widgets/scene_status_badge.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/playback/data/services/video_export_fallback_service.dart';
import 'package:production_chat_prop/features/playback/domain/playback_timeline.dart';
import 'package:production_chat_prop/features/playback/presentation/controllers/playback_controller.dart';
import 'package:production_chat_prop/features/projects/domain/character.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

final screenshotExportServiceProvider = Provider<ScreenshotExportService>((
  ref,
) {
  return ScreenshotExportService();
});

final videoExportFallbackServiceProvider = Provider<VideoExportFallbackService>(
  (
    ref,
  ) {
    return VideoExportFallbackService();
  },
);

const _kPlaybackDesktopContentMaxWidth = 1440.0;
const _kPlaybackPortraitPreviewMaxWidth = 560.0;
const _kPlaybackLandscapePreviewMaxWidth = 1040.0;
const _kFocusPreviewGestureSeekSeconds = 5;
const _kFocusPreviewEdgeTapRatio = 0.32;
const _kFocusPreviewFlingVelocityThreshold = 320.0;

class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({
    super.key,
    this.projectId,
    this.initialSceneId,
  });

  final String? projectId;
  final String? initialSceneId;

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  String? _lastAppliedInitialSceneKey;
  String? _pendingInitialSceneKey;
  String? _lastSyncedRouteSceneKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyInitialSceneSelectionIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PlaybackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyInitialSceneSelectionIfNeeded();
  }

  void _applyInitialSceneSelectionIfNeeded() {
    final projectId = widget.projectId;
    final initialSceneId = widget.initialSceneId;
    if (projectId == null || initialSceneId == null) {
      return;
    }

    final selectionKey = '$projectId::$initialSceneId';
    if (_lastAppliedInitialSceneKey == selectionKey) {
      return;
    }
    _lastAppliedInitialSceneKey = selectionKey;
    _pendingInitialSceneKey = selectionKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(sceneSelectionProvider(projectId).notifier).selectedSceneId =
          initialSceneId;
      _pendingInitialSceneKey = null;
    });
  }

  void _syncSelectedSceneIntoRoute({
    required String projectId,
    required String selectedSceneId,
  }) {
    if (GoRouter.maybeOf(context) == null) {
      return;
    }

    final currentState = GoRouterState.of(context);

    if (currentState.pathParameters['projectId'] != projectId) {
      return;
    }

    final currentSceneId = currentState.uri.queryParameters['sceneId'];
    final syncKey = '$projectId::$selectedSceneId::${currentSceneId ?? ''}';
    if (_lastSyncedRouteSceneKey == syncKey) {
      return;
    }

    if (currentSceneId == selectedSceneId) {
      _lastSyncedRouteSceneKey = syncKey;
      return;
    }

    _lastSyncedRouteSceneKey = syncKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (GoRouter.maybeOf(context) == null) {
        return;
      }

      final refreshedState = GoRouterState.of(context);

      if (refreshedState.pathParameters['projectId'] != projectId) {
        return;
      }

      final refreshedSceneId = refreshedState.uri.queryParameters['sceneId'];
      if (refreshedSceneId == selectedSceneId) {
        _lastSyncedRouteSceneKey = syncKey;
        return;
      }

      context.replaceNamed(
        'playbackProject',
        pathParameters: {'projectId': projectId},
        queryParameters: _sceneRouteQueryParameters(selectedSceneId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final viewportSize = MediaQuery.sizeOf(context);
    final isCompactAppBar = AppBreakpoints.shouldUseCompactLayout(
      viewportSize,
      textScaleFactor: textScaleFactor,
    );

    if (widget.projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playback')),
        body: CenteredScrollableState(
          scrollViewKey: const Key('playbackNoProjectScrollView'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No project selected.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.goNamed('projects'),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Back to Projects'),
              ),
            ],
          ),
        ),
      );
    }

    final activeProjectId = widget.projectId!;
    final snapshotState = ref.watch(sceneSnapshotProvider(activeProjectId));
    final selectedSceneId = ref.watch(sceneSelectionProvider(activeProjectId));
    // Prefer the scene already resolved by the snapshot so navigation matches
    // the scene currently shown in playback, including stale-selection fallbacks.
    final effectiveSceneId =
        snapshotState.asData?.value?.scene?.id ?? selectedSceneId;
    final canOpenEditor = snapshotState.asData?.value != null;
    final resolvedScene = snapshotState.asData?.value?.scene;
    final resolvedSceneHealth = resolvedScene == null
        ? null
        : summarizeSceneHealth(resolvedScene);
    final initialSceneId = widget.initialSceneId;
    final initialSceneKey = initialSceneId == null
        ? null
        : '$activeProjectId::$initialSceneId';
    final shouldDeferRouteSync =
        initialSceneKey != null &&
        selectedSceneId != initialSceneId &&
        _pendingInitialSceneKey == initialSceneKey &&
        snapshotState.asData?.value != null &&
        snapshotState.asData!.value!.project.scenes.any(
          (scene) => scene.id == initialSceneId,
        );

    if (!shouldDeferRouteSync &&
        resolvedScene != null &&
        resolvedScene.id.isNotEmpty) {
      _syncSelectedSceneIntoRoute(
        projectId: activeProjectId,
        selectedSceneId: resolvedScene.id,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback'),
        actions: _buildAppBarActions(
          context,
          activeProjectId: activeProjectId,
          selectedSceneId: effectiveSceneId,
          isCompactAppBar: isCompactAppBar,
          canOpenEditor: canOpenEditor,
          resolvedSceneHealth: resolvedSceneHealth,
        ),
      ),
      body: SafeArea(
        child: AppContentFrame(
          maxWidth: _kPlaybackDesktopContentMaxWidth,
          child: snapshotState.when(
            data: (snapshot) {
              if (snapshot == null) {
                return const ProjectNotFoundRecoveryState(
                  openRouteName: 'playbackProject',
                );
              }

              return _PlaybackTimeline(
                snapshot: snapshot,
                onSceneSelected: (sceneId) {
                  ref
                          .read(
                            sceneSelectionProvider(activeProjectId).notifier,
                          )
                          .selectedSceneId =
                      sceneId;
                  ref
                      .read(
                        playbackControllerProvider(activeProjectId).notifier,
                      )
                      .restart();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded),
                    const SizedBox(height: 12),
                    const Text('Unable to open playback.'),
                    const SizedBox(height: 8),
                    Text('$error', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context, {
    required String activeProjectId,
    required String? selectedSceneId,
    required bool isCompactAppBar,
    required bool canOpenEditor,
    required SceneHealthSummary? resolvedSceneHealth,
  }) {
    final sceneStatusBadge = resolvedSceneHealth == null
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: SceneStatusBadge(
              key: const Key('playbackSceneStatusBadge'),
              summary: resolvedSceneHealth,
              compact: isCompactAppBar,
            ),
          );

    if (!isCompactAppBar) {
      return [
        ?sceneStatusBadge,
        IconButton(
          key: const Key('playbackAppBarOpenEditorButton'),
          tooltip: 'Open Chat Editor',
          onPressed: canOpenEditor
              ? () => context.goNamed(
                  'editorProject',
                  pathParameters: {'projectId': activeProjectId},
                  queryParameters: _sceneRouteQueryParameters(selectedSceneId),
                )
              : null,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        IconButton(
          tooltip: 'Back to Projects',
          onPressed: () => context.goNamed('projects'),
          icon: const Icon(Icons.list_alt_rounded),
        ),
      ];
    }

    return [
      ?sceneStatusBadge,
      PopupMenuButton<_PlaybackAppBarAction>(
        key: const Key('playbackOverflowMenuButton'),
        tooltip: 'Playback actions',
        onSelected: (action) {
          switch (action) {
            case _PlaybackAppBarAction.openChatEditor:
              context.goNamed(
                'editorProject',
                pathParameters: {'projectId': activeProjectId},
                queryParameters: _sceneRouteQueryParameters(selectedSceneId),
              );
              return;
            case _PlaybackAppBarAction.backToProjects:
              context.goNamed('projects');
              return;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _PlaybackAppBarAction.openChatEditor,
            enabled: canOpenEditor,
            child: const Text('Open Chat Editor'),
          ),
          const PopupMenuItem(
            value: _PlaybackAppBarAction.backToProjects,
            child: Text('Back to Projects'),
          ),
        ],
      ),
    ];
  }
}

enum _PlaybackAppBarAction {
  openChatEditor,
  backToProjects,
}

Map<String, String> _sceneRouteQueryParameters(String? sceneId) {
  if (sceneId == null) {
    return const <String, String>{};
  }

  return {'sceneId': sceneId};
}

class _PlaybackTimeline extends ConsumerStatefulWidget {
  const _PlaybackTimeline({
    required this.snapshot,
    required this.onSceneSelected,
  });

  final SceneSnapshot snapshot;
  final ValueChanged<String> onSceneSelected;

  @override
  ConsumerState<_PlaybackTimeline> createState() => _PlaybackTimelineState();
}

class _PlaybackTimelineState extends ConsumerState<_PlaybackTimeline> {
  bool _showDeviceFrame = true;
  bool _cleanPreview = false;
  bool _isExporting = false;
  bool _isApplyingTemplate = false;
  _ExportState _lastExportState = _ExportState.idle;
  final GlobalKey _previewBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _schedulePlaybackSync(
      previousSceneId: null,
      currentSceneId: widget.snapshot.scene?.id,
    );
  }

  Future<void> _openFocusPreview({required Project project}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _PlaybackFocusPreviewScreen(
          projectId: project.id,
          initialShowDeviceFrame: _showDeviceFrame,
          initialCleanPreview: _cleanPreview,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _PlaybackTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePlaybackSync(
      previousSceneId: oldWidget.snapshot.scene?.id,
      currentSceneId: widget.snapshot.scene?.id,
    );
  }

  void _schedulePlaybackSync({
    required String? previousSceneId,
    required String? currentSceneId,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncPlaybackWithScene(
        previousSceneId: previousSceneId,
        currentSceneId: currentSceneId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.snapshot.project;
    final scene = widget.snapshot.scene;
    final selectedAspectRatio =
        scene?.aspectRatio ?? SceneAspectRatio.portrait9x16;
    final sortedMessages = scene == null
        ? <Message>[]
        : sortMessagesByTimeline(scene.messages);
    final palette = resolveChatStylePalette(scene?.styleId ?? 'studio_default');
    final exportTargetPixelSize =
        ScreenshotExportService.targetPixelSizeForAspectRatio(
          selectedAspectRatio,
        );
    final speakerNameById = _buildSpeakerNameById(project);
    final characterAvatarPathById = {
      for (final character in scene?.characters ?? const <Character>[])
        character.id: character.avatarPath,
    };
    final characterBubbleColorById = {
      for (final character in scene?.characters ?? const <Character>[])
        character.id: character.bubbleColor,
    };
    final maxSecond = sortedMessages.isEmpty
        ? 0
        : sortedMessages.last.timestampSeconds;

    final playbackState = ref.watch(playbackControllerProvider(project.id));
    final playbackController = ref.read(
      playbackControllerProvider(project.id).notifier,
    );
    final screenshotExportService = ref.read(
      screenshotExportServiceProvider,
    );
    final videoExportFallbackService = ref.read(
      videoExportFallbackServiceProvider,
    );

    final hasPlaybackMessages = sortedMessages.isNotEmpty;
    final sceneHealth = scene == null ? null : summarizeSceneHealth(scene);
    final viewportSize = MediaQuery.sizeOf(context);
    final viewportWidth = viewportSize.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final isCompactLayout = AppBreakpoints.shouldUseCompactLayout(
      viewportSize,
      textScaleFactor: textScaleFactor,
    );
    final isUltraCompactLayout = AppBreakpoints.isUltraCompactLayoutWidth(
      viewportWidth,
      textScaleFactor: textScaleFactor,
    );
    final visibleMessagesCount = countVisibleMessagesAtSecond(
      sortedMessages: sortedMessages,
      currentSecond: playbackState.currentSecond,
    );
    final progressPercent = maxSecond == 0
        ? 0
        : ((playbackState.currentSecond / maxSecond) * 100).round().clamp(
            0,
            100,
          );
    final sliderMax = maxSecond > 0 ? maxSecond.toDouble() : 1.0;
    final sliderValue = playbackState.currentSecond > maxSecond
        ? maxSecond.toDouble()
        : playbackState.currentSecond.toDouble();
    final previousCue = findPreviousCueSecond(
      sortedMessages: sortedMessages,
      currentSecond: playbackState.currentSecond,
    );
    final nextCue = findNextCueSecond(
      sortedMessages: sortedMessages,
      currentSecond: playbackState.currentSecond,
    );
    final openChatEditorButton = FilledButton.icon(
      key: const Key('playbackOpenEditorButton'),
      onPressed: () => context.goNamed(
        'editorProject',
        pathParameters: {'projectId': project.id},
        queryParameters: _sceneRouteQueryParameters(scene?.id),
      ),
      icon: const Icon(Icons.chat_bubble_outline_rounded),
      label: const Text('Open Chat Editor'),
    );
    final backToProjectsButton = OutlinedButton.icon(
      key: const Key('playbackBackToProjectsButton'),
      onPressed: () => context.goNamed('projects'),
      icon: const Icon(Icons.list_alt_rounded),
      label: const Text('Back to Projects'),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (maxSecond == 0) {
            return KeyEventResult.handled;
          }
          if (playbackState.isPlaying) {
            playbackController.pause();
          } else {
            playbackController.play(maxSecond: maxSecond);
          }
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (maxSecond == 0) {
            return KeyEventResult.handled;
          }
          playbackController.seekBy(delta: 1, maxSecond: maxSecond);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (maxSecond == 0) {
            return KeyEventResult.handled;
          }
          playbackController.seekBy(delta: -1, maxSecond: maxSecond);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.keyR) {
          if (!hasPlaybackMessages && playbackState.currentSecond == 0) {
            return KeyEventResult.handled;
          }
          playbackController.restart();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: ListView(
        key: const Key('playbackPageScrollView'),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: project.name,
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    key: const Key('playbackSceneLabel'),
                    'Scene: ${scene?.title ?? 'No scene'}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('playbackMessageCountLabel'),
                    'Messages: ${sortedMessages.length}',
                  ),
                  if (project.scenes.length > 1) ...[
                    const SizedBox(height: 12),
                    if (isCompactLayout) ...[
                      CompactSceneSelector(
                        dropdownKey: const Key('compactPlaybackSceneDropdown'),
                        summaryKey: const Key('compactPlaybackSceneSummary'),
                        value: scene?.id,
                        summary: buildCompactSceneSummary(
                          selectedSceneIndex: project.scenes.indexWhere(
                            (item) => item.id == scene?.id,
                          ),
                          totalScenes: project.scenes.length,
                          messageCount: sortedMessages.length,
                          maxSecond: maxSecond,
                        ),
                        items: [
                          for (final item in project.scenes)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (sceneId) {
                          if (sceneId != null) {
                            widget.onSceneSelected(sceneId);
                          }
                        },
                      ),
                    ] else
                      KeyedSubtree(
                        key: ValueKey<String?>(
                          'playbackSceneDropdown_${scene?.id}',
                        ),
                        child: DropdownButtonFormField<String>(
                          key: const Key('playbackSceneDropdown'),
                          initialValue: scene?.id,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Selected Scene',
                          ),
                          items: [
                            for (final item in project.scenes)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(item.title),
                              ),
                          ],
                          onChanged: (sceneId) {
                            if (sceneId != null) {
                              widget.onSceneSelected(sceneId);
                            }
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('playbackDeviceFrameSwitch'),
                    value: _showDeviceFrame,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Device Frame'),
                    onChanged: (value) {
                      setState(() {
                        _showDeviceFrame = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    key: const Key('playbackCleanPreviewSwitch'),
                    value: _cleanPreview,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clean Preview Mode'),
                    onChanged: (value) {
                      setState(() {
                        _cleanPreview = value;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview: ${_showDeviceFrame ? 'framed' : 'frameless'} • ${_cleanPreview ? 'clean' : 'full'} • Export: ${_exportStateLabel(_lastExportState)}',
                  ),
                  const SizedBox(height: 8),
                  if (scene != null && sceneHealth != null)
                    ExportPreflightBadge(
                      project: project,
                      scene: scene,
                      sceneHealth: sceneHealth,
                      exportTargetPixelSize: exportTargetPixelSize,
                      includeDeviceFrame: _showDeviceFrame,
                      cleanPreview: _cleanPreview,
                    )
                  else
                    const Text(
                      key: Key('exportReadinessLabel'),
                      'Export readiness: No scene selected',
                    ),
                  if (sceneHealth != null && sceneHealth.needsAttention) ...[
                    const SizedBox(height: 4),
                    Text(
                      key: const Key('playbackSceneHealthLabel'),
                      'Scene health: ${sceneHealth.statusLabel} • ${sceneHealth.detailLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (sceneHealth != null &&
                      sceneHealth.hasTimelineWarnings) ...[
                    const SizedBox(height: 4),
                    Text(
                      key: const Key('playbackSceneTimingQaLabel'),
                      'Timeline QA: ${sceneHealth.timelineStatusLabel} • ${sceneHealth.timelineDetailLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!hasPlaybackMessages) ...[
                    const SizedBox(height: 12),
                    _PlaybackEmptyStateActions(
                      scene: scene,
                      isCompactLayout: isCompactLayout,
                      onOpenChatEditor: () => context.goNamed(
                        'editorProject',
                        pathParameters: {'projectId': project.id},
                        queryParameters: _sceneRouteQueryParameters(scene?.id),
                      ),
                      onApplyTemplate: scene == null || _isApplyingTemplate
                          ? null
                          : (templateId, label) =>
                                _applySceneTemplateFromPlayback(
                                  projectId: project.id,
                                  sceneId: scene.id,
                                  templateId: templateId,
                                  label: label,
                                ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (scene != null) ...[
                    Text(
                      'Scene ratio: ${_aspectRatioLabel(scene.aspectRatio)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      key: const Key('exportTargetResolutionLabel'),
                      'Target screenshot output: '
                      '${exportTargetPixelSize.width.toInt()}×${exportTargetPixelSize.height.toInt()} PNG',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview scales to fit this screen. Export stays full resolution.',
                      key: const Key('exportPreviewScaleHintLabel'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          key: const Key('aspectRatioPortraitChip'),
                          label: const Text('9:16'),
                          selected:
                              scene.aspectRatio ==
                              SceneAspectRatio.portrait9x16,
                          onSelected: (selected) async {
                            if (!selected) {
                              return;
                            }
                            await _setSceneAspectRatio(
                              project: project,
                              scene: scene,
                              aspectRatio: SceneAspectRatio.portrait9x16,
                            );
                          },
                        ),
                        ChoiceChip(
                          key: const Key('aspectRatioLandscapeChip'),
                          label: const Text('16:9'),
                          selected:
                              scene.aspectRatio ==
                              SceneAspectRatio.landscape16x9,
                          onSelected: (selected) async {
                            if (!selected) {
                              return;
                            }
                            await _setSceneAspectRatio(
                              project: project,
                              scene: scene,
                              aspectRatio: SceneAspectRatio.landscape16x9,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _PlaybackExportActions(
                    isCompactLayout: isCompactLayout,
                    isUltraCompactLayout: isUltraCompactLayout,
                    isDisabled: sortedMessages.isEmpty || _isExporting,
                    onExportScreenshot: () async => _exportScreenshot(
                      project: project,
                      scene: scene,
                      screenshotExportService: screenshotExportService,
                    ),
                    onExportVideo: () async => _exportVideoFallback(
                      project: project,
                      scene: scene,
                      videoExportFallbackService: videoExportFallbackService,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('videoExportWorkflowHint'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Video export beta workflow',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Export Video currently saves a documented .json handoff package instead of a final encoded video file.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The package keeps the selected scene, aspect ratio, device-frame option, and clean-preview setting aligned for downstream render.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                key: const Key('copyVideoFallbackButton'),
                                onPressed:
                                    sortedMessages.isEmpty || _isExporting
                                    ? null
                                    : () => _copyVideoFallbackPackage(
                                        project: project,
                                        scene: scene,
                                        videoExportFallbackService:
                                            videoExportFallbackService,
                                      ),
                                icon: const Icon(Icons.content_copy_outlined),
                                label: const Text('Copy Handoff JSON'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Playback Controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    key: const Key('playbackStatusSummary'),
                    'Status: ${playbackState.status.name} • '
                    't=${playbackState.currentSecond}s / $maxSecond s '
                    '(${_formatTimecode(playbackState.currentSecond)} / ${_formatTimecode(maxSecond)})',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    key: const Key('playbackProgressSummary'),
                    'Progress: $progressPercent% • Visible messages: $visibleMessagesCount/${sortedMessages.length}',
                  ),
                  if (!isCompactLayout && hasPlaybackMessages) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Keyboard: Space play/pause • ←/→ seek • R restart',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Slider(
                    value: sliderValue,
                    max: sliderMax,
                    onChanged: hasPlaybackMessages
                        ? (value) {
                            playbackController.scrubTo(
                              second: value.round(),
                              maxSecond: maxSecond,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _PlaybackTransportControls(
                    isCompactLayout: isCompactLayout,
                    isUltraCompactLayout: isUltraCompactLayout,
                    isPlaying: playbackState.isPlaying,
                    previousCue: previousCue,
                    nextCue: nextCue,
                    onPrevCue: previousCue == null
                        ? null
                        : () => playbackController.scrubTo(
                            second: previousCue,
                            maxSecond: maxSecond,
                          ),
                    onNextCue: nextCue == null
                        ? null
                        : () => playbackController.scrubTo(
                            second: nextCue,
                            maxSecond: maxSecond,
                          ),
                    onSeekBackward5: maxSecond == 0
                        ? null
                        : () => playbackController.seekBy(
                            delta: -5,
                            maxSecond: maxSecond,
                          ),
                    onSeekBackward1: maxSecond == 0
                        ? null
                        : () => playbackController.seekBy(
                            delta: -1,
                            maxSecond: maxSecond,
                          ),
                    onPlay: maxSecond == 0
                        ? null
                        : () => playbackController.play(maxSecond: maxSecond),
                    onPause: playbackState.isPlaying
                        ? playbackController.pause
                        : null,
                    onRestart:
                        hasPlaybackMessages || playbackState.currentSecond > 0
                        ? playbackController.restart
                        : null,
                    onSeekForward1: maxSecond == 0
                        ? null
                        : () => playbackController.seekBy(
                            delta: 1,
                            maxSecond: maxSecond,
                          ),
                    onSeekForward5: maxSecond == 0
                        ? null
                        : () => playbackController.seekBy(
                            delta: 5,
                            maxSecond: maxSecond,
                          ),
                    onJumpToEnd: maxSecond == 0
                        ? null
                        : () => playbackController.jumpToEnd(
                            maxSecond: maxSecond,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PlaybackPreviewCard(
            sceneId: scene?.id,
            boundaryKey: _previewBoundaryKey,
            aspectRatio: selectedAspectRatio,
            palette: palette,
            showDeviceFrame: _showDeviceFrame,
            cleanPreview: _cleanPreview,
            currentSecond: playbackState.currentSecond,
            maxSecond: maxSecond,
            messages: sortedMessages,
            speakerNameById: speakerNameById,
            characterAvatarPathById: characterAvatarPathById,
            characterBubbleColorById: characterBubbleColorById,
            resolveSpeakerName: _resolveSpeakerName,
            showTypingIndicator: showsTypingIndicatorAtSecond,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('openPlaybackFocusPreviewButton'),
              onPressed: sortedMessages.isEmpty || scene == null
                  ? null
                  : () => _openFocusPreview(project: project),
              icon: const Icon(Icons.fullscreen_rounded),
              label: const Text('Open Focus Preview'),
            ),
          ),
          const SizedBox(height: 12),
          if (isUltraCompactLayout)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                openChatEditorButton,
                const SizedBox(height: 8),
                backToProjectsButton,
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [openChatEditorButton, backToProjectsButton],
            ),
        ],
      ),
    );
  }

  Future<void> _exportScreenshot({
    required Project project,
    required Scene? scene,
    required ScreenshotExportService screenshotExportService,
  }) async {
    if (_isExporting) {
      return;
    }
    if (scene == null) {
      _showSnackBar('Screenshot export failed: no scene selected.');
      return;
    }

    setState(() {
      _isExporting = true;
      _lastExportState = _ExportState.running;
    });
    final result = await screenshotExportService.exportBoundaryAsPng(
      boundaryKey: _previewBoundaryKey,
      projectName: project.name,
      sceneTitle: scene.title,
      aspectRatio: scene.aspectRatio,
    );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _lastExportState = _ExportState.screenshotOk;
        _isExporting = false;
      });
      _showSnackBar('Screenshot exported as ${result.filename}.');
      return;
    }

    final failureLabel = switch (result.failure) {
      ScreenshotExportFailure.missingBoundary => 'preview is not ready',
      ScreenshotExportFailure.captureFailed => 'capture could not complete',
      ScreenshotExportFailure.downloadUnavailable =>
        'download is not available on this platform',
      null => 'unknown error',
    };

    setState(() {
      _lastExportState = _ExportState.screenshotError;
      _isExporting = false;
    });
    _showSnackBar('Screenshot export failed: $failureLabel.');
  }

  Future<void> _exportVideoFallback({
    required Project project,
    required Scene? scene,
    required VideoExportFallbackService videoExportFallbackService,
  }) async {
    if (_isExporting) {
      return;
    }
    if (scene == null) {
      _showSnackBar('Video export failed: no scene selected.');
      return;
    }

    setState(() {
      _isExporting = true;
      _lastExportState = _ExportState.running;
    });
    final result = await videoExportFallbackService.exportFallbackPackage(
      project: project,
      scene: scene,
      includeDeviceFrame: _showDeviceFrame,
      cleanPreview: _cleanPreview,
    );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _lastExportState = _ExportState.videoOk;
        _isExporting = false;
      });
      _showSnackBar(
        'Video fallback package exported as ${result.filename}.',
      );
      return;
    }

    if (result.failure == VideoFallbackExportFailure.downloadUnavailable) {
      final copied = await _copyTextToClipboard(
        videoExportFallbackService.buildFallbackPackageJson(
          project: project,
          scene: scene,
          includeDeviceFrame: _showDeviceFrame,
          cleanPreview: _cleanPreview,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastExportState = copied
            ? _ExportState.videoOk
            : _ExportState.videoError;
        _isExporting = false;
      });
      _showSnackBar(
        copied
            ? 'Download unavailable. Video fallback JSON copied to clipboard.'
            : 'Video export failed: download is not available on this platform.',
      );
      return;
    }

    setState(() {
      _lastExportState = _ExportState.videoError;
      _isExporting = false;
    });
    _showSnackBar('Video export failed: unknown error.');
  }

  Future<void> _copyVideoFallbackPackage({
    required Project project,
    required Scene? scene,
    required VideoExportFallbackService videoExportFallbackService,
  }) async {
    if (_isExporting) {
      return;
    }
    if (scene == null) {
      _showSnackBar('Video handoff copy failed: no scene selected.');
      return;
    }

    final copied = await _copyTextToClipboard(
      videoExportFallbackService.buildFallbackPackageJson(
        project: project,
        scene: scene,
        includeDeviceFrame: _showDeviceFrame,
        cleanPreview: _cleanPreview,
      ),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _lastExportState = copied
          ? _ExportState.videoOk
          : _ExportState.videoError;
    });
    _showSnackBar(
      copied
          ? 'Video fallback JSON copied to clipboard.'
          : 'Video handoff copy failed: clipboard is not available on this platform.',
    );
  }

  Future<void> _setSceneAspectRatio({
    required Project project,
    required Scene scene,
    required SceneAspectRatio aspectRatio,
  }) async {
    if (scene.aspectRatio == aspectRatio) {
      return;
    }

    await ref
        .read(projectsControllerProvider.notifier)
        .updateSceneSettings(
          projectId: project.id,
          sceneId: scene.id,
          title: scene.title,
          styleId: scene.styleId,
          aspectRatio: aspectRatio,
        );
  }

  Future<void> _applySceneTemplateFromPlayback({
    required String projectId,
    required String sceneId,
    required String templateId,
    required String label,
  }) async {
    if (_isApplyingTemplate) {
      return;
    }

    setState(() {
      _isApplyingTemplate = true;
    });

    var applied = false;
    try {
      applied = await ref
          .read(projectsControllerProvider.notifier)
          .applySceneTemplate(
            projectId: projectId,
            sceneId: sceneId,
            templateId: templateId,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingTemplate = false;
        });
      }
    }
    if (!mounted) {
      return;
    }

    _showSnackBar(
      applied ? 'Applied template: $label' : 'Template could not be applied.',
    );
  }

  Future<bool> _copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } on PlatformException {
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _aspectRatioLabel(SceneAspectRatio value) {
    return switch (value) {
      SceneAspectRatio.portrait9x16 => '9:16',
      SceneAspectRatio.landscape16x9 => '16:9',
    };
  }

  String _exportStateLabel(_ExportState value) {
    return switch (value) {
      _ExportState.idle => 'Idle',
      _ExportState.running => 'Running',
      _ExportState.screenshotOk => 'Screenshot OK',
      _ExportState.screenshotError => 'Screenshot Error',
      _ExportState.videoOk => 'Video OK',
      _ExportState.videoError => 'Video Error',
    };
  }

  void _syncPlaybackWithScene({
    required String? previousSceneId,
    required String? currentSceneId,
  }) {
    final projectId = widget.snapshot.project.id;
    final playbackController = ref.read(
      playbackControllerProvider(projectId).notifier,
    );
    final playbackState = ref.read(playbackControllerProvider(projectId));
    final newMaxSecond = maxSecondForScene(widget.snapshot.scene);

    if (previousSceneId != currentSceneId) {
      playbackController.restart();
      return;
    }

    if (playbackState.currentSecond > newMaxSecond) {
      playbackController.scrubTo(
        second: newMaxSecond,
        maxSecond: newMaxSecond,
      );
    }
  }
}

enum _ExportState {
  idle,
  running,
  screenshotOk,
  screenshotError,
  videoOk,
  videoError,
}

class _PlaybackPreviewCard extends StatefulWidget {
  const _PlaybackPreviewCard({
    required this.sceneId,
    required this.boundaryKey,
    required this.aspectRatio,
    required this.palette,
    required this.showDeviceFrame,
    required this.cleanPreview,
    required this.currentSecond,
    required this.maxSecond,
    required this.messages,
    required this.speakerNameById,
    required this.characterAvatarPathById,
    required this.characterBubbleColorById,
    required this.resolveSpeakerName,
    required this.showTypingIndicator,
    this.maxPreviewHeight,
  });

  final String? sceneId;
  final GlobalKey boundaryKey;
  final SceneAspectRatio aspectRatio;
  final ChatStylePalette palette;
  final bool showDeviceFrame;
  final bool cleanPreview;
  final int currentSecond;
  final int maxSecond;
  final List<Message> messages;
  final Map<String, String> speakerNameById;
  final Map<String, String?> characterAvatarPathById;
  final Map<String, String> characterBubbleColorById;
  final String Function({
    required String characterId,
    required Map<String, String> speakerNameById,
  })
  resolveSpeakerName;
  final bool Function({
    required Message message,
    required int currentSecond,
  })
  showTypingIndicator;
  final double? maxPreviewHeight;

  @override
  State<_PlaybackPreviewCard> createState() => _PlaybackPreviewCardState();
}

class _PlaybackPreviewCardState extends State<_PlaybackPreviewCard> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeCueKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAutoFollow(
        previousCurrentSecond: null,
        previousActiveCueId: null,
        sceneChanged: false,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _PlaybackPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAutoFollow(
        previousCurrentSecond: oldWidget.currentSecond,
        previousActiveCueId: _activeCueIdFor(
          messages: oldWidget.messages,
          currentSecond: oldWidget.currentSecond,
        ),
        sceneChanged: oldWidget.sceneId != widget.sceneId,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncAutoFollow({
    required int? previousCurrentSecond,
    required String? previousActiveCueId,
    required bool sceneChanged,
  }) {
    if (!mounted || !_scrollController.hasClients || widget.messages.isEmpty) {
      return;
    }

    if (sceneChanged ||
        (previousCurrentSecond != null &&
            widget.currentSecond == 0 &&
            previousCurrentSecond != 0)) {
      _scrollController.jumpTo(0);
      return;
    }

    if (previousCurrentSecond == null && widget.currentSecond == 0) {
      return;
    }

    final currentActiveCueId = _activeCueId();
    if (currentActiveCueId == null ||
        currentActiveCueId == previousActiveCueId) {
      return;
    }

    final activeContext = _activeCueKey.currentContext;
    if (activeContext == null) {
      return;
    }

    unawaited(
      Scrollable.ensureVisible(
        activeContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0.92,
      ),
    );
  }

  String? _activeCueId() {
    return _activeCueIdFor(
      messages: widget.messages,
      currentSecond: widget.currentSecond,
    );
  }

  String? _activeCueIdFor({
    required List<Message> messages,
    required int currentSecond,
  }) {
    for (final message in messages) {
      if (widget.showTypingIndicator(
        message: message,
        currentSecond: currentSecond,
      )) {
        return 'typing-${message.id}';
      }
    }

    for (var index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      if (message.timestampSeconds <= currentSecond) {
        return 'message-${message.id}';
      }
    }

    return null;
  }

  Widget _wrapCue({
    required String cueId,
    required bool isActiveCue,
    required Widget child,
  }) {
    return Container(
      key: isActiveCue ? const Key('activePreviewCue') : ValueKey(cueId),
      child: Container(
        key: isActiveCue ? _activeCueKey : null,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCueId = _activeCueId();

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetPreviewWidth = switch (widget.aspectRatio) {
            SceneAspectRatio.portrait9x16 => _kPlaybackPortraitPreviewMaxWidth,
            SceneAspectRatio.landscape16x9 =>
              _kPlaybackLandscapePreviewMaxWidth,
          };
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : targetPreviewWidth;
          final previewAspectRatio = _aspectRatioValue(widget.aspectRatio);
          final constrainedMaxHeight = widget.maxPreviewHeight == null
              ? null
              : math.max(160, widget.maxPreviewHeight!).toDouble();
          final previewWidth = math
              .max(
                120,
                math.min(
                  math.min(targetPreviewWidth, availableWidth),
                  constrainedMaxHeight == null
                      ? double.infinity
                      : constrainedMaxHeight * previewAspectRatio,
                ),
              )
              .toDouble();
          final previewHeight = previewWidth / previewAspectRatio;
          final isShortPreview = AppBreakpoints.isShortPreviewHeight(
            previewHeight,
          );
          final isNarrowPreview = previewWidth < 180;
          final useCompactPreviewChrome = isShortPreview || isNarrowPreview;
          final effectiveShowDeviceFrame =
              widget.showDeviceFrame && !isNarrowPreview;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: previewWidth,
              child: AspectRatio(
                key: const Key('playbackPreviewAspectRatio'),
                aspectRatio: previewAspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveShowDeviceFrame
                        ? Colors.black
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      effectiveShowDeviceFrame ? 28 : 0,
                    ),
                    border: effectiveShowDeviceFrame
                        ? Border.all(color: Colors.black87, width: 6)
                        : null,
                    boxShadow: effectiveShowDeviceFrame
                        ? const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  padding: EdgeInsets.all(effectiveShowDeviceFrame ? 12 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      effectiveShowDeviceFrame ? 20 : 0,
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: widget.palette.surfaceColor,
                      child: Padding(
                        padding: EdgeInsets.all(
                          useCompactPreviewChrome ? 10 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.cleanPreview &&
                                useCompactPreviewChrome) ...[
                              Text(
                                'Timeline preview',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                            ] else if (!widget.cleanPreview) ...[
                              Text(
                                'Playback Timeline (read-only)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Timeline preview follows timecode: queued messages stay dim until their cue time.',
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (widget.cleanPreview)
                              Text(
                                'Preview • ${_formatTimecode(widget.currentSecond)} / ${_formatTimecode(widget.maxSecond)}',
                                key: const Key('cleanPreviewHeader'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: useCompactPreviewChrome
                                    ? Theme.of(context).textTheme.labelMedium
                                    : Theme.of(context).textTheme.labelLarge,
                              ),
                            if (widget.cleanPreview)
                              SizedBox(
                                height: useCompactPreviewChrome ? 8 : 12,
                              ),
                            Expanded(
                              child: widget.messages.isEmpty
                                  ? const Align(
                                      key: Key('playbackPreviewEmptyState'),
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'No messages available for playback yet. Add messages in Chat Editor to build the preview.',
                                        key: Key(
                                          'playbackPreviewEmptyStateText',
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      key: const Key(
                                        'playbackPreviewScrollView',
                                      ),
                                      controller: _scrollController,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (final message
                                              in widget.messages) ...[
                                            if (widget.showTypingIndicator(
                                              message: message,
                                              currentSecond:
                                                  widget.currentSecond,
                                            )) ...[
                                              _wrapCue(
                                                cueId: 'typing-${message.id}',
                                                isActiveCue:
                                                    activeCueId ==
                                                    'typing-${message.id}',
                                                child: _TypingIndicatorItem(
                                                  speakerName: widget
                                                      .resolveSpeakerName(
                                                        characterId:
                                                            message.characterId,
                                                        speakerNameById: widget
                                                            .speakerNameById,
                                                      ),
                                                  characterAvatarPath:
                                                      widget
                                                          .characterAvatarPathById[message
                                                          .characterId],
                                                  characterBubbleColor:
                                                      widget
                                                          .characterBubbleColorById[message
                                                          .characterId] ??
                                                      kDefaultCharacterBubbleColorHex,
                                                  palette: widget.palette,
                                                  isActiveCue:
                                                      activeCueId ==
                                                      'typing-${message.id}',
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            _wrapCue(
                                              cueId: 'message-${message.id}',
                                              isActiveCue:
                                                  activeCueId ==
                                                  'message-${message.id}',
                                              child: _TimelineItem(
                                                message: message,
                                                palette: widget.palette,
                                                speakerName: widget
                                                    .resolveSpeakerName(
                                                      characterId:
                                                          message.characterId,
                                                      speakerNameById: widget
                                                          .speakerNameById,
                                                    ),
                                                characterAvatarPath:
                                                    widget
                                                        .characterAvatarPathById[message
                                                        .characterId],
                                                characterBubbleColor:
                                                    widget
                                                        .characterBubbleColorById[message
                                                        .characterId] ??
                                                    kDefaultCharacterBubbleColorHex,
                                                isVisibleAtCurrentTime:
                                                    message.timestampSeconds <=
                                                    widget.currentSecond,
                                                cleanPreview:
                                                    widget.cleanPreview,
                                                isActiveCue:
                                                    activeCueId ==
                                                    'message-${message.id}',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaybackFocusPreviewScreen extends ConsumerStatefulWidget {
  const _PlaybackFocusPreviewScreen({
    required this.projectId,
    required this.initialShowDeviceFrame,
    required this.initialCleanPreview,
  });

  final String projectId;
  final bool initialShowDeviceFrame;
  final bool initialCleanPreview;

  @override
  ConsumerState<_PlaybackFocusPreviewScreen> createState() =>
      _PlaybackFocusPreviewScreenState();
}

class _PlaybackFocusPreviewScreenState
    extends ConsumerState<_PlaybackFocusPreviewScreen> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  Offset? _lastDoubleTapPosition;

  void _togglePlayback({
    required bool hasPlaybackMessages,
    required int maxSecond,
    required PlaybackState playbackState,
    required PlaybackController playbackController,
  }) {
    if (!hasPlaybackMessages) {
      return;
    }

    unawaited(Feedback.forTap(context));
    if (playbackState.isPlaying) {
      playbackController.pause();
    } else {
      playbackController.play(maxSecond: maxSecond);
    }
  }

  void _seekPreviewBy({
    required int delta,
    required int maxSecond,
    required PlaybackController playbackController,
  }) {
    if (maxSecond <= 0 || delta == 0) {
      return;
    }

    unawaited(Feedback.forTap(context));
    playbackController.seekBy(delta: delta, maxSecond: maxSecond);
  }

  void _jumpBetweenCuesFromDoubleTap({
    required double surfaceWidth,
    required int? previousCue,
    required int? nextCue,
    required bool hasPlaybackMessages,
    required int maxSecond,
    required PlaybackState playbackState,
    required PlaybackController playbackController,
  }) {
    final tapPosition = _lastDoubleTapPosition;
    if (tapPosition == null || surfaceWidth <= 0) {
      _togglePlayback(
        hasPlaybackMessages: hasPlaybackMessages,
        maxSecond: maxSecond,
        playbackState: playbackState,
        playbackController: playbackController,
      );
      return;
    }

    final dxRatio = tapPosition.dx / surfaceWidth;
    if (dxRatio <= _kFocusPreviewEdgeTapRatio) {
      unawaited(Feedback.forTap(context));
      if (previousCue != null) {
        playbackController.scrubTo(second: previousCue, maxSecond: maxSecond);
      } else {
        playbackController.seekBy(
          delta: -_kFocusPreviewGestureSeekSeconds,
          maxSecond: maxSecond,
        );
      }
      return;
    }

    if (dxRatio >= 1 - _kFocusPreviewEdgeTapRatio) {
      unawaited(Feedback.forTap(context));
      if (nextCue != null) {
        playbackController.scrubTo(second: nextCue, maxSecond: maxSecond);
      } else {
        playbackController.seekBy(
          delta: _kFocusPreviewGestureSeekSeconds,
          maxSecond: maxSecond,
        );
      }
      return;
    }

    _togglePlayback(
      hasPlaybackMessages: hasPlaybackMessages,
      maxSecond: maxSecond,
      playbackState: playbackState,
      playbackController: playbackController,
    );
  }

  void _handleHorizontalGestureSeek({
    required DragEndDetails details,
    required int maxSecond,
    required PlaybackController playbackController,
  }) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _kFocusPreviewFlingVelocityThreshold) {
      return;
    }

    _seekPreviewBy(
      delta: velocity > 0
          ? _kFocusPreviewGestureSeekSeconds
          : -_kFocusPreviewGestureSeekSeconds,
      maxSecond: maxSecond,
      playbackController: playbackController,
    );
  }

  KeyEventResult _handlePlaybackKeyEvent(
    KeyEvent event, {
    required bool hasPlaybackMessages,
    required int maxSecond,
    required PlaybackState playbackState,
    required PlaybackController playbackController,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (maxSecond == 0) {
        return KeyEventResult.handled;
      }
      if (playbackState.isPlaying) {
        playbackController.pause();
      } else {
        playbackController.play(maxSecond: maxSecond);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (maxSecond == 0) {
        return KeyEventResult.handled;
      }
      playbackController.seekBy(delta: 1, maxSecond: maxSecond);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (maxSecond == 0) {
        return KeyEventResult.handled;
      }
      playbackController.seekBy(delta: -1, maxSecond: maxSecond);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      if (!hasPlaybackMessages && playbackState.currentSecond == 0) {
        return KeyEventResult.handled;
      }
      playbackController.restart();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final snapshotState = ref.watch(sceneSnapshotProvider(widget.projectId));

    return Scaffold(
      key: const Key('playbackFocusPreviewScreen'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: snapshotState.when(
          data: (snapshot) {
            if (snapshot == null) {
              return Center(
                child: FilledButton.icon(
                  key: const Key('focusPreviewCloseFallbackButton'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  label: const Text('Close Focus Preview'),
                ),
              );
            }

            final project = snapshot.project;
            final scene = snapshot.scene;
            final selectedAspectRatio =
                scene?.aspectRatio ?? SceneAspectRatio.portrait9x16;
            final sortedMessages = scene == null
                ? <Message>[]
                : sortMessagesByTimeline(scene.messages);
            final palette = resolveChatStylePalette(
              scene?.styleId ?? 'studio_default',
            );
            final speakerNameById = _buildSpeakerNameById(project);
            final characterAvatarPathById = {
              for (final character in scene?.characters ?? const <Character>[])
                character.id: character.avatarPath,
            };
            final characterBubbleColorById = {
              for (final character in scene?.characters ?? const <Character>[])
                character.id: character.bubbleColor,
            };
            final playbackState = ref.watch(
              playbackControllerProvider(project.id),
            );
            final playbackController = ref.read(
              playbackControllerProvider(project.id).notifier,
            );
            final maxSecond = sortedMessages.isEmpty
                ? 0
                : sortedMessages.last.timestampSeconds;
            final hasPlaybackMessages = sortedMessages.isNotEmpty;
            final previousCue = findPreviousCueSecond(
              sortedMessages: sortedMessages,
              currentSecond: playbackState.currentSecond,
            );
            final nextCue = findNextCueSecond(
              sortedMessages: sortedMessages,
              currentSecond: playbackState.currentSecond,
            );
            final sliderMax = maxSecond > 0 ? maxSecond.toDouble() : 1.0;
            final sliderValue = playbackState.currentSecond > maxSecond
                ? maxSecond.toDouble()
                : playbackState.currentSecond.toDouble();
            final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

            return Focus(
              autofocus: true,
              onKeyEvent: (node, event) => _handlePlaybackKeyEvent(
                event,
                hasPlaybackMessages: hasPlaybackMessages,
                maxSecond: maxSecond,
                playbackState: playbackState,
                playbackController: playbackController,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactLayout =
                      AppBreakpoints.isCompactFilterWidth(
                        constraints.maxWidth,
                        textScaleFactor: textScaleFactor,
                      ) ||
                      AppBreakpoints.isCompactPreviewChromeHeight(
                        constraints.maxHeight,
                      );
                  final isUltraCompactLayout =
                      AppBreakpoints.isUltraCompactLayoutWidth(
                        constraints.maxWidth,
                        textScaleFactor: textScaleFactor,
                      ) ||
                      AppBreakpoints.isUltraCompactPreviewChromeHeight(
                        constraints.maxHeight,
                      );
                  final isShortHeightLayout =
                      AppBreakpoints.isCompactPreviewChromeHeight(
                        constraints.maxHeight,
                      );
                  final previewSidePadding = (isCompactLayout ? 12 : 16)
                      .toDouble();
                  final previewTopPadding =
                      (isShortHeightLayout
                              ? 52
                              : isCompactLayout
                              ? 56
                              : 72)
                          .toDouble();
                  final previewBottomPadding =
                      (isShortHeightLayout
                              ? 64
                              : isUltraCompactLayout
                              ? 72
                              : 88)
                          .toDouble();
                  final previewMaxHeight = math.max<double>(
                    AppBreakpoints.shortPreviewHeight,
                    constraints.maxHeight -
                        previewTopPadding -
                        previewBottomPadding,
                  );

                  void handlePreviewLongPress() {
                    unawaited(Feedback.forLongPress(context));
                    Navigator.of(context).pop();
                  }

                  Widget wrapPreviewGestures(Widget child, {Key? key}) {
                    return GestureDetector(
                      key: key,
                      behavior: HitTestBehavior.opaque,
                      onTap: hasPlaybackMessages
                          ? () => _togglePlayback(
                              hasPlaybackMessages: hasPlaybackMessages,
                              maxSecond: maxSecond,
                              playbackState: playbackState,
                              playbackController: playbackController,
                            )
                          : null,
                      onDoubleTapDown: (details) {
                        _lastDoubleTapPosition = details.localPosition;
                      },
                      onDoubleTap: hasPlaybackMessages
                          ? () => _jumpBetweenCuesFromDoubleTap(
                              surfaceWidth: constraints.maxWidth,
                              previousCue: previousCue,
                              nextCue: nextCue,
                              hasPlaybackMessages: hasPlaybackMessages,
                              maxSecond: maxSecond,
                              playbackState: playbackState,
                              playbackController: playbackController,
                            )
                          : null,
                      onHorizontalDragEnd: hasPlaybackMessages
                          ? (details) => _handleHorizontalGestureSeek(
                              details: details,
                              maxSecond: maxSecond,
                              playbackController: playbackController,
                            )
                          : null,
                      onLongPress: handlePreviewLongPress,
                      child: child,
                    );
                  }

                  final previewSurface = Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        previewSidePadding,
                        previewTopPadding,
                        previewSidePadding,
                        previewBottomPadding,
                      ),
                      child: _PlaybackPreviewCard(
                        sceneId: scene?.id,
                        boundaryKey: _previewBoundaryKey,
                        aspectRatio: selectedAspectRatio,
                        palette: palette,
                        showDeviceFrame: widget.initialShowDeviceFrame,
                        cleanPreview: widget.initialCleanPreview,
                        currentSecond: playbackState.currentSecond,
                        maxSecond: maxSecond,
                        messages: sortedMessages,
                        speakerNameById: speakerNameById,
                        characterAvatarPathById: characterAvatarPathById,
                        characterBubbleColorById: characterBubbleColorById,
                        resolveSpeakerName: _resolveSpeakerName,
                        showTypingIndicator: showsTypingIndicatorAtSecond,
                        maxPreviewHeight: previewMaxHeight,
                      ),
                    ),
                  );

                  final header = FocusPreviewHeader(
                    sceneTitle: scene?.title,
                    currentSecond: playbackState.currentSecond,
                    maxSecond: maxSecond,
                    statusName: playbackState.status.name,
                    onClose: () => Navigator.of(context).pop(),
                  );

                  final transportPanel = ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: isShortHeightLayout ? 120 : 220,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(isShortHeightLayout ? 10 : 12),
                        decoration: BoxDecoration(
                          color: const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FocusPreviewTransportControls(
                              isCompactLayout: isCompactLayout,
                              isUltraCompactLayout: isUltraCompactLayout,
                              hasPlaybackMessages: hasPlaybackMessages,
                              isPlaying: playbackState.isPlaying,
                              currentSecond: playbackState.currentSecond,
                              maxSecond: maxSecond,
                              sliderMax: sliderMax,
                              sliderValue: sliderValue,
                              previousCue: previousCue,
                              nextCue: nextCue,
                              onSliderChanged: maxSecond == 0
                                  ? null
                                  : (value) => playbackController.scrubTo(
                                      second: value.round(),
                                      maxSecond: maxSecond,
                                    ),
                              onPrevCue: previousCue == null
                                  ? null
                                  : () => playbackController.scrubTo(
                                      second: previousCue,
                                      maxSecond: maxSecond,
                                    ),
                              onSeekBackward: maxSecond == 0
                                  ? null
                                  : () => playbackController.seekBy(
                                      delta: -1,
                                      maxSecond: maxSecond,
                                    ),
                              onTogglePlayback: hasPlaybackMessages
                                  ? () => _togglePlayback(
                                      hasPlaybackMessages: hasPlaybackMessages,
                                      maxSecond: maxSecond,
                                      playbackState: playbackState,
                                      playbackController: playbackController,
                                    )
                                  : null,
                              onSeekForward: maxSecond == 0
                                  ? null
                                  : () => playbackController.seekBy(
                                      delta: 1,
                                      maxSecond: maxSecond,
                                    ),
                              onNextCue: nextCue == null
                                  ? null
                                  : () => playbackController.scrubTo(
                                      second: nextCue,
                                      maxSecond: maxSecond,
                                    ),
                              onRestart:
                                  hasPlaybackMessages ||
                                      playbackState.currentSecond > 0
                                  ? playbackController.restart
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isShortHeightLayout
                                  ? 'Tap play/pause • Swipe ±5s • Double-tap edges for cues • Long press to exit.'
                                  : 'Tap to play or pause. Swipe left/right for ±5s. Double-tap the left/right edge for previous/next cue. Press Esc on desktop or long press anywhere to exit.',
                              key: const Key('focusPreviewHintLabel'),
                              textAlign: TextAlign.center,
                              maxLines: isShortHeightLayout
                                  ? 2
                                  : isUltraCompactLayout
                                  ? 3
                                  : null,
                              overflow:
                                  isShortHeightLayout || isUltraCompactLayout
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.visible,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: wrapPreviewGestures(
                          previewSurface,
                          key: const Key('focusPreviewTapSurface'),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: header,
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: transportPanel,
                      ),
                    ],
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to open focus preview.\n$error',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, String> _buildSpeakerNameById(Project project) {
  final map = <String, String>{};
  for (final item in project.scenes) {
    for (final character in item.characters) {
      map[character.id] = character.displayName;
    }
  }
  return map;
}

String _resolveSpeakerName({
  required String characterId,
  required Map<String, String> speakerNameById,
}) {
  return speakerNameById[characterId] ?? 'Unknown';
}

double _aspectRatioValue(SceneAspectRatio aspectRatio) {
  return switch (aspectRatio) {
    SceneAspectRatio.portrait9x16 => 9 / 16,
    SceneAspectRatio.landscape16x9 => 16 / 9,
  };
}

String _formatTimecode(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = (safe ~/ 60).toString().padLeft(2, '0');
  final remainingSeconds = (safe % 60).toString().padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}

class FocusPreviewHeader extends StatelessWidget {
  const FocusPreviewHeader({
    required this.sceneTitle,
    required this.currentSecond,
    required this.maxSecond,
    required this.statusName,
    required this.onClose,
    super.key,
  });

  final String? sceneTitle;
  final int currentSecond;
  final int maxSecond;
  final String statusName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStackHeader =
            AppBreakpoints.isUltraCompactLayoutWidth(
              constraints.maxWidth,
              textScaleFactor: textScaleFactor,
            ) ||
            AppBreakpoints.shouldStackHeader(
              constraints.maxWidth,
              textScaleFactor: textScaleFactor,
            );

        if (shouldStackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filledTonal(
                key: const Key('focusPreviewCloseButton'),
                tooltip: 'Close Focus Preview',
                onPressed: onClose,
                icon: const Icon(Icons.close_fullscreen_rounded),
              ),
              const SizedBox(height: 8),
              _FocusPreviewStatusBanner(
                sceneTitle: sceneTitle,
                currentSecond: currentSecond,
                maxSecond: maxSecond,
                statusName: statusName,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton.filledTonal(
              key: const Key('focusPreviewCloseButton'),
              tooltip: 'Close Focus Preview',
              onPressed: onClose,
              icon: const Icon(Icons.close_fullscreen_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FocusPreviewStatusBanner(
                sceneTitle: sceneTitle,
                currentSecond: currentSecond,
                maxSecond: maxSecond,
                statusName: statusName,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FocusPreviewStatusBanner extends StatelessWidget {
  const _FocusPreviewStatusBanner({
    required this.sceneTitle,
    required this.currentSecond,
    required this.maxSecond,
    required this.statusName,
  });

  final String? sceneTitle;
  final int currentSecond;
  final int maxSecond;
  final String statusName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${sceneTitle ?? 'No scene'} • ${_formatTimecode(currentSecond)} / ${_formatTimecode(maxSecond)} • $statusName',
        key: const Key('focusPreviewStatusLabel'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class FocusPreviewTransportControls extends StatelessWidget {
  const FocusPreviewTransportControls({
    required this.isCompactLayout,
    required this.isUltraCompactLayout,
    required this.hasPlaybackMessages,
    required this.isPlaying,
    required this.currentSecond,
    required this.maxSecond,
    required this.sliderMax,
    required this.sliderValue,
    required this.previousCue,
    required this.nextCue,
    required this.onSliderChanged,
    required this.onPrevCue,
    required this.onSeekBackward,
    required this.onTogglePlayback,
    required this.onSeekForward,
    required this.onNextCue,
    required this.onRestart,
    super.key,
  });

  final bool isCompactLayout;
  final bool isUltraCompactLayout;
  final bool hasPlaybackMessages;
  final bool isPlaying;
  final int currentSecond;
  final int maxSecond;
  final double sliderMax;
  final double sliderValue;
  final int? previousCue;
  final int? nextCue;
  final ValueChanged<double>? onSliderChanged;
  final VoidCallback? onPrevCue;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onSeekForward;
  final VoidCallback? onNextCue;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final timelineLabelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: Colors.white70);

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
      ),
      child: Slider(
        key: const Key('focusPreviewProgressSlider'),
        value: sliderValue,
        max: sliderMax,
        onChanged: onSliderChanged,
      ),
    );

    final controls = [
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewPrevCueButton'),
        tooltip: previousCue == null ? 'No previous cue' : 'Previous cue',
        onPressed: onPrevCue,
        icon: const Icon(Icons.skip_previous_rounded),
        variant: _CompactTransportIconButtonVariant.tonal,
      ),
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewSeekBackwardButton'),
        tooltip: hasPlaybackMessages ? 'Back 1 second' : 'No playback messages',
        onPressed: onSeekBackward,
        icon: const Icon(Icons.replay_rounded),
        badgeText: '1',
        variant: _CompactTransportIconButtonVariant.tonal,
      ),
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewTogglePlaybackButton'),
        tooltip: isPlaying ? 'Pause playback' : 'Play playback',
        onPressed: onTogglePlayback,
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        ),
        variant: _CompactTransportIconButtonVariant.filled,
      ),
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewRestartButton'),
        tooltip: 'Restart playback',
        onPressed: onRestart,
        icon: const Icon(Icons.restart_alt_rounded),
      ),
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewSeekForwardButton'),
        tooltip: hasPlaybackMessages
            ? 'Forward 1 second'
            : 'No playback messages',
        onPressed: onSeekForward,
        icon: const Icon(Icons.forward_rounded),
        badgeText: '1',
        variant: _CompactTransportIconButtonVariant.tonal,
      ),
      _CompactTransportIconButton(
        buttonKey: const Key('focusPreviewNextCueButton'),
        tooltip: nextCue == null ? 'No next cue' : 'Next cue',
        onPressed: onNextCue,
        icon: const Icon(Icons.skip_next_rounded),
        variant: _CompactTransportIconButtonVariant.tonal,
      ),
    ];

    final compactControls = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: controls,
    );

    final standardControls = [
      Tooltip(
        message: previousCue == null ? 'No previous cue' : 'Previous cue',
        child: IconButton.filledTonal(
          key: const Key('focusPreviewPrevCueButton'),
          onPressed: onPrevCue,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
      ),
      Tooltip(
        message: hasPlaybackMessages ? 'Back 1 second' : 'No playback messages',
        child: IconButton.filledTonal(
          key: const Key('focusPreviewSeekBackwardButton'),
          onPressed: onSeekBackward,
          icon: const Icon(Icons.replay_rounded),
        ),
      ),
      FilledButton.icon(
        key: const Key('focusPreviewTogglePlaybackButton'),
        onPressed: onTogglePlayback,
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        ),
        label: Text(isPlaying ? 'Pause' : 'Play'),
      ),
      Tooltip(
        message: hasPlaybackMessages
            ? 'Forward 1 second'
            : 'No playback messages',
        child: IconButton.filledTonal(
          key: const Key('focusPreviewSeekForwardButton'),
          onPressed: onSeekForward,
          icon: const Icon(Icons.forward_rounded),
        ),
      ),
      Tooltip(
        message: nextCue == null ? 'No next cue' : 'Next cue',
        child: IconButton.filledTonal(
          key: const Key('focusPreviewNextCueButton'),
          onPressed: onNextCue,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ),
      OutlinedButton.icon(
        key: const Key('focusPreviewRestartButton'),
        onPressed: onRestart,
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Restart'),
      ),
    ];

    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStackTimeline =
            isUltraCompactLayout ||
            AppBreakpoints.shouldStackMetadata(
              constraints.maxWidth,
              textScaleFactor: textScaleFactor,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shouldStackTimeline) ...[
              slider,
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _formatTimecode(currentSecond),
                    key: const Key('focusPreviewCurrentTimeLabel'),
                    style: timelineLabelStyle,
                  ),
                  const Spacer(),
                  Text(
                    _formatTimecode(maxSecond),
                    key: const Key('focusPreviewMaxTimeLabel'),
                    style: timelineLabelStyle,
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Text(
                    _formatTimecode(currentSecond),
                    key: const Key('focusPreviewCurrentTimeLabel'),
                    style: timelineLabelStyle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: slider),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimecode(maxSecond),
                    key: const Key('focusPreviewMaxTimeLabel'),
                    style: timelineLabelStyle,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (isUltraCompactLayout)
              compactControls
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final control in standardControls)
                    if (isCompactLayout)
                      SizedBox(height: 40, child: control)
                    else
                      control,
                ],
              ),
          ],
        );
      },
    );
  }
}

class _PlaybackEmptyStateActions extends StatelessWidget {
  const _PlaybackEmptyStateActions({
    required this.scene,
    required this.isCompactLayout,
    required this.onOpenChatEditor,
    required this.onApplyTemplate,
  });

  final Scene? scene;
  final bool isCompactLayout;
  final VoidCallback onOpenChatEditor;
  final Future<void> Function(String templateId, String label)? onApplyTemplate;

  @override
  Widget build(BuildContext context) {
    final hasScene = scene != null;
    final buttons = <Widget>[
      FilledButton.icon(
        key: const Key('playbackEmptyStateOpenEditorButton'),
        onPressed: onOpenChatEditor,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Open Chat Editor'),
      ),
      OutlinedButton.icon(
        key: const Key('playbackEmptyStateBriefingTemplateButton'),
        onPressed: onApplyTemplate != null
            ? () => onApplyTemplate!('briefing', 'Briefing')
            : null,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Load Briefing Template'),
      ),
      OutlinedButton.icon(
        key: const Key('playbackEmptyStateGroupAlertTemplateButton'),
        onPressed: onApplyTemplate != null
            ? () => onApplyTemplate!('group_alert', 'Group Alert')
            : null,
        icon: const Icon(Icons.groups_rounded),
        label: const Text('Load Group Alert Template'),
      ),
    ];

    return Container(
      key: const Key('playbackEmptyStateHint'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasScene
                ? 'Add at least one timed message in Chat Editor to enable playback and export.'
                : 'Select a scene in Chat Editor before playback can start.',
          ),
          if (hasScene) ...[
            const SizedBox(height: 6),
            Text(
              'Need a fast starting point? Use the buttons below to load a starter template.',
              key: const Key('playbackEmptyStateTemplateHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          if (isCompactLayout)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < buttons.length; index += 1) ...[
                  buttons[index],
                  if (index != buttons.length - 1) const SizedBox(height: 8),
                ],
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: buttons,
            ),
        ],
      ),
    );
  }
}

class _PlaybackExportActions extends StatelessWidget {
  const _PlaybackExportActions({
    required this.isCompactLayout,
    required this.isUltraCompactLayout,
    required this.isDisabled,
    required this.onExportScreenshot,
    required this.onExportVideo,
  });

  final bool isCompactLayout;
  final bool isUltraCompactLayout;
  final bool isDisabled;
  final Future<void> Function() onExportScreenshot;
  final Future<void> Function() onExportVideo;

  @override
  Widget build(BuildContext context) {
    if (!isCompactLayout) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('exportScreenshotButton'),
            onPressed: isDisabled ? null : onExportScreenshot,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Export Screenshot'),
          ),
          OutlinedButton.icon(
            key: const Key('exportVideoButton'),
            onPressed: isDisabled ? null : onExportVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Export Video'),
          ),
        ],
      );
    }

    if (isUltraCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('exportScreenshotButton'),
            onPressed: isDisabled ? null : onExportScreenshot,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Screenshot'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('exportVideoButton'),
            onPressed: isDisabled ? null : onExportVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Video'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const Key('exportScreenshotButton'),
            onPressed: isDisabled ? null : onExportScreenshot,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Screenshot'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('exportVideoButton'),
            onPressed: isDisabled ? null : onExportVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Video'),
          ),
        ),
      ],
    );
  }
}

class _PlaybackTransportControls extends StatelessWidget {
  const _PlaybackTransportControls({
    required this.isCompactLayout,
    required this.isUltraCompactLayout,
    required this.isPlaying,
    required this.previousCue,
    required this.nextCue,
    required this.onPrevCue,
    required this.onNextCue,
    required this.onSeekBackward5,
    required this.onSeekBackward1,
    required this.onPlay,
    required this.onPause,
    required this.onRestart,
    required this.onSeekForward1,
    required this.onSeekForward5,
    required this.onJumpToEnd,
  });

  final bool isCompactLayout;
  final bool isUltraCompactLayout;
  final bool isPlaying;
  final int? previousCue;
  final int? nextCue;
  final VoidCallback? onPrevCue;
  final VoidCallback? onNextCue;
  final VoidCallback? onSeekBackward5;
  final VoidCallback? onSeekBackward1;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onRestart;
  final VoidCallback? onSeekForward1;
  final VoidCallback? onSeekForward5;
  final VoidCallback? onJumpToEnd;

  @override
  Widget build(BuildContext context) {
    if (!isCompactLayout) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('prevCueButton'),
            onPressed: onPrevCue,
            icon: const Icon(Icons.skip_previous_rounded),
            label: const Text('Prev Cue'),
          ),
          OutlinedButton.icon(
            key: const Key('nextCueButton'),
            onPressed: onNextCue,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Next Cue'),
          ),
          FilledButton.tonalIcon(
            key: const Key('seekBackward5Button'),
            onPressed: onSeekBackward5,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('-5s'),
          ),
          FilledButton.tonalIcon(
            key: const Key('seekBackward1Button'),
            onPressed: onSeekBackward1,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('-1s'),
          ),
          FilledButton.icon(
            key: const Key('playButton'),
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play'),
          ),
          OutlinedButton.icon(
            key: const Key('pauseButton'),
            onPressed: onPause,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
          OutlinedButton.icon(
            key: const Key('restartButton'),
            onPressed: onRestart,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restart'),
          ),
          FilledButton.tonalIcon(
            key: const Key('seekForward1Button'),
            onPressed: onSeekForward1,
            icon: const Icon(Icons.forward_rounded),
            label: const Text('+1s'),
          ),
          FilledButton.tonalIcon(
            key: const Key('seekForward5Button'),
            onPressed: onSeekForward5,
            icon: const Icon(Icons.forward_rounded),
            label: const Text('+5s'),
          ),
          OutlinedButton.icon(
            key: const Key('jumpToEndButton'),
            onPressed: onJumpToEnd,
            icon: const Icon(Icons.last_page_rounded),
            label: const Text('End'),
          ),
        ],
      );
    }

    if (isUltraCompactLayout) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _CompactTransportIconButton(
            buttonKey: const Key('prevCueButton'),
            tooltip: previousCue == null ? 'No previous cue' : 'Previous cue',
            onPressed: onPrevCue,
            icon: const Icon(Icons.skip_previous_rounded),
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('seekBackward5Button'),
            tooltip: 'Back 5 seconds',
            onPressed: onSeekBackward5,
            icon: const Icon(Icons.replay_rounded),
            badgeText: '5',
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('seekBackward1Button'),
            tooltip: 'Back 1 second',
            onPressed: onSeekBackward1,
            icon: const Icon(Icons.replay_rounded),
            badgeText: '1',
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: isPlaying
                ? const Key('pauseButton')
                : const Key('playButton'),
            tooltip: isPlaying ? 'Pause playback' : 'Play playback',
            onPressed: isPlaying ? onPause : onPlay,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            variant: _CompactTransportIconButtonVariant.filled,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('restartButton'),
            tooltip: 'Restart playback',
            onPressed: onRestart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('seekForward1Button'),
            tooltip: 'Forward 1 second',
            onPressed: onSeekForward1,
            icon: const Icon(Icons.forward_rounded),
            badgeText: '1',
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('seekForward5Button'),
            tooltip: 'Forward 5 seconds',
            onPressed: onSeekForward5,
            icon: const Icon(Icons.forward_rounded),
            badgeText: '5',
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('nextCueButton'),
            tooltip: nextCue == null ? 'No next cue' : 'Next cue',
            onPressed: onNextCue,
            icon: const Icon(Icons.skip_next_rounded),
            variant: _CompactTransportIconButtonVariant.tonal,
          ),
          _CompactTransportIconButton(
            buttonKey: const Key('jumpToEndButton'),
            tooltip: 'Jump to end',
            onPressed: onJumpToEnd,
            icon: const Icon(Icons.last_page_rounded),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('playButton'),
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pauseButton'),
                onPressed: onPause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('restartButton'),
                onPressed: onRestart,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('prevCueButton'),
              onPressed: onPrevCue,
              icon: const Icon(Icons.skip_previous_rounded),
              label: const Text('Prev Cue'),
            ),
            OutlinedButton.icon(
              key: const Key('nextCueButton'),
              onPressed: onNextCue,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Next Cue'),
            ),
            FilledButton.tonalIcon(
              key: const Key('seekBackward5Button'),
              onPressed: onSeekBackward5,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('-5s'),
            ),
            FilledButton.tonalIcon(
              key: const Key('seekBackward1Button'),
              onPressed: onSeekBackward1,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('-1s'),
            ),
            FilledButton.tonalIcon(
              key: const Key('seekForward1Button'),
              onPressed: onSeekForward1,
              icon: const Icon(Icons.forward_rounded),
              label: const Text('+1s'),
            ),
            FilledButton.tonalIcon(
              key: const Key('seekForward5Button'),
              onPressed: onSeekForward5,
              icon: const Icon(Icons.forward_rounded),
              label: const Text('+5s'),
            ),
            OutlinedButton.icon(
              key: const Key('jumpToEndButton'),
              onPressed: onJumpToEnd,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('End'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _CompactTransportIconButtonVariant { outlined, tonal, filled }

class _CompactTransportIconButton extends StatelessWidget {
  const _CompactTransportIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.badgeText,
    this.variant = _CompactTransportIconButtonVariant.outlined,
  });

  final Key buttonKey;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? badgeText;
  final _CompactTransportIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      _CompactTransportIconButtonVariant.outlined => IconButton.outlined(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
      ),
      _CompactTransportIconButtonVariant.tonal => IconButton.filledTonal(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
      ),
      _CompactTransportIconButtonVariant.filled => IconButton.filled(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
      ),
    };

    final decoratedButton = badgeText == null
        ? button
        : Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: button),
              Positioned(
                right: 2,
                bottom: 2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: Text(
                        badgeText!,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

    return SizedBox.square(dimension: 48, child: decoratedButton);
  }
}

class _TypingIndicatorItem extends StatelessWidget {
  const _TypingIndicatorItem({
    required this.speakerName,
    required this.characterAvatarPath,
    required this.characterBubbleColor,
    required this.palette,
    this.isActiveCue = false,
  });

  final String speakerName;
  final String? characterAvatarPath;
  final String characterBubbleColor;
  final ChatStylePalette palette;
  final bool isActiveCue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.typingColor,
        borderRadius: BorderRadius.circular(12),
        border: isActiveCue
            ? Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2)
            : null,
        boxShadow: isActiveCue
            ? const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          CharacterAvatar(
            displayName: speakerName,
            avatarPath: characterAvatarPath,
            bubbleColor: characterBubbleColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$speakerName is typing...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.message,
    required this.palette,
    required this.speakerName,
    required this.characterAvatarPath,
    required this.characterBubbleColor,
    required this.isVisibleAtCurrentTime,
    this.cleanPreview = false,
    this.isActiveCue = false,
  });

  final Message message;
  final ChatStylePalette palette;
  final String speakerName;
  final String? characterAvatarPath;
  final String characterBubbleColor;
  final bool isVisibleAtCurrentTime;
  final bool cleanPreview;
  final bool isActiveCue;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final directionLabel = message.isIncoming ? 'INCOMING' : 'OUTGOING';
    final statusLabel = message.status.name.toUpperCase();
    final statusIcon = switch (message.status) {
      MessageStatus.sent => Icons.check_rounded,
      MessageStatus.delivered => Icons.done_all_rounded,
      MessageStatus.seen => Icons.visibility_rounded,
    };

    final bubbleColor = resolveCharacterBubbleTint(
      rawColor: characterBubbleColor,
      baseColor: message.isIncoming
          ? palette.incomingBubbleColor
          : palette.outgoingBubbleColor,
    );

    return Opacity(
      opacity: isVisibleAtCurrentTime ? 1 : 0.45,
      child: Container(
        key: Key('playbackMessageBubble_${message.id}'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: isActiveCue
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                  width: 2,
                )
              : null,
          boxShadow: isActiveCue
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shouldStackMetadata = AppBreakpoints.shouldStackMetadata(
              constraints.maxWidth,
              textScaleFactor: textScaleFactor,
            );
            final messageContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CharacterAvatar(
                      displayName: speakerName,
                      avatarPath: characterAvatarPath,
                      bubbleColor: characterBubbleColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        speakerName,
                        style: TextStyle(color: palette.textColor),
                      ),
                    ),
                  ],
                ),
                if (!cleanPreview) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        backgroundColor: palette.chipColor,
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          statusIcon,
                          size: 14,
                          color: palette.textColor,
                        ),
                        label: Text(
                          statusLabel,
                          style: TextStyle(color: palette.textColor),
                        ),
                      ),
                      Chip(
                        backgroundColor: palette.chipColor,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          directionLabel,
                          style: TextStyle(color: palette.textColor),
                        ),
                      ),
                      if (message.showTypingBefore)
                        Chip(
                          backgroundColor: palette.chipColor,
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            'TYPING BEFORE',
                            style: TextStyle(color: palette.textColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ] else
                  const SizedBox(height: 6),
                Text(
                  message.text,
                  style: TextStyle(color: palette.textColor),
                ),
              ],
            );

            if (shouldStackMetadata) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    't=${message.timestampSeconds}s',
                    style: TextStyle(color: palette.textColor),
                  ),
                  const SizedBox(height: 8),
                  messageContent,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  't=${message.timestampSeconds}s',
                  style: TextStyle(color: palette.textColor),
                ),
                const SizedBox(width: 12),
                Expanded(child: messageContent),
              ],
            );
          },
        ),
      ),
    );
  }
}
