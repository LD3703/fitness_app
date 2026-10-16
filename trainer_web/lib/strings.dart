// Texty webu pro trenéry (čeština a angličtina).
//
//  s('klic')                      → text
//  s('klic', {'n': 3})            → {n} se nahradí hodnotou
//  „{n:cvik|cviky|cviků}“         → množné číslo (cs: 1 | 2–4 | 5+,
//                                    en: „{n:exercise|exercises}“)
// Test test/strings_test.dart hlídá, že obě mapy mají stejné klíče.
import 'package:flutter/widgets.dart';

class S {
  const S._(this.lang);

  /// „cs“ nebo „en“.
  final String lang;

  /// Pro intl (DateFormat, NumberFormat).
  String get locale => lang;

  static S of(BuildContext context) =>
      S._(Localizations.localeOf(context).languageCode == 'cs' ? 'cs' : 'en');

  static S forLang(String lang) => S._(lang == 'cs' ? 'cs' : 'en');

  static final _pluralStart = RegExp(r'\{(\w+):');

  String call(String key, [Map<String, Object> args = const {}]) {
    var text = (lang == 'cs' ? csStrings : enStrings)[key] ?? enStrings[key] ?? key;
    text = _plurals(text, args);
    args.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
    return text;
  }

  /// „{n:a|b|c}“ → tvar podle čísla (uvnitř smí být „{n}“).
  String _plurals(String text, Map<String, Object> args) {
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final m = _pluralStart.matchAsPrefix(text, i);
      if (m == null) {
        out.write(text[i]);
        i++;
        continue;
      }
      var depth = 1;
      var j = m.end;
      while (j < text.length && depth > 0) {
        if (text[j] == '{') depth++;
        if (text[j] == '}') depth--;
        j++;
      }
      if (depth != 0) {
        out.write(text.substring(i));
        break;
      }
      final forms = text.substring(m.end, j - 1).split('|');
      final v = args[m[1]!];
      final n = v is num ? v.abs() : 0;
      final index = lang == 'cs'
          ? (n == 1 ? 0 : (n >= 2 && n <= 4 && n % 1 == 0 ? 1 : 2))
          : (n == 1 ? 0 : 1);
      out.write(forms[index.clamp(0, forms.length - 1)]);
      i = j;
    }
    return out.toString();
  }
}

const csStrings = <String, String>{
  'appTitle': 'GymBar pro trenéry',
  'notConfigured':
      'Web ještě není nastavený (chybí firebase_options.dart – viz docs/coach.md).',

  // Přihlášení
  'signInIntro':
      'Tréninky a grafy tvých klientů, komentáře a plány, které se jim samy objeví v aplikaci GymBar.',
  'signInGoogle': 'Přihlásit se přes Google',
  'signInApple': 'Přihlásit se přes Apple',
  'signInSameAccount': 'Použij stejný účet jako v aplikaci GymBar.',
  'signInPopupBlocked': 'Prohlížeč zablokoval okno s přihlášením. Povol vyskakovací okna pro gymbar.app.',
  'signInDomain': 'Přihlášení z této adresy není povolené (Firebase → Authentication → Authorized domains).',
  'signInFailed': 'Přihlášení se nepovedlo.',
  'signOut': 'Odhlásit se',
  'signedInAs': 'Přihlášen(a) jako {email}',

  // Stát se trenérem
  'becomeTitle': 'Staň se trenérem',
  'becomeIntro':
      'Dostaneš kód a odkaz pro klienty. Klient se v aplikaci připojí sám a souhlasí se sdílením tréninků – pak tu uvidíš jeho tréninky a grafy a můžeš mu posílat plány.',
  'becomeRules':
      'Pro trenéry je GymBar zdarma. Když {days} dní nemáš žádného klienta, status trenéra zanikne (můžeš se stát trenérem znovu).',
  'becomeButton': 'Stát se trenérem',
  'trainerName': 'Jméno',
  'trainerNameHint': 'Uvidí ho klienti.',
  'trainerBio': 'O mně (nepovinné)',
  'trainerBioHint': 'Např. zaměření, posilovna, kontakt.',
  'nameRequired': 'Vyplň jméno.',
  'profanity': 'Text obsahuje nevhodná slova.',

  // Navigace
  'navClients': 'Klienti',
  'navPlans': 'Plány',
  'navProfile': 'Profil',

  // Klienti
  'expiryWarning':
      'Nemáš žádného klienta – status trenéra zanikne {date}. Pozvi klienty kódem nebo odkazem.',
  'noClientsTitle': 'Zatím nemáš žádné klienty',
  'inviteMore': 'Pozvat další klienty',
  'inviteHow':
      'Klient si nainstaluje GymBar a v Profilu → Trenér zadá tvůj kód, nebo otevře odkaz z pozvánky.',
  'copyCode': 'Kopírovat kód',
  'copyInvite': 'Kopírovat pozvánku',
  'inviteText':
      'Trénuj se mnou v aplikaci GymBar – uvidím tvoje tréninky a pošlu ti plán. Připoj se: {link} ({name})',
  'copied': 'Zkopírováno.',
  'noWorkoutsYet': 'zatím bez tréninku',
  'lastWorkoutDays':
      '{days:poslední trénink před {days} dnem|poslední trénink před {days} dny|poslední trénink před {days} dny}',
  'thisWeekCount': '{n:tento týden {n} trénink|tento týden {n} tréninky|tento týden {n} tréninků}',
  'inactiveTooltip': 'Netrénuje 10 a více dní',

  // Detail klienta
  'removeClient': 'Odebrat klienta',
  'removeClientTitle': 'Odebrat klienta {name}?',
  'removeClientMessage':
      'Propojení se zruší a jeho tréninky, plány a komentáře tady zmizí. Klientovi zůstane vše v aplikaci.',
  'statLast': 'Poslední trénink',
  'today': 'dnes',
  'daysAgo': '{days:před {days} dnem|před {days} dny|před {days} dny}',
  'statThisWeek': 'Tento týden',
  'statAvg': 'Průměr za týden',
  'statTotal': 'Tréninků celkem',
  'statSince': 'Klient od',
  'clientNoWorkouts': 'Klient zatím nemá žádný trénink.',
  'chartWorkouts': 'Tréninky po týdnech',
  'chartVolume': 'Objem po týdnech (tuny)',
  'chartExercise': 'Nejtěžší série',
  'chartBodyWeight': 'Tělesná váha',
  'weekOf': 'Týden od {date}',
  'noWeightedExercises': 'Zatím žádný cvik s váhou.',
  'weightNotShared': 'Klient tělesnou váhu nesdílí.',
  'weightEmpty': 'Zatím žádné vážení.',
  'records': 'Osobní rekordy',
  'history': 'Historie tréninků',
  'showMore': 'Zobrazit další',
  'minutes': '{n} min',
  'commentsCount': '{n:{n} komentář|{n} komentáře|{n} komentářů}',
  'addComment': 'Přidat komentář',
  'warmupTag': 'rozcvička',
  'dropTag': 'drop',

  // Plány klienta
  'clientPlans': 'Plány klienta',
  'clientPlansEmpty':
      'Klient od tebe zatím nemá žádný plán. Vytvoř nový, nebo vyber z knihovny – v aplikaci se mu objeví sám.',
  'fromLibrary': 'Z knihovny',
  'newPlan': 'Nový plán',
  'planSent': 'Plán odeslán – {name} ho uvidí v aplikaci.',
  'planSentMany': '{n:Plán odeslán {n} klientovi.|Plán odeslán {n} klientům.|Plán odeslán {n} klientům.}',
  'versionN': 'verze {n}',
  'deletePlanTitle': 'Smazat plán „{name}“?',
  'deleteClientPlanMessage':
      'Plán zmizí z tvého přehledu a další změny se klientovi už nepošlou. Kopie, kterou má klient v telefonu, mu zůstane.',

  // Knihovna
  'libraryIntro':
      'Knihovna plánů je jen tvoje. Plán odtud pošleš klientům (menu ⋮ nebo v detailu klienta). Po úpravě ho pošli znovu – klient dostane novou verzi.',
  'libraryEmpty': 'Knihovna je zatím prázdná.',
  'exercisesCount': '{n:{n} cvik|{n} cviky|{n} cviků}',
  'setsCount': '{n:{n} série|{n} série|{n} sérií}',
  'sendToClients': 'Poslat klientům',
  'send': 'Poslat',
  'shareLink': 'Sdílet odkazem',
  'shareLinkCopied': 'Odkaz na plán je zkopírovaný – kdokoli s ním si plán přidá do aplikace.',
  'duplicate': 'Duplikovat',
  'copySuffix': 'kopie',
  'deleteLibraryPlanMessage': 'Plán se smaže z knihovny. Klientům, kteří ho už mají, zůstane.',
  'savedResendHint': 'Uloženo. Klientům, kteří plán mají, ho pošli znovu (⋮ → Poslat klientům).',

  // Editor
  'editPlan': 'Upravit plán',
  'planName': 'Název plánu',
  'planDescription': 'Popis (nepovinné)',
  'planDescriptionHint': 'Klient ho uvidí u plánu.',
  'planDays': 'Dny v týdnu',
  'exercises': 'Cviky',
  'addExercise': 'Přidat cvik',
  'addSet': 'Přidat sérii',
  'supersetWithPrev': 'Supersérie s předchozím cvikem',
  'rest': 'Pauza',
  'restAuto': 'automaticky',
  'repRange': 'Rozsah opakování',
  'exerciseNote': 'Poznámka pro klienta',
  'exerciseNoteHint': 'Technika, tempo, úchop… Klient ji uvidí v plánu i při tréninku.',
  'min': 'od',
  'max': 'do',
  'reps': 'opak.',
  'seconds': 's',
  'kgOptional': 'nepovinné',
  'moveUp': 'Posunout nahoru',
  'moveDown': 'Posunout dolů',
  'planNameRequired': 'Vyplň název plánu.',
  'planNeedsExercise': 'Přidej aspoň jeden cvik.',
  'planNeedsSets': 'Každý cvik potřebuje aspoň jednu sérii.',
  'discardTitle': 'Zahodit změny?',
  'discardMessage': 'Plán není uložený.',
  'discard': 'Zahodit',
  'searchExercise': 'Hledat cvik',
  'allMuscles': 'Vše',
  'noResults': 'Nic nenalezeno.',
  'customExercise': 'Vlastní cvik',
  'exerciseName': 'Název cviku',
  'muscle': 'Partie',
  'equipment': 'Vybavení',
  'exerciseType': 'Typ',
  'add': 'Přidat',

  // Profil
  'edit': 'Upravit',
  'editProfile': 'Upravit profil',
  'clientCount': '{n:{n} klient|{n} klienti|{n} klientů}',
  'yourCode': 'Tvůj kód: {code}',
  'account': 'Účet',
  'stopButton': 'Přestat být trenérem',
  'stopHint': 'Zruší propojení se všemi klienty.',
  'stopTitle': 'Přestat být trenérem?',
  'stopMessage':
      'Propojení se všemi klienty se zruší a smaže se tvoje knihovna plánů i komentáře. Klientům zůstanou tréninky i plány v aplikaci.',

  // Obecné
  'cancel': 'Zrušit',
  'save': 'Uložit',
  'saved': 'Uloženo.',
  'delete': 'Smazat',
  'errorPermission': 'Na tohle nemáš oprávnění (nejsi už trenérem tohoto klienta?).',
  'errorOffline': 'Nepodařilo se spojit se serverem. Zkus to znovu.',
  'errorGeneric': 'Něco se pokazilo. Zkus to znovu.',

  // Dny (bit 0 = pondělí)
  'day0': 'Po', 'day1': 'Út', 'day2': 'St', 'day3': 'Čt', 'day4': 'Pá',
  'day5': 'So', 'day6': 'Ne',

  // Partie, vybavení, typy (názvy enumů z aplikace)
  'muscle_chest': 'Hrudník',
  'muscle_back': 'Záda',
  'muscle_traps': 'Trapézy',
  'muscle_lowerBack': 'Spodní záda',
  'muscle_shoulders': 'Ramena',
  'muscle_biceps': 'Biceps',
  'muscle_triceps': 'Triceps',
  'muscle_forearms': 'Předloktí',
  'muscle_core': 'Střed těla',
  'muscle_quads': 'Přední stehna',
  'muscle_hamstrings': 'Zadní stehna',
  'muscle_glutes': 'Hýždě',
  'muscle_calves': 'Lýtka',
  'muscle_legs': 'Nohy',
  'muscle_fullBody': 'Celé tělo',
  'equipment_barbell': 'Velká činka',
  'equipment_dumbbell': 'Jednoručky',
  'equipment_machine': 'Stroj',
  'equipment_cable': 'Kladka',
  'equipment_bodyweight': 'Vlastní váha',
  'equipment_kettlebell': 'Kettlebell',
  'equipment_band': 'Odporová guma',
  'type_weightReps': 'Váha × opakování',
  'type_bodyweightReps': 'Jen opakování',
  'type_duration': 'Na čas',
  // Pozvánky na trénink
  'sessions': 'Tréninky s klientem',
  'sessionsEmpty': 'Zatím žádný domluvený trénink. Pozvi klienta – po potvrzení se mu termín zapíše do kalendáře.',
  'sessionInvite': 'Pozvat na trénink',
  'sessionEdit': 'Upravit termín',
  'sessionEditHint': 'Klient změněný termín potvrdí znovu.',
  'sessionDuration': 'Délka',
  'sessionRepeat': 'Opakování',
  'sessionOnce': 'Jednorázově',
  'sessionWeeks': 'Každý týden, {n:{n} týden|{n} týdny|{n} týdnů}',
  'sessionWeeklyUntil': 'každý týden do {date}',
  'sessionPlan': 'Plán',
  'sessionNoPlan': 'Bez plánu',
  'sessionTitle': 'Název',
  'sessionTitleHint': 'Např. Nohy (jinak název plánu)',
  'sessionTitleDefault': 'Trénink',
  'sessionNote': 'Poznámka pro klienta',
  'sessionSend': 'Odeslat pozvánku',
  'sessionSent': 'Pozvánka odeslána – {name} ji potvrdí v aplikaci.',
  'sessionInPast': 'Termín je v minulosti.',
  'sessionPending': 'Čeká na potvrzení',
  'sessionAccepted': 'Potvrzeno',
  'sessionDeclined': 'Odmítnuto',
  'sessionCancelled': 'Zrušeno',
  'sessionPast': 'Proběhlo',
  'sessionCancel': 'Zrušit trénink',
  'sessionCancelTitle': 'Zrušit trénink?',
  'sessionCancelMessage': '{name} dostane upozornění a termín zmizí z jeho kalendáře.',
  'sessionIcs': 'Do mého kalendáře (.ics)',
  'sessionIcsTitle': '{title} – {name}',
};

const enStrings = <String, String>{
  'appTitle': 'GymBar for coaches',
  'notConfigured':
      'The site is not set up yet (firebase_options.dart is missing – see docs/coach.md).',

  'signInIntro':
      'Your clients\' workouts and charts, comments, and plans that show up in their GymBar app automatically.',
  'signInGoogle': 'Sign in with Google',
  'signInApple': 'Sign in with Apple',
  'signInSameAccount': 'Use the same account as in the GymBar app.',
  'signInPopupBlocked': 'Your browser blocked the sign-in window. Allow pop-ups for gymbar.app.',
  'signInDomain': 'Sign-in is not allowed from this address (Firebase → Authentication → Authorized domains).',
  'signInFailed': 'Sign-in failed.',
  'signOut': 'Sign out',
  'signedInAs': 'Signed in as {email}',

  'becomeTitle': 'Become a coach',
  'becomeIntro':
      'You get a code and a link for your clients. A client connects in the app and agrees to share their workouts – then you see their workouts and charts here and can send them plans.',
  'becomeRules':
      'GymBar is free for coaches. If you have no clients for {days} days, your coach status ends (you can become a coach again).',
  'becomeButton': 'Become a coach',
  'trainerName': 'Name',
  'trainerNameHint': 'Your clients will see it.',
  'trainerBio': 'About me (optional)',
  'trainerBioHint': 'E.g. focus, gym, contact.',
  'nameRequired': 'Enter your name.',
  'profanity': 'The text contains inappropriate words.',

  'navClients': 'Clients',
  'navPlans': 'Plans',
  'navProfile': 'Profile',

  'expiryWarning':
      'You have no clients – your coach status ends on {date}. Invite clients with your code or link.',
  'noClientsTitle': 'No clients yet',
  'inviteMore': 'Invite more clients',
  'inviteHow':
      'The client installs GymBar and enters your code in Profile → Coach, or opens the invite link.',
  'copyCode': 'Copy code',
  'copyInvite': 'Copy invite',
  'inviteText':
      'Train with me in the GymBar app – I\'ll see your workouts and send you a plan. Join here: {link} ({name})',
  'copied': 'Copied.',
  'noWorkoutsYet': 'no workouts yet',
  'lastWorkoutDays': '{days:last workout {days} day ago|last workout {days} days ago}',
  'thisWeekCount': '{n:{n} workout this week|{n} workouts this week}',
  'inactiveTooltip': 'No workout for 10 days or more',

  'removeClient': 'Remove client',
  'removeClientTitle': 'Remove {name}?',
  'removeClientMessage':
      'The connection ends and their workouts, plans and comments disappear here. The client keeps everything in the app.',
  'statLast': 'Last workout',
  'today': 'today',
  'daysAgo': '{days:{days} day ago|{days} days ago}',
  'statThisWeek': 'This week',
  'statAvg': 'Weekly average',
  'statTotal': 'Total workouts',
  'statSince': 'Client since',
  'clientNoWorkouts': 'The client has no workouts yet.',
  'chartWorkouts': 'Workouts per week',
  'chartVolume': 'Volume per week (tonnes)',
  'chartExercise': 'Heaviest set',
  'chartBodyWeight': 'Body weight',
  'weekOf': 'Week of {date}',
  'noWeightedExercises': 'No weighted exercise yet.',
  'weightNotShared': 'The client does not share body weight.',
  'weightEmpty': 'No weigh-ins yet.',
  'records': 'Personal records',
  'history': 'Workout history',
  'showMore': 'Show more',
  'minutes': '{n} min',
  'commentsCount': '{n:{n} comment|{n} comments}',
  'addComment': 'Add comment',
  'warmupTag': 'warm-up',
  'dropTag': 'drop',

  'clientPlans': 'Client\'s plans',
  'clientPlansEmpty':
      'The client has no plan from you yet. Create a new one or pick one from your library – it shows up in their app automatically.',
  'fromLibrary': 'From library',
  'newPlan': 'New plan',
  'planSent': 'Plan sent – {name} will see it in the app.',
  'planSentMany': '{n:Plan sent to {n} client.|Plan sent to {n} clients.}',
  'versionN': 'version {n}',
  'deletePlanTitle': 'Delete plan "{name}"?',
  'deleteClientPlanMessage':
      'The plan disappears from your overview and further changes won\'t reach the client. The copy on the client\'s phone stays.',

  'libraryIntro':
      'Your plan library is private. Send plans to clients from here (⋮ menu) or from a client\'s page. After editing a plan, send it again – the client gets the new version.',
  'libraryEmpty': 'Your library is empty.',
  'exercisesCount': '{n:{n} exercise|{n} exercises}',
  'setsCount': '{n:{n} set|{n} sets}',
  'sendToClients': 'Send to clients',
  'send': 'Send',
  'shareLink': 'Share link',
  'shareLinkCopied': 'Plan link copied – anyone with it can add the plan to their app.',
  'duplicate': 'Duplicate',
  'copySuffix': 'copy',
  'deleteLibraryPlanMessage': 'The plan is deleted from your library. Clients who already have it keep it.',
  'savedResendHint': 'Saved. Send it again to clients who have it (⋮ → Send to clients).',

  'editPlan': 'Edit plan',
  'planName': 'Plan name',
  'planDescription': 'Description (optional)',
  'planDescriptionHint': 'The client sees it with the plan.',
  'planDays': 'Days of the week',
  'exercises': 'Exercises',
  'addExercise': 'Add exercise',
  'addSet': 'Add set',
  'supersetWithPrev': 'Superset with previous exercise',
  'rest': 'Rest',
  'restAuto': 'automatic',
  'repRange': 'Rep range',
  'exerciseNote': 'Note for the client',
  'exerciseNoteHint': 'Technique, tempo, grip… The client sees it in the plan and during the workout.',
  'min': 'min',
  'max': 'max',
  'reps': 'reps',
  'seconds': 's',
  'kgOptional': 'optional',
  'moveUp': 'Move up',
  'moveDown': 'Move down',
  'planNameRequired': 'Enter a plan name.',
  'planNeedsExercise': 'Add at least one exercise.',
  'planNeedsSets': 'Each exercise needs at least one set.',
  'discardTitle': 'Discard changes?',
  'discardMessage': 'The plan is not saved.',
  'discard': 'Discard',
  'searchExercise': 'Search exercises',
  'allMuscles': 'All',
  'noResults': 'Nothing found.',
  'customExercise': 'Custom exercise',
  'exerciseName': 'Exercise name',
  'muscle': 'Muscle',
  'equipment': 'Equipment',
  'exerciseType': 'Type',
  'add': 'Add',

  'edit': 'Edit',
  'editProfile': 'Edit profile',
  'clientCount': '{n:{n} client|{n} clients}',
  'yourCode': 'Your code: {code}',
  'account': 'Account',
  'stopButton': 'Stop being a coach',
  'stopHint': 'Disconnects all your clients.',
  'stopTitle': 'Stop being a coach?',
  'stopMessage':
      'All client connections end and your plan library and comments are deleted. Clients keep their workouts and plans in the app.',

  'cancel': 'Cancel',
  'save': 'Save',
  'saved': 'Saved.',
  'delete': 'Delete',
  'errorPermission': 'You don\'t have permission for this (are you still this client\'s coach?).',
  'errorOffline': 'Could not reach the server. Try again.',
  'errorGeneric': 'Something went wrong. Try again.',

  'day0': 'Mon', 'day1': 'Tue', 'day2': 'Wed', 'day3': 'Thu', 'day4': 'Fri',
  'day5': 'Sat', 'day6': 'Sun',

  'muscle_chest': 'Chest',
  'muscle_back': 'Back',
  'muscle_traps': 'Traps',
  'muscle_lowerBack': 'Lower back',
  'muscle_shoulders': 'Shoulders',
  'muscle_biceps': 'Biceps',
  'muscle_triceps': 'Triceps',
  'muscle_forearms': 'Forearms',
  'muscle_core': 'Core',
  'muscle_quads': 'Quads',
  'muscle_hamstrings': 'Hamstrings',
  'muscle_glutes': 'Glutes',
  'muscle_calves': 'Calves',
  'muscle_legs': 'Legs',
  'muscle_fullBody': 'Full body',
  'equipment_barbell': 'Barbell',
  'equipment_dumbbell': 'Dumbbells',
  'equipment_machine': 'Machine',
  'equipment_cable': 'Cable',
  'equipment_bodyweight': 'Bodyweight',
  'equipment_kettlebell': 'Kettlebell',
  'equipment_band': 'Resistance band',
  'type_weightReps': 'Weight × reps',
  'type_bodyweightReps': 'Reps only',
  'type_duration': 'Timed',
  // Workout invitations
  'sessions': 'Workouts with the client',
  'sessionsEmpty': 'No workouts scheduled yet. Invite your client – once they confirm, it goes into their calendar.',
  'sessionInvite': 'Invite to a workout',
  'sessionEdit': 'Change the time',
  'sessionEditHint': 'The client will confirm the changed time again.',
  'sessionDuration': 'Duration',
  'sessionRepeat': 'Repeat',
  'sessionOnce': 'Once',
  'sessionWeeks': 'Every week, {n:{n} week|{n} weeks}',
  'sessionWeeklyUntil': 'every week until {date}',
  'sessionPlan': 'Plan',
  'sessionNoPlan': 'No plan',
  'sessionTitle': 'Title',
  'sessionTitleHint': 'E.g. Legs (otherwise the plan name)',
  'sessionTitleDefault': 'Workout',
  'sessionNote': 'Note for the client',
  'sessionSend': 'Send invitation',
  'sessionSent': 'Invitation sent – {name} confirms it in the app.',
  'sessionInPast': 'This time is in the past.',
  'sessionPending': 'Waiting for confirmation',
  'sessionAccepted': 'Confirmed',
  'sessionDeclined': 'Declined',
  'sessionCancelled': 'Cancelled',
  'sessionPast': 'Done',
  'sessionCancel': 'Cancel workout',
  'sessionCancelTitle': 'Cancel the workout?',
  'sessionCancelMessage': '{name} will be notified and the workout disappears from their calendar.',
  'sessionIcs': 'Add to my calendar (.ics)',
  'sessionIcsTitle': '{title} – {name}',
};
