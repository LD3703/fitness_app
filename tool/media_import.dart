// Přibalí koupené animace cviků (GIF / WebP) do aplikace.
//
// Spuštění z kořene projektu:
//   dart run tool/media_import.dart <složka> [volby]
//
// Složka obsahuje soubory pojmenované podle slugu cviku, např.
// bench_press.gif, back_squat.webp (velikost písmen, mezery a pomlčky
// nevadí: "Bench-Press.GIF" = bench_press). Jiné názvy přiřadí sloupec
// file v souboru s údaji (--meta).
//
// Volby:
//   --meta <soubor.csv|soubor.json>  autor, licence a odkazy k souborům
//   --author "<jméno>"               výchozí autor (např. "Gym Visual")
//   --license "<licence>"            výchozí licence (smí být prázdná)
//   --url <adresa>                   výchozí stránka zdroje (prodejce)
//   --replace                        zahodí dřív importované animace
//                                    (jinak se nové přidají / přepíší)
//
// CSV (oddělovač čárka, první řádek hlavička):
//   slug,file,author,license,author_url,source_url
//   *,,Gym Visual,Licence pro aplikace,,https://www.gymvisual.com
//   bench_press,Barbell-Bench-Press.gif,,,,
// Řádek se slugem * platí pro všechny soubory (prázdné buňky se doplní
// z něj). JSON: {"*": {"author": "...", "license": "..."},
//   "bench_press": {"file": "...", "author": "...", "license": "...",
//   "authorUrl": "...", "sourceUrl": "..."}}
//
// Co udělá:
//  1. Zkontroluje všechny soubory a zkopíruje je do dočasné složky
//     .dart_tool/media_import/ (při chybě se v projektu nic nezmění).
//  2. Přesune je do assets/exercises/<slug>.<gif|webp>.
//  3. Zapíše tool/media/purchased_media.json.
//  4. Sloučí je s obrázky z wger.de (tool/media/wger_media.json) –
//     koupená animace vyhrává – a přegeneruje
//     lib/data/seed/exercise_media.dart.
//  5. Až potom smaže staré soubory, na které už nic neodkazuje.

import 'dart:convert';
import 'dart:io';

import 'media/media_manifest.dart';

/// Upozornit, když jsou obrázky cviků větší (aplikace pak hodně váží).
const _warnTotalBytes = 40 * 1024 * 1024;

class _Meta {
  _Meta({
    this.file,
    this.author,
    this.license,
    this.authorUrl,
    this.sourceUrl,
  });

  final String? file;
  final String? author;
  final String? license;
  final String? authorUrl;
  final String? sourceUrl;

  /// Prázdné hodnoty doplní z [fallback].
  _Meta withDefaults(_Meta? fallback) => _Meta(
        file: file,
        author: author ?? fallback?.author,
        license: license ?? fallback?.license,
        authorUrl: authorUrl ?? fallback?.authorUrl,
        sourceUrl: sourceUrl ?? fallback?.sourceUrl,
      );
}

/// Soubor připravený k importu (po kontrole, před kopírováním).
class _Planned {
  _Planned({
    required this.file,
    required this.ext,
    required this.animated,
    required this.info,
    required this.author,
  });

  final File file;
  final String ext;
  final bool animated;
  final _Meta info;
  final String author;

  String get name => file.uri.pathSegments.last;
}

/// Přesune [from] na [to] (existující soubor přepíše).
void _moveFile(File from, String to) {
  try {
    from.renameSync(to);
  } on FileSystemException {
    // Záloha, když přejmenování nejde (jiný disk, Windows): kopie a smazání.
    from.copySync(to);
    from.deleteSync();
  }
}

String? _clean(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

/// "Bench-Press.GIF" → "bench_press".
String _slugFromFileName(String name) {
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  return base
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Jednoduchý parser CSV (uvozovky, zdvojené uvozovky uvnitř).
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',' || ch == ';') {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  row.add(cell.toString());
  if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
  return rows;
}

Map<String, _Meta> _readMeta(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('Soubor s údaji neexistuje', path);
  }
  final text = file.readAsStringSync().replaceFirst('﻿', '');
  final result = <String, _Meta>{};
  if (path.toLowerCase().endsWith('.json')) {
    final Object? json = jsonDecode(text);
    final items = <MapEntry<String, Map<String, dynamic>>>[];
    if (json is Map) {
      for (final e in json.entries) {
        final value = e.value;
        if (value is Map) {
          items.add(MapEntry('${e.key}', value.cast<String, dynamic>()));
        }
      }
    } else if (json is List) {
      for (final e in json) {
        if (e is Map) {
          items.add(MapEntry('${e['slug']}', e.cast<String, dynamic>()));
        }
      }
    }
    for (final e in items) {
      final m = e.value;
      result[e.key.trim()] = _Meta(
        file: _clean(m['file']),
        author: _clean(m['author']),
        license: _clean(m['license']),
        authorUrl: _clean(m['authorUrl'] ?? m['author_url']),
        sourceUrl: _clean(m['sourceUrl'] ?? m['source_url']),
      );
    }
    return result;
  }
  final rows = _parseCsv(text);
  if (rows.isEmpty) return result;
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  String? cell(List<String> row, String name) {
    final i = header.indexOf(name);
    return i < 0 || i >= row.length ? null : _clean(row[i]);
  }

  for (final row in rows.skip(1)) {
    final slug = cell(row, 'slug');
    if (slug == null) continue;
    result[slug] = _Meta(
      file: cell(row, 'file'),
      author: cell(row, 'author'),
      license: cell(row, 'license'),
      authorUrl: cell(row, 'author_url'),
      sourceUrl: cell(row, 'source_url'),
    );
  }
  return result;
}

void _usage() {
  stderr.writeln('Použití: dart run tool/media_import.dart <složka> '
      '[--meta údaje.csv] [--author "Gym Visual"] [--license "..."] '
      '[--url https://...] [--replace]');
}

Future<void> main(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Spusť skript z kořene projektu (tam, kde je pubspec.yaml).');
    exitCode = 1;
    return;
  }

  String? folder;
  String? metaPath;
  String? cliAuthor;
  String? cliLicense;
  String? cliUrl;
  var replace = false;
  const valueOptions = {'--meta', '--author', '--license', '--url'};
  var i = 0;
  while (i < args.length) {
    final a = args[i++];
    if (a == '-h' || a == '--help') {
      _usage();
      return;
    }
    if (a == '--replace') {
      replace = true;
      continue;
    }
    if (valueOptions.contains(a)) {
      if (i >= args.length) {
        _usage();
        exitCode = 1;
        return;
      }
      final value = args[i++];
      switch (a) {
        case '--meta':
          metaPath = value;
        case '--author':
          cliAuthor = _clean(value);
        case '--license':
          cliLicense = value.trim();
        case '--url':
          cliUrl = _clean(value);
      }
      continue;
    }
    if (a.startsWith('--')) {
      stderr.writeln('Neznámá volba $a');
      _usage();
      exitCode = 1;
      return;
    }
    folder = a;
  }
  if (folder == null) {
    _usage();
    exitCode = 1;
    return;
  }
  final source = Directory(folder);
  if (!source.existsSync()) {
    stderr.writeln('Složka $folder neexistuje.');
    exitCode = 1;
    return;
  }

  final meta = metaPath == null ? <String, _Meta>{} : _readMeta(metaPath);
  final defaults = _Meta(
    author: cliAuthor,
    license: cliLicense,
    sourceUrl: cliUrl,
  ).withDefaults(meta['*']);
  // Ruční přiřazení: název souboru (malými písmeny) → slug.
  final fileToSlug = <String, String>{
    for (final e in meta.entries)
      if (e.key != '*' && e.value.file != null)
        e.value.file!.toLowerCase(): e.key,
  };

  final known = knownExerciseSlugs();
  final assets = Directory(exerciseAssetsDir)..createSync(recursive: true);
  final previous = readManifest(purchasedManifestPath);
  // S --replace se dřív importované animace zahodí (obrázky z wger.de
  // zůstanou) – soubory se ale smažou až po úspěšném importu (krok 4).
  final purchased =
      replace ? <String, MediaEntry>{} : <String, MediaEntry>{...previous};

  final files = source
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'\.(gif|webp)$', caseSensitive: false)
          .hasMatch(f.uri.pathSegments.last))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('Ve složce $folder nejsou žádné soubory .gif ani .webp.');
    exitCode = 1;
    return;
  }

  // 1) Kontrola všech souborů. Při chybě skript skončí dřív, než cokoli
  //    v projektu změní.
  final planned = <String, _Planned>{};
  var skipped = 0;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final slug = fileToSlug[name.toLowerCase()] ?? _slugFromFileName(name);
    if (known.isNotEmpty && !known.contains(slug)) {
      stdout.writeln('– $name: cvik „$slug“ v aplikaci není '
          '(přejmenuj soubor, nebo ho přiřaď sloupcem file).');
      skipped++;
      continue;
    }
    final info = (meta[slug] ?? _Meta()).withDefaults(defaults);
    final author = info.author;
    if (author == null) {
      stderr.writeln('✗ $name: chybí autor – doplň --author "…" '
          'nebo sloupec author v --meta. Nic se nezměnilo.');
      exitCode = 1;
      return;
    }
    final earlier = planned[slug];
    if (earlier != null) {
      stdout.writeln('! $name: cvik „$slug“ už má soubor ${earlier.name} '
          '– použije se $name.');
      skipped++;
    }
    planned[slug] = _Planned(
      file: file,
      ext: name.split('.').last.toLowerCase(),
      animated: isAnimatedImage(file.readAsBytesSync()),
      info: info,
      author: author,
    );
  }
  if (planned.isEmpty) {
    stderr.writeln('✗ Žádný soubor nepatří ke cviku z aplikace – '
        'nic se nezměnilo.');
    exitCode = 1;
    return;
  }

  // 2) Kopie do dočasné složky (.dart_tool je v .gitignore). Když kopírování
  //    selže, v assets/exercises/ ani v manifestu se nic nezmění.
  final staging = Directory('.dart_tool/media_import');
  if (staging.existsSync()) staging.deleteSync(recursive: true);
  staging.createSync(recursive: true);
  for (final e in planned.entries) {
    e.value.file.copySync('${staging.path}/${e.key}.${e.value.ext}');
  }

  // 3) Výměna: nové soubory do assets/exercises/, manifest a
  //    exercise_media.dart.
  for (final e in planned.entries) {
    final slug = e.key;
    final p = e.value;
    final asset = '$exerciseAssetsDir/$slug.${p.ext}';
    _moveFile(File('${staging.path}/$slug.${p.ext}'), asset);
    purchased[slug] = MediaEntry(
      animated: p.animated,
      pageUrl: p.info.sourceUrl,
      images: [
        MediaImage(
          asset: asset,
          author: p.author,
          authorUrl: p.info.authorUrl,
          license: p.info.license ?? '',
        ),
      ],
    );
    stdout.writeln('✓ ${p.name} → $asset'
        '${p.animated ? '' : ' (není animovaný – ukáže se jako obrázek)'}');
  }
  final imported = planned.length;
  writeManifest(purchasedManifestPath, purchased);
  final merged = regenerateMediaDart();

  // 4) Až teď smazat soubory, na které už nic neodkazuje: dřív importované
  //    animace (--replace) a jiná přípona téhož cviku (dřív .gif, teď .webp).
  final used = <String>{
    for (final m in [readManifest(wgerManifestPath), purchased])
      for (final entry in m.values)
        for (final img in entry.images) img.asset,
  };
  final stale = <String>{
    for (final entry in previous.values)
      for (final img in entry.images) img.asset,
    for (final slug in planned.keys)
      for (final ext in ['gif', 'webp']) '$exerciseAssetsDir/$slug.$ext',
  }.difference(used);
  for (final path in stale) {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }
  try {
    staging.deleteSync(recursive: true);
  } on FileSystemException {
    // Prázdná dočasná složka nevadí – smaže se při dalším spuštění.
  }

  var total = 0;
  for (final f in assets.listSync().whereType<File>()) {
    total += f.lengthSync();
  }
  final missing = [
    for (final s in known)
      if (!merged.containsKey(s)) s,
  ]..sort();

  stdout.writeln('\nHotovo: $imported importováno, $skipped přeskočeno. '
      'Koupených animací celkem ${purchased.length}, '
      'cviků s ukázkou ${merged.length} z ${known.length}.');
  if (missing.isNotEmpty) {
    stdout.writeln('Bez ukázky: ${missing.join(', ')}');
  }
  stdout.writeln('Obrázky cviků zabírají '
      '${(total / (1024 * 1024)).toStringAsFixed(1)} MB.');
  if (total > _warnTotalBytes) {
    stdout.writeln('Pozor: aplikace bude velká. Zvaž převod GIF na WebP '
        '(menší soubory) nebo menší rozlišení (stačí 480 px).');
  }
  stdout.writeln('Pak spusť flutter run.');
}
