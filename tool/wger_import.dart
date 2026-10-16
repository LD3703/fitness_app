// Stáhne obrázky cviků z otevřené databáze wger.de a přibalí je do aplikace.
//
// Spuštění z kořene projektu (potřebuje internet):
//   dart run tool/wger_import.dart
//
// Co udělá:
//  1. Pro každý vestavěný cvik najde na wger.de nejlépe odpovídající cvik
//     (podle anglického názvu). Má-li cvik animovaný GIF / WebP, stáhne
//     ho (přednost); jinak stáhne až 2 obrázky (výchozí a koncová
//     poloha – v aplikaci se střídají jako jednoduchá animace).
//  2. Obrázky stáhne do dočasné složky .dart_tool/wger_import/ a až na
//     konci je přesune do assets/exercises/<slug>_<n>.<přípona>. Když
//     stažení cviku selže (výpadek sítě), cvik si ponechá předchozí
//     obrázky. Staré nepoužívané soubory se smažou až po zápisu manifestu.
//  3. Zapíše tool/media/wger_media.json a vygeneruje
//     lib/data/seed/exercise_media.dart s cestami a autory (licence
//     CC BY-SA vyžaduje uvést autora – aplikace ho zobrazuje). Koupené
//     animace z tool/media_import.dart mají přednost a zůstanou.
//  4. Zapíše tool/wger_report.csv – zkontroluj, jestli sedí přiřazení.
//     Špatné přiřazení oprav v mapě _overrides níže (slug → ID cviku
//     na wger.de; ID je v adrese https://wger.de/en/exercise/<ID>/view/)
//     a skript spusť znovu.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'media/media_manifest.dart';

const _api = 'https://wger.de/api/v2';
const _englishLanguageId = 2;
const _maxImagesPerExercise = 2;

/// Kolik kandidátů na animaci (GIF / WebP) se nejvýš stáhne a ověří.
const _maxAnimatedCandidates = 3;

/// Ruční přiřazení slug → ID cviku na wger.de (má přednost před hledáním).
const _overrides = <String, int>{
  // 'bench_press': 192,
  // Ověřené shody, které by přísný filtr (_acceptable) zahodil kvůli
  // vybavení v názvu na wger.de.
  'goblet_squat': 203, // Dumbbell Goblet Squat
  'skull_crusher': 246, // Skullcrusher SZ-bar
  'wrist_curl': 51, // Barbell Wrist Curl
  'straight_arm_pulldown': 1726, // Straight-Arm Pulldown (Cable)
  'upright_row': 693, // Upright Row, SZ-bar
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
  'weighted_pull_up': ['Weighted Pull-Up', 'Weighted Pull Up', 'Pull-Up'],
  'weighted_dips': ['Weighted Dips', 'Weighted Dip', 'Dips'],
  'barbell_shrug': ['Barbell Shrug', 'Shrugs, Barbells', 'Shrug'],
  'dumbbell_shrug': ['Dumbbell Shrug', 'Shrugs, Dumbbells', 'Shrug'],
  'wrist_curl': ['Wrist Curl', 'Dumbbell Wrist Curl', 'Wrist Curls'],
  'reverse_curl': ['Reverse Curl', 'Reverse Barbell Curl', 'Reverse Grip Curl'],
  'dead_hang': ['Dead Hang', 'Bar Hang'],
  'back_extension': ['Back Extension', 'Hyperextensions', 'Hyperextension'],
  'good_morning': ['Good Morning', 'Good Mornings', 'Barbell Good Morning'],
  'superman': ['Superman', 'Supermans', 'Prone Back Extension'],
  'decline_bench_press': ['Decline Bench Press', 'Decline Barbell Bench Press'],
  'smith_bench_press': ['Smith Machine Bench Press', 'Bench Press Smith Machine'],
  'dumbbell_fly': ['Dumbbell Fly', 'Flys With Dumbbells', 'Dumbbell Flyes'],
  'incline_dumbbell_fly': ['Incline Dumbbell Fly', 'Incline Dumbbell Flyes', 'Fly With Dumbbells, Incline'],
  'low_to_high_cable_fly': ['Low to High Cable Fly', 'Cable Fly Low', 'Cable Crossover Low'],
  'incline_chest_press_machine': ['Incline Chest Press Machine', 'Incline Machine Press'],
  'chest_dips': ['Chest Dips', 'Dips Chest', 'Dips'],
  'incline_push_up': ['Incline Push-up', 'Incline Push Up', 'Incline Pushups'],
  'decline_push_up': ['Decline Push-up', 'Decline Push Up', 'Decline Pushups'],
  'dumbbell_floor_press': ['Dumbbell Floor Press', 'Floor Press'],
  't_bar_row': ['T-Bar Row', 'T Bar Row', 'Landmine Row'],
  'pendlay_row': ['Pendlay Row', 'Pendlay Rows'],
  'machine_row': ['Machine Row', 'Seated Row Machine', 'Row Machine'],
  'chest_supported_row': ['Chest Supported Dumbbell Row', 'Incline Dumbbell Row', 'Chest Supported Row'],
  'close_grip_lat_pulldown': ['Close Grip Lat Pulldown', 'Lat Pulldown Close Grip', 'V-Bar Pulldown'],
  'straight_arm_pulldown': ['Straight Arm Pulldown', 'Straight-Arm Pull Down', 'Lat Pushdown'],
  'band_assisted_pull_up': ['Band Assisted Pull-up', 'Assisted Pull-Up', 'Pull-Up Assisted'],
  'inverted_row': ['Inverted Row', 'Australian Pull-Up', 'Bodyweight Row'],
  'neutral_grip_pull_up': ['Neutral Grip Pull-up', 'Hammer Grip Pull-Up', 'Parallel Grip Pull-Up'],
  'rack_pull': ['Rack Pull', 'Rack Pulls', 'Partial Deadlift'],
  'trap_bar_deadlift': ['Trap Bar Deadlift', 'Hex Bar Deadlift'],
  'single_arm_cable_row': ['Single Arm Cable Row', 'One Arm Cable Row'],
  'dumbbell_pullover': ['Dumbbell Pullover', 'Pullover', 'Pullover Dumbbell'],
  'renegade_row': ['Renegade Row', 'Plank Row'],
  'arnold_press': ['Arnold Press', 'Arnold Shoulder Press'],
  'shoulder_press_machine': ['Shoulder Press Machine', 'Machine Shoulder Press'],
  'push_press': ['Push Press', 'Barbell Push Press'],
  'cable_lateral_raise': ['Cable Lateral Raise', 'Lateral Raises on Cable', 'Single Arm Cable Lateral Raise'],
  'machine_lateral_raise': ['Machine Lateral Raise', 'Lateral Raise Machine'],
  'front_raise': ['Front Raise', 'Front Raises', 'Dumbbell Front Raise'],
  'upright_row': ['Upright Row', 'Upright Row, Barbell'],
  'reverse_pec_deck': ['Reverse Pec Deck', 'Reverse Machine Fly', 'Rear Delt Machine'],
  'band_pull_apart': ['Band Pull Apart', 'Band Pull-Aparts'],
  'handstand_push_up': ['Handstand Push-up', 'Handstand Push Up'],
  'landmine_press': ['Landmine Press', 'Single Arm Landmine Press'],
  'preacher_curl': ['Preacher Curl', 'Preacher Curls', 'Biceps Curl on Preacher Bench'],
  'concentration_curl': ['Concentration Curl', 'Concentration Curls'],
  'incline_dumbbell_curl': ['Incline Dumbbell Curl', 'Incline Curl'],
  'ez_bar_curl': ['EZ Bar Curl', 'Biceps Curl With EZ-Bar', 'EZ-Bar Curl'],
  'rope_hammer_curl': ['Rope Hammer Curl', 'Cable Hammer Curl'],
  'machine_biceps_curl': ['Machine Biceps Curl', 'Biceps Curl Machine'],
  'band_curl': ['Band Curl', 'Resistance Band Curl'],
  'rope_pushdown': ['Rope Pushdown', 'Triceps Pushdown Rope', 'Rope Triceps Extension'],
  'overhead_cable_extension': ['Overhead Cable Triceps Extension', 'Cable Overhead Extension', 'Overhead Rope Extension'],
  'triceps_kickback': ['Triceps Kickback', 'Dumbbell Kickback', 'Kickbacks'],
  'bench_dips': ['Bench Dips', 'Bench Dip', 'Dips Between Two Benches'],
  'machine_triceps_dip': ['Machine Triceps Dip', 'Seated Dip Machine', 'Dip Machine'],
  'single_arm_pushdown': ['Single Arm Pushdown', 'One Arm Triceps Pushdown'],
  'diamond_push_up': ['Diamond Push-up', 'Diamond Push Up', 'Close Grip Push-Up'],
  'reverse_wrist_curl': ['Reverse Wrist Curl', 'Wrist Extension'],
  'hack_squat': ['Hack Squat', 'Machine Hack Squat'],
  'smith_squat': ['Smith Machine Squat', 'Squats on Smith Machine'],
  'walking_lunge': ['Walking Lunge', 'Walking Lunges', 'Dumbbell Walking Lunge'],
  'reverse_lunge': ['Reverse Lunge', 'Reverse Lunges', 'Dumbbell Reverse Lunge'],
  'step_up': ['Step-up', 'Step Up', 'Dumbbell Step-Up'],
  'split_squat': ['Split Squat', 'Dumbbell Split Squat'],
  'sumo_squat': ['Sumo Squat', 'Dumbbell Sumo Squat', 'Plie Squat'],
  'pistol_squat': ['Pistol Squat', 'Single Leg Squat', 'One Legged Squat'],
  'single_leg_press': ['Single Leg Press', 'One Leg Press'],
  'hip_adduction_machine': ['Hip Adduction Machine', 'Adductor Machine', 'Hip Adduction'],
  'wall_sit': ['Wall Sit', 'Wall Squat'],
  'jump_squat': ['Jump Squat', 'Squat Jumps', 'Jump Squats'],
  'box_jump': ['Box Jump', 'Box Jumps'],
  'seated_leg_curl': ['Seated Leg Curl', 'Leg Curls (sitting)', 'Seated Hamstring Curl'],
  'nordic_curl': ['Nordic Hamstring Curl', 'Nordic Curl'],
  'single_leg_rdl': ['Single Leg Romanian Deadlift', 'Single Leg Deadlift', 'One Leg RDL'],
  'dumbbell_romanian_deadlift': ['Dumbbell Romanian Deadlift', 'Romanian Deadlift Dumbbell', 'Dumbbell RDL'],
  'stiff_leg_deadlift': ['Stiff-Leg Deadlift', 'Stiff Legged Deadlift', 'Straight Leg Deadlift'],
  'stability_ball_leg_curl': ['Stability Ball Leg Curl', 'Swiss Ball Leg Curl', 'Ball Leg Curl'],
  'sumo_deadlift': ['Sumo Deadlift', 'Deadlift Sumo'],
  'cable_glute_kickback': ['Cable Glute Kickback', 'Cable Kickback', 'Glute Kickback'],
  'hip_abduction_machine': ['Hip Abduction Machine', 'Abductor Machine', 'Hip Abduction'],
  'machine_hip_thrust': ['Hip Thrust Machine', 'Machine Hip Thrust', 'Glute Drive'],
  'single_leg_glute_bridge': ['Single Leg Glute Bridge', 'One Leg Glute Bridge'],
  'donkey_kick': ['Donkey Kick', 'Donkey Kicks', 'Quadruped Hip Extension'],
  'fire_hydrant': ['Fire Hydrant', 'Fire Hydrants'],
  'banded_lateral_walk': ['Banded Lateral Walk', 'Lateral Band Walk', 'Monster Walk'],
  'cable_pull_through': ['Cable Pull Through', 'Pull-Through'],
  'seated_calf_raise': ['Seated Calf Raise', 'Calf Raises, Seated'],
  'single_leg_calf_raise': ['Single Leg Calf Raise', 'One Leg Calf Raise'],
  'leg_press_calf_raise': ['Leg Press Calf Raise', 'Calf Press', 'Calf Press on Leg Press'],
  'sit_up': ['Sit-up', 'Sit Up', 'Sit-ups'],
  'decline_sit_up': ['Decline Sit-up', 'Decline Sit Up', 'Sit-ups on Decline Bench'],
  'bicycle_crunch': ['Bicycle Crunch', 'Bicycle Crunches'],
  'reverse_crunch': ['Reverse Crunch', 'Reverse Crunches'],
  'lying_leg_raise': ['Lying Leg Raise', 'Leg Raises, Lying', 'Leg Raise'],
  'captains_chair_knee_raise': ['Captains Chair Knee Raise', 'Knee Raise', 'Vertical Knee Raise'],
  'ab_wheel_rollout': ['Ab Wheel Rollout', 'Ab Roller', 'Ab Wheel'],
  'russian_twist': ['Russian Twist', 'Russian Twists'],
  'v_up': ['V-up', 'V Up', 'V-ups'],
  'hollow_hold': ['Hollow Body Hold', 'Hollow Hold'],
  'pallof_press': ['Pallof Press', 'Pallof'],
  'cable_woodchopper': ['Cable Woodchopper', 'Woodchopper', 'Cable Wood Chop'],
  'plank_shoulder_tap': ['Plank Shoulder Tap', 'Shoulder Taps'],
  'bird_dog': ['Bird Dog', 'Bird Dogs', 'Quadruped Arm Leg Raise'],
  'power_clean': ['Power Clean', 'Clean', 'Barbell Power Clean'],
  'thruster': ['Thruster', 'Barbell Thruster', 'Thrusters'],
  'turkish_get_up': ['Turkish Get-up', 'Turkish Get Up'],
  'bear_crawl': ['Bear Crawl', 'Bear Crawls'],
  'high_knees': ['High Knees', 'High Knee Run'],
  'jump_rope': ['Jump Rope', 'Skipping Rope', 'Rope Jumping'],
  'rowing_machine': ['Rowing Machine', 'Rowing', 'Rower'],
  'stationary_bike': ['Stationary Bike', 'Exercise Bike', 'Cycling'],
  'treadmill_run': ['Treadmill Run', 'Treadmill', 'Running'],
  'elliptical': ['Elliptical Trainer', 'Elliptical', 'Cross Trainer'],
  'stair_climber': ['Stair Climber', 'Stairmaster', 'Stair Machine'],
  'air_bike': ['Air Bike', 'Assault Bike', 'Fan Bike'],
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

  // Obrázky se stahují nejdřív do dočasné složky (.dart_tool je
  // v .gitignore). Do assets/exercises/ se přesunou až na konci, staré se
  // smažou až po zápisu manifestu – přerušený běh nic nerozbije.
  final staging = Directory('.dart_tool/wger_import');
  if (staging.existsSync()) staging.deleteSync(recursive: true);
  staging.createSync(recursive: true);

  // Dosavadní položky: cvik, jehož stažení selže, si je ponechá.
  final previous = _previousEntries();
  final entries = <String, MediaEntry>{};
  final staged = <String, String>{}; // dočasný soubor → cíl v assets
  var kept = 0;
  final report = StringBuffer(
      'slug,wger_id,wger_name,score,images,animated,ai_generated,alternatives\n');

  /// Ponechá předchozí obrázky cviku (jsou-li všechny soubory na místě).
  bool keepPrevious(String slug) {
    final old = previous[slug];
    if (old == null || old.images.isEmpty) return false;
    if (!old.images.every((i) => File(i.asset).existsSync())) return false;
    entries[slug] = old;
    kept++;
    return true;
  }

  for (final slug in _searchTerms.keys) {
    stdout.write('${slug.padRight(28)} ');
    try {
      final chosen = await _choose(slug);
      if (chosen == null) {
        stdout.writeln('– nenalezeno');
        report.writeln('$slug,,,0,0,,,');
        continue;
      }
      final d = await _download(slug, chosen, staging);
      if (!d.complete && keepPrevious(slug)) {
        stdout.writeln('! ${chosen.name} (#${chosen.id}): stažení selhalo, '
            'ponechány předchozí obrázky');
      } else if (d.images.isEmpty) {
        stdout.writeln(d.complete
            ? '– ${chosen.name} (#${chosen.id}) bez obrázků'
            : '✗ ${chosen.name} (#${chosen.id}): obrázky se nepodařilo stáhnout');
      } else {
        stdout.writeln('✓ ${chosen.name} (#${chosen.id}), '
            '${d.animated ? 'animace' : '${d.images.length} obr.'}');
        entries[slug] = MediaEntry(
          wgerId: chosen.id,
          animated: d.animated,
          images: d.images,
        );
        staged.addAll(d.staged);
      }
      report.writeln([
        slug,
        chosen.id,
        _csv(chosen.name),
        chosen.score,
        d.images.length,
        d.animated ? 'yes' : '',
        d.images.any((i) => i.aiGenerated) ? 'yes' : '',
        _csv(chosen.alternatives.join(' | ')),
      ].join(','));
    } catch (e) {
      stdout.writeln(keepPrevious(slug)
          ? '✗ chyba: $e – ponechány předchozí obrázky'
          : '✗ chyba: $e');
      report.writeln('$slug,,,0,0,,,');
    }
    // Ohleduplnost k serveru projektu wger.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  _client.close();

  // Výměna až po dokončení všech stažení: nové soubory do assets,
  // manifest a exercise_media.dart, nakonec smazat nepoužívané staré.
  staged.forEach((tmp, target) => _moveFile(File(tmp), target));
  File('tool/wger_report.csv').writeAsStringSync(report.toString());
  writeManifest(wgerManifestPath, entries);
  final merged = regenerateMediaDart();
  _removeUnused(assetsDir);
  try {
    staging.deleteSync(recursive: true);
  } on FileSystemException {
    // Nevadí – smaže se při dalším spuštění.
  }

  final purchased = readManifest(purchasedManifestPath);
  stdout.writeln('\nHotovo: ${entries.length} z ${_searchTerms.length} cviků '
      'má obrázky z wger.de'
      '${kept == 0 ? '' : ' ($kept s předchozími obrázky – stažení selhalo)'}'
      '${purchased.isEmpty ? '' : ', ${purchased.length} koupených animací má přednost'}'
      ' (celkem ${merged.length}).');
  stdout.writeln('Zkontroluj tool/wger_report.csv. Pak spusť flutter run.');
}

/// Položky wger.de z minulého běhu: z manifestu, u starší verze skriptu
/// (bez manifestu) z vygenerovaného exercise_media.dart.
Map<String, MediaEntry> _previousEntries() {
  if (File(wgerManifestPath).existsSync()) {
    return readManifest(wgerManifestPath);
  }
  final dart = File(mediaDartPath);
  if (!dart.existsSync()) return {};
  return {
    for (final e in parseGeneratedMediaDart(dart.readAsStringSync()).entries)
      if (e.value.wgerId != null) e.key: e.value,
  };
}

/// Smaže obrázky z wger.de (`<slug>_<n>.<přípona>`), na které už neodkazuje
/// žádný manifest – např. po opravě přiřazení. Koupené animace
/// (`<slug>.gif`) mají jiný název a zůstanou.
void _removeUnused(Directory dir) {
  final used = <String>{
    for (final m in [
      readManifest(wgerManifestPath),
      readManifest(purchasedManifestPath),
    ])
      for (final entry in m.values)
        for (final img in entry.images) img.asset,
  };
  final own = RegExp(r'^([a-z0-9_]+)_\d+\.(png|jpe?g|gif|webp)$');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    final m = own.firstMatch(name);
    if (m == null || !_searchTerms.containsKey(m.group(1))) continue;
    if (used.contains('$exerciseAssetsDir/$name')) continue;
    f.deleteSync();
  }
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

class _Chosen {
  _Chosen({
    required this.id,
    required this.name,
    required this.score,
    required this.rawImages,
    required this.alternatives,
  });

  final int id;
  final String name;
  final int score;
  final List<Map<String, dynamic>> rawImages;
  final List<String> alternatives;
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

/// Slova, která mění cvik (jiné vybavení, poloha, varianta). Když je
/// název na wger.de má navíc oproti hledanému výrazu, je to jiný cvik
/// (např. „Incline Bench Press“ pro bench press) – obrázek se nepoužije.
const _modifiers = {
  'incline', 'decline', 'cable', 'dumbbell', 'barbell', 'machine', 'smith',
  'seated', 'standing', 'lying', 'single', 'one', 'reverse', 'close', 'wide',
  'narrow', 'sz', 'ez', 'kettlebell', 'band', 'banded', 'side', 'front',
  'rear', 'alternating', 'alternate', 'overhead', 'hammer', 'weighted',
  'assisted', 'box', 'jump', 'jumping', 'clap', 'sumo', 'romanian', 'stiff',
  'bulgarian', 'split', 'goblet', 'hack', 'landmine', 'trap', 'rack',
  'deficit', 'low', 'high', 'upper', 'lower', 'plank', 'diamond', 'kneeling',
  'leg', 'arm', 'row', 'press', 'curl', 'raise', 'extension', 'fly',
  'pulldown', 'pull', 'push', 'dip', 'crunch', 'squat', 'lunge', 'deadlift',
  'circle', 'circles', 'monster', 'walk', 'walking', 'mark', 'lauren',
};

Set<String> _tokens(String s) => {
      for (final w in _norm(s).split(' '))
        if (w.isNotEmpty)
          w.length > 2 && w.endsWith('s') && !w.endsWith('ss')
              ? w.substring(0, w.length - 1)
              : w,
    };

/// Je [name] z wger.de opravdu hledaný cvik? Všechna slova některého
/// hledaného výrazu musí v názvu být a navíc tam nesmí být slovo, které
/// cvik mění ([_modifiers]). Ruční přiřazení (_overrides) se nekontroluje.
bool _acceptable(String name, List<String> terms) {
  final n = _tokens(name);
  for (final term in terms) {
    final t = _tokens(term);
    if (t.isEmpty || !n.containsAll(t)) continue;
    if (n.difference(t).any(_modifiers.contains)) continue;
    return true;
  }
  return false;
}

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
      if (!_acceptable(name, terms)) continue;
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

/// Stáhne soubor (null = chyba).
Future<List<int>?> _fetch(String url) async {
  final req = await _client.getUrl(Uri.parse(url));
  final res = await req.close().timeout(const Duration(seconds: 60));
  if (res.statusCode != 200) {
    await res.drain<void>();
    return null;
  }
  return res.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
}

String _absoluteUrl(Map<String, dynamic> raw) {
  final url = '${raw['image']}';
  return url.startsWith('/') ? 'https://wger.de$url' : url;
}

MediaImage _imageFrom(Map<String, dynamic> raw, String asset) {
  final author = '${raw['license_author'] ?? ''}'.trim();
  final authorUrl = '${raw['license_author_url'] ?? ''}'.trim();
  return MediaImage(
    asset: asset,
    author: author.isEmpty ? 'wger.de' : author,
    authorUrl: authorUrl.isEmpty ? null : authorUrl,
    // Obrázky na wger.de jsou pod CC BY-SA 4.0. Pole license_title je
    // název díla (např. „Bird Dog“), ne název licence.
    license: 'CC BY-SA 4.0',
    aiGenerated: raw['is_ai_generated'] == true,
  );
}

/// Výsledek stažení jednoho cviku. [complete] = false, když se některý
/// soubor nepodařilo stáhnout; [staged] = dočasný soubor → cíl v assets.
typedef _Download = ({
  List<MediaImage> images,
  bool animated,
  bool complete,
  Map<String, String> staged,
});

/// Stáhne obrázky cviku do dočasné složky [staging]. MediaImage.asset už
/// obsahuje konečnou cestu v assets/exercises/ (přesun dělá main).
Future<_Download> _download(
  String slug,
  _Chosen chosen,
  Directory staging,
) async {
  final staged = <String, String>{};
  var complete = true;

  // 1) Animovaný GIF / WebP má přednost (ověří se podle obsahu souboru).
  final candidates = chosen.rawImages.where((raw) {
    final url = _absoluteUrl(raw).toLowerCase();
    return url.endsWith('.gif') || url.endsWith('.webp');
  }).take(_maxAnimatedCandidates);
  for (final raw in candidates) {
    final url = _absoluteUrl(raw);
    final bytes = await _fetch(url);
    if (bytes == null) {
      complete = false;
      continue;
    }
    if (!isAnimatedImage(bytes)) continue;
    final name = '${slug}_1.${url.split('.').last.toLowerCase()}';
    final tmp = '${staging.path}/$name';
    File(tmp).writeAsBytesSync(bytes);
    staged[tmp] = '$exerciseAssetsDir/$name';
    return (
      images: [_imageFrom(raw, '$exerciseAssetsDir/$name')],
      animated: true,
      complete: true,
      staged: staged,
    );
  }

  // 2) Jinak až 2 statické obrázky (výchozí a koncová poloha).
  final result = <MediaImage>[];
  for (final raw in chosen.rawImages.take(_maxImagesPerExercise)) {
    final url = _absoluteUrl(raw);
    final bytes = await _fetch(url);
    if (bytes == null) {
      complete = false;
      continue;
    }
    final name =
        '${slug}_${result.length + 1}.${url.split('.').last.toLowerCase()}';
    final tmp = '${staging.path}/$name';
    File(tmp).writeAsBytesSync(bytes);
    staged[tmp] = '$exerciseAssetsDir/$name';
    result.add(_imageFrom(raw, '$exerciseAssetsDir/$name'));
  }
  return (
    images: result,
    animated: false,
    complete: complete,
    staged: staged,
  );
}

String _csv(String s) =>
    s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
