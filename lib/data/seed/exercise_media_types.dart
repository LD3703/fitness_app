/// Obrázek cviku přibalený v aplikaci (assets/exercises/).
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
  final String license;
  final bool aiGenerated;
}

/// Obrázky jednoho vestavěného cviku z databáze wger.de.
class ExerciseMedia {
  const ExerciseMedia({required this.wgerId, required this.images});

  final int wgerId;
  final List<ExerciseImage> images;

  /// Stránka cviku na wger.de (zdroj a autoři).
  String get sourceUrl => 'https://wger.de/en/exercise/$wgerId/view/';
}
