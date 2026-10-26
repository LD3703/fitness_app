import 'package:flutter/material.dart';

import '../services/live_heart_rate.dart';

/// Živý tep z hodinek během tréninku (♥ 132); nic, když hodinky tep
/// neposílají.
class LiveHeartRateBadge extends StatelessWidget {
  const LiveHeartRateBadge({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int?>(
        valueListenable: LiveHeartRate.instance.current,
        builder: (context, bpm, _) => bpm == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite,
                        size: 18, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text('$bpm'),
                  ],
                ),
              ),
      );
}
