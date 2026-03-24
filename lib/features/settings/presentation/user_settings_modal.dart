import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/app_runtime_info_provider.dart';
import 'package:fluxeron/core/providers/gateway_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/providers/account_manager_provider.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/gateway/providers/gateway_event_providers.dart';
import 'package:fluxeron/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxeron/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_appearance.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_profile.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/features/shell/presentation/responsive_layout.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserSettingsModal extends ConsumerStatefulWidget {
  const UserSettingsModal({this.openProfileSection = false, super.key});

  final bool openProfileSection;

  static Future<void> show(
    BuildContext context, {
    bool openProfileSection = false,
  }) {
    return showModalBottomSheet<void>(
      elevation: 7,
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 1400),
      backgroundColor: context.colors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UserSettingsModal(openProfileSection: openProfileSection),
    );
  }

  @override
  ConsumerState<UserSettingsModal> createState() => _UserSettingsModalState();
}

class _UserSettingsModalState extends ConsumerState<UserSettingsModal>
    with SingleTickerProviderStateMixin {
  static const _items = [
    SettingsSidebarItem.separator('YOUR ACCOUNT'),
    SettingsSidebarItem('Profile', icon: PhosphorIconsFill.user),
    SettingsSidebarItem(
      'Security & Login',
      icon: PhosphorIconsFill.shieldCheck,
    ),
    SettingsSidebarItem('Fluxer Plutonium', icon: PhosphorIconsFill.crown),
    SettingsSidebarItem('Gifts & Codes', icon: PhosphorIconsFill.gift),
    SettingsSidebarItem('Privacy Dashboard', icon: PhosphorIconsFill.detective),
    SettingsSidebarItem('Authorized Apps', icon: PhosphorIconsFill.gridFour),
    SettingsSidebarItem('Blocked Users', icon: PhosphorIconsFill.prohibit),
    SettingsSidebarItem('Linked Devices', icon: PhosphorIconsFill.devices),
    SettingsSidebarItem('Connections', icon: PhosphorIconsFill.usersThree),
    SettingsSidebarItem.separator('APPLICATION'),
    SettingsSidebarItem('Look & Feel', icon: PhosphorIconsFill.paintBrush),
    SettingsSidebarItem('Accessibility', icon: PhosphorIconsFill.wheelchair),
    SettingsSidebarItem('Messages & Media', icon: PhosphorIconsFill.chatCircle),
    SettingsSidebarItem('Audio & Video', icon: PhosphorIconsFill.microphone),
    SettingsSidebarItem('Keybinds', icon: PhosphorIconsFill.keyboard),
    SettingsSidebarItem('Sounds & Alerts', icon: PhosphorIconsFill.bell),
    SettingsSidebarItem('Language & Time', icon: PhosphorIconsFill.translate),
    SettingsSidebarItem('Advanced', icon: PhosphorIconsFill.faders),
    SettingsSidebarItem.separator('DEVELOPER'),
    SettingsSidebarItem('Applications', icon: PhosphorIconsFill.code),
    SettingsSidebarItem.separator(),
    SettingsSidebarItem("What's New", icon: PhosphorIconsFill.megaphone),
    SettingsSidebarItem(
      'Log Out',
      icon: PhosphorIconsFill.signOut,
      isDestructive: true,
    ),
  ];

  var _selectedIndex = 1;
  var _showingContent = false;

  late final AnimationController _animController;
  late final Animation<Offset> _menuSlide;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0))
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
    _contentSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
    if (widget.openProfileSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !isMobileLayout(context)) {
          return;
        }
        final int profileIndex = _indexOfProfileSidebarItem();
        if (profileIndex >= 0) {
          _openMobileContent(profileIndex);
        }
      });
    }
  }

  int _indexOfProfileSidebarItem() {
    for (var i = 0; i < _items.length; i++) {
      final SettingsSidebarItem item = _items[i];
      if (!item.isSeparator && item.label == 'Profile') {
        return i;
      }
    }
    return -1;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openMobileContent(int index) {
    setState(() {
      _selectedIndex = index;
      _showingContent = true;
    });
    unawaited(_animController.forward());
  }

  void _closeMobileContent() {
    unawaited(
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _showingContent = false);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;

    final state = ref.watch(userSettingsViewModelProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.borderColor),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        position: DecorationPosition.foreground,
        child: SizedBox(
          height: height,
          child: isMobileLayout(context)
              ? _buildMobileLayout(state)
              : _buildDesktopLayout(state),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(UserSettingsViewState state) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: ColoredBox(
                  color: context.colors.backgroundPrimary,
                  child: SettingsSidebar(
                    items: _items,
                    selectedIndex: _selectedIndex,
                    onSelected: _onItemSelected,
                    userId: state.userId,
                    username: state.displayName,
                    avatarUrl: state.avatarUrl,
                    avatarColor: state.avatarColor,
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: context.colors.borderColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 12, 12, 0),
                      child: Row(
                        children: [
                          Text(
                            _items[_selectedIndex].label,
                            style: context.textStyles.heading,
                          ),
                          const Spacer(),
                          _buildCloseButton(),
                        ],
                      ),
                    ),
                    Expanded(child: _buildContent(state)),
                    _buildBuildInfoFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(UserSettingsViewState state) {
    final groups = _buildMobileGroups();

    return ClipRect(
      child: Stack(
        children: [
          SlideTransition(
            position: _menuSlide,
            child: IgnorePointer(
              ignoring: _showingContent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDragHandle(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Settings', style: context.textStyles.heading),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: groups.length + 1,
                      itemBuilder: (context, index) {
                        if (index == groups.length) {
                          return _buildBuildInfoFooter();
                        }
                        final group = groups[index];
                        return _buildMobileGroup(group);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showingContent)
            SlideTransition(
              position: _contentSlide,
              child: _MobileContentView(
                title: _items[_selectedIndex].label,
                onBack: _closeMobileContent,
                child: _buildContent(state),
              ),
            ),
        ],
      ),
    );
  }

  List<_MobileSettingsGroup> _buildMobileGroups() {
    final groups = <_MobileSettingsGroup>[];
    String? currentLabel;
    var currentItems = <(SettingsSidebarItem, int)>[];

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isSeparator) {
        if (currentItems.isNotEmpty) {
          groups.add(
            _MobileSettingsGroup(label: currentLabel, items: currentItems),
          );
        }
        currentLabel = item.label.isNotEmpty ? item.label : null;
        currentItems = [];
      } else {
        currentItems.add((item, i));
      }
    }

    if (currentItems.isNotEmpty) {
      groups.add(
        _MobileSettingsGroup(label: currentLabel, items: currentItems),
      );
    }

    return groups;
  }

  Widget _buildMobileGroup(_MobileSettingsGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
              child: Text(group.label!, style: context.textStyles.categoryName),
            ),
          Material(
            color: context.colors.backgroundSecondaryAlt,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      color: context.colors.borderColor,
                      height: 1,
                      endIndent: 15,
                      indent: 15,
                    ),
                  _buildMobileItem(
                    group.items[i].$1,
                    () => _onItemSelected(group.items[i].$2, pushMobile: true),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileItem(SettingsSidebarItem item, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (item.icon != null) ...[
                PhosphorIcon(
                  item.icon!,
                  size: 22,
                  color: item.isDestructive
                      ? context.colors.textDanger
                      : context.colors.interactiveNormal,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.isDestructive
                        ? context.colors.textDanger
                        : context.colors.textChat,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!item.isDestructive)
                PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: context.colors.textPrimaryMuted,
                ),
            ],
          ),
        ),
      );

  void _onItemSelected(int index, {bool pushMobile = false}) {
    if (_items[index].isDestructive) {
      unawaited(_logout());
      return;
    }
    if (pushMobile) {
      _openMobileContent(index);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _logout() async {
    await ref.read(gatewayConnectionProvider).disconnect();
    ref.read(gatewayReadyProvider.notifier).reset();
    ref.read(fluxerAuthTokenProvider.notifier).setToken(null);

    ref
      // Gateway
      ..invalidate(gatewayConnectionProvider)
      ..invalidate(gatewayEventListenerProvider)
      ..invalidate(gatewayStateListenerProvider)
      ..invalidate(connectivityListenerProvider)
      // Gateway event state
      ..invalidate(typingIndicatorsProvider)
      ..invalidate(voiceStatesMapProvider)
      ..invalidate(activeCallsProvider)
      ..invalidate(inviteCacheProvider)
      // Session
      ..invalidate(currentUserIdProvider)
      // View models
      ..invalidate(dmViewModelProvider)
      ..invalidate(guildListViewModelProvider)
      ..invalidate(organizedGuildListProvider)
      ..invalidate(folderExpandedStateProvider)
      ..invalidate(channelListViewModelProvider)
      ..invalidate(memberListViewModelProvider)
      ..invalidate(chatViewModelProvider)
      ..invalidate(userSettingsViewModelProvider)
      ..invalidate(loginViewModelProvider);

    final userId = ref.read(currentUserIdProvider) ?? '';
    await ref.read(accountManagerProvider.notifier).signOut(userId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildContent(UserSettingsViewState state) {
    final label = _items[_selectedIndex].label;
    switch (label) {
      case 'Profile':
        return UserProfile(userState: state);
      case 'Look & Feel':
        return UserAppearance(
          isCompact: state.messageDisplayCompact,
          onToggleCompact: () =>
              ref.read(userSettingsViewModelProvider.notifier).toggleCompact(),
        );
      default:
        return Center(
          child: Text(
            label,
            style: TextStyle(
              color: context.colors.textPrimaryMuted,
              fontSize: 24,
            ),
          ),
        );
    }
  }

  Widget _buildDragHandle() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.interactiveMuted,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildCloseButton() => InkWell(
    onTap: () => Navigator.of(context).pop(),
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      width: 36,
      height: 36,
      child: PhosphorIcon(
        PhosphorIconsRegular.x,
        size: 18,
        color: context.colors.interactiveNormal,
      ),
    ),
  );

  Widget _buildBuildInfoFooter() {
    final runtimeInfoAsync = ref.watch(appRuntimeInfoProvider);
    final text = runtimeInfoAsync.when(
      data: (runtimeInfo) =>
          'v${runtimeInfo.version} (${runtimeInfo.buildNumber})'
          ' • ${runtimeInfo.environment.name}'
          ' • ${_formatProviderLabel(runtimeInfo.pushProvider.name)}',
      loading: () => '',
      error: (_, _) => '',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Align(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: context.colors.textPrimaryMuted,
          ),
        ),
      ),
    );
  }

  String _formatProviderLabel(String providerName) {
    switch (providerName) {
      case 'firebaseMessaging':
        return 'firebase';
      case 'unifiedPush':
        return 'unifiedpush';
      case 'apple':
        return 'apple';
      default:
        return providerName;
    }
  }
}

class _MobileSettingsGroup {
  const _MobileSettingsGroup({required this.items, this.label});

  final String? label;
  final List<(SettingsSidebarItem, int)> items;
}

class _MobileContentView extends StatelessWidget {
  const _MobileContentView({
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onBack();
        }
      },
      child: ColoredBox(
        color: context.colors.backgroundSecondary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.arrowLeft,
                      color: context.colors.interactiveNormal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(title, style: context.textStyles.heading),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
