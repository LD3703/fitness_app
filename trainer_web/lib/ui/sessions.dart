// Pozvánky na trénink (coachLinks/{klient}/sessions, docs/coach.md):
// sekce na stránce klienta a formulář termínu.
import 'package:flutter/material.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../backend.dart';
import '../strings.dart';
import 'common.dart';
import 'download.dart';

const _durations = [30, 45, 60, 75, 90, 120, 150, 180];

String _when(S s, DateTime d) =>
    '${DateFormat.yMMMEd(s.locale).format(d)} · ${DateFormat.Hm(s.locale).format(d)}';

String _statusText(S s, CoachSessionStatus st) => switch (st) {
      CoachSessionStatus.pending => s('sessionPending'),
      CoachSessionStatus.accepted => s('sessionAccepted'),
      CoachSessionStatus.declined => s('sessionDeclined'),
      CoachSessionStatus.cancelled => s('sessionCancelled'),
    };

/// Sekce „Tréninky s klientem“ na stránce klienta.
class ClientSessions extends StatefulWidget {
  const ClientSessions({super.key, required this.trainer, required this.client});

  final Trainer trainer;
  final Client client;

  @override
  State<ClientSessions> createState() => _ClientSessionsState();
}

class _ClientSessionsState extends State<ClientSessions> {
  late final _sessions = Backend.instance.watchSessions(widget.client.uid);
  late final _plans = Backend.instance.watchClientPlans(widget.client.uid);

  Future<void> _edit(BuildContext context, {CoachSession? initial}) async {
    final s = S.of(context);
    final List<ClientPlan> plans;
    try {
      plans = await _plans.first;
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
      return;
    }
    if (!context.mounted) return;
    final session = await showDialog<CoachSession>(
      context: context,
      builder: (context) => SessionDialog(
        trainerName: widget.trainer.name,
        plans: plans,
        initial: initial,
      ),
    );
    if (session == null) return;
    try {
      await Backend.instance
          .saveSession(widget.client.uid, session, id: initial?.id);
      if (context.mounted) {
        showSnack(context, s('sessionSent', {'name': widget.client.name}));
      }
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _cancel(BuildContext context, CoachSession x) async {
    final s = S.of(context);
    final ok = await confirm(
      context,
      title: s('sessionCancelTitle'),
      message: s('sessionCancelMessage', {'name': widget.client.name}),
      action: s('sessionCancel'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await Backend.instance.cancelSession(widget.client.uid, x.id);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _delete(BuildContext context, CoachSession x) async {
    try {
      await Backend.instance.deleteSession(widget.client.uid, x.id);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(S.of(context), e));
    }
  }

  void _ics(BuildContext context, CoachSession x) {
    final s = S.of(context);
    downloadText(
      'gymbar-trenink.ics',
      coachSessionIcs(
        x,
        title: s('sessionIcsTitle', {'title': x.title, 'name': widget.client.name}),
        description: x.note,
        now: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          s('sessions'),
          trailing: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(s('sessionInvite')),
          ),
        ),
        StreamBuilder<List<CoachSession>>(
          stream: _sessions,
          builder: (context, snap) {
            if (snap.hasError) return const LoadErrorText();
            final all = snap.data;
            if (all == null) return const LinearProgressIndicator();
            // Proběhlé jen posledních pár, ať seznam neroste donekonečna.
            final active = [for (final x in all) if (x.isActive(now)) x];
            final past = [for (final x in all) if (!x.isActive(now)) x].take(5);
            if (active.isEmpty && past.isEmpty) return Text(s('sessionsEmpty'));
            return Card(
              child: Column(
                children: [
                  for (final x in [...active.reversed, ...past])
                    _tile(context, s, theme, x, now),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    S s,
    ThemeData theme,
    CoachSession x,
    DateTime now,
  ) {
    final active = x.isActive(now);
    final next = x.nextOccurrence(now) ?? x.occurrences.last;
    final last = x.occurrences.last;
    final color = switch (x.status) {
      CoachSessionStatus.accepted => theme.colorScheme.primary,
      CoachSessionStatus.declined ||
      CoachSessionStatus.cancelled =>
        theme.colorScheme.error,
      CoachSessionStatus.pending => theme.colorScheme.onSurfaceVariant,
    };
    return ListTile(
      enabled: active,
      leading: Icon(x.repeats ? Icons.event_repeat : Icons.event, color: color),
      title: Text('${x.title} · ${_when(s, next)}'),
      subtitle: Text([
        if (!active)
          s('sessionPast')
        else
          _statusText(s, x.status),
        '${x.durationMin} min',
        if (x.repeats)
          s('sessionWeeklyUntil', {'date': fmtDate(last, s.locale)}),
        if (x.note != null) x.note!,
      ].join(' · ')),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => switch (v) {
          'edit' => _edit(context, initial: x),
          'ics' => _ics(context, x),
          'cancel' => _cancel(context, x),
          _ => _delete(context, x),
        },
        itemBuilder: (context) => [
          if (active) ...[
            PopupMenuItem(value: 'edit', child: Text(s('sessionEdit'))),
            PopupMenuItem(value: 'ics', child: Text(s('sessionIcs'))),
            if (x.status != CoachSessionStatus.cancelled)
              PopupMenuItem(value: 'cancel', child: Text(s('sessionCancel'))),
          ],
          PopupMenuItem(value: 'delete', child: Text(s('delete'))),
        ],
      ),
    );
  }
}

/// Formulář termínu: datum, čas, délka, opakování, název, plán, poznámka.
class SessionDialog extends StatefulWidget {
  const SessionDialog({
    super.key,
    required this.trainerName,
    required this.plans,
    this.initial,
  });

  final String trainerName;
  final List<ClientPlan> plans;
  final CoachSession? initial;

  @override
  State<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<SessionDialog> {
  late DateTime _start;
  late int _duration;
  late int _weeks;
  String? _planId;
  late final TextEditingController _title;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _start = i?.startAt ?? DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17);
    _duration = i?.durationMin ?? 60;
    _weeks = i?.weeks ?? 1;
    _planId = widget.plans.any((p) => p.id == i?.planId) ? i!.planId : null;
    _title = TextEditingController(text: i?.title ?? '');
    _note = TextEditingController(text: i?.note ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start.isBefore(now) ? now : _start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
    );
    if (t != null) {
      setState(() => _start = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
    }
  }

  void _submit() {
    final s = S.of(context);
    final plan = widget.plans.where((p) => p.id == _planId).firstOrNull;
    final title = _title.text.trim().isNotEmpty
        ? _title.text.trim()
        : plan?.assigned.plan.name ?? s('sessionTitleDefault');
    Navigator.of(context).pop(CoachSession(
      id: widget.initial?.id ?? '',
      startAt: _start,
      durationMin: _duration,
      weeks: _weeks,
      title: title,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      planId: _planId,
      trainerName: widget.trainerName,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final past = _start.isBefore(DateTime.now());
    return AlertDialog(
      title: Text(widget.initial == null ? s('sessionInvite') : s('sessionEdit')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat.yMMMEd(s.locale).format(_start)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(DateFormat.Hm(s.locale).format(_start)),
                  ),
                ],
              ),
              if (past)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(s('sessionInPast'),
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _durations.contains(_duration) ? _duration : 60,
                decoration: InputDecoration(labelText: s('sessionDuration')),
                items: [
                  for (final m in _durations)
                    DropdownMenuItem(value: m, child: Text('$m min')),
                ],
                onChanged: (v) => setState(() => _duration = v ?? 60),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _weeks,
                decoration: InputDecoration(labelText: s('sessionRepeat')),
                items: [
                  DropdownMenuItem(value: 1, child: Text(s('sessionOnce'))),
                  for (var w = 2; w <= coachSessionMaxWeeks; w++)
                    DropdownMenuItem(value: w, child: Text(s('sessionWeeks', {'n': w}))),
                ],
                onChanged: (v) => setState(() => _weeks = v ?? 1),
              ),
              const SizedBox(height: 12),
              if (widget.plans.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: _planId,
                  decoration: InputDecoration(labelText: s('sessionPlan')),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(s('sessionNoPlan'))),
                    for (final p in widget.plans)
                      DropdownMenuItem<String?>(
                          value: p.id, child: Text(p.assigned.plan.name)),
                  ],
                  onChanged: (v) => setState(() => _planId = v),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _title,
                maxLength: coachSessionTitleMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s('sessionTitle'),
                  hintText: s('sessionTitleHint'),
                ),
              ),
              TextField(
                controller: _note,
                maxLength: coachSessionNoteMax,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: s('sessionNote')),
              ),
              if (widget.initial != null)
                Text(s('sessionEditHint'),
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
        FilledButton(
          onPressed: past ? null : _submit,
          child: Text(s('sessionSend')),
        ),
      ],
    );
  }
}
