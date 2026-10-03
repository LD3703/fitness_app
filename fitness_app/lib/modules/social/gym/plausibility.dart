// Automatická kontrola nereálných výkonů v žebříčku posilovny.
//
// Stejná pravidla běží na serveru (functions/src/plausibility.ts).
// Aplikace nereálnou hodnotu vůbec nepublikuje; server pro jistotu záznam
// skryje (`hidden: true`, `hiddenReason`). Tělesná váha se v žebříčku
// posilovny nepoužívá vůbec.
import 'gym_logic.dart';

/// Proč hodnota neprošla.
enum ImplausibleReason {
  /// Nad absolutní hranicí (zhruba úroveň světového rekordu).
  absolute,

  /// Skok o víc než 15 % proti předchozímu zveřejněnému maximu
  /// zveřejněnému před méně než 14 dny.
  jump,
}

/// Absolutní hranice kategorie: kg odhadu 1RM u cviků (u jednoruček na
/// jednu jednoručku, u shybů a dipů jen přidaná zátěž), počet tréninků za
/// měsíc. Hodnoty jsou u kategorií ([GymCategory.limit]).
double gymAbsoluteLimit(GymCategory category) => category.limit;

/// Max. povolený skok proti předchozímu maximu (15 %).
const gymMaxJump = 0.15;

/// Skok se hlídá, jen když předchozí maximum je mladší než 14 dní.
const gymJumpWindow = Duration(days: 14);

const _epsilon = 1e-9;

/// Zkontroluje hodnotu kategorie. Vrací důvod, nebo null, když je hodnota
/// uvěřitelná.
///
/// - [previousValue] / [previousAt]: předchozí zveřejněné maximum a kdy
///   bylo zveřejněno (jen u cviků, pro kontrolu skoku).
ImplausibleReason? checkGymValue({
  required GymCategory category,
  required double value,
  double? previousValue,
  DateTime? previousAt,
  DateTime? now,
}) {
  if (value.isNaN || value.isInfinite || value < 0) {
    return ImplausibleReason.absolute;
  }
  if (value > gymAbsoluteLimit(category) + _epsilon) {
    return ImplausibleReason.absolute;
  }
  if (!category.isLift) return null;

  if (previousValue != null &&
      previousValue > 0 &&
      previousAt != null &&
      now != null) {
    // Budoucí čas (posunuté hodiny) bereme jako „nedávno“.
    final recent = now.difference(previousAt) < gymJumpWindow;
    if (recent && value > previousValue * (1 + gymMaxJump) + _epsilon) {
      return ImplausibleReason.jump;
    }
  }
  return null;
}
