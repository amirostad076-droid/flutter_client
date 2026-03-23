import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:fluxeron/features/ui/input/fluxer_input.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginForm extends ConsumerStatefulWidget {
  final bool showBrowserLogin;

  const LoginForm({required this.showBrowserLogin, super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitLogin() {
    final notifier = ref.read(loginViewModelProvider.notifier);
    if (ref.read(loginViewModelProvider).canLogin) {
      unawaited(notifier.login());
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: layout.s8),
              FluxerInput(
                label: strings.email,
                autofillHints: const [AutofillHints.email],
                onChanged: notifier.updateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                errorText: vm.fieldErrors['email'],
              ),
              SizedBox(height: layout.s6),
              FluxerInput(
                label: strings.password,
                focusNode: _passwordFocusNode,
                autofillHints: const [AutofillHints.password],
                onChanged: notifier.updatePassword,
                obscureText: !vm.isPasswordVisible,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submitLogin(),
                errorText: vm.fieldErrors['password'],
                suffixIcon: PhosphorIcon(
                  vm.isPasswordVisible
                      ? PhosphorIconsFill.eyeSlash
                      : PhosphorIconsFill.eye,
                  color: context.colors.textPrimaryMuted,
                  size: 20,
                ),
                onSuffixTap: notifier.togglePassword,
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
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
              SizedBox(height: layout.s6),
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
              FluxerButton.primary(
                onPressed: vm.canLogin ? _submitLogin : null,
                label: strings.logIn,
                isLoading: vm.isLoggingIn,
              ),
              SizedBox(height: layout.s6),
              _buildOrDivider(context, strings),
              SizedBox(height: layout.s6),
              FluxerButton.secondary(
                onPressed: () {},
                icon: PhosphorIconsFill.key,
                label: strings.logInWithPasskey,
              ),
              if (widget.showBrowserLogin) ...[
                SizedBox(height: layout.s2),
                FluxerButton.secondary(
                  onPressed: () {},
                  icon: PhosphorIconsFill.monitor,
                  label: strings.logInViaBrowser,
                ),
              ],
              SizedBox(height: layout.s5),
              Row(
                children: [
                  Text(
                    strings.needAccountPrompt,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
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

  Widget _buildOrDivider(BuildContext context, FluxerLocalizations strings) =>
      Row(
        children: [
          Expanded(child: Divider(color: context.colors.borderColor)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.layout.s3),
            child: Text(
              strings.orDivider,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.colors.borderColor)),
        ],
      );
}
