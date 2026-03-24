import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/domain/stored_account.dart';
import 'package:fluxeron/features/auth/presentation/widgets/account_row.dart';
import 'package:fluxeron/features/auth/providers/account_manager_provider.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:fluxeron/features/ui/modal/fluxer_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountSelector extends ConsumerWidget {
  const AccountSelector({
    required this.currentUserId,
    required this.onSelectAccount,
    required this.onAddAccount,
    super.key,
  });

  final String currentUserId;
  final void Function(StoredAccount account) onSelectAccount;
  final VoidCallback onAddAccount;

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    StoredAccount account,
  ) async {
    await FluxerConfirmModal.show(
      context,
      title: 'Remove account',
      description:
          'Remove ${account.identifier} from this device? '
          'You can add it again later.',
      confirmLabel: 'Remove',
      isDanger: true,
      onConfirm: () {
        unawaited(
          ref
              .read(accountManagerProvider.notifier)
              .removeAccount(account.userId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountManagerProvider);
    final accounts = state.accounts;

    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return AbsorbPointer(
      absorbing: state.isSwitching,
      child: AnimatedOpacity(
        opacity: state.isSwitching ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose an account',
              style: textStyles.heading.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: layout.s2),
            Text(
              'Select an account to switch to, or add a new one.',
              style: textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
            SizedBox(height: layout.s3),
            ...accounts.map(
              (account) => Padding(
                padding: EdgeInsets.only(bottom: layout.s2),
                child: AccountRow(
                  account: account,
                  isCurrent: account.userId == currentUserId,
                  onTap: () => onSelectAccount(account),
                  onRemove: () => _confirmRemove(context, ref, account),
                ),
              ),
            ),
            SizedBox(height: layout.s2),
            FluxerButton.secondary(
              onPressed: onAddAccount,
              label: 'Add an account',
              icon: PhosphorIconsBold.plus,
              fitContent: true,
            ),
          ],
        ),
      ),
    );
  }
}
