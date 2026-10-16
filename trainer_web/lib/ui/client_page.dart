import 'package:flutter/material.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../backend.dart';
import '../strings.dart';
import 'charts.dart';
import 'common.dart';
import 'plans_page.dart';
import 'sessions.dart';

/// Detail klienta: souhrn, grafy, rekordy, plány, historie s komentáři.
class ClientPage extends StatefulWidget {
  const ClientPage({super.key, required this.trainer, required this.client});

  final Trainer trainer;
  final Client client;

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late final _workouts = Backend.instance.watchWorkouts(widget.client.uid);

  String? _exerciseKey;

  Future<void> _remove() async {
    final s = S.of(context);
    final ok = await confirm(
      context,
      title: s('removeClientTitle', {'name': widget.client.name}),
      message: s('removeClientMessage'),
      action: s('removeClient'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await Backend.instance.removeClient(widget.client.uid);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'remove') _remove();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'remove', child: Text(s('removeClient'))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<CoachWorkout>>(
        stream: _workouts,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(errorText(s, snap.error!)));
          }
          final newestFirst = snap.data;
          if (newestFirst == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _body(context, newestFirst);
        },
      ),
    );
  }

  Widget _body(BuildContext context, List<CoachWorkout> newestFirst) {
    final s = S.of(context);
    final now = DateTime.now();
    final summary = summarizeClient(newestFirst, now: now);
    final days = summary.daysSinceLast(now);
    final weeks = weeklyBuckets(newestFirst, now: now, weeks: 12);
    final options = exerciseOptions(newestFirst);
    final key = options.any((o) => o.key == _exerciseKey)
        ? _exerciseKey
        : (options.isEmpty ? null : options.first.key);
    final records = personalRecords(newestFirst);

    return PageBody(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(
              label: s('statLast'),
              value: days == null
                  ? '–'
                  : days == 0
                      ? s('today')
                      : s('daysAgo', {'days': days}),
              warn: summary.inactive(now),
            ),
            StatTile(label: s('statThisWeek'), value: '${summary.thisWeek}'),
            StatTile(
              label: s('statAvg'),
              value: summary.avgPerWeek.toStringAsFixed(1),
            ),
            StatTile(label: s('statTotal'), value: '${summary.total}'),
            if (widget.client.since != null)
              StatTile(
                label: s('statSince'),
                value: fmtDate(widget.client.since!, s.locale),
              ),
          ],
        ),
        if (newestFirst.isEmpty) ...[
          const SizedBox(height: 24),
          Text(s('clientNoWorkouts')),
        ] else ...[
          _TwoUp(children: [
            _ChartCard(
              title: s('chartWorkouts'),
              child: BarChart(
                bars: [
                  for (final w in weeks)
                    BarDatum(
                      fmtShort(w.start, s.locale),
                      w.workouts.toDouble(),
                      tooltip: s('weekOf', {'date': fmtDate(w.start, s.locale)}),
                    ),
                ],
                format: (v) => v.toStringAsFixed(0),
              ),
            ),
            _ChartCard(
              title: s('chartVolume'),
              child: BarChart(
                bars: [
                  for (final w in weeks)
                    BarDatum(
                      fmtShort(w.start, s.locale),
                      w.volumeKg / 1000,
                      tooltip: s('weekOf', {'date': fmtDate(w.start, s.locale)}),
                    ),
                ],
                format: (v) => '${fmtKg(v, s.locale)} t',
              ),
            ),
          ]),
          _TwoUp(children: [
            _ChartCard(
              title: s('chartExercise'),
              action: options.isEmpty
                  ? null
                  : DropdownButton<String>(
                      value: key,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final o in options.take(40))
                          DropdownMenuItem(
                            value: o.key,
                            child: Text(o.nameFor(s.lang),
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setState(() => _exerciseKey = v),
                    ),
              child: key == null
                  ? Text(s('noWeightedExercises'))
                  : LineChart(
                      points: [
                        for (final p in topWeightSeries(newestFirst, key))
                          LinePoint(p.date, p.value),
                      ],
                      format: (v) => '${fmtKg(v, s.locale)} kg',
                      locale: s.locale,
                    ),
            ),
            _ChartCard(
              title: s('chartBodyWeight'),
              child: widget.client.shareWeight
                  ? _WeightChart(clientUid: widget.client.uid)
                  : Text(s('weightNotShared')),
            ),
          ]),
          if (records.isNotEmpty) ...[
            SectionTitle(s('records')),
            Card(
              child: Column(
                children: [
                  for (final r in records.take(12))
                    ListTile(
                      dense: true,
                      title: Text(r.option.nameFor(s.lang)),
                      subtitle: Text(fmtDate(r.date, s.locale)),
                      trailing: Text('${fmtKg(r.kg, s.locale)} kg',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                ],
              ),
            ),
          ],
        ],
        ClientSessions(trainer: widget.trainer, client: widget.client),
        _ClientPlans(trainer: widget.trainer, client: widget.client),
        SectionTitle(s('history')),
        if (newestFirst.isEmpty)
          Text(s('clientNoWorkouts'))
        else
          _History(
            trainer: widget.trainer,
            client: widget.client,
            newestFirst: newestFirst,
          ),
      ],
    );
  }
}

/// Tělesná váha (jen když ji klient sdílí).
class _WeightChart extends StatefulWidget {
  const _WeightChart({required this.clientUid});

  final String clientUid;

  @override
  State<_WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<_WeightChart> {
  late final _weight = Backend.instance.watchWeight(widget.clientUid);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return StreamBuilder<List<CoachWeightPoint>>(
      stream: _weight,
      builder: (context, w) {
        final points = w.data;
        if (points == null) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (points.isEmpty) return Text(s('weightEmpty'));
        return LineChart(
          points: [for (final p in points) LinePoint(p.day, p.kg)],
          format: (v) => '${fmtKg(v, s.locale)} kg',
          locale: s.locale,
        );
      },
    );
  }
}

/// Historie tréninků s komentáři.
class _History extends StatefulWidget {
  const _History({
    required this.trainer,
    required this.client,
    required this.newestFirst,
  });

  final Trainer trainer;
  final Client client;
  final List<CoachWorkout> newestFirst;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  late final _notes = Backend.instance.watchNotes(widget.client.uid);
  int _shown = 20;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final newestFirst = widget.newestFirst;
    return StreamBuilder<List<Note>>(
      stream: _notes,
      builder: (context, n) {
        final byWorkout = <String, List<Note>>{};
        for (final note in n.data ?? const <Note>[]) {
          byWorkout.putIfAbsent(note.workoutId, () => []).add(note);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in newestFirst.take(_shown))
              _WorkoutCard(
                key: ValueKey(w.id),
                trainer: widget.trainer,
                client: widget.client,
                workout: w,
                notes: byWorkout[w.id] ?? const [],
              ),
            if (newestFirst.length > _shown)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: () => setState(() => _shown += 30),
                    child: Text(s('showMore')),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dva bloky vedle sebe na širokém monitoru, pod sebou na úzkém.
class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          );
        },
      );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                  if (action != null) Flexible(child: action!),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plány klienta
// ---------------------------------------------------------------------------

class _ClientPlans extends StatefulWidget {
  const _ClientPlans({required this.trainer, required this.client});

  final Trainer trainer;
  final Client client;

  @override
  State<_ClientPlans> createState() => _ClientPlansState();
}

class _ClientPlansState extends State<_ClientPlans> {
  late final _plans = Backend.instance.watchClientPlans(widget.client.uid);

  Trainer get trainer => widget.trainer;
  Client get client => widget.client;

  Future<void> _send(BuildContext context, CoachPlan plan, {String? planId}) async {
    final s = S.of(context);
    try {
      await Backend.instance.assignPlan(client.uid, plan,
          trainerName: trainer.name, planId: planId);
      if (context.mounted) showSnack(context, s('planSent', {'name': client.name}));
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _newPlan(BuildContext context) async {
    final plan = await openPlanEditor(context);
    if (plan != null && context.mounted) await _send(context, plan);
  }

  Future<void> _fromLibrary(BuildContext context) async {
    final picked = await pickLibraryPlan(context);
    if (picked != null && context.mounted) {
      await _send(context, picked.plan, planId: picked.id);
    }
  }

  Future<void> _edit(BuildContext context, ClientPlan p) async {
    final plan = await openPlanEditor(context, initial: p.assigned.plan);
    if (plan != null && context.mounted) {
      await _send(context, plan, planId: p.id);
    }
  }

  Future<void> _delete(BuildContext context, ClientPlan p) async {
    final s = S.of(context);
    final ok = await confirm(
      context,
      title: s('deletePlanTitle', {'name': p.assigned.plan.name}),
      message: s('deleteClientPlanMessage'),
      action: s('delete'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await Backend.instance.deleteClientPlan(client.uid, p.id);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          s('clientPlans'),
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _fromLibrary(context),
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: Text(s('fromLibrary')),
              ),
              FilledButton.icon(
                onPressed: () => _newPlan(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s('newPlan')),
              ),
            ],
          ),
        ),
        StreamBuilder<List<ClientPlan>>(
          stream: _plans,
          builder: (context, snap) {
            final plans = snap.data;
            if (plans == null) return const LinearProgressIndicator();
            if (plans.isEmpty) {
              return Text(s('clientPlansEmpty'));
            }
            return Card(
              child: Column(
                children: [
                  for (final p in plans)
                    ListTile(
                      title: Text(p.assigned.plan.name),
                      subtitle: Text([
                        s('exercisesCount', {'n': p.assigned.plan.exercises.length}),
                        s('versionN', {'n': p.assigned.version}),
                        if (p.updatedAt != null) fmtDate(p.updatedAt!, s.locale),
                      ].join(' · ')),
                      onTap: () => _edit(context, p),
                      trailing: IconButton(
                        tooltip: s('delete'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, p),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trénink v historii
// ---------------------------------------------------------------------------

String formatSet(CoachSet set, S s) {
  final parts = <String>[];
  if (set.kg != null && set.reps != null) {
    parts.add('${fmtKg(set.kg!, s.locale)} kg × ${set.reps}');
  } else if (set.reps != null) {
    parts.add('${set.reps}×');
  } else if (set.kg != null) {
    parts.add('${fmtKg(set.kg!, s.locale)} kg');
  }
  if (set.seconds != null) parts.add('${set.seconds} s');
  if (parts.isEmpty) parts.add('–');
  var text = parts.join(' · ');
  if (set.warmup) text += ' (${s('warmupTag')})';
  if (set.drop) text += ' (${s('dropTag')})';
  return text;
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    super.key,
    required this.trainer,
    required this.client,
    required this.workout,
    required this.notes,
  });

  final Trainer trainer;
  final Client client;
  final CoachWorkout workout;
  final List<Note> notes;

  Future<void> _comment(BuildContext context) async {
    final s = S.of(context);
    final text = await askText(context,
        title: s('addComment'), maxLength: coachNoteMax);
    if (text == null || text.isEmpty || !context.mounted) return;
    try {
      await Backend.instance.addNote(client.uid,
          workoutId: workout.id, text: text, trainerName: trainer.name);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _deleteNote(BuildContext context, Note n) async {
    final s = S.of(context);
    try {
      await Backend.instance.deleteNote(client.uid, n.id);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final w = workout;
    final info = [
      if (w.durationMin != null) s('minutes', {'n': w.durationMin!}),
      s('exercisesCount', {'n': w.exercises.length}),
      if (w.volumeKg > 0) '${fmtKg(w.volumeKg, s.locale)} kg',
      if (notes.isNotEmpty) s('commentsCount', {'n': notes.length}),
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          '${fmtDateTime(w.startedAt, s.locale)}'
          '${w.title == null ? '' : ' – ${w.title}'}',
        ),
        subtitle: Text(info),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in w.exercises) ...[
            const SizedBox(height: 8),
            Text(e.nameFor(s.lang), style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(e.sets.map((set) => formatSet(set, s)).join(',  '),
                style: theme.textTheme.bodyMedium),
          ],
          const Divider(height: 24),
          for (final n in notes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.comment_outlined),
              title: Text(n.text),
              subtitle: n.createdAt == null
                  ? null
                  : Text(fmtDateTime(n.createdAt!, s.locale)),
              trailing: IconButton(
                tooltip: s('delete'),
                icon: const Icon(Icons.close),
                onPressed: () => _deleteNote(context, n),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _comment(context),
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(s('addComment')),
            ),
          ),
        ],
      ),
    );
  }
}
