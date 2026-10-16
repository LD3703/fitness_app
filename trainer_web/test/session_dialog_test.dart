import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:gymbar_trainer/backend.dart';
import 'package:gymbar_trainer/ui/sessions.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('formulář termínu vrátí pozvánku s plánem a opakováním',
      (tester) async {
    await initializeDateFormatting('en');
    CoachSession? result;
    final plan = ClientPlan(
      assigned: const AssignedPlan(
        id: 'p1',
        plan: CoachPlan(name: 'Nohy'),
        version: 1,
        trainerName: 'Tom',
      ),
    );
    final start = DateTime.now().add(const Duration(days: 2));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<CoachSession>(
            context: context,
            builder: (_) => SessionDialog(
              trainerName: 'Tom',
              plans: [plan],
              initial: CoachSession(
                id: 'x',
                startAt: DateTime(start.year, start.month, start.day, 18),
                durationMin: 90,
                weeks: 6,
                title: '',
                planId: 'p1',
                trainerName: 'Tom',
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Vem si švihadlo');
    await tester.tap(find.text('Send invitation'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect((result!.id, result!.weeks, result!.durationMin, result!.planId),
        ('x', 6, 90, 'p1'));
    // Prázdný název → název plánu.
    expect(result!.title, 'Nohy');
    expect(result!.note, 'Vem si švihadlo');
    expect(result!.startAt.hour, 18);
  });
}
