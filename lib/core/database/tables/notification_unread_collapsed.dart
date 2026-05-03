import 'package:drift/drift.dart';

class NotificationUnreadCollapsed extends Table {
  TextColumn get channelId => text()();
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {channelId};
}
