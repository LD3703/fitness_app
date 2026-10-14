import '../data/database.dart';
import '../data/seed/exercise_secondary_muscles.dart';

/// Hlavní a vedlejší partie skupiny cviků (plán, trénink).
typedef MuscleSets = ({Set<MuscleGroup> primary, Set<MuscleGroup> secondary});

const MuscleSets emptyMuscleSets =
    (primary: <MuscleGroup>{}, secondary: <MuscleGroup>{});

/// Hlavní partie = partie cviku v databázi; vedlejší podle
/// data/seed/exercise_secondary_muscles.dart (bez těch, které jsou hlavní).
MuscleSets muscleSetsOf(Iterable<Exercise> exercises) {
  final primary = <MuscleGroup>{};
  final secondary = <MuscleGroup>{};
  for (final e in exercises) {
    primary.add(e.muscleGroup);
    secondary.addAll(secondaryMusclesOf(e.slug));
  }
  secondary.removeAll(primary);
  return (primary: primary, secondary: secondary);
}
