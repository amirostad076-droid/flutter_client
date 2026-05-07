import 'package:cross_file/cross_file.dart';

import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';

class PreparedAttachments {
  const PreparedAttachments({this.attachmentMetadata, this.attachmentFiles});

  final List<ApiAttachmentMetadata>? attachmentMetadata;
  final List<XFile>? attachmentFiles;

  bool get isEmpty =>
      (attachmentMetadata == null || attachmentMetadata!.isEmpty) &&
      (attachmentFiles == null || attachmentFiles!.isEmpty);

  static const PreparedAttachments empty = PreparedAttachments();
}
