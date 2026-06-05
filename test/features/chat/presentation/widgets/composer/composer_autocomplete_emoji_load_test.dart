import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_chat_field.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:riverpod/src/framework.dart' show Override;

const String _channelId = 'general';
const String _guildId = 'guild_1';

class _FakeChannelList extends ChannelListViewModel {
  @override
  ChannelListState build() => const ChannelListState(
    guild: null,
    categories: <ChannelCategory>[
      ChannelCategory(
        id: 'cat',
        name: 'cat',
        channels: <Channel>[
          Channel(id: _channelId, guildId: _guildId, name: 'general'),
        ],
      ),
    ],
    selectedChannelId: null,
    collapsedCategories: <String>{},
  );
}

List<String> _rowTitles(ComposerAutocompletePanelHost host) =>
    host.value?.rows
        .map((ComposerAutocompletePanelRow r) => r.title)
        .toList() ??
    <String>[];

void main() {
  testWidgets(
    'custom guild emoji surface in colon autocomplete once their stream loads',
    (tester) async {
      final StreamController<List<GuildEmojiEntry>> emojis =
          StreamController<List<GuildEmojiEntry>>();
      addTearDown(emojis.close);

      final TextEditingController textController = TextEditingController();
      final FocusNode focusNode = FocusNode();
      final ComposerAutocompletePanelHost panelHost =
          ComposerAutocompletePanelHost(null);
      final ComposerAutocompleteMenuNotifier menuOpen =
          ComposerAutocompleteMenuNotifier(false);
      final ScrollController panelScroll = ScrollController();

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            channelListViewModelProvider.overrideWith(_FakeChannelList.new),
            guildEmojisForPickerProvider(
              _guildId,
            ).overrideWith((ref) => emojis.stream),
          ],
          child: MaterialApp(
            localizationsDelegates: FluxerLocalizations.localizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            home: Scaffold(
              body: ComposerAutocompleteChatField(
                controller: textController,
                focusNode: focusNode,
                channelId: _channelId,
                decoration: const InputDecoration(),
                style: const TextStyle(),
                minLines: 1,
                maxLines: 6,
                enabled: true,
                menuOpenListenable: menuOpen,
                panelHost: panelHost,
                panelScrollController: panelScroll,
              ),
            ),
          ),
        ),
      );

      // Type a colon query before the guild emoji stream has emitted.
      textController.value = const TextEditingValue(
        text: ':party',
        selection: TextSelection.collapsed(offset: 6),
      );
      // Past the typing debounce; the stream is still pending so no custom
      // emoji can be listed yet.
      await tester.pump(const Duration(milliseconds: 350));
      expect(_rowTitles(panelHost), isNot(contains(':partyblob:')));

      // The guild's custom emoji resolve after the trigger already fired.
      emojis.add(<GuildEmojiEntry>[
        GuildEmojiEntry(
          id: 'e1',
          name: 'partyblob',
          animated: false,
          guildId: _guildId,
        ),
      ]);
      await tester.pump();
      await tester.pump();

      final ComposerAutocompletePanelSnapshot? snapshot = panelHost.value;
      expect(snapshot, isNotNull);
      final ComposerAutocompletePanelRow row = snapshot!.rows.firstWhere(
        (ComposerAutocompletePanelRow r) => r.title == ':partyblob:',
        orElse: () => throw StateError('custom emoji row missing'),
      );
      expect(row.emojiImageUrl, isNotNull);
      expect(row.emojiSurrogates, isNull);
    },
  );
}
