import 'package:flutter/material.dart';
import 'package:fluxeron/core/router/shell_route_paths.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shell for mobile: bottom nav (Home, Notifications, Profile) and optional
/// top bar with back when on a non-tab route (e.g. /dms/123).
class MobileShell extends StatelessWidget {
  const MobileShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: Column(
        children: [
          Expanded(child: child),
          const Divider(height: 1, color: FluxerColors.separator),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _indexForPath(location),
          onTap: (index) => _onTabTap(context, index),
          selectedItemColor: FluxerColors.textNormal,
          unselectedItemColor: FluxerColors.textMuted,
          items: const [
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIconsFill.house),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIconsFill.bell),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIconsFill.user),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }

  int _indexForPath(String location) {
    final index = ShellRoutePaths.mobileTabPaths.indexOf(location);
    return index >= 0 ? index : 0;
  }

  void _onTabTap(BuildContext context, int index) {
    context.go(ShellRoutePaths.mobileTabPaths[index]);
  }
}
