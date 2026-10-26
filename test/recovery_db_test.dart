import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/core/auto_progression.dart';
import 'package:fitness_app/core/readiness.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/data/seed/plan_templates.dart';
import 'package:fitness_app/features/workout/workout_service.dart';
import 'package:fitness_app/modules/health/recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('denní data regenerace: uložení a přepsání dne', () async {
    final day = DateTime(2026, 10, 26, 7, 30);
    await db.upsertRecoveryDay(
        RecoveryDay(day: day, sleepMinutes: 400, hrvMs: 55, restingHr: 52));
    await db.upsertRecoveryDay(
        RecoveryDay(day: day, sleepMinutes: 420, hrvMs: 58, restingHr: 51));
    final rows = await db.watchRecoveryDays(DateTime(2026, 10, 1)).first;
    expect(rows, hasLength(1));
    expect(rows.single.day, DateTime(2026, 10, 26));
    expect(rows.single.sleepMinutes, 420);
    expect(await db.latestRecoveryDay(), DateTime(2026, 10, 26));
  });

  test('lehčí trénink: o třetinu méně pracovních sérií', () async {
    await db.addProgram(
      templatePrograms.firstWhere((p) => p.slug == 'strength_5x5'),
      languageCode: 'cs',
    );
    final plan = (await db.select(db.workoutPlans).get()).first;
    final normal =
        await loadWorkoutSetup(db, await db.startSession(planId: plan.id));
    final light = await loadWorkoutSetup(
        db, await db.startSession(planId: plan.id, light: true));
    int working(WorkoutBlockData b) =>
        b.targets.where((t) => !t.isWarmup && !t.isDrop).length;
    expect(normal.light, isFalse);
    expect(light.light, isTrue);
    // Dřep 5 × 5 → 4 pracovní série, rozcvička zůstává.
    expect(working(normal.blocks.first), 5);
    expect(working(light.blocks.first), 4);
    expect(light.blocks.first.targets.first.isWarmup, isTrue);
  });

  test('tep tréninku a lehčí trénink v progresi', () async {
    final id = await db.startSession();
    await db.saveSessionHeartRate(
      id,
      const HeartRateSummary(
          average: 128, max: 171, zoneSeconds: [0, 60, 600, 900, 300, 0]),
      kcal: 420,
    );
    final s = await db.getSession(id);
    expect((s.avgHeartRate, s.maxHeartRate, s.heartRateKcal), (128, 171, 420));
    expect(HeartRateSummary.zonesFromText(s.heartRateZones),
        [0, 60, 600, 900, 300, 0]);
    expect(
        ProgressionBlockers.none
            .withLowReadiness()
            .reasonFor(MuscleGroup.chest),
        HoldReason.readiness);
    // Nemoc má přednost.
    expect(
        const ProgressionBlockers(illness: true)
            .withLowReadiness()
            .reasonFor(MuscleGroup.chest),
        HoldReason.illness);
  });
}
