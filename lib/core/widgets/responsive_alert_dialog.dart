import 'package:flutter/material.dart';
import 'package:production_chat_prop/core/utils/app_breakpoints.dart';

class ResponsiveAlertDialog extends StatelessWidget {
  const ResponsiveAlertDialog({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final mediaSize = mediaQuery.size;
    final textScaleFactor = mediaQuery.textScaler.scale(1);
    final safePadding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;
    final isCompactWidth = AppBreakpoints.isCompactDialogWidth(
      mediaSize.width,
      textScaleFactor: textScaleFactor,
    );
    final isShortHeight = AppBreakpoints.isShortViewportHeight(
      mediaSize.height,
    );
    final horizontalInset = isCompactWidth ? 16.0 : 40.0;
    final verticalInset = isShortHeight ? 16.0 : 24.0;
    final availableWidth =
        (mediaSize.width -
                safePadding.left -
                safePadding.right -
                (horizontalInset * 2))
            .clamp(0.0, double.infinity);
    final availableHeight =
        (mediaSize.height -
                safePadding.top -
                safePadding.bottom -
                viewInsets.bottom -
                (verticalInset * 2))
            .clamp(0.0, double.infinity);
    final maxContentWidth = isCompactWidth
        ? availableWidth
        : availableWidth.clamp(0.0, 640.0);
    final maxContentHeight = availableHeight * (isCompactWidth ? 0.72 : 0.8);

    return AnimatedPadding(
      key: const Key('responsiveAlertDialogAnimatedPadding'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: viewInsets,
      child: MediaQuery.removeViewInsets(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: AlertDialog(
          insetPadding: EdgeInsets.fromLTRB(
            horizontalInset + safePadding.left,
            verticalInset + safePadding.top,
            horizontalInset + safePadding.right,
            verticalInset + safePadding.bottom,
          ),
          title: title,
          content: ConstrainedBox(
            key: const Key('responsiveAlertDialogContentConstraints'),
            constraints: BoxConstraints(
              maxWidth: maxContentWidth,
              maxHeight: maxContentHeight,
            ),
            child: SingleChildScrollView(child: content),
          ),
          actions: actions,
        ),
      ),
    );
  }
}
