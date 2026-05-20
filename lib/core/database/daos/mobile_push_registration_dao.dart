import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/mobile_push_registrations.dart';

part 'mobile_push_registration_dao.g.dart';

@DriftAccessor(tables: [MobilePushRegistrations])
class MobilePushRegistrationDao extends DatabaseAccessor<FluxerDatabase>
    with _$MobilePushRegistrationDaoMixin {
  MobilePushRegistrationDao(super.attachedDatabase);

  Future<MobilePushRegistration?> getForUser(String userId) => (select(
        mobilePushRegistrations,
      )..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();

  Future<void> upsert({
    required String userId,
    required String pushSubscriptionId,
    required String endpointUrl,
    required String encryptionKey,
    required String authSecret,
    String? vapidPublicKey,
  }) {
    return into(mobilePushRegistrations).insertOnConflictUpdate(
      MobilePushRegistrationsCompanion.insert(
        userId: userId,
        pushSubscriptionId: pushSubscriptionId,
        endpointUrl: endpointUrl,
        encryptionKey: encryptionKey,
        authSecret: authSecret,
        vapidPublicKey: Value(vapidPublicKey),
      ),
    );
  }

  Future<void> clearForUser(String userId) => (delete(
        mobilePushRegistrations,
      )..where((t) => t.userId.equals(userId)))
          .go();
}
