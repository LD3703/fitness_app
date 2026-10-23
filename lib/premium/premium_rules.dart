// Čistá logika Premium (bez Flutteru) – testy v test/premium_test.dart.
//
// Co je zdarma a co v Premium (rozhodnuto ve specifikaci):
//  - zapisování tréninků je vždy zdarma a bez omezení,
//  - vlastní plány: zdarma 3, Premium bez omezení,
//  - hotové programy: zdarma první 2, Premium všechny,
//  - rutiny plánu B: zdarma první 3, Premium všechny,
//  - grafy: zdarma posledních 30 dní a bez pruhů období, Premium vše,
//  - kdo začne aplikaci používat před spuštěním Premium, má Premium
//    zdarma ještě půl roku po spuštění plateb (první uživatel).

import '../data/seed/plan_templates.dart';
import '../data/seed/seed_translations.dart';

/// Kolik vlastních plánů má verze zdarma.
const kFreeCustomPlans = 3;

/// Kolik hotových programů (od začátku seznamu) je zdarma.
const kFreeTemplatePrograms = 2;

/// Kolik rutin plánu B (od začátku seznamu) je zdarma.
const kFreeHomeRoutines = 3;

/// Kolik dní historie ukazují grafy ve verzi zdarma.
const kFreeChartDays = 30;

/// Kolik týdnů ukazuje týdenní graf ve verzi zdarma (≈ 30 dní).
const kFreeChartWeeks = 5;

/// Na kolik měsíců dostanou první uživatelé Premium zdarma.
const kPremiumGiftMonths = 6;

/// Má uživatel přístup k Premium funkcím?
///
/// Dokud Premium nebylo spuštěno ([launched] = false), je odemčené
/// všechno. Potom stačí příznak v profilu (uložený stav posledního
/// ověření), aktivní nárok „premium“ v RevenueCat nebo platný dárek
/// pro první uživatele ([giftActive]).
/// [trainer] = uživatel má status trenéra – trenéři mají Premium zdarma,
/// dokud status mají (docs/coach.md).
bool hasPremiumAccess({
  required bool launched,
  required bool profilePremium,
  required bool entitlementActive,
  bool giftActive = false,
  bool trainer = false,
}) =>
    !launched || profilePremium || entitlementActive || giftActive || trainer;

/// Konec dárku: [kPremiumGiftMonths] měsíců od [start], konec dne.
/// Den se zkrátí na poslední den měsíce (31. 8. → 28. / 29. 2.).
DateTime premiumGiftEnd(DateTime start) {
  final month = start.month + kPremiumGiftMonths;
  final lastDay = DateTime(start.year, month + 1, 0).day;
  final day = start.day > lastDay ? lastDay : start.day;
  return DateTime(start.year, month, day, 23, 59, 59);
}

/// Do kdy platí dárek prvního uživatele: [kPremiumGiftMonths] měsíců od
/// spuštění Premium ([launchDate]). null = uživatel není první, nebo
/// Premium ještě neběží (konec zatím není známý).
DateTime? premiumGiftUntil({
  required DateTime? earlyAt,
  required DateTime? launchDate,
}) =>
    earlyAt == null || launchDate == null ? null : premiumGiftEnd(launchDate);

/// Platí dárek v čase [now]? Prvnímu uživateli platí do spuštění Premium
/// a ještě půl roku po něm.
bool isPremiumGiftActive({
  required DateTime? earlyAt,
  required DateTime? launchDate,
  required DateTime now,
}) {
  if (earlyAt == null) return false;
  if (launchDate == null) return true;
  return !now.isAfter(premiumGiftEnd(launchDate));
}

/// Stát se prvním uživatelem (a ukázat uvítací hlášku)? Jen dokud Premium
/// není spuštěné – kdo přijde až po spuštění, dostane zkušební měsíc
/// z obchodu. Každý jen jednou (smazání všech dat slib zachová).
bool shouldMarkPremiumEarlyUser({
  required bool launched,
  required bool onboardingDone,
  required DateTime? earlyAt,
}) =>
    !launched && onboardingDone && earlyAt == null;

/// Co udělat se slibem dárku po přihlášení (users/{uid}/private/premium).
enum PremiumEarlySync {
  /// Nic – obojí stejné (nebo ani jedno).
  none,

  /// Na serveru je, v telefonu ne (nový telefon) → uložit do telefonu.
  pull,

  /// V telefonu je, na serveru ne → uložit k účtu (pravidla to pustí jen
  /// před spuštěním Premium).
  push,
}

PremiumEarlySync premiumEarlySync({
  required DateTime? local,
  required DateTime? server,
}) {
  if (local == null && server != null) return PremiumEarlySync.pull;
  if (local != null && server == null) return PremiumEarlySync.push;
  return PremiumEarlySync.none;
}

/// Smí uživatel založit další vlastní plán?
bool canCreateCustomPlan({
  required int customPlanCount,
  required bool premium,
}) =>
    premium || customPlanCount < kFreeCustomPlans;

/// Je položka seznamu na pozici [index] zamčená, když je zdarma
/// prvních [freeCount] položek?
bool isIndexLocked(int index, {required int freeCount, required bool premium}) =>
    !premium && index >= freeCount;

/// Je hotový program na pozici [index] zamčený?
bool isProgramLocked(int index, {required bool premium}) =>
    isIndexLocked(index, freeCount: kFreeTemplatePrograms, premium: premium);

/// Je rutina plánu B na pozici [index] zamčená?
bool isHomeRoutineLocked(int index, {required bool premium}) =>
    isIndexLocked(index, freeCount: kFreeHomeRoutines, premium: premium);

/// Od kdy grafy ukazují data: null = celá historie (Premium),
/// jinak začátek dne před [kFreeChartDays] dny.
DateTime? chartHistoryStart(DateTime now, {required bool fullHistory}) {
  if (fullHistory) return null;
  final today = DateTime(now.year, now.month, now.day);
  return DateTime(today.year, today.month, today.day - kFreeChartDays);
}

/// Body grafu od [start] (včetně). Bez [start] vrátí všechny body.
List<T> pointsSince<T>(
  List<T> points,
  DateTime Function(T point) dateOf,
  DateTime? start,
) {
  if (start == null) return points;
  return [
    for (final p in points)
      if (!dateOf(p).isBefore(start)) p,
  ];
}

/// Kolik posledních týdnů ukázat v týdenním grafu.
int visibleWeekCount(int total, {required bool fullHistory}) =>
    fullHistory || total <= kFreeChartWeeks ? total : kFreeChartWeeks;

/// Názvy plánů z hotových programů ve všech jazycích aplikace.
/// Plány přidané z programu se do limitu vlastních plánů nepočítají.
Set<String> templatePlanNames() => {
      for (final program in templatePrograms)
        for (final plan in program.plans) ...[
          plan.nameEn,
          plan.nameCs,
          for (final t in seedTranslations.values)
            if (t.planNames[plan.nameEn] case final name?) name,
        ],
    };

/// Počet vlastních plánů: plány, jejichž název neodpovídá žádnému
/// plánu z hotových programů. ([names] = názvy plánů, které nejsou
/// vestavěné.)
int countCustomPlans(Iterable<String> names, {Set<String>? templateNames}) {
  final templates = templateNames ?? templatePlanNames();
  return names.where((n) => !templates.contains(n.trim())).length;
}
