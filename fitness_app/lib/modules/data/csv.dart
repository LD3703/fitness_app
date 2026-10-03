// Čisté pomocné funkce pro CSV (RFC 4180): oddělovač čárka, řádky CRLF,
// UTF-8 s BOM, aby soubor správně otevřel i Excel.

/// Značka pořadí bajtů (BOM) na začátek souboru.
const csvBom = '﻿';

/// Jedna hodnota CSV.
///
/// - null → prázdné pole,
/// - celé double bez „.0“ (80.0 → „80“), jinak s tečkou,
/// - bool → „true“ / „false“,
/// - DateTime → ISO 8601 bez milisekund (místní čas),
/// - text s čárkou, uvozovkou nebo koncem řádku se obalí uvozovkami
///   a uvozovky se zdvojí,
/// - text začínající „=“, „+“, „-“, „@“ dostane apostrof, aby ho
///   tabulkový procesor nespustil jako vzorec.
String csvField(Object? value) {
  if (value == null) return '';
  if (value is double) {
    if (value.isNaN || value.isInfinite) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  if (value is num || value is bool) return value.toString();
  if (value is DateTime) return csvDateTime(value);
  var text = value.toString();
  if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
  final needsQuotes = text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}

/// Řádek CSV z hodnot (bez konce řádku).
String csvRow(List<Object?> values) => values.map(csvField).join(',');

/// Celý soubor: BOM, hlavička a řádky, každý ukončený CRLF.
String buildCsv(List<String> header, Iterable<List<Object?>> rows) {
  final b = StringBuffer(csvBom)
    ..write(csvRow(header))
    ..write('\r\n');
  for (final r in rows) {
    b
      ..write(csvRow(r))
      ..write('\r\n');
  }
  return b.toString();
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Datum ve formátu ISO: „2026-09-30“.
String csvDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// Datum a čas ve formátu ISO bez milisekund: „2026-09-30T18:05:00“.
String csvDateTime(DateTime d) =>
    '${csvDate(d)}T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
