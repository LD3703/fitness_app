import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/body_map.dart';
import '../../ui/format.dart';
import '../../ui/swipe_to_delete.dart';
import '../../ui/weekdays.dart';
import '../workout/start_workout.dart';

/// Kalendář tréninků: měsíc s naplánovanými (tečka) a odcvičenými
/// (fajfka) dny. Do libovolného dne jde přidat trénink z plánu –
/// jednorázově, mimo pravidelné dny plánu (ScheduleStatus.added),
/// volitelně s časem. Přejetím doleva se trénink ze dne odebere
/// (pravidelný se ten den vynechá). Podržení dne = rovnou naplánovat.
class PlanCalendarScreen extends ConsumerStatefulWidget {
  const PlanCalendarScreen({super.key});

  @override
  ConsumerState<PlanCalendarScreen> createState() => _PlanCalendarScreenState();
}

class _PlanCalendarScreenState extends ConsumerState<PlanCalendarScreen> {
  late DateTime _month = _firstOfMonth(DateTime.now());
  late DateTime _selected = _today;
  late Stream<List<PlannedWorkout>> _planned = _watch();

  /// Tréninky odebrané přejetím, u kterých ještě jde „Vrátit“.
  final _hidden = <String>{};

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  /// První den mřížky (pondělí) a 6 týdnů.
  DateTime get _gridStart =>
      DateTime(_month.year, _month.month, 1 - dayIndexOf(_month));

  Stream<List<PlannedWorkout>> _watch() =>
      ref.read(databaseProvider).watchPlannedWorkouts(_gridStart, 42);

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _planned = _watch();
    });
  }

  void _goToday() => setState(() {
        _month = _firstOfMonth(DateTime.now());
        _selected = _today;
        _planned = _watch();
      });

  String _key(PlannedWorkout w) =>
      '${w.plan.id}@${w.day.millisecondsSinceEpoch}';

  /// Naplánuje trénink na [day]: výběr plánu (a volitelně času) – klepnutí
  /// na plán ho rovnou přidá.
  Future<void> _addWorkout(DateTime day) async {
    final l10n = AppLocalizations.of(context);
    final plans = ref.read(plansProvider).valueOrNull ??
        await ref.read(databaseProvider).watchPlans().first;
    if (!mounted) return;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.calendarNoPlans)));
      return;
    }
    final picked = await showModalBottomSheet<({WorkoutPlan plan, int? time})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AddSheet(day: day, plans: plans),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(databaseProvider)
        .addPlanToDay(picked.plan.id, day, minutes: picked.time);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _selected = day);
    final locale = Localizations.localeOf(context).toString();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.calendarAdded(
            picked.plan.name, DateFormat.MMMEd(locale).format(day))),
      ));
  }

  /// Odebrání přejetím: přidaný / odložený trénink se smaže, pravidelný se
  /// ten den vynechá. Do zavření snackbaru jde „Vrátit“.
  void _remove(PlannedWorkout w) {
    final db = ref.read(databaseProvider);
    final l10n = AppLocalizations.of(context);
    final key = _key(w);
    setState(() => _hidden.add(key));
    final scheduleId = w.scheduleId;
    showUndoSnackBar(
      context,
      message: scheduleId != null
          ? l10n.calendarRemoved(w.plan.name)
          : l10n.calendarSkipped(w.plan.name),
      onUndo: () {
        if (mounted) setState(() => _hidden.remove(key));
      },
      onCommit: () async {
        if (scheduleId != null) {
          await db.removeScheduled(scheduleId);
        } else {
          await db.skipPlan(w.plan.id, w.day);
        }
        if (mounted) setState(() => _hidden.remove(key));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ??
        const <SessionSummary>[];
    // Plány pro „Naplánovat“ ať jsou načtené předem.
    ref.watch(plansProvider);
    final doneByDay = <DateTime, List<SessionSummary>>{};
    for (final s in sessions) {
      if (s.endedAt == null) continue;
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      doneByDay.putIfAbsent(d, () => []).add(s);
    }
    final today = _today;
    final canAdd = !_selected.isBefore(today);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
        actions: [
          TextButton(onPressed: _goToday, child: Text(l10n.tabToday)),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _addWorkout(_selected),
              icon: const Icon(Icons.add),
              label: Text(l10n.calendarAddWorkout),
            )
          : null,
      body: StreamBuilder<List<PlannedWorkout>>(
        stream: _planned,
        builder: (context, snapshot) {
          final planned = [
            for (final w in snapshot.data ?? const <PlannedWorkout>[])
              if (!_hidden.contains(_key(w))) w,
          ];
          final plannedDays = {
            for (final w in planned)
              if (!w.day.isBefore(today)) w.day,
          };
          final dayPlanned = [
            for (final w in planned)
              if (w.day == _selected && !_selected.isBefore(today)) w,
          ]..sort(
              (a, b) => (a.minutes ?? 24 * 60).compareTo(b.minutes ?? 24 * 60));
          final dayDone = doneByDay[_selected] ?? const <SessionSummary>[];

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              // Měsíc: šipky i přejetí doleva / doprava.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .previousMonthTooltip,
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM(locale).format(_month),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).nextMonthTooltip,
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  _changeMonth(v < 0 ? 1 : -1);
                },
                child: _MonthGrid(
                  start: _gridStart,
                  month: _month,
                  today: today,
                  selected: _selected,
                  plannedDays: plannedDays,
                  doneDays: doneByDay.keys.toSet(),
                  onTap: (d) {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = d);
                  },
                  onLongPress: (d) {
                    if (d.isBefore(today)) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _selected = d);
                    _addWorkout(d);
                  },
                ),
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  DateFormat.MMMMEEEEd(locale).format(_selected),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              for (final s in dayDone)
                ListTile(
                  leading: Icon(Icons.check_circle,
                      color: theme.colorScheme.primary),
                  title: Text(s.planName ?? l10n.workoutFree),
                  subtitle: Text([
                    l10n.historySets(s.setCount),
                    if (s.endedAt case final end?)
                      formatDuration(end.difference(s.startedAt)),
                  ].join(' · ')),
                ),
              for (final w in dayPlanned)
                SwipeToDelete(
                  key: ValueKey(_key(w)),
                  label:
                      w.scheduleId != null ? l10n.delete : l10n.calendarSkipDay,
                  onDeleted: () => _remove(w),
                  child: ListTile(
                    leading: PlanBodyMapThumb(planId: w.plan.id),
                    title: Text(w.plan.name),
                    subtitle: Text([
                      if (w.minutes case final m?)
                        formatMinutesOfDay(context, m),
                      w.scheduleId != null
                          ? l10n.calendarAddedLabel
                          : l10n.calendarRegular,
                    ].join(' · ')),
                    onTap: () => context.go('/plans/${w.plan.id}'),
                    trailing: w.day == today
                        ? IconButton.filledTonal(
                            tooltip: l10n.workoutStart,
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () =>
                                startWorkout(context, ref, planId: w.plan.id),
                          )
                        : null,
                  ),
                ),
              if (dayDone.isEmpty && dayPlanned.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    l10n.calendarDayEmpty,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mřížka měsíce (6 týdnů od pondělí).
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.start,
    required this.month,
    required this.today,
    required this.selected,
    required this.plannedDays,
    required this.doneDays,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime start;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Set<DateTime> plannedDays;
  final Set<DateTime> doneDays;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = shortWeekdayNames(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final n in names)
                Expanded(
                  child: Center(
                    child: Text(n,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var week = 0; week < 6; week++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _DayCell(
                      day: DateTime(
                          start.year, start.month, start.day + week * 7 + d),
                      month: month,
                      today: today,
                      selected: selected,
                      planned: plannedDays.contains(DateTime(
                          start.year, start.month, start.day + week * 7 + d)),
                      done: doneDays.contains(DateTime(
                          start.year, start.month, start.day + week * 7 + d)),
                      onTap: onTap,
                      onLongPress: onLongPress,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.today,
    required this.selected,
    required this.planned,
    required this.done,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime day;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final bool planned;
  final bool done;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = day == selected;
    final isToday = day == today;
    final inMonth = day.month == month.month;
    final color = isSelected
        ? scheme.onPrimary
        : inMonth
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.35);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onTap(day),
      onLongPress: () => onLongPress(day),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : null,
                border: isToday && !isSelected
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: isToday ? FontWeight.w700 : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 8,
              child: done
                  ? Icon(Icons.check, size: 8, color: scheme.tertiary)
                  : planned
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Výběr plánu a času – klepnutí na plán ho přidá.
class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.day, required this.plans});

  final DateTime day;
  final List<WorkoutPlan> plans;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int? _time;

  Future<void> _pickTime() async {
    final current = _time ?? 17 * 60;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (t != null && mounted) {
      // 0:00 v kalendáři znamená „bez času“ – půlnoc se posune o minutu.
      final m = t.hour * 60 + t.minute;
      setState(() => _time = m == 0 ? 1 : m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${l10n.calendarAddWorkout} · '
                '${DateFormat.MMMEd(locale).format(widget.day)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.calendarTime, style: theme.textTheme.titleSmall),
                  ChoiceChip(
                    label: Text(l10n.calendarNoTime),
                    selected: _time == null,
                    onSelected: (_) => setState(() => _time = null),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(_time == null
                        ? l10n.calendarPickTime
                        : formatMinutesOfDay(context, _time!)),
                    selected: _time != null,
                    onSelected: (_) => _pickTime(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final p in widget.plans)
              ListTile(
                leading: PlanBodyMapThumb(planId: p.id),
                title: Text(p.name),
                subtitle: p.weekdaysMask == 0
                    ? null
                    : Text(describeWeekdays(context, p.weekdaysMask)),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.of(context).pop((plan: p, time: _time)),
              ),
          ],
        ),
      ),
    );
  }
}
