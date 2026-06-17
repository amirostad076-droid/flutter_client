import 'dart:async';

import 'package:fluxer_app/core/providers/gateway_session_recovery_provider.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_event_providers.g.dart';

String _voiceStateStorageKey(VoiceState voiceState) {
  if (voiceState.channelId == null) {
    throw StateError('Storage key is only for in-channel states.');
  }
  if (voiceState.connectionId != null) {
    return voiceState.connectionId!;
  }
  return '_u_${voiceState.userId}_${voiceState.channelId}';
}

List<VoiceState> otherUserConnectionsInChannel({
  required Map<String, VoiceState> voiceStates,
  required String? guildId,
  required String channelId,
  required String currentUserId,
  String? localConnectionId,
}) {
  bool matchesGuild(VoiceState vs) {
    if (guildId == null) {
      return vs.guildId == null;
    }
    return vs.guildId == guildId;
  }

  return voiceStates.values
      .where(
        (VoiceState vs) =>
            vs.channelId == channelId &&
            vs.userId == currentUserId &&
            vs.connectionId != null &&
            vs.connectionId != localConnectionId &&
            matchesGuild(vs),
      )
      .toList();
}

class TypingUser {
  final String userId;
  final String channelId;
  final DateTime expiresAt;

  const TypingUser({
    required this.userId,
    required this.channelId,
    required this.expiresAt,
  });
}

const Duration _kTypingExpiry = Duration(seconds: 10);
const Duration _kTypingCleanupInterval = Duration(seconds: 1);

@Riverpod(keepAlive: true)
class TypingIndicators extends _$TypingIndicators {
  Timer? _cleanupTimer;

  @override
  List<TypingUser> build() {
    _cleanupTimer = Timer.periodic(_kTypingCleanupInterval, (_) => _cleanup());
    ref.onDispose(() => _cleanupTimer?.cancel());
    return const [];
  }

  void addTyping(String channelId, String userId) {
    final expiresAt = DateTime.now().add(_kTypingExpiry);

    state = [
      ...state.where((t) => !(t.channelId == channelId && t.userId == userId)),
      TypingUser(userId: userId, channelId: channelId, expiresAt: expiresAt),
    ];
  }

  void removeTyping(String channelId, String userId) {
    state = state
        .where((t) => !(t.channelId == channelId && t.userId == userId))
        .toList();
  }

  List<TypingUser> typingInChannel(String channelId) {
    final now = DateTime.now();
    return state
        .where((t) => t.channelId == channelId && t.expiresAt.isAfter(now))
        .toList();
  }

  void _cleanup() {
    final now = DateTime.now();
    final updated = state.where((t) => t.expiresAt.isAfter(now)).toList();
    if (updated.length != state.length) {
      state = updated;
    }
  }

  void clearAll() => state = const [];
}

/// Tracks voice state per gateway [VoiceState.connectionId] (or a synthetic key
/// when [VoiceState.connectionId] is null) so the same user can have multiple
/// simultaneous connections. Map keys are not user ids.
@Riverpod(keepAlive: true)
class VoiceStatesMap extends _$VoiceStatesMap {
  @override
  Map<String, VoiceState> build() => {};

  void update(VoiceState voiceState) {
    final Map<String, VoiceState> next = Map<String, VoiceState>.of(state);
    if (voiceState.channelId == null) {
      final String? connectionId = voiceState.connectionId;
      if (connectionId != null) {
        if (!next.containsKey(connectionId)) {
          return;
        }
        next.remove(connectionId);
      } else {
        final List<String> keysToRemove = next.entries
            .where(
              (MapEntry<String, VoiceState> e) =>
                  e.value.userId == voiceState.userId,
            )
            .map((MapEntry<String, VoiceState> e) => e.key)
            .toList();
        if (keysToRemove.isEmpty) {
          return;
        }
        for (final String k in keysToRemove) {
          next.remove(k);
        }
      }
      state = next;
      return;
    }
    final String key = _voiceStateStorageKey(voiceState);
    final VoiceState? existing = next[key];
    if (existing == voiceState) {
      return;
    }
    next[key] = voiceState;
    state = next;
  }

  void updateBulk(List<VoiceState> voiceStates) {
    final Map<String, VoiceState> updated = Map<String, VoiceState>.of(state);
    bool hasChanges = false;
    for (final VoiceState vs in voiceStates) {
      if (vs.channelId == null) {
        if (vs.connectionId != null) {
          if (updated.containsKey(vs.connectionId)) {
            updated.remove(vs.connectionId);
            hasChanges = true;
          }
        } else {
          final List<String> keysToRemove = updated.entries
              .where(
                (MapEntry<String, VoiceState> e) => e.value.userId == vs.userId,
              )
              .map((MapEntry<String, VoiceState> e) => e.key)
              .toList();
          if (keysToRemove.isNotEmpty) {
            hasChanges = true;
            for (final String k in keysToRemove) {
              updated.remove(k);
            }
          }
        }
      } else {
        final String key = _voiceStateStorageKey(vs);
        final VoiceState? existing = updated[key];
        if (existing != vs) {
          updated[key] = vs;
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      state = updated;
    }
  }

  List<VoiceState> getForChannel(String channelId) =>
      state.values.where((VoiceState v) => v.channelId == channelId).toList();

  void clear() => state = {};
}

/// Active call state per channel.
class CallState {
  const CallState({
    required this.channelId,
    this.messageId,
    this.region,
    this.ringing = const [],
    this.pendingRingUserIds = const {},
    this.voiceStates = const [],
  });

  final String channelId;
  final String? messageId;
  final String? region;

  /// Last gateway snapshot of user IDs receiving a ring tone.
  final List<String> ringing;

  /// Subset tracked for incoming-call UI (reset from gateway `ringing` when
  /// present; mutated locally after accept/reject/ignore until next update).
  final Set<String> pendingRingUserIds;
  final List<VoiceState> voiceStates;

  CallState copyWith({
    String? messageId,
    String? region,
    List<String>? ringing,
    Set<String>? pendingRingUserIds,
    List<VoiceState>? voiceStates,
  }) {
    return CallState(
      channelId: channelId,
      messageId: messageId ?? this.messageId,
      region: region ?? this.region,
      ringing: ringing ?? this.ringing,
      pendingRingUserIds: pendingRingUserIds ?? this.pendingRingUserIds,
      voiceStates: voiceStates ?? this.voiceStates,
    );
  }
}

@Riverpod(keepAlive: true)
class ActiveCalls extends _$ActiveCalls {
  @override
  Map<String, CallState> build() => {};

  static Set<String> _normalizeRingIds(List<String>? ringing) =>
      ringing == null ? <String>{} : Set<String>.from(ringing);

  void createCall(
    String channelId, {
    String? messageId,
    String? region,
    List<String>? ringing,
    List<VoiceState>? voiceStates,
  }) {
    final List<String> ringList = List<String>.from(ringing ?? const []);
    state = {
      ...state,
      channelId: CallState(
        channelId: channelId,
        messageId: messageId,
        region: region,
        ringing: ringList,
        pendingRingUserIds: _normalizeRingIds(ringing),
        voiceStates: voiceStates ?? const [],
      ),
    };
  }

  void updateCall(
    String channelId, {
    String? messageId,
    String? region,
    List<String>? ringing,
    List<VoiceState>? voiceStates,
  }) {
    final CallState? existing = state[channelId];
    if (existing == null) {
      createCall(
        channelId,
        messageId: messageId,
        region: region,
        ringing: ringing,
        voiceStates: voiceStates,
      );
      return;
    }
    final bool hasRingPayload = ringing != null;
    final List<String> nextRing = ringing != null
        ? List<String>.from(ringing)
        : existing.ringing;
    final Set<String> nextPending = hasRingPayload
        ? _normalizeRingIds(ringing)
        : existing.pendingRingUserIds;
    state = {
      ...state,
      channelId: CallState(
        channelId: channelId,
        messageId: messageId ?? existing.messageId,
        region: region ?? existing.region,
        ringing: nextRing,
        pendingRingUserIds: nextPending,
        voiceStates: voiceStates ?? existing.voiceStates,
      ),
    };
  }

  bool isChannelPendingRingForUser({
    required String channelId,
    required String userId,
  }) {
    return state[channelId]?.pendingRingUserIds.contains(userId) ?? false;
  }

  void removeUserFromPendingRing({
    required String channelId,
    required String userId,
  }) {
    final CallState? existing = state[channelId];
    if (existing == null) {
      return;
    }
    final Set<String> next = {...existing.pendingRingUserIds}..remove(userId);
    if (next.length == existing.pendingRingUserIds.length) {
      return;
    }
    state = {...state, channelId: existing.copyWith(pendingRingUserIds: next)};
  }

  void clearPendingRingForChannel(String channelId) {
    final CallState? existing = state[channelId];
    if (existing == null) {
      return;
    }
    state = {...state, channelId: existing.copyWith(pendingRingUserIds: {})};
  }

  void deleteCall(String channelId) {
    state = Map.of(state)..remove(channelId);
  }

  void clear() => state = {};
}

/// Tracks channels where this client initiated an outbound ring (suppresses
/// incoming overlay for caller), matching fluxer-web [CallInitiator].
@Riverpod(keepAlive: true)
class OutgoingVoiceCallInitiator extends _$OutgoingVoiceCallInitiator {
  @override
  Set<String> build() => {};

  void markInitiated({
    required String channelId,
    required List<String> outboundRingRecipients,
  }) {
    final List<String> filtered = outboundRingRecipients
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (filtered.isEmpty) {
      state = {...state}..remove(channelId);
      return;
    }
    state = {...state, channelId};
  }

  bool hasInitiated(String channelId) => state.contains(channelId);

  void clearChannel(String channelId) {
    if (!state.contains(channelId)) {
      return;
    }
    state = {...state}..remove(channelId);
  }

  void clearAll() => state = {};
}

/// Returns the [VoiceState] for a specific connection ID.
/// Uses select to only rebuild when this connection's state changes.
@riverpod
VoiceState? voiceStateForConnection(Ref ref, String connectionId) {
  return ref.watch(
    voiceStatesMapProvider.select((Map<String, VoiceState> map) => map[connectionId]),
  );
}

/// Returns voice states for a specific guild channel.
/// Only emits when voice states for this specific channel change.
@riverpod
List<VoiceState> voiceStatesInChannel(
  Ref ref,
  String guildId,
  String channelId,
) {
  final Map<String, VoiceState> map = ref.watch(voiceStatesMapProvider);
  return map.values
      .where(
        (VoiceState vs) =>
            vs.channelId == channelId && vs.guildId == guildId,
      )
      .toList();
}

/// Returns voice states for a specific DM/private channel.
/// Only emits when voice states for this specific channel change.
@riverpod
List<VoiceState> voiceStatesInPrivateChannel(Ref ref, String channelId) {
  final Map<String, VoiceState> map = ref.watch(voiceStatesMapProvider);
  return map.values
      .where(
        (VoiceState vs) =>
            vs.channelId == channelId &&
            (vs.guildId == null || vs.guildId!.isEmpty),
      )
      .toList();
}

/// Returns voice states for a specific guild (all channels).
/// Only emits when voice states for this guild change.
@riverpod
List<VoiceState> voiceStatesInGuild(Ref ref, String guildId) {
  final Map<String, VoiceState> map = ref.watch(voiceStatesMapProvider);
  return map.values.where((VoiceState vs) => vs.guildId == guildId).toList();
}

/// Returns the count of unique participants in a private DM channel.
/// Uses select for minimal rebuilds.
@riverpod
int privateChannelVoiceParticipantCount(Ref ref, String channelId) {
  final Map<String, VoiceState> map = ref.watch(voiceStatesMapProvider);
  final Set<String> userIds = <String>{};
  for (final VoiceState vs in map.values) {
    if (vs.channelId == channelId &&
        (vs.guildId == null || vs.guildId!.isEmpty)) {
      userIds.add(vs.userId);
    }
  }
  return userIds.length;
}

/// Returns the count of unique participants in a guild voice channel.
/// Uses select for minimal rebuilds.
@riverpod
int guildChannelVoiceParticipantCount(
  Ref ref,
  String guildId,
  String channelId,
) {
  final Map<String, VoiceState> map = ref.watch(voiceStatesMapProvider);
  final Set<String> userIds = <String>{};
  for (final VoiceState vs in map.values) {
    if (vs.channelId == channelId && vs.guildId == guildId) {
      userIds.add(vs.userId);
    }
  }
  return userIds.length;
}

/// Clears ephemeral gateway derived UI state after session recovery
@Riverpod(keepAlive: true)
void gatewayEphemeralStateRecoveryListener(Ref ref) {
  ref.listen<int>(gatewaySessionRecoveryProvider, (int? previous, int next) {
    if (next <= 0 || previous == next) {
      return;
    }
    ref.read(typingIndicatorsProvider.notifier).clearAll();
    ref.read(voiceStatesMapProvider.notifier).clear();
    ref.read(activeCallsProvider.notifier).clear();
    ref.read(outgoingVoiceCallInitiatorProvider.notifier).clearAll();
  });
}

/// In-memory invite cache.
@Riverpod(keepAlive: true)
class InviteCache extends _$InviteCache {
  @override
  Map<String, Map<String, dynamic>> build() => {};

  void addInvite(Map<String, dynamic> data) {
    final code = data['code'] as String?;
    if (code != null) {
      state = {...state, code: data};
    }
  }

  void removeInvite(String code) {
    state = Map.of(state)..remove(code);
  }

  void clear() => state = {};
}
