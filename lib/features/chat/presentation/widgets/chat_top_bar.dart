import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';

/// The chat header bar showing channel name, topic, and
/// action icons.
///
/// Channel and member-list state are no longer sourced
/// from [appViewModelProvider] (removed). This widget
/// now renders a static toolbar; channel context should
/// be supplied via constructor or a dedicated provider
/// once wired up.
class ChatTopBar extends ConsumerWidget {
  const ChatTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelListViewModelProvider);
    final channel = _findSelectedChannel(channelState);
    final isMemberListVisible = channelState.isMemberListVisible;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FluxerColors.separator)),
      ),
      child: Row(
        children: [
          if (channel != null) ...[
            ChannelIcon(type: channel.type),
            const SizedBox(width: 8),
            Text(channel.name, style: FluxerTextStyles.channelName),
          ],
          const Spacer(),
          _topBarIcon(PhosphorIconsFill.bell, 'Notification Settings'),
          _topBarIcon(PhosphorIconsFill.pushPin, 'Pinned Messages'),
          _topBarIcon(
            PhosphorIconsFill.users,
            'Member List',
            isActive: isMemberListVisible,
            onTap: () => ref
                .read(channelListViewModelProvider.notifier)
                .toggleMemberList(),
          ),
          SizedBox(
            width: 160,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: FluxerColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: FluxerColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIconsFill.magnifyingGlass,
                    size: 16,
                    color: FluxerColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          _topBarIcon(PhosphorIconsFill.tray, 'Inbox'),
          _topBarIcon(PhosphorIconsFill.question, 'Help'),
        ],
      ),
    );
  }

  Channel? _findSelectedChannel(ChannelListState state) {
    if (state.selectedChannelId == null) {
      return null;
    }
    for (final category in state.categories) {
      for (final channel in category.channels) {
        if (channel.id == state.selectedChannelId) {
          return channel;
        }
      }
    }
    return null;
  }

  Widget _topBarIcon(
    IconData icon,
    String tooltip, {
    bool isActive = false,
    VoidCallback? onTap,
  }) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: PhosphorIcon(
          icon,
          size: 24,
          color: isActive
              ? FluxerColors.interactiveActive
              : FluxerColors.interactiveNormal,
        ),
      ),
    ),
  );
}
