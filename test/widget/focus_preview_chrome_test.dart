import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/features/playback/presentation/pages/playback_screen.dart';

void main() {
  testWidgets('focus preview header stacks on ultra-compact larger text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildChromeHarness(
        size: const Size(320, 700),
        textScaler: const TextScaler.linear(1.25),
        child: FocusPreviewHeader(
          sceneTitle: 'Scene 01',
          currentSecond: 3,
          maxSecond: 19,
          statusName: 'paused',
          onClose: () {},
        ),
      ),
    );

    final closeRect = tester.getRect(
      find.byKey(const Key('focusPreviewCloseButton')),
    );
    final statusRect = tester.getRect(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );

    expect(statusRect.top, greaterThan(closeRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus preview header stays inline on roomy widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildChromeHarness(
        size: const Size(480, 700),
        child: FocusPreviewHeader(
          sceneTitle: 'Scene 01',
          currentSecond: 3,
          maxSecond: 19,
          statusName: 'paused',
          onClose: () {},
        ),
      ),
    );

    final closeRect = tester.getRect(
      find.byKey(const Key('focusPreviewCloseButton')),
    );
    final statusRect = tester.getRect(
      find.byKey(const Key('focusPreviewStatusLabel')),
    );

    expect(statusRect.left, greaterThan(closeRect.right));
    expect((statusRect.top - closeRect.top).abs(), lessThan(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'focus preview transport stacks timeline on ultra-compact larger text',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildChromeHarness(
          size: const Size(320, 700),
          textScaler: const TextScaler.linear(1.25),
          child: FocusPreviewTransportControls(
            isCompactLayout: true,
            isUltraCompactLayout: true,
            hasPlaybackMessages: true,
            isPlaying: false,
            currentSecond: 3,
            maxSecond: 19,
            sliderMax: 19,
            sliderValue: 3,
            previousCue: 1,
            nextCue: 8,
            onSliderChanged: (_) {},
            onPrevCue: () {},
            onSeekBackward: () {},
            onTogglePlayback: () {},
            onSeekForward: () {},
            onNextCue: () {},
            onRestart: () {},
          ),
        ),
      );

      final sliderRect = tester.getRect(
        find.byKey(const Key('focusPreviewProgressSlider')),
      );
      final currentTimeRect = tester.getRect(
        find.byKey(const Key('focusPreviewCurrentTimeLabel')),
      );
      final maxTimeRect = tester.getRect(
        find.byKey(const Key('focusPreviewMaxTimeLabel')),
      );

      expect(currentTimeRect.top, greaterThan(sliderRect.bottom));
      expect(maxTimeRect.top, greaterThan(sliderRect.bottom));
      expect(
        find.byKey(const Key('focusPreviewTogglePlaybackButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('focus preview transport keeps timeline inline on wider widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildChromeHarness(
        size: const Size(480, 700),
        child: FocusPreviewTransportControls(
          isCompactLayout: false,
          isUltraCompactLayout: false,
          hasPlaybackMessages: true,
          isPlaying: true,
          currentSecond: 3,
          maxSecond: 19,
          sliderMax: 19,
          sliderValue: 3,
          previousCue: 1,
          nextCue: 8,
          onSliderChanged: (_) {},
          onPrevCue: () {},
          onSeekBackward: () {},
          onTogglePlayback: () {},
          onSeekForward: () {},
          onNextCue: () {},
          onRestart: () {},
        ),
      ),
    );

    final sliderRect = tester.getRect(
      find.byKey(const Key('focusPreviewProgressSlider')),
    );
    final currentTimeRect = tester.getRect(
      find.byKey(const Key('focusPreviewCurrentTimeLabel')),
    );
    final maxTimeRect = tester.getRect(
      find.byKey(const Key('focusPreviewMaxTimeLabel')),
    );

    expect(currentTimeRect.right, lessThan(sliderRect.left));
    expect(maxTimeRect.left, greaterThan(sliderRect.right));
    expect(
      (currentTimeRect.center.dy - sliderRect.center.dy).abs(),
      lessThan(16),
    );
    expect((maxTimeRect.center.dy - sliderRect.center.dy).abs(), lessThan(16));
    expect(tester.takeException(), isNull);
  });
}

Widget _buildChromeHarness({
  required Size size,
  Widget? child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width - 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
}
