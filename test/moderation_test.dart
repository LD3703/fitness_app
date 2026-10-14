import 'package:fitness_app/modules/social/moderation_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('id nahlášení odpovídá pravidlům (kind_targetId_reporter)', () {
    expect(contentReportId(ContentReportKind.gym, 'g1', 'u1'), 'gym_g1_u1');
    expect(contentReportId(ContentReportKind.user, 'u2', 'u1'), 'user_u2_u1');
  });

  test('pole nahlášení: názvy výčtů a zkrácený název cíle', () {
    final m = contentReportFields(
      kind: ContentReportKind.user,
      targetId: 'u2',
      targetName: '  ${'x' * 100}  ',
      reason: ContentReportReason.spam,
      reporterUid: 'u1',
    );
    expect(m['kind'], 'user');
    expect(m['reason'], 'spam');
    expect(m['reporterUid'], 'u1');
    expect((m['targetName']! as String).length, kReportTargetNameMax);
    expect(m.keys.toSet(),
        {'kind', 'targetId', 'targetName', 'reason', 'reporterUid'});
  });
}
