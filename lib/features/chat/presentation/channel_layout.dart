import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_header.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_chat_content.dart';
import 'package:fluxer_app/features/members/presentation/widgets/channel_members.dart';

/// Wrapper screen for the chat area content.
/// Takes serverId and channelId from go_router params.
class ChannelLayout extends ConsumerWidget {
  final String serverId;
  final String channelId;
  final String? messageId;

  const ChannelLayout({
    required this.serverId,
    required this.channelId,
    this.messageId,
    super.key,
  });

  static const _minWidthForMemberList = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMemberListVisible = ref.watch(
      channelListViewModelProvider.select((s) => s.isMemberListVisible),
    );

    return ColoredBox(
      color: context.colors.chatBackground,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showMemberList =
                isMemberListVisible &&
                constraints.maxWidth >= _minWidthForMemberList;

            return Column(
              children: [
                const ChannelHeader(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ChannelChatContent(
                          channelId: channelId,
                          targetMessageId: messageId,
                          showTopBar: false,
                        ),
                      ),
                      if (showMemberList) const ChannelMembers(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
