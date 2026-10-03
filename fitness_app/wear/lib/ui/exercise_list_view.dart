import 'package:flutter/material.dart';

import '../watch_controller.dart';
import '../wear_protocol.dart';
import 'common.dart';

/// Seznam cviků tréninku s počtem hotových sérií; klepnutí přepne cvik.
class ExerciseListView extends StatefulWidget {
  const ExerciseListView({
    super.key,
    required this.controller,
    required this.round,
  });

  final WatchController controller;
  final bool round;

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.strings;
    final theme = Theme.of(context);
    final items = c.state?.exercises ?? const <WearExerciseItem>[];
    final currentBlock = c.current?.blockIndex;

    return RotaryScroll(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        padding: watchPadding(context, round: widget.round),
        children: [
          Text(
            s.exercises,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(
                color: item.blockIndex == currentBlock
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: item.isDone ? null : () => c.selectExercise(item),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (item.isDone)
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: theme.colorScheme.primary,
                            )
                          else
                            Text(
                              '${item.doneSets}/${item.totalSets}',
                              style: theme.textTheme.labelMedium,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => c.toggleList(false),
            icon: const Icon(Icons.arrow_back),
            label: Text(s.back),
          ),
        ],
      ),
    );
  }
}
