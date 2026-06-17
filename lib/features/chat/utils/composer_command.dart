import 'package:fluxer_app/features/chat/domain/message.dart';

/// Threshold above which mentioning `@everyone`/`@here` asks for confirmation.
/// Mirrors the web app's `MENTION_EVERYONE_THRESHOLD` (production value).
const int kMentionConfirmThreshold = 50;

/// A parsed composer submission. Mirrors the web app's client-side command
/// layer (`CommandUtils.parseCommand` + `ReplaceCommandUtils`).
sealed class ComposerCommand {
  const ComposerCommand();
}

/// Normal message content. Also covers any unrecognized `/command`, which is
/// sent verbatim (matching the web app).
class ComposerContentSend extends ComposerCommand {
  const ComposerContentSend(this.content);

  final String content;
}

/// `/me <content>` — italicised action text.
class ComposerMeCommand extends ComposerCommand {
  const ComposerMeCommand(this.content);

  final String content;
}

/// `/spoiler <content>` — content wrapped in a spoiler.
class ComposerSpoilerCommand extends ComposerCommand {
  const ComposerSpoilerCommand(this.content);

  final String content;
}

/// `/tts <content>` — text-to-speech message.
class ComposerTtsCommand extends ComposerCommand {
  const ComposerTtsCommand(this.content);

  final String content;
}

/// `s/<source>/<replacement>[/g]` — edits the last own message in place.
class ComposerReplaceCommand extends ComposerCommand {
  const ComposerReplaceCommand({
    required this.source,
    required this.replacement,
    required this.global,
  });

  final String source;
  final String replacement;
  final bool global;
}

final RegExp _replaceCommandRegex = RegExp(r'^s/(.+?)/(.*?)(?:/(g)?)?$');

/// Parses [wireText] (the composer's wire representation) into a
/// [ComposerCommand]. Pure; intended to be called exactly once per send.
ComposerCommand parseComposerCommand(String wireText) {
  final String trimmed = wireText.trim();

  final RegExpMatch? replace = _replaceCommandRegex.firstMatch(trimmed);
  if (replace != null) {
    final String source = replace.group(1) ?? '';
    if (source.isNotEmpty) {
      return ComposerReplaceCommand(
        source: source,
        replacement: replace.group(2) ?? '',
        global: replace.group(3) != null,
      );
    }
  }

  final String? me = _commandArg(trimmed, '/me ');
  if (me != null) {
    return ComposerMeCommand(me);
  }
  final String? spoiler = _commandArg(trimmed, '/spoiler ');
  if (spoiler != null) {
    return ComposerSpoilerCommand(spoiler);
  }
  final String? tts = _commandArg(trimmed, '/tts ');
  if (tts != null) {
    return ComposerTtsCommand(tts);
  }

  return ComposerContentSend(wireText);
}

String? _commandArg(String trimmed, String prefix) {
  if (!trimmed.startsWith(prefix)) {
    return null;
  }
  final String rest = trimmed.substring(prefix.length).trim();
  return rest.isEmpty ? null : rest;
}

/// `/me x` → `_x_` (web `transformWrappingCommands`).
String wrapMe(String content) => '_${content}_';

/// `/spoiler x` → `||x||` (web `transformWrappingCommands`).
String wrapSpoiler(String content) => '||$content||';

final RegExp _regexSpecialChars = RegExp(r'[.*+?^${}()|\[\]\\]');

/// Applies a parsed replace [cmd] to [text] (web `executeReplaceCommand`).
/// [ComposerReplaceCommand.source] is treated as a literal (regex-escaped);
/// the replacement is inserted literally (no `$`-capture interpretation, since
/// Dart's `String` replace overloads do not interpret `$`).
String executeReplace(String text, ComposerReplaceCommand cmd) {
  final String escaped = cmd.source.replaceAllMapped(
    _regexSpecialChars,
    (Match m) => '\\${m[0]}',
  );
  final RegExp pattern = RegExp(escaped);
  return cmd.global
      ? text.replaceAll(pattern, cmd.replacement)
      : text.replaceFirst(pattern, cmd.replacement);
}

/// Strips a leading `@silent ` prefix, returning the remaining content and the
/// message flags to apply (web `removeSilentFlag` + `getMessageFlags`).
({String content, int flags}) stripSilentPrefix(String content) {
  const String prefix = '@silent ';
  if (content.startsWith(prefix)) {
    return (
      content: content.substring(prefix.length),
      flags: messageFlagSuppressNotifications,
    );
  }
  return (content: content, flags: 0);
}
