import 'dart:async';

import 'package:flutter/material.dart';

import '../native.dart';

/// Okraje obsahu: na kulatém displeji větší, aby nic nebylo v rozích
/// mimo kruh (na displeji ~200 dp zhruba 12 % po stranách).
EdgeInsets watchPadding(BuildContext context, {required bool round}) {
  final size = MediaQuery.sizeOf(context);
  if (!round) return const EdgeInsets.fromLTRB(8, 8, 8, 16);
  return EdgeInsets.fromLTRB(
    size.width * 0.12,
    size.height * 0.16,
    size.width * 0.12,
    size.height * 0.22,
  );
}

/// Posouvá [controller] otáčením korunky / lunety (viz WearNative).
class RotaryScroll extends StatefulWidget {
  const RotaryScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<RotaryScroll> createState() => _RotaryScrollState();
}

class _RotaryScrollState extends State<RotaryScroll> {
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = WearNative.rotaryEvents.listen(_onRotate);
  }

  void _onRotate(double delta) {
    final c = widget.controller;
    if (!c.hasClients) return;
    final p = c.position;
    final target =
        (p.pixels + delta).clamp(p.minScrollExtent, p.maxScrollExtent);
    c.jumpTo(target.toDouble());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Kulaté tlačítko +/- (min. 44 dp – dobře trefitelné na hodinkách).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Obrazovka se stavem (připojování, bez tréninku…) s volitelným tlačítkem.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.round,
    required this.icon,
    required this.text,
    this.busy = false,
    this.actionLabel,
    this.onAction,
  });

  final bool round;
  final IconData icon;
  final String text;
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;
    return Center(
      child: SingleChildScrollView(
        padding: watchPadding(context, round: round),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Krátké hlášení dole na displeji (potvrzení z telefonu).
class NoticeBubble extends StatelessWidget {
  const NoticeBubble({super.key, required this.text, required this.round});

  final String text;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    return Positioned(
      left: size.width * (round ? 0.15 : 0.05),
      right: size.width * (round ? 0.15 : 0.05),
      bottom: size.height * (round ? 0.1 : 0.04),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onInverseSurface),
          ),
        ),
      ),
    );
  }
}
