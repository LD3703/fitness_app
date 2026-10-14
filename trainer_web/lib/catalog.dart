// Katalog vestavěných cviků (assets/exercises.json – generuje
// tool/trainer_catalog.dart z dat aplikace). Slug propojí cvik v plánu
// s cvikem v aplikaci klienta.
import 'dart:convert';

import 'package:flutter/services.dart';

class CatalogExercise {
  const CatalogExercise({
    required this.slug,
    required this.en,
    required this.cs,
    required this.muscle,
    required this.equipment,
    required this.type,
  });

  final String slug;
  final String en;
  final String cs;
  final String muscle;
  final String equipment;
  final String type;

  String nameFor(String lang) => lang == 'cs' ? cs : en;
}

/// Pořadí partií ve filtru (jako v aplikaci).
const muscleOrder = [
  'chest', 'back', 'traps', 'lowerBack', 'shoulders', 'biceps', 'triceps',
  'forearms', 'core', 'quads', 'hamstrings', 'glutes', 'calves', 'legs',
  'fullBody',
];

const equipmentOrder = [
  'barbell', 'dumbbell', 'machine', 'cable', 'bodyweight', 'kettlebell', 'band',
];

const typeOrder = ['weightReps', 'bodyweightReps', 'duration'];

class Catalog {
  Catalog._(this.exercises) : _bySlug = {for (final e in exercises) e.slug: e};

  final List<CatalogExercise> exercises;
  final Map<String, CatalogExercise> _bySlug;

  static Future<Catalog>? _loading;

  static Future<Catalog> load() => _loading ??= _load();

  static Future<Catalog> _load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/exercises.json'))
        as List<dynamic>;
    return Catalog._([
      for (final m in raw.cast<Map<String, dynamic>>())
        CatalogExercise(
          slug: m['slug'] as String,
          en: m['en'] as String,
          cs: m['cs'] as String,
          muscle: m['muscle'] as String,
          equipment: m['equipment'] as String,
          type: m['type'] as String,
        ),
    ]);
  }

  CatalogExercise? bySlug(String? slug) => slug == null ? null : _bySlug[slug];

  /// Cviky podle textu (v obou jazycích, bez diakritiky) a partie.
  List<CatalogExercise> search(String query, {String? muscle, required String lang}) {
    final q = foldForSearch(query.trim());
    final list = [
      for (final e in exercises)
        if ((muscle == null || e.muscle == muscle) &&
            (q.isEmpty ||
                foldForSearch(e.cs).contains(q) ||
                foldForSearch(e.en).contains(q)))
          e,
    ]..sort((a, b) => a.nameFor(lang).compareTo(b.nameFor(lang)));
    return list;
  }
}

const _fold = {
  'á': 'a', 'ä': 'a', 'č': 'c', 'ď': 'd', 'é': 'e', 'ě': 'e', 'ë': 'e',
  'í': 'i', 'ľ': 'l', 'ĺ': 'l', 'ň': 'n', 'ó': 'o', 'ô': 'o', 'ö': 'o',
  'ř': 'r', 'š': 's', 'ť': 't', 'ú': 'u', 'ů': 'u', 'ü': 'u', 'ý': 'y',
  'ž': 'z', 'ß': 'ss',
};

/// Malá písmena bez diakritiky („tlaky“ najde i „Tlaky na lavici“).
String foldForSearch(String text) {
  final buf = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    buf.write(_fold[ch] ?? ch);
  }
  return buf.toString();
}
