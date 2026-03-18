import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigates to [path] using go() which declaratively updates the route stack.
///
/// Using go() ensures the [StatefulShellRoute] builder receives the updated
/// location. Child routes maintain the parent in the stack, so pop() and
/// system back gestures still work on mobile.
void navigateToContent(BuildContext context, String path) {
  context.go(path);
}
