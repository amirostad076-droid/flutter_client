import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:fluxeron/features/ui/checkbox/fluxer_checkbox.dart';
import 'package:fluxeron/features/ui/input/fluxer_input.dart';
import 'package:fluxeron/features/ui/select/fluxer_select.dart';
import 'package:fluxeron/features/ui/text_link/fluxer_text_link.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _displayNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  int? _birthMonth;
  int? _birthDay;
  int? _birthYear;
  bool _consent = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _displayNameFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _emailRegex.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _birthMonth != null &&
        _birthDay != null &&
        _birthYear != null &&
        _consent;
  }

  String? get _dateOfBirth {
    if (_birthYear == null || _birthMonth == null || _birthDay == null) {
      return null;
    }
    final y = _birthYear.toString().padLeft(4, '0');
    final m = _birthMonth.toString().padLeft(2, '0');
    final d = _birthDay.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _submit() {
    final l10n = FluxerLocalizations.of(context);
    final notifier = ref.read(loginViewModelProvider.notifier);

    if (_passwordController.text != _confirmController.text) {
      notifier.setError(l10n.resetPasswordMismatch);
      return;
    }

    final dob = _dateOfBirth;
    if (dob == null) {
      return;
    }

    unawaited(
      notifier.submitRegister(
        email: _emailController.text,
        password: _passwordController.text,
        dateOfBirth: dob,
        username: _usernameController.text,
        displayName: _displayNameController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);

    return AbsorbPointer(
      absorbing: vm.isLoggingIn,
      child: AnimatedOpacity(
        opacity: vm.isLoggingIn ? 0.6 : 1.0,
        duration: context.motion.fast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.registerTitle,
              style: textStyles.heading.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s6),

            // Email
            FluxerInput(
              controller: _emailController,
              label: l10n.email,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _displayNameFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
              errorText: vm.fieldErrors['email'],
            ),
            SizedBox(height: layout.s4),

            // Display name
            FluxerInput(
              controller: _displayNameController,
              focusNode: _displayNameFocus,
              label: l10n.registerDisplayName,
              hint: l10n.registerDisplayNameHint,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _usernameFocus.requestFocus(),
              errorText: vm.fieldErrors['global_name'],
            ),
            SizedBox(height: layout.s4),

            // Username
            FluxerInput(
              controller: _usernameController,
              focusNode: _usernameFocus,
              label: l10n.registerUsername,
              hint: l10n.registerUsernameHint,
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              errorText: vm.fieldErrors['username'],
            ),
            SizedBox(height: layout.s4),

            // Password
            FluxerInput(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: l10n.password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _confirmFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
              errorText: vm.fieldErrors['password'],
            ),
            SizedBox(height: layout.s4),

            // Confirm password
            FluxerInput(
              controller: _confirmController,
              focusNode: _confirmFocus,
              label: l10n.resetPasswordConfirm,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: layout.s4),

            // Date of birth
            Text(
              l10n.registerDateOfBirth,
              style: textStyles.label.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: layout.s1_5),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FluxerSelect<int>(
                    hint: l10n.registerMonth,
                    value: _birthMonth,
                    onChanged: (v) => setState(() => _birthMonth = v),
                    items: List.generate(
                      12,
                      (i) => FluxerSelectItem(
                        value: i + 1,
                        label: _monthName(i + 1, l10n),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: layout.s2),
                Expanded(
                  child: FluxerSelect<int>(
                    hint: l10n.registerDay,
                    value: _birthDay,
                    onChanged: (v) => setState(() => _birthDay = v),
                    items: List.generate(
                      31,
                      (i) => FluxerSelectItem(value: i + 1, label: '${i + 1}'),
                    ),
                  ),
                ),
                SizedBox(width: layout.s2),
                Expanded(
                  child: FluxerSelect<int>(
                    hint: l10n.registerYear,
                    value: _birthYear,
                    onChanged: (v) => setState(() => _birthYear = v),
                    items: List.generate(100, (i) {
                      final year = DateTime.now().year - 13 - i;
                      return FluxerSelectItem(value: year, label: '$year');
                    }),
                  ),
                ),
              ],
            ),
            if (vm.fieldErrors['date_of_birth'] != null) ...[
              SizedBox(height: layout.s1),
              Text(
                vm.fieldErrors['date_of_birth']!,
                style: textStyles.bodySmall.copyWith(color: colors.textDanger),
              ),
            ],
            SizedBox(height: layout.s4),

            // Terms consent
            FluxerCheckbox(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              label: l10n.registerConsent,
            ),
            SizedBox(height: layout.s6),

            // Error message
            if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) ...[
              Text(
                vm.errorMessage!,
                style: textStyles.bodySmall.copyWith(color: colors.textDanger),
              ),
              SizedBox(height: layout.s2),
            ],

            // Submit
            FluxerButton.primary(
              onPressed: _isFormValid && !vm.isLoggingIn ? _submit : null,
              label: l10n.registerSubmit,
              isLoading: vm.isLoggingIn,
            ),
            SizedBox(height: layout.s5),

            // Back to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.registerHaveAccount,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                FluxerTextLink(
                  text: l10n.logIn,
                  onTap: widget.onBack,
                  style: textStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month, FluxerLocalizations l10n) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
