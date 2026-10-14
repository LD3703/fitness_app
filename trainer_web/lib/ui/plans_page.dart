import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../backend.dart';
import '../catalog.dart';
import '../strings.dart';
import 'common.dart';

// ---------------------------------------------------------------------------
// Knihovna plánů
// ---------------------------------------------------------------------------

class PlansPage extends StatefulWidget {
  const PlansPage({super.key, required this.trainer});

  final Trainer trainer;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late final _library = Backend.instance.watchLibrary();

  Future<void> _create() async {
    final s = S.of(context);
    final plan = await openPlanEditor(context);
    if (plan == null) return;
    try {
      await Backend.instance.saveLibraryPlan(plan);
      if (mounted) showSnack(context, s('saved'));
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _edit(LibraryPlan p) async {
    final s = S.of(context);
    final plan = await openPlanEditor(context, initial: p.plan);
    if (plan == null) return;
    try {
      await Backend.instance.saveLibraryPlan(plan, id: p.id);
      if (mounted) showSnack(context, s('savedResendHint'));
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _duplicate(LibraryPlan p) async {
    final s = S.of(context);
    final name = '${p.plan.name} (${s('copySuffix')})';
    final copy = CoachPlan(
      name: name.length > coachPlanNameMax
          ? name.substring(0, coachPlanNameMax)
          : name,
      description: p.plan.description,
      weekdaysMask: p.plan.weekdaysMask,
      exercises: p.plan.exercises,
    );
    try {
      await Backend.instance.saveLibraryPlan(copy);
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _delete(LibraryPlan p) async {
    final s = S.of(context);
    final ok = await confirm(
      context,
      title: s('deletePlanTitle', {'name': p.plan.name}),
      message: s('deleteLibraryPlanMessage'),
      action: s('delete'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await Backend.instance.deleteLibraryPlan(p.id);
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _share(LibraryPlan p) async {
    final s = S.of(context);
    try {
      final id = await Backend.instance
          .sharePlan(p.plan, authorName: widget.trainer.name);
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: sharedPlanUrl(id)));
      if (mounted) showSnack(context, s('shareLinkCopied'));
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _sendToClients(LibraryPlan p) async {
    final s = S.of(context);
    final List<Client> clients;
    try {
      clients = await Backend.instance.watchClients().first;
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
      return;
    }
    if (!mounted) return;
    if (clients.isEmpty) {
      showSnack(context, s('noClientsTitle'));
      return;
    }
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PickClientsDialog(clients: clients),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    try {
      for (final uid in picked) {
        await Backend.instance.assignPlan(uid, p.plan,
            trainerName: widget.trainer.name, planId: p.id);
      }
      if (mounted) showSnack(context, s('planSentMany', {'n': picked.length}));
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s('navPlans'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(s('newPlan')),
      ),
      body: StreamBuilder<List<LibraryPlan>>(
        stream: _library,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(errorText(s, snap.error!)));
          }
          final plans = snap.data;
          if (plans == null) return const Center(child: CircularProgressIndicator());
          return PageBody(
            children: [
              Text(s('libraryIntro')),
              const SizedBox(height: 16),
              if (plans.isEmpty) Text(s('libraryEmpty')),
              for (final p in plans)
                Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    title: Text(p.plan.name),
                    subtitle: Text([
                      s('exercisesCount', {'n': p.plan.exercises.length}),
                      s('setsCount', {'n': p.plan.workingSets}),
                      if (p.plan.weekdaysMask != 0) weekdaysText(s, p.plan.weekdaysMask),
                    ].join(' · ')),
                    onTap: () => _edit(p),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'send':
                            _sendToClients(p);
                          case 'share':
                            _share(p);
                          case 'copy':
                            _duplicate(p);
                          case 'delete':
                            _delete(p);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'send', child: Text(s('sendToClients'))),
                        PopupMenuItem(value: 'share', child: Text(s('shareLink'))),
                        PopupMenuItem(value: 'copy', child: Text(s('duplicate'))),
                        PopupMenuItem(value: 'delete', child: Text(s('delete'))),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 72),
            ],
          );
        },
      ),
    );
  }
}

class _PickClientsDialog extends StatefulWidget {
  const _PickClientsDialog({required this.clients});

  final List<Client> clients;

  @override
  State<_PickClientsDialog> createState() => _PickClientsDialogState();
}

class _PickClientsDialogState extends State<_PickClientsDialog> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s('sendToClients')),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in widget.clients)
              CheckboxListTile(
                value: _picked.contains(c.uid),
                title: Text(c.name),
                onChanged: (v) => setState(
                    () => v == true ? _picked.add(c.uid) : _picked.remove(c.uid)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
        FilledButton(
          onPressed: _picked.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set<String>.of(_picked)),
          child: Text(s('send')),
        ),
      ],
    );
  }
}

/// Výběr plánu z knihovny (přiřazení klientovi).
Future<LibraryPlan?> pickLibraryPlan(BuildContext context) async {
  final s = S.of(context);
  final List<LibraryPlan> plans;
  try {
    plans = await Backend.instance.watchLibrary().first;
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(s, e));
    return null;
  }
  if (!context.mounted) return null;
  if (plans.isEmpty) {
    showSnack(context, s('libraryEmpty'));
    return null;
  }
  return showDialog<LibraryPlan>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(s('fromLibrary')),
      children: [
        for (final p in plans)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(p),
            child: ListTile(
              title: Text(p.plan.name),
              subtitle: Text(s('exercisesCount', {'n': p.plan.exercises.length})),
            ),
          ),
      ],
    ),
  );
}

String weekdaysText(S s, int mask) => [
      for (var i = 0; i < 7; i++)
        if (mask & (1 << i) != 0) s('day$i'),
    ].join(' ');

// ---------------------------------------------------------------------------
// Editor plánu
// ---------------------------------------------------------------------------

/// Otevře editor; vrátí hotový plán, nebo null (zrušeno).
Future<CoachPlan?> openPlanEditor(BuildContext context, {CoachPlan? initial}) =>
    Navigator.of(context).push<CoachPlan>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PlanEditorPage(initial: initial),
    ));

class _EditSet {
  _EditSet({this.reps = 10, this.kg, this.warmup = false, this.drop = false});

  int reps;
  double? kg;
  bool warmup;
  bool drop;

  _EditSet copy() => _EditSet(reps: reps, kg: kg, warmup: false, drop: false);
}

class _EditExercise {
  _EditExercise({
    this.slug,
    required this.en,
    required this.cs,
    this.muscle,
    this.equipment,
    this.type,
    this.restAuto = true,
    this.restSeconds,
    this.repMin,
    this.repMax,
    this.note,
    this.linkPrev = false,
    required this.sets,
  });

  factory _EditExercise.fromPlan(CoachPlanExercise e, {required bool linkPrev}) =>
      _EditExercise(
        slug: e.slug,
        en: e.nameEn,
        cs: e.nameCs,
        muscle: e.muscle,
        equipment: e.equipment,
        type: e.type,
        restAuto: e.restAuto,
        restSeconds: e.restSeconds,
        repMin: e.repMin,
        repMax: e.repMax,
        note: e.note,
        linkPrev: linkPrev,
        sets: [
          for (final s in e.sets)
            _EditSet(reps: s.reps, kg: s.kg, warmup: s.warmup, drop: s.drop),
        ],
      );

  /// Nový cvik z katalogu (výchozí 3 série).
  factory _EditExercise.fromCatalog(CatalogExercise c) => _EditExercise(
        slug: c.slug,
        en: c.en,
        cs: c.cs,
        type: c.type,
        sets: _defaultSets(c.type),
      );

  final String? slug;
  String en;
  String cs;
  String? muscle;
  String? equipment;
  String? type;
  bool restAuto;
  int? restSeconds;
  int? repMin;
  int? repMax;

  /// Poznámka pro klienta (technika, tempo…).
  String? note;
  bool linkPrev;
  final List<_EditSet> sets;

  String nameFor(String lang) => lang == 'cs' ? cs : en;
}

List<_EditSet> _defaultSets(String? type) => switch (type) {
      'duration' => [for (var i = 0; i < 3; i++) _EditSet(reps: 30)],
      'bodyweightReps' => [for (var i = 0; i < 3; i++) _EditSet(reps: 12)],
      _ => [for (var i = 0; i < 3; i++) _EditSet(reps: 10)],
    };

const _restOptions = [30, 45, 60, 90, 120, 150, 180, 240, 300];

class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({super.key, this.initial});

  final CoachPlan? initial;

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _desc =
      TextEditingController(text: widget.initial?.description ?? '');
  late int _days = widget.initial?.weekdaysMask ?? 0;
  late final List<_EditExercise> _exercises = _load(widget.initial);
  Catalog? _catalog;
  bool _dirty = false;

  static List<_EditExercise> _load(CoachPlan? plan) {
    final list = <_EditExercise>[];
    final ex = plan?.exercises ?? const <CoachPlanExercise>[];
    for (var i = 0; i < ex.length; i++) {
      final link = i > 0 && ex[i].superset != null && ex[i].superset == ex[i - 1].superset;
      list.add(_EditExercise.fromPlan(ex[i], linkPrev: link));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    Catalog.load().then((c) {
      if (mounted) setState(() => _catalog = c);
    });
    _name.addListener(_touch);
    _desc.addListener(_touch);
  }

  void _touch() => _dirty = true;

  void _change(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  String? _typeOf(_EditExercise e) => e.type ?? _catalog?.bySlug(e.slug)?.type;

  String? _muscleOf(_EditExercise e) => e.muscle ?? _catalog?.bySlug(e.slug)?.muscle;

  Future<void> _addExercise() async {
    final catalog = _catalog ?? await Catalog.load();
    if (!mounted) return;
    final picked = await showDialog<_EditExercise>(
      context: context,
      builder: (context) => _ExercisePicker(catalog: catalog),
    );
    if (picked != null) _change(() => _exercises.add(picked));
  }

  void _save() {
    final s = S.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, s('planNameRequired'));
      return;
    }
    if (_exercises.isEmpty) {
      showSnack(context, s('planNeedsExercise'));
      return;
    }
    if (_exercises.any((e) => e.sets.isEmpty)) {
      showSnack(context, s('planNeedsSets'));
      return;
    }
    // Supersérie: cvik spojený s předchozím má stejné číslo skupiny.
    final groups = List<int?>.filled(_exercises.length, null);
    var next = 1;
    for (var i = 1; i < _exercises.length; i++) {
      if (!_exercises[i].linkPrev) continue;
      groups[i - 1] ??= next++;
      groups[i] = groups[i - 1];
    }
    final plan = CoachPlan(
      name: name,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      weekdaysMask: _days,
      exercises: [
        for (var i = 0; i < _exercises.length; i++)
          _toPlan(_exercises[i], groups[i]),
      ],
    );
    Navigator.of(context).pop(plan);
  }

  CoachPlanExercise _toPlan(_EditExercise e, int? superset) {
    var lo = e.repMin;
    var hi = e.repMax;
    if (lo != null && hi != null && lo > hi) (lo, hi) = (hi, lo);
    final type = _typeOf(e);
    return CoachPlanExercise(
      slug: e.slug,
      nameEn: e.en,
      nameCs: e.cs,
      muscle: e.slug == null ? e.muscle : null,
      equipment: e.slug == null ? e.equipment : null,
      type: e.slug == null ? e.type : null,
      restAuto: e.restAuto,
      restSeconds: e.restAuto ? null : e.restSeconds,
      superset: superset,
      repMin: lo,
      repMax: hi,
      note: e.note == null || e.note!.trim().isEmpty ? null : e.note!.trim(),
      sets: [
        for (final set in e.sets)
          CoachPlanSet(
            reps: set.reps,
            kg: type == 'weightReps' || type == null ? set.kg : null,
            warmup: set.warmup,
            drop: set.drop,
          ),
      ],
    );
  }

  Future<void> _close() async {
    final s = S.of(context);
    if (_dirty) {
      final ok = await confirm(context,
          title: s('discardTitle'), message: s('discardMessage'), action: s('discard'));
      if (!ok) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          title: Text(widget.initial == null ? s('newPlan') : s('editPlan')),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(onPressed: _save, child: Text(s('save'))),
            ),
          ],
        ),
        body: PageBody(
          children: [
            TextField(
              controller: _name,
              maxLength: coachPlanNameMax,
              decoration: InputDecoration(
                labelText: s('planName'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLength: coachPlanDescriptionMax,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s('planDescription'),
                helperText: s('planDescriptionHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(s('planDays'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(s('day$i')),
                    selected: _days & (1 << i) != 0,
                    onSelected: (v) => _change(() => _days ^= 1 << i),
                  ),
              ],
            ),
            SectionTitle(s('exercises')),
            for (var i = 0; i < _exercises.length; i++)
              _ExerciseCard(
                key: ObjectKey(_exercises[i]),
                index: i,
                exercise: _exercises[i],
                count: _exercises.length,
                type: _typeOf(_exercises[i]),
                muscle: _muscleOf(_exercises[i]),
                onChanged: _change,
                onMove: (d) => _change(() {
                  final e = _exercises.removeAt(i);
                  _exercises.insert(i + d, e);
                }),
                onRemove: () => _change(() => _exercises.removeAt(i)),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: Text(s('addExercise')),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.count,
    required this.type,
    required this.muscle,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final _EditExercise exercise;
  final int count;
  final String? type;
  final String? muscle;
  final void Function(VoidCallback) onChanged;
  final void Function(int delta) onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final e = exercise;
    final withKg = type == 'weightReps' || type == null;
    final repsLabel = type == 'duration' ? s('seconds') : s('reps');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: e.linkPrev,
                title: Text(s('supersetWithPrev')),
                onChanged: (v) => onChanged(() => e.linkPrev = v ?? false),
              ),
            Row(
              children: [
                Text('${index + 1}.', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.nameFor(s.lang), style: theme.textTheme.titleMedium),
                      Text(
                        [
                          if (muscle != null) s('muscle_$muscle'),
                          if (e.slug == null) s('customExercise'),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: s('moveUp'),
                  onPressed: index == 0 ? null : () => onMove(-1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: s('moveDown'),
                  onPressed: index == count - 1 ? null : () => onMove(1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: s('delete'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${s('rest')}: '),
                    DropdownButton<int>(
                      value: e.restAuto ? 0 : (e.restSeconds ?? 90),
                      isDense: true,
                      items: [
                        DropdownMenuItem(value: 0, child: Text(s('restAuto'))),
                        for (final r in _restChoices(e))
                          DropdownMenuItem(value: r, child: Text(_restLabel(r))),
                      ],
                      onChanged: (v) => onChanged(() {
                        if (v == null || v == 0) {
                          e.restAuto = true;
                          e.restSeconds = null;
                        } else {
                          e.restAuto = false;
                          e.restSeconds = v;
                        }
                      }),
                    ),
                  ],
                ),
                if (type != 'duration')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${s('repRange')}: '),
                      _NumberField(
                        width: 56,
                        value: e.repMin?.toDouble(),
                        hint: s('min'),
                        onChanged: (v) => onChanged(() => e.repMin = v?.round()),
                      ),
                      const Text(' – '),
                      _NumberField(
                        width: 56,
                        value: e.repMax?.toDouble(),
                        hint: s('max'),
                        onChanged: (v) => onChanged(() => e.repMax = v?.round()),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextFormField(
                initialValue: e.note ?? '',
                minLines: 1,
                maxLines: 4,
                maxLength: coachExerciseNoteMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: s('exerciseNote'),
                  helperText: s('exerciseNoteHint'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => onChanged(() => e.note = v),
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < e.sets.length; i++)
              _SetRow(
                key: ObjectKey(e.sets[i]),
                number: i + 1,
                set: e.sets[i],
                withKg: withKg,
                repsLabel: repsLabel,
                onChanged: onChanged,
                onRemove: () => onChanged(() => e.sets.removeAt(i)),
              ),
            TextButton.icon(
              onPressed: e.sets.length >= coachPlanMaxSets
                  ? null
                  : () => onChanged(() => e.sets.add(
                      e.sets.isEmpty ? _defaultSets(type).first : e.sets.last.copy())),
              icon: const Icon(Icons.add),
              label: Text(s('addSet')),
            ),
          ],
        ),
      ),
    );
  }

  /// Nabízené pauzy (+ ruční hodnota z plánu, když v nabídce není).
  static List<int> _restChoices(_EditExercise e) {
    final set = {..._restOptions};
    if (!e.restAuto && e.restSeconds != null) set.add(e.restSeconds!);
    return set.toList()..sort();
  }

  static String _restLabel(int seconds) {
    if (seconds < 60) return '$seconds s';
    final m = seconds ~/ 60;
    final r = seconds % 60;
    return r == 0 ? '$m min' : '$m:${r.toString().padLeft(2, '0')}';
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.number,
    required this.set,
    required this.withKg,
    required this.repsLabel,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final _EditSet set;
  final bool withKg;
  final String repsLabel;
  final void Function(VoidCallback) onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 24, child: Text('$number.')),
          _NumberField(
            width: 72,
            value: set.reps.toDouble(),
            label: repsLabel,
            onChanged: (v) => onChanged(() => set.reps = (v ?? 0).round().clamp(0, 10000)),
          ),
          if (withKg)
            _NumberField(
              width: 84,
              value: set.kg,
              label: 'kg',
              hint: s('kgOptional'),
              decimal: true,
              onChanged: (v) => onChanged(() => set.kg = v == null || v <= 0 ? null : v.clamp(0, 1000).toDouble()),
            ),
          FilterChip(
            label: Text(s('warmupTag')),
            selected: set.warmup,
            onSelected: (v) => onChanged(() {
              set.warmup = v;
              if (v) set.drop = false;
            }),
          ),
          FilterChip(
            label: Text(s('dropTag')),
            selected: set.drop,
            onSelected: (v) => onChanged(() {
              set.drop = v;
              if (v) set.warmup = false;
            }),
          ),
          IconButton(
            tooltip: s('delete'),
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Malé číselné pole (bez controlleru – hodnota se drží v modelu editoru).
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.width,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.decimal = false,
  });

  final double width;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? label;
  final String? hint;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null
        ? ''
        : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: text,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
        ],
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        onChanged: (t) => onChanged(double.tryParse(t.replaceAll(',', '.'))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Výběr cviku
// ---------------------------------------------------------------------------

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.catalog});

  final Catalog catalog;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';
  String? _muscle;

  Future<void> _custom() async {
    final e = await showDialog<_EditExercise>(
      context: context,
      builder: (context) => const _CustomExerciseDialog(),
    );
    if (e != null && mounted) Navigator.of(context).pop(e);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final results =
        widget.catalog.search(_query, muscle: _muscle, lang: s.lang);
    return AlertDialog(
      title: Text(s('addExercise')),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s('searchExercise'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s('allMuscles')),
                      selected: _muscle == null,
                      onSelected: (_) => setState(() => _muscle = null),
                    ),
                  ),
                  for (final m in muscleOrder)
                    if (widget.catalog.exercises.any((e) => e.muscle == m))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(s('muscle_$m')),
                          selected: _muscle == m,
                          onSelected: (_) => setState(() => _muscle = m),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text(s('noResults')))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final c = results[i];
                        return ListTile(
                          dense: true,
                          title: Text(c.nameFor(s.lang)),
                          subtitle: Text(
                              '${s('muscle_${c.muscle}')} · ${s('equipment_${c.equipment}')}'),
                          onTap: () => Navigator.of(context)
                              .pop(_EditExercise.fromCatalog(c)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _custom,
          icon: const Icon(Icons.edit_note),
          label: Text(s('customExercise')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
      ],
    );
  }
}

/// Vlastní cvik (u klienta se založí podle názvu, partie, vybavení, typu).
class _CustomExerciseDialog extends StatefulWidget {
  const _CustomExerciseDialog();

  @override
  State<_CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<_CustomExerciseDialog> {
  final _name = TextEditingController();
  String _muscle = 'chest';
  String _equipment = 'barbell';
  String _type = 'weightReps';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget dropdown(String label, String value, List<String> values,
            String prefix, ValueChanged<String> onChanged) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              SizedBox(width: 120, child: Text(label)),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: [
                    for (final v in values)
                      DropdownMenuItem(value: v, child: Text(s('$prefix$v'))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => onChanged(v));
                  },
                ),
              ),
            ],
          ),
        );
    return AlertDialog(
      title: Text(s('customExercise')),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(labelText: s('exerciseName')),
            ),
            dropdown(s('muscle'), _muscle,
                muscleOrder.where((m) => m != 'legs').toList(), 'muscle_',
                (v) => _muscle = v),
            dropdown(s('equipment'), _equipment, equipmentOrder, 'equipment_',
                (v) => _equipment = v),
            dropdown(s('exerciseType'), _type, typeOrder, 'type_', (v) => _type = v),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_EditExercise(
              en: name,
              cs: name,
              muscle: _muscle,
              equipment: _equipment,
              type: _type,
              sets: _defaultSets(_type),
            ));
          },
          child: Text(s('add')),
        ),
      ],
    );
  }
}
