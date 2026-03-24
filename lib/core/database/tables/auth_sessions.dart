import 'package:drift/drift.dart';

class AuthSessions extends Table {
  TextColumn get token => text()();
  TextColumn get userId => text()();
  TextColumn get username => text().nullable()();
  TextColumn get discriminator => text().nullable()();
  TextColumn get avatar => text().nullable()();
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastActive => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
