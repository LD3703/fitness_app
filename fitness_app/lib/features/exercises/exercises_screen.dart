import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';

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
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _GroupChip(
                  label: l10n.filterAll,
                  selected: selectedGroup == null,
                  onSelected: () => ref
                      .read(exerciseGroupFilterProvider.notifier)
                      .state = null,
                ),
                for (final g in MuscleGroup.values)
                  _GroupChip(
                    label: l10n.muscleGroup(g),
                    selected: selectedGroup == g,
                    onSelected: () => ref
                        .read(exerciseGroupFilterProvider.notifier)
                        .state = g,
                  ),
              ],
            ),
          ),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorGeneric)),
              data: (list) {
                if (list.isEmpty) {
                  return Center(child: Text(l10n.exercisesEmpty));
                }
                final sorted = [...list]..sort((a, b) => a
                    .localizedName(context)
                    .toLowerCase()
                    .compareTo(b.localizedName(context).toLowerCase()));
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = sorted[i];
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

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
