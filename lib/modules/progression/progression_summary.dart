import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auto_progression.dart';
import '../../core/coach_tone.dart';
import '../../data/database.dart';
import '../../features/workout/workout_service.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../ui/labels.dart';
import 'progression_format.dart';
import 'progression_queries.dart';
import 'progression_service.dart';

enum _Status { pending, applied, kept, undone }

IconData progressionKindIcon(ProgressionKind kind) => switch (kind) {
      ProgressionKind.increase => Icons.trending_up,
      ProgressionKind.reps => Icons.add_circle_outline,
      ProgressionKind.deload => Icons.trending_down,
      ProgressionKind.hold => Icons.pause_circle_outline,
    };

/// Sekce „Příště“ v souhrnu po tréninku (progression:summary): navržené
/// změny cílů plánu s možností je použít / ponechat plán, v režimu
/// „použít automaticky“ s možností vrátit.
/// Premium (autoProgression): bez předplatného místo návrhů jen malá
/// zamčená upoutávka (háček po tréninku pak nic nenavrhuje).
class ProgressionSummarySection extends ConsumerStatefulWidget {
  const ProgressionSummarySection({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  ConsumerState<ProgressionSummarySection> createState() =>
      _ProgressionSummarySectionState();
}

class _ProgressionSummarySectionState
    extends ConsumerState<ProgressionSummarySection> {
  _Status? _status;
  Set<int>? _selected;
  List<int> _appliedIds = const [];
  bool _busy = false;
  bool _stale = false;

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _apply(List<ProgressionEntry> changes, Set<int> selected) async {
    setState(() => _busy = true);
    final applied = <int>[];
    var stale = false;
    try {
      for (final e in changes) {
        if (!selected.contains(e.eventId)) continue;
        if (await _db.applyProgressionEvent(e.eventId)) {
          applied.add(e.eventId);
        } else {
          stale = true;
        }
      }
      // Odškrtnuté návrhy uživatel nechce – zahodí se.
      await _db.discardProgressionEvents([
        for (final e in changes)
          if (!selected.contains(e.eventId)) e.eventId,
      ]);
    } catch (e) {
      debugPrint('Progression apply failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _stale = stale;
      _appliedIds = applied;
      _status = applied.isEmpty ? _Status.kept : _Status.applied;
    });
  }

  Future<void> _keep(List<ProgressionEntry> changes) async {
    setState(() => _busy = true);
    try {
      await _db.discardProgressionEvents([for (final e in changes) e.eventId]);
    } catch (e) {
      debugPrint('Progression discard failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = _Status.kept;
    });
  }

  Future<void> _undo() async {
    setState(() => _busy = true);
    try {
      for (final id in _appliedIds) {
        await _db.undoProgressionEvent(id);
      }
    } catch (e) {
      debugPrint('Progression undo failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _appliedIds = const [];
      _status = _Status.undone;
    });
  }

  /// Zamčená sekce „Příště“ (bez Premium), jen když má uživatel
  /// progresi zapnutou.
  Widget _lockedTeaser(BuildContext context) {
    final mode = progressionModeOf(
      ref.watch(profileProvider).valueOrNull?.progressionMode ?? 0,
    );
    if (mode == ProgressionMode.off) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).progressionSummaryTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const PremiumLockedPlaceholder(
            feature: PremiumFeature.autoProgression,
            compact: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(premiumProvider
        .select((a) => a.isPremium(PremiumFeature.autoProgression)));
    if (!allowed) return _lockedTeaser(context);
    final state = ref.watch(progressionSummaryProvider);
    if (state == null ||
        state.sessionId != widget.summary.sessionId ||
        state.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final changes = [
      for (final e in state.entries)
        if (e.proposal.changesPlan) e,
    ];
    final selected = _selected ??= {for (final e in changes) e.eventId};
    final status = _status ??= state.autoApplied
        ? _Status.applied
        : _Status.pending;
    if (state.autoApplied && _appliedIds.isEmpty && status == _Status.applied) {
      _appliedIds = [for (final e in changes) e.eventId];
    }

    final tone = effectiveCoachTone(
      coachToneOf(ref.watch(profileProvider).valueOrNull?.coachTone),
      ref.watch(situationProvider),
    );
    final hasIncrease = state.entries
        .any((e) => e.proposal.kind == ProgressionKind.increase);
    final showMessage = hasIncrease &&
        (status == _Status.pending || status == _Status.applied);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(ProgressionEntry e) {
      final title = Text(e.exercise.localizedName(context));
      final subtitle =
          Text(progressionChangeText(context, e.proposal.kind, e.proposal.info));
      if (status == _Status.pending && e.proposal.changesPlan) {
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: selected.contains(e.eventId),
          onChanged: _busy
              ? null
              : (v) => setState(() {
                    if (v ?? false) {
                      selected.add(e.eventId);
                    } else {
                      selected.remove(e.eventId);
                    }
                  }),
          title: title,
          subtitle: subtitle,
        );
      }
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(
          progressionKindIcon(e.proposal.kind),
          color: e.proposal.kind == ProgressionKind.hold
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
        title: title,
        subtitle: subtitle,
      );
    }

    final selectedCount =
        changes.where((e) => selected.contains(e.eventId)).length;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.progressionSummaryTitle, style: theme.textTheme.titleMedium),
          if (showMessage) ...[
            const SizedBox(height: 4),
            Text(
              progressionIncreaseMessage(l10n, tone, DateTime.now()),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 4),
          for (final e in state.entries) row(e),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 4),
            switch (status) {
              _Status.pending => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton(
                      onPressed: _busy || selectedCount == 0
                          ? null
                          : () => _apply(changes, selected),
                      child: Text(selectedCount == changes.length
                          ? l10n.progressionApplyAll
                          : l10n.progressionApplySelected(selectedCount)),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _keep(changes),
                      child: Text(l10n.progressionKeepCurrent),
                    ),
                  ],
                ),
              _Status.applied => Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(state.autoApplied
                          ? l10n.progressionAutoApplied
                          : l10n.progressionApplied),
                    ),
                    TextButton(
                      onPressed: _busy || _appliedIds.isEmpty ? null : _undo,
                      child: Text(l10n.undo),
                    ),
                  ],
                ),
              _Status.kept => Text(l10n.progressionKept, style: muted),
              _Status.undone => Text(l10n.progressionUndone, style: muted),
            },
          ],
          if (_stale)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.progressionStale, style: muted),
            ),
        ],
      ),
    );
  }
}
