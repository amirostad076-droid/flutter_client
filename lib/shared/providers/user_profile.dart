import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile.g.dart';

@riverpod
Future<UserProfileFullResponse?> userProfile(
  Ref ref, {
  String? userId,
  String? guildId,
}) async {
  final String resolvedId =
      userId ?? ref.read(userSettingsViewModelProvider).userId;

  if (resolvedId.isEmpty) {
    return null;
  }

  final FluxerClient client = ref.read(fluxerClientProvider);
  try {
    return await client.users.getUserProfile(
      targetId: resolvedId,
      guildId: guildId,
    );
  } on Object {
    return null;
  }
}

@riverpod
Future<String?> userProfileSelfNote(Ref ref, {required String userId}) async {
  if (userId.isEmpty) {
    return null;
  }
  final UserNotesTableData? row = await ref
      .read(fluxerDatabaseProvider)
      .userNotesDao
      .getNote(userId);
  final String? content = row?.content;
  if (content == null || content.trim().isEmpty) {
    return null;
  }
  return content.trim();
}
