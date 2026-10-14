import 'package:flutter/widgets.dart';

import '../data/database.dart';
import '../data/seed/content_i18n.dart';
import '../data/seed/seed_translations.dart';
import '../l10n/app_localizations.dart';

/// Přeložené názvy výčtů a cviků podle jazyka aplikace.
extension LabelsX on AppLocalizations {
  String muscleGroup(MuscleGroup g) => switch (g) {
        MuscleGroup.chest => muscleChest,
        MuscleGroup.back => muscleBack,
        MuscleGroup.shoulders => muscleShoulders,
        MuscleGroup.biceps => muscleBiceps,
        MuscleGroup.triceps => muscleTriceps,
        MuscleGroup.legs => muscleLegs,
        MuscleGroup.glutes => muscleGlutes,
        MuscleGroup.core => muscleCore,
        MuscleGroup.fullBody => muscleFullBody,
        MuscleGroup.quads => muscleQuads,
        MuscleGroup.hamstrings => muscleHamstrings,
        MuscleGroup.calves => muscleCalves,
        MuscleGroup.forearms => muscleForearms,
        MuscleGroup.traps => muscleTraps,
        MuscleGroup.lowerBack => muscleLowerBack,
      };

  String equipment(Equipment e) => switch (e) {
        Equipment.barbell => equipmentBarbell,
        Equipment.dumbbell => equipmentDumbbell,
        Equipment.machine => equipmentMachine,
        Equipment.cable => equipmentCable,
        Equipment.bodyweight => equipmentBodyweight,
        Equipment.kettlebell => equipmentKettlebell,
        Equipment.band => equipmentBand,
      };

  String trainingFocus(TrainingFocus f) => switch (f) {
        TrainingFocus.strength => focusStrength,
        TrainingFocus.muscle => focusMuscle,
        TrainingFocus.conditioning => focusConditioning,
      };

  String trainingFocusHint(TrainingFocus f) => switch (f) {
        TrainingFocus.strength => focusStrengthHint,
        TrainingFocus.muscle => focusMuscleHint,
        TrainingFocus.conditioning => focusConditioningHint,
      };

  /// Pohlaví z profilu; null = neuvedeno.
  String sex(Sex? s) => switch (s) {
        Sex.male => sexMale,
        Sex.female => sexFemale,
        null => sexUnspecified,
      };

  String periodType(PeriodType p) => switch (p) {
        PeriodType.illness => periodIllness,
        PeriodType.injury => periodInjury,
        PeriodType.cut => periodCut,
        PeriodType.bulk => periodBulk,
        PeriodType.maintenance => periodMaintenance,
        PeriodType.pause => periodPause,
      };
}

extension ExerciseLocalizedX on Exercise {
  String localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final s = slug;
    return seedText(
      lang,
      en: nameEn,
      cs: nameCs,
      other: s == null ? null : (t) => t.exerciseNames[s],
    );
  }

  String? localizedInstructions(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'cs') return instructionsCs;
    if (lang == 'en') return instructionsEn;
    final s = slug;
    return (s == null ? null : seedTranslations[lang]?.exerciseInstructions[s]) ??
        instructionsEn;
  }
}
