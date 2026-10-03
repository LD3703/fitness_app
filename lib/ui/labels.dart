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
