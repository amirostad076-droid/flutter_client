import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/mature_content/domain/mature_content_types.dart';
import 'package:fluxer_app/features/mature_content/presentation/sheets/channel_access_gate_sheet.dart';
import 'package:fluxer_app/features/mature_content/providers/mature_content_agreements_provider.dart';

Future<bool> promptForChannelGateIfNeeded({
  required BuildContext context,
  required ProviderContainer container,
  required String channelId,
  String? guildId,
  ChannelType? channelType,
}) async {
  final MatureContentGateReason reason = await container.read(
    matureContentGateReasonProvider(channelId).future,
  );
  if (reason == MatureContentGateReason.none) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }
  return showChannelAccessGateSheet(
    context: context,
    container: container,
    channelId: channelId,
    guildId: guildId,
    channelType: channelType,
  );
}
