import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Fetches a single role by ID from the local database.
final FutureProviderFamily<MemberRole?, String> roleByIdProvider = FutureProvider.family<MemberRole?, String>((
  ref,
  id,
) async {
  final db = ref.watch(fluxerDatabaseProvider);
  final row = await db.roleDao.getRoleById(id);
  return row == null ? null : MemberRole.fromRow(row);
});
