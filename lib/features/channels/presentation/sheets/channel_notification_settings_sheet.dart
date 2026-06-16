import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> showChannelNotificationSettingsSheet(
  BuildContext context, {
  required Channel channel,
  required Future<void> Function(UserNotificationSettings setting)
  onSetNotification,
}) async {
  final info = await _readChannelNotificationInfo(context, channel);
  if (!context.mounted) {
    return;
  }

  final defaultLabel = info.hasCategory
      ? 'Category Default'
      : 'Community Default';
  final defaultHint = _notificationLabel(info.effectiveDefault);

  await FluxerBottomSheet.show<void>(
    context,
    title: 'Notification Settings',
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, close) {
      void select(UserNotificationSettings setting) {
        close();
        unawaited(onSetNotification(setting));
      }

      return FluxerBottomSheetContent(
        child: FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              label: defaultLabel,
              hint: defaultHint,
              icon: PhosphorIconsBold.bell,
              isSelected: info.selected == UserNotificationSettings.inherit,
              onTap: () => select(UserNotificationSettings.inherit),
            ),
            FluxerBottomSheetMenuItem(
              label: 'All Messages',
              icon: PhosphorIconsBold.bellRinging,
              isSelected: info.selected == UserNotificationSettings.allMessages,
              onTap: () => select(UserNotificationSettings.allMessages),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Only @mentions',
              icon: PhosphorIconsBold.at,
              isSelected:
                  info.selected == UserNotificationSettings.onlyMentions,
              onTap: () => select(UserNotificationSettings.onlyMentions),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Nothing',
              icon: PhosphorIconsBold.bellSlash,
              isSelected: info.selected == UserNotificationSettings.noMessages,
              onTap: () => select(UserNotificationSettings.noMessages),
            ),
          ],
        ),
      );
    },
  );
}

class _ChannelNotificationInfo {
  const _ChannelNotificationInfo({
    required this.selected,
    required this.effectiveDefault,
    required this.hasCategory,
  });

  final UserNotificationSettings selected;
  final UserNotificationSettings effectiveDefault;
  final bool hasCategory;
}

Future<_ChannelNotificationInfo> _readChannelNotificationInfo(
  BuildContext context,
  Channel channel,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final row = await container
      .read(fluxerDatabaseProvider)
      .userGuildSettingsDao
      .getByGuildId(channel.guildId);

  var selected = UserNotificationSettings.inherit;
  var guildDefault = UserNotificationSettings.allMessages;
  var categoryOverride = UserNotificationSettings.inherit;

  if (row != null) {
    try {
      final settings = UserGuildSettingsResponse.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
      selected =
          settings.channelOverrides?[channel.id]?.messageNotifications ??
          UserNotificationSettings.inherit;
      guildDefault = settings.messageNotifications;
      if (channel.parentId != null) {
        categoryOverride =
            settings
                .channelOverrides?[channel.parentId]
                ?.messageNotifications ??
            UserNotificationSettings.inherit;
      }
    } on Object {
      // Malformed override JSON falls back to defaults.
    }
  }

  final effectiveDefault = categoryOverride == UserNotificationSettings.inherit
      ? guildDefault
      : categoryOverride;

  return _ChannelNotificationInfo(
    selected: selected,
    effectiveDefault: effectiveDefault,
    hasCategory: channel.parentId != null,
  );
}

String _notificationLabel(UserNotificationSettings setting) {
  return switch (setting) {
    UserNotificationSettings.allMessages => 'All Messages',
    UserNotificationSettings.onlyMentions => 'Only @mentions',
    UserNotificationSettings.noMessages => 'Nothing',
    UserNotificationSettings.inherit => 'Default',
    UserNotificationSettings.$unknown => 'Default',
  };
}
