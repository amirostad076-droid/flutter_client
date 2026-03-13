import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';

class UserProfile extends StatelessWidget {
  final UserSettingsViewState userState;

  const UserProfile({required this.userState, super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Account', style: FluxerTextStyles.heading),
        const SizedBox(height: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: FluxerColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: FluxerColors.blurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -38),
                      child: Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FluxerColors.backgroundSecondary,
                                width: 6,
                              ),
                            ),
                            child: UserAvatar(
                              displayName: userState.displayName,
                              avatarUrl: userState.avatarUrl,
                              avatarColor: userState.avatarColor,
                              size: 80,
                              showStatus: false,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FluxerColors.blurple,
                                foregroundColor: FluxerColors.white,
                              ),
                              child: const Text(
                                'Edit User Profile',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FluxerColors.backgroundTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileField(
                              'DISPLAY NAME',
                              userState.displayName,
                            ),
                            const SizedBox(height: 16),
                            _buildProfileField(
                              'USERNAME',
                              '${userState.username}'
                                  '#${userState.discriminator}',
                            ),
                            const SizedBox(height: 16),
                            _buildProfileField('EMAIL', 'user@example.com'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Divider(color: FluxerColors.divider),
        const SizedBox(height: 16),
        Text(
          'PASSWORD AND AUTHENTICATION',
          style: FluxerTextStyles.categoryName,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: FluxerColors.blurple,
            foregroundColor: FluxerColors.white,
          ),
          child: const Text('Change Password'),
        ),
      ],
    ),
  );

  Widget _buildProfileField(String label, String value) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FluxerColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: FluxerColors.textNormal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: FluxerColors.textNormal,
          side: const BorderSide(color: FluxerColors.interactiveMuted),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: const Text('Edit', style: TextStyle(fontSize: 13)),
      ),
    ],
  );
}
