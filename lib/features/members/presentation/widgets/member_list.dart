import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/members/domain/member.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kPanelWidth = 264.0;

class MemberList extends ConsumerWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberState =
        ref.watch(memberListViewModelProvider);
    final groups = memberState.roleGroups;

    if (memberState.isLoading && groups.isEmpty) {
      return const _MemberPanel(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (memberState.errorMessage != null &&
        groups.isEmpty) {
      return _MemberPanel(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.layout.s6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.users,
                  size: context.layout.s12,
                  color: context
                      .colors.textPrimaryMuted,
                ),
                SizedBox(height: context.layout.s3),
                Text(
                  'Member List Unavailable',
                  style: context.textStyles.heading
                      .copyWith(
                    color: context.colors.textChat,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.layout.s2),
                Text(
                  'Member lists are temporarily'
                  '\nunavailable in this '
                  'community',
                  style: context
                      .textStyles.bodyMedium
                      .copyWith(
                    color: context
                        .colors.textPrimaryMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _MemberPanel(
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 10,
          left: context.layout.s2,
          right: context.layout.s2,
          bottom: context.layout.s4,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(context, group),
              ...group.members.map(
                (m) => _MemberTile(member: m),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    RoleGroup group,
  ) {
    final layout = context.layout;
    final count = group.members.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.s2,
        layout.s3,
        layout.s2,
        layout.s1,
      ),
      child: Text(
        '${group.displayName} \u2014 $count',
        style: context.textStyles.categoryName
            .copyWith(
          color: group.role != null
              ? Color(group.role!.color)
              : context.colors.textPrimaryMuted,
        ),
      ),
    );
  }
}

class _MemberPanel extends StatelessWidget {
  final Widget child;

  const _MemberPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kPanelWidth,
      decoration: BoxDecoration(
        color: context.colors.memberListBackground,
        border: Border(
          left: BorderSide(
            color: context.colors.borderColor,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _MemberTile extends StatefulWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  State<_MemberTile> createState() =>
      _MemberTileState();
}

class _MemberTileState extends State<_MemberTile> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final layout = context.layout;
    final isOffline = member.status == 'offline';

    return MouseRegion(
      onEnter: (_) =>
          setState(() => _isHovered = true),
      onExit: (_) =>
          setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Opacity(
          opacity: isOffline ? 0.3 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 1,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: layout.s2,
                vertical: layout.s1,
              ),
              decoration: BoxDecoration(
                color: _isHovered
                    ? context.colors
                        .backgroundModifierHover
                    : Colors.transparent,
                borderRadius: layout.radiusMd,
              ),
              child: Row(
                children: [
                  UserAvatar(
                    displayName:
                        member.displayName,
                    avatarUrl: member.avatarUrl,
                    avatarColor: member.avatarColor,
                    roleColor: member.roleColor,
                    status: member.status,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.displayName,
                                style: context
                                    .textStyles.label
                                    .copyWith(
                                  color: member
                                              .roleColor !=
                                          null
                                      ? Color(
                                          member
                                              .roleColor!,
                                        )
                                      : context
                                          .colors
                                          .textChat,
                                ),
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                            if (member.isBot) ...[
                              SizedBox(
                                width: layout.s1,
                              ),
                              _buildBotBadge(
                                context,
                              ),
                            ],
                          ],
                        ),
                        if (member.customStatus !=
                            null)
                          Text(
                            member.customStatus!,
                            style: TextStyle(
                              color: context.colors
                                  .textPrimaryMuted,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                            overflow: TextOverflow
                                .ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotBadge(BuildContext context) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.layout.s1,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: context.colors.brandPrimary,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          'BOT',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
