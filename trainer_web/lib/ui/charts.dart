// Jednoduché grafy bez knihoven: sloupcový (týdny) a čárový (vývoj váhy).
// Najetí myší / klepnutí ukáže hodnotu bodu.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

typedef ValueFormat = String Function(double v);

/// Hezké zaokrouhlení kroku osy (1, 2, 2.5, 5 × 10^n).
double _niceStep(double range, int ticks) {
  if (range <= 0) return 1;
  final raw = range / ticks;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (raw <= m * mag) return m * mag;
  }
  return 10 * mag;
}

class _Colors {
  _Colors(ThemeData t)
      : line = t.colorScheme.primary,
        grid = t.colorScheme.outlineVariant.withValues(alpha: 0.6),
        text = t.colorScheme.onSurfaceVariant,
        surface = t.colorScheme.surface,
        tooltipBg = t.colorScheme.inverseSurface,
        tooltipText = t.colorScheme.onInverseSurface;

  final Color line;
  final Color grid;
  final Color text;
  final Color surface;
  final Color tooltipBg;
  final Color tooltipText;
}

void _paintText(Canvas canvas, String text, Offset at, TextStyle style,
    {TextAlign align = TextAlign.left, bool above = false}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  var dx = at.dx;
  if (align == TextAlign.center) dx -= tp.width / 2;
  if (align == TextAlign.right) dx -= tp.width;
  tp.paint(canvas, Offset(dx, above ? at.dy - tp.height : at.dy - tp.height / 2));
}

void _paintTooltip(Canvas canvas, Size size, Offset anchor, List<String> lines,
    _Colors c, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
            text: lines.first,
            style: style.copyWith(
                color: c.tooltipText, fontWeight: FontWeight.w600)),
        for (final l in lines.skip(1))
          TextSpan(text: '\n$l', style: style.copyWith(color: c.tooltipText)),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const pad = 8.0;
  final w = tp.width + pad * 2;
  final h = tp.height + pad * 2;
  var left = anchor.dx + 10;
  if (left + w > size.width) left = anchor.dx - 10 - w;
  final top = (anchor.dy - h - 10).clamp(0.0, math.max(0.0, size.height - h));
  final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(math.max(0.0, left), top, w, h), const Radius.circular(6));
  canvas.drawRRect(r, Paint()..color = c.tooltipBg);
  tp.paint(canvas, Offset(r.left + pad, r.top + pad));
}

// ---------------------------------------------------------------------------
// Sloupce
// ---------------------------------------------------------------------------

class BarDatum {
  const BarDatum(this.label, this.value, {this.tooltip});

  final String label;
  final double value;
  final String? tooltip;
}

class BarChart extends StatefulWidget {
  const BarChart({
    super.key,
    required this.bars,
    required this.format,
    this.height = 180,
  });

  final List<BarDatum> bars;
  final ValueFormat format;
  final double height;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  int? _hover;

  int? _indexAt(Offset p, double width) {
    if (widget.bars.isEmpty) return null;
    final slot = (width - _BarPainter.leftAxis) / widget.bars.length;
    final i = ((p.dx - _BarPainter.leftAxis) / slot).floor();
    return i < 0 || i >= widget.bars.length ? null : i;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return LayoutBuilder(
      builder: (context, box) => MouseRegion(
        onHover: (e) => setState(() => _hover = _indexAt(e.localPosition, box.maxWidth)),
        onExit: (_) => setState(() => _hover = null),
        child: GestureDetector(
          onTapDown: (e) =>
              setState(() => _hover = _indexAt(e.localPosition, box.maxWidth)),
          child: SizedBox(
            height: widget.height,
            width: box.maxWidth,
            child: CustomPaint(
              painter: _BarPainter(
                bars: widget.bars,
                format: widget.format,
                hover: _hover,
                colors: _Colors(theme),
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bars,
    required this.format,
    required this.hover,
    required this.colors,
    required this.style,
  });

  static const leftAxis = 40.0;
  static const bottomAxis = 20.0;

  final List<BarDatum> bars;
  final ValueFormat format;
  final int? hover;
  final _Colors colors;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final textStyle = style.copyWith(color: colors.text);
    final plotH = size.height - bottomAxis - 8;
    final maxV = bars.fold<double>(0, (m, b) => math.max(m, b.value));
    final step = _niceStep(maxV == 0 ? 1 : maxV, 3);
    final top = math.max(step, (maxV / step).ceil() * step);
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    for (var v = 0.0; v <= top + step / 2; v += step) {
      final y = 8 + plotH - plotH * v / top;
      canvas.drawLine(Offset(leftAxis, y), Offset(size.width, y), grid);
      _paintText(canvas, format(v), Offset(leftAxis - 6, y), textStyle,
          align: TextAlign.right);
    }
    final slot = (size.width - leftAxis) / bars.length;
    final barW = math.min(28.0, slot * 0.6);
    final labelEvery = (bars.length / 6).ceil();
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final h = plotH * b.value / top;
      final cx = leftAxis + slot * i + slot / 2;
      if (b.value > 0) {
        final paint = Paint()
          ..color = hover == null || hover == i
              ? colors.line
              : colors.line.withValues(alpha: 0.45);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, 8 + plotH - h, barW, h),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          paint,
        );
      }
      if (i % labelEvery == 0 || i == bars.length - 1) {
        _paintText(canvas, b.label, Offset(cx, size.height - 4), textStyle,
            align: TextAlign.center, above: true);
      }
    }
    final h = hover;
    if (h != null && h < bars.length) {
      final b = bars[h];
      final cx = leftAxis + slot * h + slot / 2;
      final y = 8 + plotH - plotH * b.value / top;
      _paintTooltip(canvas, size, Offset(cx, y),
          [b.tooltip ?? b.label, format(b.value)], colors, style);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.bars != bars || old.hover != hover || old.colors.line != colors.line;
}

// ---------------------------------------------------------------------------
// Čára v čase
// ---------------------------------------------------------------------------

class LinePoint {
  const LinePoint(this.date, this.value);

  final DateTime date;
  final double value;
}

class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
    required this.points,
    required this.format,
    required this.locale,
    this.height = 200,
  });

  final List<LinePoint> points;
  final ValueFormat format;
  final String locale;
  final double height;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  int? _hover;

  int? _nearest(Offset p, Size size) {
    final pts = widget.points;
    if (pts.isEmpty) return null;
    final xs = _LinePainter.xPositions(pts, size);
    var best = 0;
    for (var i = 1; i < xs.length; i++) {
      if ((xs[i] - p.dx).abs() < (xs[best] - p.dx).abs()) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, widget.height);
      return MouseRegion(
        onHover: (e) => setState(() => _hover = _nearest(e.localPosition, size)),
        onExit: (_) => setState(() => _hover = null),
        child: GestureDetector(
          onTapDown: (e) => setState(() => _hover = _nearest(e.localPosition, size)),
          child: SizedBox.fromSize(
            size: size,
            child: CustomPaint(
              painter: _LinePainter(
                points: widget.points,
                format: widget.format,
                dateFormat: DateFormat.yMd(widget.locale),
                axisFormat: DateFormat.MMMd(widget.locale),
                hover: _hover,
                colors: _Colors(theme),
                style: style,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.format,
    required this.dateFormat,
    required this.axisFormat,
    required this.hover,
    required this.colors,
    required this.style,
  });

  static const leftAxis = 44.0;
  static const rightPad = 12.0;
  static const bottomAxis = 20.0;

  final List<LinePoint> points;
  final ValueFormat format;
  final DateFormat dateFormat;
  final DateFormat axisFormat;
  final int? hover;
  final _Colors colors;
  final TextStyle style;

  static List<double> xPositions(List<LinePoint> pts, Size size) {
    final w = size.width - leftAxis - rightPad;
    if (pts.length == 1) return [leftAxis + w / 2];
    final t0 = pts.first.date.millisecondsSinceEpoch.toDouble();
    final t1 = pts.last.date.millisecondsSinceEpoch.toDouble();
    final span = math.max(1.0, t1 - t0);
    return [
      for (final p in pts)
        leftAxis + w * (p.date.millisecondsSinceEpoch - t0) / span,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final textStyle = style.copyWith(color: colors.text);
    const plotTop = 8.0;
    final plotH = size.height - bottomAxis - plotTop;
    var lo = points.map((p) => p.value).reduce(math.min);
    var hi = points.map((p) => p.value).reduce(math.max);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    final step = _niceStep(hi - lo, 3);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;
    double y(double v) => plotTop + plotH - plotH * (v - lo) / (hi - lo);

    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    for (var v = lo; v <= hi + step / 2; v += step) {
      canvas.drawLine(Offset(leftAxis, y(v)), Offset(size.width - rightPad, y(v)), grid);
      _paintText(canvas, format(v), Offset(leftAxis - 6, y(v)), textStyle,
          align: TextAlign.right);
    }

    final xs = xPositions(points, size);
    final path = Path()..moveTo(xs.first, y(points.first.value));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(xs[i], y(points[i].value));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    if (points.length <= 40) {
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(Offset(xs[i], y(points[i].value)), 3.5,
            Paint()..color = colors.line);
      }
    }

    _paintText(canvas, axisFormat.format(points.first.date),
        Offset(xs.first, size.height - 2), textStyle,
        align: points.length == 1 ? TextAlign.center : TextAlign.left,
        above: true);
    if (points.length > 1) {
      _paintText(canvas, axisFormat.format(points.last.date),
          Offset(xs.last, size.height - 2), textStyle,
          align: TextAlign.right, above: true);
    }

    final h = hover;
    if (h != null && h < points.length) {
      final p = Offset(xs[h], y(points[h].value));
      canvas.drawLine(Offset(p.dx, plotTop), Offset(p.dx, plotTop + plotH),
          Paint()
            ..color = colors.text.withValues(alpha: 0.5)
            ..strokeWidth = 1);
      canvas.drawCircle(p, 6, Paint()..color = colors.surface);
      canvas.drawCircle(p, 4.5, Paint()..color = colors.line);
      _paintTooltip(canvas, size, p,
          [dateFormat.format(points[h].date), format(points[h].value)], colors, style);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.hover != hover || old.colors.line != colors.line;
}
