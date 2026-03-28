import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/guild_sidebar.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/dm/presentation/widgets/dm_list.dart';
import 'package:fluxer_app/features/guilds/presentation/widgets/guild_navbar.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/members/providers/member_list_view_model.dart';
import 'package:fluxer_app/features/settings/presentation/user_settings_modal.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/shell/presentation/user_area.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Left sidebars width is computed from layout theme in _buildDesktopBody.

class AppLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({required this.navigationShell, super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout>
    with SingleTickerProviderStateMixin {
  static const _youBranchIndex = 2;
  static const _swipeThreshold = 0.35;
  static final _rootRoutePattern = RegExp(r'^/channels/[^/]+$');
  static final _chatRoutePattern = RegExp('^/channels/[^/]+/.+');
  late final GoRouter _router;
  late final AnimationController _swipeController;

  @override
  void initState() {
    super.initState();
    _router = ref.read(fluxerRouterProvider);
    _router.routerDelegate.addListener(_onRouteChange);
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _router.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    if (mounted) {
      _swipeController.value = 0;
      setState(() {});
    }
  }

  String get _currentLocation {
    final config = _router.routerDelegate.currentConfiguration;
    return config.isNotEmpty ? config.last.matchedLocation : '/';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeGuildIdProvider, (previous, next) {
      if (next != null) {
        final guilds = ref.read(guildListViewModelProvider).guilds;
        final guild = guilds.where((g) => g.id == next).firstOrNull;
        ref
            .read(channelListViewModelProvider.notifier)
            .loadChannels(next, serverName: guild?.name);
        ref.read(memberListViewModelProvider.notifier).loadMembers(next);
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
    final location = _currentLocation;
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
    final location = _currentLocation;
    final showSidebar = _isRootRoute(location);

    if (showSidebar) {
      return Scaffold(
        backgroundColor: context.colors.backgroundPrimary,
        body: Column(
          children: [
            Expanded(child: _buildMobileSidebar(location)),
            _buildBottomNav(context),
          ],
        ),
      );
    }

    final isChatRoute = _isChatRoute(location);
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: _buildSwipeableContent(location, showBottomNav: !isChatRoute),
    );
  }

  Widget _buildSwipeableContent(
    String location, {
    required bool showBottomNav,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _swipeController.value =
            (_swipeController.value + (details.primaryDelta ?? 0) / screenWidth)
                .clamp(0.0, 1.0);
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dx;
        if (_swipeController.value > _swipeThreshold || velocity > 800) {
          unawaited(
            _swipeController.forward().then((_) {
              if (mounted) {
                context.pop();
              }
            }),
          );
        } else {
          unawaited(_swipeController.reverse());
        }
      },
      child: AnimatedBuilder(
        animation: _swipeController,
        builder: (context, child) {
          if (_swipeController.value == 0) {
            if (showBottomNav) {
              return Column(
                children: [
                  Expanded(child: child!),
                  _buildBottomNav(context),
                ],
              );
            }
            return child!;
          }
          final slideOffset = _swipeController.value * screenWidth;
          Widget slidingContent = child!;
          if (showBottomNav) {
            slidingContent = Column(
              children: [
                Expanded(child: slidingContent),
                _buildBottomNav(context),
              ],
            );
          }
          return Stack(
            children: [
              IgnorePointer(
                child: Column(
                  children: [
                    Expanded(child: _buildMobileSidebar(location)),
                    _buildBottomNav(context),
                  ],
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: 0.5 * (1 - _swipeController.value),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(slideOffset, 0),
                child: slidingContent,
              ),
            ],
          );
        },
        child: widget.navigationShell,
      ),
    );
  }

  Widget _buildMobileSidebar(String location) {
    final isDm = location.startsWith('/channels/@me');
    return ColoredBox(
      color: context.colors.channelSidebarBackground,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const GuildNavbar(),
            Expanded(child: isDm ? const DMList() : const GuildSidebar()),
          ],
        ),
      ),
    );
  }

  /// Matches /channels/@me, /channels/@favorites, /channels/:guildId (no sub-path).
  bool _isRootRoute(String location) => _rootRoutePattern.hasMatch(location);

  /// Matches any /channels/:x/:y path (DM channel, guild channel, message).
  bool _isChatRoute(String location) => _chatRoutePattern.hasMatch(location);

  Widget _buildProfileTabIcon({
    required UserSettingsViewState user,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == _youBranchIndex;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1 : 0.5,
      child: FluxerAvatar.user(
        fallbackText: user.displayName,
        userId: user.userId,
        imageUrl: user.avatarUrl,
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
