import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_sidebar.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/dm/presentation/widgets/dm_list.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/features/servers/presentation/widgets/server_sidebar.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_panel.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
        builder: (context, mode) {
          switch (mode) {
            case LayoutMode.desktop:
              return _buildDesktopLayout();
            case LayoutMode.tablet:
              return _buildTabletLayout();
            case LayoutMode.mobile:
              return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
              UserPanel(onSettingsTap: () => context.go('/settings/user')),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildTabletLayout() {
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
              UserPanel(onSettingsTap: () => context.go('/settings/user')),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final isDm = ref.watch(
      serverListViewModelProvider.select((s) => s.isDmActive),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: SizedBox(
        width: _kLeftSidebarsWidth,
        child: Row(
          children: [
            const ServerSidebar(),
            Expanded(child: isDm ? const DmList() : const ChannelSidebar()),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 56,
            color: FluxerColors.backgroundPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.list),
                  color: FluxerColors.interactiveNormal,
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: Text('', style: FluxerTextStyles.channelName)),
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
