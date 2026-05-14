import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/core/utils/character_bubble_colors.dart';
import 'package:production_chat_prop/core/utils/message_timeline_sort.dart';
import 'package:production_chat_prop/core/widgets/app_content_frame.dart';
import 'package:production_chat_prop/core/widgets/compact_scene_selector.dart';
import 'package:production_chat_prop/core/widgets/project_not_found_recovery_state.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/playback/data/services/video_export_fallback_service.dart';
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

class PlaybackScreen extends ConsumerWidget {
  const PlaybackScreen({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompactAppBar = MediaQuery.sizeOf(context).width < 720;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playback')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
        ),
      );
    }

    final activeProjectId = projectId!;
    final snapshotState = ref.watch(sceneSnapshotProvider(activeProjectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback'),
        actions: _buildAppBarActions(
          context,
          activeProjectId: activeProjectId,
          isCompactAppBar: isCompactAppBar,
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
    required bool isCompactAppBar,
  }) {
    if (!isCompactAppBar) {
      return [
        IconButton(
          key: const Key('playbackAppBarOpenEditorButton'),
          tooltip: 'Open Chat Editor',
          onPressed: () => context.goNamed(
            'editorProject',
            pathParameters: {'projectId': activeProjectId},
          ),
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
      PopupMenuButton<_PlaybackAppBarAction>(
        key: const Key('playbackOverflowMenuButton'),
        tooltip: 'Playback actions',
        onSelected: (action) {
          switch (action) {
            case _PlaybackAppBarAction.openChatEditor:
              context.goNamed(
                'editorProject',
                pathParameters: {'projectId': activeProjectId},
              );
              return;
            case _PlaybackAppBarAction.backToProjects:
              context.goNamed('projects');
              return;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _PlaybackAppBarAction.openChatEditor,
            child: Text('Open Chat Editor'),
          ),
          PopupMenuItem(
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
    final exportReadiness = hasPlaybackMessages
        ? _isExporting
              ? 'Export in progress'
              : 'Ready'
        : 'No messages in scene';
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isCompactLayout = viewportWidth < 720;
    final isUltraCompactLayout = viewportWidth < 360;
    final visibleMessagesCount = _countVisibleMessages(
      messages: sortedMessages,
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
    final previousCue = _findPreviousCue(
      messages: sortedMessages,
      currentSecond: playbackState.currentSecond,
    );
    final nextCue = _findNextCue(
      messages: sortedMessages,
      currentSecond: playbackState.currentSecond,
    );
    final openChatEditorButton = FilledButton.icon(
      key: const Key('playbackOpenEditorButton'),
      onPressed: () => context.goNamed(
        'editorProject',
        pathParameters: {'projectId': project.id},
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Scene: ${scene?.title ?? 'No scene'}'),
                  const SizedBox(height: 4),
                  Text('Messages: ${sortedMessages.length}'),
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
                      DropdownButtonFormField<String>(
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
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('exportReadinessLabel'),
                    'Export readiness: $exportReadiness',
                  ),
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
                  if (!hasPlaybackMessages) ...[
                    Container(
                      key: const Key('playbackEmptyStateHint'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Add at least one timed message in Chat Editor to enable playback and export.',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
            characterBubbleColorById: characterBubbleColorById,
            resolveSpeakerName: _resolveSpeakerName,
            showTypingIndicator: _showTypingIndicator,
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

  String _resolveSpeakerName({
    required String characterId,
    required Map<String, String> speakerNameById,
  }) {
    return speakerNameById[characterId] ?? 'Unknown';
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

  bool _showTypingIndicator({
    required Message message,
    required int currentSecond,
  }) {
    if (!message.showTypingBefore) {
      return false;
    }
    final typingSecond = message.timestampSeconds - 1;
    if (typingSecond < 0) {
      return false;
    }
    return currentSecond == typingSecond;
  }

  int _maxSecondForScene(Scene? scene) {
    if (scene == null || scene.messages.isEmpty) {
      return 0;
    }
    final sortedMessages = sortMessagesByTimeline(scene.messages);
    return sortedMessages.last.timestampSeconds;
  }

  int _countVisibleMessages({
    required List<Message> messages,
    required int currentSecond,
  }) {
    if (messages.isEmpty) {
      return 0;
    }

    var low = 0;
    var high = messages.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (messages[mid].timestampSeconds <= currentSecond) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  int? _findNextCue({
    required List<Message> messages,
    required int currentSecond,
  }) {
    for (final message in messages) {
      if (message.timestampSeconds > currentSecond) {
        return message.timestampSeconds;
      }
    }
    return null;
  }

  int? _findPreviousCue({
    required List<Message> messages,
    required int currentSecond,
  }) {
    int? candidate;
    for (final message in messages) {
      if (message.timestampSeconds < currentSecond) {
        candidate = message.timestampSeconds;
      } else {
        break;
      }
    }
    return candidate;
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
    final newMaxSecond = _maxSecondForScene(widget.snapshot.scene);

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
    required this.characterBubbleColorById,
    required this.resolveSpeakerName,
    required this.showTypingIndicator,
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
      _syncAutoFollow(previousCurrentSecond: null, sceneChanged: false);
    });
  }

  @override
  void didUpdateWidget(covariant _PlaybackPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAutoFollow(
        previousCurrentSecond: oldWidget.currentSecond,
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

    final movedForward = previousCurrentSecond == null
        ? widget.currentSecond > 0
        : widget.currentSecond > previousCurrentSecond;
    if (!movedForward) {
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
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ),
    );
  }

  String? _activeCueId() {
    for (final message in widget.messages) {
      if (widget.showTypingIndicator(
        message: message,
        currentSecond: widget.currentSecond,
      )) {
        return 'typing-${message.id}';
      }
    }

    for (var index = widget.messages.length - 1; index >= 0; index -= 1) {
      final message = widget.messages[index];
      if (message.timestampSeconds <= widget.currentSecond) {
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
          final previewWidth = math.min(targetPreviewWidth, availableWidth);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: previewWidth,
              child: AspectRatio(
                key: const Key('playbackPreviewAspectRatio'),
                aspectRatio: _aspectRatioValue(widget.aspectRatio),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.showDeviceFrame
                        ? Colors.black
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      widget.showDeviceFrame ? 28 : 0,
                    ),
                    border: widget.showDeviceFrame
                        ? Border.all(color: Colors.black87, width: 6)
                        : null,
                    boxShadow: widget.showDeviceFrame
                        ? const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  padding: EdgeInsets.all(widget.showDeviceFrame ? 12 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      widget.showDeviceFrame ? 20 : 0,
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: widget.palette.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.cleanPreview) ...[
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
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            if (widget.cleanPreview) const SizedBox(height: 12),
                            Expanded(
                              child: widget.messages.isEmpty
                                  ? const Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'No messages available for playback yet. Add messages in Chat Editor to build the preview.',
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
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('End'),
          ),
        ],
      );
    }

    if (isUltraCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPlaying)
            OutlinedButton.icon(
              key: const Key('pauseButton'),
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
              label: const Text('Pause'),
            )
          else
            FilledButton.icon(
              key: const Key('playButton'),
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Play'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('restartButton'),
            onPressed: onRestart,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restart'),
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
                label: const Text('Prev'),
              ),
              OutlinedButton.icon(
                key: const Key('nextCueButton'),
                onPressed: onNextCue,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Next'),
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

class _TypingIndicatorItem extends StatelessWidget {
  const _TypingIndicatorItem({
    required this.speakerName,
    required this.palette,
    this.isActiveCue = false,
  });

  final String speakerName;
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
          Icon(Icons.more_horiz_rounded, size: 18, color: palette.textColor),
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
    required this.characterBubbleColor,
    required this.isVisibleAtCurrentTime,
    this.cleanPreview = false,
    this.isActiveCue = false,
  });

  final Message message;
  final ChatStylePalette palette;
  final String speakerName;
  final String characterBubbleColor;
  final bool isVisibleAtCurrentTime;
  final bool cleanPreview;
  final bool isActiveCue;

  @override
  Widget build(BuildContext context) {
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
            final shouldStackMetadata = constraints.maxWidth < 220;
            final messageContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speakerName,
                  style: TextStyle(color: palette.textColor),
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
