import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_item.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/ui/modal/fluxer_modal.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

Future<bool?> showDeleteMessageConfirmModal(
  BuildContext context,
  WidgetRef ref, {
  required Message message,
  String? guildId,
}) {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  return FluxerModal.show<bool>(
    context,
    title: l10n.chatMessageDeleteConfirmTitle,
    centered: true,
    builder: (dialogContext, close) {
      final textStyles = dialogContext.textStyles;
      final layout = dialogContext.layout;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chatMessageDeleteConfirmDescription,
            style: textStyles.bodySmall.copyWith(height: 1.4),
          ),
          SizedBox(height: layout.s4),
          _DeleteMessagePreview(message: message, guildId: guildId),
        ],
      );
    },
    actionsBuilder: (pop) => [
      FluxerButton.dangerPrimary(
        onPressed: () {
          unawaited(
            ref.read(chatViewModelProvider.notifier).deleteMessage(message.id),
          );
          pop(true);
        },
        label: l10n.chatMessageDelete,
      ),
      const SizedBox(height: 8),
      FluxerButton.secondary(
        onPressed: () => pop(false),
        label: 'Cancel',
      ),
    ],
  );
}

class _DeleteMessagePreview extends ConsumerWidget {
  const _DeleteMessagePreview({required this.message, this.guildId});

  final Message message;
  final String? guildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final layout = context.layout;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.textScalerOf(context).scale(1) * 0.875,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: layout.radiusMd,
          border: Border.all(color: colors.backgroundHeaderSecondary),
        ),
        child: ClipRRect(
          borderRadius: layout.radiusMd,
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: MessageItem(
                message: message,
                inboxPreviewMode: true,
                hideMentionHighlight: true,
                previewRoleGuildId: guildId,
                currentUserId: ref.watch(currentUserIdProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
