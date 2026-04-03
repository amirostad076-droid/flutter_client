import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild_overview.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild_roles.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxer_app/features/settings/providers/guild_settings_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/settings/fluxer_settings_nav_list.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuildSettingsModal extends ConsumerStatefulWidget {
  final String guildId;
  final int initialTab;

  const GuildSettingsModal({
    required this.guildId,
    this.initialTab = 0,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required String guildId,
  }) {
    if (isMobileLayout(context)) {
      return _showMobileSettings(context, guildId: guildId);
    }

    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GuildSettingsModal(guildId: guildId),
      ),
    );
  }

  static Future<void> _showMobileSettings(
    BuildContext context, {
    required String guildId,
  }) async {
    await FluxerBottomSheet.showScrollable<void>(
      context,
      title: 'Server Settings',
      useRootNavigator: true,
      builder: (sheetContext, scrollController, close) =>
          _MobileGuildSettingsNavBody(
            guildId: guildId,
            onClose: close,
            scrollController: scrollController,
          ),
    );
  }

  @override
  ConsumerState<GuildSettingsModal> createState() => _GuildSettingsModalState();
}

class _GuildSettingsModalState extends ConsumerState<GuildSettingsModal> {
  static const _items = [
    SettingsSidebarItem('Overview'),
    SettingsSidebarItem('Roles'),
    SettingsSidebarItem.separator(),
    SettingsSidebarItem('Emoji'),
    SettingsSidebarItem('Stickers'),
    SettingsSidebarItem.separator('MODERATION'),
    SettingsSidebarItem('Members'),
    SettingsSidebarItem('Channels'),
    SettingsSidebarItem('Bans'),
  ];

  late int _selectedIndex = widget.initialTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guildSettingsViewModelProvider.notifier)
          .loadServer(widget.guildId)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guildSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ColoredBox(
              color: context.colors.backgroundSecondary,
              child: SettingsSidebar(
                items: _items,
                selectedIndex: _selectedIndex,
                onSelected: (i) => setState(() => _selectedIndex = i),
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
                    child: _buildCloseButton(context),
                  ),
                ),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GuildSettingsViewState state) {
    final guild = state.guild;
    if (guild == null) {
      return const Center(child: FluxerLoadingSpinner());
    }

    switch (_selectedIndex) {
      case 0:
        return GuildOverview(guild: guild);
      case 1:
        return GuildRoles(roles: state.roles);
      default:
        return Center(
          child: Text(
            _items[_selectedIndex].label,
            style: TextStyle(
              color: context.colors.textPrimaryMuted,
              fontSize: 24,
            ),
          ),
        );
    }
  }

  Widget _buildCloseButton(BuildContext context) => InkWell(
    onTap: () => context.pop(),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.interactiveMuted, width: 2),
      ),
      child: PhosphorIcon(
        PhosphorIconsFill.x,
        size: 18,
        color: context.colors.interactiveNormal,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Mobile settings — stacked bottom sheets
// ---------------------------------------------------------------------------

class _MobileGuildSettingsNavBody extends ConsumerStatefulWidget {
  const _MobileGuildSettingsNavBody({
    required this.guildId,
    required this.onClose,
    required this.scrollController,
  });

  final String guildId;
  final VoidCallback onClose;
  final ScrollController scrollController;

  @override
  ConsumerState<_MobileGuildSettingsNavBody> createState() =>
      _MobileGuildSettingsNavBodyState();
}

class _MobileGuildSettingsNavBodyState
    extends ConsumerState<_MobileGuildSettingsNavBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guildSettingsViewModelProvider.notifier)
          .loadServer(widget.guildId)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guildSettingsViewModelProvider);

    if (state.isLoading || state.guild == null) {
      return const Center(child: FluxerLoadingSpinner());
    }

    return FluxerSettingsNavList(
      controller: widget.scrollController,
      groups: [
        FluxerSettingsNavGroup(
          items: [
            FluxerSettingsNavItem(
              label: 'Overview',
              icon: PhosphorIconsFill.gear,
              onTap: () => _openSettingsPage('Overview'),
            ),
            FluxerSettingsNavItem(
              label: 'Roles',
              icon: PhosphorIconsFill.shieldStar,
              onTap: () => _openSettingsPage('Roles'),
            ),
          ],
        ),
        FluxerSettingsNavGroup(
          items: [
            FluxerSettingsNavItem(
              label: 'Emoji',
              icon: PhosphorIconsFill.smiley,
              onTap: () => _openSettingsPage('Emoji'),
            ),
            FluxerSettingsNavItem(
              label: 'Stickers',
              icon: PhosphorIconsFill.sticker,
              onTap: () => _openSettingsPage('Stickers'),
            ),
          ],
        ),
        FluxerSettingsNavGroup(
          label: 'MODERATION',
          items: [
            FluxerSettingsNavItem(
              label: 'Members',
              icon: PhosphorIconsFill.users,
              onTap: () => _openSettingsPage('Members'),
            ),
            FluxerSettingsNavItem(
              label: 'Channels',
              icon: PhosphorIconsFill.hash,
              onTap: () => _openSettingsPage('Channels'),
            ),
            FluxerSettingsNavItem(
              label: 'Bans',
              icon: PhosphorIconsFill.hammer,
              onTap: () => _openSettingsPage('Bans'),
            ),
          ],
        ),
      ],
    );
  }

  void _openSettingsPage(String label) {
    unawaited(
      FluxerBottomSheet.showScrollable<void>(
        context,
        title: label,
        useRootNavigator: true,
        builder: (sheetContext, scrollController, close) =>
            _MobileGuildSettingsContentBody(
              label: label,
              scrollController: scrollController,
            ),
      ),
    );
  }
}

class _MobileGuildSettingsContentBody extends ConsumerWidget {
  const _MobileGuildSettingsContentBody({
    required this.label,
    required this.scrollController,
  });

  final String label;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guildSettingsViewModelProvider);
    final guild = state.guild;

    if (guild == null) {
      return const Center(child: FluxerLoadingSpinner());
    }

    switch (label) {
      case 'Overview':
        return GuildOverview(guild: guild, scrollController: scrollController);
      case 'Roles':
        return GuildRoles(
          roles: state.roles,
          scrollController: scrollController,
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
}
