import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';
import 'package:fluxer_app/features/chat/providers/cloud_upload_controller.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class AttachmentEditModal {
  AttachmentEditModal._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String channelId,
    required PendingAttachment attachment,
  }) {
    final TextEditingController filenameController =
        TextEditingController(text: attachment.filename);
    final TextEditingController descriptionController =
        TextEditingController(text: attachment.description ?? '');
    final ValueNotifier<bool> spoilerNotifier = ValueNotifier<bool>(
      (attachment.flags & attachmentFlagIsSpoiler) != 0,
    );
    return FluxerBottomSheet.show<void>(
      context,
      title: FluxerLocalizations.of(context).chatAttachmentEditTitle,
      builder: (BuildContext sheetContext, VoidCallback close) {
        final colors = sheetContext.colors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FluxerInput(
                controller: filenameController,
                label: FluxerLocalizations.of(context).chatAttachmentFilenameLabel,
              ),
              const SizedBox(height: 12),
              FluxerInput.multiline(
                controller: descriptionController,
                label: FluxerLocalizations.of(context).chatAttachmentDescriptionLabel,
                hint: FluxerLocalizations.of(context).chatAttachmentDescriptionHint,
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: spoilerNotifier,
                builder: (BuildContext ctx, bool isSpoiler, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          FluxerLocalizations.of(context).chatAttachmentSpoilerLabel,
                          style: sheetContext.textStyles.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: isSpoiler,
                        onChanged: (bool v) => spoilerNotifier.value = v,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FluxerButton.primary(
                label: FluxerLocalizations.of(context).save,
                onPressed: () {
                  final String name = filenameController.text.trim();
                  final String desc = descriptionController.text.trim();
                  int flags = attachment.flags & ~attachmentFlagIsSpoiler;
                  if (spoilerNotifier.value) {
                    flags |= attachmentFlagIsSpoiler;
                  }
                  ref
                      .read(cloudUploadControllerProvider(channelId).notifier)
                      .updateAttachment(
                        attachment.id,
                        filename: name.isNotEmpty ? name : attachment.filename,
                        description: desc.isEmpty ? null : desc,
                        flags: flags,
                      );
                  close();
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      filenameController.dispose();
      descriptionController.dispose();
      spoilerNotifier.dispose();
    });
  }
}
