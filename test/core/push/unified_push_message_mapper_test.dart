import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_message_mapper.dart';
import 'package:unifiedpush/unifiedpush.dart' as up;

void main() {
  group('mapUnifiedPushMessage', () {
    test('maps nested data fields for navigation payload', () {
      final up.PushMessage input = up.PushMessage(
        Uint8List.fromList(
          utf8.encode(
            '{"title":"alice","body":"hello","data":{"message_id":"1",'
            '"channel_id":"2","guild_id":"3","url":"/channels/3/2/1"}}',
          ),
        ),
        true,
      );
      final message = mapUnifiedPushMessage(input);
      expect(message.title, 'alice');
      expect(message.body, 'hello');
      expect(message.id, '1');
      expect(message.payload['channel_id'], '2');
      expect(message.payload['url'], '/channels/3/2/1');
    });
  });
}
