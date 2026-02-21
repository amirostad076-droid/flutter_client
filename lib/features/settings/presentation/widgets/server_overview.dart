import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/servers/domain/server.dart';

class ServerOverview extends StatelessWidget {
  final Server server;

  const ServerOverview({required this.server, super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server Overview', style: FluxerTextStyles.heading),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: FluxerColors.backgroundAccent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  server.name.isNotEmpty ? server.name[0] : '?',
                  style: const TextStyle(
                    color: FluxerColors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We recommend an image of '
                    'at least 512x512 for '
                    'the server.',
                    style: TextStyle(
                      color: FluxerColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FluxerColors.textNormal,
                      side: const BorderSide(
                        color: FluxerColors.interactiveMuted,
                      ),
                    ),
                    child: const Text('Upload Image'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSettingsField('SERVER NAME', server.name),
        const SizedBox(height: 24),
        _buildSettingsField(
          'DESCRIPTION',
          server.description ?? 'No description set',
        ),
        const SizedBox(height: 24),
        _buildInfoRow('Members', '${server.memberCount}'),
        const SizedBox(height: 8),
        _buildInfoRow('Online', '${server.onlineCount}'),
      ],
    ),
  );

  Widget _buildSettingsField(String label, String value) => Column(
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
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: FluxerColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          value,
          style: const TextStyle(color: FluxerColors.textNormal, fontSize: 16),
        ),
      ),
    ],
  );

  Widget _buildInfoRow(String label, String value) => Row(
    children: [
      Text(
        '$label: ',
        style: const TextStyle(color: FluxerColors.textMuted, fontSize: 14),
      ),
      Text(
        value,
        style: const TextStyle(
          color: FluxerColors.textNormal,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
