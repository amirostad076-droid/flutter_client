import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/domain/channel_settings_tab.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/channel_settings_nav_page.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/channel_settings_tab_body.dart';
import 'package:fluxer_app/features/channels/presentation/delete_channel_flow.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChannelSettingsModal extends ConsumerStatefulWidget {
  const ChannelSettingsModal({
    required this.channelId,
    this.initialTab = ChannelSettingsTab.overview,
    super.key,
  });

  final String channelId;
  final ChannelSettingsTab initialTab;

  static Future<void> show(
    BuildContext context, {
    required String channelId,
    ChannelSettingsTab? initialTab,
  }) {
    if (initialTab == null) {
      return context.push(RoutePaths.channelSettingsPath(channelId));
    }
    return context.push(
      RoutePaths.channelSettingsPath(channelId, tab: _tabQuery(initialTab)),
    );
  }

  static String _tabQuery(ChannelSettingsTab tab) {
    return switch (tab) {
      ChannelSettingsTab.overview => 'overview',
      ChannelSettingsTab.permissions => 'permissions',
      ChannelSettingsTab.invites => 'invites',
      ChannelSettingsTab.webhooks => 'webhooks',
    };
  }

  @override
  ConsumerState<ChannelSettingsModal> createState() =>
      _ChannelSettingsModalState();
}

class _ChannelSettingsModalState extends ConsumerState<ChannelSettingsModal> {
  late ChannelSettingsTab _selectedTab = widget.initialTab;

  Future<void> _confirmDeleteChannel(Channel channel) async {
    await DeleteChannelFlow.confirmAndDelete(context, ref, channel: channel);
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final AsyncValue<Channel?> channelAsync = ref.watch(
      channelByIdProvider(widget.channelId),
    );
    final AsyncValue<int> permissionsAsync = ref.watch(
      effectiveGuildChannelPermissionBitsProvider(widget.channelId),
    );
    return channelAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: FluxerLoadingSpinner())),
      error: (Object error, StackTrace stackTrace) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      data: (Channel? channel) {
        if (channel == null) {
          return Scaffold(body: Center(child: Text(l10n.comingSoon)));
        }
        return permissionsAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: FluxerLoadingSpinner())),
          error: (Object error, StackTrace stackTrace) =>
              Scaffold(body: Center(child: Text(error.toString()))),
          data: (int permissions) {
            final List<ChannelSettingsTab> visibleTabs =
                visibleChannelSettingsTabs(
                  channel: channel,
                  permissions: permissions,
                );
            if (visibleTabs.isEmpty) {
              return Scaffold(body: Center(child: Text(l10n.comingSoon)));
            }
            final ChannelSettingsTab activeTab =
                visibleTabs.contains(_selectedTab)
                ? _selectedTab
                : visibleTabs.first;
            if (activeTab != _selectedTab) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedTab = activeTab);
                }
              });
            }
            return _buildDesktop(
              context,
              l10n: l10n,
              channel: channel,
              permissions: permissions,
              visibleTabs: visibleTabs,
              activeTab: activeTab,
            );
          },
        );
      },
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required FluxerLocalizations l10n,
    required Channel channel,
    required int permissions,
    required List<ChannelSettingsTab> visibleTabs,
    required ChannelSettingsTab activeTab,
  }) {
    final bool canDelete = hasPermission(
      permissions,
      Permission.manageChannels,
    );
    final List<SettingsSidebarItem> sidebarItems = _buildSidebarItems(
      l10n: l10n,
      channel: channel,
      visibleTabs: visibleTabs,
      canDelete: canDelete,
    );
    final int selectedIndex = visibleTabs.indexOf(activeTab);
    final int deleteIndex = sidebarItems.length - 1;
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Row(
        children: <Widget>[
          SizedBox(
            width: 300,
            child: ColoredBox(
              color: context.colors.backgroundPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 16, 12),
                    child: Row(
                      children: <Widget>[
                        ChannelIcon(type: channel.type, channel: channel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            channel.name,
                            style: context.textStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SettingsSidebar(
                      items: sidebarItems,
                      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                      onSelected: (int index) {
                        if (canDelete && index == deleteIndex) {
                          unawaited(_confirmDeleteChannel(channel));
                          return;
                        }
                        if (index >= 0 && index < visibleTabs.length) {
                          setState(() => _selectedTab = visibleTabs[index]);
                        }
                      },
                    ),
                  ),
                ],
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
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 12, 12, 0),
                  child: Row(
                    children: <Widget>[
                      Text(
                        channelSettingsTabTitle(l10n, activeTab),
                        style: context.textStyles.heading,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => context.pop(),
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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ChannelSettingsTabBody(
                    channel: channel,
                    tab: activeTab,
                    permissions: permissions,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<SettingsSidebarItem> _buildSidebarItems({
  required FluxerLocalizations l10n,
  required Channel channel,
  required List<ChannelSettingsTab> visibleTabs,
  required bool canDelete,
}) {
  final List<SettingsSidebarItem> items = <SettingsSidebarItem>[];
  String? previousCategory;
  for (final ChannelSettingsTab tab in visibleTabs) {
    final String? category = channelSettingsTabCategoryLabel(l10n, tab);
    if (category != null && category != previousCategory) {
      items.add(SettingsSidebarItem.separator(category));
      previousCategory = category;
    }
    items.add(
      SettingsSidebarItem(
        channelSettingsTabTitle(l10n, tab),
        icon: channelSettingsTabIcon(tab),
      ),
    );
  }
  if (canDelete) {
    items.add(const SettingsSidebarItem.separator());
    items.add(
      SettingsSidebarItem(
        channelSettingsDeleteLabel(l10n, channel: channel),
        icon: PhosphorIconsFill.trash,
        isDestructive: true,
      ),
    );
  }
  return items;
}
