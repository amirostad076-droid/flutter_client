import 'dart:convert';

import 'package:fluxer_app/core/database/fluxer_database.dart';

Set<String> parseCollapsedCategoryIdsFromGuildSettingsJson(
  Map<String, dynamic> data,
) {
  final overrides = data['channel_overrides'] as Map<String, dynamic>?;
  if (overrides == null || overrides.isEmpty) {
    return {};
  }
  final collapsed = <String>{};
  for (final entry in overrides.entries) {
    final override = entry.value;
    if (override is Map<String, dynamic> && override['collapsed'] == true) {
      collapsed.add(entry.key);
    }
  }
  return collapsed;
}

Set<String> parseCollapsedCategoryIdsFromGuildSettingsRow(
  UserGuildSettingsTableData? row,
) {
  if (row == null) {
    return {};
  }
  final data = jsonDecode(row.data) as Map<String, dynamic>;
  return parseCollapsedCategoryIdsFromGuildSettingsJson(data);
}
