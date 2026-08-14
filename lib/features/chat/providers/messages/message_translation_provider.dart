import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/data/local_device_translation_source.dart';
import 'package:fluxer_app/features/chat/data/message_translation_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_translation_provider.g.dart';

@Riverpod(keepAlive: true)
MessageTranslationService messageTranslationService(Ref ref) {
  return MessageTranslationService(
    messageDao: ref.watch(fluxerDatabaseProvider).messageDao,
    sources: <LocalDeviceTranslationSource>[LocalDeviceTranslationSource()],
  );
}

@Riverpod(keepAlive: true)
Future<bool> messageTranslationAvailable(Ref ref) {
  return ref.watch(messageTranslationServiceProvider).isAvailable();
}

@Riverpod(keepAlive: true)
class TranslatingMessageIds extends _$TranslatingMessageIds {
  @override
  Set<String> build() => <String>{};

  void add(String messageId) {
    state = <String>{...state, messageId};
  }

  void remove(String messageId) {
    if (!state.contains(messageId)) {
      return;
    }
    final Set<String> next = <String>{...state}..remove(messageId);
    state = next;
  }
}
