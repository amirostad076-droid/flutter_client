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
    final strings = FluxerLocalizations.of(context);
    final vm = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);
    final layout = context.layout;

    return AbsorbPointer(
      absorbing: vm.isLoggingIn,
      child: AnimatedOpacity(
        opacity: vm.isLoggingIn ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  strings.welcomeBack,
                  style: context.textStyles.heading,
                ),
              ),
              SizedBox(height: layout.s6),
              _buildLabel(context, strings.email),
              SizedBox(height: layout.s2),
              TextField(
                autofillHints: const [AutofillHints.email],
                onChanged: notifier.updateEmail,
                keyboardType: TextInputType.emailAddress,
                style: context.textStyles.inputText,
              ),
              SizedBox(height: layout.s5),
              _buildLabel(context, strings.password),
              SizedBox(height: layout.s2),
              TextField(
                autofillHints: const [AutofillHints.password],
                onChanged: notifier.updatePassword,
                obscureText: !vm.isPasswordVisible,
                keyboardType: TextInputType.visiblePassword,
                style: context.textStyles.inputText,
                decoration: InputDecoration(
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
              ),
              SizedBox(height: layout.s1),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  strings.forgotPassword,
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textPrimaryMuted,
                  ),
                ),
              ),
              SizedBox(height: layout.s5),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: vm.errorMessage != null && vm.errorMessage!.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(bottom: layout.s2),
                        child: Text(
                          vm.errorMessage!,
                          style: context.textStyles.bodySmall.copyWith(
                            color: context.colors.textDanger,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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
                            color: context.colors.buttonPrimaryText,
                          ),
                        )
                      : Text(strings.logIn),
                ),
              ),
              SizedBox(height: layout.s4),
              _buildOrDivider(context, strings),
              SizedBox(height: layout.s4),
              _buildSecondaryButton(
                context,
                icon: PhosphorIconsFill.key,
                label: strings.logInWithPasskey,
                onTap: () {},
              ),
              if (showBrowserLogin) ...[
                SizedBox(height: layout.s2),
                _buildSecondaryButton(
                  context,
                  icon: PhosphorIconsFill.monitor,
                  label: strings.logInViaBrowser,
                  onTap: () {},
                ),
              ],
              SizedBox(height: layout.s4),
              Row(
                children: [
                  Text(
                    strings.needAccountPrompt,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textPrimaryMuted,
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
                      style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.textLink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) => Text(
    text,
    style: context.textStyles.label.copyWith(
      color: context.colors.textPrimaryMuted,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildOrDivider(BuildContext context, FluxerLocalizations strings) =>
      Row(
        children: [
          Expanded(child: Divider(color: context.colors.borderColor)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.layout.s3),
            child: Text(
              strings.orDivider,
              style: context.textStyles.bodySmall.copyWith(
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
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.backgroundTertiary,
        foregroundColor: context.colors.textChat,
      ),
    ),
  );
}
