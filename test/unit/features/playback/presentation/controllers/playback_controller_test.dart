import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/presentation/controllers/playback_controller.dart';

void main() {
  group('PlaybackController', () {
    test('starts idle at second 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = playbackControllerProvider('project-1');

      final state = container.read(provider);

      expect(state.status, PlaybackStatus.idle);
      expect(state.currentSecond, 0);
    });

    test('play advances time and reaches finished', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = playbackControllerProvider('project-1');

        container.read(provider.notifier).play(maxSecond: 3);
        expect(container.read(provider).status, PlaybackStatus.playing);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(provider).currentSecond, 1);

        async.elapse(const Duration(seconds: 2));
        final finishedState = container.read(provider);
        expect(finishedState.currentSecond, 3);
        expect(finishedState.status, PlaybackStatus.finished);
      });
    });

    test('pause stops advancing currentSecond', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = playbackControllerProvider('project-1');

        container.read(provider.notifier).play(maxSecond: 10);
        async.elapse(const Duration(seconds: 2));
        container.read(provider.notifier).pause();

        final pausedAt = container.read(provider).currentSecond;
        async.elapse(const Duration(seconds: 3));

        final stateAfterWait = container.read(provider);
        expect(stateAfterWait.status, PlaybackStatus.paused);
        expect(stateAfterWait.currentSecond, pausedAt);
      });
    });

    test('restart resets to idle and zero', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = playbackControllerProvider('project-1');

        container.read(provider.notifier).play(maxSecond: 10);
        async.elapse(const Duration(seconds: 4));

        container.read(provider.notifier).restart();

        final state = container.read(provider);
        expect(state.status, PlaybackStatus.idle);
        expect(state.currentSecond, 0);
      });
    });

    test('scrub clamps and marks finished at max second', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = playbackControllerProvider('project-1');

      container.read(provider.notifier).scrubTo(second: 12, maxSecond: 5);
      final state = container.read(provider);

      expect(state.currentSecond, 5);
      expect(state.status, PlaybackStatus.finished);
    });

    test('scrub to zero sets idle status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = playbackControllerProvider('project-1');

      container.read(provider.notifier).scrubTo(second: 0, maxSecond: 8);
      final state = container.read(provider);

      expect(state.currentSecond, 0);
      expect(state.status, PlaybackStatus.idle);
    });

    test('seekBy moves current second and clamps by max', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = playbackControllerProvider('project-1');

      container.read(provider.notifier).seekBy(delta: 3, maxSecond: 5);
      expect(container.read(provider).currentSecond, 3);
      expect(container.read(provider).status, PlaybackStatus.paused);

      container.read(provider.notifier).seekBy(delta: 10, maxSecond: 5);
      expect(container.read(provider).currentSecond, 5);
      expect(container.read(provider).status, PlaybackStatus.finished);
    });

    test('jumpToEnd and jumpToStart set terminal and reset states', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = playbackControllerProvider('project-1');

      container.read(provider.notifier).jumpToEnd(maxSecond: 6);
      expect(container.read(provider).currentSecond, 6);
      expect(container.read(provider).status, PlaybackStatus.finished);

      container.read(provider.notifier).jumpToStart();
      expect(container.read(provider).currentSecond, 0);
      expect(container.read(provider).status, PlaybackStatus.idle);
    });

    test('playback remains stable across long max timeline', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = playbackControllerProvider('project-large');

        container.read(provider.notifier).play(maxSecond: 520);
        async.elapse(const Duration(seconds: 520));

        final state = container.read(provider);
        expect(state.currentSecond, 520);
        expect(state.status, PlaybackStatus.finished);
      });
    });
  });
}
