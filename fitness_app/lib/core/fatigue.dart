// Model únavy svalů (čistý Dart, testy: test/fatigue_test.dart).
//
// Z dokončených tréninků za posledních [fatigueWindow] se pro každou partii
// sečte „zátěž“:
// - každá pracovní série přidá 1,0 hlavní partii cviku a 0,5 každé
//   vedlejší partii (viz data/seed/exercise_secondary_muscles.dart),
// - drop série se počítá 0,7×, rozcvička vůbec,
// - cvik na celé tělo přidá 0,3 každé partii,
// - pocit po tréninku (lehké / akorát / náročné) násobí zátěž celého
//   tréninku 0,8 / 1,0 / 1,25, trénink plán B (krátká domácí rutina) 0,5×.
// Zátěž pak exponenciálně odeznívá s poločasem podle velikosti partie
// (velké 36 h, malé 24 h). Výsledek se převede na 0–100 %:
// [fatigueFullScaleLoad] čerstvých těžkých sérií ≈ 100 %.
//
// Jde o orientační odhad pro motivaci a plánování, ne o měření.

import 'dart:math' as math;

import '../data/enums.dart';

/// Jedna série pro výpočet únavy.
typedef FatigueSet = ({
  MuscleGroup primary,
  Set<MuscleGroup> secondary,
  bool isWarmup,
  bool isDrop,
});

/// Dokončený trénink pro výpočet únavy. [at] = konec tréninku.
typedef FatigueSession = ({
  DateTime at,
  WorkoutFeeling? feeling,
  bool isPlanB,
  List<FatigueSet> sets,
});

/// Únava partií v procentech (0–100) a počet tréninků v okně.
typedef FatigueReport = ({Map<MuscleGroup, double> percent, int sessions});

enum FatigueStatus { recovered, recovering, fatigued }

/// Jak daleko do minulosti se tréninky započítávají.
const fatigueWindow = Duration(days: 7);

/// Zátěž (v „těžkých sériích“), která odpovídá 100 % únavy.
const fatigueFullScaleLoad = 12.0;

/// Od kolika procent se před tréninkem zobrazí upozornění.
const fatigueWarningPercent = 80.0;

/// Hranice stavů: pod 30 % zotaveno, od 70 % unaveno.
const fatigueRecoveringFrom = 30.0;
const fatigueFatiguedFrom = 70.0;

const _primaryLoad = 1.0;
const _secondaryLoad = 0.5;
const _fullBodyLoad = 0.3;
const _dropFactor = 0.7;
const _planBFactor = 0.5;

/// Partie, pro které se únava počítá (celé tělo se rozkládá do ostatních).
const fatigueGroups = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.biceps,
  MuscleGroup.triceps,
  MuscleGroup.legs,
  MuscleGroup.glutes,
  MuscleGroup.core,
];

/// Poločas odeznění zátěže v hodinách: velké partie 36 h, malé 24 h.
double fatigueHalfLifeHours(MuscleGroup g) => switch (g) {
      MuscleGroup.legs ||
      MuscleGroup.back ||
      MuscleGroup.glutes ||
      MuscleGroup.chest =>
        36.0,
      MuscleGroup.shoulders ||
      MuscleGroup.biceps ||
      MuscleGroup.triceps ||
      MuscleGroup.core ||
      MuscleGroup.fullBody =>
        24.0,
    };

/// Násobitel zátěže tréninku podle pocitu (bez vyplnění 1,0).
double feelingFactor(WorkoutFeeling? f) => switch (f) {
      null => 1.0,
      WorkoutFeeling.easy => 0.8,
      WorkoutFeeling.ok => 1.0,
      WorkoutFeeling.hard => 1.25,
    };

/// Zátěž jedné série po partiích (bez odeznění a pocitu).
Map<MuscleGroup, double> setLoad(FatigueSet s) {
  final result = <MuscleGroup, double>{};
  if (s.isWarmup) return result;
  final factor = s.isDrop ? _dropFactor : 1.0;
  void add(MuscleGroup g, double v) =>
      result[g] = (result[g] ?? 0) + v * factor;

  if (s.primary == MuscleGroup.fullBody) {
    for (final g in fatigueGroups) {
      add(g, _fullBodyLoad);
    }
  } else {
    add(s.primary, _primaryLoad);
  }
  for (final g in s.secondary) {
    if (g == s.primary) continue;
    if (g == MuscleGroup.fullBody) {
      for (final x in fatigueGroups) {
        add(x, _fullBodyLoad * _secondaryLoad);
      }
    } else {
      add(g, _secondaryLoad);
    }
  }
  return result;
}

/// Kolik zátěže zbývá po [hours] hodinách při poločasu [halfLifeHours].
double decayFactor(double hours, double halfLifeHours) {
  if (hours <= 0) return 1;
  return math.pow(0.5, hours / halfLifeHours).toDouble();
}

/// Únava všech partií [fatigueGroups] v procentech (0–100) k času [now].
FatigueReport computeFatigue(Iterable<FatigueSession> sessions, DateTime now) {
  final load = {for (final g in fatigueGroups) g: 0.0};
  final from = now.subtract(fatigueWindow);
  var count = 0;
  for (final session in sessions) {
    if (session.at.isBefore(from)) continue;
    count++;
    final hours = now.difference(session.at).inMinutes / 60.0;
    final sessionFactor =
        feelingFactor(session.feeling) * (session.isPlanB ? _planBFactor : 1);
    for (final s in session.sets) {
      setLoad(s).forEach((g, v) {
        if (!load.containsKey(g)) return;
        load[g] = load[g]! +
            v * sessionFactor * decayFactor(hours, fatigueHalfLifeHours(g));
      });
    }
  }
  return (
    percent: {
      for (final e in load.entries)
        e.key: (e.value / fatigueFullScaleLoad * 100).clamp(0.0, 100.0),
    },
    sessions: count,
  );
}

FatigueStatus fatigueStatus(double percent) {
  if (percent >= fatigueFatiguedFrom) return FatigueStatus.fatigued;
  if (percent >= fatigueRecoveringFrom) return FatigueStatus.recovering;
  return FatigueStatus.recovered;
}

/// Partie seřazené od nejunavenější (při shodě v pořadí výčtu).
List<MapEntry<MuscleGroup, double>> sortedByFatigue(FatigueReport report) =>
    report.percent.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.index.compareTo(b.key.index);
      });

/// Nejunavenější z [groups] s únavou aspoň [threshold] %, jinak null.
/// Cvik na celé tělo se nebere (rozkládá se do ostatních partií).
MapEntry<MuscleGroup, double>? mostFatiguedOf(
  FatigueReport report,
  Iterable<MuscleGroup> groups, {
  double threshold = fatigueWarningPercent,
}) {
  MapEntry<MuscleGroup, double>? best;
  for (final g in groups.toSet()) {
    final p = report.percent[g];
    if (p == null || p < threshold) continue;
    if (best == null || p > best.value) best = MapEntry(g, p);
  }
  return best;
}
