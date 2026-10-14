import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../social/social_backend.dart';
import '../../social/ui/social_ui.dart' show showSocialSnack;
import '../coach_queries.dart';
import '../coach_service.dart';

/// /shared-plan?id=… – plán sdílený odkazem gymbar.app/plan?id=…
/// Načíst ho jde i bez přihlášení.
class SharedPlanScreen extends ConsumerStatefulWidget {
  const SharedPlanScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SharedPlanScreen> createState() => _SharedPlanScreenState();
}

class _SharedPlanScreenState extends ConsumerState<SharedPlanScreen> {
  late final Future<SharedPlan?> _plan = SocialBackend.available
      ? CoachService.instance.fetchSharedPlan(widget.id)
      : Future.value(null);
  bool _busy = false;

  Future<void> _add(SharedPlan shared) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    try {
      final planId = await db.importCoachPlan(
        shared.plan,
        remoteId: sharedPlanRemoteId(widget.id),
        version: 1,
        from: shared.authorName,
      );
      if (!mounted) return;
      showSocialSnack(context, l10n.sharedPlanAdded);
      context.go('/plans/$planId');
    } catch (e) {
      debugPrint('Coach: import shared plan failed: $e');
      if (mounted) showSocialSnack(context, l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = l10n.localeName.split(RegExp('[_-]')).first;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharedPlanTitle)),
      body: FutureBuilder<SharedPlan?>(
        future: _plan,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final shared = snap.data;
          if (shared == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snap.hasError ? l10n.socialOffline : l10n.sharedPlanNotFound,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final plan = shared.plan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(plan.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(l10n.sharedPlanBy(shared.authorName)),
              if (plan.description != null) ...[
                const SizedBox(height: 8),
                Text(plan.description!),
              ],
              const SizedBox(height: 8),
              Text(l10n.sharedPlanExercises(plan.exercises.length),
                  style: theme.textTheme.titleSmall),
              for (final e in plan.exercises)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.nameFor(lang)),
                  subtitle: Text([
                    e.sets
                        .where((s) => !s.warmup)
                        .map((s) => s.kg == null
                            ? '${s.reps}×'
                            : '${s.reps}× ${s.kg!.toStringAsFixed(s.kg! % 1 == 0 ? 0 : 1)} kg')
                        .join(', '),
                    if (e.note != null) e.note!,
                  ].join('\n')),
                ),
              const SizedBox(height: 16),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: () => _add(shared),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.sharedPlanAdd),
                ),
            ],
          );
        },
      ),
    );
  }
}
