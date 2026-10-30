// Mazání přejetím s „Vrátit“ (lib/ui/swipe_to_delete.dart) a odebrání
// cviku z rozpracovaného tréninku (AppDatabase.removeSessionBlock).
import 'package:drift/native.dart';
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/features/workout/workout_service.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/ui/swipe_to_delete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seznam tří položek; smazaná zmizí hned, „Vrátit“ ji vrátí.
class _List extends StatefulWidget {
  const _List({required this.committed});

  final List<String> committed;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  final items = ['A', 'B', 'C'];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          children: [
            for (final (i, it) in items.indexed)
              SwipeToDelete(
                key: ValueKey(it),
                onDeleted: () {
                  setState(() => items.remove(it));
                  showUndoSnackBar(
                    context,
                    message: 'Smazáno $it',
                    onUndo: () => setState(() => items.insert(i, it)),
                    onCommit: () => widget.committed.add(it),
                  );
                },
                child: ListTile(title: Text('Položka $it')),
              ),
          ],
        ),
      );
}

Widget _app(List<String> committed) => MaterialApp(
      locale: const Locale('cs'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _List(committed: committed),
    );

void main() {
  testWidgets('přejetí doleva smaže, Vrátit vrátí bez zápisu', (tester) async {
    final committed = <String>[];
    await tester.pumpWidget(_app(committed));
    await tester.drag(find.text('Položka B'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Položka B'), findsNothing);
    expect(find.text('Smazáno B'), findsOneWidget);

    await tester.tap(find.text('Vrátit'));
    await tester.pumpAndSettle();
    expect(find.text('Položka B'), findsOneWidget);
    expect(committed, isEmpty);
  });

  testWidgets('bez Vrátit se smazání po zavření snackbaru potvrdí',
      (tester) async {
    final committed = <String>[];
    await tester.pumpWidget(_app(committed));
    await tester.drag(find.text('Položka A'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    // Další smazání nahradí snackbar – první se potvrdí hned.
    await tester.drag(find.text('Položka C'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(committed, ['A']);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(committed, ['A', 'C']);
  });

  testWidgets('krátké přejetí nic nesmaže', (tester) async {
    final committed = <String>[];
    await tester.pumpWidget(_app(committed));
    await tester.drag(find.text('Položka A'), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(find.text('Položka A'), findsOneWidget);
    expect(committed, isEmpty);
  });

  test('odebraný cvik z plánu se po návratu do tréninku nenačte', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final exercises = await db.select(db.exercises).get();
    final squat = exercises.firstWhere((e) => e.slug == 'back_squat');
    final bench = exercises.firstWhere((e) => e.slug == 'bench_press');
    final planId = await db.createPlan('Test');
    await db.addExerciseToPlan(planId, squat.id);
    await db.addExerciseToPlan(planId, bench.id);
    final session = await db.startSession(planId: planId);
    final setId = await db.insertSet(
      sessionId: session,
      exerciseId: squat.id,
      position: setPositionFor(0, 0),
      weightKg: 60,
      reps: 8,
    );

    var setup = await loadWorkoutSetup(db, session);
    expect(setup.blocks.map((b) => b.exercise.id), [squat.id, bench.id]);

    await db.removeSessionBlock(session,
        exerciseId: squat.id, slot: 0, setIds: [setId]);
    setup = await loadWorkoutSetup(db, session);
    expect(setup.blocks.map((b) => b.exercise.id), [bench.id]);
    expect(await db.getSessionSets(session), isEmpty);

    // Stejný cvik přidaný znovu (se sérií) se načte jako přidaný cvik.
    await db.insertSet(
      sessionId: session,
      exerciseId: squat.id,
      position: setPositionFor(1, 0),
      weightKg: 60,
      reps: 8,
    );
    setup = await loadWorkoutSetup(db, session);
    expect(setup.blocks.map((b) => b.exercise.id), [bench.id, squat.id]);
  });
}
