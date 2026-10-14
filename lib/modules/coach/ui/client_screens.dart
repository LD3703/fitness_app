import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../social/ui/gym_screen.dart' show gymGate;
import '../../social/ui/social_ui.dart' show showSocialSnack;
import '../coach_queries.dart';
import '../coach_service.dart';
import 'coach_widgets.dart';

/// /coach/clients – klienti trenéra.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: l10n.coachMyClients,
      builder: () {
        final clients = ref.watch(myClientsProvider);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.coachMyClients)),
          body: clients.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.socialOffline)),
            data: (list) => list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.coachClientsNone,
                          textAlign: TextAlign.center),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _ClientTile(link: list[i]),
                  ),
          ),
        );
      },
    );
  }
}

/// „dnes“ / „před 3 dny“ / „zatím žádný trénink“.
String lastWorkoutText(AppLocalizations l10n, ClientSummary s, DateTime now) {
  final days = s.daysSinceLast(now);
  if (days == null) return l10n.coachNeverTrained;
  return l10n.coachLastWorkout(l10n.coachDaysAgo(days));
}

class _ClientTile extends ConsumerWidget {
  const _ClientTile({required this.link});

  final CoachLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final workouts =
        ref.watch(clientWorkoutsProvider(link.clientUid)).valueOrNull;
    final now = DateTime.now();
    final summary =
        workouts == null ? null : summarizeClient(workouts, now: now);
    final inactive = summary?.inactive(now) ?? false;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: inactive ? theme.colorScheme.errorContainer : null,
        child: Text(link.clientName.isEmpty
            ? '?'
            : link.clientName.substring(0, 1).toUpperCase()),
      ),
      title: Text(link.clientName),
      subtitle: summary == null
          ? null
          : Text([
              lastWorkoutText(l10n, summary, now),
              l10n.coachThisWeek(summary.thisWeek),
            ].join(' · ')),
      trailing: inactive
          ? Chip(label: Text(l10n.coachInactiveBadge))
          : const Icon(Icons.chevron_right),
      onTap: () => context.push(
        '/coach/client?uid=${Uri.encodeQueryComponent(link.clientUid)}'
        '&name=${Uri.encodeQueryComponent(link.clientName)}',
      ),
    );
  }
}

/// /coach/client?uid=…&name=… – detail klienta.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  final String clientUid;
  final String clientName;

  Future<void> _sendPlan(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final trainer = ref.read(myTrainerProvider).valueOrNull;
    if (trainer == null) return;
    final plans = (await db.watchPlans().first)
        .where((p) => !p.isBuiltIn && p.remoteId == null)
        .toList();
    if (!context.mounted) return;
    if (plans.isEmpty) {
      showSocialSnack(context, l10n.coachNoPlansToSend);
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.coachSendPlanPick),
        children: [
          for (final p in plans)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(p.id),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (picked == null) return;
    try {
      final plan = await db.coachPlanFromLocal(picked);
      if (plan == null) return;
      // Stejný plán posílaný znovu = nová verze (ID podle plánu v telefonu
      // trenéra; plány z webu mají ID z knihovny plánů).
      await CoachService.instance.assignPlan(
        clientUid,
        plan,
        trainerName: trainer.name,
        planId: 'app$picked',
      );
      if (context.mounted) showSocialSnack(context, l10n.coachSendPlanDone);
    } catch (e) {
      debugPrint('Coach: send plan failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _remove(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.coachRemoveClientTitle(clientName),
      message: l10n.coachRemoveClientMessage,
      confirmLabel: l10n.coachRemoveClient,
      destructive: true,
    );
    if (!ok) return;
    try {
      await CoachService.instance.removeClient(clientUid);
      if (context.mounted) context.pop();
    } catch (e) {
      debugPrint('Coach: remove client failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: clientName,
      builder: () {
        final workouts = ref.watch(clientWorkoutsProvider(clientUid));
        return Scaffold(
          appBar: AppBar(
            title: Text(clientName),
            actions: [
              PopupMenuButton<int>(
                onSelected: (_) => _remove(context),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 0, child: Text(l10n.coachRemoveClient)),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _sendPlan(context, ref),
            icon: const Icon(Icons.send_outlined),
            label: Text(l10n.coachSendPlan),
          ),
          body: workouts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.socialOffline)),
            data: (list) => _ClientBody(
              clientUid: clientUid,
              workouts: list,
            ),
          ),
        );
      },
    );
  }
}

class _ClientBody extends ConsumerWidget {
  const _ClientBody({required this.clientUid, required this.workouts});

  final String clientUid;
  final List<CoachWorkout> workouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final lang = l10n.localeName.split(RegExp('[_-]')).first;
    final summary = summarizeClient(workouts, now: now);
    final weeks = weeklyBuckets(workouts, now: now, weeks: 12);
    final records = personalRecords(workouts).take(8).toList();
    final dateFmt = DateFormat.MMMEd(Localizations.localeOf(context).toString());
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(
          title: Text(lastWorkoutText(l10n, summary, now)),
          subtitle: Text(l10n.coachThisWeek(summary.thisWeek)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(l10n.coachWorkoutsPerWeek, style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeeklyBarsChart(weeks: weeks),
        ),
        if (records.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l10n.coachRecords, style: theme.textTheme.titleSmall),
          ),
          for (final r in records)
            ListTile(
              dense: true,
              title: Text(r.option.nameFor(lang)),
              trailing: Text(formatWeightWithUnit(context, r.kg, rounded: true),
                  style: theme.textTheme.titleSmall),
              subtitle: Text(dateFmt.format(r.date)),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.coachRecentWorkouts, style: theme.textTheme.titleSmall),
        ),
        for (final w in workouts.take(30))
          ExpansionTile(
            title: Text(w.title ?? dateFmt.format(w.startedAt)),
            subtitle: Text([
              dateFmt.format(w.startedAt),
              if (w.durationMin != null) '${w.durationMin} min',
              l10n.coachSetsCount(w.workingSets),
            ].join(' · ')),
            children: [
              for (final e in w.exercises)
                ListTile(
                  dense: true,
                  title: Text(e.nameFor(lang)),
                  subtitle: Text(e.sets
                      .where((s) => !s.warmup)
                      .map((s) => _setText(context, s))
                      .join(', ')),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _note(context, ref, w),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.coachAddNote),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _setText(BuildContext context, CoachSet s) {
    if (s.seconds != null) return '${s.seconds} s';
    final reps = s.reps ?? 0;
    final kg = s.kg;
    return kg == null || kg == 0
        ? '$reps×'
        : '${formatWeightWithUnit(context, kg)} × $reps';
  }

  Future<void> _note(BuildContext context, WidgetRef ref, CoachWorkout w) async {
    final l10n = AppLocalizations.of(context);
    final trainer = ref.read(myTrainerProvider).valueOrNull;
    if (trainer == null) return;
    final text = await showMultilineInputDialog(context, title: l10n.coachAddNote);
    if (text == null || text.trim().isEmpty) return;
    try {
      await CoachService.instance.addNote(
        clientUid,
        workoutId: w.id,
        text: text,
        trainerName: trainer.name,
      );
      if (context.mounted) showSocialSnack(context, l10n.coachNoteSent);
    } catch (e) {
      debugPrint('Coach: note failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }
}
