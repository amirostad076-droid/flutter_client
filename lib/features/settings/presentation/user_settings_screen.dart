import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/gateway_provider.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_appearance.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_profile.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      elevation: 7,
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 1400),
      backgroundColor: FluxerColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) => const UserSettingsScreen(),
    );
  }

  @override
  ConsumerState<UserSettingsScreen> createState() =>
      _UserSettingsScreenState();
}

class _UserSettingsScreenState
    extends ConsumerState<UserSettingsScreen> {
  static const _items = [
    SettingsSidebarItem.separator('YOUR ACCOUNT'),
    SettingsSidebarItem(
      'Profile',
      icon: PhosphorIconsFill.user,
    ),
    SettingsSidebarItem(
      'Security & Login',
      icon: PhosphorIconsFill.shieldCheck,
    ),
    SettingsSidebarItem(
      'Fluxer Plutonium',
      icon: PhosphorIconsFill.crown,
    ),
    SettingsSidebarItem(
      'Gifts & Codes',
      icon: PhosphorIconsFill.gift,
    ),
    SettingsSidebarItem(
      'Privacy Dashboard',
      icon: PhosphorIconsFill.detective,
    ),
    SettingsSidebarItem(
      'Authorized Apps',
      icon: PhosphorIconsFill.gridFour,
    ),
    SettingsSidebarItem(
      'Blocked Users',
      icon: PhosphorIconsFill.prohibit,
    ),
    SettingsSidebarItem(
      'Linked Devices',
      icon: PhosphorIconsFill.devices,
    ),
    SettingsSidebarItem(
      'Connections',
      icon: PhosphorIconsFill.usersThree,
    ),
    SettingsSidebarItem.separator('APPLICATION'),
    SettingsSidebarItem(
      'Look & Feel',
      icon: PhosphorIconsFill.paintBrush,
    ),
    SettingsSidebarItem(
      'Accessibility',
      icon: PhosphorIconsFill.wheelchair,
    ),
    SettingsSidebarItem(
      'Messages & Media',
      icon: PhosphorIconsFill.chatCircle,
    ),
    SettingsSidebarItem(
      'Audio & Video',
      icon: PhosphorIconsFill.microphone,
    ),
    SettingsSidebarItem(
      'Keybinds',
      icon: PhosphorIconsFill.keyboard,
    ),
    SettingsSidebarItem(
      'Sounds & Alerts',
      icon: PhosphorIconsFill.bell,
    ),
    SettingsSidebarItem(
      'Language & Time',
      icon: PhosphorIconsFill.translate,
    ),
    SettingsSidebarItem(
      'Advanced',
      icon: PhosphorIconsFill.faders,
    ),
    SettingsSidebarItem.separator('DEVELOPER'),
    SettingsSidebarItem(
      'Applications',
      icon: PhosphorIconsFill.code,
    ),
    SettingsSidebarItem.separator(),
    SettingsSidebarItem(
      "What's New",
      icon: PhosphorIconsFill.megaphone,
    ),
    SettingsSidebarItem(
      'Log Out',
      icon: PhosphorIconsFill.signOut,
      isDestructive: true,
    ),
  ];

  var _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;

    final state = ref.watch(userSettingsViewModelProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: FluxerColors.divider,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
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
                    color: FluxerColors.backgroundPrimary,
                    child: SettingsSidebar(
                      items: _items,
                      selectedIndex: _selectedIndex,
                      onSelected: _onItemSelected,
                      username: state.displayName,
                      avatarUrl: state.avatarUrl,
                      avatarColor: state.avatarColor,
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: FluxerColors.divider,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          40,
                          12,
                          12,
                          0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _items[_selectedIndex].label,
                              style: FluxerTextStyles.heading,
                            ),
                            const Spacer(),
                            _buildCloseButton(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildContent(state),
                      ),
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
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Settings',
              style: FluxerTextStyles.heading,
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                if (item.isSeparator) {
                  return _buildMobileSeparator(item);
                }
                return _buildMobileItem(
                  item,
                  () => _onItemSelected(index, pushMobile: true),
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _buildMobileSeparator(
    SettingsSidebarItem item,
  ) =>
      Padding(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 4,
          left: 4,
        ),
        child: item.label.isNotEmpty
            ? Text(
                item.label,
                style: FluxerTextStyles.categoryName,
              )
            : const Divider(
                color: FluxerColors.divider,
                height: 1,
              ),
      );

  Widget _buildMobileItem(
    SettingsSidebarItem item,
    VoidCallback onTap,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: FluxerColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    PhosphorIcon(
                      item.icon!,
                      size: 22,
                      color: item.isDestructive
                          ? FluxerColors.textDanger
                          : FluxerColors.interactiveNormal,
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.isDestructive
                            ? FluxerColors.textDanger
                            : FluxerColors.textNormal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!item.isDestructive)
                    const PhosphorIcon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                      color: FluxerColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  void _onItemSelected(int index, {bool pushMobile = false}) {
    if (_items[index].isDestructive) {
      unawaited(_logout());
      return;
    }
    setState(() => _selectedIndex = index);
    if (pushMobile) {
      final state = ref.read(userSettingsViewModelProvider);
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _MobileSettingsContentPage(
              title: _items[index].label,
              child: _buildContent(state),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(gatewayClientProvider).disconnect();
    ref
        .read(fluxerAuthTokenProvider.notifier)
        .setToken(null);

    ref
      ..invalidate(dmViewModelProvider)
      ..invalidate(serverListViewModelProvider)
      ..invalidate(chatViewModelProvider);

    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    ref
        .read(authStateProvider.notifier)
        .setAuthenticated(value: false);
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
          isDarkTheme: state.isDarkTheme,
          isCompact: state.messageDisplayCompact,
          onToggleTheme: () => ref
              .read(
                userSettingsViewModelProvider.notifier,
              )
              .toggleTheme(),
          onToggleCompact: () => ref
              .read(
                userSettingsViewModelProvider.notifier,
              )
              .toggleCompact(),
        );
      default:
        return Center(
          child: Text(
            label,
            style: const TextStyle(
              color: FluxerColors.textMuted,
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
            color: FluxerColors.interactiveMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildCloseButton() => InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: PhosphorIcon(
            PhosphorIconsRegular.x,
            size: 18,
            color: FluxerColors.interactiveNormal,
          ),
        ),
      );
}

class _MobileSettingsContentPage extends StatelessWidget {
  const _MobileSettingsContentPage({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: FluxerColors.backgroundPrimary,
        leading: IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
        centerTitle: true,
      ),
      body: child,
    );
  }
}
