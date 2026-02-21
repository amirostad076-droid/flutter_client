import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMemberListVisible = ref.watch(
      channelListViewModelProvider.select((s) => s.isMemberListVisible),
    );

    return Row(
      children: [
        Expanded(child: ChatView(channelId: channelId)),
        if (isMemberListVisible) const MemberList(),
      ],
    );
  }
}
