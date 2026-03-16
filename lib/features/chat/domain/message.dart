import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/servers/domain/server.dart';

enum EmbedType { rich, image, link, video }

class EmbedField {
  final String name;
  final String value;
  final bool isInline;

  const EmbedField({
    required this.name,
    required this.value,
    this.isInline = false,
  });

  factory EmbedField.fromSdk(EmbedFieldResponse sdk) {
    return EmbedField(name: sdk.name, value: sdk.value, isInline: sdk.inline);
  }

  factory EmbedField.fromJson(Map<String, dynamic> json) {
    return EmbedField(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      isInline: json['inline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'inline': isInline,
  };
}

class Embed {
  final EmbedType type;
  final String? title;
  final String? description;
  final String? url;
  final int? color;
  final String? thumbnailUrl;
  final String? imageUrl;
  final String? videoUrl;
  final List<EmbedField> fields;
  final String? footerText;
  final String? footerIconUrl;
  final String? authorName;
  final String? authorIconUrl;
  final String? providerName;

  const Embed({
    required this.type,
    this.title,
    this.description,
    this.url,
    this.color,
    this.thumbnailUrl,
    this.imageUrl,
    this.videoUrl,
    this.fields = const [],
    this.footerText,
    this.footerIconUrl,
    this.authorName,
    this.authorIconUrl,
    this.providerName,
  });

  factory Embed.fromSdk(MessageEmbedResponse sdk) {
    return Embed(
      type: _parseEmbedType(sdk.type),
      title: sdk.title,
      description: sdk.description,
      url: sdk.url,
      color: sdk.color,
      thumbnailUrl: sdk.thumbnail?.url,
      imageUrl: sdk.image?.url,
      videoUrl: sdk.video?.url,
      fields: sdk.fields?.map(EmbedField.fromSdk).toList() ?? const [],
      footerText: sdk.footer?.text,
      footerIconUrl: sdk.footer?.iconUrl,
      authorName: sdk.author?.name,
      authorIconUrl: sdk.author?.iconUrl,
      providerName: sdk.provider?.name,
    );
  }

  factory Embed.fromJson(Map<String, dynamic> json) {
    return Embed(
      type: _parseEmbedType(json['type'] as String? ?? 'rich'),
      title: json['title'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      color: json['color'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => EmbedField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      footerText: json['footerText'] as String?,
      footerIconUrl: json['footerIconUrl'] as String?,
      authorName: json['authorName'] as String?,
      authorIconUrl: json['authorIconUrl'] as String?,
      providerName: json['providerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'title': title,
    'description': description,
    'url': url,
    'color': color,
    'thumbnailUrl': thumbnailUrl,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'fields': fields.map((f) => f.toJson()).toList(),
    'footerText': footerText,
    'footerIconUrl': footerIconUrl,
    'authorName': authorName,
    'authorIconUrl': authorIconUrl,
    'providerName': providerName,
  };

  static EmbedType _parseEmbedType(String type) {
    switch (type) {
      case 'image':
        return EmbedType.image;
      case 'link':
        return EmbedType.link;
      case 'video':
        return EmbedType.video;
      default:
        return EmbedType.rich;
    }
  }
}

class Attachment {
  final String id;
  final String filename;
  final String url;
  final int? size;
  final int? width;
  final int? height;

  const Attachment({
    required this.id,
    required this.filename,
    required this.url,
    this.size,
    this.width,
    this.height,
  });

  factory Attachment.fromSdk(MessageAttachmentResponse sdk) {
    return Attachment(
      id: sdk.id,
      filename: sdk.filename,
      url: sdk.url ?? '',
      size: sdk.size,
      width: sdk.width,
      height: sdk.height,
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      url: json['url'] as String? ?? '',
      size: json['size'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'url': url,
    'size': size,
    'width': width,
    'height': height,
  };

  bool get isImage {
    final ext = filename.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
  }
}

class Reaction {
  final String emoji;
  final int count;
  final bool hasReacted;

  const Reaction({
    required this.emoji,
    required this.count,
    this.hasReacted = false,
  });

  factory Reaction.fromSdk(MessageReactionResponse sdk) {
    return Reaction(
      emoji: sdk.emoji.name,
      count: sdk.count,
      hasReacted: sdk.me != null,
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      emoji: json['emoji'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      hasReacted: json['hasReacted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'count': count,
    'hasReacted': hasReacted,
  };
}

class Message {
  final String id;
  final String channelId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final int? authorAvatarColor;
  final String content;
  final DateTime timestamp;
  final DateTime? editedTimestamp;
  final List<Embed> embeds;
  final List<Attachment> attachments;
  final List<Reaction> reactions;
  final String? replyToId;
  final String? forwardedFrom;
  final bool isPinned;
  final bool isMentioned;
  final int type;

  const Message({
    required this.id,
    required this.channelId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.authorAvatar,
    this.authorAvatarColor,
    this.editedTimestamp,
    this.embeds = const [],
    this.attachments = const [],
    this.reactions = const [],
    this.replyToId,
    this.forwardedFrom,
    this.isPinned = false,
    this.isMentioned = false,
    this.type = 0,
  });

  factory Message.fromSdk(MessageResponseSchema sdk) {
    return Message(
      id: sdk.id,
      channelId: sdk.channelId,
      authorId: sdk.author.id,
      authorName: sdk.author.globalName ?? sdk.author.username,
      authorAvatar: sdk.author.avatar,
      authorAvatarColor: sdk.author.avatarColor,
      content: sdk.content,
      timestamp: sdk.timestamp,
      editedTimestamp: sdk.editedTimestamp,
      embeds: sdk.embeds?.map(Embed.fromSdk).toList() ?? const [],
      attachments:
          sdk.attachments?.map(Attachment.fromSdk).toList() ?? const [],
      reactions: sdk.reactions?.map(Reaction.fromSdk).toList() ?? const [],
      replyToId: sdk.referencedMessage?.id,
      isPinned: sdk.pinned,
      isMentioned: sdk.mentionEveryone,
      type: int.tryParse(sdk.type.name.replaceFirst('number', '')) ?? 0,
    );
  }

  factory Message.fromRow(db.Message row) {
    return Message(
      id: row.id,
      channelId: row.channelId,
      authorId: row.authorId,
      authorName: row.authorName.isNotEmpty ? row.authorName : row.authorId,
      authorAvatar: row.authorAvatar,
      authorAvatarColor: row.authorAvatarColor,
      content: row.content,
      timestamp: row.timestamp,
      editedTimestamp: row.editedTimestamp,
      embeds: _decodeList(row.embedsJson, Embed.fromJson),
      attachments: _decodeList(row.attachmentsJson, Attachment.fromJson),
      reactions: _decodeList(row.reactionsJson, Reaction.fromJson),
      replyToId: row.replyToId,
      forwardedFrom: row.forwardedFrom,
      isPinned: row.isPinned,
      isMentioned: row.isMentioned,
      type: row.type,
    );
  }

  db.MessagesCompanion toCompanion() {
    return db.MessagesCompanion.insert(
      id: id,
      channelId: channelId,
      authorId: authorId,
      authorName: Value(authorName),
      authorAvatar: Value(authorAvatar),
      authorAvatarColor: Value(authorAvatarColor),
      content: content,
      timestamp: timestamp,
      embedsJson: Value(jsonEncode(embeds.map((e) => e.toJson()).toList())),
      attachmentsJson: Value(
        jsonEncode(attachments.map((a) => a.toJson()).toList()),
      ),
      reactionsJson: Value(
        jsonEncode(reactions.map((r) => r.toJson()).toList()),
      ),
      type: Value(type),
    );
  }

  String? get authorAvatarUrl {
    if (authorAvatar == null) {
      return null;
    }
    return '$fluxerMediaCdn/avatars/$authorId/$authorAvatar.png';
  }

  bool get hasEmbeds => embeds.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyToId != null;
  bool get isForwarded => forwardedFrom != null;
  bool get isEdited => editedTimestamp != null;
  bool get isSystemMessage => type != 0 && type != 1;
  bool get isMemberJoin => type == 7;
  bool get isPin => type == 19;

  static List<T> _decodeList<T>(
    String json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } on Object {
      return [];
    }
  }
}
