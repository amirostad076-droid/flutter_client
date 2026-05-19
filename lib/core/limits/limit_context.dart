import 'package:fluxer_app/core/limits/limit_types.dart';

LimitMatchContext buildUserLimitContext({required bool isPremium}) {
  final Set<String> traits = <String>{};
  if (isPremium) {
    traits.add('premium');
  }
  return LimitMatchContext(traits: traits, guildFeatures: <String>{});
}
