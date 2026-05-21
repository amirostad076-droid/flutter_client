import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _ReportCategory {
  const _ReportCategory({required this.value, required this.label});

  final MessageReportCategoryEnum value;
  final String label;
}

Future<void> showReportMessageSheet(
  BuildContext context, {
  required String channelId,
  required String messageId,
}) {
  return FluxerBottomSheet.show<void>(
    context,
    variant: FluxerBottomSheetVariant.menu,
    title: FluxerLocalizations.of(context).chatReportSheetTitle,
    subtitle: Text(
      FluxerLocalizations.of(context).chatReportSheetSubtitle,
      style: context.textStyles.bodySmall.copyWith(
        color: context.colors.textTertiary,
      ),
    ),
    builder: (sheetContext, close) => _ReportMessageBody(
      channelId: channelId,
      messageId: messageId,
      onClose: close,
    ),
  );
}

class _ReportMessageBody extends ConsumerStatefulWidget {
  const _ReportMessageBody({
    required this.channelId,
    required this.messageId,
    required this.onClose,
  });

  final String channelId;
  final String messageId;
  final VoidCallback onClose;

  @override
  ConsumerState<_ReportMessageBody> createState() => _ReportMessageBodyState();
}

class _ReportMessageBodyState extends ConsumerState<_ReportMessageBody> {
  bool _isSubmitting = false;

  Future<void> _submit(MessageReportCategoryEnum category) async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final toast = ref.read(toastProvider.notifier);
    final l10n = FluxerLocalizations.of(context);
    try {
      await ref
          .read(fluxerClientProvider)
          .reports
          .reportMessage(
            body: ReportMessageRequest(
              channelId: widget.channelId,
              messageId: widget.messageId,
              category: category,
            ),
          );
      toast.show(
        FluxerToast(
          message: l10n.chatReportSubmittedToast,
          variant: FluxerToastVariant.success,
        ),
      );
    } on Object {
      toast.show(
        FluxerToast(
          message: l10n.chatReportFailedToast,
          variant: FluxerToastVariant.danger,
        ),
      );
    } finally {
      if (mounted) {
        widget.onClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    final categories = <_ReportCategory>[
      _ReportCategory(
        value: MessageReportCategoryEnum.harassment,
        label: l10n.chatReportCategoryHarassment,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.hateSpeech,
        label: l10n.chatReportCategoryHateSpeech,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.violentContent,
        label: l10n.chatReportCategoryViolentContent,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.spam,
        label: l10n.chatReportCategorySpam,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.nsfwViolation,
        label: l10n.chatReportCategoryNsfwViolation,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.illegalActivity,
        label: l10n.chatReportCategoryIllegalActivity,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.doxxing,
        label: l10n.chatReportCategoryDoxxing,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.selfHarm,
        label: l10n.chatReportCategorySelfHarm,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.childSafety,
        label: l10n.chatReportCategoryChildSafety,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.maliciousLinks,
        label: l10n.chatReportCategoryMaliciousLinks,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.impersonation,
        label: l10n.chatReportCategoryImpersonation,
      ),
      _ReportCategory(
        value: MessageReportCategoryEnum.other,
        label: l10n.chatReportCategoryOther,
      ),
    ];

    return AbsorbPointer(
      absorbing: _isSubmitting,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: FluxerMenuGroup(
            children: [
              for (final category in categories)
                FluxerBottomSheetMenuItem(
                  icon: PhosphorIconsRegular.flag,
                  label: category.label,
                  isDanger: true,
                  onTap: () => _submit(category.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
