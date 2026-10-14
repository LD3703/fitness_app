import 'package:flutter/material.dart';

/// Ikona GymBar (logo varianta 1 – „stupňovaná činka“) kreslená přímo,
/// bez obrázku. Stejné souřadnice jako assets/branding/logo.svg (0–100).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GymBar',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _BrandMarkPainter(),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  static const _teal = Color(0xFF2E7D6B);
  static const _amber = Color(0xFFFFC857);
  static const _white = Color(0xFFFFFFFF);

  // x, y, šířka, výška – kotouče rostou zleva doprava, nejtěžší je žlutý.
  static const _plates = [
    (20.0, 41.0, 8.0, 18.0, _white),
    (31.0, 35.0, 8.0, 30.0, _white),
    (61.0, 29.0, 8.0, 42.0, _white),
    (72.0, 23.0, 8.0, 54.0, _amber),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 100;
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x * u, y * u, w * u, h * u), Radius.circular(r * u));

    canvas.drawRRect(rr(0, 0, 100, 100, 22), Paint()..color = _teal);
    // Osa činky: 12–88 s kulatými konci, tloušťka 5.
    canvas.drawRRect(rr(9.5, 47.5, 81, 5, 2.5), Paint()..color = _white);
    for (final (x, y, w, h, color) in _plates) {
      canvas.drawRRect(rr(x, y, w, h, 3), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Název „GymBar“ jako v logu: „Gym“ v barvě textu, „Bar“ zvýrazněné
/// (teal na světlém pozadí, žlutá na tmavém).
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 18,
    this.color,
    this.barColor,
  });

  final double fontSize;

  /// Barva „Gym“; výchozí je barva okolního textu.
  final Color? color;

  /// Barva „Bar“; výchozí je primární barva motivu.
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: 'Gym'),
        TextSpan(
          text: 'Bar',
          style: TextStyle(
              color: barColor ?? Theme.of(context).colorScheme.primary),
        ),
      ]),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * fontSize,
        color: color,
      ),
    );
  }
}
