import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/members/domain/member.dart';

class ServerRoles extends StatelessWidget {
  final List<MemberRole> roles;

  const ServerRoles({required this.roles, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Roles', style: FluxerTextStyles.heading)),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const PhosphorIcon(PhosphorIconsFill.plus, size: 16),
              label: const Text('Create Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FluxerColors.blurple,
                foregroundColor: FluxerColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Use roles to group your server '
          'members and assign permissions.',
          style: TextStyle(color: FluxerColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text('ROLE', style: FluxerTextStyles.categoryName),
            ),
            Expanded(
              child: Text('MEMBERS', style: FluxerTextStyles.categoryName),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: FluxerColors.divider),
        Expanded(
          child: ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return _buildRoleRow(role);
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildRoleRow(MemberRole role) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: FluxerColors.divider)),
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
        const Expanded(
          child: Text(
            '--',
            style: TextStyle(color: FluxerColors.textMuted, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsFill.pencil, size: 16),
          color: FluxerColors.interactiveNormal,
          onPressed: () {},
        ),
      ],
    ),
  );
}
