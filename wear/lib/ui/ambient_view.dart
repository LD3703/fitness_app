import 'package:flutter/material.dart';

import '../watch_controller.dart';

/// Úsporný režim (ambient): černé pozadí, jen obrysový text, žádné plochy
/// ani animace. Systém ho překresluje zhruba jednou za minutu – během
/// pauzy se do ambientu nepřechází (displej drží MainActivity zapnutý).
class AmbientView extends StatelessWidget {
  const AmbientView({super.key, required this.controller});

  final WatchController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final entry = controller.current;
    const style = TextStyle(color: Colors.white70, fontSize: 14);
    final lines = <String>[];
    if (controller.phase == WatchPhase.active) {
      if (entry != null) {
        lines
          ..add(entry.name)
          ..add(s.setOf(entry.setIndex + 1, entry.setCount))
          ..add(controller.describeSet(
            controller.weightKgOf(entry),
            controller.valueOf(entry),
            isDuration: entry.isDuration,
          ));
      } else {
        lines.add(s.allDone);
      }
    } else {
      lines.add(s.appTitle);
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in lines)
                Text(
                  line,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
