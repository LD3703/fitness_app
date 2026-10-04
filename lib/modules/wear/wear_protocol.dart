// Protokol mezi telefonem a hodinkami s Wear OS (čistý Dart).
//
// TENTO SOUBOR EXISTUJE VE DVOU STEJNÝCH KOPIÍCH:
//   lib/modules/wear/wear_protocol.dart  (aplikace v telefonu)
//   wear/lib/wear_protocol.dart          (aplikace v hodinkách)
// Při změně uprav oba (test/wear_protocol_test.dart hlídá, že jsou shodné)
// a zvyš kWearProtocolVersion, pokud se mění význam polí.
//
// Zprávy jdou přes Wearable Data Layer (balíček watch_connectivity,
// MessageClient). Každá zpráva je mapa s jediným klíčem [kWearMessageKey]
// a hodnotou JSON textu – nezávisí to na tom, jak plugin převádí vnořené
// mapy a seznamy.
//
// Telefon → hodinky:
//   {t: state, boot, seq, sentAtMs, state: WearState}
//   {t: ack, id, ok, reason?}       odpověď na příkaz
//   {t: ping}                       hodinky odpoví „hello“
// Hodinky → telefon:
//   {t: hello}                      telefon pošle aktuální stav
//   {t: cmd, id, cmd: <název>, …}   příkaz (viz [WearCommand])
//
// Váhy jsou vždy v kg. Hodinky zobrazují váhu v jednotkách telefonu:
// zobrazená hodnota = kg / kgPerUnit, krok tlačítek +/- = weightStep
// (v zobrazovaných jednotkách).

import 'dart:convert';

const int kWearProtocolVersion = 1;

/// Jediný klíč mapy posílané přes Data Layer.
const String kWearMessageKey = 'fitnessWear';

/// Typy zpráv (pole `t`).
abstract final class WearMsg {
  static const state = 'state';
  static const ack = 'ack';
  static const ping = 'ping';
  static const hello = 'hello';
  static const command = 'cmd';
}

/// Důvody v potvrzení příkazu (pole `reason`).
abstract final class WearAckReason {
  /// Trénink neběží.
  static const noWorkout = 'noWorkout';

  /// Trénink běží, ale obrazovka tréninku v telefonu není otevřená.
  static const notOpen = 'notOpen';

  /// Telefon je zamčený / aplikace na pozadí – obrazovku nejde otevřít.
  static const phoneLocked = 'phoneLocked';

  /// Série nebo cvik už v tréninku nejsou (změna v telefonu).
  static const notFound = 'notFound';

  /// Neplatné hodnoty série (např. chybí váha).
  static const invalid = 'invalid';

  /// Všechny série jsou hotové.
  static const allDone = 'allDone';

  /// Ukončení tréninku je potřeba potvrdit v telefonu.
  static const confirmOnPhone = 'confirmOnPhone';

  /// Neznámý příkaz (jiná verze aplikace).
  static const unsupported = 'unsupported';

  /// Chyba při zpracování.
  static const error = 'error';

  /// Hodinky jsou funkce Premium a uživatel ji nemá.
  static const premiumRequired = 'premiumRequired';
}

/// Zabalí zprávu pro odeslání.
Map<String, dynamic> wearEnvelope(Map<String, Object?> payload) => {
      kWearMessageKey: jsonEncode({'v': kWearProtocolVersion, ...payload}),
    };

/// Rozbalí přijatou zprávu; null, pokud nepatří této aplikaci.
Map<String, Object?>? openWearEnvelope(Map<String, dynamic> message) {
  final raw = message[kWearMessageKey];
  if (raw is! String) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    return null;
  }
  return null;
}

int? _int(Object? v) => v is num ? v.toInt() : null;
double? _double(Object? v) => v is num ? v.toDouble() : null;
String? _string(Object? v) => v is String ? v : null;
bool _bool(Object? v) => v == true;
Map<String, Object?>? _map(Object? v) =>
    v is Map ? v.map((k, value) => MapEntry('$k', value)) : null;

// ---------------------------------------------------------------------
// Stav (telefon → hodinky)
// ---------------------------------------------------------------------

enum WearPhase {
  /// Žádný rozpracovaný trénink.
  idle,

  /// Trénink běží, ale obrazovka tréninku v telefonu není otevřená.
  openOnPhone,

  /// Obrazovka tréninku je otevřená – hodinky můžou zapisovat série.
  active,

  /// Hodinky jsou funkce Premium a uživatel ji nemá (starší aplikace
  /// v hodinkách neznámou hodnotu přečte jako [idle]).
  premiumRequired,
}

enum WearSetKind { working, warmup, drop }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Série, která je na řadě.
class WearCurrentSet {
  const WearCurrentSet({
    required this.blockIndex,
    required this.exerciseId,
    required this.name,
    required this.isDuration,
    required this.weightRequired,
    required this.setIndex,
    required this.setCount,
    required this.kind,
    this.weightKg,
    this.value,
    this.previousWeightKg,
    this.previousValue,
  });

  /// Pořadí cviku v tréninku (pro jednoznačnost, když je cvik dvakrát).
  final int blockIndex;
  final int exerciseId;

  /// Název cviku v jazyce aplikace v telefonu.
  final String name;

  /// Cvik na čas: [value] jsou sekundy a váha se nezadává.
  final bool isDuration;

  /// Váha je povinná (ne u cviků s vlastní vahou).
  final bool weightRequired;

  /// Index řádku série (od 0, včetně rozcviček a drop sérií).
  final int setIndex;
  final int setCount;
  final WearSetKind kind;
  final double? weightKg;

  /// Opakování (u cviků na čas sekundy).
  final int? value;
  final double? previousWeightKg;
  final int? previousValue;

  Map<String, Object?> toJson() => {
        'b': blockIndex,
        'ex': exerciseId,
        'name': name,
        'dur': isDuration,
        'wreq': weightRequired,
        'set': setIndex,
        'sets': setCount,
        'kind': kind.name,
        'w': weightKg,
        'val': value,
        'pw': previousWeightKg,
        'pval': previousValue,
      };

  static WearCurrentSet? fromJson(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final b = _int(m['b']);
    final ex = _int(m['ex']);
    final set = _int(m['set']);
    if (b == null || ex == null || set == null) return null;
    return WearCurrentSet(
      blockIndex: b,
      exerciseId: ex,
      name: _string(m['name']) ?? '',
      isDuration: _bool(m['dur']),
      weightRequired: _bool(m['wreq']),
      setIndex: set,
      setCount: _int(m['sets']) ?? set + 1,
      kind: _enumByName(WearSetKind.values, m['kind'], WearSetKind.working),
      weightKg: _double(m['w']),
      value: _int(m['val']),
      previousWeightKg: _double(m['pw']),
      previousValue: _int(m['pval']),
    );
  }
}

/// Cvik v seznamu cviků na hodinkách.
class WearExerciseItem {
  const WearExerciseItem({
    required this.blockIndex,
    required this.exerciseId,
    required this.name,
    required this.doneSets,
    required this.totalSets,
  });

  final int blockIndex;
  final int exerciseId;
  final String name;
  final int doneSets;
  final int totalSets;

  bool get isDone => totalSets > 0 && doneSets >= totalSets;

  Map<String, Object?> toJson() => {
        'b': blockIndex,
        'ex': exerciseId,
        'name': name,
        'done': doneSets,
        'total': totalSets,
      };

  static WearExerciseItem? fromJson(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final b = _int(m['b']);
    final ex = _int(m['ex']);
    if (b == null || ex == null) return null;
    return WearExerciseItem(
      blockIndex: b,
      exerciseId: ex,
      name: _string(m['name']) ?? '',
      doneSets: _int(m['done']) ?? 0,
      totalSets: _int(m['total']) ?? 0,
    );
  }
}

/// Kompaktní stav tréninku pro hodinky.
class WearState {
  const WearState({
    required this.phase,
    this.sessionId,
    this.title,
    this.startedAtMs,
    this.unit = 'kg',
    this.kgPerUnit = 1,
    this.weightStep = 2.5,
    this.current,
    this.restEndsAtMs,
    this.restTotalSeconds = 0,
    this.exercises = const [],
  });

  const WearState.idle() : this(phase: WearPhase.idle);

  const WearState.openOnPhone(int sessionId)
      : this(phase: WearPhase.openOnPhone, sessionId: sessionId);

  const WearState.premiumRequired() : this(phase: WearPhase.premiumRequired);

  final WearPhase phase;
  final int? sessionId;

  /// Název plánu (null = volný trénink).
  final String? title;
  final int? startedAtMs;

  /// „kg“ nebo „lb“.
  final String unit;

  /// Kolik kg je jedna zobrazovaná jednotka (1 nebo 0,45359237).
  final double kgPerUnit;

  /// Krok tlačítek +/- v zobrazovaných jednotkách (2,5 kg / 5 lb).
  final double weightStep;

  /// Série na řadě; null = všechno hotové.
  final WearCurrentSet? current;

  /// Konec pauzy podle hodin telefonu (ms od epochy); null = bez pauzy.
  /// Hodinky si ho přepočítají přes `sentAtMs` zprávy, takže rozdíl hodin
  /// telefonu a hodinek nevadí.
  final int? restEndsAtMs;
  final int restTotalSeconds;
  final List<WearExerciseItem> exercises;

  int get doneSets => exercises.fold(0, (sum, e) => sum + e.doneSets);
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.totalSets);

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'session': sessionId,
        'title': title,
        'started': startedAtMs,
        'unit': unit,
        'kgPerUnit': kgPerUnit,
        'step': weightStep,
        'current': current?.toJson(),
        'restEnd': restEndsAtMs,
        'restTotal': restTotalSeconds,
        'exercises': [for (final e in exercises) e.toJson()],
      };

  static WearState? fromJson(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final list = m['exercises'];
    return WearState(
      phase: _enumByName(WearPhase.values, m['phase'], WearPhase.idle),
      sessionId: _int(m['session']),
      title: _string(m['title']),
      startedAtMs: _int(m['started']),
      unit: _string(m['unit']) ?? 'kg',
      kgPerUnit: _double(m['kgPerUnit']) ?? 1,
      weightStep: _double(m['step']) ?? 2.5,
      current: WearCurrentSet.fromJson(m['current']),
      restEndsAtMs: _int(m['restEnd']),
      restTotalSeconds: _int(m['restTotal']) ?? 0,
      exercises: list is List
          ? list.map(WearExerciseItem.fromJson).whereType<WearExerciseItem>().toList()
          : const [],
    );
  }
}

// ---------------------------------------------------------------------
// Příkazy (hodinky → telefon)
// ---------------------------------------------------------------------

/// Příkaz z hodinek. Série se určuje trojicí blockIndex + exerciseId +
/// setIndex (telefon ověří, že index cviku odpovídá ID, jinak hledá podle ID).
sealed class WearCommand {
  const WearCommand();

  String get name;

  Map<String, Object?> get args => const {};

  Map<String, Object?> toJson(int id) => {
        't': WearMsg.command,
        'id': id,
        'cmd': name,
        ...args,
      };

  static WearCommand? fromJson(Map<String, Object?> json) {
    final b = _int(json['b']);
    final ex = _int(json['ex']);
    final set = _int(json['set']);
    final delta = _int(json['delta']);
    switch (json['cmd']) {
      case 'completeSet':
        final value = _int(json['val']);
        if (b == null || ex == null || set == null || value == null) {
          return null;
        }
        return WearCompleteSet(
          blockIndex: b,
          exerciseId: ex,
          setIndex: set,
          weightKg: _double(json['w']),
          value: value,
        );
      case 'adjustWeight':
        if (b == null || ex == null || set == null || delta == null) {
          return null;
        }
        return WearAdjustWeight(
          blockIndex: b,
          exerciseId: ex,
          setIndex: set,
          delta: delta,
        );
      case 'adjustReps':
        if (b == null || ex == null || set == null || delta == null) {
          return null;
        }
        return WearAdjustReps(
          blockIndex: b,
          exerciseId: ex,
          setIndex: set,
          delta: delta,
        );
      case 'skipRest':
        return const WearSkipRest();
      case 'nextExercise':
        return const WearNextExercise();
      case 'selectExercise':
        if (b == null || ex == null) return null;
        return WearSelectExercise(blockIndex: b, exerciseId: ex);
      case 'finishWorkout':
        return const WearFinishWorkout();
      case 'openWorkout':
        return const WearOpenWorkout();
    }
    return null;
  }
}

/// Odškrtne sérii s hodnotami z hodinek (váha v kg, [value] = opakování,
/// u cviků na čas sekundy).
final class WearCompleteSet extends WearCommand {
  const WearCompleteSet({
    required this.blockIndex,
    required this.exerciseId,
    required this.setIndex,
    required this.weightKg,
    required this.value,
  });

  final int blockIndex;
  final int exerciseId;
  final int setIndex;
  final double? weightKg;
  final int value;

  @override
  String get name => 'completeSet';

  @override
  Map<String, Object?> get args => {
        'b': blockIndex,
        'ex': exerciseId,
        'set': setIndex,
        'w': weightKg,
        'val': value,
      };
}

/// Změní váhu série o [delta] kroků (krok = WearState.weightStep).
final class WearAdjustWeight extends WearCommand {
  const WearAdjustWeight({
    required this.blockIndex,
    required this.exerciseId,
    required this.setIndex,
    required this.delta,
  });

  final int blockIndex;
  final int exerciseId;
  final int setIndex;
  final int delta;

  @override
  String get name => 'adjustWeight';

  @override
  Map<String, Object?> get args =>
      {'b': blockIndex, 'ex': exerciseId, 'set': setIndex, 'delta': delta};
}

/// Změní opakování o [delta] (u cviků na čas o delta × [kWearDurationStep] s).
final class WearAdjustReps extends WearCommand {
  const WearAdjustReps({
    required this.blockIndex,
    required this.exerciseId,
    required this.setIndex,
    required this.delta,
  });

  final int blockIndex;
  final int exerciseId;
  final int setIndex;
  final int delta;

  @override
  String get name => 'adjustReps';

  @override
  Map<String, Object?> get args =>
      {'b': blockIndex, 'ex': exerciseId, 'set': setIndex, 'delta': delta};
}

final class WearSkipRest extends WearCommand {
  const WearSkipRest();

  @override
  String get name => 'skipRest';
}

/// Přejde na další cvik, který má neodškrtnuté série.
final class WearNextExercise extends WearCommand {
  const WearNextExercise();

  @override
  String get name => 'nextExercise';
}

/// Přejde na vybraný cvik (ze seznamu cviků na hodinkách).
final class WearSelectExercise extends WearCommand {
  const WearSelectExercise({required this.blockIndex, required this.exerciseId});

  final int blockIndex;
  final int exerciseId;

  @override
  String get name => 'selectExercise';

  @override
  Map<String, Object?> get args => {'b': blockIndex, 'ex': exerciseId};
}

/// Ukončení tréninku – potvrzuje se v telefonu.
final class WearFinishWorkout extends WearCommand {
  const WearFinishWorkout();

  @override
  String get name => 'finishWorkout';
}

/// Otevře obrazovku rozpracovaného tréninku v telefonu (jen když je
/// aplikace v popředí – Android jinak spouštění obrazovek z pozadí nedovolí).
final class WearOpenWorkout extends WearCommand {
  const WearOpenWorkout();

  @override
  String get name => 'openWorkout';
}

/// Krok tlačítek +/- u cviků na čas (sekundy).
const int kWearDurationStep = 5;

/// Potvrzení příkazu (telefon → hodinky).
class WearAck {
  const WearAck(this.id, {required this.ok, this.reason});

  final int id;
  final bool ok;
  final String? reason;

  Map<String, Object?> toJson() =>
      {'t': WearMsg.ack, 'id': id, 'ok': ok, 'reason': reason};

  static WearAck? fromJson(Map<String, Object?> json) {
    final id = _int(json['id']);
    if (id == null) return null;
    return WearAck(id, ok: _bool(json['ok']), reason: _string(json['reason']));
  }
}
