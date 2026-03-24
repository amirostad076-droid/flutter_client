import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/domain/stored_account.dart';
import 'package:fluxeron/features/ui/avatar/fluxer_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.account,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final StoredAccount account;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String? get _avatarUrl {
    final av = account.avatar;
    if (av == null) {
      return null;
    }
    return 'https://fluxermedia.com/avatars/${account.userId}/$av.png';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return GestureDetector(
      onTap: account.isValid ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: layout.s3,
          vertical: layout.s2,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: layout.radiusMd,
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            FluxerAvatar.user(
              imageUrl: _avatarUrl,
              fallbackText: account.displayName,
              size: 36,
              showStatus: false,
              userId: account.userId,
            ),
            SizedBox(width: layout.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.identifier,
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!account.isValid)
                    Text(
                      'Expired',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textDanger,
                      ),
                    )
                  else if (isCurrent)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsFill.checkCircle,
                          size: 12,
                          color: colors.textPositive,
                        ),
                        SizedBox(width: layout.s1),
                        Text(
                          'Active account',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textPositive,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showRemoveMenu(context),
              icon: Icon(
                PhosphorIconsBold.dotsThreeVertical,
                size: 18,
                color: colors.textTertiary,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: layout.s8,
                minHeight: layout.s8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMenu(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) {
      return;
    }

    final position = RelativeRect.fromRect(
      renderBox.localToGlobal(Offset.zero, ancestor: overlay) & renderBox.size,
      Offset.zero & overlay.size,
    );

    unawaited(
      showMenu<String>(
        context: context,
        position: position,
        items: [
          PopupMenuItem<String>(
            value: 'remove',
            child: Row(
              children: [
                Icon(
                  PhosphorIconsBold.userMinus,
                  size: 16,
                  color: colors.textDanger,
                ),
                SizedBox(width: layout.s2),
                Text(
                  'Remove account',
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textDanger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).then((value) {
        if (value == 'remove') {
          onRemove();
        }
      }),
    );
  }
}
