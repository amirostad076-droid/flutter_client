import 'package:flutter/material.dart';
import 'package:fluxer_app/core/router/shell_popup_overlay_sync.dart';

typedef ShellPopupOverlayChanged = void Function({required bool hasOverlay});

/// Tracks [PopupRoute]s (bottom sheets, dialogs) across shell navigators
class ShellPopupRouteObserver extends NavigatorObserver {
  ShellPopupRouteObserver(this._onOverlayChanged);

  final ShellPopupOverlayChanged _onOverlayChanged;

  void reconcile() {
    _onOverlayChanged(hasOverlay: shellNavigatorsHavePopupOverlay());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reconcile();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reconcile();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reconcile();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    reconcile();
  }
}
