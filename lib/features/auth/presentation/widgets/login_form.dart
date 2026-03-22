import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginForm extends ConsumerWidget {
  final bool showBrowserLogin;

  const LoginForm({required this.showBrowserLogin, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations strings = FluxerLocalizations.of(context);
    final vm = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              strings.welcomeBack,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel(context, strings.email),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            autofillHints: [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.updateEmail,
            obscure: false,
          ),
          const SizedBox(height: 20),
          _buildLabel(context, strings.password),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            autofillHints: [AutofillHints.password],
            keyboardType: TextInputType.visiblePassword,
            onChanged: notifier.updatePassword,
            obscure: !vm.isPasswordVisible,
            suffixIcon: IconButton(
              icon: PhosphorIcon(
                vm.isPasswordVisible
                    ? PhosphorIconsFill.eyeSlash
                    : PhosphorIconsFill.eye,
                color: context.colors.textPrimaryMuted,
                size: 20,
              ),
              onPressed: notifier.togglePassword,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings.forgotPassword,
              style: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(
                  color: context.colors.textDanger,
                  fontSize: 14,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: vm.canLogin
                  ? () {
                      unawaited(
                        ref.read(loginViewModelProvider.notifier).login(),
                      );
                      TextInput.finishAutofillContext();
                    }
                  : null,
              child: vm.isLoggingIn
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.textPrimary,
                      ),
                    )
                  : Text(
                      strings.logIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOrDivider(context, strings),
          const SizedBox(height: 16),
          _buildSecondaryButton(
            context,
            icon: PhosphorIconsFill.key,
            label: strings.logInWithPasskey,
            onTap: () {},
          ),
          if (showBrowserLogin) ...[
            const SizedBox(height: 8),
            _buildSecondaryButton(
              context,
              icon: PhosphorIconsFill.monitor,
              label: strings.logInViaBrowser,
              onTap: () {},
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                strings.needAccountPrompt,
                style: TextStyle(
                  color: context.colors.textPrimaryMuted,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  strings.register,
                  style: TextStyle(
                    color: context.colors.textLink,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      color: context.colors.textPrimaryMuted,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildTextField(
    BuildContext context, {
    required Iterable<String>? autofillHints,
    required TextInputType keyboardType,
    required ValueChanged<String> onChanged,
    required bool obscure,
    Widget? suffixIcon,
  }) => TextField(
    autofillHints: autofillHints,
    onChanged: onChanged,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: TextStyle(color: context.colors.textChat, fontSize: 16),
    decoration: InputDecoration(suffixIcon: suffixIcon),
  );

  Widget _buildOrDivider(BuildContext context, FluxerLocalizations strings) =>
      Row(
        children: [
          Expanded(child: Divider(color: context.colors.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              strings.orDivider,
              style: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.colors.borderColor)),
        ],
      );

  Widget _buildSecondaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    height: 44,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: PhosphorIcon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.backgroundTertiary,
        foregroundColor: context.colors.textChat,
      ),
    ),
  );
}
