import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigates to [path] using go() so the responsive shell can
/// react to the route change (showing/hiding sidebar vs content).
void navigateToContent(BuildContext context, String path) {
  context.go(path);
}
