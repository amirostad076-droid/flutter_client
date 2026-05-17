import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/providers/cloud_upload_controller.dart';

/// Whether the composer has text or pending uploads worth sending.
bool composerHasSendableContent(
  WidgetRef ref,
  String channelId,
  String wireText,
) {
  final bool hasPendingUploads = ref
      .read(cloudUploadControllerProvider(channelId))
      .items
      .isNotEmpty;
  return composerHasSendableContentFromParts(
    channelId: channelId,
    wireText: wireText,
    hasPendingUploads: hasPendingUploads,
  );
}

/// Core sendable check without reading providers (for unit tests).
bool composerHasSendableContentFromParts({
  required String channelId,
  required String wireText,
  required bool hasPendingUploads,
}) {
  if (channelId.isEmpty) {
    return false;
  }
  return wireText.trim().isNotEmpty || hasPendingUploads;
}
