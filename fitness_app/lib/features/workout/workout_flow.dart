// Pořadí sérií v tréninku se supersériemi a drop sériemi (čistý Dart,
// testy: test/workout_flow_test.dart).
//
// Pravidla po odškrtnutí série:
// 1. Když hned za ní následuje neodškrtnutá drop série téhož cviku,
//    pokračuje se jí – bez pauzy.
// 2. U cviku v supersérii se pokračuje stejným kolem dalšího cviku
//    supersérie (A1 → A2) – bez pauzy. Kolo = pořadí pracovní série
//    (rozcvičky se nepočítají, drop série patří ke své sérii).
// 3. Když je kolo hotové u všech cviků supersérie, začne pauza podle
//    posledního cviku supersérie a navrhne se další kolo od prvního cviku.
// 4. Jinak (samostatný cvik, rozcvička) pauza podle cviku jako dřív.

/// Řádek série pro výpočet dalšího kroku.
typedef FlowRow = ({bool isDone, bool isWarmup, bool isDrop});

/// Cvik v tréninku: skupina supersérie (null = samostatný), řádky a pauza.
typedef FlowBlock = ({int? group, List<FlowRow> rows, int restSeconds});

/// Další krok: navržená série ([block], [row]) a pauza v sekundách
/// (null = bez pauzy).
typedef FlowStep = ({int? block, int? row, int? restSeconds});

/// Pořadí kola pro každý řádek (null u rozcvičky). Drop série dostane
/// kolo své „mateřské“ série.
List<int?> roundsOf(List<FlowRow> rows) {
  final result = <int?>[];
  var round = -1;
  int? lastWorkingRound;
  for (final r in rows) {
    if (r.isWarmup) {
      result.add(null);
      lastWorkingRound = null;
    } else if (r.isDrop) {
      result.add(lastWorkingRound);
    } else {
      round++;
      lastWorkingRound = round;
      result.add(round);
    }
  }
  return result;
}

/// Indexy cviků supersérie, do které patří cvik [blockIndex] (po sobě
/// jdoucí cviky se stejnou skupinou). U samostatného cviku jen on sám.
List<int> supersetMembers(List<FlowBlock> blocks, int blockIndex) {
  final g = blocks[blockIndex].group;
  if (g == null) return [blockIndex];
  var start = blockIndex;
  while (start > 0 && blocks[start - 1].group == g) {
    start--;
  }
  var end = blockIndex + 1;
  while (end < blocks.length && blocks[end].group == g) {
    end++;
  }
  return [for (var i = start; i < end; i++) i];
}

/// První neodškrtnutá pracovní série cviku v kole [round], nebo null.
int? _undoneWorkingInRound(FlowBlock block, int round) {
  final rounds = roundsOf(block.rows);
  for (var i = 0; i < block.rows.length; i++) {
    final r = block.rows[i];
    if (!r.isDone && !r.isWarmup && !r.isDrop && rounds[i] == round) return i;
  }
  return null;
}

/// Co dělat po odškrtnutí série [rowIndex] cviku [blockIndex].
FlowStep nextAfterSet(List<FlowBlock> blocks, int blockIndex, int rowIndex) {
  final block = blocks[blockIndex];
  final rows = block.rows;

  // 1. Navazující drop série.
  if (rowIndex + 1 < rows.length) {
    final next = rows[rowIndex + 1];
    if (next.isDrop && !next.isDone) {
      return (block: blockIndex, row: rowIndex + 1, restSeconds: null);
    }
  }

  final FlowStep standalone =
      (block: null, row: null, restSeconds: block.restSeconds);
  final members = supersetMembers(blocks, blockIndex);
  if (members.length < 2) return standalone;
  final round = roundsOf(rows)[rowIndex];
  if (round == null) return standalone; // rozcvička

  // 2. Další cvik supersérie ve stejném kole (nejdřív ty za tímto cvikem).
  final pos = members.indexOf(blockIndex);
  final order = [...members.sublist(pos + 1), ...members.sublist(0, pos)];
  for (final m in order) {
    final r = _undoneWorkingInRound(blocks[m], round);
    if (r != null) return (block: m, row: r, restSeconds: null);
  }

  // 3. Kolo hotové: pauza podle posledního cviku, další kolo od začátku.
  final rest = blocks[members.last].restSeconds;
  final maxRounds = members
      .map((m) => blocks[m].rows.length)
      .fold<int>(0, (a, b) => a > b ? a : b);
  for (var r = round + 1; r <= maxRounds; r++) {
    for (final m in members) {
      final row = _undoneWorkingInRound(blocks[m], r);
      if (row != null) return (block: m, row: row, restSeconds: rest);
    }
  }
  // Zbyly jen dřívější vynechané série? Navrhni první z nich.
  for (var r = 0; r < round; r++) {
    for (final m in members) {
      final row = _undoneWorkingInRound(blocks[m], r);
      if (row != null) return (block: m, row: row, restSeconds: rest);
    }
  }
  return (block: null, row: null, restSeconds: rest);
}
