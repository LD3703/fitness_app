import 'package:flutter/material.dart';

import '../watch_controller.dart';
import 'active_view.dart';
import 'common.dart';
import 'exercise_list_view.dart';

/// Hlavní obrazovka hodinek podle stavu spojení a tréninku.
///
/// Záměrně bez vodorovného posouvání stránek: Wear OS zavírá aplikaci
/// tahem zleva doprava (swipe-to-dismiss) a Flutter s ním koliduje.
/// Všechno je pod sebou a posouvá se prstem nebo korunkou.
class WatchHome extends StatelessWidget {
  const WatchHome({super.key, required this.controller, required this.round});

  final WatchController controller;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.strings;
        final Widget body = switch (controller.phase) {
          WatchPhase.connecting => StatusView(
              round: round,
              icon: Icons.watch,
              text: s.connecting,
              busy: true,
            ),
          WatchPhase.unreachable => StatusView(
              round: round,
              icon: Icons.phonelink_off,
              text: s.unreachable,
              actionLabel: s.retry,
              onAction: controller.retry,
            ),
          WatchPhase.idle => StatusView(
              round: round,
              icon: Icons.fitness_center,
              text: s.idle,
            ),
          WatchPhase.openOnPhone => StatusView(
              round: round,
              icon: Icons.smartphone,
              text: s.openOnPhone,
              actionLabel: s.open,
              onAction: controller.isPending('openWorkout')
                  ? null
                  : controller.openWorkout,
            ),
          WatchPhase.premiumRequired => StatusView(
              round: round,
              icon: Icons.workspace_premium_outlined,
              text: s.premiumRequired,
            ),
          WatchPhase.active => controller.showList
              ? ExerciseListView(controller: controller, round: round)
              : ActiveView(controller: controller, round: round),
        };
        final notice = controller.notice;
        return PopScope(
          // Systémové „zpět“ v seznamu cviků vrátí na sérii.
          canPop: !controller.showList,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.toggleList(false);
          },
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (notice != null) NoticeBubble(text: notice, round: round),
            ],
          ),
        );
      },
    );
  }
}
