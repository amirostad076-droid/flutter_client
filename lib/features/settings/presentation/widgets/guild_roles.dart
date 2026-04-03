import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuildRoles extends StatelessWidget {
  final List<MemberRole> roles;
  final ScrollController? scrollController;

  const GuildRoles({required this.roles, this.scrollController, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Roles', style: context.textStyles.heading)),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const PhosphorIcon(PhosphorIconsFill.plus, size: 16),
              label: const Text('Create Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brandPrimary,
                foregroundColor: context.colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use roles to group your server '
          'members and assign permissions.',
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text('ROLE', style: context.textStyles.categoryName),
            ),
            Expanded(
              child: Text('MEMBERS', style: context.textStyles.categoryName),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: context.colors.borderColor),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return _buildRoleRow(context, role);
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildRoleRow(BuildContext context, MemberRole role) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.borderColor)),
    ),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(role.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            role.name,
            style: TextStyle(
              color: Color(role.color),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '--',
            style: TextStyle(
              color: context.colors.textPrimaryMuted,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsFill.pencil, size: 16),
          color: context.colors.interactiveNormal,
          onPressed: () {},
        ),
      ],
    ),
  );
}
