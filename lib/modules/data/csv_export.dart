import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';
import 'csv.dart';
import 'data_queries.dart';

/// Vytvoří CSV soubory se všemi daty uživatele v dočasné složce.
/// Váhy jsou vždy v kg a objemy v ml (bez ohledu na zvolené jednotky).
Future<List<File>> writeCsvExport(AppDatabase db) async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory(
    '${tmp.path}/csv_export_${DateTime.now().millisecondsSinceEpoch}',
  );
  await dir.create(recursive: true);

  Future<File> write(String name, String content) async {
    final f = File('${dir.path}/$name');
    await f.writeAsString(content, encoding: utf8, flush: true);
    return f;
  }

  final workouts = await db.exportWorkouts();
  final sets = await db.exportSets();
  final weights = await db.exportBodyWeights();
  final water = await db.exportWater();
  final periods = await db.exportPeriods();

  return [
    await write(
      'workouts.csv',
      buildCsv(
        ['session_id', 'start', 'end', 'kind', 'plan_name', 'kcal', 'feeling'],
        [
          for (final w in workouts)
            [
              w.session.id,
              w.session.startedAt,
              w.session.endedAt,
              w.session.kind.name,
              w.planName,
              w.session.estimatedKcal == null
                  ? null
                  : w.session.estimatedKcal!.roundToDouble(),
              w.session.feeling?.name,
            ],
        ],
      ),
    ),
    await write(
      'sets.csv',
      buildCsv(
        [
          'session_id',
          'date',
          'exercise',
          'exercise_slug',
          'set_number',
          'warmup',
          'drop',
          'superset',
          'weight_kg',
          'reps',
          'duration_s',
        ],
        [
          for (final s in sets)
            [
              s.session.id,
              csvDate(s.session.startedAt),
              s.exercise.nameEn,
              s.exercise.slug,
              s.set.position + 1,
              s.set.isWarmup,
              s.set.isDrop,
              s.set.supersetGroup,
              s.set.weightKg,
              s.set.reps,
              s.set.durationSeconds,
            ],
        ],
      ),
    ),
    await write(
      'body_weight.csv',
      buildCsv(
        ['date', 'weight_kg'],
        [
          for (final w in weights) [csvDate(w.day), w.weightKg],
        ],
      ),
    ),
    await write(
      'water.csv',
      buildCsv(
        ['logged_at', 'amount_ml'],
        [
          for (final w in water) [w.loggedAt, w.amountMl],
        ],
      ),
    ),
    await write(
      'periods.csv',
      buildCsv(
        ['type', 'start', 'end', 'muscle_groups', 'note'],
        [
          for (final p in periods)
            [
              p.type.name,
              csvDate(p.startDate),
              p.endDate == null ? null : csvDate(p.endDate!),
              p.muscleGroups,
              p.note,
            ],
        ],
      ),
    ),
  ];
}
