// Motivy vzhledu (šablony „GymBar – šablony vzhledu“, docs/skins.md):
// Klasik (výchozí), Květy, Lebky, Neon, Retro gym, Y2K samolepky a Původní
// (dřívější teal vzhled se světlým/tmavým režimem podle nastavení).
//
// Každý motiv má pevné barvy, písma (assets/fonts/skins/, OFL), zaoblení
// a ozdobu záhlaví na obrazovce Dnes (SkinHeaderMotif). Vybírá se v Profilu
// (UserProfile.skin, klíč AppSkin.key).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum AppSkin {
  classic('classic'),
  flowers('flowers'),
  skulls('skulls'),
  neon('neon'),
  retro('retro'),
  y2k('y2k'),

  /// Dřívější vzhled (teal z loga), světlý / tmavý podle nastavení.
  original('original');

  const AppSkin(this.key);

  /// Hodnota v databázi (UserProfile.skin).
  final String key;

  /// Motiv z databáze; neznámý nebo prázdný = Klasik (výchozí).
  static AppSkin fromKey(String? key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return AppSkin.classic;
  }
}

/// Rodiny písem motivů (pubspec.yaml) – licence v O aplikaci.
const kSkinFontFamilies = [
  'Archivo',
  'ArchivoBlack',
  'Fraunces',
  'Nunito',
  'BebasNeue',
  'Barlow',
  'Oxanium',
  'SpaceGrotesk',
  'AlfaSlabOne',
  'WorkSans',
  'Unbounded',
  'DMSans',
];

/// Barvy a tvary jednoho motivu (podle šablon).
class SkinSpec {
  const SkinSpec({
    required this.brightness,
    required this.background,
    required this.header,
    required this.onHeader,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.onTertiary,
    required this.nav,
    required this.radius,
    required this.buttonRadius,
    required this.displayFont,
    required this.bodyFont,
    this.displayWeight = FontWeight.w700,
    this.displayScale = 1,
    this.displayLetterSpacing,
    this.borderWidth = 1,
    this.glow,
    this.headerLine,
  });

  final Brightness brightness;
  final Color background;
  final Color header;
  final Color onHeader;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;

  /// Rekordy, odznaky, výzvy (ColorScheme.tertiary).
  final Color tertiary;
  final Color onTertiary;
  final Color nav;

  /// Zaoblení karet a tlačítek (999 = „pilulka“).
  final double radius;
  final double buttonRadius;

  final String displayFont;
  final String bodyFont;
  final FontWeight displayWeight;

  /// Úzká písma (Bebas Neue) potřebují větší velikost nadpisů.
  final double displayScale;
  final double? displayLetterSpacing;
  final double borderWidth;

  /// Záře kolem karet (Neon).
  final Color? glow;

  /// Čára pod záhlavím (Lebky – červená, Klasik – jemná).
  final BorderSide? headerLine;

  bool get dark => brightness == Brightness.dark;
}

const _classic = SkinSpec(
  brightness: Brightness.dark,
  background: Color(0xFF111111),
  header: Color(0xFF111111),
  onHeader: Color(0xFFF3F1EC),
  card: Color(0xFF1D1D1D),
  border: Color(0xFF2C2C2C),
  text: Color(0xFFF3F1EC),
  muted: Color(0xFFA8A49B),
  primary: Color(0xFFC8F03C),
  onPrimary: Color(0xFF111111),
  secondary: Color(0xFFC8F03C),
  onSecondary: Color(0xFF111111),
  tertiary: Color(0xFFC8F03C),
  onTertiary: Color(0xFF111111),
  nav: Color(0xFF161616),
  radius: 16,
  buttonRadius: 12,
  displayFont: 'ArchivoBlack',
  bodyFont: 'Archivo',
  displayWeight: FontWeight.w400,
  headerLine: BorderSide(color: Color(0xFF2C2C2C)),
);

const _flowers = SkinSpec(
  brightness: Brightness.light,
  background: Color(0xFFFFF7F4),
  header: Color(0xFFFBE4EC),
  onHeader: Color(0xFF3A2530),
  card: Color(0xFFFFFFFF),
  border: Color(0xFFF1D9E1),
  text: Color(0xFF3A2530),
  muted: Color(0xFF7A5F6A),
  primary: Color(0xFFC2336A),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF8E6CCF),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFF6E4DB8),
  onTertiary: Color(0xFFFFFFFF),
  nav: Color(0xFFFFFFFF),
  radius: 24,
  buttonRadius: 999,
  displayFont: 'Fraunces',
  bodyFont: 'Nunito',
  displayWeight: FontWeight.w600,
);

const _skulls = SkinSpec(
  brightness: Brightness.dark,
  background: Color(0xFF0A0A0A),
  header: Color(0xFF141414),
  onHeader: Color(0xFFEDEDED),
  card: Color(0xFF161616),
  border: Color(0xFF2A2A2A),
  text: Color(0xFFEDEDED),
  muted: Color(0xFF9C9C9C),
  primary: Color(0xFFD62B1A),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFFF5A47),
  onSecondary: Color(0xFF0A0A0A),
  tertiary: Color(0xFFFF5A47),
  onTertiary: Color(0xFF0A0A0A),
  nav: Color(0xFF0A0A0A),
  radius: 2,
  buttonRadius: 2,
  displayFont: 'BebasNeue',
  bodyFont: 'Barlow',
  displayWeight: FontWeight.w400,
  displayScale: 1.3,
  displayLetterSpacing: 1,
  headerLine: BorderSide(color: Color(0xFFD62B1A), width: 4),
);

const _neon = SkinSpec(
  brightness: Brightness.dark,
  background: Color(0xFF0D0A1E),
  header: Color(0xFF0D0A1E),
  onHeader: Color(0xFFF2EEFF),
  card: Color(0xFF19143A),
  border: Color(0xFF2E2763),
  text: Color(0xFFF2EEFF),
  muted: Color(0xFFA99FD6),
  primary: Color(0xFF22E3F0),
  onPrimary: Color(0xFF0D0A1E),
  secondary: Color(0xFFFF4FD8),
  onSecondary: Color(0xFF0D0A1E),
  tertiary: Color(0xFFFF4FD8),
  onTertiary: Color(0xFF0D0A1E),
  nav: Color(0xFF0D0A1E),
  radius: 14,
  buttonRadius: 10,
  displayFont: 'Oxanium',
  bodyFont: 'SpaceGrotesk',
  displayWeight: FontWeight.w800,
  glow: Color(0xFF22E3F0),
);

const _retro = SkinSpec(
  brightness: Brightness.light,
  background: Color(0xFFF1E6D0),
  header: Color(0xFF8C2F1B),
  onHeader: Color(0xFFFFF4DE),
  card: Color(0xFFFFF9EE),
  border: Color(0xFF2B1D14),
  text: Color(0xFF2B1D14),
  muted: Color(0xFF6B5644),
  primary: Color(0xFF8C2F1B),
  onPrimary: Color(0xFFFFF4DE),
  secondary: Color(0xFFE0A526),
  onSecondary: Color(0xFF2B1D14),
  tertiary: Color(0xFF2F6F73),
  onTertiary: Color(0xFFFFF4DE),
  nav: Color(0xFFFFF9EE),
  radius: 8,
  buttonRadius: 6,
  displayFont: 'AlfaSlabOne',
  bodyFont: 'WorkSans',
  displayWeight: FontWeight.w400,
  borderWidth: 2,
);

const _y2k = SkinSpec(
  brightness: Brightness.light,
  background: Color(0xFFE3E8FF),
  header: Color(0xFFE3E8FF),
  onHeader: Color(0xFF1B1446),
  card: Color(0xFFFFFFFF),
  border: Color(0xFF1B1446),
  text: Color(0xFF1B1446),
  muted: Color(0xFF4A4370),
  primary: Color(0xFF3A5BFF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFFF3EA5),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFFD1006F),
  onTertiary: Color(0xFFFFFFFF),
  nav: Color(0xFFFFFFFF),
  radius: 22,
  buttonRadius: 999,
  displayFont: 'Unbounded',
  bodyFont: 'DMSans',
  displayWeight: FontWeight.w800,
  borderWidth: 2,
);

/// Barvy a tvary motivu; Původní nemá pevné barvy (null).
SkinSpec? skinSpec(AppSkin skin) => switch (skin) {
      AppSkin.classic => _classic,
      AppSkin.flowers => _flowers,
      AppSkin.skulls => _skulls,
      AppSkin.neon => _neon,
      AppSkin.retro => _retro,
      AppSkin.y2k => _y2k,
      AppSkin.original => null,
    };

/// Téma aplikace pro motiv. Původní: světlé nebo tmavé podle [brightness].
ThemeData skinTheme(AppSkin skin, {Brightness brightness = Brightness.light}) {
  final s = skinSpec(skin);
  if (s == null) {
    return brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
  }
  return buildSkinTheme(s);
}

Color _mix(Color top, double alpha, Color under) =>
    Color.alphaBlend(top.withValues(alpha: alpha), under);

/// Styl textového tlačítka v záhlaví (AppBar.actions). Téma TextButton
/// počítá s pozadím obrazovky; když má motiv záhlaví jiné barvy (Retro),
/// tlačítko převezme barvu písma záhlaví. Jinak null = výchozí styl.
ButtonStyle? headerTextButtonStyle(BuildContext context) {
  final t = Theme.of(context);
  final header = t.appBarTheme.backgroundColor;
  final fg = t.appBarTheme.foregroundColor;
  if (header == null || fg == null || header == t.scaffoldBackgroundColor) {
    return null;
  }
  return TextButton.styleFrom(foregroundColor: fg);
}

ThemeData buildSkinTheme(SkinSpec s) {
  final cardHigh = _mix(s.text, s.dark ? 0.06 : 0.04, s.card);
  final scheme = ColorScheme.fromSeed(
    seedColor: s.primary,
    brightness: s.brightness,
  ).copyWith(
    primary: s.primary,
    onPrimary: s.onPrimary,
    primaryContainer: _mix(s.primary, 0.22, s.card),
    onPrimaryContainer: s.text,
    secondary: s.secondary,
    onSecondary: s.onSecondary,
    secondaryContainer: _mix(s.secondary, 0.24, s.card),
    onSecondaryContainer: s.text,
    tertiary: s.tertiary,
    onTertiary: s.onTertiary,
    tertiaryContainer: _mix(s.tertiary, 0.2, s.card),
    onTertiaryContainer: s.text,
    surface: s.background,
    onSurface: s.text,
    onSurfaceVariant: s.muted,
    surfaceContainerLowest: s.card,
    surfaceContainerLow: s.card,
    surfaceContainer: s.card,
    surfaceContainerHigh: cardHigh,
    surfaceContainerHighest: _mix(s.text, s.dark ? 0.1 : 0.07, s.card),
    surfaceTint: Colors.transparent,
    outline: s.dark ? s.muted : s.border,
    outlineVariant: s.border,
    inverseSurface: s.text,
    onInverseSurface: s.background,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme)
      .textTheme
      .apply(fontFamily: s.bodyFont, bodyColor: s.text, displayColor: s.text);
  TextStyle? display(TextStyle? t) => t?.copyWith(
        fontFamily: s.displayFont,
        fontWeight: s.displayWeight,
        fontSize: t.fontSize == null ? null : t.fontSize! * s.displayScale,
        letterSpacing: s.displayLetterSpacing,
      );
  final text = base.copyWith(
    displayLarge: display(base.displayLarge),
    displayMedium: display(base.displayMedium),
    displaySmall: display(base.displaySmall),
    headlineLarge: display(base.headlineLarge),
    headlineMedium: display(base.headlineMedium),
    headlineSmall: display(base.headlineSmall),
    titleLarge: display(base.titleLarge),
  );

  final radius = BorderRadius.circular(s.radius);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(s.buttonRadius),
    side: s.borderWidth > 1
        ? BorderSide(color: s.border, width: s.borderWidth)
        : BorderSide.none,
  );
  final outlinedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(s.buttonRadius),
  );
  final buttonText = TextStyle(
    fontFamily: s.bodyFont,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: s.background,
    appBarTheme: AppBarTheme(
      backgroundColor: s.header,
      foregroundColor: s.onHeader,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge?.copyWith(color: s.onHeader),
      iconTheme: IconThemeData(color: s.onHeader),
      actionsIconTheme: IconThemeData(color: s.onHeader),
      shape: s.headerLine == null ? null : Border(bottom: s.headerLine!),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: s.card,
      elevation: s.glow == null ? 0 : 3,
      shadowColor: s.glow?.withValues(alpha: 0.45),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: s.border, width: s.borderWidth),
      ),
    ),
    // Jediný TabBar v aplikaci je v záhlaví (Přátelé) → barvy záhlaví.
    tabBarTheme: TabBarThemeData(
      labelColor: s.onHeader,
      unselectedLabelColor: s.onHeader.withValues(alpha: 0.72),
      indicatorColor: s.onHeader,
      dividerColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: s.nav,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _mix(s.primary, s.dark ? 0.25 : 0.2, s.nav),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: s.bodyFont, fontSize: 12, fontWeight: FontWeight.w600, color: s.text),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: buttonShape, textStyle: buttonText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: buttonShape, textStyle: buttonText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: outlinedShape,
        textStyle: buttonText,
        side: BorderSide(color: s.dark ? s.muted : s.border, width: s.borderWidth),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: buttonText,
        foregroundColor: s.dark ? s.primary : (s.borderWidth > 1 ? s.text : s.primary),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: s.primary,
      foregroundColor: s.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.min(s.radius, 28)),
        side: s.borderWidth > 1
            ? BorderSide(color: s.border, width: s.borderWidth)
            : BorderSide.none,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.min(s.radius, 12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: s.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(math.max(s.radius, 4))),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: s.card,
      surfaceTintColor: Colors.transparent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: s.primary,
      linearTrackColor: s.border,
    ),
    dividerTheme: DividerThemeData(color: s.border),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(math.min(s.radius, 14))),
    ),
  );
}

// ---------------------------------------------------------------------------
// Ozdoba záhlaví (obrazovka Dnes)
// ---------------------------------------------------------------------------

/// Vzor motivu za záhlavím (AppBar.flexibleSpace na obrazovce Dnes).
class SkinHeaderMotif extends StatelessWidget {
  const SkinHeaderMotif({super.key, required this.skin});

  final AppSkin skin;

  @override
  Widget build(BuildContext context) {
    if (skinSpec(skin) == null) return const SizedBox.shrink();
    return ClipRect(
      child: CustomPaint(
        painter: SkinMotifPainter(skin),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class SkinMotifPainter extends CustomPainter {
  SkinMotifPainter(this.skin);

  final AppSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    switch (skin) {
      case AppSkin.classic:
        _dumbbells(canvas, size);
      case AppSkin.flowers:
        _flowers(canvas, size);
      case AppSkin.skulls:
        _skulls(canvas, size);
      case AppSkin.neon:
        _synthwave(canvas, size);
      case AppSkin.retro:
        _retro(canvas, size);
      case AppSkin.y2k:
        _stickers(canvas, size);
      case AppSkin.original:
        break;
    }
  }

  @override
  bool shouldRepaint(SkinMotifPainter old) => old.skin != skin;

  /// Klasik: drobné činky v mřížce pootočené o −18°.
  static void _dumbbells(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8F03C).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.rotate(-18 * math.pi / 180);
    for (var y = -size.width; y < size.height + size.width; y += 44) {
      for (var x = -size.width; x < size.width * 1.5; x += 64) {
        final o = Offset(x, y);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + 8, o.dy + 12, 5, 20), const Radius.circular(1)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + 14, o.dy + 16, 4, 12), const Radius.circular(1)), paint);
        canvas.drawLine(o + const Offset(18, 22), o + const Offset(40, 22), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + 40, o.dy + 16, 4, 12), const Radius.circular(1)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + 45, o.dy + 12, 5, 20), const Radius.circular(1)), paint);
      }
    }
    canvas.restore();
  }

  /// Kytička s pěti okvětními lístky.
  static void flower(Canvas canvas, Offset c, double scale, Color petal, Color middle) {
    final p = Paint()..color = petal;
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 72 * math.pi / 180);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -7 * scale), width: 8 * scale, height: 14 * scale), p);
      canvas.restore();
    }
    canvas.drawCircle(c, 3.5 * scale, Paint()..color = middle);
  }

  static void _flowers(Canvas canvas, Size size) {
    const pink = Color(0x8CE68AAE);
    const lilac = Color(0x99B9A3E3);
    const gold = Color(0xE6F6C453);
    const leaf = Color(0xB39CC7A4);
    for (var y = 0.0; y < size.height + 76; y += 76) {
      for (var x = 0.0; x < size.width + 84; x += 84) {
        flower(canvas, Offset(x + 20, y + 20), 1, pink, gold);
        flower(canvas, Offset(x + 62, y + 54), 0.75, lilac, const Color(0xFFFFF7F4));
        canvas.drawCircle(Offset(x + 58, y + 16), 2.5, Paint()..color = leaf);
        canvas.drawCircle(Offset(x + 22, y + 58), 2, Paint()..color = leaf);
      }
    }
  }

  /// Lebka (24 × 24) v bodě [o] v měřítku [scale].
  static void skull(Canvas canvas, Offset o, double scale, Color fill, Color holes) {
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.scale(scale);
    final head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 11), radius: 9))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6.5, 14, 11, 7), const Radius.circular(1.5)));
    canvas.drawPath(head, Paint()..color = fill);
    final h = Paint()..color = holes;
    canvas.drawCircle(const Offset(8.5, 11), 2.3, h);
    canvas.drawCircle(const Offset(15.5, 11), 2.3, h);
    canvas.drawPath(
      Path()
        ..moveTo(12, 13.6)
        ..lineTo(10.7, 16)
        ..lineTo(13.3, 16)
        ..close(),
      h,
    );
    final teeth = Paint()
      ..color = holes
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(10, 18.5), const Offset(10, 21), teeth);
    canvas.drawLine(const Offset(14, 18.5), const Offset(14, 21), teeth);
    canvas.restore();
  }

  static void _skulls(Canvas canvas, Size size) {
    final bolt = Paint()..color = const Color(0xFFD62B1A).withValues(alpha: 0.35);
    for (var y = 0.0; y < size.height + 68; y += 68) {
      for (var x = 0.0; x < size.width + 76; x += 76) {
        skull(canvas, Offset(x + 8, y + 6), 1, const Color(0x17FFFFFF), const Color(0xFF141414));
        canvas.drawPath(
          Path()
            ..moveTo(x + 52, y + 34)
            ..relativeLineTo(-8, 11)
            ..relativeLineTo(6, 0)
            ..relativeLineTo(-1, 8)
            ..relativeLineTo(8, -11)
            ..relativeLineTo(-6, 0)
            ..close(),
          bolt,
        );
      }
    }
  }

  /// Neon: synthwave slunce s pruhy a perspektivní mřížka.
  static void _synthwave(Canvas canvas, Size size) {
    // Vpravo nechat místo pro ikony v záhlaví.
    final cx = size.width - 112;
    final cy = size.height * 0.78;
    const r = 44.0;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    final top = Rect.fromLTRB(cx - r, cy - r, cx + r, cy + 0.15 * r);
    canvas.drawRect(top, Paint()..color = const Color(0x99FFB547));
    canvas.drawRect(Rect.fromLTRB(cx - r, cy + 0.15 * r, cx + r, cy + r), Paint()..color = const Color(0x99FF4FD8));
    final gap = Paint()..color = const Color(0xFF0D0A1E);
    for (final (dy, h) in const [(-0.05, 2.0), (0.15, 3.0), (0.35, 4.0), (0.55, 5.0)]) {
      canvas.drawRect(Rect.fromLTWH(cx - r, cy + dy * r, 2 * r, h), gap);
    }
    canvas.restore();
    final line = Paint()
      ..color = const Color(0xFF22E3F0).withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final horizon = cy;
    for (final f in const [0.0, 0.12, 0.3, 0.55, 0.9]) {
      final y = horizon + f * (size.height - horizon);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final vx = size.width / 2;
    for (var i = -4; i <= 4; i++) {
      canvas.drawLine(Offset(vx, horizon), Offset(vx + i * size.width * 0.32, size.height), line);
    }
  }

  /// Hvězda s pěti cípy (24 × 24) v bodě [o].
  static Path star(Offset o, double scale) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = (i.isEven ? 10.0 : 4.2) * scale;
      final pt = Offset(o.dx + 12 * scale + r * math.cos(a), o.dy + 12 * scale + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  /// Retro: hvězdy a pruhy 70. let u spodního okraje.
  static void _retro(Canvas canvas, Size size) {
    final cream = Paint()..color = const Color(0x29FFF4DE);
    final mustard = Paint()..color = const Color(0x59E0A526);
    for (var y = 0.0; y < size.height; y += 56) {
      for (var x = 0.0; x < size.width + 70; x += 70) {
        canvas.drawPath(star(Offset(x + 6, y + 6), 0.7), cream);
        canvas.drawPath(star(Offset(x + 42, y + 30), 0.5), mustard);
      }
    }
    const bands = [
      (7.0, Color(0xFFE0A526)),
      (3.0, Color(0xFFFFF4DE)),
      (5.0, Color(0xFFC9622B)),
      (3.0, Color(0xFFFFF4DE)),
      (5.0, Color(0xFF2B1D14)),
    ];
    var y = size.height - bands.fold<double>(0, (a, b) => a + b.$1);
    for (final (h, c) in bands) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), Paint()..color = c);
      y += h;
    }
  }

  /// Čtyřcípá jiskra (24 × 24) se středem v [c].
  static Path sparkle(Offset c, double size) {
    final s = size / 24;
    Offset p(double x, double y) => Offset(c.dx + (x - 12) * s, c.dy + (y - 12) * s);
    return Path()
      ..moveTo(p(12, 0).dx, p(12, 0).dy)
      ..quadraticBezierTo(p(13, 11).dx, p(13, 11).dy, p(24, 12).dx, p(24, 12).dy)
      ..quadraticBezierTo(p(13, 13).dx, p(13, 13).dy, p(12, 24).dx, p(12, 24).dy)
      ..quadraticBezierTo(p(11, 13).dx, p(11, 13).dy, p(0, 12).dx, p(0, 12).dy)
      ..quadraticBezierTo(p(11, 11).dx, p(11, 11).dy, p(12, 0).dx, p(12, 0).dy)
      ..close();
  }

  /// Y2K: nálepky – jiskry, smajlík a motýl.
  static void _stickers(Canvas canvas, Size size) {
    const ink = Color(0xFF1B1446);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    void sticker(Path path, Color fill) {
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, outline);
    }

    // Vpravo nechat místo pro ikony v záhlaví.
    final right = size.width - 56;
    sticker(sparkle(Offset(right - 140, size.height * 0.32), 30), const Color(0xFFFF3EA5));
    sticker(sparkle(Offset(right - 168, size.height * 0.7), 16), Colors.white);
    // Smajlík
    final face = Offset(right - 44, size.height * 0.42);
    canvas.save();
    canvas.translate(face.dx, face.dy);
    canvas.rotate(12 * math.pi / 180);
    sticker(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 20)), const Color(0xFFC6FF3D));
    final eye = Paint()..color = ink;
    canvas.drawOval(Rect.fromCenter(center: const Offset(-6, -4), width: 4.5, height: 7), eye);
    canvas.drawOval(Rect.fromCenter(center: const Offset(6, -4), width: 4.5, height: 7), eye);
    canvas.drawPath(
      Path()
        ..moveTo(-9, 4)
        ..quadraticBezierTo(0, 14, 9, 4),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    // Motýl
    final b = Offset(right - 92, size.height * 0.78);
    canvas.save();
    canvas.translate(b.dx, b.dy);
    canvas.rotate(-14 * math.pi / 180);
    const wing = Color(0xFF8FA2FF);
    for (final (dx, dy, w, h) in const [(-8.0, -6.0, 16.0, 12.0), (8.0, -6.0, 16.0, 12.0), (-6.0, 6.0, 11.0, 10.0), (6.0, 6.0, 11.0, 10.0)]) {
      sticker(Path()..addOval(Rect.fromCenter(center: Offset(dx, dy), width: w, height: h)), wing);
    }
    canvas.drawLine(const Offset(0, -9), const Offset(0, 11), outline..strokeWidth = 2);
    canvas.restore();
  }
}
