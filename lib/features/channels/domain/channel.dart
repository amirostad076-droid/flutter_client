import 'package:drift/drift.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;

enum ChannelType { text, voice, announcement, stage }

ChannelType channelTypeFromInt(int type) {
  switch (type) {
    case 0:
      return ChannelType.text;
    case 2:
      return ChannelType.voice;
    case 5:
      return ChannelType.announcement;
    case 13:
      return ChannelType.stage;
    default:
      return ChannelType.text;
  }
}

int channelTypeToInt(ChannelType type) {
  switch (type) {
    case ChannelType.text:
      return 0;
    case ChannelType.voice:
      return 2;
    case ChannelType.announcement:
      return 5;
    case ChannelType.stage:
      return 13;
  }
}

class Channel {
  final String id;
  final String serverId;
  final String name;
  final ChannelType type;
  final String? topic;
  final String? parentId;
  final int position;

  const Channel({
    required this.id,
    required this.serverId,
    required this.name,
    this.type = ChannelType.text,
    this.topic,
    this.parentId,
    this.position = 0,
  });

  factory Channel.fromRow(db.Channel row) {
    return Channel(
      id: row.id,
      serverId: row.serverId,
      name: row.name,
      type: channelTypeFromInt(row.type),
      topic: row.topic,
      parentId: row.parentId,
      position: row.position,
    );
  }

  db.ChannelsCompanion toCompanion() {
    return db.ChannelsCompanion.insert(
      id: id,
      serverId: serverId,
      name: name,
      type: Value(channelTypeToInt(type)),
      topic: Value(topic),
      parentId: Value(parentId),
      position: Value(position),
    );
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final List<Channel> channels;

  const ChannelCategory({
    required this.id,
    required this.name,
    required this.channels,
  });
}

/// Groups a flat list of [Channel]s into [ChannelCategory]s.
///
/// Channels with type 4 (category) become group headers. Child channels
/// reference their category via [parentId]. Channels without a parent
/// are placed in a synthetic "Channels" category.
List<ChannelCategory> groupChannelsIntoCategories(List<Channel> channels) {
  final uncategorized = <Channel>[];
  final parentMap = <String, List<Channel>>{};

  for (final ch in channels) {
    if (ch.parentId != null) {
      parentMap.putIfAbsent(ch.parentId!, () => <Channel>[]).add(ch);
    } else {
      uncategorized.add(ch);
    }
  }

  final categoryChannels = <Channel>[];
  final actualUncategorized = <Channel>[];

  for (final ch in uncategorized) {
    if (parentMap.containsKey(ch.id)) {
      categoryChannels.add(ch);
    } else {
      actualUncategorized.add(ch);
    }
  }

  actualUncategorized.sort((a, b) => a.position.compareTo(b.position));
  categoryChannels.sort((a, b) => a.position.compareTo(b.position));

  final result = <ChannelCategory>[];

  if (actualUncategorized.isNotEmpty) {
    result.add(
      ChannelCategory(
        id: '_uncategorized',
        name: 'Channels',
        channels: actualUncategorized,
      ),
    );
  }

  for (final cat in categoryChannels) {
    final catChildren = parentMap[cat.id] ?? <Channel>[]
      ..sort((a, b) => a.position.compareTo(b.position));
    result.add(
      ChannelCategory(id: cat.id, name: cat.name, channels: catChildren),
    );
  }

  return result;
}
