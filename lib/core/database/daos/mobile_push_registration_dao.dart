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

  /// Last known VAPID key from any logged-in user (for the UP background isolate).
  Future<void> saveVapidForUser({
    required String userId,
    required String vapidPublicKey,
  }) async {
    final MobilePushRegistration? existing = await getForUser(userId);
    if (existing != null) {
      await (update(mobilePushRegistrations)
            ..where((t) => t.userId.equals(userId)))
          .write(
        MobilePushRegistrationsCompanion(
          vapidPublicKey: Value(vapidPublicKey),
        ),
      );
      return;
    }
    await into(mobilePushRegistrations).insert(
      MobilePushRegistrationsCompanion.insert(
        userId: userId,
        pushSubscriptionId: '',
        endpointUrl: '',
        encryptionKey: '',
        authSecret: '',
        vapidPublicKey: Value(vapidPublicKey),
      ),
    );
  }

  Future<String?> getCachedVapidPublicKey() async {
    final MobilePushRegistration? row = await (select(
          mobilePushRegistrations,
        )..where((t) => t.vapidPublicKey.isNotNull())
          ..limit(1))
        .getSingleOrNull();
    final String? key = row?.vapidPublicKey;
    if (key == null || key.isEmpty) {
      return null;
    }
    return key;
  }
}
