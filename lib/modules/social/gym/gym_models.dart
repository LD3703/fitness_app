// Datové třídy žebříčku posilovny (obraz dokumentů ve Firestore).
// Popis modelu: docs/social.md, sekce „Žebříček posilovny“.
import '../social_models.dart';
import 'gym_logic.dart';

/// Posilovna (gyms/{gymId}) – veřejný adresář pro přihlášené.
class Gym {
  Gym({
    required this.id,
    required this.name,
    required this.city,
    required this.code,
    required this.createdBy,
    this.address,
    this.memberCount = 0,
  });

  factory Gym.fromMap(String id, Map<String, Object?> m) => Gym(
        id: id,
        name: readString(m['name']) ?? '?',
        city: readString(m['city']) ?? '',
        address: readString(m['address']),
        code: readString(m['code']) ?? '',
        createdBy: readString(m['createdBy']) ?? '',
        memberCount: readInt(m['memberCount']) ?? 0,
      );

  final String id;
  final String name;
  final String city;
  final String? address;
  final String code;
  final String createdBy;
  final int memberCount;
}

/// Moje členství a nastavení (users/{uid}/private/gym) – vidí jen vlastník.
/// Uložené ve Firestore, ne v lokální databázi (schéma se nemění).
class GymMembership {
  GymMembership({
    required this.gymId,
    required this.nickname,
    required this.gender,
    required this.show,
  });

  factory GymMembership.fromMap(Map<String, Object?> m) => GymMembership(
        gymId: readString(m['gymId']),
        nickname: readString(m['nickname']),
        gender: gymGenderFromKey(readString(m['gender'])),
        show: m['show'] != false,
      );

  /// null = nejsem v žádné posilovně.
  final String? gymId;
  final String? nickname;
  final GymGender gender;

  /// „Ukázat mě v žebříčku posilovny“.
  final bool show;
}

/// Záznam v žebříčku (gyms/{gymId}/entries/{uid}_{kategorie}).
class GymEntry {
  GymEntry({
    required this.id,
    required this.uid,
    required this.category,
    required this.nickname,
    required this.gender,
    required this.best,
    this.ageGroup,
    this.bestAt,
    this.bestMonth,
    this.monthKey,
    this.hidden = false,
    this.hiddenReason,
    this.reportCount = 0,
    this.verifiedValue,
    this.verifiedAt,
  });

  static GymEntry? fromMap(String id, Map<String, Object?> m) {
    final category = gymCategoryFromKey(readString(m['category']));
    final best = readDouble(m['best']);
    if (category == null || best == null) return null;
    final verified = readMap(m['verified']);
    return GymEntry(
      id: id,
      uid: readString(m['uid']) ?? '',
      category: category,
      nickname: readString(m['nickname']) ?? '?',
      gender: gymGenderFromKey(readString(m['gender'])),
      ageGroup: gymAgeGroupFromKey(readString(m['ageGroup'])),
      best: best,
      bestAt: readDate(m['bestAt']),
      bestMonth: readDouble(m['bestMonth']),
      monthKey: readString(m['monthKey']),
      hidden: m['hidden'] == true,
      hiddenReason: readString(m['hiddenReason']),
      reportCount: readInt(m['reportCount']) ?? 0,
      verifiedValue: readDouble(verified['value']),
      verifiedAt: readDate(verified['at']),
    );
  }

  final String id;
  final String uid;
  final GymCategory category;
  final String nickname;
  final GymGender gender;

  /// Věková skupina (pro filtr 40+ / 50+ / 60+); null = neuvedeno.
  final GymAgeGroup? ageGroup;

  /// Nejlepší hodnota celkově (kg / nejvíc tréninků za měsíc).
  final double best;
  final DateTime? bestAt;

  /// Nejlepší hodnota v měsíci [monthKey].
  final double? bestMonth;
  final String? monthKey;

  /// Nastavuje jen server (Cloud Functions).
  final bool hidden;
  final String? hiddenReason;
  final int reportCount;

  /// Poslední maximum, které server ověřil (pro kontrolu skoku).
  final double? verifiedValue;
  final DateTime? verifiedAt;

  /// Skrytý záznam (nereálný výkon nebo nahlášení) – i bez Cloud
  /// Functions skryje aplikace záznamy s [gymReportHideThreshold] nahlášeními.
  bool get isHidden => hidden || reportCount >= gymReportHideThreshold;

  bool get hiddenForReports =>
      reportCount >= gymReportHideThreshold || hiddenReason == 'reports';

  /// Hodnota pro žebříček: měsíční jen pro aktuální měsíc.
  double? valueFor({required bool monthly, required String month}) =>
      monthly ? (monthKey == month ? bestMonth : null) : best;
}
