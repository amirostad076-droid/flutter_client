import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/router/navigate_to_content.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DMList extends ConsumerWidget {
  const DMList({super.key});

  void personalNote(WidgetRef ref, BuildContext context) {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      navigateToContent(context, RoutePaths.dmChannel(userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dmViewModelProvider);
    final convos = vm.conversations;
    final location = GoRouterState.of(context).matchedLocation;
    final mePrefix = '${RoutePaths.me}/';
    final selectedId = location.startsWith(mePrefix)
        ? location.substring(mePrefix.length)
        : null;

    final isMobile = isMobileLayout(context);

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: context.colors.channelSidebarBackground,
      child: Column(
        children: [
          if (isMobile)
            _buildMobileHeader(context)
          else ...[
            _buildQuickSwitcher(context),
            Divider(color: context.colors.borderColor, height: 1),
            Builder(
              builder: (context) {
                final location = GoRouterState.of(context).matchedLocation;
                final userId = ref.watch(currentUserIdProvider);
                final isFriends = location == RoutePaths.me;
                final isNotes =
                    userId != null && location == RoutePaths.dmChannel(userId);

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
            child: vm.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.colors.brandPrimary,
                    ),
                  )
                : _buildConvoList(
                    context,
                    ref,
                    convos,
                    selectedId,
                    isMobile: isMobile,
                  ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMobileHeader(BuildContext context) => Container(
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
        IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 22,
            color: context.colors.interactiveNormal,
          ),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => context.go(RoutePaths.me),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ),
      ],
    ),
  );

  Widget _buildConvoList(
    BuildContext context,
    WidgetRef ref,
    List<DmConversation> convos,
    String? selectedId, {
    required bool isMobile,
  }) {
    final userId = ref.watch(currentUserIdProvider);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: convos.length + (isMobile ? 1 : 0),
      itemBuilder: (context, index) {
        if (isMobile && index == 0) {
          return _buildMobilePersonalNotes(context, ref, userId);
        }
        final convoIndex = isMobile ? index - 1 : index;
        final convo = convos[convoIndex];
        final isSelected = convo.id == selectedId;
        return _buildConvoTile(
          context,
          ref,
          convo: convo,
          isSelected: isSelected,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildMobilePersonalNotes(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        if (userId != null) {
          navigateToContent(context, RoutePaths.dmChannel(userId));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.backgroundModifierAccent,
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
    BuildContext context,
    WidgetRef ref, {
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: layout.radiusMd,
        hoverColor: context.colors.surfaceInteractiveHoverBg,
        onTap: () {
          navigateToContent(context, RoutePaths.dmChannel(c.id));
        },
        child: Container(
          height: tileHeight,
          margin: EdgeInsets.symmetric(horizontal: layout.s2, vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: layout.s2),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.surfaceInteractiveSelectedBg.withValues(
                    alpha: 0.35,
                  )
                : Colors.transparent,
            borderRadius: layout.radiusMd,
          ),
          child: Row(
            children: [
              if (c.isGroup)
                _buildGroupAvatar(context, size: avatarSize)
              else
                UserAvatar(
                  displayName: c.recipientName,
                  avatarUrl: _avatarUrl(c),
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
                            : c.unreadCount > 0
                            ? context.colors.textChat
                            : context.colors.textPrimaryMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.isGroup)
                      Text(
                        '${c.memberCount} Members',
                        style: TextStyle(
                          color: context.colors.textPrimaryMuted.withValues(
                            alpha: 0.85,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (c.lastMessage.isNotEmpty)
                      Text(
                        c.lastMessage,
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
              if (c.unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 20,
                    minWidth: 20,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: layout.s1),
                  decoration: BoxDecoration(
                    color: context.colors.statusDanger,
                    borderRadius: layout.radiusFull,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${c.unreadCount}',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(BuildContext context, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.backgroundModifierAccent,
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

  String? _avatarUrl(DmConversation convo) {
    final avatar = convo.recipientAvatar;
    if (avatar == null) {
      return null;
    }
    return 'https://fluxerusercontent.com'
        '/avatars/${convo.recipientId}/$avatar.png';
  }
}
