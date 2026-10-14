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
    this.hidden = false,
    this.lat,
    this.lng,
    this.country,
    this.website,
    this.source,
    this.osmMissing = false,
  });

  factory Gym.fromMap(String id, Map<String, Object?> m) => Gym(
        id: id,
        name: readString(m['name']) ?? '?',
        city: readString(m['city']) ?? '',
        address: readString(m['address']),
        code: readString(m['code']) ?? '',
        createdBy: readString(m['createdBy']) ?? '',
        memberCount: readInt(m['memberCount']) ?? 0,
        hidden: m['hidden'] == true,
        lat: readDouble(m['lat']),
        lng: readDouble(m['lng']),
        country: readString(m['country']),
        website: readString(m['website']),
        source: readString(m['source']),
        osmMissing: m['osmMissing'] == true,
      );

  final String id;
  final String name;
  final String city;
  final String? address;
  final String code;
  final String createdBy;
  final int memberCount;

  /// Skrytá z adresáře po nahlášeních (zapisuje jen Cloud Function
  /// onContentReportCreated). Připojit se jde dál kódem / QR.
  final bool hidden;

  /// Poloha (import z OpenStreetMap, nebo zakladatel v posilovně).
  final double? lat;
  final double? lng;

  /// Země (ISO 3166-1) – jen u posiloven z importu.
  final String? country;

  /// Web posilovny (z OpenStreetMap).
  final String? website;

  /// Původ: „osm“ = import z OpenStreetMap, null = založil uživatel.
  final String? source;

  /// Posilovna při posledním importu v OpenStreetMap chyběla (zavřená?).
  final bool osmMissing;

  bool get isFromOsm => source == 'osm';

  bool get hasLocation => lat != null && lng != null;

  /// Ukázat v seznamech: ne skrytou po nahlášeních a ne prázdnou
  /// posilovnu, která z OpenStreetMap zmizela.
  bool get isListed => !hidden && !(osmMissing && memberCount == 0);
}

/// Posilovna se vzdáleností od uživatele (km; null = bez polohy).
typedef GymWithDistance = ({Gym gym, double? km});

/// Moje členství a nastavení (users/{uid}/private/gym) – vidí jen vlastník.
/// Uložené ve Firestore, ne v lokální databázi (schéma se nemění).
class GymMembership {
  GymMembership({
    required this.gymId,
    required this.nickname,
    required this.gender,
    required this.show,
    this.printable = true,
  });

  factory GymMembership.fromMap(Map<String, Object?> m) => GymMembership(
        gymId: readString(m['gymId']),
        nickname: readString(m['nickname']),
        gender: gymGenderFromKey(readString(m['gender'])),
        show: m['show'] != false,
        printable: m['printable'] != false,
      );

  /// null = nejsem v žádné posilovně.
  final String? gymId;
  final String? nickname;
  final GymGender gender;

  /// „Ukázat mě v žebříčku posilovny“.
  final bool show;

  /// „Ukázat mě na vytištěném žebříčku“ (nástěnka posilovny). Bez pole
  /// (dřívější verze) = ano.
  final bool printable;
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
    this.noPrint = false,
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
      noPrint: m['noPrint'] == true,
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

  /// Autor nechce být na vytištěném žebříčku (GymMembership.printable).
  final bool noPrint;

  /// Skrytý záznam (nereálný výkon nebo nahlášení) – i bez Cloud
  /// Functions skryje aplikace záznamy s [gymReportHideThreshold] nahlášeními.
  bool get isHidden => hidden || reportCount >= gymReportHideThreshold;

  /// Skrytý trvale (nahlášení, ruční skrytí vývojářem) – ne kvůli
  /// nereálné hodnotě (`hiddenReason` „implausible:…“).
  bool get hiddenForReports =>
      reportCount >= gymReportHideThreshold ||
      (hidden && !(hiddenReason ?? '').startsWith('implausible'));

  /// Hodnota pro žebříček: měsíční jen pro aktuální měsíc.
  double? valueFor({required bool monthly, required String month}) =>
      monthly ? (monthKey == month ? bestMonth : null) : best;
}
