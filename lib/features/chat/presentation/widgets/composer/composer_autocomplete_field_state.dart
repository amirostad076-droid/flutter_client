part of 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_chat_field.dart';

const int _kMentionLimit = 100;
const int _kRoleMentionLimit = 10;
const int _kChannelLimit = 10;
const int _kEmojiLimit = 10;
const int _kGatewayMentionChunkWaitMs = 280;
const int _kAutocompleteTypingDebounceMs = 300;

String _composerMentionAutocompleteRightLabel(
  Member member,
  Map<String, String>? discriminatorByUserId,
) {
  final String? disc = discriminatorByUserId?[member.id];
  final String username = member.username;
  if (disc != null && disc.isNotEmpty && disc != '0') {
    return '$username#$disc';
  }
  return username;
}

class _ComposerRow {
  _ComposerRow({
    required this.title,
    required this.onApply,
    this.subtitle,
    this.mentionMember,
    this.titleColor,
    this.channelRowType,
  });

  final String title;
  final VoidCallback onApply;
  final String? subtitle;
  final Member? mentionMember;
  final Color? titleColor;
  final ChannelType? channelRowType;
}

class ComposerAutocompleteChatFieldState
    extends ConsumerState<ComposerAutocompleteChatField> {
  final List<_ComposerRow> _rows = <_ComposerRow>[];
  int _selectedIndex = 0;
  int _syncGeneration = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      _setRows(const <_ComposerRow>[]);
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: _kAutocompleteTypingDebounceMs),
      _scheduleSync,
    );
  }

  void _scheduleSync() {
    if (!mounted) {
      return;
    }
    final int gen = ++_syncGeneration;
    unawaited(_sync(gen));
  }

  Future<void> _sync(int generation) async {
    final TextSelection sel = widget.controller.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      if (generation == _syncGeneration) {
        _setRows(const <_ComposerRow>[]);
      }
      return;
    }
    final String full = widget.controller.text;
    final int caret = sel.baseOffset;
    final ComposerAutocompleteTrigger? trigger =
        ComposerAutocompleteTrigger.detectIfAllowed(
          fullText: full,
          caretIndex: caret,
        );
    if (generation != _syncGeneration) {
      return;
    }
    if (trigger == null) {
      _setRows(const <_ComposerRow>[]);
      return;
    }
    switch (trigger.kind) {
      case ComposerAutocompleteTriggerKind.emojiReaction:
        _setRows(const <_ComposerRow>[]);
        return;
      case ComposerAutocompleteTriggerKind.channel:
        await _syncChannels(trigger, generation);
        return;
      case ComposerAutocompleteTriggerKind.mention:
        await _syncMention(trigger, generation);
        return;
      case ComposerAutocompleteTriggerKind.emoji:
        _syncEmoji(trigger, generation);
        return;
    }
  }

  Future<int> _effectiveChannelBits() async {
    if (widget.channelId.isEmpty) {
      return 0;
    }
    final bool isDm = ref.read(
      dmViewModelProvider.select(
        (DmViewState s) =>
            findDmById(s.conversations, widget.channelId) != null,
      ),
    );
    if (isDm) {
      return allPermissions;
    }
    return ref.read(
      effectiveGuildChannelPermissionBitsProvider(widget.channelId).future,
    );
  }

  Channel? _guildChannel() {
    final ChannelListState list = ref.read(channelListViewModelProvider);
    return findChannelById(list, widget.channelId);
  }

  Future<void> _syncChannels(
    ComposerAutocompleteTrigger trigger,
    int generation,
  ) async {
    final Channel? ch = _guildChannel();
    final String? guildId = ch?.guildId;
    if (guildId == null || guildId.isEmpty) {
      _setRows(const <_ComposerRow>[]);
      return;
    }
    final ChannelListState list = ref.read(channelListViewModelProvider);
    final List<Channel> flat = <Channel>[];
    for (final ChannelCategory cat in list.categories) {
      for (final Channel c in cat.channels) {
        if (!c.isCategory) {
          flat.add(c);
        }
      }
    }
    final String q = trigger.matchedText.toLowerCase();
    List<Channel> filtered = flat;
    if (q.isNotEmpty) {
      filtered = flat
          .where((Channel c) => c.name.toLowerCase().contains(q))
          .toList();
    }
    filtered.sort((Channel a, Channel b) => a.position.compareTo(b.position));
    if (filtered.length > _kChannelLimit) {
      filtered = filtered.sublist(0, _kChannelLimit);
    }
    if (generation != _syncGeneration) {
      return;
    }
    _setRows(
      filtered.map((Channel c) {
        return _ComposerRow(
          title: c.name,
          onApply: () => _applyChannel(trigger, c),
          channelRowType: c.type,
        );
      }).toList(),
    );
  }

  Future<void> _syncMention(
    ComposerAutocompleteTrigger trigger,
    int generation,
  ) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final ParsedMentionQuery parsed = parseMentionQuery(trigger.matchedText);
    final ({
      List<Member> members,
      Set<String> remoteSearchMemberIds,
      Set<String> localMemberIds,
    })
    source = await _mentionMemberSource(parsed);
    if (generation != _syncGeneration) {
      return;
    }
    final Map<String, String>? discs = await _discriminatorsFor(source.members);
    if (generation != _syncGeneration) {
      return;
    }
    List<Member> ranked = rankMembersForMentionQuery(
      source.members,
      parsed,
      limit: _kMentionLimit,
      discriminatorByUserId: discs,
      prioritizeMemberIds: source.remoteSearchMemberIds,
    );
    final Channel? ch = _guildChannel();
    final String? guildId = ch?.guildId;
    if (guildId != null && guildId.isNotEmpty) {
      final Set<String> assumeVisibleForUserIds = source.remoteSearchMemberIds
          .difference(source.localMemberIds);
      ranked = await filterMembersByViewChannel(
        database: ref.read(fluxerDatabaseProvider),
        channelId: widget.channelId,
        guildId: guildId,
        members: ranked,
        assumeVisibleForUserIds: assumeVisibleForUserIds,
      );
    }
    if (generation != _syncGeneration) {
      return;
    }
    final List<_ComposerRow> rows = ranked
        .map(
          (Member m) => _ComposerRow(
            title: memberDisplayLabel(m),
            subtitle: _composerMentionAutocompleteRightLabel(m, discs),
            onApply: () => _applyUserMention(trigger, m.id),
            mentionMember: m,
          ),
        )
        .toList();
    final int bits = await _effectiveChannelBits();
    if (generation != _syncGeneration) {
      return;
    }
    final bool canMentionEveryone =
        guildId != null &&
        guildId.isNotEmpty &&
        hasPermission(bits, Permission.mentionEveryone);
    final String q = parsed.usernameQuery.trim().toLowerCase();
    if (canMentionEveryone) {
      if (q.isEmpty || 'everyone'.startsWith(q)) {
        rows.add(
          _ComposerRow(
            title: '@everyone',
            onApply: () => _applyLiteralMention(trigger, '@everyone'),
          ),
        );
      }
      if (q.isEmpty || 'here'.startsWith(q)) {
        rows.add(
          _ComposerRow(
            title: '@here',
            onApply: () => _applyLiteralMention(trigger, '@here'),
          ),
        );
      }
    }
    if (guildId != null && guildId.isNotEmpty) {
      final String roleSubtitle =
          l10n.composerAutocompleteRoleMentionDescription;
      final List<db.Role> dbRoles = await ref
          .read(fluxerDatabaseProvider)
          .roleDao
          .getRoles(guildId);
      if (generation != _syncGeneration) {
        return;
      }
      int roleCount = 0;
      for (final db.Role r in dbRoles) {
        if (roleCount >= _kRoleMentionLimit) {
          break;
        }
        if (r.id == guildId) {
          continue;
        }
        if (!(canMentionEveryone || r.mentionable)) {
          continue;
        }
        if (q.isNotEmpty && !r.name.toLowerCase().contains(q)) {
          continue;
        }
        roleCount++;
        final Color? titleColor = (r.color & 0xffffff) == 0
            ? null
            : Color(0xff000000 | (r.color & 0xffffff));
        rows.add(
          _ComposerRow(
            title: '@${r.name}',
            subtitle: roleSubtitle,
            titleColor: titleColor,
            onApply: () => _applyRoleMention(trigger, r.id, r.name, r.color),
          ),
        );
      }
    }
    if (generation != _syncGeneration) {
      return;
    }
    _setRows(rows);
  }

  Future<
    ({
      List<Member> members,
      Set<String> remoteSearchMemberIds,
      Set<String> localMemberIds,
    })
  >
  _mentionMemberSource(ParsedMentionQuery parsed) async {
    final Channel? ch = _guildChannel();
    final String? guildId = ch?.guildId;
    if (guildId != null && guildId.isNotEmpty) {
      ref.read(memberListViewModelProvider.notifier).loadMembers(guildId);
      final MemberListViewState memberState = ref.read(
        memberListViewModelProvider,
      );
      final List<Member> local = memberState.roleGroups
          .expand((RoleGroup g) => g.members)
          .toList();
      final Set<String> localMemberIds = <String>{
        for (final Member m in local) m.id,
      };
      final MemberRepository repo = ref.read(memberRepositoryProvider);
      List<Member> remote = const <Member>[];
      final String searchQuery = parsed.usernameQuery.trim();
      if (searchQuery.isNotEmpty) {
        try {
          ref
              .read(gatewayConnectionProvider)
              .requestGuildMembers(
                guildId: guildId,
                query: searchQuery,
                limit: _kMentionLimit,
              );
          await Future<void>.delayed(
            const Duration(milliseconds: _kGatewayMentionChunkWaitMs),
          );
          remote = await repo.searchMembersForAutocomplete(
            guildId: guildId,
            query: searchQuery,
          );
        } on Object {
          remote = const <Member>[];
        }
      }
      final Set<String> remoteSearchMemberIds = <String>{
        for (final Member m in remote) m.id,
      };
      final Map<String, Member> byId = <String, Member>{};
      for (final Member m in local) {
        byId[m.id] = m;
      }
      for (final Member m in remote) {
        byId.putIfAbsent(m.id, () => m);
      }
      return (
        members: byId.values.toList(),
        remoteSearchMemberIds: remoteSearchMemberIds,
        localMemberIds: localMemberIds,
      );
    }
    final List<DmConversation> dms = ref.read(
      dmViewModelProvider.select((DmViewState s) => s.conversations),
    );
    final DmConversation? dm = findDmById(dms, widget.channelId);
    if (dm == null) {
      return (
        members: const <Member>[],
        remoteSearchMemberIds: <String>{},
        localMemberIds: <String>{},
      );
    }
    if (dm.isGroup) {
      return (
        members: dm.groupMembers
            .map((GroupMemberInfo g) => Member(id: g.id, username: g.name))
            .toList(),
        remoteSearchMemberIds: <String>{},
        localMemberIds: <String>{},
      );
    }
    return (
      members: <Member>[
        Member(
          id: dm.recipientId,
          username: dm.recipientUsername ?? dm.recipientName,
          globalName: dm.recipientName,
          status: dm.recipientStatus,
          isBot: dm.isBot,
        ),
      ],
      remoteSearchMemberIds: <String>{},
      localMemberIds: <String>{},
    );
  }

  Future<Map<String, String>?> _discriminatorsFor(List<Member> members) async {
    if (members.isEmpty) {
      return null;
    }
    final db.FluxerDatabase database = ref.read(fluxerDatabaseProvider);
    final List<String> ids = members.map((Member m) => m.id).toList();
    final List<db.User> users = await database.userDao.getUsersByIds(ids);
    return {for (final db.User u in users) u.id: u.discriminator};
  }

  void _syncEmoji(ComposerAutocompleteTrigger trigger, int generation) {
    final String q = trigger.matchedText.toLowerCase();
    final List<EmojiEntry> unicode = EmojiRegistry.search(
      q,
    ).take(_kEmojiLimit).toList();
    final Channel? ch = _guildChannel();
    final String? guildId = ch?.guildId;
    final List<GuildEmojiEntry> customs = guildId != null && guildId.isNotEmpty
        ? ref.read(guildEmojisForPickerProvider(guildId)).value ??
              const <GuildEmojiEntry>[]
        : const <GuildEmojiEntry>[];
    final List<GuildEmojiEntry> customFiltered = customs
        .where((GuildEmojiEntry e) => e.nameLower.contains(q))
        .take(_kEmojiLimit)
        .toList();
    if (generation != _syncGeneration) {
      return;
    }
    final List<_ComposerRow> rows = <_ComposerRow>[
      ...customFiltered.map(
        (GuildEmojiEntry e) => _ComposerRow(
          title: ':${e.name}:',
          onApply: () => _applyEmoji(trigger, insert: e.markdown),
        ),
      ),
      ...unicode.map(
        (EmojiEntry e) => _ComposerRow(
          title: ':${e.primaryName}:',
          onApply: () => _applyEmoji(trigger, insert: ':${e.primaryName}:'),
        ),
      ),
    ];
    _setRows(rows.take(_kEmojiLimit).toList());
  }

  void _setRows(List<_ComposerRow> next) {
    if (!mounted) {
      return;
    }
    setState(() {
      _rows
        ..clear()
        ..addAll(next);
      _selectedIndex = 0;
    });
    widget.menuOpenListenable.value = next.isNotEmpty;
    _publishPanel();
    if (next.isNotEmpty) {
      _scheduleScrollSelectionIntoView();
    }
  }

  void _publishPanel() {
    if (_rows.isEmpty) {
      widget.panelHost.value = null;
      return;
    }
    final int safeIndex = _selectedIndex.clamp(0, _rows.length - 1);
    widget.panelHost.value = ComposerAutocompletePanelSnapshot(
      rows: _rows.map((_ComposerRow r) {
        final Member? m = r.mentionMember;
        return ComposerAutocompletePanelRow(
          title: r.title,
          subtitle: r.subtitle,
          titleColor: r.titleColor,
          onTap: r.onApply,
          channelRowType: r.channelRowType,
          userAvatarUserId: m?.id,
          userAvatarImageUrl: m?.avatarUrl,
          userAvatarFallbackText: m != null ? memberDisplayLabel(m) : null,
          userAvatarColor: m?.avatarColor,
          userAvatarRoleColor: m?.roleColor,
          userAvatarStatus: m?.status,
        );
      }).toList(),
      selectedIndex: safeIndex,
    );
  }

  void _scheduleScrollSelectionIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.panelScrollController.hasClients) {
        return;
      }
      final ScrollController c = widget.panelScrollController;
      final double offset = (_selectedIndex * _kAutocompleteScrollRowStride)
          .clamp(0.0, c.position.maxScrollExtent);
      unawaited(
        c.animateTo(
          offset,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _replaceTrigger(ComposerAutocompleteTrigger trigger, String inserted) {
    final String full = widget.controller.text;
    final String before = full.substring(0, trigger.matchStart);
    final String after = full.substring(trigger.matchEnd);
    final String spaced = inserted.endsWith(' ') ? inserted : '$inserted ';
    final String next = '$before$spaced$after';
    final int cursor = before.length + spaced.length;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  void _applyUserMention(ComposerAutocompleteTrigger trigger, String userId) {
    if (widget.controller is ComposerMentionController &&
        trigger.kind == ComposerAutocompleteTriggerKind.mention) {
      (widget.controller as ComposerMentionController)
          .insertUserMentionPlaceholder(
            matchStart: trigger.matchStart,
            matchEnd: trigger.matchEnd,
            userId: userId,
          );
      _closeMenu();
      return;
    }
    _replaceTrigger(trigger, '<@$userId>');
    _closeMenu();
  }

  void _applyLiteralMention(ComposerAutocompleteTrigger trigger, String text) {
    _replaceTrigger(trigger, text);
    _closeMenu();
  }

  void _applyRoleMention(
    ComposerAutocompleteTrigger trigger,
    String roleId,
    String displayName,
    int colorArgb,
  ) {
    if (widget.controller is ComposerMentionController &&
        trigger.kind == ComposerAutocompleteTriggerKind.mention) {
      (widget.controller as ComposerMentionController)
          .insertRoleMentionPlaceholder(
            matchStart: trigger.matchStart,
            matchEnd: trigger.matchEnd,
            roleId: roleId,
            displayName: displayName,
            colorArgb: colorArgb,
          );
      _closeMenu();
      return;
    }
    _replaceTrigger(trigger, '<@&$roleId>');
    _closeMenu();
  }

  void _applyChannel(ComposerAutocompleteTrigger trigger, Channel c) {
    if (widget.controller is ComposerMentionController) {
      (widget.controller as ComposerMentionController)
          .insertChannelMentionPlaceholder(
            matchStart: trigger.matchStart,
            matchEnd: trigger.matchEnd,
            channelId: c.id,
          );
      _closeMenu();
      return;
    }
    _replaceTrigger(trigger, '<#${c.id}>');
    _closeMenu();
  }

  void _applyEmoji(
    ComposerAutocompleteTrigger trigger, {
    required String insert,
  }) {
    _replaceTrigger(trigger, insert);
    _closeMenu();
  }

  void _closeMenu() {
    _setRows(const <_ComposerRow>[]);
  }

  void closeAutocompleteMenu() {
    _closeMenu();
  }

  void moveSelection(int delta) {
    if (_rows.isEmpty) {
      return;
    }
    setState(() {
      _selectedIndex = (_selectedIndex + delta + _rows.length) % _rows.length;
    });
    _publishPanel();
    _scheduleScrollSelectionIntoView();
  }

  void applyCurrentSelection() {
    if (_rows.isEmpty) {
      return;
    }
    _rows[_selectedIndex].onApply();
  }

  bool get hasOpenMenu => _rows.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        final bool hasWidth = maxW.isFinite && maxW > 0;
        return SizedBox(
          width: hasWidth ? maxW : null,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            style: widget.style,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: widget.decoration,
            textAlignVertical: widget.textAlignVertical,
          ),
        );
      },
    );
  }
}
