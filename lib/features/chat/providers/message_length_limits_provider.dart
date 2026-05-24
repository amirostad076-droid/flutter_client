import 'package:fluxer_app/core/limits/limit_context.dart';
import 'package:fluxer_app/core/limits/limit_defaults.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/limits/limit_resolver.dart';
import 'package:fluxer_app/core/providers/well_known_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/utils/message_length_constants.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_length_limits_provider.g.dart';

@Riverpod(keepAlive: true)
int maxMessageLength(Ref ref) {
  final bool isPremium = ref.watch(currentUserPremiumTypeProvider) > 0;
  final int fallback = resolveMaxMessageLength(isPremium: isPremium);
  final AsyncValue<WellKnownFluxerResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownFluxerResponse response) => resolveInstanceLimit(
      limits: response.limits,
      key: LimitKeys.maxMessageLength,
      context: buildUserLimitContext(isPremium: isPremium),
      fallback: fallback,
    ),
    loading: () => fallback,
    error: (_, _) => fallback,
  );
}

@Riverpod(keepAlive: true)
int premiumMaxMessageLength(Ref ref) {
  final AsyncValue<WellKnownFluxerResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownFluxerResponse response) => resolveInstanceLimit(
      limits: response.limits,
      key: LimitKeys.maxMessageLength,
      context: buildUserLimitContext(isPremium: true),
      fallback: kMaxMessageLengthPremium,
    ),
    loading: () => kMaxMessageLengthPremium,
    error: (_, _) => kMaxMessageLengthPremium,
  );
}
