import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

enum LayoutMode { mobile, tablet, desktop }

/// Classifies layout from a reference extent, typically the viewport’s shortest
/// side so orientation does not flip phone vs tablet on rotation.
LayoutMode layoutModeOf(double referenceExtent) {
  if (referenceExtent < Breakpoints.mobile) {
    return LayoutMode.mobile;
  }
  if (referenceExtent < Breakpoints.tablet) {
    return LayoutMode.tablet;
  }
  return LayoutMode.desktop;
}

double layoutReferenceExtentOf(Size size) => math.min(size.width, size.height);

/// Whether the current layout is mobile ([layoutReferenceExtentOf] <
/// [Breakpoints.mobile]).
bool isMobileLayout(BuildContext context) =>
    layoutModeOf(layoutReferenceExtentOf(MediaQuery.sizeOf(context))) ==
    LayoutMode.mobile;

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, LayoutMode mode) builder;

  const ResponsiveLayout({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final LayoutMode mode = layoutModeOf(
      layoutReferenceExtentOf(MediaQuery.sizeOf(context)),
    );
    return builder(context, mode);
  }
}
