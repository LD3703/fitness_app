// Vývoj úrovně pokročilosti (lib/core/experience_level.dart): návrh
// postupu po pravidelném tréninku a návratu po dlouhé pauze.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitness_app/core/experience_level.dart';
import 'package:fitness_app/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// [count] tréninků po [everyDays] dnech, poslední [lastDaysAgo] dní před
/// [now].
List<DateTime> _workouts(DateTime now, int count,
        {int everyDays = 3, int lastDaysAgo = 1}) =>
    [
      for (var i = 0; i < count; i++)
        DateTime(now.year, now.month, now.day - lastDaysAgo - i * everyDays,
            18),
    ];

void main() {
  final now = DateTime(2026, 10, 26, 12);
  const beginner = ExperienceLevel.beginner;
  const intermediate = ExperienceLevel.intermediate;
  const advanced = ExperienceLevel.advanced;

  test('začátečník po půl roce pravidelného tréninku → mírně pokročilý', () {
    // Každé 3 dny (2–3× týdně) 7 měsíců.
    final workouts = _workouts(now, 70, everyDays: 3);
    final s = suggestLevelChange(
        current: beginner, since: null, workouts: workouts, now: now);
    expect(s, (level: intermediate, reason: LevelChangeReason.progress));

    final p = levelProgress(
        current: beginner, since: null, workouts: workouts, now: now)!;
    expect(p.next, intermediate);
    expect(p.workouts, 70);
    expect(p.weeks, greaterThanOrEqualTo(29));
  });

  test('málo týdnů, málo tréninků nebo nepravidelnost → nic', () {
    // Hodně tréninků, ale jen 3 měsíce.
    expect(
        suggestLevelChange(
            current: beginner,
            since: null,
            workouts: _workouts(now, 60, everyDays: 1),
            now: now),
        isNull);
    // Půl roku, ale jen 1× týdně.
    expect(
        suggestLevelChange(
            current: beginner,
            since: null,
            workouts: _workouts(now, 30, everyDays: 7),
            now: now),
        isNull);
    // Dost tréninků, ale posledních 12 týdnů skoro nic.
    final old = [
      ..._workouts(now, 50, everyDays: 3, lastDaysAgo: 70),
      DateTime(2026, 10, 20),
    ];
    expect(
        suggestLevelChange(
            current: beginner, since: null, workouts: old, now: now),
        isNull);
  });

  test('úroveň se počítá od jejího zvolení', () {
    final workouts = _workouts(now, 60, everyDays: 3);
    final since = DateTime(2026, 8, 1);
    expect(
        suggestLevelChange(
            current: beginner, since: since, workouts: workouts, now: now),
        isNull);
    final p = levelProgress(
        current: beginner, since: since, workouts: workouts, now: now)!;
    expect(p.workouts, lessThan(60));
  });

  test('mírně pokročilý → pokročilý až po 1,5 roce a 180 trénincích', () {
    final since = DateTime(2025, 1, 1);
    final enough = _workouts(now, 200, everyDays: 2);
    expect(
        suggestLevelChange(
            current: intermediate, since: since, workouts: enough, now: now),
        (level: advanced, reason: LevelChangeReason.progress));
    expect(
        suggestLevelChange(
            current: intermediate,
            since: since,
            workouts: _workouts(now, 120, everyDays: 4),
            now: now),
        isNull);
    expect(
        levelProgress(
            current: advanced, since: since, workouts: enough, now: now),
        isNull);
  });

  test('po 12 týdnech bez tréninku o úroveň níž', () {
    final workouts = _workouts(now, 40, everyDays: 3, lastDaysAgo: 90);
    expect(
        suggestLevelChange(
            current: intermediate,
            since: DateTime(2025, 1, 1),
            workouts: workouts,
            now: now),
        (level: beginner, reason: LevelChangeReason.longBreak));
    // Začátečník níž nejde, 10 týdnů pauzy nevadí.
    expect(
        suggestLevelChange(
            current: beginner, since: null, workouts: workouts, now: now),
        isNull);
    expect(
        suggestLevelChange(
            current: advanced,
            since: DateTime(2025, 1, 1),
            workouts: _workouts(now, 40, lastDaysAgo: 70),
            now: now),
        isNull);
    // Čerstvě zvolená úroveň se nezpochybňuje.
    expect(
        suggestLevelChange(
            current: advanced,
            since: DateTime(2026, 10, 1),
            workouts: workouts,
            now: now),
        isNull);
  });

  test('odmítnutý návrh se 30 dní neukáže', () {
    final workouts = _workouts(now, 70, everyDays: 3);
    LevelSuggestion? at(DateTime promptAt) => suggestLevelChange(
        current: beginner,
        since: null,
        workouts: workouts,
        now: now,
        promptAt: promptAt);
    expect(at(DateTime(2026, 10, 10)), isNull);
    expect(at(DateTime(2026, 9, 20)), isNotNull);
  });

  group('databáze', () {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('změna úrovně nastaví začátek a zapomene odmítnutí', () async {
      var p = await db.select(db.userProfiles).getSingle();
      expect(p.experienceLevel, ExperienceLevel.beginner.index);
      expect(p.experienceSince, isNull);
      await db.dismissExperiencePrompt(now: now);
      p = await db.select(db.userProfiles).getSingle();
      expect(p.experiencePromptAt, now);
      await db.setExperienceLevel(intermediate, now: now);
      p = await db.select(db.userProfiles).getSingle();
      expect(p.experienceLevel, intermediate.index);
      expect(p.experienceSince, now);
      expect(p.experiencePromptAt, isNull);
    });

    test('Plán B se do úrovně nepočítá', () async {
      final full = await db.startSession(startedAt: DateTime(2026, 10, 1));
      await db.finishSession(full, endedAt: DateTime(2026, 10, 1, 1));
      final planB = await db.startSession(
          startedAt: DateTime(2026, 10, 2), kind: SessionKind.planB);
      await db.finishSession(planB, endedAt: DateTime(2026, 10, 2, 0, 5));
      final dates =
          await db.watchFullWorkoutDatesSince(DateTime(2026, 9, 1)).first;
      expect(dates, [DateTime(2026, 10, 1)]);
    });
  });
}
