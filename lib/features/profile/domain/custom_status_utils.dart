import 'package:fluxer_dart/export.dart';

const int kCustomStatusTextLimit = 128;

CustomStatusResponse? normalizeCustomStatus(CustomStatusResponse? status) {
  if (status == null) {
    return null;
  }
  final String? text = status.text?.trim();
  final bool hasEmoji =
      status.emojiId != null ||
      (status.emojiName != null && status.emojiName!.isNotEmpty);
  if ((text == null || text.isEmpty) && !hasEmoji) {
    return null;
  }
  final DateTime? expiresAt = status.expiresAt;
  if (expiresAt != null && !expiresAt.toUtc().isAfter(DateTime.now().toUtc())) {
    return null;
  }
  return status;
}

CustomStatusPayload buildCustomStatusPayload({
  required String? text,
  required String? emojiId,
  required String? emojiName,
  required DateTime? expiresAt,
}) {
  final String? trimmedText = text?.trim();
  return CustomStatusPayload(
    text: trimmedText == null || trimmedText.isEmpty ? null : trimmedText,
    emojiId: emojiId,
    emojiName: emojiId == null ? emojiName : null,
    expiresAt: expiresAt?.toUtc().toIso8601String(),
  );
}
