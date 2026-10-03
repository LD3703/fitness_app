import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../services/calendar_service.dart';
import '../../../ui/labels.dart';
import '../social_logic.dart';
import '../social_models.dart';
import '../social_publisher.dart';
import '../social_queries.dart';
import '../social_service.dart';
import 'social_ui.dart';

/// /friends/invite?uid=…&name=… – pozvánka na společný trénink.
class InviteWorkoutScreen extends ConsumerStatefulWidget {
  const InviteWorkoutScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  final String friendUid;
  final String friendName;

  @override
  ConsumerState<InviteWorkoutScreen> createState() =>
      _InviteWorkoutScreenState();
}

class _InviteWorkoutScreenState extends ConsumerState<InviteWorkoutScreen> {
  int? _planId;
  late DateTime _day;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  int _duration = 60;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day + 1);
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);

  Future<void> _send(WorkoutPlan plan) async {
    final l10n = AppLocalizations.of(context);
    if (!_start.isAfter(DateTime.now())) {
      showSocialSnack(context, l10n.socialInviteInPast);
      return;
    }
    setState(() => _busy = true);
    try {
      final profile = await ref.read(databaseProvider).watchProfile().first;
      await SocialService.instance.sendInvitation(
        toUid: widget.friendUid,
        myName: SocialPublisher.displayName(profile),
        planName: plan.name,
        startAt: _start,
        durationMinutes: _duration,
      );
      // Povolení kalendáře teď, ať se trénink po přijetí zapíše sám.
      await CalendarService.instance.requestPermission();
      if (!mounted) return;
      showSocialSnack(context, l10n.socialInviteSent(widget.friendName));
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Social: invite failed: $e');
      if (mounted) {
        showSocialSnack(context, l10n.socialOffline);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plans = ref.watch(plansProvider).valueOrNull ?? const [];
    WorkoutPlan? plan;
    for (final p in plans) {
      if (p.id == _planId) plan = p;
    }
    if (plan == null && plans.isNotEmpty) {
      plan = plans.first;
    }
    final selected = plan;
    final locale = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialInviteTitle(widget.friendName))),
      body: plans.isEmpty
          ? SocialMessage(
              icon: Icons.list_alt_outlined,
              title: l10n.socialInviteNoPlans,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.socialInvitePlan),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selected?.id,
                      isDense: true,
                      isExpanded: true,
                      items: [
                        for (final p in plans)
                          DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ],
                      onChanged: (id) {
                        final p = plans.where((x) => x.id == id).firstOrNull;
                        setState(() {
                          _planId = id;
                          final t = p?.plannedTimeMinutes;
                          if (t != null) {
                            _time = TimeOfDay(hour: t ~/ 60, minute: t % 60);
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.socialInviteDay),
                  subtitle: Text(locale.formatFullDate(_day)),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 90)),
                    );
                    if (d != null) setState(() => _day = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(l10n.socialInviteTime),
                  subtitle: Text(locale.formatTimeOfDay(
                    _time,
                    alwaysUse24HourFormat:
                        MediaQuery.alwaysUse24HourFormatOf(context),
                  )),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (t != null) setState(() => _time = t);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timelapse_outlined),
                  title: Text(l10n.socialInviteDuration),
                  trailing: DropdownButton<int>(
                    value: _duration,
                    items: [
                      for (final m in const [30, 45, 60, 75, 90, 120])
                        DropdownMenuItem(
                          value: m,
                          child: Text(l10n.socialMinutes(m)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 60),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.socialInviteHint,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy || selected == null
                      ? null
                      : () => _send(selected),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(l10n.socialSend),
                ),
              ],
            ),
    );
  }
}

/// /friends/challenge?uid=…&name=… – vyzvat přítele.
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  final String friendUid;
  final String friendName;

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  ChallengeKind _kind = ChallengeKind.beatRecord;
  int? _exerciseId;
  int _workouts = 12;
  late DateTime _recordDeadline;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _recordDeadline = DateTime(now.year, now.month, now.day + 30, 23, 59);
  }

  DateTime get _weekEnd {
    final start = isoWeekStart(DateTime.now());
    return DateTime(start.year, start.month, start.day + 7)
        .subtract(const Duration(seconds: 1));
  }

  Future<void> _send({Exercise? exercise, double? record}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final profile = await db.watchProfile().first;
      final myName = SocialPublisher.displayName(profile);
      final now = DateTime.now();
      switch (_kind) {
        case ChallengeKind.beatRecord:
          // Přítel má překonat můj rekord; já sám lokální výzvu nemám.
          await SocialService.instance.createChallenge(
            friendUid: widget.friendUid,
            myName: myName,
            kind: RemoteChallengeKind.beatRecord,
            target: roundRecord(record!),
            deadline: _recordDeadline,
            creatorAccepted: false,
            notify: 'invite',
            exerciseSlug: exercise!.slug,
            exerciseNameEn: exercise.nameEn,
            exerciseNameCs: exercise.nameCs,
          );
        case ChallengeKind.workoutsInMonth:
          final deadline = endOfMonth(now);
          final id = await SocialService.instance.createChallenge(
            friendUid: widget.friendUid,
            myName: myName,
            kind: RemoteChallengeKind.workoutsInMonth,
            target: _workouts.toDouble(),
            deadline: deadline,
            creatorAccepted: true,
            notify: 'invite',
          );
          await db.socialInsertChallenge(
            remoteId: id,
            kind: ChallengeKind.workoutsInMonth,
            targetValue: _workouts.toDouble(),
            fromName: widget.friendName,
            deadline: deadline,
          );
        case ChallengeKind.weeklyWater:
          // Na server jde cíl 100 % – množství vody telefon neopustí.
          final id = await SocialService.instance.createChallenge(
            friendUid: widget.friendUid,
            myName: myName,
            kind: RemoteChallengeKind.weeklyWater,
            target: 100,
            deadline: _weekEnd,
            creatorAccepted: true,
            notify: 'invite',
          );
          await db.socialInsertChallenge(
            remoteId: id,
            kind: ChallengeKind.weeklyWater,
            targetValue: (profile.waterGoalMl * 7).toDouble(),
            fromName: widget.friendName,
            deadline: _weekEnd,
          );
      }
      if (!mounted) return;
      showSocialSnack(context, l10n.socialChallengeSent(widget.friendName));
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Social: challenge failed: $e');
      if (mounted) {
        showSocialSnack(context, l10n.socialOffline);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final exercises = [
      for (final e in ref.watch(exercisesWithHistoryProvider).valueOrNull ??
          const <Exercise>[])
        if (e.slug != null) e,
    ];
    Exercise? exercise;
    for (final e in exercises) {
      if (e.id == _exerciseId) exercise = e;
    }
    exercise ??= exercises.firstOrNull;
    final record = exercise == null
        ? null
        : ref.watch(exerciseStatsProvider(exercise.id)).valueOrNull?.record;
    final locale = MaterialLocalizations.of(context);

    final canSend = !_busy &&
        switch (_kind) {
          ChallengeKind.beatRecord => exercise != null && record != null,
          ChallengeKind.workoutsInMonth => true,
          ChallengeKind.weeklyWater => profile?.trackWater ?? false,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialChallengeTitle(widget.friendName))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Výběr druhu (bez RadioGroup/groupValue – stabilní napříč verzemi).
          for (final (kind, title, hint) in [
            (
              ChallengeKind.beatRecord,
              l10n.socialKindRecord,
              l10n.socialKindRecordHint,
            ),
            (
              ChallengeKind.workoutsInMonth,
              l10n.socialKindWorkouts,
              l10n.socialKindWorkoutsHint,
            ),
            (
              ChallengeKind.weeklyWater,
              l10n.socialKindWater,
              l10n.socialKindWaterHint,
            ),
          ])
            ListTile(
              leading: Icon(
                _kind == kind
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _kind == kind ? theme.colorScheme.primary : null,
              ),
              title: Text(title),
              subtitle: Text(hint),
              selected: _kind == kind,
              onTap: () => setState(() => _kind = kind),
            ),
          const Divider(),
          ...switch (_kind) {
            ChallengeKind.beatRecord => <Widget>[
                if (exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(l10n.socialNoRecords),
                  )
                else ...[
                  InputDecorator(
                    decoration:
                        InputDecoration(labelText: l10n.socialChallengeExercise),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: exercise?.id,
                        isDense: true,
                        isExpanded: true,
                        items: [
                          for (final e in exercises)
                            DropdownMenuItem(
                              value: e.id,
                              child: Text(e.localizedName(context)),
                            ),
                        ],
                        onChanged: (id) => setState(() => _exerciseId = id),
                      ),
                    ),
                  ),
                  if (record != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.socialChallengeYourRecord(
                          socialKg(context, roundRecord(record.oneRepMax)))),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(l10n.socialChallengeDeadline),
                    subtitle: Text(locale.formatFullDate(_recordDeadline)),
                    onTap: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _recordDeadline,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 180)),
                      );
                      if (d != null) {
                        setState(() => _recordDeadline =
                            DateTime(d.year, d.month, d.day, 23, 59));
                      }
                    },
                  ),
                ],
              ],
            ChallengeKind.workoutsInMonth => <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.socialChallengeWorkouts(_workouts)),
                  subtitle: Text(l10n.socialChallengeUntil(
                      locale.formatFullDate(endOfMonth(DateTime.now())))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _workouts > 1
                            ? () => setState(() => _workouts--)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _workouts < 31
                            ? () => setState(() => _workouts++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ChallengeKind.weeklyWater => <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    profile?.trackWater ?? false
                        ? l10n.socialChallengeUntil(
                            locale.formatFullDate(_weekEnd))
                        : l10n.socialWaterOff,
                  ),
                ),
              ],
          },
          const SizedBox(height: 8),
          Text(l10n.socialChallengePrivacy, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canSend
                ? () => _send(exercise: exercise, record: record?.oneRepMax)
                : null,
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.socialSend),
          ),
        ],
      ),
    );
  }
}
