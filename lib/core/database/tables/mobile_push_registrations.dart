import 'package:drift/drift.dart';

class MobilePushRegistrations extends Table {
  TextColumn get userId => text()();
  TextColumn get pushSubscriptionId => text()();
  TextColumn get endpointUrl => text()();
  TextColumn get encryptionKey => text()();
  TextColumn get authSecret => text()();
  TextColumn get vapidPublicKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
