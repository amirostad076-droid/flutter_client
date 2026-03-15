import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/members/domain/member.dart';
import 'package:fluxeron/features/members/providers/member_list_view_model.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberList extends ConsumerWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberState =
        ref.watch(memberListViewModelProvider);
    final groups = memberState.roleGroups;

    if (memberState.isLoading && groups.isEmpty) {
      return Container(
        width: 240,
        decoration: BoxDecoration(
          color:
              context.colors.memberListBackground,
          border: Border(
            left: BorderSide(
              color: context.colors.borderColor,
            ),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (memberState.errorMessage != null &&
        groups.isEmpty) {
      return Container(
        width: 240,
        decoration: BoxDecoration(
          color:
              context.colors.memberListBackground,
          border: Border(
            left: BorderSide(
              color: context.colors.borderColor,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.users,
                  size: 48,
                  color: context
                      .colors.textPrimaryMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Member List Unavailable',
                  style: TextStyle(
                    color: context.colors.textChat,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Member lists are temporarily'
                  '\nunavailable in this '
                  'community',
                  style: TextStyle(
                    color: context
                        .colors.textPrimaryMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: context.colors.memberListBackground,
        border: Border(
          left: BorderSide(
            color: context.colors.borderColor,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  4,
                ),
                child: Text(
                  group.displayName.toUpperCase(),
                  style: context
                      .textStyles.categoryName
                      .copyWith(
                    color: group.role != null
                        ? Color(group.role!.color)
                        : context.colors
                            .textPrimaryMuted,
                  ),
                ),
              ),
              ...group.members.map(
                (m) => _buildMemberTile(context, m),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    Member member,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 1,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(4),
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
                  const SizedBox(width: 8),
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
                                style: TextStyle(
                                  color: member
                                              .status ==
                                          'offline'
                                      ? context
                                          .colors
                                          .textPrimaryMuted
                                      : member.roleColor !=
                                              null
                                          ? Color(
                                              member
                                                  .roleColor!,
                                            )
                                          : context
                                              .colors
                                              .textChat,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                            if (member.isBot) ...[
                              const SizedBox(
                                width: 4,
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
                              fontSize: 12,
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
      );

  Widget _buildBotBadge(BuildContext context) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
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
