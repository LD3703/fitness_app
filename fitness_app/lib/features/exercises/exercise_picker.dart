import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/exercise_media_view.dart';
import '../../ui/labels.dart';

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
  late Stream<List<Exercise>> _stream = _buildStream();

  Stream<List<Exercise>> _buildStream() =>
      ref.read(databaseProvider).watchExercises(query: _query);

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
              autofocus: true,
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
                final sorted = [...list]..sort((a, b) => a
                    .localizedName(context)
                    .toLowerCase()
                    .compareTo(b.localizedName(context).toLowerCase()));
                return ListView.builder(
                  controller: scrollController,
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final e = sorted[i];
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
