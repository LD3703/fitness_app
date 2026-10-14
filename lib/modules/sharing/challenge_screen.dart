import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/labels.dart';
import '../../ui/set_format.dart';
import 'challenge_link.dart';
import 'challenge_progress.dart';
import 'challenge_service.dart';
import 'sharing_queries.dart';

/// Cesta obrazovky s výzvou z odkazu.
const kChallengeRoute = '/challenge';

GoRoute challengeRoute() => GoRoute(
      path: kChallengeRoute,
      builder: (context, state) => ChallengeScreen(
        link: _linkFromUri(state.uri),
      ),
    );

/// Parametry výzvy z adresy. Neplatné kódování (např. „%FF“) vyhodí
/// výjimku až při čtení parametrů – pak je to neplatný odkaz (obrazovka
/// to oznámí), ne chybová stránka navigace. Builder routy nesmí spadnout
/// na žádné chybě dekódování (FormatException i ArgumentError).
ChallengeLink? _linkFromUri(Uri uri) {
  try {
    return ChallengeLink.fromQuery(uri.queryParameters);
  } catch (_) {
    return null;
  }
}

/// Co jsme o výzvě zjistili z databáze.
typedef _Resolved = ({
  Exercise? exercise,
  ExerciseRecord? record,
  bool duplicate,
});

/// Obrazovka „Kamarád tě vyzývá“: přijmout / odmítnout.
class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, required this.link});

  /// null = neplatný odkaz.
  final ChallengeLink? link;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  Future<_Resolved>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final link = widget.link;
    if (link != null) _future = _resolve(link);
  }

  Future<_Resolved> _resolve(ChallengeLink link) async {
    final db = ref.read(databaseProvider);
    Exercise? exercise;
    final slug = link.exerciseSlug;
    final id = link.exerciseId;
    final name = link.exerciseName;
    if (slug != null) {
      exercise = await db.exerciseBySlug(slug);
    } else if (id != null) {
      // ID cizího vlastního cviku u nás znamená něco jiného – když odkaz
      // nese název, hledáme podle něj; ID jen jako záloha bez názvu.
      if (name != null) {
        exercise = await db.customExerciseByName(name);
      } else {
        exercise = await db.exerciseById(id);
      }
    }
    final record =
        exercise == null ? null : await db.exerciseRecord(exercise.id);
    final duplicate = exercise != null &&
        await db.hasOpenRecordChallenge(
          exerciseId: exercise.id,
          exerciseSlug: exercise.slug,
          targetValue: link.target,
          fromName: link.fromName,
        );
    return (exercise: exercise, record: record, duplicate: duplicate);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  Future<void> _accept(ChallengeLink link, Exercise exercise) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    try {
      await db.insertChallenge(ChallengesCompanion.insert(
        kind: ChallengeKind.beatRecord,
        exerciseSlug: Value(exercise.slug),
        exerciseId: Value(exercise.id),
        targetValue: link.target,
        fromName: Value(link.fromName),
        createdAt: DateTime.now(),
        deadline: Value(link.deadline),
      ));
      await checkChallenges(db);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.shareChallengeAccepted)),
      );
      if (mounted) _close();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = widget.link;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareChallengeTitle)),
      body: link == null
          ? _Message(
              icon: Icons.link_off,
              text: l10n.shareChallengeInvalid,
              onClose: _close,
            )
          : FutureBuilder<_Resolved>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Message(
                    icon: Icons.error_outline,
                    text: l10n.errorGeneric,
                    onClose: _close,
                  );
                }
                final data = snap.data;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _body(context, link, data);
              },
            ),
    );
  }

  Widget _body(BuildContext context, ChallengeLink link, _Resolved data) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final exercise = data.exercise;
    final exerciseName = exercise?.localizedName(context) ??
        link.exerciseName ??
        (link.exerciseSlug != null
            ? humanizeSlug(link.exerciseSlug!)
            : l10n.shareUnknownExercise);
    final from = link.fromName;
    final deadline = link.deadline;
    final expired = deadline != null &&
        challengeState(deadline: deadline, now: DateTime.now()) ==
            ChallengeState.expired;
    final best = data.record;
    final progress = challengeProgress(
      ChallengeKind.beatRecord,
      link.target,
      bestTopWeight: best?.value,
    );

    final notices = <String>[
      if (exercise == null) l10n.shareChallengeUnknownExercise,
      if (expired) l10n.shareChallengeExpiredLink,
      if (data.duplicate) l10n.shareChallengeAlreadyAccepted,
      if (exercise != null && progress.reached && !data.duplicate)
        l10n.shareChallengeAlreadyBeaten,
    ];
    final canAccept =
        exercise != null && !expired && !data.duplicate && !_busy;
    // Lokální proměnná s typem bez null – funguje stejně ve všech verzích
    // Dartu (povýšení typu přes canAccept některé verze neumí).
    final acceptable = canAccept ? exercise : null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.sports_kabaddi, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          from == null
              ? l10n.shareChallengeFromAnonymous
              : l10n.shareChallengeFrom(from),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.shareChallengeGoal(
                      describeTopSet(context, link.value, link.reps)),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                if (exercise != null) ...[
                  Text(best == null
                      ? l10n.shareChallengeNoRecord
                      : l10n.shareChallengeYourBest(
                          describeTopSet(context, best.weightKg, best.reps))),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                ],
                if (deadline != null)
                  Row(
                    children: [
                      Icon(Icons.event,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(l10n.shareChallengeDeadline(
                          DateFormat.yMMMd(locale).format(deadline))),
                    ],
                  ),
              ],
            ),
          ),
        ),
        for (final n in notices) ...[
          const SizedBox(height: 12),
          Text(
            n,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed:
              acceptable == null ? null : () => _accept(link, acceptable),
          icon: const Icon(Icons.check),
          label: Text(l10n.shareChallengeAccept),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _close,
          child: Text(canAccept
              ? l10n.shareChallengeDecline
              : l10n.shareChallengeClose),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.onClose,
  });

  final IconData icon;
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onClose, child: Text(l10n.shareChallengeClose)),
          ],
        ),
      ),
    );
  }
}
