import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_item.dart';
import 'package:fluxer_app/features/moderation/iar/iar_flow.dart';

/// Faithful preview of the reported message (reuses [MessageItem] in preview
/// mode), matching web `IARModalPreview.tsx`.
class IarPreview extends StatelessWidget {
  const IarPreview({required this.context, super.key});

  final IarContext context;

  @override
  Widget build(BuildContext ctx) {
    return switch (context) {
      IarMessageContext(:final message, :final guildId) => _MessagePreviewCard(
        message: message,
        guildId: guildId,
      ),
    };
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({required this.message, this.guildId});

  final Message message;
  final String? guildId;

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
