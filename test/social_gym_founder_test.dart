// Úprava a smazání posilovny zakladatelem (Gym.canEdit / canDelete,
// lib/modules/social/gym/gym_models.dart; pravidla tool/rules_test).
import 'package:fitness_app/modules/social/gym/gym_models.dart';
import 'package:flutter_test/flutter_test.dart';

Gym _gym({String createdBy = 'me', int members = 1, String? source}) => Gym(
      id: 'g1',
      name: 'Fitnes Jicin',
      city: 'Jicin',
      code: 'XYZ234',
      createdBy: createdBy,
      memberCount: members,
      source: source,
    );

void main() {
  test('upravit smí jen zakladatel posilovny založené v aplikaci', () {
    expect(_gym().canEdit('me'), isTrue);
    expect(_gym().canEdit('other'), isFalse);
    expect(_gym().canEdit(null), isFalse);
    expect(_gym(createdBy: '').canEdit(''), isFalse);
    expect(_gym(source: 'osm').canEdit('me'), isFalse);
  });

  test('smazat jde jen posilovnu bez dalších členů', () {
    expect(_gym(members: 1).canDelete('me'), isTrue);
    expect(_gym(members: 0).canDelete('me'), isTrue);
    expect(_gym(members: 2).canDelete('me'), isFalse);
    expect(_gym(members: 1).canDelete('other'), isFalse);
    expect(_gym(members: 1, source: 'osm').canDelete('me'), isFalse);
  });
}
