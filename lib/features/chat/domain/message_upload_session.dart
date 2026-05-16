import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';

class MessageUploadSession {
  const MessageUploadSession({
    required this.nonce,
    required this.channelId,
    required this.attachments,
    this.sendingProgress,
  });

  final String nonce;
  final String channelId;
  final List<PendingAttachment> attachments;
  final double? sendingProgress;

  bool get hasFailedUploads => attachments.any(
    (PendingAttachment a) => a.status == PendingAttachmentStatus.failed,
  );

  MessageUploadSession copyWith({
    String? nonce,
    String? channelId,
    List<PendingAttachment>? attachments,
    Object? sendingProgress = _unset,
  }) {
    return MessageUploadSession(
      nonce: nonce ?? this.nonce,
      channelId: channelId ?? this.channelId,
      attachments: attachments ?? this.attachments,
      sendingProgress: sendingProgress == _unset
          ? this.sendingProgress
          : sendingProgress as double?,
    );
  }

  static const Object _unset = Object();
}
