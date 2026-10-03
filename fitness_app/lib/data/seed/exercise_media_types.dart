/// Obrázek nebo animace cviku přibalená v aplikaci (assets/exercises/).
class ExerciseImage {
  const ExerciseImage({
    required this.asset,
    required this.author,
    this.authorUrl,
    required this.license,
    this.aiGenerated = false,
  });

  final String asset;
  final String author;
  final String? authorUrl;

  /// Licence (prázdná u koupených animací bez povinného uvedení licence).
  final String license;
  final bool aiGenerated;
}

/// Ukázka jednoho vestavěného cviku. Dva druhy:
///  - animace ([animated] = true): jeden animovaný soubor GIF / WebP
///    (koupený balíček nebo animovaný obrázek z wger.de),
///  - dvojice obrázků (výchozí a koncová poloha), které se v aplikaci
///    střídají jako jednoduchá animace (wger.de).
class ExerciseMedia {
  const ExerciseMedia({
    this.wgerId,
    required this.images,
    this.animated = false,
    this.pageUrl,
  });

  /// ID cviku na wger.de (null u koupených animací).
  final int? wgerId;
  final List<ExerciseImage> images;

  /// true = [images] obsahuje jeden animovaný GIF / WebP.
  final bool animated;

  /// Stránka zdroje (např. prodejce animací), když nejde o wger.de.
  final String? pageUrl;

  /// Pochází z otevřené databáze wger.de (licence CC BY-SA)?
  bool get isFromWger => wgerId != null;

  /// Stránka zdroje a autorů (null = žádná).
  String? get sourceUrl =>
      pageUrl ??
      (wgerId == null ? null : 'https://wger.de/en/exercise/$wgerId/view/');
}
