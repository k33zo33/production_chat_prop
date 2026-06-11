import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/widgets/compact_scene_selector.dart';
import 'package:production_chat_prop/core/widgets/responsive_alert_dialog.dart';

void main() {
  Widget buildHarness({
    required Widget child,
    Size size = const Size(390, 844),
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          viewInsets: viewInsets,
        ),
        child: Material(child: Center(child: child)),
      ),
    );
  }

  group('ResponsiveAlertDialog', () {
    testWidgets('adds safe-area padding to compact dialog insets', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          padding: const EdgeInsets.only(top: 24, bottom: 34),
          child: const ResponsiveAlertDialog(
            title: Text('Dialog title'),
            content: Text('Dialog body'),
            actions: [TextButton(onPressed: null, child: Text('Close'))],
          ),
        ),
      );

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));

      expect(dialog.insetPadding, const EdgeInsets.fromLTRB(16, 48, 16, 58));
    });

    testWidgets('moves above the keyboard and shrinks content height', (
      tester,
    ) async {
      const dialog = ResponsiveAlertDialog(
        title: Text('Dialog title'),
        content: SizedBox(height: 600, child: Text('Dialog body')),
        actions: [TextButton(onPressed: null, child: Text('Close'))],
      );

      await tester.pumpWidget(buildHarness(child: dialog));

      final initialPadding = tester.widget<AnimatedPadding>(
        find.byKey(const Key('responsiveAlertDialogAnimatedPadding')),
      );
      final initialConstraints = tester
          .widget<ConstrainedBox>(
            find.byKey(const Key('responsiveAlertDialogContentConstraints')),
          )
          .constraints;

      await tester.pumpWidget(
        buildHarness(
          child: dialog,
          viewInsets: const EdgeInsets.only(bottom: 280),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final keyboardPadding = tester.widget<AnimatedPadding>(
        find.byKey(const Key('responsiveAlertDialogAnimatedPadding')),
      );
      final keyboardConstraints = tester
          .widget<ConstrainedBox>(
            find.byKey(const Key('responsiveAlertDialogContentConstraints')),
          )
          .constraints;

      expect(initialPadding.padding, EdgeInsets.zero);
      expect(keyboardPadding.padding, const EdgeInsets.only(bottom: 280));
      expect(
        keyboardConstraints.maxHeight,
        lessThan(initialConstraints.maxHeight),
      );
    });
  });

  testWidgets('CompactSceneSelector keeps a 48dp touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        size: const Size(320, 640),
        child: SizedBox(
          width: 280,
          child: CompactSceneSelector(
            value: 'scene-1',
            summary: 'Scene 1 of 2 • 3 messages • 24s max',
            onChanged: (_) {},
            items: const [
              DropdownMenuItem(value: 'scene-1', child: Text('Scene 1')),
              DropdownMenuItem(value: 'scene-2', child: Text('Scene 2')),
            ],
          ),
        ),
      ),
    );

    final selectorSize = tester.getSize(
      find.byKey(const Key('compactSceneSelectorTouchTarget')),
    );

    expect(selectorSize.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });
}
