import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';

class MfaScreen extends StatelessWidget {
  const MfaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxerColors.blurple,
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: FluxerColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  color: FluxerColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter the code from your authenticator app.',
                style: TextStyle(color: FluxerColors.textMuted, fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                'MFA is not yet supported in this client.',
                style: TextStyle(color: FluxerColors.textDanger, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
