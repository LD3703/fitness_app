// Trénink klienta sdílený s trenérem (coachLinks/{klient}/workouts/{id}).
// Posílá se jen se souhlasem klienta: datum, délka, název, cviky a série.
// Nic dalšího (pocit, poznámky, kalorie) – viz docs/coach.md.
import 'json.dart';

const coachWorkoutMaxExercises = 40;
const coachWorkoutMaxSets = 30;

/// Zapsaná série.
class CoachSet {
  const CoachSet({
    this.kg,
    this.reps,
    this.seconds,
    this.warmup = false,
    this.drop = false,
  });

  factory CoachSet.fromJson(Object? json) {
    final m = asMap(json, 'set');
    return CoachSet(
      kg: optDouble(m['kg'], max: 1000),
      reps: optInt(m['r'], max: 10000),
      seconds: optInt(m['s'], max: 86400),
      warmup: optBool(m['w']),
      drop: optBool(m['d']),
    );
  }

  final double? kg;
  final int? reps;
  final int? seconds;
  final bool warmup;
  final bool drop;

  /// Počítá se do objemu (ne rozcvička).
  bool get working => !warmup;

  /// Objem série v kg (váha × opakování).
  double get volumeKg =>
      warmup || kg == null || reps == null ? 0 : kg! * reps!;

  Map<String, Object?> toJson() => {
        if (kg != null) 'kg': kg,
        if (reps != null) 'r': reps,
        if (seconds != null) 's': seconds,
        if (warmup) 'w': true,
        if (drop) 'd': true,
      };
}

/// Cvik v tréninku.
class CoachWorkoutExercise {
  const CoachWorkoutExercise({
    this.slug,
    required this.nameEn,
    required this.nameCs,
    this.sets = const [],
  });

  factory CoachWorkoutExercise.fromJson(Object? json) {
    final m = asMap(json, 'exercise');
    final en = optString(m['en'], max: 80);
    final cs = optString(m['cs'], max: 80);
    final name = en ?? cs ?? optString(m['slug'], max: 60) ?? '?';
    return CoachWorkoutExercise(
      slug: optString(m['slug'], max: 60),
      nameEn: name,
      nameCs: cs ?? name,
      sets: [
        for (final s in asList(m['sets'] ?? const [], 'sets')
            .take(coachWorkoutMaxSets))
          CoachSet.fromJson(s),
      ],
    );
  }

  final String? slug;
  final String nameEn;
  final String nameCs;
  final List<CoachSet> sets;

  /// Klíč cviku pro grafy: slug, u vlastních cviků název.
  String get key => slug ?? 'name:${nameEn.toLowerCase()}';

  String nameFor(String lang) => lang == 'cs' ? nameCs : nameEn;

  /// Nejtěžší pracovní série (bez rozcvičky a drop sérií, aspoň 1 opak.).
  double? get topKg {
    double? best;
    for (final s in sets) {
      if (s.warmup || s.drop || s.kg == null || (s.reps ?? 0) < 1) continue;
      if (best == null || s.kg! > best) best = s.kg;
    }
    return best;
  }

  double get volumeKg => sets.fold(0, (v, s) => v + s.volumeKg);

  int get workingSets => sets.where((s) => s.working).length;

  Map<String, Object?> toJson() => {
        if (slug != null) 'slug': slug,
        'en': clip(nameEn, 80),
        'cs': clip(nameCs, 80),
        'sets': [for (final s in sets.take(coachWorkoutMaxSets)) s.toJson()],
      };
}

/// Jeden trénink.
class CoachWorkout {
  const CoachWorkout({
    required this.id,
    required this.startedAt,
    this.durationMin,
    this.title,
    this.exercises = const [],
  });

  /// [json] = dokument Firestore (startedAtMs je číslo, ne Timestamp –
  /// stejně v aplikaci i na webu).
  factory CoachWorkout.fromJson(String id, Object? json) {
    final m = asMap(json, 'workout');
    final ms = optInt(m['startedAtMs'], min: 0, max: maxTimeMs);
    if (ms == null) throw CoachFormatException('startedAtMs missing');
    return CoachWorkout(
      id: id,
      startedAt: DateTime.fromMillisecondsSinceEpoch(ms),
      durationMin: optInt(m['durationMin'], max: 24 * 60),
      title: optString(m['title'], max: 60),
      exercises: [
        for (final e in asList(m['exercises'] ?? const [], 'exercises')
            .take(coachWorkoutMaxExercises))
          CoachWorkoutExercise.fromJson(e),
      ],
    );
  }

  /// ID dokumentu: „`s<id tréninku v telefonu>`“.
  final String id;
  final DateTime startedAt;
  final int? durationMin;

  /// Název plánu (nebo null u volného tréninku).
  final String? title;
  final List<CoachWorkoutExercise> exercises;

  double get volumeKg => exercises.fold(0, (v, e) => v + e.volumeKg);

  int get workingSets => exercises.fold(0, (n, e) => n + e.workingSets);

  Map<String, Object?> toJson() => {
        'startedAtMs': startedAt.millisecondsSinceEpoch,
        if (durationMin != null) 'durationMin': durationMin,
        if (title != null) 'title': clip(title!, 60),
        'exercises': [
          for (final e in exercises.take(coachWorkoutMaxExercises)) e.toJson(),
        ],
      };
}

/// ID dokumentu tréninku podle ID v databázi telefonu.
String coachWorkoutId(int sessionId) => 's$sessionId';

/// Tělesná váha sdílená s trenérem (coachLinks/{klient}/meta/weight),
/// jen když to klient zvlášť povolí.
class CoachWeightPoint {
  const CoachWeightPoint(this.day, this.kg);

  final DateTime day;
  final double kg;

  static List<CoachWeightPoint> listFromJson(Object? json) {
    if (json is! Map) return const [];
    final points = json['points'];
    if (points is! List) return const [];
    final out = <CoachWeightPoint>[];
    for (final p in points) {
      if (p is! Map) continue;
      final ms = optInt(p['d'], min: 0, max: maxTimeMs);
      final kg = optDouble(p['kg'], min: 20, max: 400);
      if (ms == null || kg == null) continue;
      out.add(CoachWeightPoint(DateTime.fromMillisecondsSinceEpoch(ms), kg));
    }
    out.sort((a, b) => a.day.compareTo(b.day));
    return out;
  }

  static Map<String, Object?> listToJson(Iterable<CoachWeightPoint> points) =>
      {
        'points': [
          for (final p in points)
            {'d': p.day.millisecondsSinceEpoch, 'kg': p.kg},
        ],
      };
}

/// Max. počet bodů tělesné váhy v dokumentu (zhruba rok denně).
const coachWeightMaxPoints = 400;
