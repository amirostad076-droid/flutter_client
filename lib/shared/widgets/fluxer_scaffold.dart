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
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_panel.dart';

const _kLeftSidebarsWidth = 312.0;

/// Shell route widget that provides the persistent server + channel sidebars
/// around the content area.
class FluxerScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const FluxerScaffold({required this.child, super.key});

  @override
  ConsumerState<FluxerScaffold> createState() => _FluxerScaffoldState();
}

class _FluxerScaffoldState extends ConsumerState<FluxerScaffold> {
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

    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: ResponsiveLayout(
        builder: (context, _) => _buildSidebarLayout(),
      ),
    );
  }

  Widget _buildSidebarLayout() {
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

}
