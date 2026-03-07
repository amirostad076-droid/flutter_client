import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_sidebar.dart';
import 'package:fluxeron/features/dm/presentation/widgets/dm_list.dart';
import 'package:fluxeron/features/servers/presentation/widgets/server_sidebar.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';

class MobileHomePage extends ConsumerWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDm = ref.watch(
      serverListViewModelProvider.select((s) => s.isDmActive),
    );

    return ColoredBox(
      color: FluxerColors.channelSidebarBackground,
      child: SafeArea(
        child: Row(
          children: [
            const ServerSidebar(),
            Expanded(child: isDm ? const DmList() : const ChannelSidebar()),
          ],
        ),
      ),
    );
  }
}
