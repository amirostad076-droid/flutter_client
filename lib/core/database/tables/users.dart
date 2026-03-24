import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get discriminator => text().withDefault(const Constant('0'))();
  TextColumn get globalName => text().nullable()();
  TextColumn get avatar => text().nullable()();
  IntColumn get avatarColor => integer().nullable()();
  BoolColumn get isBot => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('offline'))();
  TextColumn get customStatus => text().nullable()();
  DateTimeColumn get memberSince => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
