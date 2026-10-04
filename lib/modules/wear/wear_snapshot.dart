// Výběr série „na řadě“ a sestavení stavu pro hodinky (čistý Dart,
// testy: test/wear_snapshot_test.dart).
//
// Obrazovka tréninku (lib/features/workout/workout_screen_wear.dart)
// převede své bloky a řádky na [WearBlockInput] a z nich se tu složí
// [WearState]. Pravidla pro sérii na řadě:
// 1. Navržená série obrazovky (supersérie, drop série, výběr z hodinek),
//    pokud ještě není odškrtnutá.
// 2. Jinak první neodškrtnutá série cviku, u kterého byla naposledy
//    odškrtnuta série (nejvyšší ID uložené série) – po sérii samostatného
//    cviku se tak zůstane u něj.
// 3. Jinak první cvik s neodškrtnutou sérií za ním (dokola od začátku).
// 4. Všechno hotové → null.

import 'wear_protocol.dart';

/// Řádek série. [value] = opakování, u cviků na čas sekundy.
typedef WearRowInput = ({
  bool isDone,
  bool isWarmup,
  bool isDrop,
  double? weightKg,
  int? value,
  double? previousWeightKg,
  int? previousValue,
  int? savedId,
});

/// Cvik v tréninku (pořadí jako na obrazovce).
typedef WearBlockInput = ({
  int exerciseId,
  String name,
  bool isDuration,
  bool weightRequired,
  List<WearRowInput> rows,
});

/// Pozice série: index cviku a index řádku.
typedef WearSetPosition = ({int block, int row});

int? _firstUndone(WearBlockInput block) {
  for (var i = 0; i < block.rows.length; i++) {
    if (!block.rows[i].isDone) return i;
  }
  return null;
}

bool _isUndone(List<WearBlockInput> blocks, WearSetPosition p) =>
    p.block >= 0 &&
    p.block < blocks.length &&
    p.row >= 0 &&
    p.row < blocks[p.block].rows.length &&
    !blocks[p.block].rows[p.row].isDone;

/// Cvik, u kterého byla naposledy odškrtnuta série, nebo null.
int? _lastActiveBlock(List<WearBlockInput> blocks) {
  int? result;
  var bestId = -1;
  for (var b = 0; b < blocks.length; b++) {
    for (final r in blocks[b].rows) {
      final id = r.savedId;
      if (id != null && id > bestId) {
        bestId = id;
        result = b;
      }
    }
  }
  return result;
}

/// První cvik s neodškrtnutou sérií od indexu [start] dokola (bez [skip]).
WearSetPosition? _firstUndoneFrom(
  List<WearBlockInput> blocks,
  int start, {
  int? skip,
}) {
  final n = blocks.length;
  for (var k = 0; k < n; k++) {
    final b = (start + k) % n;
    if (b == skip) continue;
    final r = _firstUndone(blocks[b]);
    if (r != null) return (block: b, row: r);
  }
  return null;
}

/// Série na řadě (pravidla v záhlaví souboru), nebo null = vše hotové.
WearSetPosition? pickCurrentSet(
  List<WearBlockInput> blocks, {
  WearSetPosition? suggested,
}) {
  if (blocks.isEmpty) return null;
  if (suggested != null && _isUndone(blocks, suggested)) return suggested;
  final last = _lastActiveBlock(blocks);
  if (last != null) {
    final r = _firstUndone(blocks[last]);
    if (r != null) return (block: last, row: r);
    return _firstUndoneFrom(blocks, last + 1);
  }
  return _firstUndoneFrom(blocks, 0);
}

/// Pozice první neodškrtnuté série dalšího cviku za [fromBlock] (dokola),
/// nebo null, když jiný cvik s neodškrtnutou sérií není.
WearSetPosition? nextExercisePosition(
  List<WearBlockInput> blocks,
  int fromBlock,
) {
  if (blocks.isEmpty) return null;
  return _firstUndoneFrom(blocks, fromBlock + 1, skip: fromBlock);
}

/// První neodškrtnutá série cviku [block], nebo null.
WearSetPosition? firstUndoneInBlock(List<WearBlockInput> blocks, int block) {
  if (block < 0 || block >= blocks.length) return null;
  final r = _firstUndone(blocks[block]);
  return r == null ? null : (block: block, row: r);
}

WearSetKind _kind(WearRowInput r) => r.isWarmup
    ? WearSetKind.warmup
    : r.isDrop
        ? WearSetKind.drop
        : WearSetKind.working;

/// Stav probíhajícího tréninku pro hodinky.
WearState buildActiveWearState({
  required int sessionId,
  required String? title,
  required DateTime startedAt,
  required List<WearBlockInput> blocks,
  WearSetPosition? suggested,
  DateTime? restEndsAt,
  int restTotalSeconds = 0,
  required String unit,
  required double kgPerUnit,
  required double weightStep,
}) {
  final pick = pickCurrentSet(blocks, suggested: suggested);
  WearCurrentSet? current;
  if (pick != null) {
    final block = blocks[pick.block];
    final row = block.rows[pick.row];
    current = WearCurrentSet(
      blockIndex: pick.block,
      exerciseId: block.exerciseId,
      name: block.name,
      isDuration: block.isDuration,
      weightRequired: block.weightRequired,
      setIndex: pick.row,
      setCount: block.rows.length,
      kind: _kind(row),
      weightKg: block.isDuration ? null : row.weightKg,
      value: row.value,
      previousWeightKg: block.isDuration ? null : row.previousWeightKg,
      previousValue: row.previousValue,
    );
  }
  return WearState(
    phase: WearPhase.active,
    sessionId: sessionId,
    title: title,
    startedAtMs: startedAt.millisecondsSinceEpoch,
    unit: unit,
    kgPerUnit: kgPerUnit,
    weightStep: weightStep,
    current: current,
    restEndsAtMs: restEndsAt?.millisecondsSinceEpoch,
    restTotalSeconds: restEndsAt == null ? 0 : restTotalSeconds,
    exercises: [
      for (var b = 0; b < blocks.length; b++)
        WearExerciseItem(
          blockIndex: b,
          exerciseId: blocks[b].exerciseId,
          name: blocks[b].name,
          doneSets: blocks[b].rows.where((r) => r.isDone).length,
          totalSets: blocks[b].rows.length,
        ),
    ],
  );
}
