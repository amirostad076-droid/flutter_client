import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/chat/presentation/widgets/chat_top_bar.dart';
import 'package:fluxeron/features/chat/presentation/widgets/chat_view.dart';
import 'package:fluxeron/features/members/presentation/widgets/member_list.dart';

/// Wrapper screen for the chat area content.
/// Takes serverId and channelId from go_router params.
class ChatScreen extends ConsumerWidget {
  final String serverId;
  final String channelId;

  const ChatScreen({
    required this.serverId,
    required this.channelId,
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
            final showMemberList = isMemberListVisible &&
                constraints.maxWidth >= _minWidthForMemberList;

            return Column(
              children: [
                const ChatTopBar(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ChatView(
                          channelId: channelId,
                          showTopBar: false,
                        ),
                      ),
                      if (showMemberList) const MemberList(),
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
