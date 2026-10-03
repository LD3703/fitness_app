import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../modules/module_hub.dart';
import '../../providers.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';

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
              if (mediaForExercise(e) case final media?)
                ExerciseMediaView(media: media)
              else
                AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
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
