import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

/// Navigates to [path] using push() on mobile (enables swipe-back gesture)
/// and go() on desktop (replaces content in-place, sidebar persists).
void navigateToContent(BuildContext context, String path) {
  if (isMobileLayout(context)) {
    unawaited(context.push(path));
  } else {
    context.go(path);
  }
}
