import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/router/navigate_to_content.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/friends/providers/friend_providers.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart' show fluxerMediaCdn;
import 'package:fluxeron/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxeron/features/shell/presentation/responsive_layout.dart';
import 'package:fluxeron/features/ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DMList extends ConsumerStatefulWidget {
  const DMList({super.key});

  @override
  ConsumerState<DMList> createState() => _DMListState();
}

class _DMListState extends ConsumerState<DMList> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void personalNote() {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      navigateToContent(context, RoutePaths.dmChannel(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(dmViewModelProvider);
    final convos = vm.conversations;
    final location = GoRouterState.of(context).matchedLocation;
    const mePrefix = '${RoutePaths.me}/';
    final selectedId = location.startsWith(mePrefix)
        ? location.substring(mePrefix.length)
        : null;

    final isMobile = isMobileLayout(context);

    final filteredConvos = _searchQuery.isEmpty
        ? convos
        : convos
              .where(
                (c) => c.displayName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: context.colors.channelSidebarBackground,
      child: Stack(
        children: [
          Column(
            children: [
              if (isMobile)
                _isSearching
                    ? _buildSearchHeader(context)
                    : _buildMobileHeader(context)
              else ...[
                _buildQuickSwitcher(context),
                Divider(color: context.colors.borderColor, height: 1),
                Builder(
                  builder: (context) {
                    final location = GoRouterState.of(context).matchedLocation;
                    final userId = ref.watch(currentUserIdProvider);
                    final isFriends = location == RoutePaths.me;
                    final isNotes =
                        userId != null &&
                        location == RoutePaths.dmChannel(userId);

                    return Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Column(
                        children: [
                          _buildNavButton(
                            context,
                            icon: PhosphorIconsFill.users,
                            label: 'Friends',
                            isSelected: isFriends,
                            onTap: () => context.go(RoutePaths.me),
                          ),
                          _buildNavButton(
                            context,
                            icon: PhosphorIconsFill.notePencil,
                            label: 'Personal Notes',
                            isSelected: isNotes,
                            onTap: () {
                              if (userId != null) {
                                navigateToContent(
                                  context,
                                  RoutePaths.dmChannel(userId),
                                );
                              }
                            },
                          ),
                          _buildNavButton(
                            context,
                            icon: PhosphorIconsFill.skull,
                            label: 'Plutonium',
                            onTap: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(color: context.colors.borderColor, height: 1),
                _buildDmHeader(context),
              ],
              Expanded(
                child: _buildConvoList(
                  context,
                  filteredConvos,
                  selectedId,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
          if (isMobile && !_isSearching)
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _buildComposeFab(context),
            ),
        ],
      ),
    );
  }

  Widget _buildComposeFab(BuildContext context) => SizedBox(
    width: 56,
    height: 56,
    child: FloatingActionButton(
      onPressed: () => context.go(RoutePaths.me),
      backgroundColor: context.colors.brandPrimary,
      elevation: 4,
      shape: const CircleBorder(),
      child: PhosphorIcon(
        PhosphorIconsFill.paperPlaneTilt,
        size: 24,
        color: context.colors.textPrimary,
      ),
    ),
  );

  Widget _buildSearchHeader(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 8),
        _buildCircleButton(
          context,
          icon: PhosphorIconsBold.x,
          onTap: _toggleSearch,
        ),
      ],
    ),
  );

  Widget _buildQuickSwitcher(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: context.layout.s2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Quick Switcher',
                style: TextStyle(
                  color: context.colors.textPrimaryMuted,
                  fontSize: 13,
                ),
              ),
            ),
            _buildKbdBadge(context, 'CTRL'),
            const SizedBox(width: 3),
            _buildKbdBadge(context, 'K'),
          ],
        ),
      ),
    ),
  );

  Widget _buildKbdBadge(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: context.colors.backgroundModifierSelected,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: context.colors.textPrimaryMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.layout.s2, vertical: 1),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: context.layout.radiusMd,
        hoverColor: context.colors.surfaceInteractiveHoverBg,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: context.layout.s2),
          decoration: isSelected
              ? BoxDecoration(
                  color: context.colors.surfaceInteractiveSelectedBg.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: context.layout.radiusMd,
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.brandPrimary
                      : context.colors.backgroundModifierAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? context.colors.textPrimary
                        : context.colors.interactiveNormal,
                  ),
                ),
              ),
              SizedBox(width: context.layout.s3),
              Text(
                label,
                style: context.textStyles.username.copyWith(
                  color: isSelected
                      ? context.colors.surfaceInteractiveSelectedColor
                      : context.colors.textPrimaryMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildCircleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: context.colors.backgroundModifierAccent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(icon, size: 18, color: context.colors.textPrimary),
    ),
  );

  Widget _buildMobileHeader(BuildContext context) {
    final pendingCount =
        ref.watch(pendingFriendRequestCountProvider).value ?? 0;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildCircleButton(
            context,
            icon: PhosphorIconsBold.magnifyingGlass,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.go(RoutePaths.me),
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundModifierAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.userPlus,
                        size: 16,
                        color: context.colors.textChat,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add Friends',
                        style: TextStyle(
                          color: context.colors.textChat,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: context.colors.statusDanger,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvoList(
    BuildContext context,
    List<DmConversation> convos,
    String? selectedId, {
    required bool isMobile,
  }) {
    final userId = ref.watch(currentUserIdProvider);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: convos.length + (isMobile && !_isSearching ? 1 : 0),
      itemBuilder: (context, index) {
        if (isMobile && !_isSearching && index == 0) {
          return _buildMobilePersonalNotes(
            context,
            userId,
            isSelected: selectedId == userId,
          );
        }

        final convoIndex = isMobile && !_isSearching ? index - 1 : index;
        final convo = convos[convoIndex];
        final isSelected = convo.id == selectedId;

        return _buildConvoTile(
          context,
          convo: convo,
          isSelected: isSelected,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildMobilePersonalNotes(
    BuildContext context,
    String? userId, {
    required bool isSelected,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        if (userId != null) {
          navigateToContent(context, RoutePaths.dmChannel(userId));
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.layout.s2,
          vertical: 1,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.layout.s2,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.surfaceInteractiveSelectedBg.withValues(
                  alpha: 0.15,
                )
              : Colors.transparent,
          borderRadius: context.layout.radiusMd,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.brandPrimary
                    : context.colors.backgroundModifierAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsFill.notePencil,
                  size: 20,
                  color: context.colors.interactiveNormal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Personal Notes',
              style: TextStyle(color: context.colors.textChat, fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDmHeader(BuildContext context) {
    final layout = context.layout;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s2, vertical: layout.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Direct Messages',
              style: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          PhosphorIcon(
            PhosphorIconsRegular.plus,
            size: 16,
            color: context.colors.textPrimaryMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildConvoTile(
    BuildContext context, {
    required bool isSelected,
    bool isMobile = false,
    DmConversation? convo,
    IconData? leadingIcon,
    String? leadingLabel,
    VoidCallback? onCustomTap,
  }) {
    final avatarSize = isMobile ? 40.0 : 32.0;
    final tileHeight = isMobile ? 52.0 : 42.0;

    final isIconTile =
        leadingIcon != null && leadingLabel != null && onCustomTap != null;
    if (isIconTile) {
      return _buildConvoStyleTile(
        context: context,
        leading: _buildCircleIcon(
          context,
          leadingIcon,
          isSelected,
          size: avatarSize,
        ),
        label: leadingLabel,
        isSelected: isSelected,
        onTap: onCustomTap,
      );
    }
    final c = convo!;
    final layout = context.layout;
    final hasUnread = c.unreadCount > 0;
    final currentUserId = ref.watch(currentUserIdProvider);

    String lastMessagePreview = c.lastMessage;
    if (c.lastMessage.isNotEmpty && c.lastMessageAuthorName != null) {
      final prefix = c.lastMessageAuthorId == currentUserId
          ? 'You'
          : c.lastMessageAuthorName!;
      lastMessagePreview = '$prefix: ${c.lastMessage}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: layout.radiusMd,
        hoverColor: context.colors.surfaceInteractiveHoverBg,
        onTap: () {
          navigateToContent(context, RoutePaths.dmChannel(c.id));
        },
        onLongPress: isMobile ? () => _showDmContextMenu(context, c) : null,
        child: Container(
          height: tileHeight,
          margin: EdgeInsets.symmetric(horizontal: layout.s2, vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: layout.s2),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.surfaceInteractiveSelectedBg.withValues(
                    alpha: 0.15,
                  )
                : Colors.transparent,
            borderRadius: layout.radiusMd,
          ),
          child: Row(
            children: [
              if (hasUnread && !isSelected)
                Container(
                  width: 4,
                  height: tileHeight * 0.5,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: context.colors.textChat,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              if (c.isGroup)
                _buildGroupAvatar(
                  context,
                  size: avatarSize,
                  isSelected: isSelected,
                )
              else
                FluxerAvatar.user(
                  fallbackText: c.recipientName,
                  userId: c.recipientId,
                  imageUrl: _dmAvatarUrl(c),
                  status: c.recipientStatus,
                  size: avatarSize,
                ),
              SizedBox(width: layout.s3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.displayName,
                      style: context.textStyles.username.copyWith(
                        color: isSelected
                            ? context.colors.surfaceInteractiveSelectedColor
                            : hasUnread
                            ? context.colors.textChat
                            : context.colors.textPrimaryMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastMessagePreview.isNotEmpty)
                      Text(
                        lastMessagePreview,
                        style: TextStyle(
                          color: context.colors.textPrimaryMuted.withValues(
                            alpha: 0.85,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatRelativeTime(c.lastMessageTime),
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDmContextMenu(
    BuildContext context,
    DmConversation convo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FluxerBottomSheet.show<Object>(
      context,
      builder: (context, _) => _DmBottomSheet(convo: convo, isMuted: false),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result is _InviteToGuildAction) {
      // TODO(fluxeron): send invite for guild ${result.guildId} in DM
      return;
    }

    final action = result as _DmAction;
    switch (action) {
      case _DmAction.markAsRead:
        unawaited(ref.read(dmViewModelProvider.notifier).markAsRead(convo.id));
      case _DmAction.viewProfile:
        // TODO(fluxeron): navigate to user profile sheet
        break;
      case _DmAction.voiceCall:
        // TODO(fluxeron): initiate voice call
        break;
      case _DmAction.addNote:
        // TODO(fluxeron): open add note sheet
        break;
      case _DmAction.mute15Min:
      case _DmAction.mute30Min:
      case _DmAction.mute1Hour:
      case _DmAction.mute3Hours:
      case _DmAction.mute4Hours:
      case _DmAction.mute8Hours:
      case _DmAction.mute24Hours:
      case _DmAction.mute3Days:
      case _DmAction.muteForever:
      case _DmAction.unmute:
        // TODO(fluxeron): implement mute/unmute with selected duration
        break;
      case _DmAction.pinToggle:
        // TODO(fluxeron): implement pin/unpin DM
        break;
      case _DmAction.editGroup:
        // TODO(fluxeron): open edit group sheet
        break;
      case _DmAction.block:
        // TODO(fluxeron): implement block/unblock user
        break;
      case _DmAction.closeDm:
        final success = await ref
            .read(dmViewModelProvider.notifier)
            .closeDmChannel(convo.id);
        if (!success && mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Failed to close conversation')),
          );
        }
      case _DmAction.copyUserId:
        await Clipboard.setData(ClipboardData(text: convo.recipientId));
      case _DmAction.copyChannelId:
        await Clipboard.setData(ClipboardData(text: convo.id));
    }
  }

  static String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return 'Now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7}w';
    }
    if (diff.inDays < 365) {
      return '${diff.inDays ~/ 30}mo';
    }
    return '${diff.inDays ~/ 365}y';
  }

  Widget _buildGroupAvatar(
    BuildContext context, {
    double size = 32,
    bool isSelected = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? context.colors.brandPrimary
            : context.colors.backgroundModifierAccent,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        PhosphorIconsFill.usersThree,
        size: size * 0.55,
        color: context.colors.interactiveNormal,
      ),
    );
  }

  Widget _buildCircleIcon(
    BuildContext context,
    IconData icon,
    bool isSelected, {
    double size = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? context.colors.brandPrimary
            : context.colors.backgroundTertiary,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        icon,
        size: size * 0.55,
        color: isSelected
            ? context.colors.textPrimary
            : context.colors.interactiveNormal,
      ),
    );
  }

  Widget _buildConvoStyleTile({
    required BuildContext context,
    required Widget leading,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: context.layout.radiusMd,
      hoverColor: context.colors.surfaceInteractiveHoverBg,
      onTap: onTap,
      child: Container(
        height: 42,
        margin: EdgeInsets.symmetric(
          horizontal: context.layout.s2,
          vertical: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: context.layout.s2),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.surfaceInteractiveSelectedBg.withValues(
                  alpha: 0.35,
                )
              : Colors.transparent,
          borderRadius: context.layout.radiusMd,
        ),
        child: Row(
          children: [
            leading,
            SizedBox(width: context.layout.s3),
            Expanded(
              child: Text(
                label,
                style: context.textStyles.username.copyWith(
                  color: isSelected
                      ? context.colors.surfaceInteractiveSelectedColor
                      : context.colors.textPrimaryMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _dmAvatarUrl(DmConversation convo) {
  final avatar = convo.recipientAvatar;
  if (avatar == null) {
    return null;
  }
  return '$fluxerMediaCdn'
      '/avatars/${convo.recipientId}/$avatar.png';
}

enum _DmAction {
  markAsRead,
  viewProfile,
  voiceCall,
  addNote,
  mute15Min,
  mute30Min,
  mute1Hour,
  mute3Hours,
  mute4Hours,
  mute8Hours,
  mute24Hours,
  mute3Days,
  muteForever,
  unmute,
  pinToggle,
  editGroup,
  block,
  closeDm,
  copyUserId,
  copyChannelId,
}

class _InviteToGuildAction {
  final String guildId;
  const _InviteToGuildAction(this.guildId);
}

class _DmBottomSheet extends StatelessWidget {
  final DmConversation convo;
  final bool isMuted;

  const _DmBottomSheet({required this.convo, required this.isMuted});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final hasUnread = convo.unreadCount > 0;

    void pop(Object action) => Navigator.of(context).pop(action);

    final groups = <Widget>[];

    // Group 1: Mark as Read
    if (hasUnread) {
      groups.add(
        FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.eye,
              label: 'Mark as Read',
              onTap: () => pop(_DmAction.markAsRead),
            ),
          ],
        ),
      );
    }

    // Group 2: Profile actions (1-on-1 DMs only)
    if (!convo.isGroup) {
      groups.add(
        FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.user,
              label: 'View Profile',
              onTap: () => pop(_DmAction.viewProfile),
            ),
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.phone,
              label: 'Voice Call',
              onTap: () => pop(_DmAction.voiceCall),
            ),
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.notePencil,
              label: 'Add Note',
              onTap: () => pop(_DmAction.addNote),
            ),
          ],
        ),
      );
    }

    // Group 3: Mute & Pin (+ Edit Group for group DMs)
    groups.add(
      FluxerMenuGroup(
        children: [
          if (convo.isGroup)
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.pencilSimple,
              label: 'Edit Group',
              onTap: () => pop(_DmAction.editGroup),
            ),
          FluxerBottomSheetSubmenuItem(
            label: isMuted ? 'Unmute Conversation' : 'Mute Conversation',
            onTap: () => _openMuteSheet(context),
          ),
          FluxerBottomSheetMenuItem(
            icon: PhosphorIconsFill.pushPin,
            label: 'Pin DM',
            onTap: () => pop(_DmAction.pinToggle),
          ),
        ],
      ),
    );

    // Group 4: Relationship actions (1-on-1 DMs only)
    if (!convo.isGroup) {
      groups.add(
        FluxerMenuGroup(
          children: [
            FluxerBottomSheetSubmenuItem(
              label: 'Invite to Community',
              onTap: () => _openInviteSheet(context),
            ),
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.prohibit,
              label: 'Block',
              isDanger: true,
              onTap: () => pop(_DmAction.block),
            ),
          ],
        ),
      );
    }

    // Group 5: Close / Leave (danger) + Group 6: Copy IDs
    groups
      ..add(
        FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsFill.xCircle,
              label: convo.isGroup ? 'Leave Group' : 'Close DM',
              isDanger: true,
              onTap: () => pop(_DmAction.closeDm),
            ),
          ],
        ),
      )
      ..add(
        FluxerMenuGroup(
          children: [
            if (!convo.isGroup)
              FluxerBottomSheetMenuItem(
                icon: PhosphorIconsRegular.snowflake,
                label: 'Copy User ID',
                onTap: () => pop(_DmAction.copyUserId),
              ),
            FluxerBottomSheetMenuItem(
              icon: PhosphorIconsRegular.snowflake,
              label: 'Copy Channel ID',
              onTap: () => pop(_DmAction.copyChannelId),
            ),
          ],
        ),
      );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: convo.isGroup ? 0.45 : 0.7,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              FluxerBottomSheetHeader(
                leading: convo.isGroup
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.backgroundSecondaryAlt,
                        ),
                        alignment: Alignment.center,
                        child: PhosphorIcon(
                          PhosphorIconsFill.usersThree,
                          size: 26,
                          color: context.colors.interactiveNormal,
                        ),
                      )
                    : FluxerAvatar.user(
                        fallbackText: convo.recipientName,
                        userId: convo.recipientId,
                        imageUrl: _dmAvatarUrl(convo),
                        status: convo.recipientStatus,
                        size: 48,
                      ),
                title: convo.displayName,
                subtitle: convo.isGroup
                    ? Text(
                        '${convo.memberCount} Members',
                        style: context.textStyles.timestamp.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [FluxerBottomSheetGroupColumn(children: groups)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMuteSheet(BuildContext context) {
    final nav = Navigator.of(context);
    unawaited(
      FluxerBottomSheet.show<_DmAction>(
        context,
        builder: (_, _) => _DmMuteSheet(isMuted: isMuted),
      ).then((result) {
        if (result != null) {
          nav.pop(result);
        }
      }),
    );
  }

  void _openInviteSheet(BuildContext context) {
    final nav = Navigator.of(context);
    unawaited(
      FluxerBottomSheet.show<_InviteToGuildAction>(
        context,
        builder: (_, _) => const _DmInviteSheet(),
      ).then((result) {
        if (result != null) {
          nav.pop(result);
        }
      }),
    );
  }
}

class _DmMuteSheet extends StatelessWidget {
  final bool isMuted;

  const _DmMuteSheet({required this.isMuted});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(_DmAction action) => Navigator.of(context).pop(action);

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              FluxerBottomSheetSubmenuHeader(
                title: isMuted ? 'Unmute Conversation' : 'Mute Conversation',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [
                    FluxerBottomSheetGroupColumn(
                      children: [
                        FluxerMenuGroup(
                          children: isMuted
                              ? [
                                  FluxerBottomSheetMenuItem(
                                    label: 'Unmute Conversation',
                                    onTap: () => pop(_DmAction.unmute),
                                  ),
                                ]
                              : [
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 15 minutes',
                                    onTap: () => pop(_DmAction.mute15Min),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 30 minutes',
                                    onTap: () => pop(_DmAction.mute30Min),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 1 hour',
                                    onTap: () => pop(_DmAction.mute1Hour),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 3 hours',
                                    onTap: () => pop(_DmAction.mute3Hours),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 4 hours',
                                    onTap: () => pop(_DmAction.mute4Hours),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 8 hours',
                                    onTap: () => pop(_DmAction.mute8Hours),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 24 hours',
                                    onTap: () => pop(_DmAction.mute24Hours),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'For 3 days',
                                    onTap: () => pop(_DmAction.mute3Days),
                                  ),
                                  FluxerBottomSheetMenuItem(
                                    label: 'Until I turn it back on',
                                    onTap: () => pop(_DmAction.muteForever),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DmInviteSheet extends ConsumerWidget {
  const _DmInviteSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = context.layout;
    final colors = context.colors;
    final guilds = ref.watch(guildListViewModelProvider).guilds;

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              FluxerBottomSheetSubmenuHeader(
                title: 'Invite to Community',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [
                    FluxerBottomSheetGroupColumn(
                      children: [
                        FluxerMenuGroup(
                          children: guilds.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No communities available',
                                      style: context.textStyles.username
                                          .copyWith(color: colors.textTertiary),
                                    ),
                                  ),
                                ]
                              : [
                                  for (final guild in guilds)
                                    FluxerBottomSheetMenuItem(
                                      label: guild.name,
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(_InviteToGuildAction(guild.id)),
                                    ),
                                ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
