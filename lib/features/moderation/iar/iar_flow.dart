// In-App Reporting (IAR) — flow taxonomy.
//
// Mirrors the web `IARFlowUtils.ts`. The user-facing taxonomy is richer than
// the wire-format enum: the user picks a `IarPrimaryPath` (platform/community/
// preference), then for the `platform` path a high-level `IarRuleCategory`,
// then a specific `IarRuleReason`. At submit time the reason is mapped onto
// the backend `MessageReportCategoryEnum` via [iarReasonToMessageCategory].
//
// Mobile currently exposes only the `message` IAR context — `user` and
// `guild` contexts on the web are intentionally deferred until those entry
// points exist on mobile.

import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_dart/export.dart';

/// Stepper position in the IAR flow.
enum IarStep { path, category, reason, guidance, success }

/// What the user is trying to do at the top of the flow.
enum IarPrimaryPath { platform, community, preference }

/// Specific platform-rule reasons.
///
/// Source of truth lives in `packages/.../IARFlowUtils.ts`. Order is unstable
/// but value names must match the web exactly so analytics, logs, and
/// regressions can cross-reference both clients.
enum IarRuleReason {
  harassment,
  hate,
  violence,
  terrorismExtremism,
  matureContent,
  childSafety,
  harmfulMisinformation,
  illegalActivity,
  spamScams,
  malware,
  privacy,
  impersonation,
  inappropriateProfile,
  raidCoordination,
  selfHarm,
  other,
}

/// High-level category groupings the user picks before drilling into a reason.
enum IarRuleCategory {
  targetedHarm,
  safetyMinors,
  privacyIdentity,
  deception,
  illegalOther,
}

/// Reasons allowed under each category.
///
/// The ordering matches the web list within each category and is what the
/// reason-step radio group renders after [IarRuleCategory] is selected.
const Map<IarRuleCategory, List<IarRuleReason>> ruleReasonsByCategory = {
  IarRuleCategory.targetedHarm: [
    IarRuleReason.harassment,
    IarRuleReason.hate,
    IarRuleReason.violence,
    IarRuleReason.terrorismExtremism,
    IarRuleReason.raidCoordination,
    IarRuleReason.selfHarm,
  ],
  IarRuleCategory.safetyMinors: [
    IarRuleReason.childSafety,
    IarRuleReason.matureContent,
  ],
  IarRuleCategory.privacyIdentity: [
    IarRuleReason.privacy,
    IarRuleReason.impersonation,
    IarRuleReason.inappropriateProfile,
  ],
  IarRuleCategory.deception: [
    IarRuleReason.spamScams,
    IarRuleReason.malware,
    IarRuleReason.harmfulMisinformation,
  ],
  IarRuleCategory.illegalOther: [
    IarRuleReason.illegalActivity,
    IarRuleReason.other,
  ],
};

/// Inverse lookup: which category a reason belongs to.
IarRuleCategory iarCategoryForReason(IarRuleReason reason) {
  for (final entry in ruleReasonsByCategory.entries) {
    if (entry.value.contains(reason)) {
      return entry.key;
    }
  }
  return IarRuleCategory.illegalOther;
}

/// Maps a chosen reason onto the backend wire-format
/// [MessageReportCategoryEnum]. Mirrors `REPORT_CATEGORY_BY_REASON.message`
/// from the web.
MessageReportCategoryEnum iarReasonToMessageCategory(IarRuleReason reason) {
  return switch (reason) {
    IarRuleReason.harassment => MessageReportCategoryEnum.harassment,
    IarRuleReason.hate => MessageReportCategoryEnum.hateSpeech,
    IarRuleReason.violence => MessageReportCategoryEnum.violentContent,
    IarRuleReason.terrorismExtremism =>
      MessageReportCategoryEnum.violentContent,
    IarRuleReason.matureContent => MessageReportCategoryEnum.nsfwViolation,
    IarRuleReason.childSafety => MessageReportCategoryEnum.childSafety,
    IarRuleReason.harmfulMisinformation => MessageReportCategoryEnum.other,
    IarRuleReason.illegalActivity => MessageReportCategoryEnum.illegalActivity,
    IarRuleReason.spamScams => MessageReportCategoryEnum.spam,
    IarRuleReason.malware => MessageReportCategoryEnum.maliciousLinks,
    IarRuleReason.privacy => MessageReportCategoryEnum.doxxing,
    IarRuleReason.impersonation => MessageReportCategoryEnum.impersonation,
    IarRuleReason.inappropriateProfile => MessageReportCategoryEnum.other,
    IarRuleReason.raidCoordination => MessageReportCategoryEnum.harassment,
    IarRuleReason.selfHarm => MessageReportCategoryEnum.selfHarm,
    IarRuleReason.other => MessageReportCategoryEnum.other,
  };
}

/// Discriminated input to the IAR flow. Only the message variant is wired
/// up today; user/guild variants will be added when those entry points land.
sealed class IarContext {
  const IarContext();
}

class IarMessageContext extends IarContext {
  const IarMessageContext({required this.message, required this.guildId});

  /// The message under report.
  final Message message;

  /// Guild owning the channel, or `null` for DMs / group DMs.
  final String? guildId;
}
