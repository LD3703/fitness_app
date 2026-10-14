import 'package:fitness_app/modules/social/social_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAcceptedReplyTo', () {
    bool check({
      String me = 'me',
      String replier = 'friend',
      String from = 'me',
      String to = 'friend',
      String status = 'accepted',
    }) =>
        isAcceptedReplyTo(
          me: me,
          replierUid: replier,
          invitationFromUid: from,
          invitationToUid: to,
          invitationStatus: status,
        );

    test('moje pozvánka přijatá tím, komu byla poslaná', () {
      expect(check(), isTrue);
    });

    test('cizí pozvánka (odesílatel nejsem já) se nepřijme', () {
      expect(check(from: 'someone'), isFalse);
    });

    test('odpověď od někoho jiného než příjemce se nepřijme', () {
      expect(check(replier: 'other'), isFalse);
    });

    test('nepřijatá pozvánka se nepřijme', () {
      expect(check(status: 'pending'), isFalse);
      expect(check(status: 'declined'), isFalse);
      expect(check(status: 'cancelled'), isFalse);
    });

    test('prázdná uid se nepřijmou', () {
      expect(check(me: '', from: ''), isFalse);
      expect(check(replier: '', to: ''), isFalse);
    });
  });

  group('isGoneRemoteChallengeError', () {
    test('smazaná výzva', () {
      expect(isGoneRemoteChallengeError('permission-denied'), isTrue);
      expect(isGoneRemoteChallengeError('not-found'), isTrue);
    });

    test('dočasné chyby výzvu nezapomenou', () {
      expect(isGoneRemoteChallengeError('unavailable'), isFalse);
      expect(isGoneRemoteChallengeError('deadline-exceeded'), isFalse);
    });
  });

  group('isValidDocId', () {
    test('běžné ID', () {
      expect(isValidDocId('abc123XYZ'), isTrue);
    });

    test('prázdné, null nebo s lomítkem', () {
      expect(isValidDocId(null), isFalse);
      expect(isValidDocId(''), isFalse);
      expect(isValidDocId('a/b'), isFalse);
    });
  });
}
