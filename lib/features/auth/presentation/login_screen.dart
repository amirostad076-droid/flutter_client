import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/auth/presentation/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
          child: const LoginForm(),
        ),
      ),
    );
  }
}
