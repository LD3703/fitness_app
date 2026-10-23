// Obrazovka „Jak si vedu“ (lib/modules/social/ui/strength_rank_screen.dart)
// s ukázkovými daty místo Firestore a databáze.
import 'package:fitness_app/data/database.dart';
import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:fitness_app/modules/social/gym/gym_service.dart';
import 'package:fitness_app/modules/social/gym/strength_rank.dart';
import 'package:fitness_app/modules/social/social_backend.dart';
import 'package:fitness_app/modules/social/ui/strength_rank_screen.dart';
import 'package:fitness_app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('cs'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StrengthRankScreen(),
      ),
    );

final base = <Override>[
  socialAvailableProvider.overrideWithValue(true),
  gymMembershipProvider.overrideWith((ref) => Stream.value(null)),
  profileProvider.overrideWith((ref) => const Stream<UserProfile>.empty()),
];

void main() {
  testWidgets('percentil ve světě a „málo dat“ u malé skupiny', (tester) async {
    await tester.pumpWidget(app([
      ...base,
      myLiftBestsProvider.overrideWith((ref) async => [(GymCategory.benchPress, 100.0)]),
      liftStatsProvider.overrideWith((ref, docId) async => {
            if (docId == liftStatsDocId(kLiftStatsWorld, GymCategory.benchPress))
              'all_all': LiftDistribution.fromMap({
                'n': 20,
                'h': [80, 10, 100, 5, 120, 5],
              })!
            else
              'all_all': LiftDistribution.fromMap({'n': 3})!,
          }),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('lepší než 62 %'), findsOneWidget);
    // „Můj věk a pohlaví“ bez profilu nejde, ukáže se nápověda.
    expect(find.textContaining('rok narození'), findsOneWidget);
  });

  testWidgets('bez výkonů prázdná zpráva', (tester) async {
    await tester.pumpWidget(app([
      ...base,
      myLiftBestsProvider.overrideWith((ref) async => const []),
    ]));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zatím nemáš výkon'), findsOneWidget);
  });
}
