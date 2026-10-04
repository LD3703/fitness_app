import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../watch_controller.dart';
import '../wear_protocol.dart';
import 'common.dart';

/// Probíhající trénink: pauza (když běží), série na řadě s +/- a velkým
/// tlačítkem Hotovo, pod tím přechod na další cvik, seznam a ukončení.
class ActiveView extends StatefulWidget {
  const ActiveView({super.key, required this.controller, required this.round});

  final WatchController controller;
  final bool round;

  @override
  State<ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends State<ActiveView> {
  final _scroll = ScrollController();
  bool _wasResting = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.strings;
    final state = c.state;
    final current = c.current;
    final resting = c.isResting;

    // Začátek pauzy → nahoru na odpočet.
    if (resting && !_wasResting && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
    _wasResting = resting;

    final exercises = state?.exercises ?? const <WearExerciseItem>[];
    final doneExercises = exercises.where((e) => e.isDone).length;

    return RotaryScroll(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        padding: watchPadding(context, round: widget.round),
        children: [
          if (resting) ...[
            _RestPanel(controller: c),
            const SizedBox(height: 8),
          ],
          if (current == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                s.allDone,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          else
            _SetPanel(controller: c, entry: current, compact: resting),
          const SizedBox(height: 12),
          if (current != null && exercises.length > 1)
            OutlinedButton.icon(
              onPressed: c.isPending('nextExercise') ? null : c.nextExercise,
              icon: const Icon(Icons.skip_next),
              label: Text(s.nextExercise),
            ),
          if (exercises.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => c.toggleList(true),
              icon: const Icon(Icons.list),
              label: Text('${s.exercises} $doneExercises/${exercises.length}'),
            ),
          TextButton.icon(
            onPressed: c.isPending('finishWorkout') ? null : c.finishWorkout,
            icon: const Icon(Icons.flag_outlined),
            label: Text(s.finish),
          ),
        ],
      ),
    );
  }
}

/// Odpočet pauzy s kruhovým ukazatelem a tlačítkem Přeskočit.
class _RestPanel extends StatelessWidget {
  const _RestPanel({required this.controller});

  final WatchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = controller.strings;
    // Zaokrouhlení nahoru, aby „0:00“ svítilo až na konci.
    final left = controller.restRemaining + const Duration(milliseconds: 999);
    final minutes = left.inMinutes;
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: controller.restProgress,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.rest, style: theme.textTheme.labelMedium),
                  Text(
                    '$minutes:$seconds',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        FilledButton.tonal(
          onPressed: controller.skipRest,
          child: Text(s.skip),
        ),
      ],
    );
  }
}

/// Série na řadě: název cviku, „Série 2 z 4“, váha a opakování s +/-,
/// tlačítko Hotovo a hodnoty z minula.
class _SetPanel extends StatelessWidget {
  const _SetPanel({
    required this.controller,
    required this.entry,
    required this.compact,
  });

  final WatchController controller;
  final WearCurrentSet entry;

  /// Během pauzy menší nadpis (série je „další“).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;
    final s = c.strings;
    final unit = c.state?.unit ?? 'kg';
    final weight = c.displayWeight(c.weightKgOf(entry));
    final value = c.valueOf(entry);
    final kindLabel = switch (entry.kind) {
      WearSetKind.warmup => s.warmup,
      WearSetKind.drop => s.drop,
      WearSetKind.working => null,
    };
    final completing = c.isPending('completeSet');
    final previous = entry.previousValue == null
        ? null
        : c.describeSet(entry.previousWeightKg, entry.previousValue,
            isDuration: entry.isDuration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          Text(
            s.next(entry.name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          )
        else
          Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 2),
        Text(
          [
            s.setOf(entry.setIndex + 1, entry.setCount),
            if (kindLabel != null) kindLabel,
          ].join(' · '),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        if (!entry.isDuration)
          _Stepper(
            value: weight == null
                ? (entry.weightRequired ? '–' : s.bodyweight)
                : c.formatNumber(weight),
            unit: weight == null ? null : unit,
            label: s.weightLabel,
            controller: c,
            onMinus: weight == null ? null : () => c.adjustWeight(-1),
            onPlus: () => c.adjustWeight(1),
          ),
        _Stepper(
          value: value == null ? '–' : '$value',
          unit: entry.isDuration ? s.seconds : s.reps,
          label: entry.isDuration ? s.seconds : s.reps,
          controller: c,
          onMinus: value == null || value <= 1 ? null : () => c.adjustValue(-1),
          onPlus: () => c.adjustValue(1),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: completing ? null : c.completeSet,
            icon: completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              s.done,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (previous != null) ...[
          const SizedBox(height: 6),
          Text(
            s.lastTime(previous),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Řádek „−  60 kg  +“.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.label,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final String? unit;
  final String label;
  final WatchController controller;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = controller.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.remove,
            tooltip: '${s.decrease}: $label',
            onPressed: onMinus,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (unit != null)
                  Text(
                    unit!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.add,
            tooltip: '${s.increase}: $label',
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}
