// Stáhne obrázky cviků z otevřené databáze wger.de a přibalí je do aplikace.
//
// Spuštění z kořene projektu (potřebuje internet):
//   dart run tool/wger_import.dart
//
// Co udělá:
//  1. Pro každý vestavěný cvik najde na wger.de nejlépe odpovídající cvik
//     (podle anglického názvu) a stáhne až 2 obrázky (výchozí a koncová
//     poloha – v aplikaci se střídají jako jednoduchá animace).
//  2. Obrázky uloží do assets/exercises/<slug>_<n>.<přípona>.
//  3. Vygeneruje lib/data/seed/exercise_media.dart s cestami a autory
//     (licence CC BY-SA vyžaduje uvést autora – aplikace ho zobrazuje).
//  4. Zapíše tool/wger_report.csv – zkontroluj, jestli sedí přiřazení.
//     Špatné přiřazení oprav v mapě _overrides níže (slug → ID cviku
//     na wger.de; ID je v adrese https://wger.de/en/exercise/<ID>/view/)
//     a skript spusť znovu.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _api = 'https://wger.de/api/v2';
const _englishLanguageId = 2;
const _maxImagesPerExercise = 2;

/// Ruční přiřazení slug → ID cviku na wger.de (má přednost před hledáním).
const _overrides = <String, int>{
  // 'bench_press': 192,
};

/// Hledané anglické názvy pro každý vestavěný cvik (první je hlavní).
const _searchTerms = <String, List<String>>{
  'bench_press': ['Bench Press', 'Barbell Bench Press'],
  'incline_dumbbell_press': ['Incline Dumbbell Press', 'Incline Dumbbell Bench Press'],
  'cable_fly': ['Cable Fly', 'Cable Crossover', 'Fly With Cable'],
  'push_up': ['Push-Up', 'Push Up', 'Pushups'],
  'deadlift': ['Deadlift', 'Barbell Deadlift'],
  'barbell_row': ['Bent Over Barbell Row', 'Barbell Row', 'Bent Over Rowing'],
  'lat_pulldown': ['Lat Pulldown', 'Lat Pull Down', 'Pulldown'],
  'pull_up': ['Pull-Up', 'Pull Up', 'Pull-ups'],
  'overhead_press': ['Overhead Press', 'Shoulder Press, Barbell', 'Military Press'],
  'lateral_raise': ['Lateral Raise', 'Lateral Raises', 'Side Raise'],
  'pike_push_up': ['Pike Push-Up', 'Pike Push Up'],
  'dumbbell_curl': ['Dumbbell Curl', 'Biceps Curls With Dumbbell', 'Bicep Curl'],
  'triceps_pushdown': ['Triceps Pushdown', 'Triceps Pushdown Rope', 'Pushdown'],
  'dips': ['Dips', 'Dip', 'Parallel Bar Dips'],
  'back_squat': ['Squat', 'Barbell Squat', 'Back Squat'],
  'leg_press': ['Leg Press', 'Leg Presses'],
  'romanian_deadlift': ['Romanian Deadlift', 'Stiff-legged Deadlift'],
  'bodyweight_squat': ['Bodyweight Squat', 'Air Squat', 'Squats'],
  'lunge': ['Lunge', 'Lunges', 'Dumbbell Lunges'],
  'hip_thrust': ['Hip Thrust', 'Barbell Hip Thrust'],
  'glute_bridge': ['Glute Bridge', 'Hip Raise', 'Bridge'],
  'plank': ['Plank', 'Front Plank'],
  'crunch': ['Crunch', 'Crunches'],
  'mountain_climber': ['Mountain Climber', 'Mountain Climbers'],
  'jumping_jack': ['Jumping Jack', 'Jumping Jacks'],
  'dumbbell_bench_press': ['Dumbbell Bench Press', 'Bench Press Dumbbells'],
  'incline_bench_press': ['Incline Bench Press', 'Incline Barbell Bench Press'],
  'chest_press_machine': ['Chest Press Machine', 'Machine Chest Press', 'Chest Press'],
  'pec_deck': ['Pec Deck', 'Butterfly', 'Machine Fly'],
  'seated_cable_row': ['Seated Cable Row', 'Seated Row', 'Cable Row'],
  'one_arm_dumbbell_row': ['One Arm Dumbbell Row', 'Dumbbell Row', 'Single Arm Row'],
  'chin_up': ['Chin-Up', 'Chin Up', 'Chin-ups'],
  'dumbbell_shoulder_press': ['Dumbbell Shoulder Press', 'Shoulder Press, Dumbbells', 'Seated Dumbbell Press'],
  'rear_delt_fly': ['Rear Delt Fly', 'Reverse Fly', 'Bent Over Lateral Raise'],
  'face_pull': ['Face Pull', 'Face Pulls'],
  'barbell_curl': ['Barbell Curl', 'Biceps Curls With Barbell'],
  'hammer_curl': ['Hammer Curl', 'Hammercurls'],
  'cable_curl': ['Cable Curl', 'Biceps Curl Cable'],
  'skull_crusher': ['Skull Crusher', 'Skullcrusher', 'French Press'],
  'overhead_triceps_extension': ['Overhead Triceps Extension', 'Triceps Extension Dumbbell', 'Overhead Extension'],
  'close_grip_bench_press': ['Close-Grip Bench Press', 'Close Grip Bench Press', 'Bench Press Narrow Grip'],
  'front_squat': ['Front Squat', 'Front Squats'],
  'goblet_squat': ['Goblet Squat'],
  'bulgarian_split_squat': ['Bulgarian Split Squat', 'Split Squat'],
  'leg_extension': ['Leg Extension', 'Leg Extensions'],
  'leg_curl': ['Leg Curl', 'Leg Curls (laying)', 'Lying Leg Curl'],
  'calf_raise': ['Calf Raise', 'Standing Calf Raises', 'Calf Raises'],
  'hanging_leg_raise': ['Hanging Leg Raise', 'Hanging Leg Raises', 'Leg Raises, Hanging'],
  'cable_crunch': ['Cable Crunch', 'Kneeling Cable Crunch'],
  'dead_bug': ['Dead Bug', 'Deadbug'],
  'side_plank': ['Side Plank'],
  'burpee': ['Burpee', 'Burpees'],
  'kettlebell_swing': ['Kettlebell Swing', 'Kettlebell Swings'],
};

final _client = HttpClient()..userAgent = 'fitness_app-seed-import/1.0';

Future<void> main() async {
  final assetsDir = Directory('assets/exercises');
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Spusť skript z kořene projektu (tam, kde je pubspec.yaml).');
    exitCode = 1;
    return;
  }
  assetsDir.createSync(recursive: true);

  final entries = <String, _Chosen>{};
  final report = StringBuffer(
      'slug,wger_id,wger_name,score,images,ai_generated,alternatives\n');

  for (final slug in _searchTerms.keys) {
    stdout.write('${slug.padRight(28)} ');
    try {
      final chosen = await _choose(slug);
      if (chosen == null) {
        stdout.writeln('– nenalezeno');
        report.writeln('$slug,,,0,0,,');
        continue;
      }
      final images = await _download(slug, chosen, assetsDir);
      if (images.isEmpty) {
        stdout.writeln('– ${chosen.name} (#${chosen.id}) bez obrázků');
      } else {
        stdout.writeln('✓ ${chosen.name} (#${chosen.id}), '
            '${images.length} obr.');
        entries[slug] = chosen.copyWith(images: images);
      }
      report.writeln([
        slug,
        chosen.id,
        _csv(chosen.name),
        chosen.score,
        images.length,
        images.any((i) => i.aiGenerated) ? 'yes' : '',
        _csv(chosen.alternatives.join(' | ')),
      ].join(','));
    } catch (e) {
      stdout.writeln('✗ chyba: $e');
      report.writeln('$slug,,,0,0,,');
    }
    // Ohleduplnost k serveru projektu wger.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  File('tool/wger_report.csv').writeAsStringSync(report.toString());
  File('lib/data/seed/exercise_media.dart')
      .writeAsStringSync(_generateDart(entries));
  _client.close();

  stdout.writeln('\nHotovo: ${entries.length} z ${_searchTerms.length} cviků '
      'má obrázky.');
  stdout.writeln('Zkontroluj tool/wger_report.csv. Pak spusť flutter run.');
}

class _Image {
  _Image({
    required this.asset,
    required this.author,
    required this.authorUrl,
    required this.license,
    required this.aiGenerated,
  });

  final String asset;
  final String author;
  final String? authorUrl;
  final String license;
  final bool aiGenerated;
}

class _Chosen {
  _Chosen({
    required this.id,
    required this.name,
    required this.score,
    required this.rawImages,
    required this.alternatives,
    this.images = const [],
  });

  final int id;
  final String name;
  final int score;
  final List<Map<String, dynamic>> rawImages;
  final List<String> alternatives;
  final List<_Image> images;

  _Chosen copyWith({required List<_Image> images}) => _Chosen(
        id: id,
        name: name,
        score: score,
        rawImages: rawImages,
        alternatives: alternatives,
        images: images,
      );
}

Future<Map<String, dynamic>> _getJson(String url) async {
  final req = await _client.getUrl(Uri.parse(url));
  req.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final res = await req.close().timeout(const Duration(seconds: 30));
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode} pro $url');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

String _englishName(Map<String, dynamic> info) {
  final translations = (info['translations'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  for (final t in translations) {
    if (t['language'] == _englishLanguageId) return '${t['name']}';
  }
  return translations.isEmpty ? '' : '${translations.first['name']}';
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

int _score(String name, List<String> terms, bool hasImages) {
  final n = _norm(name);
  var best = 0;
  for (var i = 0; i < terms.length; i++) {
    final t = _norm(terms[i]);
    var s = 0;
    if (n == t) {
      s = 100;
    } else if (n == '${t}s' || '${n}s' == t) {
      s = 95;
    } else if (n.contains(t)) {
      s = 70 - (n.length - t.length).clamp(0, 40);
    } else {
      final nt = n.split(' ').toSet();
      final tt = t.split(' ').toSet();
      final common = nt.intersection(tt).length;
      if (common > 0) s = (40 * common / tt.length).round();
    }
    s -= i * 3; // hlavní název má přednost
    if (s > best) best = s;
  }
  return best + (hasImages ? 30 : 0);
}

Future<_Chosen?> _choose(String slug) async {
  final override = _overrides[slug];
  if (override != null) {
    final info = await _getJson('$_api/exerciseinfo/$override/');
    return _Chosen(
      id: override,
      name: _englishName(info),
      score: 999,
      rawImages: _images(info),
      alternatives: const [],
    );
  }

  final terms = _searchTerms[slug]!;
  final candidates = <int, ({String name, int score, List<Map<String, dynamic>> images})>{};
  for (final term in terms) {
    final url = '$_api/exerciseinfo/?language__code=en&limit=10'
        '&name__search=${Uri.encodeQueryComponent(term)}';
    final data = await _getJson(url);
    for (final r in (data['results'] as List? ?? const [])
        .cast<Map<String, dynamic>>()) {
      final id = r['id'] as int;
      final name = _englishName(r);
      if (name.isEmpty) continue;
      final images = _images(r);
      final score = _score(name, terms, images.isNotEmpty);
      final prev = candidates[id];
      if (prev == null || prev.score < score) {
        candidates[id] = (name: name, score: score, images: images);
      }
    }
    // Přesná shoda s obrázky – dál hledat nemusíme.
    if (candidates.values.any((c) => c.score >= 125)) break;
  }
  if (candidates.isEmpty) return null;

  final sorted = candidates.entries.toList()
    ..sort((a, b) => b.value.score.compareTo(a.value.score));
  final best = sorted.first;
  if (best.value.score < 40) return null;
  return _Chosen(
    id: best.key,
    name: best.value.name,
    score: best.value.score,
    rawImages: best.value.images,
    alternatives: [
      for (final c in sorted.skip(1).take(3)) '#${c.key} ${c.value.name}',
    ],
  );
}

List<Map<String, dynamic>> _images(Map<String, dynamic> info) {
  final list = (info['images'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .where((i) {
    final url = '${i['image']}'.toLowerCase();
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }).toList()
    // Hlavní obrázek první, pak podle ID (obvykle výchozí → koncová poloha).
    ..sort((a, b) {
      final main = ((b['is_main'] == true) ? 1 : 0) -
          ((a['is_main'] == true) ? 1 : 0);
      if (main != 0) return main;
      return (a['id'] as int? ?? 0).compareTo(b['id'] as int? ?? 0);
    });
  return list;
}

Future<List<_Image>> _download(
  String slug,
  _Chosen chosen,
  Directory dir,
) async {
  // Staré obrázky cviku smažeme, ať po opravě přiřazení nezůstanou.
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('${slug}_')) f.deleteSync();
  }
  final result = <_Image>[];
  for (final raw in chosen.rawImages.take(_maxImagesPerExercise)) {
    var url = '${raw['image']}';
    if (url.startsWith('/')) url = 'https://wger.de$url';
    final ext = url.split('.').last.toLowerCase();
    final asset = 'assets/exercises/${slug}_${result.length + 1}.$ext';
    final req = await _client.getUrl(Uri.parse(url));
    final res = await req.close().timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      await res.drain<void>();
      continue;
    }
    final bytes = await res.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    File(asset).writeAsBytesSync(bytes);
    final author = '${raw['license_author'] ?? ''}'.trim();
    final authorUrl = '${raw['license_author_url'] ?? ''}'.trim();
    result.add(_Image(
      asset: asset,
      author: author.isEmpty ? 'wger.de' : author,
      authorUrl: authorUrl.isEmpty ? null : authorUrl,
      license: '${raw['license_title'] ?? 'CC BY-SA 4.0'}'.trim(),
      aiGenerated: raw['is_ai_generated'] == true,
    ));
  }
  return result;
}

String _csv(String s) =>
    s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;

String _dartString(String s) =>
    "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

String _generateDart(Map<String, _Chosen> entries) {
  final b = StringBuffer()
    ..writeln('// Vygenerováno skriptem tool/wger_import.dart – neupravuj ručně.')
    ..writeln('// Obrázky: projekt wger.de, licence uvedené u každého obrázku.')
    ..writeln()
    ..writeln("import 'exercise_media_types.dart';")
    ..writeln()
    ..writeln("export 'exercise_media_types.dart';")
    ..writeln()
    ..writeln('const exerciseMedia = <String, ExerciseMedia>{');
  for (final e in entries.entries) {
    final c = e.value;
    b
      ..writeln('  ${_dartString(e.key)}: ExerciseMedia(')
      ..writeln('    wgerId: ${c.id},')
      ..writeln('    images: [');
    for (final i in c.images) {
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
