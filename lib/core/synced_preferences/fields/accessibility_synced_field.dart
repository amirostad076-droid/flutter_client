import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_field_adapter.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/accessibility.pb.dart'
    as pb;
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as prefs;
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class AccessibilityLocalState {
  const AccessibilityLocalState({
    required this.hideKeyboardHints,
    required this.channelTypingIndicatorMode,
    required this.showSelectedChannelTypingIndicator,
    required this.showFadedUnreadOnMutedChannels,
    required this.showFavorites,
  });

  final bool hideKeyboardHints;
  final ChannelTypingIndicatorMode channelTypingIndicatorMode;
  final bool showSelectedChannelTypingIndicator;
  final bool showFadedUnreadOnMutedChannels;
  final bool showFavorites;
}

class AccessibilitySyncedField
    extends SyncedFieldAdapter<AccessibilityLocalState> {
  AccessibilitySyncedField(this._ref);

  final Ref _ref;

  @override
  SyncedPreferenceField get field => SyncedPreferenceField.accessibility;

  @override
  AccessibilityLocalState readLocal() {
    final appearance = _ref.read(appearancePreferencesProvider);
    return AccessibilityLocalState(
      hideKeyboardHints: appearance.hideKeyboardHints,
      channelTypingIndicatorMode: appearance.channelTypingIndicatorMode,
      showSelectedChannelTypingIndicator:
          appearance.showSelectedChannelTypingIndicator,
      showFadedUnreadOnMutedChannels: appearance.showFadedUnreadOnMutedChannels,
      showFavorites: appearance.showFavorites,
    );
  }

  @override
  Future<void> applyRemote(AccessibilityLocalState value) async {
    final notifier = _ref.read(appearancePreferencesProvider.notifier);
    await notifier.applySyncedAccessibility(value);
  }

  @override
  AccessibilityLocalState? readFromProto(prefs.SyncedPreferences message) {
    if (!message.hasAccessibility()) {
      return null;
    }
    return fromProto(message.accessibility);
  }

  @override
  $pb.GeneratedMessage toProtoMessage(AccessibilityLocalState local) {
    return toProto(local);
  }

  @override
  bool statesEqual(AccessibilityLocalState a, AccessibilityLocalState b) {
    return a.hideKeyboardHints == b.hideKeyboardHints &&
        a.channelTypingIndicatorMode == b.channelTypingIndicatorMode &&
        a.showSelectedChannelTypingIndicator ==
            b.showSelectedChannelTypingIndicator &&
        a.showFadedUnreadOnMutedChannels == b.showFadedUnreadOnMutedChannels &&
        a.showFavorites == b.showFavorites;
  }

  @override
  AccessibilityLocalState mergeForMigration({
    required AccessibilityLocalState local,
    required AccessibilityLocalState remote,
  }) {
    return AccessibilityLocalState(
      hideKeyboardHints: local.hideKeyboardHints,
      channelTypingIndicatorMode: local.channelTypingIndicatorMode,
      showSelectedChannelTypingIndicator:
          local.showSelectedChannelTypingIndicator,
      showFadedUnreadOnMutedChannels: local.showFadedUnreadOnMutedChannels,
      showFavorites: local.showFavorites,
    );
  }

  @override
  bool verifyRoundtrip(AccessibilityLocalState candidate) {
    final roundtripped = fromProto(toProto(candidate));
    return statesEqual(candidate, roundtripped);
  }

  static AccessibilityLocalState fromProto(pb.AccessibilitySettings proto) {
    return AccessibilityLocalState(
      hideKeyboardHints: proto.hideKeyboardHints,
      channelTypingIndicatorMode: _fromProtoTypingMode(
        proto.channelTypingIndicatorMode,
      ),
      showSelectedChannelTypingIndicator:
          proto.hasShowSelectedChannelTypingIndicator() &&
          proto.showSelectedChannelTypingIndicator,
      showFadedUnreadOnMutedChannels:
          proto.hasShowFadedUnreadOnMutedChannels() &&
          proto.showFadedUnreadOnMutedChannels,
      showFavorites: !proto.hasShowFavorites() || proto.showFavorites,
    );
  }

  static pb.AccessibilitySettings toProto(AccessibilityLocalState local) {
    return pb.AccessibilitySettings(
      hideKeyboardHints: local.hideKeyboardHints,
      channelTypingIndicatorMode: _toProtoTypingMode(
        local.channelTypingIndicatorMode,
      ),
      showSelectedChannelTypingIndicator:
          local.showSelectedChannelTypingIndicator,
      showFadedUnreadOnMutedChannels: local.showFadedUnreadOnMutedChannels,
      showFavorites: local.showFavorites,
    );
  }

  static ChannelTypingIndicatorMode _fromProtoTypingMode(
    pb.ChannelTypingIndicatorMode mode,
  ) {
    return switch (mode) {
      pb.ChannelTypingIndicatorMode.CHANNEL_TYPING_INDICATOR_MODE_HIDDEN =>
        ChannelTypingIndicatorMode.hidden,
      pb
          .ChannelTypingIndicatorMode
          .CHANNEL_TYPING_INDICATOR_MODE_INDICATOR_ONLY =>
        ChannelTypingIndicatorMode.indicatorOnly,
      _ => ChannelTypingIndicatorMode.avatars,
    };
  }

  static pb.ChannelTypingIndicatorMode _toProtoTypingMode(
    ChannelTypingIndicatorMode mode,
  ) {
    return switch (mode) {
      ChannelTypingIndicatorMode.hidden =>
        pb.ChannelTypingIndicatorMode.CHANNEL_TYPING_INDICATOR_MODE_HIDDEN,
      ChannelTypingIndicatorMode.indicatorOnly =>
        pb
            .ChannelTypingIndicatorMode
            .CHANNEL_TYPING_INDICATOR_MODE_INDICATOR_ONLY,
      ChannelTypingIndicatorMode.avatars =>
        pb.ChannelTypingIndicatorMode.CHANNEL_TYPING_INDICATOR_MODE_AVATARS,
    };
  }
}
