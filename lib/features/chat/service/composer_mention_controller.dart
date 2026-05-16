import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_inline_mention.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/composer_mention_query.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/providers/member_list_view_model.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';

/// One code unit per user mention. Maps entries in [mentionUserIds] to the
/// outgoing user mention wire form (see [ComposerMentionController.toWireText]).
const int _kUserMentionPlaceholderCodeUnit = 0xfffc;

/// One code unit per channel mention. Maps entries in [mentionChannelIds] to
/// the outgoing channel mention wire form (see
/// [ComposerMentionController.toWireText]).
const int _kChannelMentionPlaceholderCodeUnit = 0xfffa;

/// One code unit per role mention. Maps entries in [mentionRoleIds] and
/// [mentionRoleLabels] to the outgoing role mention wire form (see
/// [ComposerMentionController.toWireText]).
const int _kRoleMentionPlaceholderCodeUnit = 0xfffb;

String _userPlaceholderChar() =>
    String.fromCharCode(_kUserMentionPlaceholderCodeUnit);

String _channelPlaceholderChar() =>
    String.fromCharCode(_kChannelMentionPlaceholderCodeUnit);

String _rolePlaceholderChar() =>
    String.fromCharCode(_kRoleMentionPlaceholderCodeUnit);

String _shortMentionWireIdFallback(String userId) {
  if (userId.length <= 10) {
    return userId;
  }
  return '${userId.substring(0, 8)}…';
}

String _composerMentionUserLabel(WidgetRef ref, String userId) {
  final String channelId = ref.read(chatViewModelProvider).channelId;
  if (channelId.isEmpty) {
    return _shortMentionWireIdFallback(userId);
  }
  final DmViewState dmState = ref.read(dmViewModelProvider);
  final DmConversation? dm = findDmById(dmState.conversations, channelId);
  if (dm != null && userId == dm.recipientId) {
    return dm.recipientName;
  }
  final ChannelListState listState = ref.read(channelListViewModelProvider);
  final Channel? ch = findChannelById(listState, channelId);
  final String? guildId = ch?.guildId;
  if (guildId != null && guildId.isNotEmpty) {
    final MemberListViewState roster = ref.read(memberListViewModelProvider);
    for (final RoleGroup g in roster.roleGroups) {
      for (final Member m in g.members) {
        if (m.id == userId) {
          return memberDisplayLabel(m);
        }
      }
    }
  }
  return _shortMentionWireIdFallback(userId);
}

String _composerMentionChannelLabel(WidgetRef ref, String targetChannelId) {
  final ChannelListState listState = ref.read(channelListViewModelProvider);
  final Channel? ch = findChannelById(listState, targetChannelId);
  return ch?.name ?? _shortMentionWireIdFallback(targetChannelId);
}

/// Renders user, channel, and role mentions as inline text while [toWireText]
/// preserves wire forms for sending.
class ComposerMentionController extends TextEditingController {
  ComposerMentionController({required WidgetRef ref, super.text}) : _ref = ref;

  final WidgetRef _ref;

  final List<String> mentionUserIds = <String>[];
  final List<String> mentionChannelIds = <String>[];
  final List<String> mentionRoleIds = <String>[];
  final List<String> mentionRoleLabels = <String>[];
  final List<int?> mentionRoleColorsArgb = <int?>[];

  static final RegExp _wireMentions = RegExp(
    '<@&([^>]+)>|<@!?([^>]+)>|<#([^>]+)>',
  );

  int _countUserPlaceholders(String t) {
    int n = 0;
    for (int i = 0; i < t.length; i++) {
      if (t.codeUnitAt(i) == _kUserMentionPlaceholderCodeUnit) {
        n++;
      }
    }
    return n;
  }

  int _countChannelPlaceholders(String t) {
    int n = 0;
    for (int i = 0; i < t.length; i++) {
      if (t.codeUnitAt(i) == _kChannelMentionPlaceholderCodeUnit) {
        n++;
      }
    }
    return n;
  }

  int _countRolePlaceholders(String t) {
    int n = 0;
    for (int i = 0; i < t.length; i++) {
      if (t.codeUnitAt(i) == _kRoleMentionPlaceholderCodeUnit) {
        n++;
      }
    }
    return n;
  }

  void _syncMentionIdsToText(String newText) {
    final String uPh = _userPlaceholderChar();
    final String cPh = _channelPlaceholderChar();
    final String rPh = _rolePlaceholderChar();
    while (mentionUserIds.length > _countUserPlaceholders(newText)) {
      mentionUserIds.removeLast();
    }
    while (mentionChannelIds.length > _countChannelPlaceholders(newText)) {
      mentionChannelIds.removeLast();
    }
    while (mentionRoleIds.length > _countRolePlaceholders(newText)) {
      mentionRoleIds.removeLast();
      if (mentionRoleLabels.isNotEmpty) {
        mentionRoleLabels.removeLast();
      }
      if (mentionRoleColorsArgb.isNotEmpty) {
        mentionRoleColorsArgb.removeLast();
      }
    }
    String fixed = newText;
    while (_countUserPlaceholders(fixed) > mentionUserIds.length) {
      final int i = fixed.lastIndexOf(uPh);
      if (i < 0) {
        break;
      }
      fixed = fixed.replaceRange(i, i + uPh.length, '');
    }
    while (_countChannelPlaceholders(fixed) > mentionChannelIds.length) {
      final int i = fixed.lastIndexOf(cPh);
      if (i < 0) {
        break;
      }
      fixed = fixed.replaceRange(i, i + cPh.length, '');
    }
    while (_countRolePlaceholders(fixed) > mentionRoleIds.length) {
      final int i = fixed.lastIndexOf(rPh);
      if (i < 0) {
        break;
      }
      fixed = fixed.replaceRange(i, i + rPh.length, '');
    }
    if (fixed != newText) {
      final int sel = value.selection.isValid
          ? value.selection.extentOffset.clamp(0, fixed.length)
          : fixed.length;
      super.value = TextEditingValue(
        text: fixed,
        selection: TextSelection.collapsed(offset: sel),
      );
    }
  }

  String toWireText() {
    final StringBuffer buf = StringBuffer();
    final String t = value.text;
    int ui = 0;
    int ci = 0;
    int ri = 0;
    for (int i = 0; i < t.length; i++) {
      final int cu = t.codeUnitAt(i);
      if (cu == _kUserMentionPlaceholderCodeUnit) {
        if (ui < mentionUserIds.length) {
          buf.write('<@${mentionUserIds[ui]}>');
          ui++;
        }
      } else if (cu == _kChannelMentionPlaceholderCodeUnit) {
        if (ci < mentionChannelIds.length) {
          buf.write('<#${mentionChannelIds[ci]}>');
          ci++;
        }
      } else if (cu == _kRoleMentionPlaceholderCodeUnit) {
        if (ri < mentionRoleIds.length) {
          buf.write('<@&${mentionRoleIds[ri]}>');
          ri++;
        }
      } else {
        buf.writeCharCode(cu);
      }
    }
    return buf.toString();
  }

  Future<void> applyWireText(String wire) async {
    if (toWireText() == wire) {
      return;
    }
    final List<String> users = <String>[];
    final List<String> channels = <String>[];
    final List<String> roles = <String>[];
    final List<String> roleLabels = <String>[];
    final List<int?> roleColorsArgb = <int?>[];
    final StringBuffer display = StringBuffer();
    int start = 0;
    final db.FluxerDatabase database = _ref.read(fluxerDatabaseProvider);
    for (final RegExpMatch m in _wireMentions.allMatches(wire)) {
      display.write(wire.substring(start, m.start));
      final String? roleId = m.group(1);
      final String? userId = m.group(2);
      final String? channelId = m.group(3);
      if (roleId != null) {
        display.write(_rolePlaceholderChar());
        roles.add(roleId);
        final db.Role? row = await database.roleDao.getRoleById(roleId);
        roleLabels.add(row?.name ?? _shortMentionWireIdFallback(roleId));
        roleColorsArgb.add(row?.color);
      } else if (userId != null) {
        display.write(_userPlaceholderChar());
        users.add(userId);
      } else if (channelId != null) {
        display.write(_channelPlaceholderChar());
        channels.add(channelId);
      }
      start = m.end;
    }
    display.write(wire.substring(start));
    mentionUserIds
      ..clear()
      ..addAll(users);
    mentionChannelIds
      ..clear()
      ..addAll(channels);
    mentionRoleIds
      ..clear()
      ..addAll(roles);
    mentionRoleLabels
      ..clear()
      ..addAll(roleLabels);
    mentionRoleColorsArgb
      ..clear()
      ..addAll(roleColorsArgb);
    final String next = display.toString();
    value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void insertUserMentionPlaceholder({
    required int matchStart,
    required int matchEnd,
    required String userId,
  }) {
    final String full = text;
    final String before = full.substring(0, matchStart);
    final String after = full.substring(matchEnd);
    final String insert = '${_userPlaceholderChar()} ';
    final int indexBefore = _countUserPlaceholders(before);
    mentionUserIds.insert(indexBefore, userId);
    final String next = '$before$insert$after';
    value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: matchStart + insert.length),
    );
  }

  void insertChannelMentionPlaceholder({
    required int matchStart,
    required int matchEnd,
    required String channelId,
  }) {
    final String full = text;
    final String before = full.substring(0, matchStart);
    final String after = full.substring(matchEnd);
    final String insert = '${_channelPlaceholderChar()} ';
    final int indexBefore = _countChannelPlaceholders(before);
    mentionChannelIds.insert(indexBefore, channelId);
    final String next = '$before$insert$after';
    value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: matchStart + insert.length),
    );
  }

  void insertRoleMentionPlaceholder({
    required int matchStart,
    required int matchEnd,
    required String roleId,
    required String displayName,
    int? colorArgb,
  }) {
    final String full = text;
    final String before = full.substring(0, matchStart);
    final String after = full.substring(matchEnd);
    final String insert = '${_rolePlaceholderChar()} ';
    final int indexBefore = _countRolePlaceholders(before);
    mentionRoleIds.insert(indexBefore, roleId);
    mentionRoleLabels.insert(indexBefore, displayName);
    mentionRoleColorsArgb.insert(indexBefore, colorArgb);
    final String next = '$before$insert$after';
    value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: matchStart + insert.length),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _syncMentionIdsToText(newValue.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed &&
        value.isComposingRangeValid) {
      final TextStyle? composingStyle = style?.merge(
        const TextStyle(decoration: TextDecoration.underline),
      );
      return TextSpan(
        style: style,
        children: <TextSpan>[
          TextSpan(text: value.composing.textBefore(value.text)),
          TextSpan(
            style: composingStyle,
            text: value.text.substring(
              value.composing.start,
              value.composing.end,
            ),
          ),
          TextSpan(text: value.composing.textAfter(value.text)),
        ],
      );
    }
    final String t = value.text;
    if (t.isEmpty) {
      return TextSpan(style: style, text: '');
    }
    final List<InlineSpan> children = <InlineSpan>[];
    int i = 0;
    int userIdx = 0;
    int channelIdx = 0;
    int roleIdx = 0;
    while (i < t.length) {
      final int cu = t.codeUnitAt(i);
      if (cu == _kUserMentionPlaceholderCodeUnit) {
        final String userId = userIdx < mentionUserIds.length
            ? mentionUserIds[userIdx]
            : '';
        userIdx++;
        final String label = userId.isEmpty
            ? '?'
            : _composerMentionUserLabel(_ref, userId);
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ComposerInlineMention(
              visibleText: '@$label',
              baseStyle: style,
            ),
          ),
        );
        i += 1;
      } else if (cu == _kChannelMentionPlaceholderCodeUnit) {
        final String channelId = channelIdx < mentionChannelIds.length
            ? mentionChannelIds[channelIdx]
            : '';
        channelIdx++;
        final String name = channelId.isEmpty
            ? '?'
            : _composerMentionChannelLabel(_ref, channelId);
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ComposerInlineMention(
              visibleText: '#$name',
              baseStyle: style,
            ),
          ),
        );
        i += 1;
      } else if (cu == _kRoleMentionPlaceholderCodeUnit) {
        final String label = roleIdx < mentionRoleLabels.length
            ? mentionRoleLabels[roleIdx]
            : '?';
        final int? colorArgb = roleIdx < mentionRoleColorsArgb.length
            ? mentionRoleColorsArgb[roleIdx]
            : null;
        roleIdx++;
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ComposerInlineMention(
              visibleText: '@$label',
              baseStyle: style,
              foregroundArgb: colorArgb,
            ),
          ),
        );
        i += 1;
      } else {
        final int start = i;
        while (i < t.length) {
          final int c = t.codeUnitAt(i);
          if (c == _kUserMentionPlaceholderCodeUnit ||
              c == _kChannelMentionPlaceholderCodeUnit ||
              c == _kRoleMentionPlaceholderCodeUnit) {
            break;
          }
          i++;
        }
        children.add(TextSpan(text: t.substring(start, i), style: style));
      }
    }
    return TextSpan(style: style, children: children);
  }
}
