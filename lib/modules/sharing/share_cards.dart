import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/format.dart';
import '../links/deep_links.dart';

/// Název aplikace na kartách. TODO: změnit, až bude název finální.
const kShareAppName = 'Fitness App';

/// Logický rozměr karty (4:5). Obrázek se renderuje ve 3× → 1080 × 1350 px,
/// což je rozměr, který Instagram i ostatní sítě berou bez ořezu.
const kShareCardSize = Size(360, 450);

/// Barvy karet – pevné, aby obrázek vypadal stejně ve světlém i tmavém režimu.
class _CardColors {
  static const top = Color(0xFF0E3B32);
  static const bottom = Color(0xFF2E7D6B);
  static const accent = Color(0xFFFFC857);
  static const text = Colors.white;
  static const muted = Color(0xCCFFFFFF);
  static const faint = Color(0x33FFFFFF);
}

/// Adresa webu bez „https://“ (pro patičku karty).
String get shareWebHost {
  final uri = Uri.tryParse(kWebBaseUrl);
  return (uri == null || uri.host.isEmpty) ? kWebBaseUrl : uri.host;
}

/// Data pro kartu osobního rekordu.
class RecordCardData {
  const RecordCardData({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.oneRepMax,
    required this.date,
  });

  final String exerciseName;
  final double weightKg;
  final int reps;
  final double oneRepMax;
  final DateTime date;
}

/// Data pro kartu dokončeného tréninku.
class WorkoutCardData {
  const WorkoutCardData({
    required this.date,
    required this.duration,
    required this.setCount,
    required this.volumeKg,
    required this.recordCount,
    required this.exerciseNames,
  });

  final DateTime date;
  final Duration duration;
  final int setCount;
  final double volumeKg;
  final int recordCount;
  final List<String> exerciseNames;
}

/// Karta osobního rekordu (obrázek ke sdílení).
class RecordShareCard extends StatelessWidget {
  const RecordShareCard({super.key, required this.data});

  final RecordCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CardFrame(
      label: l10n.shareCardRecordLabel,
      icon: Icons.emoji_events,
      date: data.date,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.exerciseName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: _CardColors.text,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: formatWeight(context, data.weightKg),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: _CardColors.accent,
                  ),
                ),
                TextSpan(
                  text: ' $weightUnit',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _CardColors.accent,
                  ),
                ),
                TextSpan(
                  text: '  × ${data.reps}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: _CardColors.text,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _CardColors.faint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.shareCardOneRepMax(formatWeightWithUnit(context, data.oneRepMax)),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _CardColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Karta dokončeného tréninku (obrázek ke sdílení).
class WorkoutShareCard extends StatelessWidget {
  const WorkoutShareCard({super.key, required this.data});

  final WorkoutCardData data;

  static const _maxExercises = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = data.exerciseNames.take(_maxExercises).toList();
    final more = data.exerciseNames.length - shown.length;
    return _CardFrame(
      label: l10n.shareCardWorkoutLabel,
      icon: Icons.check_circle,
      date: data.date,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _Stat(
                value: formatDuration(data.duration),
                label: l10n.shareCardDuration,
              ),
              _Stat(value: '${data.setCount}', label: l10n.shareCardSets),
              _Stat(
                value: formatWeightTotal(context, data.volumeKg),
                label: l10n.shareCardVolume,
              ),
            ],
          ),
          if (data.recordCount > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: _CardColors.accent, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.shareCardRecords(data.recordCount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _CardColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final name in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _CardColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _CardColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 2),
                child: Text(
                  l10n.shareCardMoreExercises(more),
                  style: const TextStyle(
                      fontSize: 13, color: _CardColors.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _CardColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _CardColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Společný rámec karty: pozadí, logo s názvem, štítek, datum a odkaz.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.label,
    required this.icon,
    required this.date,
    required this.child,
  });

  final String label;
  final IconData icon;
  final DateTime date;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.yMMMMd(locale).format(date);
    // Karta má pevnou velikost – velikost písma v systému ji nesmí rozbít.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: _CardColors.text,
          decoration: TextDecoration.none,
          fontSize: 14,
        ),
        child: SizedBox.fromSize(
          size: kShareCardSize,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_CardColors.top, _CardColors.bottom],
              ),
            ),
            child: Stack(
              children: [
                // Dekorativní kruhy v pozadí.
                Positioned(
                  right: -80,
                  top: -60,
                  child: _Ring(size: 240, color: _CardColors.faint),
                ),
                Positioned(
                  right: -30,
                  bottom: 40,
                  child: _Ring(size: 140, color: const Color(0x1AFFFFFF)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          AppLogoMark(size: 34),
                          SizedBox(width: 10),
                          Text(
                            kShareAppName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: _CardColors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Icon(icon, size: 18, color: _CardColors.accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: _CardColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                            fontSize: 13, color: _CardColors.muted),
                      ),
                      Expanded(child: child),
                      Container(height: 1, color: _CardColors.faint),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.link,
                              size: 16, color: _CardColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            shareWebHost,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _CardColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 18),
      ),
    );
  }
}

/// Jednoduché logo aplikace: činka v zaobleném čtverci.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final bg = Paint()..color = _CardColors.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & Size.square(s),
          Radius.circular(s * 0.26)),
      bg,
    );

    final ink = Paint()..color = _CardColors.top;
    final cy = s / 2;
    RRect bar(double cx, double w, double h) => RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
          Radius.circular(w * 0.35),
        );
    // Tyč
    canvas.drawRRect(bar(s / 2, s * 0.56, s * 0.08), ink);
    // Kotouče (velký + malý na každé straně)
    for (final dir in [-1.0, 1.0]) {
      canvas.drawRRect(bar(s / 2 + dir * s * 0.22, s * 0.1, s * 0.46), ink);
      canvas.drawRRect(bar(s / 2 + dir * s * 0.33, s * 0.08, s * 0.30), ink);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}
