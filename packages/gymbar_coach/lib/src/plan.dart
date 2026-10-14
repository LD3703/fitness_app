// Tréninkový plán přenášený mezi trenérem a klientem (coachLinks/{klient}/
// plans/{id}) nebo sdílený odkazem (sharedPlans/{id}). Odpovídá plánu
// v aplikaci (WorkoutPlans + PlanExercises + PlanSets), jen cviky jsou
// podle slugu (vestavěné) nebo podle názvu (vlastní).
import 'json.dart';

/// Limity (stejně ve firestore.rules a v editoru na webu).
const coachPlanNameMax = 60;
const coachPlanDescriptionMax = 500;
const coachPlanMaxExercises = 40;
const coachPlanMaxSets = 20;

/// Max. délka poznámky ke cviku v plánu (stejně jako exerciseNoteMax
/// v aplikaci).
const coachExerciseNoteMax = 300;

/// Cílová série.
class CoachPlanSet {
  const CoachPlanSet({
    required this.reps,
    this.kg,
    this.warmup = false,
    this.drop = false,
  });

  factory CoachPlanSet.fromJson(Object? json) {
    final m = asMap(json, 'set');
    return CoachPlanSet(
      reps: optInt(m['r'], min: 0, max: 10000) ?? 10,
      kg: optDouble(m['kg'], max: 1000),
      warmup: optBool(m['w']),
      drop: optBool(m['d']),
    );
  }

  /// Opakování (u cviků na čas sekundy).
  final int reps;

  /// Cílová váha v kg (null = podle minula).
  final double? kg;
  final bool warmup;
  final bool drop;

  Map<String, Object?> toJson() => {
        'r': reps,
        if (kg != null) 'kg': kg,
        if (warmup) 'w': true,
        if (drop) 'd': true,
      };

  @override
  bool operator ==(Object other) =>
      other is CoachPlanSet &&
      other.reps == reps &&
      other.kg == kg &&
      other.warmup == warmup &&
      other.drop == drop;

  @override
  int get hashCode => Object.hash(reps, kg, warmup, drop);
}

/// Cvik v plánu.
class CoachPlanExercise {
  const CoachPlanExercise({
    this.slug,
    required this.nameEn,
    required this.nameCs,
    this.muscle,
    this.equipment,
    this.type,
    this.restSeconds,
    this.restAuto = true,
    this.superset,
    this.repMin,
    this.repMax,
    this.note,
    this.sets = const [],
  });

  factory CoachPlanExercise.fromJson(Object? json) {
    final m = asMap(json, 'exercise');
    final en = optString(m['en'], max: 80);
    final cs = optString(m['cs'], max: 80);
    final name = en ?? cs ?? reqString(m['slug'], 'exercise name');
    final sets = [
      for (final s in asList(m['sets'] ?? const [], 'sets')
          .take(coachPlanMaxSets))
        CoachPlanSet.fromJson(s),
    ];
    return CoachPlanExercise(
      slug: optString(m['slug'], max: 60),
      nameEn: name,
      nameCs: cs ?? name,
      muscle: optString(m['muscle'], max: 30),
      equipment: optString(m['equipment'], max: 30),
      type: optString(m['type'], max: 30),
      restSeconds: optInt(m['rest'], min: 0, max: 3600),
      restAuto: m['restAuto'] != false,
      superset: optInt(m['ss'], min: 0, max: 1000),
      repMin: optInt(m['repMin'], min: 1, max: 1000),
      repMax: optInt(m['repMax'], min: 1, max: 1000),
      note: optString(m['note'], max: coachExerciseNoteMax),
      sets: sets,
    );
  }

  /// Slug vestavěného cviku (např. „bench_press“), u vlastního null.
  final String? slug;
  final String nameEn;
  final String nameCs;

  /// U vlastního cviku: názvy enumů z aplikace (MuscleGroup, Equipment,
  /// ExerciseType) – podle nich se u klienta cvik založí.
  final String? muscle;
  final String? equipment;
  final String? type;

  /// Ruční pauza v sekundách; platí, jen když [restAuto] je false.
  final int? restSeconds;
  final bool restAuto;

  /// Supersérie (po sobě jdoucí cviky se stejnou hodnotou).
  final int? superset;
  final int? repMin;
  final int? repMax;

  /// Poznámka ke cviku (technika, tempo…) – u klienta se ukáže v plánu
  /// i při tréninku.
  final String? note;
  final List<CoachPlanSet> sets;

  /// Název v jazyce [lang] („cs“ / ostatní).
  String nameFor(String lang) => lang == 'cs' ? nameCs : nameEn;

  Map<String, Object?> toJson() => {
        if (slug != null) 'slug': slug,
        'en': clip(nameEn, 80),
        'cs': clip(nameCs, 80),
        if (muscle != null) 'muscle': muscle,
        if (equipment != null) 'equipment': equipment,
        if (type != null) 'type': type,
        if (restSeconds != null) 'rest': restSeconds,
        if (!restAuto) 'restAuto': false,
        if (superset != null) 'ss': superset,
        if (repMin != null) 'repMin': repMin,
        if (repMax != null) 'repMax': repMax,
        if (note != null && note!.trim().isNotEmpty)
          'note': clip(note!, coachExerciseNoteMax),
        'sets': [for (final s in sets.take(coachPlanMaxSets)) s.toJson()],
      };
}

/// Celý plán.
class CoachPlan {
  const CoachPlan({
    required this.name,
    this.description,
    this.weekdaysMask = 0,
    this.exercises = const [],
  });

  factory CoachPlan.fromJson(Object? json) {
    final m = asMap(json, 'plan');
    return CoachPlan(
      name: reqString(m['name'], 'plan name', max: coachPlanNameMax),
      description: optString(m['desc'], max: coachPlanDescriptionMax),
      weekdaysMask: optInt(m['days'], min: 0, max: 127) ?? 0,
      exercises: [
        for (final e in asList(m['exercises'] ?? const [], 'exercises')
            .take(coachPlanMaxExercises))
          CoachPlanExercise.fromJson(e),
      ],
    );
  }

  final String name;
  final String? description;

  /// Dny v týdnu: bit 0 = pondělí … bit 6 = neděle (jako v aplikaci).
  final int weekdaysMask;
  final List<CoachPlanExercise> exercises;

  Map<String, Object?> toJson() => {
        'name': clip(name, coachPlanNameMax),
        if (description != null && description!.trim().isNotEmpty)
          'desc': clip(description!, coachPlanDescriptionMax),
        'days': weekdaysMask & 127,
        'exercises': [
          for (final e in exercises.take(coachPlanMaxExercises)) e.toJson(),
        ],
      };

  /// Počet pracovních (ne rozcvičkových) sérií – do přehledu.
  int get workingSets => exercises.fold(
      0, (n, e) => n + e.sets.where((s) => !s.warmup).length);
}

/// Plán od trenéra pro klienta (coachLinks/{klient}/plans/{id}).
class AssignedPlan {
  const AssignedPlan({
    required this.id,
    required this.plan,
    required this.version,
    required this.trainerName,
  });

  /// [json] = dokument Firestore (pole plan, version, trainerName).
  factory AssignedPlan.fromJson(String id, Object? json) {
    final m = asMap(json, 'assigned plan');
    return AssignedPlan(
      id: id,
      plan: CoachPlan.fromJson(m['plan']),
      version: optInt(m['version'], min: 1) ?? 1,
      trainerName: optString(m['trainerName'], max: 40) ?? '?',
    );
  }

  final String id;
  final CoachPlan plan;

  /// Zvyšuje se při každé úpravě – podle něj klient pozná novou verzi.
  final int version;
  final String trainerName;
}

/// Klíč, podle kterého aplikace pozná plán od trenéra / sdílený plán
/// (WorkoutPlans.remoteId): „coach:<id>“, „shared:<id>“.
String assignedPlanRemoteId(String planId) => 'coach:$planId';
String sharedPlanRemoteId(String planId) => 'shared:$planId';
