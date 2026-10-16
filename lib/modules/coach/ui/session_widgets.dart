// Pozvánky na trénink v aplikaci (docs/coach.md): klient přijímá / odmítá
// (obrazovka Trenér a karta na obrazovce Dnes), trenér zve, upravuje
// a ruší (detail klienta). Stejný formulář je i na webu pro trenéry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/app_localizations.dart';
import '../../../services/calendar_service.dart';
import '../../../ui/dialogs.dart';
import '../../social/ui/social_ui.dart' show showSocialSnack;
import '../coach_service.dart';

const _durations = [30, 45, 60, 75, 90, 120, 150, 180];

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

String sessionWhen(BuildContext context, DateTime d) {
  final locale = _locale(context);
  return '${DateFormat.MMMEd(locale).format(d)} · ${DateFormat.Hm(locale).format(d)}';
}

String sessionStatusText(AppLocalizations l10n, CoachSessionStatus s) =>
    switch (s) {
      CoachSessionStatus.pending => l10n.coachSessionPending,
      CoachSessionStatus.accepted => l10n.coachSessionAccepted,
      CoachSessionStatus.declined => l10n.coachSessionDeclined,
      CoachSessionStatus.cancelled => l10n.coachSessionCancelled,
    };

/// „čt 20. 10. · 18:00 · 60 min · každý týden do 1. 12.“
String sessionDetails(BuildContext context, CoachSession s, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final next = s.nextOccurrence(now) ?? s.occurrences.last;
  return [
    sessionWhen(context, next),
    '${s.durationMin} min',
    if (s.repeats)
      l10n.coachSessionWeeklyUntil(
          DateFormat.MMMd(_locale(context)).format(s.occurrences.last)),
  ].join(' · ');
}

// ---------------------------------------------------------------------------
// Klient
// ---------------------------------------------------------------------------

/// Přijme / odmítne pozvánku. Před přijetím požádá o přístup ke kalendáři
/// (termíny zapíše coachAppProvider).
Future<void> respondToSession(
  BuildContext context,
  CoachSession s, {
  required bool accept,
}) async {
  final l10n = AppLocalizations.of(context);
  var calendar = false;
  if (accept && CalendarService.instance.supported) {
    calendar = await CalendarService.instance.hasPermission() ||
        await CalendarService.instance.requestPermission();
  }
  try {
    await CoachService.instance.respondSession(s.id, accept: accept);
    if (accept && context.mounted) {
      showSocialSnack(
        context,
        calendar
            ? l10n.coachSessionAcceptedCalendar
            : l10n.coachSessionAcceptedNoCalendar,
      );
    }
  } catch (e) {
    debugPrint('Coach: respond session failed: $e');
    if (context.mounted) showSocialSnack(context, l10n.socialOffline);
  }
}

/// Pozvánka u klienta: název, termín, poznámka, stav a tlačítka.
class ClientSessionTile extends StatelessWidget {
  const ClientSessionTile({super.key, required this.session});

  final CoachSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = session;
    final now = DateTime.now();
    final pending = s.status == CoachSessionStatus.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(s.repeats ? Icons.event_repeat : Icons.event),
          title: Text(s.title),
          subtitle: Text([
            sessionDetails(context, s, now),
            if (!pending) sessionStatusText(l10n, s.status),
            if (s.note != null) s.note!,
          ].join('\n')),
          isThreeLine: s.note != null || !pending,
        ),
        if (s.status != CoachSessionStatus.cancelled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (s.status != CoachSessionStatus.declined)
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error),
                    onPressed: () => respondToSession(context, s, accept: false),
                    child: Text(l10n.coachSessionDecline),
                  ),
                if (s.status != CoachSessionStatus.accepted)
                  FilledButton(
                    onPressed: () => respondToSession(context, s, accept: true),
                    child: Text(l10n.coachSessionAccept),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Sekce „Tréninky s trenérem“ na obrazovce Trenér (jsem klient).
class ClientSessionsSection extends ConsumerWidget {
  const ClientSessionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final sessions = [
      for (final s in ref.watch(mySessionsProvider).valueOrNull ?? const <CoachSession>[])
        if (s.isActive(now)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(l10n.coachSessions,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l10n.coachSessionsNone),
          ),
        for (final s in sessions) ClientSessionTile(session: s),
      ],
    );
  }
}

/// [coach:today] – nevyřízené pozvánky od trenéra na obrazovce Dnes.
class CoachSessionsTodayCard extends ConsumerWidget {
  const CoachSessionsTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final pending = [
      for (final s in ref.watch(mySessionsProvider).valueOrNull ?? const <CoachSession>[])
        if (s.status == CoachSessionStatus.pending && s.isActive(now)) s,
    ];
    if (pending.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.sports, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.coachSessionInviteFrom(pending.first.trainerName),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            for (final s in pending) ClientSessionTile(session: s),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trenér
// ---------------------------------------------------------------------------

/// Sekce „Tréninky s klientem“ v detailu klienta (jsem trenér).
class TrainerSessionsSection extends ConsumerWidget {
  const TrainerSessionsSection({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  final String clientUid;
  final String clientName;

  Future<void> _cancel(BuildContext context, CoachSession s) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.coachSessionCancelTitle,
      message: l10n.coachSessionCancelMessage(clientName),
      confirmLabel: l10n.coachSessionCancel,
      destructive: true,
    );
    if (!ok) return;
    try {
      await CoachService.instance.cancelSession(clientUid, s.id);
    } catch (e) {
      debugPrint('Coach: cancel session failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final sessions = [
      for (final s in ref.watch(clientSessionsProvider(clientUid)).valueOrNull ??
          const <CoachSession>[])
        if (s.isActive(now)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.coachSessionsWithClient,
                    style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: () => editTrainerSession(context, ref, clientUid),
                icon: const Icon(Icons.event_outlined),
                label: Text(l10n.coachSessionInvite),
              ),
            ],
          ),
        ),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(l10n.coachSessionsNone),
          ),
        for (final s in sessions)
          ListTile(
            leading: Icon(s.repeats ? Icons.event_repeat : Icons.event),
            title: Text(s.title),
            subtitle: Text(
                '${sessionDetails(context, s, now)}\n${sessionStatusText(l10n, s.status)}'),
            isThreeLine: true,
            trailing: s.status == CoachSessionStatus.cancelled
                ? null
                : PopupMenuButton<bool>(
                    onSelected: (edit) => edit
                        ? editTrainerSession(context, ref, clientUid, initial: s)
                        : _cancel(context, s),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: true, child: Text(l10n.coachSessionEdit)),
                      PopupMenuItem(
                          value: false, child: Text(l10n.coachSessionCancel)),
                    ],
                  ),
          ),
      ],
    );
  }
}

/// Nová pozvánka / úprava [initial] pro klienta [clientUid].
Future<void> editTrainerSession(
  BuildContext context,
  WidgetRef ref,
  String clientUid, {
  CoachSession? initial,
}) async {
  final l10n = AppLocalizations.of(context);
  final trainer = ref.read(myTrainerProvider).valueOrNull;
  if (trainer == null) return;
  List<AssignedPlan> plans;
  try {
    plans = await CoachService.instance.clientPlans(clientUid);
  } catch (_) {
    plans = const [];
  }
  if (!context.mounted) return;
  final session = await showDialog<CoachSession>(
    context: context,
    builder: (context) => SessionEditorDialog(
      trainerName: trainer.name,
      plans: plans,
      initial: initial,
    ),
  );
  if (session == null) return;
  // Trenér s aplikací má termíny po přijetí i ve svém kalendáři.
  if (CalendarService.instance.supported &&
      !await CalendarService.instance.hasPermission()) {
    await CalendarService.instance.requestPermission();
  }
  try {
    await CoachService.instance.saveSession(clientUid, session, id: initial?.id);
    if (context.mounted) showSocialSnack(context, l10n.coachSessionSent);
  } catch (e) {
    debugPrint('Coach: save session failed: $e');
    if (context.mounted) showSocialSnack(context, l10n.socialOffline);
  }
}

/// Formulář termínu: datum, čas, délka, opakování, plán, název, poznámka.
class SessionEditorDialog extends StatefulWidget {
  const SessionEditorDialog({
    super.key,
    required this.trainerName,
    required this.plans,
    this.initial,
  });

  final String trainerName;
  final List<AssignedPlan> plans;
  final CoachSession? initial;

  @override
  State<SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<SessionEditorDialog> {
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
    _start = i?.startAt ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17);
    _duration = _durations.contains(i?.durationMin) ? i!.durationMin : 60;
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
      setState(() =>
          _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
    );
    if (t != null) {
      setState(() => _start =
          DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final plan = widget.plans.where((p) => p.id == _planId).firstOrNull;
    final title = _title.text.trim().isNotEmpty
        ? _title.text.trim()
        : plan?.plan.name ?? l10n.coachSessionTitleDefault;
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
    final l10n = AppLocalizations.of(context);
    final locale = _locale(context);
    final past = _start.isBefore(DateTime.now());
    return AlertDialog(
      title: Text(widget.initial == null
          ? l10n.coachSessionInvite
          : l10n.coachSessionEdit),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(DateFormat.MMMEd(locale).format(_start)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(DateFormat.Hm(locale).format(_start)),
              ),
            ],
          ),
          if (past)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.coachSessionInPast,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _duration,
            decoration: InputDecoration(labelText: l10n.coachSessionDuration),
            items: [
              for (final m in _durations)
                DropdownMenuItem(value: m, child: Text('$m min')),
            ],
            onChanged: (v) => setState(() => _duration = v ?? 60),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _weeks,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.coachSessionRepeat),
            items: [
              DropdownMenuItem(value: 1, child: Text(l10n.coachSessionOnce)),
              for (var w = 2; w <= coachSessionMaxWeeks; w++)
                DropdownMenuItem(value: w, child: Text(l10n.coachSessionWeeks(w))),
            ],
            onChanged: (v) => setState(() => _weeks = v ?? 1),
          ),
          const SizedBox(height: 12),
          if (widget.plans.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: _planId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.coachSessionPlan),
              items: [
                DropdownMenuItem<String?>(
                    value: null, child: Text(l10n.coachSessionNoPlan)),
                for (final p in widget.plans)
                  DropdownMenuItem<String?>(value: p.id, child: Text(p.plan.name)),
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
              labelText: l10n.coachSessionTitle,
              hintText: l10n.coachSessionTitleHint,
            ),
          ),
          TextField(
            controller: _note,
            maxLength: coachSessionNoteMax,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.coachSessionNote),
          ),
          if (widget.initial != null)
            Text(l10n.coachSessionEditHint,
                style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: past ? null : _submit,
          child: Text(l10n.coachSessionSend),
        ),
      ],
    );
  }
}
