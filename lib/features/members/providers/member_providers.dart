import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/members/data/member_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_providers.g.dart';

@Riverpod(keepAlive: true)
MemberRepository memberRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return MemberRepository(client, db);
}
