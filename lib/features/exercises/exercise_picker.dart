import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';
import '../../ui/muscle_group_strip.dart';

/// Spodní panel pro výběr cviku z knihovny. Vrací vybraný cvik nebo null.
Future<Exercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _ExercisePicker(),
  );
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  String _query = '';
  MuscleGroup? _group;
  late Stream<List<Exercise>> _stream = _buildStream();

  Stream<List<Exercise>> _buildStream() =>
      ref.read(databaseProvider).watchExercises(query: _query, group: _group);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.exercisesSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (text) => setState(() {
                _query = text;
                _stream = _buildStream();
              }),
            ),
          ),
          // Partie s postavičkou – klepnutím jen cviky dané partie.
          MuscleGroupStrip(
            selected: _group,
            onSelected: (g) => setState(() {
              _group = g;
              _stream = _buildStream();
            }),
          ),
          Expanded(
            child: StreamBuilder<List<Exercise>>(
              stream: _stream,
              builder: (context, snapshot) {
                final list = snapshot.data;
                if (list == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return Center(child: Text(l10n.exercisesEmpty));
                }
                // Bez filtru a hledání rozdělené do sekcí podle partie.
                final entries = exerciseListEntries(
                  context,
                  list,
                  withHeaders: _group == null && _query.trim().isEmpty,
                );
                return ListView.builder(
                  controller: scrollController,
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
                      onTap: () => Navigator.of(context).pop(e),
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
