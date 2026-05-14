import 'package:fluxer_app/features/members/domain/member.dart';

class ParsedMentionQuery {
  const ParsedMentionQuery({
    required this.usernameQuery,
    required this.tagQuery,
    required this.hasTagSeparator,
  });

  final String usernameQuery;
  final String? tagQuery;
  final bool hasTagSeparator;
}

ParsedMentionQuery parseMentionQuery(String query) {
  final int hashIndex = query.indexOf('#');
  if (hashIndex == -1) {
    return ParsedMentionQuery(
      usernameQuery: query,
      tagQuery: null,
      hasTagSeparator: false,
    );
  }
  return ParsedMentionQuery(
    usernameQuery: query.substring(0, hashIndex),
    tagQuery: query.substring(hashIndex + 1),
    hasTagSeparator: true,
  );
}

String memberDisplayLabel(Member member) => member.displayName;

bool memberMatchesMentionQuery(
  Member member,
  ParsedMentionQuery parsed,
  String? discriminator,
) {
  final String trimmedUsername = parsed.usernameQuery.trim();
  final String disc = discriminator ?? '0';
  if (parsed.hasTagSeparator) {
    final String uq = parsed.usernameQuery.toLowerCase();
    final String tq = (parsed.tagQuery ?? '').toLowerCase();
    final String nick = (member.nickname ?? '').toLowerCase();
    final String un = member.username.toLowerCase();
    final String gn = (member.globalName ?? '').toLowerCase();
    final bool matchesUsername = uq.isEmpty ||
        un.startsWith(uq) ||
        gn.startsWith(uq) ||
        nick.startsWith(uq);
    final bool matchesTag = tq.isEmpty || disc.toLowerCase().startsWith(tq);
    return matchesUsername && matchesTag;
  }
  if (trimmedUsername.isEmpty) {
    return true;
  }
  final String q = trimmedUsername.toLowerCase();
  final String haystack =
      '${memberDisplayLabel(member)} ${member.username} ${member.globalName ?? ''}'
          .toLowerCase();
  return haystack.contains(q);
}

int _memberSortKey(Member a, Member b) => memberDisplayLabel(a)
    .toLowerCase()
    .compareTo(memberDisplayLabel(b).toLowerCase());

List<Member> rankMembersForMentionQuery(
  List<Member> members,
  ParsedMentionQuery parsed, {
  required int limit,
  Map<String, String>? discriminatorByUserId,
  Set<String>? prioritizeMemberIds,
}) {
  final List<Member> filtered = members
      .where(
        (Member m) => memberMatchesMentionQuery(
          m,
          parsed,
          discriminatorByUserId?[m.id],
        ),
      )
      .toList();
  final Set<String> prefer = prioritizeMemberIds ?? const <String>{};
  if (prefer.isEmpty) {
    filtered.sort(_memberSortKey);
  } else {
    int compare(Member a, Member b) {
      final bool pa = prefer.contains(a.id);
      final bool pb = prefer.contains(b.id);
      if (pa != pb) {
        return pa ? -1 : 1;
      }
      return _memberSortKey(a, b);
    }
    filtered.sort(compare);
  }
  if (filtered.length <= limit) {
    return filtered;
  }
  return filtered.sublist(0, limit);
}
