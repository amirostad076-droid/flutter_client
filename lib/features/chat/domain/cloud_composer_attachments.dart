import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';

class CloudComposerAttachments {
  const CloudComposerAttachments(this.items);

  final List<PendingAttachment> items;

  static const CloudComposerAttachments empty = CloudComposerAttachments(
    <PendingAttachment>[],
  );
}
