import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/domain/channel_settings_tab.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/channel_settings_page_shell.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/channel_settings_tab_body.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class ChannelSettingsOverviewPage extends ConsumerWidget {
  const ChannelSettingsOverviewPage({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChannelSettingsTabPage(
      channelId: channelId,
      tab: ChannelSettingsTab.overview,
    );
  }
}

class ChannelSettingsPermissionsPage extends ConsumerWidget {
  const ChannelSettingsPermissionsPage({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChannelSettingsTabPage(
      channelId: channelId,
      tab: ChannelSettingsTab.permissions,
    );
  }
}

class ChannelSettingsInvitesPage extends ConsumerWidget {
  const ChannelSettingsInvitesPage({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChannelSettingsTabPage(
      channelId: channelId,
      tab: ChannelSettingsTab.invites,
    );
  }
}

class ChannelSettingsWebhooksPage extends ConsumerWidget {
  const ChannelSettingsWebhooksPage({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChannelSettingsTabPage(
      channelId: channelId,
      tab: ChannelSettingsTab.webhooks,
    );
  }
}

class _ChannelSettingsTabPage extends ConsumerWidget {
  const _ChannelSettingsTabPage({required this.channelId, required this.tab});

  final String channelId;
  final ChannelSettingsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final AsyncValue<Channel?> channelAsync = ref.watch(
      channelByIdProvider(channelId),
    );
    final AsyncValue<int> permissionsAsync = ref.watch(
      effectiveGuildChannelPermissionBitsProvider(channelId),
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
            if (!visibleTabs.contains(tab)) {
              return Scaffold(body: Center(child: Text(l10n.comingSoon)));
            }
            return ChannelSettingsPageShell(
              tab: tab,
              body: ChannelSettingsTabBody(
                channel: channel,
                tab: tab,
                permissions: permissions,
              ),
            );
          },
        );
      },
    );
  }
}
