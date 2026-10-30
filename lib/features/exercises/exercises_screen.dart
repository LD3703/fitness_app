import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';
import '../../ui/muscle_group_strip.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final exercises = ref.watch(exercisesProvider);
    final selectedGroup = ref.watch(exerciseGroupFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabExercises)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercise-edit'),
        icon: const Icon(Icons.add),
        label: Text(l10n.dataExerciseAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.exercisesSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (text) =>
                  ref.read(exerciseQueryProvider.notifier).state = text,
            ),
          ),
          MuscleGroupStrip(
            selected: selectedGroup,
            onSelected: (g) =>
                ref.read(exerciseGroupFilterProvider.notifier).state = g,
          ),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorGeneric)),
              data: (list) {
                if (list.isEmpty) {
                  return Center(child: Text(l10n.exercisesEmpty));
                }
                // Bez filtru a hledání rozdělené do sekcí podle partie.
                final entries = exerciseListEntries(
                  context,
                  list,
                  withHeaders: selectedGroup == null &&
                      ref.watch(exerciseQueryProvider).trim().isEmpty,
                );
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    if (entry.header case final g?) {
                      return ExerciseGroupHeader(group: g);
                    }
                    final e = entry.exercise!;
                    return ListTile(
                      leading: ExerciseThumbnail(exercise: e),
                      title: Text(e.localizedName(context)),
                      subtitle: Text(
                        '${l10n.muscleGroup(e.muscleGroup)} · '
                        '${l10n.equipment(e.equipment)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/exercises/${e.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
