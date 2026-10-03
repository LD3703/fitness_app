import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Jedna datová řada grafu.
class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.color,
    this.showLine = true,
    this.showDots = true,
  });

  final List<({DateTime x, double y})> points;
  final Color color;
  final bool showLine;
  final bool showDots;
}

/// Barevný pruh na pozadí (období nemoci, diety…).
class ChartBand {
  const ChartBand(this.start, this.end, this.color);

  final DateTime start;
  final DateTime end;
  final Color color;
}

/// Jednoduchý čárový graf v čase s pruhy období na pozadí.
/// Klepnutím nebo tažením se zobrazí hodnota nejbližšího bodu.
class TimeSeriesChart extends StatefulWidget {
  const TimeSeriesChart({
    super.key,
    required this.series,
    this.bands = const [],
    required this.formatY,
    this.height = 200,
    this.primaryIndex = 0,
  });

  final List<ChartSeries> series;
  final List<ChartBand> bands;
  final String Function(double) formatY;
  final double height;

  /// Řada, jejíž hodnota se ukáže po klepnutí.
  final int primaryIndex;

  @override
  State<TimeSeriesChart> createState() => _TimeSeriesChartState();
}

class _TimeSeriesChartState extends State<TimeSeriesChart> {
  int? _selected;

  void _select(Offset pos, Size size) {
    final pts = widget.series[widget.primaryIndex].points;
    if (pts.isEmpty) return;
    final layout = _ChartLayout.of(widget, size);
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < pts.length; i++) {
      final d = (layout.xFor(pts[i].x) - pos.dx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    setState(() => _selected = best);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, widget.height);
          return GestureDetector(
            onTapDown: (d) => _select(d.localPosition, size),
            onHorizontalDragUpdate: (d) => _select(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _TimeSeriesPainter(
                chart: widget,
                selected: _selected,
                gridColor: theme.colorScheme.outlineVariant,
                labelStyle: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltipBg: theme.colorScheme.inverseSurface,
                tooltipStyle: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
                surface: theme.colorScheme.surface,
                dateFormat: DateFormat.MMMd(locale),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Přepočet dat na souřadnice (sdílí kreslení i výběr bodu).
class _ChartLayout {
  _ChartLayout(this.plot, this.minX, this.maxX, this.minY, this.maxY);

  factory _ChartLayout.of(TimeSeriesChart chart, Size size) {
    final all = [for (final s in chart.series) ...s.points];
    var minX = all.map((p) => p.x).reduce((a, b) => a.isBefore(b) ? a : b);
    var maxX = all.map((p) => p.x).reduce((a, b) => a.isAfter(b) ? a : b);
    if (!maxX.isAfter(minX)) {
      minX = minX.subtract(const Duration(days: 1));
      maxX = maxX.add(const Duration(days: 1));
    }
    var minY = all.map((p) => p.y).reduce(math.min);
    var maxY = all.map((p) => p.y).reduce(math.max);
    final pad = maxY > minY ? (maxY - minY) * 0.15 : math.max(1.0, maxY.abs() * 0.05);
    minY -= pad;
    maxY += pad;
    const left = 44.0, right = 8.0, top = 12.0, bottom = 22.0;
    return _ChartLayout(
      Rect.fromLTRB(left, top, size.width - right, size.height - bottom),
      minX,
      maxX,
      minY,
      maxY,
    );
  }

  final Rect plot;
  final DateTime minX;
  final DateTime maxX;
  final double minY;
  final double maxY;

  double xFor(DateTime x) {
    final span = maxX.difference(minX).inMilliseconds;
    final t = x.difference(minX).inMilliseconds / span;
    return plot.left + t.clamp(0.0, 1.0) * plot.width;
  }

  double yFor(double y) =>
      plot.bottom - (y - minY) / (maxY - minY) * plot.height;
}

class _TimeSeriesPainter extends CustomPainter {
  _TimeSeriesPainter({
    required this.chart,
    required this.selected,
    required this.gridColor,
    required this.labelStyle,
    required this.tooltipBg,
    required this.tooltipStyle,
    required this.surface,
    required this.dateFormat,
  });

  final TimeSeriesChart chart;
  final int? selected;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color tooltipBg;
  final TextStyle tooltipStyle;
  final Color surface;
  final DateFormat dateFormat;

  void _text(Canvas canvas, String text, Offset at, TextStyle style,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.center => at.dx - tp.width / 2,
      TextAlign.right => at.dx - tp.width,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (chart.series.every((s) => s.points.isEmpty)) return;
    final l = _ChartLayout.of(chart, size);
    final plot = l.plot;

    // Pruhy období
    for (final b in chart.bands) {
      if (b.end.isBefore(l.minX) || b.start.isAfter(l.maxX)) continue;
      final x1 = l.xFor(b.start.isBefore(l.minX) ? l.minX : b.start);
      final x2 = l.xFor(b.end.isAfter(l.maxX) ? l.maxX : b.end);
      canvas.drawRect(
        Rect.fromLTRB(x1, plot.top, math.max(x2, x1 + 2), plot.bottom),
        Paint()..color = b.color,
      );
    }

    // Mřížka a popisky osy Y
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final v = l.minY + (l.maxY - l.minY) * i / 2;
      final y = l.yFor(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, chart.formatY(v), Offset(plot.left - 6, y), labelStyle,
          align: TextAlign.right);
    }

    // Popisky osy X: začátek a konec
    final xLabelY = plot.bottom + 12;
    _text(canvas, dateFormat.format(l.minX), Offset(plot.left, xLabelY),
        labelStyle);
    _text(canvas, dateFormat.format(l.maxX), Offset(plot.right, xLabelY),
        labelStyle,
        align: TextAlign.right);

    // Řady
    for (final s in chart.series) {
      if (s.points.isEmpty) continue;
      if (s.showLine && s.points.length > 1) {
        final path = Path()
          ..moveTo(l.xFor(s.points.first.x), l.yFor(s.points.first.y));
        for (final p in s.points.skip(1)) {
          path.lineTo(l.xFor(p.x), l.yFor(p.y));
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      }
      if (s.showDots) {
        for (final p in s.points) {
          final c = Offset(l.xFor(p.x), l.yFor(p.y));
          canvas.drawCircle(c, 4.5, Paint()..color = surface);
          canvas.drawCircle(c, 3, Paint()..color = s.color);
        }
      }
    }

    // Vybraný bod
    final pts = chart.series[chart.primaryIndex].points;
    final sel = selected;
    if (sel != null && sel < pts.length) {
      final p = pts[sel];
      final c = Offset(l.xFor(p.x), l.yFor(p.y));
      canvas.drawLine(Offset(c.dx, plot.top), Offset(c.dx, plot.bottom),
          grid..strokeWidth = 1);
      canvas.drawCircle(c, 6, Paint()..color = surface);
      canvas.drawCircle(
          c, 5, Paint()..color = chart.series[chart.primaryIndex].color);
      final label = '${dateFormat.format(p.x)}: ${chart.formatY(p.y)}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: tooltipStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = tp.width + 12, h = tp.height + 8;
      final maxLeft = math.max(plot.left, plot.right - w);
      final left = (c.dx - w / 2).clamp(plot.left, maxLeft);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, plot.top, w, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = tooltipBg);
      tp.paint(canvas, Offset(left + 6, plot.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter old) =>
      old.chart != chart || old.selected != selected || old.surface != surface;
}

/// Sloupcový graf (např. počet tréninků po týdnech).
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.tooltip,
    this.height = 140,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;

  /// Text bubliny po klepnutí na sloupec.
  final String Function(int index) tooltip;
  final double height;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = math.max(1, widget.values.fold<int>(0, math.max));
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 20,
          child: sel == null
              ? null
              : Text(
                  widget.tooltip(sel),
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
        ),
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.values.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: math.max(
                                2.0, widget.height * widget.values[i] / maxV),
                            decoration: BoxDecoration(
                              color: widget.values[i] == 0
                                  ? theme.colorScheme.outlineVariant
                                  : (sel == i
                                      ? widget.color
                                      : widget.color.withValues(alpha: 0.75)),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(widget.labels.first,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text(widget.labels.last,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
