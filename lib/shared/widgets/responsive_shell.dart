import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_sidebar.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/dm/presentation/widgets/dm_list.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/features/servers/presentation/widgets/server_sidebar.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/features/settings/presentation/user_settings_screen.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:fluxeron/shared/widgets/user_panel.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kLeftSidebarsWidth = 312.0;

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveShell({required this.child, super.key});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  @override
  Widget build(BuildContext context) {
    ref.listen(serverListViewModelProvider.select((s) => s.selectedServerId), (
      previous,
      next,
    ) {
      if (next != null) {
        final servers = ref.read(serverListViewModelProvider).servers;
        final server = servers.where((s) => s.id == next).firstOrNull;
        unawaited(
          ref
              .read(channelListViewModelProvider.notifier)
              .loadChannels(next, serverName: server?.name),
        );
        unawaited(
          ref.read(memberListViewModelProvider.notifier).loadMembers(next),
        );
      }
    });

    final isMobile = isMobileLayout(context);

    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: isMobile ? _buildMobileBody() : _buildDesktopBody(),
      bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildDesktopBody() {
    final isDm = ref.watch(
      serverListViewModelProvider.select((s) => s.isDmActive),
    );

    return Row(
      children: [
        SizedBox(
          width: _kLeftSidebarsWidth,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const ServerSidebar(),
                    Expanded(
                      child: isDm ? const DmList() : const ChannelSidebar(),
                    ),
                  ],
                ),
              ),
              UserPanel(onSettingsTap: () => UserSettingsScreen.show(context)),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildMobileBody() {
    final location = GoRouterState.of(context).matchedLocation;
    final isLeaf = _isMobileLeafRoute(location);

    if (isLeaf) {
      return widget.child;
    }

    final isDm = ref.watch(
      serverListViewModelProvider.select((s) => s.isDmActive),
    );

    return ColoredBox(
      color: FluxerColors.channelSidebarBackground,
      child: SafeArea(
        child: Row(
          children: [
            const ServerSidebar(),
            Expanded(child: isDm ? const DmList() : const ChannelSidebar()),
          ],
        ),
      ),
    );
  }

  bool _isMobileLeafRoute(String location) {
    if (location.startsWith('/servers/') && location.contains('/channels/')) {
      return true;
    }
    if (location.startsWith('/channels/@me/') && location != '/channels/@me') {
      return true;
    }
    if (location == '/notifications' || location == '/profile') {
      return true;
    }
    return false;
  }

  bool _shouldHideBottomNav(String location) {
    if (location.startsWith('/servers/') && location.contains('/channels/')) {
      return true;
    }
    if (location.startsWith('/dms/') && location != '/dms') {
      return true;
    }
    return false;
  }

  static const _tabPaths = ['/servers', '/notifications', '/profile'];

  int _tabIndexForPath(String location) {
    final index = _tabPaths.indexOf(location);
    if (index >= 0) {
      return index;
    }
    return 0;
  }

  static const _profileTabIndex = 2;

  Widget _buildProfileTabIcon({
    required UserSettingsViewState user,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == _profileTabIndex;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1 : 0.5,
      child: UserAvatar(
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        avatarColor: user.avatarColor,
        size: 24,
      ),
    );
  }

  Widget? _buildBottomNav(BuildContext context) {
    final user = ref.watch(userSettingsViewModelProvider);
    final location = GoRouterState.of(context).matchedLocation;
    if (_shouldHideBottomNav(location)) {
      return null;
    }

    final currentIndex = _tabIndexForPath(location);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: FluxerColors.separator),
        Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => context.go(_tabPaths[index]),
            selectedItemColor: FluxerColors.textNormal,
            unselectedItemColor: FluxerColors.textMuted,
            items: [
              const BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsFill.house),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsFill.bell),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: _buildProfileTabIcon(
                  user: user,
                  currentIndex: currentIndex,
                ),
                label: 'You',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
