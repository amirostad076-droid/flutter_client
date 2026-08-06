import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/system_message_text.dart';
import 'package:fluxer_app/features/chat/utils/voice_message_attachment.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

const int kMessageAccessibilitySummaryMaxLength = 120;

final RegExp _spoilerContentRegex = RegExp(r'\|\|([\s\S]*?)\|\|');
final RegExp _customEmojiRegex = RegExp(r'<a?:([^:>]+):\d+>');
final RegExp _userMentionRegex = RegExp(r'<@!?\d+>');
final RegExp _roleMentionRegex = RegExp(r'<@&\d+>');
final RegExp _channelMentionRegex = RegExp(r'<#\d+>');
final RegExp _markdownLinkRegex = RegExp(r'\[([^\]]+)\]\([^)]+\)');
final RegExp _inlineCodeRegex = RegExp('`([^`]+)`');
final RegExp _fencedCodeBlockRegex = RegExp(r'```[^\n]*\n([\s\S]*?)```');
final RegExp _blockQuotePrefixRegex = RegExp(r'^>+\s?', multiLine: true);
final RegExp _headingPrefixRegex = RegExp(r'^#{1,6}\s+', multiLine: true);
final RegExp _boldAsteriskRegex = RegExp(r'\*\*(.+?)\*\*');
final RegExp _boldUnderscoreRegex = RegExp('__(.+?)__');
final RegExp _italicAsteriskRegex = RegExp(
  r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)',
);
final RegExp _italicUnderscoreRegex = RegExp('(?<!_)_(?!_)(.+?)(?<!_)_(?!_)');
final RegExp _strikethroughRegex = RegExp('~~(.+?)~~');
final RegExp _collapsedWhitespaceRegex = RegExp(r'\s+');

String plainTextFromMessageContent(String content, FluxerLocalizations l10n) {
  var text = content;
  text = text.replaceAll(_spoilerContentRegex, l10n.chatAttachmentSpoiler);
  text = text.replaceAllMapped(
    _customEmojiRegex,
    (match) => ':${match.group(1)}:',
  );
  text = text.replaceAll(_userMentionRegex, '@');
  text = text.replaceAll(_roleMentionRegex, '@');
  text = text.replaceAll(_channelMentionRegex, '#');
  text = text.replaceAllMapped(
    _fencedCodeBlockRegex,
    (match) => match.group(1)?.trim() ?? '',
  );
  text = text.replaceAllMapped(
    _markdownLinkRegex,
    (match) => match.group(1) ?? '',
  );
  text = text.replaceAllMapped(
    _inlineCodeRegex,
    (match) => match.group(1) ?? '',
  );
  text = _stripSimpleMarkdownEmphasis(text);
  text = text.replaceAll(_blockQuotePrefixRegex, '');
  text = text.replaceAll(_headingPrefixRegex, '');
  return text.trim().replaceAll(_collapsedWhitespaceRegex, ' ');
}

String truncateAccessibilitySummary(String text) {
  if (text.length <= kMessageAccessibilitySummaryMaxLength) {
    return text;
  }
  return '${text.substring(0, kMessageAccessibilitySummaryMaxLength - 3)}...';
}

String messageAccessibilitySummary(
  Message message,
  FluxerLocalizations l10n, {
  String? mentionedUserName,
  String? currentUserId,
}) {
  final String? summary = _resolveAccessibilitySummary(
    message,
    l10n,
    mentionedUserName: mentionedUserName,
    currentUserId: currentUserId,
  );
  return truncateAccessibilitySummary(
    summary ?? l10n.messageAccessibilityEmptySummary,
  );
}

String? _resolveAccessibilitySummary(
  Message message,
  FluxerLocalizations l10n, {
  String? mentionedUserName,
  String? currentUserId,
}) {
  if (message.isSystemMessage) {
    final String authorName = message.authorName.isNotEmpty
        ? message.authorName
        : message.authorId;
    final String? systemText = stringifySystemMessage(
      l10n: l10n,
      message: message,
      authorName: authorName,
      mentionedUserName: mentionedUserName,
      currentUserId: currentUserId,
    );
    if (systemText != null && systemText.isNotEmpty) {
      return systemText;
    }
  }

  if (message.isForwarded && message.messageSnapshots.isNotEmpty) {
    final MessageSnapshot snapshot = message.messageSnapshots.first;
    final String? forwardedSummary = _summaryFromParts(
      l10n: l10n,
      content: snapshot.content,
      stickers: snapshot.stickers,
      attachments: snapshot.attachments,
      embeds: snapshot.embeds,
      messageFlags: snapshot.flags,
    );
    if (forwardedSummary != null) {
      return forwardedSummary;
    }
  }

  return _summaryFromParts(
    l10n: l10n,
    content: message.content,
    stickers: message.stickers,
    attachments: message.attachments,
    embeds: message.embeds,
    messageFlags: message.flags,
  );
}

String _stripSimpleMarkdownEmphasis(String text) {
  var result = text;
  for (final RegExp pattern in <RegExp>[
    _boldAsteriskRegex,
    _boldUnderscoreRegex,
    _strikethroughRegex,
    _italicAsteriskRegex,
    _italicUnderscoreRegex,
  ]) {
    result = result.replaceAllMapped(pattern, (match) => match.group(1) ?? '');
  }
  return result;
}

String? _summaryFromParts({
  required FluxerLocalizations l10n,
  required String content,
  required List<MessageSticker> stickers,
  required List<Attachment> attachments,
  required List<Embed> embeds,
  required int messageFlags,
}) {
  final String plainContent = plainTextFromMessageContent(content, l10n);
  if (plainContent.isNotEmpty) {
    return plainContent;
  }
  if (stickers.isNotEmpty) {
    return l10n.messageAccessibilityStickerSummary(stickers.first.name);
  }
  final String? attachmentSummary = _attachmentSummary(
    l10n: l10n,
    attachments: attachments,
    messageFlags: messageFlags,
  );
  if (attachmentSummary != null) {
    return attachmentSummary;
  }
  return _embedSummary(l10n: l10n, embeds: embeds);
}

String? _attachmentSummary({
  required FluxerLocalizations l10n,
  required List<Attachment> attachments,
  required int messageFlags,
}) {
  if (attachments.isEmpty) {
    return null;
  }
  final Attachment attachment = attachments.first;
  if (isVoiceMessageAttachment(
    messageFlags: messageFlags,
    attachment: attachment,
  )) {
    return l10n.voiceMessageTitle;
  }
  if (attachment.isSpoiler) {
    return l10n.messageAccessibilitySpoilerAttachmentSummary;
  }
  if (attachment.isImage) {
    return l10n.messageAccessibilityImageSummary;
  }
  if (attachment.isVideo) {
    return l10n.messageAccessibilityVideoSummary;
  }
  if (attachment.isAudio) {
    return l10n.messageAccessibilityAudioSummary;
  }
  if (attachments.length == 1) {
    final String label = (attachment.title?.trim().isNotEmpty ?? false)
        ? attachment.title!.trim()
        : attachment.filename.trim();
    if (label.isNotEmpty) {
      return l10n.messageAccessibilityFileSummary(label);
    }
  }
  if (attachments.length > 1) {
    return l10n.messageAccessibilityAttachmentsSummary(attachments.length);
  }
  return l10n.messageAccessibilityAttachmentSummary;
}

String? _embedSummary({
  required FluxerLocalizations l10n,
  required List<Embed> embeds,
}) {
  if (embeds.isEmpty) {
    return null;
  }
  final Embed embed = embeds.first;
  final String? title = embed.title?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }
  final String? description = embed.description?.trim();
  if (description != null && description.isNotEmpty) {
    return plainTextFromMessageContent(description, l10n);
  }
  return switch (embed.type) {
    EmbedType.image || EmbedType.gifv => l10n.messageAccessibilityImageSummary,
    EmbedType.video => l10n.messageAccessibilityVideoSummary,
    _ => l10n.messageAccessibilityEmbedSummary,
  };
}
