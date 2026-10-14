// Nahlášení nevhodného obsahu (pravidla Google Play a App Store pro obsah
// od uživatelů). Čistá logika bez Firebase – testy v test/moderation_test.dart.
//
// Model: contentReports/{kind}_{targetId}_{reporterUid} – každý nahlásí
// stejný cíl jen jednou; číst smí jen vývojář (Firebase konzole).
// Popis: docs/social.md, „Nahlášení a blokování“.

/// Co se nahlašuje.
enum ContentReportKind {
  /// Posilovna v adresáři (název, město, adresa).
  gym,

  /// Přítel (jméno, obsah v novinkách, výzvy).
  user,
}

/// Důvod nahlášení. closed a duplicate jen u posilovny (neexistuje /
/// je zavřená, duplicita jiné posilovny).
enum ContentReportReason { offensive, spam, other, closed, duplicate }

/// Důvody nahlášení posilovny (pořadí v dialogu).
const kGymReportReasons = [
  ContentReportReason.closed,
  ContentReportReason.duplicate,
  ContentReportReason.offensive,
  ContentReportReason.spam,
  ContentReportReason.other,
];

/// Důvody nahlášení přítele.
const kUserReportReasons = [
  ContentReportReason.offensive,
  ContentReportReason.spam,
  ContentReportReason.other,
];

/// Kolik nahlášení „neexistuje / duplicita“ skryje prázdnou posilovnu
/// (zrcadlo GYM_CLOSED_REPORT_THRESHOLD ve functions/src/gymDirectory.ts).
const kGymClosedReportThreshold = 5;

/// Kolik nahlášení skryje posilovnu z adresáře (zrcadlo
/// GYM_DIRECTORY_REPORT_THRESHOLD ve functions/src/gymDirectory.ts).
const kGymDirectoryReportThreshold = 5;

/// Nejdelší uložený název cíle (pro kontrolu vývojářem).
const kReportTargetNameMax = 80;

/// Id dokumentu – zároveň brání opakovanému nahlášení (pravidla
/// dovolí jen vytvoření, ne přepsání).
String contentReportId(
  ContentReportKind kind,
  String targetId,
  String reporterUid,
) =>
    '${kind.name}_${targetId}_$reporterUid';

/// Data dokumentu bez času (ten doplní server).
Map<String, Object> contentReportFields({
  required ContentReportKind kind,
  required String targetId,
  required String targetName,
  required ContentReportReason reason,
  required String reporterUid,
}) {
  final name = targetName.trim();
  return {
    'kind': kind.name,
    'targetId': targetId,
    'targetName': name.length > kReportTargetNameMax
        ? name.substring(0, kReportTargetNameMax)
        : name,
    'reason': reason.name,
    'reporterUid': reporterUid,
  };
}
