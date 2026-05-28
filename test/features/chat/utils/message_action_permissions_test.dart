import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/message_action_permissions.dart';

int _bits(List<Permission> permissions) =>
    permissions.fold<int>(0, (acc, p) => acc | p.value);

Message _domainMessage({
  String id = 'm-1',
  String channelId = 'c-1',
  String authorId = 'author-1',
  int type = 0,
  int flags = 0,
  List<Embed> embeds = const [],
}) {
  return Message(
    id: id,
    channelId: channelId,
    authorId: authorId,
    authorName: 'Author',
    content: 'hello',
    timestamp: DateTime.utc(2026),
    type: type,
    flags: flags,
    embeds: embeds,
  );
}

Embed _imageEmbed() => const Embed(type: EmbedType.image, url: 'https://x/y');

void main() {
  group('canManageMessagesInChannel', () {
    test('returns false in DMs even with bits', () {
      expect(
        canManageMessagesInChannel(
          isDmChannel: true,
          channelPermissionBits: _bits([Permission.manageMessages]),
        ),
        isFalse,
      );
    });

    test('returns false when guild bits are null', () {
      expect(canManageMessagesInChannel(isDmChannel: false), isFalse);
    });

    test('returns false when manageMessages bit is missing', () {
      expect(
        canManageMessagesInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.sendMessages]),
        ),
        isFalse,
      );
    });

    test('returns true when manageMessages bit is set', () {
      expect(
        canManageMessagesInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.manageMessages]),
        ),
        isTrue,
      );
    });
  });

  group('canPinMessageInChannel', () {
    test('returns true in DMs', () {
      expect(canPinMessageInChannel(isDmChannel: true), isTrue);
    });

    test('returns true with explicit pinMessages bit', () {
      expect(
        canPinMessageInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.pinMessages]),
        ),
        isTrue,
      );
    });

    test('returns true with manageMessages override', () {
      expect(
        canPinMessageInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.manageMessages]),
        ),
        isTrue,
      );
    });

    test('returns false with neither bit', () {
      expect(
        canPinMessageInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.sendMessages]),
        ),
        isFalse,
      );
    });

    test('returns false when guild bits are null', () {
      expect(canPinMessageInChannel(isDmChannel: false), isFalse);
    });
  });

  group('canAddReactionsInChannel', () {
    test('returns true in DMs', () {
      expect(canAddReactionsInChannel(isDmChannel: true), isTrue);
    });

    test('returns true with addReactions bit', () {
      expect(
        canAddReactionsInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.addReactions]),
        ),
        isTrue,
      );
    });

    test('returns false without addReactions bit', () {
      expect(
        canAddReactionsInChannel(
          isDmChannel: false,
          channelPermissionBits: _bits([Permission.sendMessages]),
        ),
        isFalse,
      );
    });

    test('returns false when guild bits are null', () {
      expect(canAddReactionsInChannel(isDmChannel: false), isFalse);
    });
  });

  group('canSuppressEmbedsOnMessage', () {
    test('own user message with embeds: true', () {
      final m = _domainMessage(embeds: [_imageEmbed()]);
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: true,
          isDmChannel: false,
          canDelete: true,
        ),
        isTrue,
      );
    });

    test('own user message already suppressed and no embeds: still true', () {
      final m = _domainMessage(flags: messageFlagSuppressEmbeds);
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: true,
          isDmChannel: false,
          canDelete: false,
        ),
        isTrue,
      );
    });

    test('system message (type=4): false', () {
      final m = _domainMessage(type: 4, embeds: [_imageEmbed()]);
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: true,
          isDmChannel: false,
          canDelete: true,
        ),
        isFalse,
      );
    });

    test('moderator in guild with embeds on peer message: true', () {
      final m = _domainMessage(
        authorId: 'someone-else',
        embeds: [_imageEmbed()],
      );
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: false,
          isDmChannel: false,
          canDelete: true,
        ),
        isTrue,
      );
    });

    test('non-author without delete permission: false', () {
      final m = _domainMessage(
        authorId: 'someone-else',
        embeds: [_imageEmbed()],
      );
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: false,
          isDmChannel: false,
          canDelete: false,
        ),
        isFalse,
      );
    });

    test('non-author in DM even with canDelete: false', () {
      final m = _domainMessage(
        authorId: 'someone-else',
        embeds: [_imageEmbed()],
      );
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: false,
          isDmChannel: true,
          canDelete: true,
        ),
        isFalse,
      );
    });

    test('no embeds and not suppressed: false (nothing to toggle)', () {
      final m = _domainMessage();
      expect(
        canSuppressEmbedsOnMessage(
          message: m,
          isOwnMessage: true,
          isDmChannel: false,
          canDelete: true,
        ),
        isFalse,
      );
    });
  });

  group('Message.isUserMessage', () {
    test('default text', () {
      expect(_domainMessage().isUserMessage, isTrue);
    });

    test('reply (type 19)', () {
      expect(_domainMessage(type: messageTypeReply).isUserMessage, isTrue);
      expect(
        _domainMessage(type: messageTypeReply).supportsInteractiveActions,
        isTrue,
      );
      expect(
        _domainMessage(type: messageTypeReply).isClientSystemMessage,
        isFalse,
      );
    });

    test('client system (type 99)', () {
      expect(
        _domainMessage(type: messageTypeClientSystem).isUserMessage,
        isTrue,
      );
      expect(
        _domainMessage(type: messageTypeClientSystem).isClientSystemMessage,
        isTrue,
      );
      expect(
        _domainMessage(
          type: messageTypeClientSystem,
        ).supportsInteractiveActions,
        isFalse,
      );
    });

    test('system kinds are not user messages', () {
      expect(
        _domainMessage(type: messageTypeRecipientAdd).isUserMessage,
        isFalse,
      );
      expect(_domainMessage(type: messageTypeCall).isUserMessage, isFalse);
      expect(
        _domainMessage(type: messageTypeChannelPinnedMessage).isUserMessage,
        isFalse,
      );
      expect(_domainMessage(type: messageTypeUserJoin).isUserMessage, isFalse);
    });
  });
}
