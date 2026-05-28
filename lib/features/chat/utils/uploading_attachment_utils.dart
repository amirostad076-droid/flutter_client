import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/domain/message_upload_session.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';

const String kUploadingAttachmentPlaceholderId = 'uploading';

bool isUploadingPlaceholderAttachment(Attachment attachment) {
  return attachment.id == kUploadingAttachmentPlaceholderId &&
      attachment.url.isEmpty;
}

List<Attachment> buildUploadingPlaceholderAttachments({
  required List<PendingAttachment> claimed,
  required String Function(int count) labelForMultiple,
}) {
  if (claimed.isEmpty) {
    return const <Attachment>[];
  }
  if (claimed.length == 1) {
    final PendingAttachment first = claimed.first;
    return <Attachment>[
      Attachment(
        id: kUploadingAttachmentPlaceholderId,
        filename: first.filename,
        title: first.filename,
        url: '',
        size: first.size,
        contentType: first.contentType,
      ),
    ];
  }
  final int totalSize = claimed.fold<int>(
    0,
    (int sum, PendingAttachment a) => sum + a.size,
  );
  return <Attachment>[
    Attachment(
      id: kUploadingAttachmentPlaceholderId,
      filename: labelForMultiple(claimed.length),
      url: '',
      size: totalSize,
      contentType: 'application/octet-stream',
    ),
  ];
}

/// Aggregate upload percent (0–100) for a message upload session.
double? computeMessageUploadSendingProgress(MessageUploadSession session) {
  if (session.sendingProgress != null) {
    return session.sendingProgress!.clamp(0, 100);
  }
  return computeMessageUploadSendingProgressFromAttachments(
    session.attachments,
  );
}

double? computeMessageUploadSendingProgressFromAttachments(
  List<PendingAttachment> attachments,
) {
  final List<PendingAttachment> active = attachments
      .where(
        (PendingAttachment a) => a.status != PendingAttachmentStatus.failed,
      )
      .toList();
  if (active.isEmpty) {
    return null;
  }
  final int totalBytes = active.fold<int>(
    0,
    (int sum, PendingAttachment a) => sum + a.size,
  );
  if (totalBytes > 0) {
    final double loadedBytes = active.fold<double>(
      0,
      (double sum, PendingAttachment a) =>
          sum + a.size * a.uploadProgress.clamp(0.0, 1.0),
    );
    return (loadedBytes / totalBytes * 100).clamp(0, 100);
  }
  final int completed = active
      .where(
        (PendingAttachment a) =>
            a.status == PendingAttachmentStatus.sending ||
            a.uploadProgress >= 1,
      )
      .length;
  return (completed / active.length * 100).clamp(0, 100);
}
