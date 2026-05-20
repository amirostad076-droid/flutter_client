import 'dart:convert';

import 'package:fluxer_app/core/push/push_message.dart';
import 'package:unifiedpush/unifiedpush.dart' as up;

const String kUnifiedPushDefaultTitle = 'Fluxer';

PushMessage mapUnifiedPushMessage(up.PushMessage message) {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
  if (!message.decrypted) {
    return PushMessage(
      id: id,
      title: kUnifiedPushDefaultTitle,
      body: 'New notification',
      payload: const <String, String>{},
    );
  }
  final String raw = utf8.decode(message.content);
  final Object? decoded = _tryJsonDecode(raw);
  if (decoded is Map<String, Object?>) {
    return _mapJsonPayload(decoded, id);
  }
  return PushMessage(
    id: id,
    title: kUnifiedPushDefaultTitle,
    body: raw.isEmpty ? null : raw,
    payload: const <String, String>{},
  );
}

Object? _tryJsonDecode(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

PushMessage _mapJsonPayload(Map<String, Object?> json, String fallbackId) {
  final String? title = _readString(json, 'title');
  final String? body = _readString(json, 'body');
  final String id =
      _readString(json, 'id') ??
      _readString(json, 'message_id') ??
      fallbackId;
  final Map<String, String> payload = <String, String>{};
  for (final MapEntry<String, Object?> entry in json.entries) {
    if (entry.key == 'title' ||
        entry.key == 'body' ||
        entry.key == 'id' ||
        entry.key == 'message_id') {
      continue;
    }
    payload[entry.key] = entry.value?.toString() ?? '';
  }
  return PushMessage(
    id: id,
    title: title ?? kUnifiedPushDefaultTitle,
    body: body ?? 'New message',
    payload: payload,
  );
}

String? _readString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}
