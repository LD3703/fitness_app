// Vytištěný žebříček posilovny: A4 PDF → systémový tisk (tiskárna nebo
// „Uložit jako PDF“). Co se na papír dostane: gym/gym_printout.dart.
// Na papíře jsou jen přezdívky lidí, kteří tisk nevypnuli
// (GymMembership.printable → pole `noPrint` u záznamů).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_printout.dart';
import '../gym/gym_service.dart';
import '../social_logic.dart';
import 'gym_widgets.dart';
import 'social_ui.dart';

/// Načte žebříček posilovny, složí stránku A4 a otevře systémový tisk.
Future<void> printGymBoard(BuildContext context, Gym gym) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final month = monthKey(now);

  final List<GymPrintBox> boxes;
  try {
    final service = GymService.instance;
    final monthly = <GymCategory, List<GymEntry>>{};
    final allTime = <GymCategory, List<GymEntry>>{};
    await Future.wait([
      for (final c in gymPrintCategories) ...[
        service
            .boardOnce(gym.id, c, monthly: true, month: month)
            .then((v) => monthly[c] = v),
        service
            .boardOnce(gym.id, c, monthly: false, month: month)
            .then((v) => allTime[c] = v),
      ],
    ]);
    boxes = gymPrintBoxes(monthly: monthly, allTime: allTime, month: month);
  } catch (e) {
    debugPrint('Gym: print load failed: $e');
    if (context.mounted) showSocialSnack(context, l10n.socialGymPrintFailed);
    return;
  }
  if (!context.mounted) return;
  if (!gymPrintHasData(boxes)) {
    showSocialSnack(context, l10n.socialGymPrintNothing);
    return;
  }

  // Texty (jednotky kg / lb, překlady) se připraví tady – PDF se skládá
  // až v onLayout, kdy už kontext nemusí platit.
  List<_Row> rows(List<RankedEntry<GymEntry>> list) => [
        for (final r in list)
          (
            rank: r.rank,
            nickname: _short(r.item.nickname),
            value: gymValueText(context, r.item.category, r.value),
          ),
      ];
  String genderLabel(GymGenderFilter g) => switch (g) {
        GymGenderFilter.men => l10n.socialGymFilterMen,
        GymGenderFilter.women => l10n.socialGymFilterWomen,
        GymGenderFilter.all => l10n.socialGymFilterAll,
      };

  final page = _Page(
    gymName: gym.name,
    place: gym.city,
    title: l10n.socialGymPrintTitle,
    asOf: l10n.socialGymPrintAsOf(DateFormat.yMMMMd(locale).format(now)),
    monthLabel: l10n.socialGymPrintMonth,
    allTimeLabel: l10n.socialGymPrintAllTime,
    emptyLabel: l10n.socialGymPrintEmpty,
    genders: [for (final g in gymPrintGenders) genderLabel(g)],
    boxes: [
      for (final b in boxes)
        (
          category: gymCategoryLabel(l10n, b.category),
          month: rows(b.month),
          allTime: rows(b.allTime),
        ),
    ],
    join: l10n.socialGymPrintJoin,
    joinHint: l10n.socialGymPrintJoinHint,
    note: l10n.socialGymPrintNote,
    code: l10n.socialGymPrintCode(gym.code),
    link: gymWebLink(gym.code),
  );

  try {
    await Printing.layoutPdf(
      name: 'GymBar – ${gym.name}',
      format: PdfPageFormat.a4,
      onLayout: (format) => _buildPdf(page, format),
    );
  } catch (e) {
    debugPrint('Gym: print failed: $e');
    if (context.mounted) showSocialSnack(context, l10n.errorGeneric);
  }
}

// ---------------------------------------------------------------------------
// Data stránky (jen texty – PDF nepotřebuje kontext)
// ---------------------------------------------------------------------------

typedef _Row = ({int rank, String nickname, String value});

typedef _Box = ({String category, List<_Row> month, List<_Row> allTime});

class _Page {
  const _Page({
    required this.gymName,
    required this.place,
    required this.title,
    required this.asOf,
    required this.monthLabel,
    required this.allTimeLabel,
    required this.emptyLabel,
    required this.genders,
    required this.boxes,
    required this.join,
    required this.joinHint,
    required this.note,
    required this.code,
    required this.link,
  });

  final String gymName;
  final String place;
  final String title;
  final String asOf;
  final String monthLabel;
  final String allTimeLabel;
  final String emptyLabel;

  /// Popisky sloupců (gymPrintGenders).
  final List<String> genders;

  /// Rámečky po řádcích: kategorie × pohlaví (gymPrintBoxes).
  final List<_Box> boxes;
  final String join;
  final String joinHint;
  final String note;
  final String code;
  final String link;
}

/// Přezdívka na šířku sloupce (až 24 znaků by se nevešlo).
String _short(String nickname) =>
    nickname.length <= 13 ? nickname : '${nickname.substring(0, 12)}…';

// ---------------------------------------------------------------------------
// PDF
// ---------------------------------------------------------------------------

const _logoSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
    '<rect width="100" height="100" rx="22" fill="#2E7D6B"/>'
    '<line x1="12" y1="50" x2="88" y2="50" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>'
    '<rect x="20" y="41" width="8" height="18" rx="3" fill="#FFFFFF"/>'
    '<rect x="31" y="35" width="8" height="30" rx="3" fill="#FFFFFF"/>'
    '<rect x="61" y="29" width="8" height="42" rx="3" fill="#FFFFFF"/>'
    '<rect x="72" y="23" width="8" height="54" rx="3" fill="#FFC857"/>'
    '</svg>';

const _teal = PdfColor.fromInt(0xFF2E7D6B);
const _amber = PdfColor.fromInt(0xFFFFC857);
const _ink = PdfColor.fromInt(0xFF13201D);
const _muted = PdfColor.fromInt(0xFF4A5754);
const _line = PdfColor.fromInt(0xFFCFD8D5);

/// Výška rámečku: nadpis, popisky a až gymPrintMaxRows (7) řádků.
const _boxHeight = 132.0;

Future<Uint8List> _buildPdf(_Page p, PdfPageFormat format) async {
  // Archivo (OFL) je v aplikaci kvůli logu – umí češtinu i ostatní jazyky.
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Archivo-Bold.ttf'));
  final heavy =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Archivo-ExtraBold.ttf'));
  final doc = pw.Document(
    title: '${p.title} – ${p.gymName}',
    author: 'GymBar',
    theme: pw.ThemeData.withFont(base: regular, bold: heavy),
  );

  pw.TextStyle style(double size, {bool bold = false, PdfColor? color, double? spacing}) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _ink,
        letterSpacing: spacing,
      );

  pw.Widget rank(int r) => r == 1
      ? pw.Container(
          width: 11,
          height: 11,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _amber,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text('1', style: style(7, bold: true)),
        )
      : pw.Text('$r', style: style(8, color: _muted));

  pw.Widget list(String label, List<_Row> rows) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: style(7, bold: true, color: _teal, spacing: 0.8)),
          pw.SizedBox(height: 3),
          if (rows.isEmpty)
            pw.Text(p.emptyLabel, style: style(8, color: _muted))
          else
            for (final r in rows)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 0.75),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 15, child: rank(r.rank)),
                    pw.Expanded(
                      child: pw.Text(r.nickname,
                          maxLines: 1, style: style(8.5)),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(r.value, style: style(8.5, bold: true)),
                  ],
                ),
              ),
        ],
      );

  pw.Widget box(_Box b) => pw.Container(
        height: _boxHeight,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(b.category, maxLines: 1, style: style(12, bold: true)),
            pw.SizedBox(height: 4),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: list(p.monthLabel, b.month)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: list(p.allTimeLabel, b.allTime)),
              ],
            ),
          ],
        ),
      );

  final columns = p.genders.length;
  final gridRows = <pw.Widget>[];
  for (var i = 0; i < p.boxes.length; i += columns) {
    if (i > 0) gridRows.add(pw.SizedBox(height: 8));
    gridRows.add(pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var j = 0; j < columns && i + j < p.boxes.length; j++) ...[
          if (j > 0) pw.SizedBox(width: 10),
          pw.Expanded(child: box(p.boxes[i + j])),
        ],
      ],
    ));
  }

  doc.addPage(pw.Page(
    pageFormat: format,
    margin: const pw.EdgeInsets.all(32),
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Hlavička: logo, posilovna, datum.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SvgImage(svg: _logoSvg, width: 40, height: 40),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(p.title.toUpperCase(),
                      style: style(9, bold: true, color: _teal, spacing: 1.2)),
                  pw.Text(p.gymName, maxLines: 1, style: style(20, bold: true)),
                  pw.Text(
                    [if (p.place.isNotEmpty) p.place, p.asOf].join(' · '),
                    style: style(10, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        // Sloupce: muži, ženy.
        pw.Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _teal, width: 2),
                    ),
                  ),
                  child: pw.Text(p.genders[j].toUpperCase(),
                      style: style(12, bold: true, spacing: 1)),
                ),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 8),
        ...gridRows,
        pw.Spacer(),
        // Pata: výzva a QR kód do žebříčku téhle posilovny.
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 1)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p.join, style: style(16, bold: true)),
                    pw.SizedBox(height: 2),
                    pw.Text(p.joinHint, style: style(10)),
                    pw.SizedBox(height: 6),
                    pw.Text(p.note, style: style(7.5, color: _muted)),
                    pw.SizedBox(height: 4),
                    pw.Text('gymbar.app', style: style(10, bold: true, color: _teal)),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Column(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: p.link,
                    width: 78,
                    height: 78,
                    drawText: false,
                    color: _ink,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(p.code, style: style(8, color: _muted)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ));
  return doc.save();
}
