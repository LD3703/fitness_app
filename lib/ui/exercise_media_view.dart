import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';
import '../data/seed/exercise_media.dart';
import '../l10n/app_localizations.dart';
import 'labels.dart';

/// Obrázky vestavěného cviku (null u vlastních cviků a cviků bez obrázku).
ExerciseMedia? mediaForExercise(Exercise exercise) {
  final slug = exercise.slug;
  if (slug == null) return null;
  final media = exerciseMedia[slug];
  return (media == null || media.images.isEmpty) ? null : media;
}

/// Ukázka cviku: obrázky výchozí a koncové polohy se střídají jako
/// jednoduchá animace. Klepnutím se střídání zastaví / spustí.
/// Pod obrázkem je autor a licence (vyžaduje CC BY-SA).
class ExerciseMediaView extends StatefulWidget {
  const ExerciseMediaView({super.key, required this.media});

  final ExerciseMedia media;

  @override
  State<ExerciseMediaView> createState() => _ExerciseMediaViewState();
}

class _ExerciseMediaViewState extends State<ExerciseMediaView> {
  static const _interval = Duration(milliseconds: 1200);

  Timer? _timer;
  int _index = 0;
  bool _paused = false;

  List<ExerciseImage> get _images => widget.media.images;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant ExerciseMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media != widget.media) {
      _index = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (_images.length < 2 || _paused) return;
    _timer = Timer.periodic(_interval, (_) {
      if (mounted) setState(() => _index = (_index + 1) % _images.length);
    });
  }

  void _togglePause() {
    if (_images.length < 2) return;
    setState(() => _paused = !_paused);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final image = _images[_index % _images.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _togglePause,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                // Obrázky z wger mají bílé pozadí – i v tmavém režimu.
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Image.asset(
                        image.asset,
                        key: ValueKey(image.asset),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    if (_images.length > 1)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Icon(
                          _paused ? Icons.play_arrow : Icons.pause,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => launchUrl(
            Uri.parse(widget.media.sourceUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.mediaAttribution(image.author, image.license),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

/// Malý náhled cviku do seznamů (nic, když cvik obrázek nemá).
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({super.key, required this.exercise, this.size = 48});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final media = mediaForExercise(exercise);
    if (media == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.fitness_center,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: Image.asset(
          media.images.first.asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}

/// Spodní panel s ukázkou cviku (např. během tréninku).
Future<void> showExerciseMediaSheet(BuildContext context, Exercise exercise) {
  final media = mediaForExercise(exercise);
  final instructions = exercise.localizedInstructions(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              exercise.localizedName(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (media != null) ExerciseMediaView(media: media),
            if (instructions != null) ...[
              const SizedBox(height: 12),
              Text(instructions),
            ],
          ],
        ),
      ),
    ),
  );
}
