import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/shared/providers/member_role_color.dart';

void main() {
  test('exposes the member role color provider used by chat widgets', () {
    expect(memberRoleColorProvider, isNotNull);
  });
}
