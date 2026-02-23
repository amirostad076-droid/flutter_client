import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/gateway_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/auth/providers/auth_providers.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_appearance.dart';
import 'package:fluxeron/features/settings/presentation/widgets/user_profile.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  static const _items = [
    SettingsSidebarItem.separator('USER SETTINGS'),
    SettingsSidebarItem('My Account'),
    SettingsSidebarItem('Profiles'),
    SettingsSidebarItem('Privacy & Safety'),
    SettingsSidebarItem.separator('APP SETTINGS'),
    SettingsSidebarItem('Appearance'),
    SettingsSidebarItem('Accessibility'),
    SettingsSidebarItem('Voice & Video'),
    SettingsSidebarItem('Notifications'),
    SettingsSidebarItem('Keybinds'),
    SettingsSidebarItem.separator(),
    SettingsSidebarItem('Log Out'),
  ];

  var _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ColoredBox(
              color: FluxerColors.backgroundSecondary,
              child: SettingsSidebar(
                items: _items,
                selectedIndex: _selectedIndex,
                onSelected: _onSidebarSelected,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildCloseButton(),
                  ),
                ),
                Expanded(child: _buildContent(state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSidebarSelected(int index) {
    if (_items[index].label == 'Log Out') {
      unawaited(_logout());
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await ref.read(gatewayClientProvider).disconnect();
    ref.read(fluxerAuthTokenProvider.notifier).setToken(null);

    ref
      ..invalidate(dmViewModelProvider)
      ..invalidate(serverListViewModelProvider)
      ..invalidate(chatViewModelProvider);

    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    ref.read(authStateProvider.notifier).setAuthenticated(value: false);
    if (mounted) {
      context.go('/login');
    }
  }

  Widget _buildContent(UserSettingsViewState state) {
    final label = _items[_selectedIndex].label;
    switch (label) {
      case 'My Account':
        return UserProfile(userState: state);
      case 'Appearance':
        return UserAppearance(
          isDarkTheme: state.isDarkTheme,
          isCompact: state.messageDisplayCompact,
          onToggleTheme: () =>
              ref.read(userSettingsViewModelProvider.notifier).toggleTheme(),
          onToggleCompact: () =>
              ref.read(userSettingsViewModelProvider.notifier).toggleCompact(),
        );
      default:
        return Center(
          child: Text(
            label,
            style: const TextStyle(color: FluxerColors.textMuted, fontSize: 24),
          ),
        );
    }
  }

  Widget _buildCloseButton() => InkWell(
    onTap: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/servers');
      }
    },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: FluxerColors.interactiveMuted, width: 2),
      ),
      child: const PhosphorIcon(
        PhosphorIconsFill.x,
        size: 18,
        color: FluxerColors.interactiveNormal,
      ),
    ),
  );
}
