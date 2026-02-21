import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

enum LayoutMode { mobile, tablet, desktop }

LayoutMode layoutModeOf(double width) {
  if (width < Breakpoints.mobile) {
    return LayoutMode.mobile;
  }
  if (width < Breakpoints.tablet) {
    return LayoutMode.tablet;
  }
  return LayoutMode.desktop;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, LayoutMode mode) builder;

  const ResponsiveLayout({required this.builder, super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mode = layoutModeOf(constraints.maxWidth);
      return builder(context, mode);
    },
  );
}
