import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:production_chat_prop/core/theme/chat_style_palette.dart';
import 'package:production_chat_prop/features/chat_editor/presentation/controllers/scene_controller.dart';
import 'package:production_chat_prop/features/playback/data/services/screenshot_export_service.dart';
import 'package:production_chat_prop/features/playback/data/services/video_export_fallback_service.dart';
import 'package:production_chat_prop/features/playback/presentation/controllers/playback_controller.dart';
import 'package:production_chat_prop/features/projects/domain/message.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';
import 'package:production_chat_prop/features/projects/presentation/controllers/projects_controller.dart';

class PlaybackScreen extends ConsumerWidget {
  const PlaybackScreen({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        actions: [
          IconButton(
            tooltip: 'Back to Projects',
            onPressed: () => context.goNamed('projects'),
            icon: const Icon(Icons.list_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: snapshotState.when(
          data: (snapshot) {
            if (snapshot == null) {
              return const _ProjectNotFoundState();
            }

            return _PlaybackTimeline(
              snapshot: snapshot,
              onSceneSelected: (sceneId) {
                ref
                        .read(sceneSelectionProvider(activeProjectId).notifier)
                        .selectedSceneId =
                    sceneId;
                ref
                    .read(playbackControllerProvider(activeProjectId).notifier)
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
    );
  }
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
  final ScreenshotExportService _screenshotExportService =
      ScreenshotExportService();
  final VideoExportFallbackService _videoExportFallbackService =
      VideoExportFallbackService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPlaybackWithScene(
        previousSceneId: null,
        currentSceneId: widget.snapshot.scene?.id,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _PlaybackTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlaybackWithScene(
      previousSceneId: oldWidget.snapshot.scene?.id,
      currentSceneId: widget.snapshot.scene?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.snapshot.project;
    final scene = widget.snapshot.scene;
    final sortedMessages = scene == null ? <Message>[] : [...scene.messages]
      ..sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));
    final palette = resolveChatStylePalette(scene?.styleId ?? 'studio_default');
    final speakerNameById = _buildSpeakerNameById(project);
    final maxSecond = sortedMessages.isEmpty
        ? 0
        : sortedMessages.last.timestampSeconds;

    final playbackState = ref.watch(playbackControllerProvider(project.id));
    final playbackController = ref.read(
      playbackControllerProvider(project.id).notifier,
    );
    final exportReadiness = sortedMessages.isEmpty
        ? 'No messages in scene'
        : _isExporting
        ? 'Export in progress'
        : 'Ready';
    final visibleMessagesCount = sortedMessages
        .where(
          (message) => message.timestampSeconds <= playbackState.currentSecond,
        )
        .length;
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

    return ListView(
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
                  DropdownButtonFormField<String>(
                    initialValue: scene?.id,
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        key: const Key('aspectRatioPortraitChip'),
                        label: const Text('9:16'),
                        selected:
                            scene.aspectRatio == SceneAspectRatio.portrait9x16,
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
                            scene.aspectRatio == SceneAspectRatio.landscape16x9,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('exportScreenshotButton'),
                      onPressed: sortedMessages.isEmpty || _isExporting
                          ? null
                          : () async => _exportScreenshot(
                              project: project,
                              scene: scene,
                            ),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Export Screenshot'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('exportVideoButton'),
                      onPressed: sortedMessages.isEmpty || _isExporting
                          ? null
                          : () async => _exportVideoFallback(
                              project: project,
                              scene: scene,
                            ),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Export Video'),
                    ),
                  ],
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
                const SizedBox(height: 12),
                Slider(
                  value: sliderValue,
                  max: sliderMax,
                  onChanged: (value) {
                    playbackController.scrubTo(
                      second: value.round(),
                      maxSecond: maxSecond,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('prevCueButton'),
                      onPressed: previousCue == null
                          ? null
                          : () => playbackController.scrubTo(
                              second: previousCue,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.skip_previous_rounded),
                      label: const Text('Prev Cue'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('nextCueButton'),
                      onPressed: nextCue == null
                          ? null
                          : () => playbackController.scrubTo(
                              second: nextCue,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Next Cue'),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('seekBackward5Button'),
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.seekBy(
                              delta: -5,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.replay_30_rounded),
                      label: const Text('-5s'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.seekBy(
                              delta: -1,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.replay_10_rounded),
                      label: const Text('-1s'),
                    ),
                    FilledButton.icon(
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.play(maxSecond: maxSecond),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                    ),
                    OutlinedButton.icon(
                      onPressed: playbackState.isPlaying
                          ? playbackController.pause
                          : null,
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('Pause'),
                    ),
                    OutlinedButton.icon(
                      onPressed: playbackController.restart,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Restart'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.seekBy(
                              delta: 1,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.forward_10_rounded),
                      label: const Text('+1s'),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('seekForward5Button'),
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.seekBy(
                              delta: 5,
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.forward_30_rounded),
                      label: const Text('+5s'),
                    ),
                    OutlinedButton.icon(
                      onPressed: maxSecond == 0
                          ? null
                          : () => playbackController.jumpToEnd(
                              maxSecond: maxSecond,
                            ),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('End'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          key: _previewBoundaryKey,
          child: Card(
            color: palette.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Playback Timeline (read-only)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Timeline preview follows timecode: queued messages stay dim until their cue time.',
                  ),
                  const SizedBox(height: 12),
                  if (sortedMessages.isEmpty)
                    const Text('No messages available for playback.')
                  else
                    for (final message in sortedMessages) ...[
                      if (_showTypingIndicator(
                        message: message,
                        currentSecond: playbackState.currentSecond,
                      )) ...[
                        _TypingIndicatorItem(
                          speakerName: _resolveSpeakerName(
                            characterId: message.characterId,
                            speakerNameById: speakerNameById,
                          ),
                          palette: palette,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _TimelineItem(
                        message: message,
                        palette: palette,
                        speakerName: _resolveSpeakerName(
                          characterId: message.characterId,
                          speakerNameById: speakerNameById,
                        ),
                        isVisibleAtCurrentTime:
                            message.timestampSeconds <=
                            playbackState.currentSecond,
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => context.goNamed(
                'editorProject',
                pathParameters: {'projectId': project.id},
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Open Chat Editor'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.goNamed('projects'),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Back to Projects'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportScreenshot({
    required Project project,
    required Scene? scene,
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
    final result = await _screenshotExportService.exportBoundaryAsPng(
      boundaryKey: _previewBoundaryKey,
      projectName: project.name,
      sceneTitle: scene.title,
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
    final result = await _videoExportFallbackService.exportFallbackPackage(
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

    final failureLabel = switch (result.failure) {
      VideoFallbackExportFailure.downloadUnavailable =>
        'download is not available on this platform',
      null => 'unknown error',
    };
    setState(() {
      _lastExportState = _ExportState.videoError;
      _isExporting = false;
    });
    _showSnackBar('Video export failed: $failureLabel.');
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

  String _formatTimecode(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  int _maxSecondForScene(Scene? scene) {
    if (scene == null || scene.messages.isEmpty) {
      return 0;
    }
    final sortedMessages = [...scene.messages]
      ..sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));
    return sortedMessages.last.timestampSeconds;
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

class _TypingIndicatorItem extends StatelessWidget {
  const _TypingIndicatorItem({
    required this.speakerName,
    required this.palette,
  });

  final String speakerName;
  final ChatStylePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.typingColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.more_horiz_rounded, size: 18, color: palette.textColor),
          const SizedBox(width: 8),
          Text(
            '$speakerName is typing...',
            style: TextStyle(color: palette.textColor),
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
    required this.isVisibleAtCurrentTime,
  });

  final Message message;
  final ChatStylePalette palette;
  final String speakerName;
  final bool isVisibleAtCurrentTime;

  @override
  Widget build(BuildContext context) {
    final directionLabel = message.isIncoming ? 'INCOMING' : 'OUTGOING';
    final statusLabel = message.status.name.toUpperCase();
    final statusIcon = switch (message.status) {
      MessageStatus.sent => Icons.check_rounded,
      MessageStatus.delivered => Icons.done_all_rounded,
      MessageStatus.seen => Icons.visibility_rounded,
    };

    return Opacity(
      opacity: isVisibleAtCurrentTime ? 1 : 0.45,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: message.isIncoming
              ? palette.incomingBubbleColor
              : palette.outgoingBubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              't=${message.timestampSeconds}s',
              style: TextStyle(color: palette.textColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speakerName,
                    style: TextStyle(color: palette.textColor),
                  ),
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
                  Text(
                    message.text,
                    style: TextStyle(color: palette.textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectNotFoundState extends StatelessWidget {
  const _ProjectNotFoundState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined),
            const SizedBox(height: 12),
            const Text('Project not found.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.goNamed('projects'),
              child: const Text('Back to Projects'),
            ),
          ],
        ),
      ),
    );
  }
}
