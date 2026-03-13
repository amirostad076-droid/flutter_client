import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';

/// On mobile, pushes [path] so the user can swipe/tap back.
/// On desktop, uses go() since the sidebar stays visible.
void navigateToContent(BuildContext context, String path) {
  if (isMobileLayout(context)) {
    unawaited(context.push(path));
  } else {
    context.go(path);
  }
}
