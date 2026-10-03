import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formulas.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/progression/progression_plan_widgets.dart';
import '../../modules/progression/progression_queries.dart';
import '../../providers.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import '../../ui/set_format.dart';
import '../../ui/set_kind_chip.dart';

/// Úprava jednoho cviku v plánu: série (opakování, cílová váha, rozcvička,
/// drop série),
/// pauza a přehled rekordu a posledního výkonu.
class PlanItemEditorScreen extends ConsumerStatefulWidget {
  const PlanItemEditorScreen({
    super.key,
    required this.planId,
    required this.planExerciseId,
  });

  final int planId;
  final int planExerciseId;

  @override
  ConsumerState<PlanItemEditorScreen> createState() =>
      _PlanItemEditorScreenState();
}

class _EditRow {
  _EditRow({
    required String reps,
    required String weight,
    this.isWarmup = false,
    this.isDrop = false,
  })  : reps = TextEditingController(text: reps),
        weight = TextEditingController(text: weight);

  final TextEditingController reps;
  final TextEditingController weight;
  bool isWarmup;

  /// Drop série: hned po předchozí sérii s nižší vahou, bez pauzy.
  bool isDrop;

  bool get isWorking => !isWarmup && !isDrop;

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class _PlanItemEditorScreenState extends ConsumerState<PlanItemEditorScreen> {
  PlanItem? _item;
  bool _notFound = false;
  bool _dirty = false;
  final _rows = <_EditRow>[];
  final _rest = TextEditingController();
  String? _error;

  /// Nastavení automatické progrese (rozsah, přírůstek, přepínač).
  ProgressionItemSettings? _progression;

  AppDatabase get _db => ref.read(databaseProvider);

  bool get _isDuration => _item?.exercise.type == ExerciseType.duration;

  /// Váha dává smysl u cviků s činkou/strojem; u vlastní váhy jde o zátěž navíc.
  bool get _showWeight => !_isDuration;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _rest.dispose();
    _progression?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _db.getPlanItems(widget.planId);
    final item =
        items.where((i) => i.item.id == widget.planExerciseId).firstOrNull;
    if (!mounted) return;
    if (item == null) {
      setState(() => _notFound = true);
      return;
    }
    setState(() {
      _item = item;
      _rest.text = '${item.item.restSeconds}';
      _progression = ProgressionItemSettings.fromItem(item.item);
      _rows.addAll(item.sets.map((s) => _EditRow(
            reps: '${s.reps}',
            weight: weightInputText(s.weightKg),
            isWarmup: s.isWarmup,
            isDrop: s.isDrop,
          )));
      if (_rows.isEmpty) _rows.add(_EditRow(reps: '10', weight: ''));
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _setRows(List<_EditRow> rows) {
    setState(() {
      for (final r in _rows) {
        r.dispose();
      }
      _rows
        ..clear()
        ..addAll(rows);
      _dirty = true;
    });
  }

  // -------------------------------------------------------------------
  // Akce
  // -------------------------------------------------------------------

  void _addSet() {
    final last = _rows.lastWhere((r) => r.isWorking, orElse: () => _rows.last);
    setState(() {
      _rows.add(_EditRow(reps: last.reps.text, weight: last.weight.text));
      _dirty = true;
    });
  }

  /// Přidá drop sérii na konec: stejná opakování, váha o 20 % nižší.
  void _addDrop() {
    final last = _rows.last;
    setState(() {
      _rows.add(_EditRow(
        reps: last.reps.text,
        weight: _dropWeightText(last.weight.text),
        isDrop: true,
      ));
      _dirty = true;
    });
  }

  /// Text váhy drop série z textu váhy předchozí série (prázdný bez váhy).
  String _dropWeightText(String previous) {
    final kg = parseWeightInput(previous);
    if (kg == null) return '';
    return weightInputText(dropSetWeight(kg, step: weightStepKg));
  }

  void _toggleDrop(int index) {
    setState(() {
      final row = _rows[index];
      row.isDrop = !row.isDrop;
      if (row.isDrop) {
        row.isWarmup = false;
        // Prázdnou váhu doplníme podle předchozí série.
        if (index > 0 && row.weight.text.trim().isEmpty) {
          row.weight.text = _dropWeightText(_rows[index - 1].weight.text);
        }
      }
      _dirty = true;
    });
  }

  void _toggleWarmup(int index) {
    setState(() {
      final row = _rows[index];
      row.isWarmup = !row.isWarmup;
      if (row.isWarmup) row.isDrop = false;
      _dirty = true;
    });
  }

  void _addWarmup() {
    final firstWorking = _rows.where((r) => r.isWorking).firstOrNull;
    final workingWeight =
        firstWorking == null ? null : parseDecimal(firstWorking.weight.text);
    final warmupCount = _rows.takeWhile((r) => r.isWarmup).length;
    setState(() {
      _rows.insert(
        warmupCount,
        _EditRow(
          reps: _isDuration ? '20' : '15',
          weight: workingWeight == null
              ? ''
              : plainNumber(
                  roundToStep(workingWeight * 0.5, step: weightDisplayStep),
                ),
          isWarmup: true,
        ),
      );
      _dirty = true;
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(index).dispose();
      _dirty = true;
    });
  }

  void _fillFromLastTime(List<SetEntry> last) {
    _setRows([
      for (final s in last)
        _EditRow(
          reps: '${(_isDuration ? s.durationSeconds : s.reps) ?? 10}',
          weight: weightInputText(s.weightKg),
          isWarmup: s.isWarmup,
          isDrop: s.isDrop,
        ),
    ]);
  }

  void _suggestFromRecord(ExerciseRecord record) {
    double? firstWorking;
    double? previous;
    for (final r in _rows) {
      if (r.isWarmup) continue;
      if (r.isDrop) {
        // Drop série navazuje na předchozí sérii: o 20 % méně.
        final w = previous == null
            ? null
            : dropSetWeight(previous, step: weightStepKg);
        r.weight.text = weightInputText(w);
        previous = w;
        continue;
      }
      final reps = int.tryParse(r.reps.text) ?? 10;
      final w =
          suggestWorkingWeight(record.oneRepMax, reps, step: weightStepKg);
      firstWorking ??= w;
      previous = w;
      r.weight.text = weightInputText(w);
    }
    for (final r in _rows.where((r) => r.isWarmup)) {
      if (firstWorking != null) {
        r.weight.text =
            weightInputText(roundToStep(firstWorking * 0.5, step: weightStepKg));
      }
    }
    _markDirty();
    setState(() {});
  }

  /// Vrátí série k uložení, nebo null při neplatném vstupu.
  List<PlanSetDraft>? _collect() {
    final maxReps = _isDuration ? 600 : 100;
    final result = <PlanSetDraft>[];
    for (final r in _rows) {
      final reps = int.tryParse(r.reps.text.trim());
      if (reps == null || reps < 1 || reps > maxReps) return null;
      double? weight;
      if (_showWeight && r.weight.text.trim().isNotEmpty) {
        weight = parseWeightInput(r.weight.text);
        if (weight == null || weight < 0 || weight > 1000) return null;
        if (weight == 0) weight = null;
      }
      result.add((
        reps: reps,
        weightKg: weight,
        isWarmup: r.isWarmup,
        isDrop: r.isDrop && !r.isWarmup,
      ));
    }
    return result;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final sets = _collect();
    final rest = int.tryParse(_rest.text.trim());
    if (sets == null || rest == null || rest < 0 || rest > 600) {
      setState(() => _error = l10n.dataPlanSetsInvalid(
            formatWeightWithUnit(context, 1000, maxDecimals: 0),
          ));
      return;
    }
    final progression = _progression?.collect();
    if (_progression != null && progression == null) {
      setState(() => _error = l10n.progressionInvalid);
      return;
    }
    await _db.savePlanItem(
      widget.planExerciseId,
      sets: sets,
      restSeconds: rest,
    );
    if (progression != null) {
      await _db.saveProgressionSettings(widget.planExerciseId, progression);
    }
    await _db.dropStaleProgression(widget.planExerciseId);
    _leave();
  }

  /// Zavře obrazovku bez dotazu na neuložené změny. PopScope čte `_dirty`
  /// při sestavení, proto nejdřív překreslíme a zavřeme až po snímku.
  void _leave() {
    if (!mounted) return;
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _removeFromPlan() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.planRemoveExerciseTitle,
      confirmLabel: l10n.planRemoveExercise,
      destructive: true,
    );
    if (!ok) return;
    await _db.removePlanItem(widget.planExerciseId);
    _leave();
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final leave = await showConfirmDialog(
      context,
      title: l10n.unsavedChangesTitle,
      message: l10n.unsavedChangesMessage,
      confirmLabel: l10n.discardChanges,
      destructive: true,
    );
    if (leave) _leave();
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = _item;

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }
    if (item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stats = ref.watch(exerciseStatsProvider(item.exercise.id)).valueOrNull;
    var workingNumber = 0;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.exercise.localizedName(context)),
          actions: [
            TextButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _StatsCard(
              stats: stats,
              canSuggest: _showWeight && stats?.record != null,
              onFillFromLast: stats == null || stats.lastSets.isEmpty
                  ? null
                  : () => _fillFromLastTime(stats.lastSets),
              onSuggest: stats?.record == null
                  ? null
                  : () => _suggestFromRecord(stats!.record!),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l10n.planSetsTitle,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (var i = 0; i < _rows.length; i++)
              _SetEditorRow(
                number: _rows[i].isWorking ? ++workingNumber : null,
                row: _rows[i],
                isDuration: _isDuration,
                showWeight: _showWeight,
                canDelete: _rows.length > 1,
                onChanged: _markDirty,
                onToggleWarmup: () => _toggleWarmup(i),
                onToggleDrop: () => _toggleDrop(i),
                onDelete: () => _removeRow(i),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.planAddSet),
                  ),
                  TextButton.icon(
                    onPressed: _addWarmup,
                    icon: const Icon(Icons.whatshot_outlined),
                    label: Text(l10n.planAddWarmup),
                  ),
                  TextButton.icon(
                    onPressed: _addDrop,
                    icon: const Icon(Icons.trending_down),
                    label: Text(l10n.dropAdd),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _rest,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.planTargetRest),
                onChanged: (_) => _markDirty(),
              ),
            ),
            if (_progression case final progression?)
              ProgressionItemSettingsSection(
                settings: progression,
                exercise: item.exercise,
                planExerciseId: widget.planExerciseId,
                firstWorkingReps: int.tryParse(
                  _rows.where((r) => r.isWorking).firstOrNull?.reps.text.trim() ??
                      '',
                ),
                onChanged: _markDirty,
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton(
                onPressed: _removeFromPlan,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.planRemoveExercise),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stats,
    required this.canSuggest,
    required this.onFillFromLast,
    required this.onSuggest,
  });

  final ExerciseStats? stats;
  final bool canSuggest;
  final VoidCallback? onFillFromLast;
  final VoidCallback? onSuggest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = stats;
    final record = s?.record;
    final last = s?.lastSets ?? const <SetEntry>[];

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(l10n.statsTitle, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (s == null)
              const LinearProgressIndicator()
            else if (record == null && last.isEmpty)
              Text(l10n.statsNoHistory)
            else ...[
              if (record != null) Text(describeRecord(context, record)),
              if (last.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(describeLastSets(context, last)),
              ],
            ],
            if (onFillFromLast != null || canSuggest) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (onFillFromLast != null)
                    OutlinedButton(
                      onPressed: onFillFromLast,
                      child: Text(l10n.planFillFromLast),
                    ),
                  if (canSuggest)
                    OutlinedButton(
                      onPressed: onSuggest,
                      child: Text(l10n.planSuggestWeights),
                    ),
                ],
              ),
              if (canSuggest)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.planSuggestHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Řádek série v editoru. Pracovní série má číslo; rozcvička a drop
/// série mají místo čísla ikonu a nad řádkem štítek s celým slovem.
class _SetEditorRow extends StatelessWidget {
  const _SetEditorRow({
    required this.number,
    required this.row,
    required this.isDuration,
    required this.showWeight,
    required this.canDelete,
    required this.onChanged,
    required this.onToggleWarmup,
    required this.onToggleDrop,
    required this.onDelete,
  });

  /// Číslo pracovní série; null u rozcvičky a drop série.
  final int? number;
  final _EditRow row;
  final bool isDuration;
  final bool showWeight;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onToggleWarmup;
  final VoidCallback onToggleDrop;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = number;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SetKindChip(isWarmup: row.isWarmup),
            ),
          Row(
            children: [
              SizedBox(
                width: 32,
                child: n != null
                    ? Text(
                        '$n',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    : Icon(
                        row.isWarmup ? Icons.whatshot : Icons.trending_down,
                        size: 18,
                        color: row.isWarmup ? scheme.tertiary : scheme.secondary,
                        semanticLabel:
                            row.isWarmup ? l10n.setKindWarmup : l10n.setKindDrop,
                      ),
              ),
              IconButton(
                tooltip: l10n.planToggleWarmup,
                isSelected: row.isWarmup,
                visualDensity: VisualDensity.compact,
                onPressed: onToggleWarmup,
                icon: const Icon(Icons.whatshot_outlined),
                selectedIcon: Icon(Icons.whatshot, color: scheme.tertiary),
              ),
              IconButton(
                tooltip: l10n.dropToggle,
                isSelected: row.isDrop,
                visualDensity: VisualDensity.compact,
                onPressed: onToggleDrop,
                icon: const Icon(Icons.trending_down),
                selectedIcon: Icon(Icons.trending_down, color: scheme.secondary),
              ),
              Expanded(
                child: TextField(
                  controller: row.reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: isDuration ? 's' : l10n.workoutColReps,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (showWeight) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: weightUnit,
                      hintText: '–',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
              IconButton(
                tooltip: l10n.planRemoveSet,
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
