import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/presentation/widgets/chat_view.dart';
import 'package:fluxeron/features/friends/presentation/widgets/friends_list.dart';

class DmScreen extends ConsumerWidget {
  final String? channelId;

  const DmScreen({this.channelId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (channelId == null) {
      return ColoredBox(
        color: context.colors.chatBackground,
        child: const FriendsList(),
      );
    }

    return ChatView(channelId: channelId!);
  }
}
