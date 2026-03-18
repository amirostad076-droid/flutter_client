import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/route_state_providers.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/presentation/widgets/guild_sidebar.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/dm/presentation/widgets/dm_list.dart';
import 'package:fluxeron/features/guilds/presentation/widgets/guild_navbar.dart';
import 'package:fluxeron/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/features/settings/presentation/user_settings_modal.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_area.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Left sidebars width is computed from layout theme in _buildDesktopBody.

class AppLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({required this.navigationShell, super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  static const _youBranchIndex = 2;

  @override
  Widget build(BuildContext context) {
    ref.listen(activeGuildIdProvider, (previous, next) {
      if (next != null) {
        final guilds = ref.read(guildListViewModelProvider).guilds;
        final guild = guilds.where((g) => g.id == next).firstOrNull;
        unawaited(
          ref
              .read(channelListViewModelProvider.notifier)
              .loadChannels(next, serverName: guild?.name),
        );
        unawaited(
          ref.read(memberListViewModelProvider.notifier).loadMembers(next),
        );
      }
    });

    final isMobile = isMobileLayout(context);

    if (!isMobile) {
      return Scaffold(
        backgroundColor: context.colors.backgroundPrimary,
        body: _buildDesktopBody(),
      );
    }

    return _buildMobileBody();
  }

  Widget _buildDesktopBody() {
    final location = GoRouterState.of(context).matchedLocation;
    final isDm = location.startsWith('/channels/@me');

    final layout = context.layout;
    final leftSidebarsWidth = layout.guildListWidth + layout.sidebarWidth;

    return Row(
      children: [
        SizedBox(
          width: leftSidebarsWidth,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const GuildNavbar(),
                    Expanded(
                      child: isDm ? const DMList() : const GuildSidebar(),
                    ),
                  ],
                ),
              ),
              UserArea(onSettingsTap: () => UserSettingsModal.show(context)),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: context.colors.backgroundModifierAccent,
        ),
        Expanded(child: widget.navigationShell),
      ],
    );
  }

  Widget _buildMobileBody() {
    final location = GoRouterState.of(context).matchedLocation;
    final showSidebar = _isRootRoute(location);
    final isChatRoute = _isChatRoute(location);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Column(
        children: [
          Expanded(
            child: showSidebar
                ? _buildMobileSidebar(location)
                : widget.navigationShell,
          ),
          if (!isChatRoute) _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(String location) {
    final isDm = location.startsWith('/channels/@me');
    return ColoredBox(
      color: context.colors.channelSidebarBackground,
      child: SafeArea(
        child: Row(
          children: [
            const GuildNavbar(),
            Expanded(child: isDm ? const DMList() : const GuildSidebar()),
          ],
        ),
      ),
    );
  }

  bool _isRootRoute(String location) {
    if (location == '/channels/@me') {
      return true;
    }
    if (location == '/channels/@favorites') {
      return true;
    }
    // /channels/:guildId exactly (no sub-path)
    final guildRoot = RegExp(r'^/channels/[^@/][^/]*$');
    if (guildRoot.hasMatch(location)) {
      return true;
    }
    return false;
  }

  bool _isChatRoute(String location) {
    if (location.startsWith('/channels/@me/') && location != '/channels/@me') {
      return true;
    }
    if (location.startsWith('/channels/@favorites/') &&
        location != '/channels/@favorites') {
      return true;
    }
    final guildChat = RegExp('^/channels/[^@/][^/]*/[^/]+');
    if (guildChat.hasMatch(location)) {
      return true;
    }
    return false;
  }

  Widget _buildProfileTabIcon({
    required UserSettingsViewState user,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == _youBranchIndex;
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

  Widget _buildBottomNav(BuildContext context) {
    final user = ref.watch(userSettingsViewModelProvider);
    final currentIndex = widget.navigationShell.currentIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: context.colors.borderColor),
        Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            ),
            selectedItemColor: context.colors.textChat,
            unselectedItemColor: context.colors.textPrimaryMuted,
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
