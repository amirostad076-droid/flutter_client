import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/shared/utils/chat_context_utils.dart';
import 'package:fluxeron/shared/widgets/circle_icon_button.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The chat header bar showing channel name, topic, and
/// action icons. Renders a compact single-row layout on
/// mobile and the full toolbar on tablet and desktop.
///
/// Resolves the title from server channels first, then
/// falls back to DM conversations so both contexts
/// display correctly.
class ChannelHeader extends ConsumerWidget {
  const ChannelHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final channelState = ref.watch(channelListViewModelProvider);
    final channel = findChannelById(channelState, channelId);
    final dm = channel == null
        ? findDmById(
            ref.watch(dmViewModelProvider.select((s) => s.conversations)),
            channelId,
          )
        : null;
    final isMemberListVisible = ref.watch(
      channelListViewModelProvider.select((s) => s.isMemberListVisible),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.borderColor)),
      ),
      child: ResponsiveLayout(
        builder: (context, mode) => switch (mode) {
          LayoutMode.mobile => _buildMobileBar(
            context,
            ref,
            channel: channel,
            dm: dm,
            isMemberListVisible: isMemberListVisible,
          ),
          _ => _buildDesktopBar(
            context,
            ref,
            channel: channel,
            dm: dm,
            isMemberListVisible: isMemberListVisible,
          ),
        },
      ),
    );
  }

  Widget _buildMobileBar(
    BuildContext context,
    WidgetRef ref, {
    required Channel? channel,
    required DmConversation? dm,
    required bool isMemberListVisible,
  }) => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _topBarIcon(
            context,
            Icons.arrow_back,
            'Back',
            onTap: () => context.pop(),
          ),
          _buildLeadingIcon(context, channel: channel, dm: dm),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _resolveTitle(channel: channel, dm: dm),
              style: context.textStyles.channelName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (dm != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleIconButton(
                icon: PhosphorIconsFill.phoneCall,
                backgroundColor: context.colors.backgroundTertiary,
                iconColor: context.colors.interactiveNormal,
                onTap: () {},
              ),
            ),
          if (dm != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleIconButton(
                icon: PhosphorIconsFill.videoCamera,
                backgroundColor: context.colors.backgroundTertiary,
                iconColor: context.colors.interactiveNormal,
                onTap: () {},
              ),
            ),
          if (dm == null)
            _topBarIcon(context, PhosphorIconsFill.magnifyingGlass, 'Search'),
          if (dm == null)
            _topBarIcon(
              context,
              PhosphorIconsFill.users,
              'Member List',
              isActive: isMemberListVisible,
              onTap: () => ref
                  .read(channelListViewModelProvider.notifier)
                  .toggleMemberList(),
            ),
        ],
      ),
    ),
  );

  Widget _buildDesktopBar(
    BuildContext context,
    WidgetRef ref, {
    required Channel? channel,
    required DmConversation? dm,
    required bool isMemberListVisible,
  }) => SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildLeadingIcon(context, channel: channel, dm: dm),
          const SizedBox(width: 8),
          Text(
            _resolveTitle(channel: channel, dm: dm),
            style: context.textStyles.channelName,
          ),
          const Spacer(),
          _topBarIcon(context, PhosphorIconsFill.bell, 'Notification Settings'),
          _topBarIcon(context, PhosphorIconsFill.pushPin, 'Pinned Messages'),
          if (dm == null)
            _topBarIcon(
              context,
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
                color: context.colors.backgroundTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: context.colors.textPrimaryMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIconsFill.magnifyingGlass,
                    size: 16,
                    color: context.colors.textPrimaryMuted,
                  ),
                ],
              ),
            ),
          ),
          _topBarIcon(context, PhosphorIconsFill.tray, 'Inbox'),
          _topBarIcon(context, PhosphorIconsFill.question, 'Help'),
        ],
      ),
    ),
  );

  Widget _buildLeadingIcon(
    BuildContext context, {
    required Channel? channel,
    required DmConversation? dm,
  }) {
    if (channel != null) {
      return ChannelIcon(type: channel.type);
    }
    if (dm != null) {
      return UserAvatar(
        displayName: dm.recipientName,
        userId: dm.recipientId,
        avatarUrl: _dmAvatarUrl(dm),
        status: dm.recipientStatus,
        size: 28,
      );
    }
    return PhosphorIcon(
      PhosphorIconsFill.chatCircle,
      size: 20,
      color: context.colors.interactiveNormal,
    );
  }

  String? _dmAvatarUrl(DmConversation dm) {
    final avatar = dm.recipientAvatar;
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn/avatars/'
        '${dm.recipientId}/$avatar.png';
  }

  String _resolveTitle({
    required Channel? channel,
    required DmConversation? dm,
  }) {
    if (channel != null) {
      return channel.name;
    }
    if (dm != null) {
      return dm.recipientName;
    }
    return '';
  }

  Widget _topBarIcon(
    BuildContext context,
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
              ? context.colors.interactiveActive
              : context.colors.interactiveNormal,
        ),
      ),
    ),
  );
}
