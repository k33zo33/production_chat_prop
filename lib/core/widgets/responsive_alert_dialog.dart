import 'package:flutter/material.dart';

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
    final mediaSize = MediaQuery.sizeOf(context);
    final isCompactWidth = mediaSize.width < 600;
    final horizontalInset = isCompactWidth ? 16.0 : 40.0;
    final availableWidth = (mediaSize.width - (horizontalInset * 2)).clamp(
      0.0,
      double.infinity,
    );
    final maxContentWidth = isCompactWidth
        ? availableWidth
        : availableWidth.clamp(0.0, 640.0);
    final maxContentHeight = mediaSize.height * (isCompactWidth ? 0.72 : 0.8);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: mediaSize.height < 720 ? 16 : 24,
      ),
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth,
          maxHeight: maxContentHeight,
        ),
        child: SingleChildScrollView(child: content),
      ),
      actions: actions,
    );
  }
}
