import 'dart:math' as math;

import 'package:flutter/material.dart';

class CenteredScrollableState extends StatelessWidget {
  const CenteredScrollableState({
    required this.child,
    this.maxWidth = 440,
    this.padding = const EdgeInsets.all(24),
    this.scrollViewKey,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Key? scrollViewKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final minHeight = math.max<double>(
          0,
          constraints.maxHeight - resolvedPadding.vertical,
        );

        return SingleChildScrollView(
          key: scrollViewKey,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
