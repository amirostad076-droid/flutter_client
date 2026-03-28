import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';

class UserProfile extends StatelessWidget {
  final UserSettingsViewState userState;

  const UserProfile({required this.userState, super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Account', style: context.textStyles.heading),
        const SizedBox(height: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: context.colors.brandPrimary,
                  borderRadius: const BorderRadius.only(
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
                                color: context.colors.backgroundSecondary,
                                width: 6,
                              ),
                            ),
                            child: FluxerAvatar.user(
                              fallbackText: userState.displayName,
                              userId: userState.userId,
                              imageUrl: userState.avatarUrl,
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
                                backgroundColor: context.colors.brandPrimary,
                                foregroundColor: context.colors.textPrimary,
                              ),
                              child: const Text(
                                'Edit User '
                                'Profile',
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
                          color: context.colors.backgroundTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileField(
                              context,
                              'DISPLAY NAME',
                              userState.displayName,
                            ),
                            const SizedBox(height: 16),
                            _buildProfileField(
                              context,
                              'USERNAME',
                              '${userState.username}'
                                  '#${userState.discriminator}',
                            ),
                            const SizedBox(height: 16),
                            _buildProfileField(
                              context,
                              'EMAIL',
                              'user@example'
                                  '.com',
                            ),
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
        Divider(color: context.colors.borderColor),
        const SizedBox(height: 16),
        Text(
          'PASSWORD AND AUTHENTICATION',
          style: context.textStyles.categoryName,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.brandPrimary,
            foregroundColor: context.colors.textPrimary,
          ),
          child: const Text('Change Password'),
        ),
      ],
    ),
  );

  Widget _buildProfileField(BuildContext context, String label, String value) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textPrimaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: context.colors.textChat,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.textChat,
              side: BorderSide(color: context.colors.interactiveMuted),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Edit', style: TextStyle(fontSize: 13)),
          ),
        ],
      );
}
