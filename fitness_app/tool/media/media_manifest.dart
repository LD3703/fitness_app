// Společný kód skriptů tool/wger_import.dart a tool/media_import.dart:
// seznamy obrázků (manifesty), sloučení zdrojů a vygenerování
// lib/data/seed/exercise_media.dart. Čisté dart:io, bez Flutteru.
//
// Manifesty (JSON, ukládají se do gitu):
//   tool/media/wger_media.json       – obrázky z wger.de (wger_import)
//   tool/media/purchased_media.json  – koupené animace (media_import)
// Při sloučení vyhrává koupená animace nad obrázky z wger.de.

import 'dart:convert';
import 'dart:io';

const wgerManifestPath = 'tool/media/wger_media.json';
const purchasedManifestPath = 'tool/media/purchased_media.json';
const mediaDartPath = 'lib/data/seed/exercise_media.dart';
const exerciseAssetsDir = 'assets/exercises';
const _seedDataPath = 'lib/data/seed/seed_data.dart';

/// Jeden soubor (obrázek nebo animace) v assets/exercises/.
class MediaImage {
  MediaImage({
    required this.asset,
    required this.author,
    this.authorUrl,
    required this.license,
    this.aiGenerated = false,
  });

  factory MediaImage.fromJson(Map<String, dynamic> json) => MediaImage(
        asset: '${json['asset']}',
        author: '${json['author'] ?? ''}',
        authorUrl: _nonEmpty(json['authorUrl']),
        license: '${json['license'] ?? ''}',
        aiGenerated: json['aiGenerated'] == true,
      );

  final String asset;
  final String author;
  final String? authorUrl;
  final String license;
  final bool aiGenerated;

  Map<String, dynamic> toJson() => {
        'asset': asset,
        'author': author,
        if (authorUrl != null) 'authorUrl': authorUrl,
        'license': license,
        if (aiGenerated) 'aiGenerated': true,
      };
}

/// Ukázka jednoho cviku (odpovídá třídě ExerciseMedia v aplikaci).
class MediaEntry {
  MediaEntry({
    this.wgerId,
    this.pageUrl,
    this.animated = false,
    required this.images,
  });

  factory MediaEntry.fromJson(Map<String, dynamic> json) => MediaEntry(
        wgerId: json['wgerId'] as int?,
        pageUrl: _nonEmpty(json['pageUrl']),
        animated: json['animated'] == true,
        images: [
          for (final i in (json['images'] as List? ?? const []))
            MediaImage.fromJson((i as Map).cast<String, dynamic>()),
        ],
      );

  final int? wgerId;
  final String? pageUrl;
  final bool animated;
  final List<MediaImage> images;

  Map<String, dynamic> toJson() => {
        if (wgerId != null) 'wgerId': wgerId,
        if (pageUrl != null) 'pageUrl': pageUrl,
        if (animated) 'animated': true,
        'images': [for (final i in images) i.toJson()],
      };
}

String? _nonEmpty(Object? value) {
  if (value == null) return null;
  final s = '$value'.trim();
  return s.isEmpty ? null : s;
}

/// Načte manifest (chybí-li soubor, vrátí prázdnou mapu).
Map<String, MediaEntry> readManifest(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      e.key: MediaEntry.fromJson((e.value as Map).cast<String, dynamic>()),
  };
}

/// Zapíše manifest (klíče seřazené, ať se dobře porovnávají změny).
void writeManifest(String path, Map<String, MediaEntry> entries) {
  final sorted = entries.keys.toList()..sort();
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            for (final k in sorted) k: entries[k]!.toJson(),
          })}\n',
    );
}

/// Sloučí zdroje: koupená animace má přednost před wger.de.
Map<String, MediaEntry> mergeMedia(
  Map<String, MediaEntry> wger,
  Map<String, MediaEntry> purchased,
) {
  final merged = <String, MediaEntry>{...wger, ...purchased};
  final keys = merged.keys.toList()..sort();
  return {for (final k in keys) k: merged[k]!};
}

/// Načte oba manifesty, sloučí je a přepíše lib/data/seed/exercise_media.dart.
/// Vrátí sloučené položky.
///
/// Když manifest wger.de ještě neexistuje (obrázky stažené starší verzí
/// skriptu), převezme položky z dosavadního exercise_media.dart.
Map<String, MediaEntry> regenerateMediaDart() {
  var wger = readManifest(wgerManifestPath);
  var purchased = readManifest(purchasedManifestPath);
  final dartFile = File(mediaDartPath);
  if (!File(wgerManifestPath).existsSync() && dartFile.existsSync()) {
    final old = parseGeneratedMediaDart(dartFile.readAsStringSync());
    wger = {
      for (final e in old.entries)
        if (e.value.wgerId != null) e.key: e.value,
    };
    if (wger.isNotEmpty) writeManifest(wgerManifestPath, wger);
    if (!File(purchasedManifestPath).existsSync()) {
      final oldPurchased = {
        for (final e in old.entries)
          if (e.value.wgerId == null) e.key: e.value,
      };
      purchased = {...oldPurchased, ...purchased};
    }
  }
  final merged = mergeMedia(wger, purchased);
  dartFile.writeAsStringSync(generateMediaDart(merged));
  return merged;
}

String _dartString(String s) =>
    "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n')}'";

/// Zdrojový kód lib/data/seed/exercise_media.dart.
String generateMediaDart(Map<String, MediaEntry> entries) {
  final b = StringBuffer()
    ..writeln('// Vygenerováno skripty tool/wger_import.dart a '
        'tool/media_import.dart – neupravuj ručně.')
    ..writeln('// Obrázky: projekt wger.de (licence u každého obrázku), '
        'animace: koupené balíčky.')
    ..writeln()
    ..writeln("import 'exercise_media_types.dart';")
    ..writeln()
    ..writeln("export 'exercise_media_types.dart';")
    ..writeln()
    ..writeln('const exerciseMedia = <String, ExerciseMedia>{');
  for (final e in entries.entries) {
    final m = e.value;
    if (m.images.isEmpty) continue;
    b.writeln('  ${_dartString(e.key)}: ExerciseMedia(');
    if (m.wgerId != null) b.writeln('    wgerId: ${m.wgerId},');
    if (m.animated) b.writeln('    animated: true,');
    if (m.pageUrl != null) b.writeln('    pageUrl: ${_dartString(m.pageUrl!)},');
    b.writeln('    images: [');
    for (final i in m.images) {
      b
        ..writeln('      ExerciseImage(')
        ..writeln('        asset: ${_dartString(i.asset)},')
        ..writeln('        author: ${_dartString(i.author)},');
      if (i.authorUrl != null) {
        b.writeln('        authorUrl: ${_dartString(i.authorUrl!)},');
      }
      b.writeln('        license: ${_dartString(i.license)},');
      if (i.aiGenerated) b.writeln('        aiGenerated: true,');
      b.writeln('      ),');
    }
    b
      ..writeln('    ],')
      ..writeln('  ),');
  }
  b.writeln('};');
  return b.toString();
}

const _str = r"'((?:[^'\\]|\\.)*)'";

String _unescape(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (ch == r'\' && i + 1 < s.length) {
      i++;
      b.write(s[i] == 'n' ? '\n' : s[i]);
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

String? _field(String block, String name) {
  final m = RegExp('$name: $_str').firstMatch(block);
  return m == null ? null : _unescape(m.group(1)!);
}

/// Přečte položky z vygenerovaného exercise_media.dart (i ze starší
/// verze bez manifestů).
Map<String, MediaEntry> parseGeneratedMediaDart(String source) {
  final result = <String, MediaEntry>{};
  final starts = RegExp(
    '^  $_str: ExerciseMedia\\(\$',
    multiLine: true,
  ).allMatches(source).toList();
  for (var i = 0; i < starts.length; i++) {
    final slug = _unescape(starts[i].group(1)!);
    final end = i + 1 < starts.length ? starts[i + 1].start : source.length;
    final block = source.substring(starts[i].end, end);
    final wgerId = RegExp(r'^    wgerId: (\d+),', multiLine: true)
        .firstMatch(block)
        ?.group(1);
    final images = <MediaImage>[];
    for (final m in RegExp(r'ExerciseImage\((.*?)\n      \),', dotAll: true)
        .allMatches(block)) {
      final img = m.group(1)!;
      final asset = _field(img, 'asset');
      if (asset == null) continue;
      images.add(MediaImage(
        asset: asset,
        author: _field(img, 'author') ?? '',
        authorUrl: _field(img, 'authorUrl'),
        license: _field(img, 'license') ?? '',
        aiGenerated: img.contains('aiGenerated: true'),
      ));
    }
    if (images.isEmpty) continue;
    result[slug] = MediaEntry(
      wgerId: wgerId == null ? null : int.parse(wgerId),
      pageUrl: _field(block.split('images:').first, 'pageUrl'),
      animated: RegExp(r'^    animated: true,', multiLine: true).hasMatch(block),
      images: images,
    );
  }
  return result;
}

/// Slugy vestavěných cviků (z lib/data/seed/seed_data.dart).
Set<String> knownExerciseSlugs() {
  final file = File(_seedDataPath);
  if (!file.existsSync()) return {};
  return {
    for (final m in RegExp(r"SeedExercise\(\s*'([a-z0-9_]+)'")
        .allMatches(file.readAsStringSync()))
      m.group(1)!,
  };
}

/// Je soubor animovaný GIF (víc snímků) nebo animovaný WebP?
bool isAnimatedImage(List<int> bytes) {
  if (_startsWith(bytes, 'GIF8')) return _gifFrameCount(bytes) > 1;
  if (_startsWith(bytes, 'RIFF') && _matchesAt(bytes, 8, 'WEBP')) {
    return _webpIsAnimated(bytes);
  }
  return false;
}

bool _startsWith(List<int> bytes, String ascii) => _matchesAt(bytes, 0, ascii);

bool _matchesAt(List<int> bytes, int offset, String ascii) {
  if (bytes.length < offset + ascii.length) return false;
  for (var i = 0; i < ascii.length; i++) {
    if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

/// Počet snímků GIF (stačí zjistit, jestli je víc než 1).
int _gifFrameCount(List<int> b) {
  if (b.length < 13) return 0;
  var pos = 13;
  final packed = b[10];
  if (packed & 0x80 != 0) pos += 3 * (1 << ((packed & 0x07) + 1));
  var frames = 0;

  int skipSubBlocks(int p) {
    while (p < b.length) {
      final size = b[p++];
      if (size == 0) break;
      p += size;
    }
    return p;
  }

  while (pos < b.length) {
    final marker = b[pos];
    if (marker == 0x2C) {
      frames++;
      if (frames > 1) return frames;
      if (pos + 10 > b.length) break;
      final local = b[pos + 9];
      pos += 10;
      if (local & 0x80 != 0) pos += 3 * (1 << ((local & 0x07) + 1));
      pos++; // minimální velikost kódu LZW
      pos = skipSubBlocks(pos);
    } else if (marker == 0x21) {
      pos = skipSubBlocks(pos + 2);
    } else {
      break; // 0x3B = konec souboru, cokoli jiného = poškozený soubor
    }
  }
  return frames;
}

bool _webpIsAnimated(List<int> b) {
  var pos = 12;
  while (pos + 8 <= b.length) {
    final fourcc = String.fromCharCodes(b.sublist(pos, pos + 4));
    final size = b[pos + 4] |
        (b[pos + 5] << 8) |
        (b[pos + 6] << 16) |
        (b[pos + 7] << 24);
    if (fourcc == 'ANIM' || fourcc == 'ANMF') return true;
    if (fourcc == 'VP8X' && pos + 8 < b.length && (b[pos + 8] & 0x02) != 0) {
      return true;
    }
    pos += 8 + size + (size.isOdd ? 1 : 0);
  }
  return false;
}
