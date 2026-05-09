import 'package:fluxer_app/features/chat/domain/message.dart';

enum AttachmentRenderType { image, video, audio, file }

class AttachmentRenderState {
  const AttachmentRenderState({
    required this.attachment,
    required this.type,
    required this.canRenderInlineMedia,
  });

  final Attachment attachment;
  final AttachmentRenderType type;
  final bool canRenderInlineMedia;

  bool get shouldRenderAsFile =>
      !canRenderInlineMedia || attachment.url.isEmpty;
}

AttachmentRenderState buildAttachmentRenderState({
  required Attachment attachment,
  required bool inlineAttachmentMedia,
}) {
  final bool hasUrl = attachment.url.isNotEmpty;
  final bool canRenderInlineMedia = inlineAttachmentMedia && hasUrl;
  if (attachment.isImage) {
    return AttachmentRenderState(
      attachment: attachment,
      type: AttachmentRenderType.image,
      canRenderInlineMedia: canRenderInlineMedia,
    );
  }
  if (attachment.isVideo) {
    return AttachmentRenderState(
      attachment: attachment,
      type: AttachmentRenderType.video,
      canRenderInlineMedia: canRenderInlineMedia,
    );
  }
  if (_isAudioAttachment(attachment)) {
    return AttachmentRenderState(
      attachment: attachment,
      type: AttachmentRenderType.audio,
      canRenderInlineMedia: canRenderInlineMedia,
    );
  }
  return AttachmentRenderState(
    attachment: attachment,
    type: AttachmentRenderType.file,
    canRenderInlineMedia: false,
  );
}

bool _isAudioAttachment(Attachment attachment) {
  final String normalizedType = attachment.contentType?.toLowerCase() ?? '';
  if (normalizedType.startsWith('audio/')) {
    return true;
  }
  final String lowerFilename = attachment.filename.toLowerCase();
  return lowerFilename.endsWith('.mp3') ||
      lowerFilename.endsWith('.wav') ||
      lowerFilename.endsWith('.ogg') ||
      lowerFilename.endsWith('.m4a') ||
      lowerFilename.endsWith('.flac') ||
      lowerFilename.endsWith('.aac');
}
