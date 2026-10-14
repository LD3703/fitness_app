// Vytištěný žebříček posilovny (A4 na nástěnku) – co se na papír dostane.
// Čistá logika bez Flutteru; PDF skládá ui/gym_print.dart.
// Testy: test/social_gym_printout_test.dart
import '../social_logic.dart';
import 'gym_logic.dart';
import 'gym_models.dart';

/// Kategorie na papíře – základní cviky, které se dají porovnat s lidmi
/// u stroje (samolepky na legpress, bench a klec).
const gymPrintCategories = <GymCategory>[
  GymCategory.benchPress,
  GymCategory.backSquat,
  GymCategory.deadlift,
  GymCategory.legPress,
];

/// Sloupce podle pohlaví. Kdo pohlaví neuvedl, na papír se nedostane
/// (v aplikaci ho uvidí dál ve filtru „Všichni“).
const gymPrintGenders = <GymGenderFilter>[
  GymGenderFilter.men,
  GymGenderFilter.women,
];

/// Kolik míst se tiskne.
const gymPrintTop = 5;

/// Nejvýš tolik řádků i při shodě na posledním místě (aby se vešly).
const gymPrintMaxRows = gymPrintTop + 2;

/// Řádky jednoho seznamu na papíře: bez skrytých záznamů (nereálné,
/// nahlášené), bez lidí, kteří tisk vypnuli, jen dané pohlaví, prvních
/// [gymPrintTop] míst (shodné hodnoty mají stejné místo, jako v aplikaci).
List<RankedEntry<GymEntry>> gymPrintRows(
  Iterable<GymEntry> entries, {
  required GymGenderFilter gender,
  required bool monthly,
  required String month,
}) {
  final printable = entries.where(
    (e) => !e.isHidden && !e.noPrint && gymGenderMatches(gender, e.gender),
  );
  final ranked = rankBy<GymEntry>(printable, (e) {
    final v = e.valueFor(monthly: monthly, month: month);
    return v != null && v > 0 ? v : null;
  });
  return ranked.where((r) => r.rank <= gymPrintTop).take(gymPrintMaxRows).toList();
}

/// Jeden rámeček na papíře: kategorie × pohlaví, vedle sebe tento měsíc
/// a celkově.
typedef GymPrintBox = ({
  GymCategory category,
  GymGenderFilter gender,
  List<RankedEntry<GymEntry>> month,
  List<RankedEntry<GymEntry>> allTime,
});

/// Data celé stránky z načtených žebříčků ([monthly] a [allTime] podle
/// kategorie – stejné dotazy jako v aplikaci). Pořadí: kategorie
/// v řádcích, muži a ženy ve sloupcích.
List<GymPrintBox> gymPrintBoxes({
  required Map<GymCategory, List<GymEntry>> monthly,
  required Map<GymCategory, List<GymEntry>> allTime,
  required String month,
}) =>
    [
      for (final c in gymPrintCategories)
        for (final g in gymPrintGenders)
          (
            category: c,
            gender: g,
            month: gymPrintRows(
              monthly[c] ?? const [],
              gender: g,
              monthly: true,
              month: month,
            ),
            allTime: gymPrintRows(
              allTime[c] ?? const [],
              gender: g,
              monthly: false,
              month: month,
            ),
          ),
    ];

/// Je na papíře aspoň jeden výkon? (Prázdný žebříček se netiskne.)
bool gymPrintHasData(List<GymPrintBox> boxes) =>
    boxes.any((b) => b.month.isNotEmpty || b.allTime.isNotEmpty);
