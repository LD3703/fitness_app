import 'dart:ui' show PlatformDispatcher;

/// Texty aplikace v hodinkách v 10 jazycích jako v telefonu (podle jazyka
/// hodinek, neznámý jazyk anglicky). Plná lokalizace přes ARB tu záměrně
/// není: textů je pár desítek a názvy cviků posílá telefon už přeložené.
/// Každý jazyk je podtřída – chybějící text analyzér nahlásí jako chybu.
abstract class WearStrings {
  const WearStrings();

  /// Texty podle jazyka hodinek.
  factory WearStrings.device() =>
      WearStrings.of(PlatformDispatcher.instance.locale.languageCode);

  /// Texty pro kód jazyka („cs“, „de“…).
  factory WearStrings.of(String languageCode) => switch (languageCode) {
        'cs' => const _Cs(),
        'de' => const _De(),
        'es' => const _Es(),
        'fr' => const _Fr(),
        'it' => const _It(),
        'nl' => const _Nl(),
        'pl' => const _Pl(),
        'pt' => const _Pt(),
        'sk' => const _Sk(),
        _ => const _En(),
      };

  /// Desetinná čárka (82,5) – všude kromě angličtiny.
  bool get decimalComma => true;

  String get appTitle;
  String get connecting;
  String get unreachable;
  String get retry;
  String get idle;
  String get openOnPhone;
  String get open;
  String get premiumRequired;

  String setOf(int number, int count);
  String get warmup;
  String get drop;
  String get reps;
  String get seconds => 's';
  String get done;
  String get rest;
  String get skip;
  String next(String what);
  String lastTime(String what);
  String get exercises;
  String get nextExercise;
  String get finish;
  String get back;
  String get allDone;
  String get weightLabel;
  String get bodyweight;
  String get note;
  String get myNote;
  String noteFromTrainer(String name);
  String get increase;
  String get decrease;

  // Krátká hlášení (potvrzení z telefonu).
  String get confirmOnPhone;
  String get notResponding;
  String get checkOnPhone;
  String get weightMissing;
  String get openWorkoutOnPhone;
  String get unlockPhone;
  String get noWorkout;
  String get notFound;
  String get updateApps;
  String get somethingWrong;
}

class _Cs extends WearStrings {
  const _Cs();

  @override
  String get appTitle => 'Trénink';
  @override
  String get connecting => 'Připojuji se k telefonu…';
  @override
  String get unreachable => 'Telefon neodpovídá. Otevři aplikaci v telefonu.';
  @override
  String get retry => 'Zkusit znovu';
  @override
  String get idle => 'Neběží žádný trénink. Spusť ho v telefonu.';
  @override
  String get openOnPhone => 'Trénink běží, ale v telefonu není otevřený.';
  @override
  String get open => 'Otevřít v telefonu';
  @override
  String get premiumRequired =>
      'Aplikace pro hodinky je součástí Premium. Odemkni ji v telefonu.';
  @override
  String setOf(int number, int count) => 'Série $number z $count';
  @override
  String get warmup => 'Rozcvička';
  @override
  String get drop => 'Drop série';
  @override
  String get reps => 'opakování';
  @override
  String get done => 'Hotovo';
  @override
  String get rest => 'Pauza';
  @override
  String get skip => 'Přeskočit';
  @override
  String next(String what) => 'Další: $what';
  @override
  String lastTime(String what) => 'Minule: $what';
  @override
  String get exercises => 'Cviky';
  @override
  String get nextExercise => 'Další cvik';
  @override
  String get finish => 'Ukončit trénink';
  @override
  String get back => 'Zpět';
  @override
  String get allDone => 'Všechny série jsou hotové!';
  @override
  String get weightLabel => 'Váha';
  @override
  String get bodyweight => 'Vlastní váha';
  @override
  String get note => 'Poznámka';
  @override
  String get myNote => 'Moje poznámka';
  @override
  String noteFromTrainer(String name) => 'Trenér $name';
  @override
  String get increase => 'Přidat';
  @override
  String get decrease => 'Ubrat';
  @override
  String get confirmOnPhone => 'Potvrď v telefonu';
  @override
  String get notResponding => 'Telefon neodpovídá';
  @override
  String get checkOnPhone => 'Zkontroluj hodnoty v telefonu';
  @override
  String get weightMissing => 'Nejdřív nastav váhu';
  @override
  String get openWorkoutOnPhone => 'Otevři trénink v telefonu';
  @override
  String get unlockPhone => 'Odemkni telefon a otevři aplikaci';
  @override
  String get noWorkout => 'Neběží žádný trénink';
  @override
  String get notFound => 'Trénink se v telefonu změnil';
  @override
  String get updateApps => 'Aktualizuj aplikaci v telefonu i hodinkách';
  @override
  String get somethingWrong => 'Něco se nepovedlo';
}

class _En extends WearStrings {
  const _En();

  @override
  bool get decimalComma => false;

  @override
  String get appTitle => 'Workout';
  @override
  String get connecting => 'Connecting to your phone…';
  @override
  String get unreachable =>
      'Your phone isn’t responding. Open the app on your phone.';
  @override
  String get retry => 'Try again';
  @override
  String get idle => 'No workout running. Start one on your phone.';
  @override
  String get openOnPhone =>
      'Your workout is running but isn’t open on your phone.';
  @override
  String get open => 'Open on phone';
  @override
  String get premiumRequired =>
      'The watch app is part of Premium. Unlock it on your phone.';
  @override
  String setOf(int number, int count) => 'Set $number of $count';
  @override
  String get warmup => 'Warm-up';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'reps';
  @override
  String get done => 'Done';
  @override
  String get rest => 'Rest';
  @override
  String get skip => 'Skip';
  @override
  String next(String what) => 'Next: $what';
  @override
  String lastTime(String what) => 'Last time: $what';
  @override
  String get exercises => 'Exercises';
  @override
  String get nextExercise => 'Next exercise';
  @override
  String get finish => 'Finish workout';
  @override
  String get back => 'Back';
  @override
  String get allDone => 'All sets done!';
  @override
  String get weightLabel => 'Weight';
  @override
  String get bodyweight => 'Bodyweight';
  @override
  String get note => 'Note';
  @override
  String get myNote => 'My note';
  @override
  String noteFromTrainer(String name) => 'Coach $name';
  @override
  String get increase => 'Increase';
  @override
  String get decrease => 'Decrease';
  @override
  String get confirmOnPhone => 'Confirm on your phone';
  @override
  String get notResponding => 'Phone isn’t responding';
  @override
  String get checkOnPhone => 'Check the values on your phone';
  @override
  String get weightMissing => 'Set the weight first';
  @override
  String get openWorkoutOnPhone => 'Open the workout on your phone';
  @override
  String get unlockPhone => 'Unlock your phone and open the app';
  @override
  String get noWorkout => 'No workout running';
  @override
  String get notFound => 'The workout changed on your phone';
  @override
  String get updateApps => 'Update the app on your phone and watch';
  @override
  String get somethingWrong => 'Something went wrong';
}

class _De extends WearStrings {
  const _De();

  @override
  String get appTitle => 'Training';
  @override
  String get connecting => 'Verbinde mit dem Handy…';
  @override
  String get unreachable =>
      'Dein Handy antwortet nicht. Öffne die App auf dem Handy.';
  @override
  String get retry => 'Erneut versuchen';
  @override
  String get idle => 'Kein Training aktiv. Starte eins auf dem Handy.';
  @override
  String get openOnPhone =>
      'Dein Training läuft, ist aber auf dem Handy nicht geöffnet.';
  @override
  String get open => 'Auf dem Handy öffnen';
  @override
  String get premiumRequired =>
      'Die Uhr-App gehört zu Premium. Schalte sie auf dem Handy frei.';
  @override
  String setOf(int number, int count) => 'Satz $number von $count';
  @override
  String get warmup => 'Aufwärmen';
  @override
  String get drop => 'Drop-Satz';
  @override
  String get reps => 'Wdh.';
  @override
  String get done => 'Fertig';
  @override
  String get rest => 'Pause';
  @override
  String get skip => 'Überspringen';
  @override
  String next(String what) => 'Als Nächstes: $what';
  @override
  String lastTime(String what) => 'Letztes Mal: $what';
  @override
  String get exercises => 'Übungen';
  @override
  String get nextExercise => 'Nächste Übung';
  @override
  String get finish => 'Training beenden';
  @override
  String get back => 'Zurück';
  @override
  String get allDone => 'Alle Sätze erledigt!';
  @override
  String get weightLabel => 'Gewicht';
  @override
  String get bodyweight => 'Körpergewicht';
  @override
  String get note => 'Notiz';
  @override
  String get myNote => 'Meine Notiz';
  @override
  String noteFromTrainer(String name) => 'Coach $name';
  @override
  String get increase => 'Mehr';
  @override
  String get decrease => 'Weniger';
  @override
  String get confirmOnPhone => 'Bestätige auf dem Handy';
  @override
  String get notResponding => 'Handy antwortet nicht';
  @override
  String get checkOnPhone => 'Prüf die Werte auf dem Handy';
  @override
  String get weightMissing => 'Stell zuerst das Gewicht ein';
  @override
  String get openWorkoutOnPhone => 'Öffne das Training auf dem Handy';
  @override
  String get unlockPhone => 'Entsperr das Handy und öffne die App';
  @override
  String get noWorkout => 'Kein Training aktiv';
  @override
  String get notFound => 'Das Training wurde auf dem Handy geändert';
  @override
  String get updateApps => 'Aktualisiere die App auf Handy und Uhr';
  @override
  String get somethingWrong => 'Etwas ist schiefgelaufen';
}

class _Es extends WearStrings {
  const _Es();

  @override
  String get appTitle => 'Entrenamiento';
  @override
  String get connecting => 'Conectando con el móvil…';
  @override
  String get unreachable => 'El móvil no responde. Abre la app en el móvil.';
  @override
  String get retry => 'Reintentar';
  @override
  String get idle => 'No hay ningún entrenamiento. Empieza uno en el móvil.';
  @override
  String get openOnPhone =>
      'Tu entrenamiento está en curso, pero no está abierto en el móvil.';
  @override
  String get open => 'Abrir en el móvil';
  @override
  String get premiumRequired =>
      'La app del reloj forma parte de Premium. Desbloquéala en el móvil.';
  @override
  String setOf(int number, int count) => 'Serie $number de $count';
  @override
  String get warmup => 'Calentamiento';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'reps';
  @override
  String get done => 'Hecho';
  @override
  String get rest => 'Descanso';
  @override
  String get skip => 'Saltar';
  @override
  String next(String what) => 'Siguiente: $what';
  @override
  String lastTime(String what) => 'La última vez: $what';
  @override
  String get exercises => 'Ejercicios';
  @override
  String get nextExercise => 'Siguiente ejercicio';
  @override
  String get finish => 'Terminar entrenamiento';
  @override
  String get back => 'Atrás';
  @override
  String get allDone => '¡Todas las series hechas!';
  @override
  String get weightLabel => 'Peso';
  @override
  String get bodyweight => 'Peso corporal';
  @override
  String get note => 'Nota';
  @override
  String get myNote => 'Mi nota';
  @override
  String noteFromTrainer(String name) => 'Entrenador $name';
  @override
  String get increase => 'Más';
  @override
  String get decrease => 'Menos';
  @override
  String get confirmOnPhone => 'Confirma en el móvil';
  @override
  String get notResponding => 'El móvil no responde';
  @override
  String get checkOnPhone => 'Revisa los valores en el móvil';
  @override
  String get weightMissing => 'Primero indica el peso';
  @override
  String get openWorkoutOnPhone => 'Abre el entrenamiento en el móvil';
  @override
  String get unlockPhone => 'Desbloquea el móvil y abre la app';
  @override
  String get noWorkout => 'No hay ningún entrenamiento';
  @override
  String get notFound => 'El entrenamiento cambió en el móvil';
  @override
  String get updateApps => 'Actualiza la app en el móvil y en el reloj';
  @override
  String get somethingWrong => 'Algo salió mal';
}

class _Fr extends WearStrings {
  const _Fr();

  @override
  String get appTitle => 'Séance';
  @override
  String get connecting => 'Connexion au téléphone…';
  @override
  String get unreachable =>
      'Ton téléphone ne répond pas. Ouvre l’app sur ton téléphone.';
  @override
  String get retry => 'Réessayer';
  @override
  String get idle => 'Aucune séance en cours. Lance-la sur ton téléphone.';
  @override
  String get openOnPhone =>
      'Ta séance est en cours, mais elle n’est pas ouverte sur ton téléphone.';
  @override
  String get open => 'Ouvrir sur le téléphone';
  @override
  String get premiumRequired =>
      'L’app pour montre fait partie de Premium. Débloque-la sur ton téléphone.';
  @override
  String setOf(int number, int count) => 'Série $number sur $count';
  @override
  String get warmup => 'Échauffement';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'rép.';
  @override
  String get done => 'Fait';
  @override
  String get rest => 'Repos';
  @override
  String get skip => 'Passer';
  @override
  String next(String what) => 'Ensuite : $what';
  @override
  String lastTime(String what) => 'La dernière fois : $what';
  @override
  String get exercises => 'Exercices';
  @override
  String get nextExercise => 'Exercice suivant';
  @override
  String get finish => 'Terminer la séance';
  @override
  String get back => 'Retour';
  @override
  String get allDone => 'Toutes les séries sont faites !';
  @override
  String get weightLabel => 'Poids';
  @override
  String get bodyweight => 'Poids du corps';
  @override
  String get note => 'Note';
  @override
  String get myNote => 'Ma note';
  @override
  String noteFromTrainer(String name) => 'Coach $name';
  @override
  String get increase => 'Plus';
  @override
  String get decrease => 'Moins';
  @override
  String get confirmOnPhone => 'Confirme sur ton téléphone';
  @override
  String get notResponding => 'Le téléphone ne répond pas';
  @override
  String get checkOnPhone => 'Vérifie les valeurs sur ton téléphone';
  @override
  String get weightMissing => 'Indique d’abord le poids';
  @override
  String get openWorkoutOnPhone => 'Ouvre la séance sur ton téléphone';
  @override
  String get unlockPhone => 'Déverrouille ton téléphone et ouvre l’app';
  @override
  String get noWorkout => 'Aucune séance en cours';
  @override
  String get notFound => 'La séance a changé sur ton téléphone';
  @override
  String get updateApps => 'Mets à jour l’app sur le téléphone et la montre';
  @override
  String get somethingWrong => 'Un problème est survenu';
}

class _It extends WearStrings {
  const _It();

  @override
  String get appTitle => 'Allenamento';
  @override
  String get connecting => 'Connessione al telefono…';
  @override
  String get unreachable =>
      'Il telefono non risponde. Apri l’app sul telefono.';
  @override
  String get retry => 'Riprova';
  @override
  String get idle => 'Nessun allenamento in corso. Avvialo sul telefono.';
  @override
  String get openOnPhone =>
      'L’allenamento è in corso, ma non è aperto sul telefono.';
  @override
  String get open => 'Apri sul telefono';
  @override
  String get premiumRequired =>
      'L’app per lo smartwatch fa parte di Premium. Sbloccala sul telefono.';
  @override
  String setOf(int number, int count) => 'Serie $number di $count';
  @override
  String get warmup => 'Riscaldamento';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'rip.';
  @override
  String get done => 'Fatto';
  @override
  String get rest => 'Recupero';
  @override
  String get skip => 'Salta';
  @override
  String next(String what) => 'Prossimo: $what';
  @override
  String lastTime(String what) => 'L’ultima volta: $what';
  @override
  String get exercises => 'Esercizi';
  @override
  String get nextExercise => 'Esercizio successivo';
  @override
  String get finish => 'Termina allenamento';
  @override
  String get back => 'Indietro';
  @override
  String get allDone => 'Tutte le serie completate!';
  @override
  String get weightLabel => 'Peso';
  @override
  String get bodyweight => 'Corpo libero';
  @override
  String get note => 'Nota';
  @override
  String get myNote => 'La mia nota';
  @override
  String noteFromTrainer(String name) => 'Coach $name';
  @override
  String get increase => 'Aumenta';
  @override
  String get decrease => 'Diminuisci';
  @override
  String get confirmOnPhone => 'Conferma sul telefono';
  @override
  String get notResponding => 'Il telefono non risponde';
  @override
  String get checkOnPhone => 'Controlla i valori sul telefono';
  @override
  String get weightMissing => 'Prima imposta il peso';
  @override
  String get openWorkoutOnPhone => 'Apri l’allenamento sul telefono';
  @override
  String get unlockPhone => 'Sblocca il telefono e apri l’app';
  @override
  String get noWorkout => 'Nessun allenamento in corso';
  @override
  String get notFound => 'L’allenamento è cambiato sul telefono';
  @override
  String get updateApps => 'Aggiorna l’app sul telefono e sullo smartwatch';
  @override
  String get somethingWrong => 'Qualcosa è andato storto';
}

class _Nl extends WearStrings {
  const _Nl();

  @override
  String get appTitle => 'Training';
  @override
  String get connecting => 'Verbinden met je telefoon…';
  @override
  String get unreachable =>
      'Je telefoon reageert niet. Open de app op je telefoon.';
  @override
  String get retry => 'Opnieuw proberen';
  @override
  String get idle => 'Geen training bezig. Start er een op je telefoon.';
  @override
  String get openOnPhone =>
      'Je training loopt, maar is niet geopend op je telefoon.';
  @override
  String get open => 'Openen op telefoon';
  @override
  String get premiumRequired =>
      'De horloge-app hoort bij Premium. Ontgrendel hem op je telefoon.';
  @override
  String setOf(int number, int count) => 'Set $number van $count';
  @override
  String get warmup => 'Warming-up';
  @override
  String get drop => 'Dropset';
  @override
  String get reps => 'herh.';
  @override
  String get done => 'Klaar';
  @override
  String get rest => 'Rust';
  @override
  String get skip => 'Overslaan';
  @override
  String next(String what) => 'Volgende: $what';
  @override
  String lastTime(String what) => 'Vorige keer: $what';
  @override
  String get exercises => 'Oefeningen';
  @override
  String get nextExercise => 'Volgende oefening';
  @override
  String get finish => 'Training afronden';
  @override
  String get back => 'Terug';
  @override
  String get allDone => 'Alle sets klaar!';
  @override
  String get weightLabel => 'Gewicht';
  @override
  String get bodyweight => 'Eigen gewicht';
  @override
  String get note => 'Notitie';
  @override
  String get myNote => 'Mijn notitie';
  @override
  String noteFromTrainer(String name) => 'Coach $name';
  @override
  String get increase => 'Meer';
  @override
  String get decrease => 'Minder';
  @override
  String get confirmOnPhone => 'Bevestig op je telefoon';
  @override
  String get notResponding => 'Telefoon reageert niet';
  @override
  String get checkOnPhone => 'Controleer de waarden op je telefoon';
  @override
  String get weightMissing => 'Stel eerst het gewicht in';
  @override
  String get openWorkoutOnPhone => 'Open de training op je telefoon';
  @override
  String get unlockPhone => 'Ontgrendel je telefoon en open de app';
  @override
  String get noWorkout => 'Geen training bezig';
  @override
  String get notFound => 'De training is gewijzigd op je telefoon';
  @override
  String get updateApps => 'Werk de app bij op je telefoon en horloge';
  @override
  String get somethingWrong => 'Er ging iets mis';
}

class _Pl extends WearStrings {
  const _Pl();

  @override
  String get appTitle => 'Trening';
  @override
  String get connecting => 'Łączenie z telefonem…';
  @override
  String get unreachable =>
      'Telefon nie odpowiada. Otwórz aplikację w telefonie.';
  @override
  String get retry => 'Spróbuj ponownie';
  @override
  String get idle => 'Żaden trening nie trwa. Rozpocznij go w telefonie.';
  @override
  String get openOnPhone => 'Trening trwa, ale nie jest otwarty w telefonie.';
  @override
  String get open => 'Otwórz w telefonie';
  @override
  String get premiumRequired =>
      'Aplikacja na zegarek jest częścią Premium. Odblokuj ją w telefonie.';
  @override
  String setOf(int number, int count) => 'Seria $number z $count';
  @override
  String get warmup => 'Rozgrzewka';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'powt.';
  @override
  String get done => 'Gotowe';
  @override
  String get rest => 'Przerwa';
  @override
  String get skip => 'Pomiń';
  @override
  String next(String what) => 'Dalej: $what';
  @override
  String lastTime(String what) => 'Ostatnio: $what';
  @override
  String get exercises => 'Ćwiczenia';
  @override
  String get nextExercise => 'Następne ćwiczenie';
  @override
  String get finish => 'Zakończ trening';
  @override
  String get back => 'Wstecz';
  @override
  String get allDone => 'Wszystkie serie zrobione!';
  @override
  String get weightLabel => 'Ciężar';
  @override
  String get bodyweight => 'Masa ciała';
  @override
  String get note => 'Notatka';
  @override
  String get myNote => 'Moja notatka';
  @override
  String noteFromTrainer(String name) => 'Trener $name';
  @override
  String get increase => 'Więcej';
  @override
  String get decrease => 'Mniej';
  @override
  String get confirmOnPhone => 'Potwierdź w telefonie';
  @override
  String get notResponding => 'Telefon nie odpowiada';
  @override
  String get checkOnPhone => 'Sprawdź wartości w telefonie';
  @override
  String get weightMissing => 'Najpierw ustaw ciężar';
  @override
  String get openWorkoutOnPhone => 'Otwórz trening w telefonie';
  @override
  String get unlockPhone => 'Odblokuj telefon i otwórz aplikację';
  @override
  String get noWorkout => 'Żaden trening nie trwa';
  @override
  String get notFound => 'Trening zmienił się w telefonie';
  @override
  String get updateApps => 'Zaktualizuj aplikację w telefonie i zegarku';
  @override
  String get somethingWrong => 'Coś poszło nie tak';
}

class _Pt extends WearStrings {
  const _Pt();

  @override
  String get appTitle => 'Treino';
  @override
  String get connecting => 'Conectando ao celular…';
  @override
  String get unreachable =>
      'O celular não está respondendo. Abra o app no celular.';
  @override
  String get retry => 'Tentar de novo';
  @override
  String get idle => 'Nenhum treino em andamento. Comece um no celular.';
  @override
  String get openOnPhone =>
      'Seu treino está em andamento, mas não está aberto no celular.';
  @override
  String get open => 'Abrir no celular';
  @override
  String get premiumRequired =>
      'O app do relógio faz parte do Premium. Desbloqueie no celular.';
  @override
  String setOf(int number, int count) => 'Série $number de $count';
  @override
  String get warmup => 'Aquecimento';
  @override
  String get drop => 'Drop set';
  @override
  String get reps => 'reps';
  @override
  String get done => 'Feito';
  @override
  String get rest => 'Descanso';
  @override
  String get skip => 'Pular';
  @override
  String next(String what) => 'Próximo: $what';
  @override
  String lastTime(String what) => 'Da última vez: $what';
  @override
  String get exercises => 'Exercícios';
  @override
  String get nextExercise => 'Próximo exercício';
  @override
  String get finish => 'Finalizar treino';
  @override
  String get back => 'Voltar';
  @override
  String get allDone => 'Todas as séries feitas!';
  @override
  String get weightLabel => 'Peso';
  @override
  String get bodyweight => 'Peso corporal';
  @override
  String get note => 'Nota';
  @override
  String get myNote => 'Minha nota';
  @override
  String noteFromTrainer(String name) => 'Treinador $name';
  @override
  String get increase => 'Mais';
  @override
  String get decrease => 'Menos';
  @override
  String get confirmOnPhone => 'Confirme no celular';
  @override
  String get notResponding => 'O celular não responde';
  @override
  String get checkOnPhone => 'Confira os valores no celular';
  @override
  String get weightMissing => 'Defina o peso primeiro';
  @override
  String get openWorkoutOnPhone => 'Abra o treino no celular';
  @override
  String get unlockPhone => 'Desbloqueie o celular e abra o app';
  @override
  String get noWorkout => 'Nenhum treino em andamento';
  @override
  String get notFound => 'O treino mudou no celular';
  @override
  String get updateApps => 'Atualize o app no celular e no relógio';
  @override
  String get somethingWrong => 'Algo deu errado';
}

class _Sk extends WearStrings {
  const _Sk();

  @override
  String get appTitle => 'Tréning';
  @override
  String get connecting => 'Pripájam sa k telefónu…';
  @override
  String get unreachable => 'Telefón neodpovedá. Otvor aplikáciu v telefóne.';
  @override
  String get retry => 'Skúsiť znova';
  @override
  String get idle => 'Nebeží žiadny tréning. Spusti ho v telefóne.';
  @override
  String get openOnPhone => 'Tréning beží, ale v telefóne nie je otvorený.';
  @override
  String get open => 'Otvoriť v telefóne';
  @override
  String get premiumRequired =>
      'Aplikácia pre hodinky je súčasťou Premium. Odomkni ju v telefóne.';
  @override
  String setOf(int number, int count) => 'Séria $number z $count';
  @override
  String get warmup => 'Rozcvička';
  @override
  String get drop => 'Drop séria';
  @override
  String get reps => 'opakovaní';
  @override
  String get done => 'Hotovo';
  @override
  String get rest => 'Pauza';
  @override
  String get skip => 'Preskočiť';
  @override
  String next(String what) => 'Ďalej: $what';
  @override
  String lastTime(String what) => 'Minule: $what';
  @override
  String get exercises => 'Cviky';
  @override
  String get nextExercise => 'Ďalší cvik';
  @override
  String get finish => 'Ukončiť tréning';
  @override
  String get back => 'Späť';
  @override
  String get allDone => 'Všetky série sú hotové!';
  @override
  String get weightLabel => 'Váha';
  @override
  String get bodyweight => 'Vlastná váha';
  @override
  String get note => 'Poznámka';
  @override
  String get myNote => 'Moja poznámka';
  @override
  String noteFromTrainer(String name) => 'Tréner $name';
  @override
  String get increase => 'Pridať';
  @override
  String get decrease => 'Ubrať';
  @override
  String get confirmOnPhone => 'Potvrď v telefóne';
  @override
  String get notResponding => 'Telefón neodpovedá';
  @override
  String get checkOnPhone => 'Skontroluj hodnoty v telefóne';
  @override
  String get weightMissing => 'Najprv nastav váhu';
  @override
  String get openWorkoutOnPhone => 'Otvor tréning v telefóne';
  @override
  String get unlockPhone => 'Odomkni telefón a otvor aplikáciu';
  @override
  String get noWorkout => 'Nebeží žiadny tréning';
  @override
  String get notFound => 'Tréning sa v telefóne zmenil';
  @override
  String get updateApps => 'Aktualizuj aplikáciu v telefóne aj hodinkách';
  @override
  String get somethingWrong => 'Niečo sa nepodarilo';
}
