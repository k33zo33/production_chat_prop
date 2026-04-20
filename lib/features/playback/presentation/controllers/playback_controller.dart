import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlaybackStatus { idle, playing, paused, finished }

class PlaybackState {
  const PlaybackState({
    required this.status,
    required this.currentSecond,
  });

  final PlaybackStatus status;
  final int currentSecond;

  bool get isPlaying => status == PlaybackStatus.playing;

  PlaybackState copyWith({
    PlaybackStatus? status,
    int? currentSecond,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentSecond: currentSecond ?? this.currentSecond,
    );
  }
}

class PlaybackController extends Notifier<PlaybackState> {
  PlaybackController(this.projectId);

  final String projectId;
  Timer? _timer;

  @override
  PlaybackState build() {
    ref.onDispose(_disposeTimer);
    return const PlaybackState(
      status: PlaybackStatus.idle,
      currentSecond: 0,
    );
  }

  void play({required int maxSecond}) {
    if (maxSecond <= 0) {
      return;
    }

    if (state.status == PlaybackStatus.finished &&
        state.currentSecond >= maxSecond) {
      state = state.copyWith(currentSecond: 0);
    }

    _timer?.cancel();
    state = state.copyWith(status: PlaybackStatus.playing);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nextSecond = state.currentSecond + 1;
      if (nextSecond >= maxSecond) {
        state = state.copyWith(
          status: PlaybackStatus.finished,
          currentSecond: maxSecond,
        );
        _disposeTimer();
        return;
      }

      state = state.copyWith(currentSecond: nextSecond);
    });
  }

  void pause() {
    if (state.status != PlaybackStatus.playing) {
      return;
    }

    _disposeTimer();
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  void restart() {
    _disposeTimer();
    state = const PlaybackState(
      status: PlaybackStatus.idle,
      currentSecond: 0,
    );
  }

  void scrubTo({required int second, required int maxSecond}) {
    if (maxSecond <= 0) {
      _disposeTimer();
      state = const PlaybackState(
        status: PlaybackStatus.idle,
        currentSecond: 0,
      );
      return;
    }

    final clamped = second.clamp(0, maxSecond);
    _disposeTimer();
    state = state.copyWith(
      currentSecond: clamped,
      status: clamped == 0
          ? PlaybackStatus.idle
          : clamped >= maxSecond
          ? PlaybackStatus.finished
          : PlaybackStatus.paused,
    );
  }

  void seekBy({required int delta, required int maxSecond}) {
    final target = state.currentSecond + delta;
    scrubTo(second: target, maxSecond: maxSecond);
  }

  void jumpToStart() {
    _disposeTimer();
    state = const PlaybackState(
      status: PlaybackStatus.idle,
      currentSecond: 0,
    );
  }

  void jumpToEnd({required int maxSecond}) {
    if (maxSecond <= 0) {
      return;
    }
    _disposeTimer();
    state = state.copyWith(
      status: PlaybackStatus.finished,
      currentSecond: maxSecond,
    );
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

// ignore: specify_nonobvious_property_types, typed via NotifierProvider.family generic args.
final playbackControllerProvider =
    NotifierProvider.family<PlaybackController, PlaybackState, String>(
      PlaybackController.new,
    );
