import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserProfileActionCardRow extends StatelessWidget {
  const UserProfileActionCardRow({
    required this.isCurrentUser,
    required this.isBlocked,
    required this.username,
    required this.onMessage,
    required this.onEditProfile,
    super.key,
  });

  final bool isCurrentUser;
  final bool isBlocked;
  final String username;
  final Future<void> Function() onMessage;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    if (isCurrentUser) {
      return SizedBox(
        width: double.infinity,
        child: FluxerButton.primary(
          label: l10n.userProfileEditProfile,
          icon: PhosphorIconsFill.pencil,
          onPressed: onEditProfile,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _MessageCard(
            label: isBlocked ? l10n.userProfileOpenDm : l10n.userProfileMessage,
            onTap: onMessage,
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    return FluxerTappable(
      onTap: () async {
        await onTap();
      },
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundSecondaryAlt,
          borderRadius: layout.radiusXl,
        ),
        child: Padding(
          padding: EdgeInsets.all(layout.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  PhosphorIconsFill.chatTeardrop,
                  size: 24,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.ibmPlexSans(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
