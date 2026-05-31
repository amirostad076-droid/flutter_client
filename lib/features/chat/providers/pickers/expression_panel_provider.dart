import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expression_panel_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpressionPanel extends _$ExpressionPanel {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

@Riverpod(keepAlive: true)
class PendingEmojiInsert extends _$PendingEmojiInsert {
  @override
  ({String name, String surrogates})? build() => null;

  void emit(String name, String surrogates) =>
      state = (name: name, surrogates: surrogates);

  void consume() => state = null;
}

final NotifierProvider<PendingGifSelection, FluxerSelectedGif?>
pendingGifSelectionProvider =
    NotifierProvider<PendingGifSelection, FluxerSelectedGif?>(
      PendingGifSelection.new,
    );

class PendingGifSelection extends Notifier<FluxerSelectedGif?> {
  @override
  FluxerSelectedGif? build() => null;

  // GIF selections are transient events, matching PendingEmojiInsert above.
  // ignore: use_setters_to_change_properties
  void emit(FluxerSelectedGif selection) => state = selection;

  void consume() => state = null;
}

final NotifierProvider<PendingStickerSelection, StickerEntry?>
pendingStickerSelectionProvider =
    NotifierProvider<PendingStickerSelection, StickerEntry?>(
      PendingStickerSelection.new,
    );

class PendingStickerSelection extends Notifier<StickerEntry?> {
  @override
  StickerEntry? build() => null;

  // Sticker selections are transient events, matching GIF selections.
  // ignore: use_setters_to_change_properties
  void emit(StickerEntry selection) => state = selection;

  void consume() => state = null;
}

final NotifierProvider<PendingFavoriteMemeSelection, FavoriteMemeSelection?>
pendingFavoriteMemeSelectionProvider =
    NotifierProvider<PendingFavoriteMemeSelection, FavoriteMemeSelection?>(
      PendingFavoriteMemeSelection.new,
    );

class PendingFavoriteMemeSelection extends Notifier<FavoriteMemeSelection?> {
  @override
  FavoriteMemeSelection? build() => null;

  // Saved media selections are transient events, matching GIF selections.
  // ignore: use_setters_to_change_properties
  void emit(FavoriteMemeSelection selection) => state = selection;

  void consume() => state = null;
}
