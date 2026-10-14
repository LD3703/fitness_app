import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/muscle_sets.dart';
import '../data/database.dart';
import '../providers.dart';

export '../core/muscle_sets.dart';

/// Postava zepředu a zezadu s obarvenými svalovými partiemi – „mapa těla“
/// pro souhrny tréninků, plány a regeneraci.
///
/// Tvary jsou vlastní, stylizované (souřadnice 0–100 × 0–190 na jednu
/// postavu). Mezery mezi svaly jsou průhledné, takže mapa sedí na kartě
/// i v dialogu bez ohledu na barvu pozadí.
class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.colors,
    this.height = 160,
    this.showFront = true,
    this.showBack = true,
    this.semanticLabel,
  });

  /// Barva partie; partie, které tu nejsou, mají neutrální barvu.
  /// [MuscleGroup.fullBody] obarví všechny partie, které jinak barvu nemají.
  final Map<MuscleGroup, Color> colors;
  final double height;
  final bool showFront;
  final bool showBack;

  /// Popis pro čtečku obrazovky (např. seznam partií).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final views = (showFront ? 1 : 0) + (showBack ? 1 : 0);
    final width = height * _figureWidth * views / _figureHeight;
    final neutral = bodyMapNeutralColor(context);
    final map = CustomPaint(
      size: Size(width, height),
      painter: _BodyMapPainter(
        colors: colors,
        neutral: neutral,
        showFront: showFront,
        showBack: showBack,
      ),
    );
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: map,
    );
  }
}

/// Barva netrénovaných partií (šedá s nádechem tealu).
Color bodyMapNeutralColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A4542)
        : const Color(0xFFC9D3CF);

/// Barvy „hlavní“ a „vedlejší“ partie – žlutá z loga GymBar.
({Color primary, Color secondary}) bodyMapTrainedColors(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark
      ? (primary: const Color(0xFFFFC857), secondary: const Color(0xFF8E7536))
      : (primary: const Color(0xFFE8A317), secondary: const Color(0xFFF2CA6B));
}

/// Barvy mapy pro hlavní a vedlejší partie.
Map<MuscleGroup, Color> trainedGroupColors(
  BuildContext context,
  MuscleSets sets,
) {
  final c = bodyMapTrainedColors(context);
  return {
    for (final g in sets.secondary) g: c.secondary,
    for (final g in sets.primary) g: c.primary,
  };
}

/// Mapa těla s legendou „Hlavní partie / Vedlejší“ (souhrn tréninku, plán).
class TrainedBodyMap extends StatelessWidget {
  const TrainedBodyMap({
    super.key,
    required this.sets,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.groupName,
    this.height = 150,
  });

  final MuscleSets sets;
  final String primaryLabel;
  final String secondaryLabel;

  /// Název partie pro čtečku obrazovky.
  final String Function(MuscleGroup) groupName;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = bodyMapTrainedColors(context);
    final theme = Theme.of(context);
    Widget legend(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );
    final semantic = [
      '$primaryLabel: ${sets.primary.map(groupName).join(', ')}',
      if (sets.secondary.isNotEmpty)
        '$secondaryLabel: ${sets.secondary.map(groupName).join(', ')}',
    ].join('. ');
    return Column(
      children: [
        Center(
          child: BodyMap(
            colors: trainedGroupColors(context, sets),
            height: height,
            semanticLabel: semantic,
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              legend(c.primary, primaryLabel),
              if (sets.secondary.isNotEmpty) legend(c.secondary, secondaryLabel),
            ],
          ),
        ),
      ],
    );
  }
}

/// Malá mapa těla k plánu (v seznamu plánů a na obrazovce Dnes).
class PlanBodyMapThumb extends ConsumerWidget {
  const PlanBodyMapThumb({super.key, required this.planId, this.height = 56});

  final int planId;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(planMusclesProvider(planId));
    if (sets == null || sets.primary.isEmpty) {
      return SizedBox(width: height * 2 * _figureWidth / _figureHeight);
    }
    return BodyMap(colors: trainedGroupColors(context, sets), height: height);
  }
}

/// Ikona partie cviku – výřez postavy (horní / dolní polovina, zepředu /
/// zezadu podle hlavní partie) s obarvenou hlavní a vedlejší partií.
class MuscleIcon extends StatelessWidget {
  const MuscleIcon({
    super.key,
    required this.focus,
    required this.sets,
    this.size = 48,
  });

  /// Hlavní partie – podle ní se vybere pohled a výřez.
  final MuscleGroup focus;
  final MuscleSets sets;
  final double size;

  static const _upper = Rect.fromLTWH(10, 8, 80, 80);
  static const _lower = Rect.fromLTWH(10, 80, 80, 80);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fromBack = const {
      MuscleGroup.back,
      MuscleGroup.traps,
      MuscleGroup.lowerBack,
      MuscleGroup.triceps,
      MuscleGroup.glutes,
      MuscleGroup.hamstrings,
    }.contains(focus);
    final lower = focus.isLowerBody;
    final full = focus == MuscleGroup.fullBody;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: ColoredBox(
          color: dark ? const Color(0xFF1F2725) : const Color(0xFFEEF3F0),
          child: CustomPaint(
            size: Size.square(size),
            painter: _BodyMapPainter(
              colors: trainedGroupColors(context, sets),
              neutral: bodyMapNeutralColor(context),
              showFront: !fromBack,
              showBack: fromBack,
              // Celé tělo: celá postava zmenšená doprostřed.
              crop: full
                  ? const Rect.fromLTWH(-45, 0, 190, 190)
                  : (lower ? _lower : _upper),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikona partie konkrétního cviku (seznamy cviků, plán, trénink).
class ExerciseMuscleIcon extends StatelessWidget {
  const ExerciseMuscleIcon({super.key, required this.exercise, this.size = 48});

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) => MuscleIcon(
        focus: exercise.muscleGroup,
        sets: muscleSetsOf([exercise]),
        size: size,
      );
}

// ---------------------------------------------------------------------------
// Kreslení
// ---------------------------------------------------------------------------

const _figureWidth = 100.0;
const _figureHeight = 190.0;

/// Část postavy: partie (null = neutrální: hlava, předloktí, kolena…),
/// [mirror] = nakreslit i zrcadlově (pravá polovina těla).
typedef _Part = ({MuscleGroup? group, bool mirror, String path});

/// Zepředu: trapézy, deltoidy, prsa, pilovité svaly, šikmé a přímé břišní
/// (4 řady), biceps, předloktí, čtyřhlavý sval (3 hlavy), přitahovače,
/// holeň a lýtka.
const List<_Part> _front = [
  (group: null, mirror: false, path: 'M50,4 C55.5,4 58.5,8.5 58.5,14 C58.5,20 55,25 50,25 C45,25 41.5,20 41.5,14 C41.5,8.5 44.5,4 50,4 Z'),
  (group: null, mirror: false, path: 'M45.5,24 C46.3,26.5 46.8,28.8 47.2,31.5 L52.8,31.5 C53.2,28.8 53.7,26.5 54.5,24 Z'),
  (group: MuscleGroup.traps, mirror: true, path: 'M44.8,25.5 C43.2,28.3 40.5,30.2 35.5,31.8 L46.4,31.8 C46,29.5 45.5,27.3 44.8,25.5 Z'),
  (group: MuscleGroup.shoulders, mirror: true, path: 'M35,32.6 C29,32.6 25.5,36 24.5,41.2 C24,44 24.4,46.2 25,48.2 C27,46.2 29,44 30.6,42 C32.2,38.6 34.2,35.7 37.8,33.8 Z'),
  (group: MuscleGroup.chest, mirror: true, path: 'M49.3,33 L39.2,33 C35.6,35 33.2,38.5 32.7,43 C32.6,46.2 34.1,48.6 37.1,49.6 C41.1,50.6 45.6,50.1 49.3,48.6 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M33.6,49.8 L37.2,51.2 L36.8,54.2 L33.9,53.2 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M34.2,55.2 L37.4,56.2 L37.1,59.3 L34.6,58.3 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M44.3,51.6 L49.3,51.6 L49.3,57.3 L44.6,57.7 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M44.6,58.7 L49.3,58.4 L49.3,64.5 L44.8,64.8 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M44.8,65.8 L49.3,65.6 L49.3,71.6 L44.9,71.8 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M44.9,72.8 L49.3,72.7 L49.3,84 C47.5,83.6 46,82.4 45.2,80.5 Z'),
  (group: MuscleGroup.core, mirror: true, path: 'M43,51.2 C40.3,50.7 38.8,51.2 38.2,52.6 C37.8,60 38.8,70 41.2,78.8 L43.6,82.2 L43.4,58 Z'),
  (group: MuscleGroup.biceps, mirror: true, path: 'M24.3,49.2 C22.5,54 22.3,59.6 23.5,64.6 C25.5,66.1 28,65.6 29.5,62.6 C30.8,58.6 31.2,53.1 30.6,47.6 C28.5,47.9 26,48.4 24.3,49.2 Z'),
  (group: MuscleGroup.forearms, mirror: true, path: 'M23,66.6 C20.4,71.2 19.4,77 19.4,83.4 L19.6,90 L21.6,90 C21.8,84 23.2,77.5 26.2,70.5 C25,69.5 23.9,68.3 23,66.6 Z'),
  (group: MuscleGroup.forearms, mirror: true, path: 'M26.2,70.5 C23.2,77.5 21.8,84 21.6,90 L24.2,90 C25.9,84.2 28,77.4 29.4,68.6 C28.4,69.6 27.3,70.3 26.2,70.5 Z'),
  (group: null, mirror: true, path: 'M19.4,91.2 L24,91.2 C24.8,95.2 24,99.6 21.6,101 C19.6,100.2 18.8,95.6 19.4,91.2 Z'),
  (group: null, mirror: false, path: 'M42,84.2 C45,88 55,88 58,84.2 L60.4,88.6 L39.6,88.6 Z'),
  (group: MuscleGroup.quads, mirror: true, path: 'M38.4,88.6 C35.2,95 33.9,104 34,112 C34.1,120 35.2,125.5 37,129.5 L42.4,127.5 C40.6,125 40.3,121 40.3,116 C40.2,106 40.3,97 41.2,89 Z'),
  (group: MuscleGroup.quads, mirror: true, path: 'M41.2,89 C40.3,97 40.2,106 40.3,116 C40.3,121 40.6,125 42.4,127.5 C43.6,125.6 44.4,124.5 44.8,124.5 C45.4,117 46.3,105 46.5,92 C44.8,89.8 43,89.2 41.2,89 Z'),
  (group: MuscleGroup.quads, mirror: true, path: 'M46.4,104 C46.2,112 45.6,118.5 44.8,124.5 C45.6,127.5 46.6,129.2 47.8,129.5 C48.4,122 48.6,113 48.6,104 Z'),
  (group: MuscleGroup.quads, mirror: true, path: 'M46.5,92 C47.6,90.8 48.4,90.3 49.4,90 L49.4,98 C49.2,100.5 48.9,102.5 48.6,104 L46.4,104 C46.5,100 46.5,96 46.5,92 Z'),
  (group: null, mirror: true, path: 'M37,130 C39.5,134.5 45.5,134.5 47.8,130 L47.4,137.4 L38,137.4 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M38.3,139 C35.7,144 35.2,151 36.6,158 L39.4,153 C39.2,148 39.3,143 39.8,139 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M39.8,139 C39.3,143 39.2,148 39.4,153 C39.5,160 39.8,166 40.4,172.5 L43,172.5 C43.6,166 44,160 44.2,153 C44.3,148 44.2,143 43.8,139 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M43.8,139 C44.2,143 44.3,148 44.2,153 L45.9,158.5 C47.4,151.5 47.2,144.5 45.2,139 Z'),
  (group: null, mirror: true, path: 'M38.2,174 L44,174 L45.5,182 C42,184.5 36,184.5 33.6,182.6 Z'),
];

/// Zezadu: trapéz, zadní deltoidy, podhřebenové svaly, široké svaly zad,
/// vzpřimovače, triceps (2 hlavy), předloktí, hýžďové svaly (velký
/// a střední), hamstringy, lýtka a šikmý sval lýtka.
const List<_Part> _back = [
  (group: null, mirror: false, path: 'M50,4 C55.5,4 58.5,8.5 58.5,14 C58.5,20 55,25 50,25 C45,25 41.5,20 41.5,14 C41.5,8.5 44.5,4 50,4 Z'),
  (group: MuscleGroup.traps, mirror: false, path: 'M50,22.5 C52,25.2 55,27.6 60,30 L63.2,31.6 C59.2,33 56.6,35 54.6,38.2 L50,52.4 L45.4,38.2 C43.4,35 40.8,33 36.8,31.6 L40,30 C45,27.6 48,25.2 50,22.5 Z'),
  (group: MuscleGroup.shoulders, mirror: true, path: 'M36.4,32.4 C30,32.4 26,35.6 24.6,40.8 C24,43.6 24.4,46.2 25.2,48.2 C27,45.6 29,43.2 30.6,40.6 C32.1,37.2 34.1,35.2 37.6,34 Z'),
  (group: MuscleGroup.back, mirror: true, path: 'M38.8,35.4 C35.7,37.3 33.7,40.6 33.6,44 C36.1,45 39.6,44.6 43.1,42.2 L44.6,38.6 C42.6,37 40.7,35.8 38.8,35.4 Z'),
  (group: MuscleGroup.back, mirror: true, path: 'M43.7,43.6 C40.2,46.1 36.7,47.1 34.2,46.6 C34.2,53.2 35.6,60.2 38.6,66.2 C42.1,69.6 45.6,71 49.3,71.4 L49.3,56.2 C47.1,53.2 45.2,48.6 43.7,43.6 Z'),
  (group: MuscleGroup.lowerBack, mirror: true, path: 'M45.2,72.6 C46.6,72.6 48,72.8 49.3,73 L49.3,82.2 L45.6,81.2 C45.3,78.2 45.1,75.2 45.2,72.6 Z'),
  (group: MuscleGroup.triceps, mirror: true, path: 'M24.5,49.2 C22.5,54.2 22.5,59.6 23.8,64.6 C25,65.6 26.3,65.6 27,64.6 C27,59 27.2,53.6 28,48.2 C26.8,48.4 25.6,48.7 24.5,49.2 Z'),
  (group: MuscleGroup.triceps, mirror: true, path: 'M28.7,48 C28.1,53.6 27.9,59.1 27.9,64.6 C29.3,64.6 30.1,62.6 30.5,60.1 C31.1,55.6 31.2,51.1 30.8,47.4 Z'),
  (group: MuscleGroup.forearms, mirror: true, path: 'M23,66.6 C20.4,71.2 19.4,77 19.4,83.4 L19.6,90 L21.6,90 C21.8,84 23.2,77.5 26.2,70.5 C25,69.5 23.9,68.3 23,66.6 Z'),
  (group: MuscleGroup.forearms, mirror: true, path: 'M26.2,70.5 C23.2,77.5 21.8,84 21.6,90 L24.2,90 C25.9,84.2 28,77.4 29.4,68.6 C28.4,69.6 27.3,70.3 26.2,70.5 Z'),
  (group: null, mirror: true, path: 'M19.4,91.2 L24,91.2 C24.8,95.2 24,99.6 21.6,101 C19.6,100.2 18.8,95.6 19.4,91.2 Z'),
  (group: MuscleGroup.glutes, mirror: true, path: 'M38.2,83.2 C40.6,82.2 43,82 45,82.5 C42,83.3 39.6,84.7 37.4,87.2 C37.1,85.7 37.4,84.2 38.2,83.2 Z'),
  (group: MuscleGroup.glutes, mirror: true, path: 'M49.3,84.6 C44,83.6 39.6,84.6 37.1,88.1 C35.6,91.6 35.9,96.6 38.6,99.6 C41.6,102.1 45.6,102.6 49.3,101.6 Z'),
  (group: MuscleGroup.hamstrings, mirror: true, path: 'M37,103.4 C35.2,109 34.6,116 35,122 C35.3,125.5 35.8,127.8 36.6,129.5 L41,130.2 C40.6,121 40.9,112 42,103.6 C40.3,103.2 38.6,103.1 37,103.4 Z'),
  (group: MuscleGroup.hamstrings, mirror: true, path: 'M42,103.6 C40.9,112 40.6,121 41,130.2 L46.5,130.6 C47.6,124 48.3,117 48.4,110 L48.2,103.8 C46.2,103.4 44,103.3 42,103.6 Z'),
  (group: MuscleGroup.hamstrings, mirror: true, path: 'M48.2,103.8 L49.4,103.4 L49.4,112 C49,113.5 48.7,112 48.4,110 Z'),
  (group: null, mirror: true, path: 'M36.9,131.2 C39.1,133.2 45.1,133.7 46.6,131.7 L46.1,136.2 L37.6,136.2 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M37.1,137.2 C34.3,143.2 34.1,150.2 36.3,157.2 C37.6,159.7 39.6,160 40.9,158.2 C40.9,151.2 41.1,144.2 41.4,137.7 C40.1,137.2 38.6,137.1 37.1,137.2 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M42.1,137.5 C42,144.2 42.1,151.2 42.3,158.7 C43.6,160.7 45.6,159.7 46.4,156.7 C47.4,149.7 46.9,142.7 45.6,137.8 C44.5,137.5 43.3,137.4 42.1,137.5 Z'),
  (group: MuscleGroup.calves, mirror: true, path: 'M37.9,160.4 C38.6,164.2 39.3,167.2 39.9,170.2 L43.6,170.2 C44.1,167.2 44.9,164.2 45.4,160.8 C44.1,162.3 41.6,162.3 37.9,160.4 Z'),
  (group: null, mirror: true, path: 'M40.1,171.2 L43.4,171.2 L43.7,176.2 L39.7,176.2 Z'),
  (group: null, mirror: true, path: 'M38.1,176.8 L45.1,176.8 L45.6,182.2 C42.6,184.2 37.1,184.2 35.1,182.2 Z'),
];

final Map<String, Path> _pathCache = {};

/// Jednoduchý převod SVG cesty (jen absolutní M, L, C, Z) na [Path].
Path _parsePath(String d) => _pathCache.putIfAbsent(d, () {
      final path = Path();
      final tokens = RegExp(r'[MLCZ]|-?\d+(?:\.\d+)?')
          .allMatches(d)
          .map((m) => m.group(0)!)
          .toList();
      var i = 0;
      double next() => double.parse(tokens[i++]);
      var cmd = 'M';
      while (i < tokens.length) {
        final t = tokens[i];
        if (RegExp(r'^[MLCZ]$').hasMatch(t)) {
          cmd = t;
          i++;
          if (cmd == 'Z') {
            path.close();
            continue;
          }
        }
        switch (cmd) {
          case 'M':
            path.moveTo(next(), next());
            cmd = 'L'; // další dvojice za M jsou podle SVG čáry
          case 'L':
            path.lineTo(next(), next());
          case 'C':
            path.cubicTo(next(), next(), next(), next(), next(), next());
          default:
            i++;
        }
      }
      return path;
    });

class _BodyMapPainter extends CustomPainter {
  _BodyMapPainter({
    required this.colors,
    required this.neutral,
    required this.showFront,
    required this.showBack,
    this.crop,
  });

  final Map<MuscleGroup, Color> colors;
  final Color neutral;
  final bool showFront;
  final bool showBack;

  /// Výřez jedné postavy (souřadnice postavy) roztažený na celou plochu –
  /// pro ikonu cviku. Null = celé postavy vedle sebe.
  final Rect? crop;

  /// Barva oblasti: přesná partie, pak souhrnná (stehna → nohy), pak
  /// celé tělo, jinak neutrální.
  Color _colorOf(MuscleGroup? g) {
    if (g == null) return neutral;
    final parent = g.parent;
    return colors[g] ??
        (parent == null ? null : colors[parent]) ??
        colors[MuscleGroup.fullBody] ??
        neutral;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _figureHeight;
    final views = <List<_Part>>[
      if (showFront) _front,
      if (showBack) _back,
    ];
    // Vlastní vrstva: mezery mezi svaly se „vygumují“ (BlendMode.clear),
    // takže je vidět pozadí karty nebo dialogu.
    canvas.saveLayer(Offset.zero & size, Paint());
    final c = crop;
    final unit = c != null ? size.width / c.width : scale;
    canvas.scale(unit);
    if (c != null) canvas.translate(-c.left, -c.top);
    // Mezera mezi svaly: tenká linka, ale aspoň ~1 px i na malé ikoně.
    final gapWidth = math.max(0.6, 1.0 / unit);
    final fill = Paint()..style = PaintingStyle.fill;
    final gap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gapWidth
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear;
    for (var v = 0; v < views.length; v++) {
      final parts = views[v];
      canvas.save();
      canvas.translate(v * _figureWidth, 0);
      for (final part in parts) {
        fill.color = _colorOf(part.group);
        final path = _parsePath(part.path);
        canvas.drawPath(path, fill);
        if (part.mirror) {
          canvas.save();
          canvas.translate(_figureWidth, 0);
          canvas.scale(-1, 1);
          canvas.drawPath(path, fill);
          canvas.restore();
        }
      }
      for (final part in parts) {
        final path = _parsePath(part.path);
        canvas.drawPath(path, gap);
        if (part.mirror) {
          canvas.save();
          canvas.translate(_figureWidth, 0);
          canvas.scale(-1, 1);
          canvas.drawPath(path, gap);
          canvas.restore();
        }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter old) =>
      old.neutral != neutral ||
      old.showFront != showFront ||
      old.showBack != showBack ||
      old.crop != crop ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(Map<MuscleGroup, Color> a, Map<MuscleGroup, Color> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
