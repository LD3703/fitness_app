import 'dart:ui' show PlatformDispatcher;

/// Texty aplikace v hodinkách – čeština a angličtina (podle jazyka hodinek,
/// ostatní jazyky anglicky). Plná lokalizace přes ARB tu záměrně není:
/// textů je pár desítek a názvy cviků posílá telefon už přeložené.
class WearStrings {
  const WearStrings._(this.cs);

  /// Texty podle jazyka hodinek.
  factory WearStrings.device() =>
      WearStrings._(PlatformDispatcher.instance.locale.languageCode == 'cs');

  final bool cs;

  String get appTitle => cs ? 'Trénink' : 'Workout';
  String get connecting => cs ? 'Připojuji se k telefonu…' : 'Connecting to your phone…';
  String get unreachable => cs
      ? 'Telefon neodpovídá. Otevři aplikaci v telefonu.'
      : 'Your phone isn’t responding. Open the app on your phone.';
  String get retry => cs ? 'Zkusit znovu' : 'Try again';
  String get idle => cs
      ? 'Neběží žádný trénink. Spusť ho v telefonu.'
      : 'No workout running. Start one on your phone.';
  String get openOnPhone => cs
      ? 'Trénink běží, ale v telefonu není otevřený.'
      : 'Your workout is running but isn’t open on your phone.';
  String get open => cs ? 'Otevřít v telefonu' : 'Open on phone';
  String get premiumRequired => cs
      ? 'Aplikace pro hodinky je součástí Premium. Odemkni ji v telefonu.'
      : 'The watch app is part of Premium. Unlock it on your phone.';

  String setOf(int number, int count) =>
      cs ? 'Série $number z $count' : 'Set $number of $count';
  String get warmup => cs ? 'Rozcvička' : 'Warm-up';
  String get drop => cs ? 'Drop série' : 'Drop set';
  String get reps => cs ? 'opakování' : 'reps';
  String get seconds => 's';
  String get done => cs ? 'Hotovo' : 'Done';
  String get rest => cs ? 'Pauza' : 'Rest';
  String get skip => cs ? 'Přeskočit' : 'Skip';
  String next(String what) => cs ? 'Další: $what' : 'Next: $what';
  String lastTime(String what) => cs ? 'Minule: $what' : 'Last time: $what';
  String get exercises => cs ? 'Cviky' : 'Exercises';
  String get nextExercise => cs ? 'Další cvik' : 'Next exercise';
  String get finish => cs ? 'Ukončit trénink' : 'Finish workout';
  String get back => cs ? 'Zpět' : 'Back';
  String get allDone => cs ? 'Všechny série jsou hotové!' : 'All sets done!';
  String get weightLabel => cs ? 'Váha' : 'Weight';
  String get bodyweight => cs ? 'Vlastní váha' : 'Bodyweight';
  String get increase => cs ? 'Přidat' : 'Increase';
  String get decrease => cs ? 'Ubrat' : 'Decrease';

  // Krátká hlášení (potvrzení z telefonu).
  String get confirmOnPhone => cs ? 'Potvrď v telefonu' : 'Confirm on your phone';
  String get notResponding => cs ? 'Telefon neodpovídá' : 'Phone isn’t responding';
  String get checkOnPhone =>
      cs ? 'Zkontroluj hodnoty v telefonu' : 'Check the values on your phone';
  String get weightMissing => cs ? 'Nejdřív nastav váhu' : 'Set the weight first';
  String get openWorkoutOnPhone =>
      cs ? 'Otevři trénink v telefonu' : 'Open the workout on your phone';
  String get unlockPhone =>
      cs ? 'Odemkni telefon a otevři aplikaci' : 'Unlock your phone and open the app';
  String get noWorkout => cs ? 'Neběží žádný trénink' : 'No workout running';
  String get notFound =>
      cs ? 'Trénink se v telefonu změnil' : 'The workout changed on your phone';
  String get updateApps => cs
      ? 'Aktualizuj aplikaci v telefonu i hodinkách'
      : 'Update the app on your phone and watch';
  String get somethingWrong => cs ? 'Něco se nepovedlo' : 'Something went wrong';
}
