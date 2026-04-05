import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const int _kMinUsernameLength = 2;
const int _kMaxUsernameLength = 32;
final RegExp _kUsernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');

Future<void> showFluxerTagChangeSheet(BuildContext context) {
  final canDismissNotifier = ValueNotifier<bool>(true);
  return FluxerBottomSheet.show<void>(
    context,
    title: 'Change FluxerTag',
    canDismissNotifier: canDismissNotifier,
    builder: (sheetContext, close) => _FluxerTagChangeContent(
      canDismissNotifier: canDismissNotifier,
      onDone: close,
    ),
  );
}

class _FluxerTagChangeContent extends ConsumerStatefulWidget {
  const _FluxerTagChangeContent({
    required this.canDismissNotifier,
    required this.onDone,
  });

  final ValueNotifier<bool> canDismissNotifier;
  final VoidCallback onDone;

  @override
  ConsumerState<_FluxerTagChangeContent> createState() =>
      _FluxerTagChangeContentState();
}

class _FluxerTagChangeContentState
    extends ConsumerState<_FluxerTagChangeContent> {
  late final TextEditingController _usernameController;
  late final TextEditingController _discriminatorController;
  late String _originalUsername;
  late String _originalDiscriminator;

  var _isSubmitting = false;
  String? _error;
  var _confirmedReroll = false;
  var _confirmedTemporary = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(userSettingsViewModelProvider);
    _originalUsername = state.username;
    _originalDiscriminator = state.discriminator;

    _usernameController = TextEditingController(text: _originalUsername);
    _discriminatorController = TextEditingController(
      text: _originalDiscriminator,
    );

    _usernameController.addListener(_onFormChanged);
    _discriminatorController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _discriminatorController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final isDirty = _usernameController.text != _originalUsername ||
        _discriminatorController.text != _originalDiscriminator;
    widget.canDismissNotifier.value = !isDirty;
    setState(() {
      _confirmedReroll = false;
      _confirmedTemporary = false;
      _error = null;
    });
  }

  bool get _isValidLength {
    final trimmed = _usernameController.text.trim();
    return trimmed.length >= _kMinUsernameLength &&
        trimmed.length <= _kMaxUsernameLength;
  }

  bool get _isValidChars {
    final trimmed = _usernameController.text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return _kUsernamePattern.hasMatch(trimmed);
  }

  bool get _isValidDiscriminator {
    final state = ref.read(userSettingsViewModelProvider);
    final text = _discriminatorController.text.trim();
    if (text.length != 4) {
      return false;
    }
    final value = int.tryParse(text);
    if (value == null) {
      return false;
    }
    if (state.hasLifetimePremium) {
      return value >= 0 && value <= 9999;
    }
    return value >= 1 && value <= 9999;
  }

  bool get _isFormValid =>
      _isValidLength && _isValidChars && _isValidDiscriminator;

  bool get _isDirty {
    return _usernameController.text != _originalUsername ||
        _discriminatorController.text != _originalDiscriminator;
  }

  Future<void> _submit() async {
    if (!_isFormValid || _isSubmitting) {
      return;
    }

    final username = _usernameController.text.trim();
    final discriminator =
        _discriminatorController.text.trim().padLeft(4, '0');
    final state = ref.read(userSettingsViewModelProvider);

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (!state.isPremium && !_confirmedReroll) {
        final checkResponse = await ref
            .read(fluxerClientProvider)
            .users
            .checkUsernameTagAvailability(
              username: username,
              discriminator: discriminator,
            );

        if (!mounted) {
          return;
        }

        if (checkResponse.taken) {
          setState(() => _isSubmitting = false);

          final confirmed = await _showRerollConfirmation(
            username: username,
            discriminator: discriminator,
          );

          if (!mounted) {
            return;
          }
          if (confirmed != true) {
            return;
          }
          _confirmedReroll = true;
          unawaited(_submit());
          return;
        }
      }

      if (state.isPremium &&
          !state.hasLifetimePremium &&
          _discriminatorController.text.trim() != _originalDiscriminator &&
          !_confirmedTemporary) {
        setState(() => _isSubmitting = false);

        final confirmed = await _showTemporaryTagWarning();

        if (!mounted) {
          return;
        }
        if (confirmed != true) {
          return;
        }
        _confirmedTemporary = true;
        unawaited(_submit());
        return;
      }

      await ref.read(fluxerClientProvider).users.updateCurrentUser(
        body: UserUpdateWithVerificationRequest(
          username: username,
          discriminator: discriminator,
        ),
      );

      if (!mounted) {
        return;
      }

      ref.read(toastProvider.notifier).show(
        const FluxerToast(
          message: 'FluxerTag updated',
          variant: FluxerToastVariant.success,
        ),
      );
      widget.onDone();
    } on Exception catch (e) {
      talker.error('Failed to update FluxerTag', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to update FluxerTag. Please try again.';
      });
    }
  }

  Future<bool?> _showRerollConfirmation({
    required String username,
    required String discriminator,
  }) {
    return FluxerBottomSheet.show<bool>(
      context,
      title: 'FluxerTag Already Taken',
      builder: (sheetContext, _) => Padding(
        padding: EdgeInsets.all(sheetContext.layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The FluxerTag $username#$discriminator is already taken. '
              'Continuing will reroll your discriminator automatically.',
              style: sheetContext.textStyles.bodyMedium.copyWith(
                color: sheetContext.colors.textSecondary,
              ),
            ),
            SizedBox(height: sheetContext.layout.s4),
            FluxerButton.primary(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              label: 'Continue',
            ),
            SizedBox(height: sheetContext.layout.s2),
            FluxerButton.secondary(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              label: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showTemporaryTagWarning() {
    return FluxerBottomSheet.show<bool>(
      context,
      title: 'Custom Tag Is Temporary',
      builder: (sheetContext, _) => Padding(
        padding: EdgeInsets.all(sheetContext.layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your custom 4-digit tag is only available while your '
              'Plutonium subscription is active. When your subscription '
              'expires, your tag will revert to a randomly assigned number '
              'after a 3-day grace period.',
              style: sheetContext.textStyles.bodyMedium.copyWith(
                color: sheetContext.colors.textSecondary,
              ),
            ),
            SizedBox(height: sheetContext.layout.s4),
            FluxerButton.primary(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              label: 'I Understand, Continue',
            ),
            SizedBox(height: sheetContext.layout.s2),
            FluxerButton.secondary(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              label: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValidationRule(
          label: 'Between 2 and 32 characters',
          isValid: _isValidLength,
        ),
        _ValidationRule(
          label: 'Only letters, numbers, and underscores',
          isValid: _isValidChars,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;

    final showValidationRules = _usernameController.text.isNotEmpty;

    Widget? discriminatorSuffix;
    if (!state.isPremium) {
      discriminatorSuffix = FluxerTooltip(
        message: 'Customize your 4-digit tag with Plutonium',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s2),
          child: PhosphorIcon(
            PhosphorIconsFill.crown,
            size: 18,
            color: colors.brandPrimary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerInput(
              controller: _usernameController,
              label: 'Username',
              hint: 'Marty_McFly',
              maxLength: _kMaxUsernameLength,
              autofocus: true,
            ),
            SizedBox(height: layout.s2),
            if (showValidationRules) _buildValidationRules(),
            SizedBox(height: layout.s4),
            FluxerInput(
              controller: _discriminatorController,
              label: 'Discriminator',
              hint: '0000',
              maxLength: 4,
              enabled: state.isPremium,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffixIcon: discriminatorSuffix,
            ),
            if (_error != null) ...[
              SizedBox(height: layout.s2),
              Text(
                _error!,
                style: textStyles.bodySmall.copyWith(
                  color: colors.accentDanger,
                ),
              ),
            ],
            SizedBox(height: layout.s4),
            FluxerButton.primary(
              onPressed:
                  _isFormValid && _isDirty && !_isSubmitting ? _submit : null,
              label: 'Save',
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationRule extends StatelessWidget {
  const _ValidationRule({
    required this.label,
    required this.isValid,
  });

  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final color = isValid ? colors.accentSuccess : colors.accentDanger;
    final icon = isValid
        ? PhosphorIconsFill.checkCircle
        : PhosphorIconsFill.xCircle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
