import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginForm extends ConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Welcome back!',
          style: TextStyle(
            color: FluxerColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We're so excited to see you again!",
          style: TextStyle(color: FluxerColors.textMuted, fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildLabel('EMAIL OR PHONE NUMBER'),
        const SizedBox(height: 8),
        _buildTextField(onChanged: notifier.updateEmail, obscure: false),
        const SizedBox(height: 20),
        _buildLabel('PASSWORD'),
        const SizedBox(height: 8),
        _buildTextField(
          onChanged: notifier.updatePassword,
          obscure: !vm.isPasswordVisible,
          suffixIcon: IconButton(
            icon: PhosphorIcon(
              vm.isPasswordVisible
                  ? PhosphorIconsFill.eyeSlash
                  : PhosphorIconsFill.eye,
              color: FluxerColors.textMuted,
              size: 20,
            ),
            onPressed: notifier.togglePassword,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot your password?',
              style: TextStyle(color: FluxerColors.textLink, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              vm.errorMessage!,
              style: const TextStyle(
                color: FluxerColors.textDanger,
                fontSize: 14,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: vm.canLogin
                ? () => ref.read(loginViewModelProvider.notifier).login()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: FluxerColors.blurple,
              foregroundColor: FluxerColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              disabledBackgroundColor: FluxerColors.blurple.withValues(
                alpha: 0.5,
              ),
            ),
            child: vm.isLoggingIn
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FluxerColors.white,
                    ),
                  )
                : const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Need an account? ',
              style: TextStyle(color: FluxerColors.textMuted, fontSize: 14),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Register',
                style: TextStyle(color: FluxerColors.textLink, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: FluxerColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildTextField({
    required ValueChanged<String> onChanged,
    required bool obscure,
    Widget? suffixIcon,
  }) => TextField(
    onChanged: onChanged,
    obscureText: obscure,
    style: const TextStyle(color: FluxerColors.textNormal, fontSize: 16),
    decoration: InputDecoration(
      filled: true,
      fillColor: FluxerColors.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      suffixIcon: suffixIcon,
    ),
  );
}
