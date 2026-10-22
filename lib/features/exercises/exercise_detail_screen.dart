import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../ui/body_map.dart';
import '../../ui/dialogs.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';

/// ID vestavěného cviku podle slugu (null = takový cvik v databázi není).
final exerciseIdBySlugProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, slug) async {
  final db = ref.watch(databaseProvider);
  final e = await (db.select(db.exercises)..where((x) => x.slug.equals(slug)))
      .getSingleOrNull();
  return e?.id;
});

/// Cvik otevřený odkazem ze samolepky na stroji (`gymbar.app/ex?id=<slug>`,
/// docs/fitka.md) – najde cvik podle slugu a ukáže jeho detail.
class ExerciseBySlugScreen extends ConsumerWidget {
  const ExerciseBySlugScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref.watch(exerciseIdBySlugProvider(slug)).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.errorGeneric)),
          ),
          data: (id) => id == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Text(l10n.exercisesEmpty)),
                )
              : ExerciseDetailScreen(exerciseId: id),
        );
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = ref.watch(exerciseProvider(exerciseId));

    return exercise.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (e) {
        if (e == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.exercisesEmpty)),
          );
        }
        final instructions = e.localizedInstructions(context);
        return Scaffold(
          appBar: AppBar(title: Text(e.localizedName(context))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (mediaForExercise(e) case final media?) ...[
                ExerciseMediaView(media: media),
                const SizedBox(height: 16),
              ],
              // Zapojené partie na postavě (hlavní plně, vedlejší světleji).
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.exerciseMusclesTitle,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TrainedBodyMap(
                        sets: muscleSetsOf([e]),
                        primaryLabel: l10n.bodyMapPrimary,
                        secondaryLabel: l10n.bodyMapSecondary,
                        groupName: l10n.muscleGroup,
                        height: 180,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _MyNoteCard(exercise: e),
              const SizedBox(height: 16),
              _InfoRow(
                label: l10n.exerciseMuscleGroup,
                value: l10n.muscleGroup(e.muscleGroup),
              ),
              _InfoRow(
                label: l10n.exerciseEquipment,
                value: l10n.equipment(e.equipment),
              ),
              const SizedBox(height: 16),
              Text(l10n.exerciseInstructionsTitle,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(instructions ?? l10n.exerciseInstructionsMissing),
              ...moduleExerciseDetailSections(e),
            ],
          ),
        );
      },
    );
  }
}

/// Moje poznámka ke cviku (např. nastavení stroje) – ukazuje se i při
/// tréninku.
class _MyNoteCard extends ConsumerWidget {
  const _MyNoteCard({required this.exercise});

  final Exercise exercise;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final text = await showNoteDialog(
      context,
      title: l10n.exerciseNoteMine,
      initialValue: exercise.note ?? '',
      hintText: l10n.exerciseNoteMineHint,
      maxLength: exerciseNoteMax,
    );
    if (text == null) return;
    await ref.read(databaseProvider).setExerciseNote(exercise.id, text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final note = exercise.note;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.edit_note),
        title: Text(note ?? l10n.exerciseNoteAdd),
        subtitle: Text(
          note == null ? l10n.exerciseNoteMineHint : l10n.exerciseNoteMine,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(note == null ? Icons.add : Icons.edit_outlined),
        onTap: () => _edit(context, ref),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
