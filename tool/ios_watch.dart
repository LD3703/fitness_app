// Zapne aplikaci pro Apple Watch: přidá cíl GymBarWatch do Xcode projektu
// (docs/apple_watch.md). Spouštěj až po registraci App ID
// cz.dedina.fitnessApp.watchkitapp v Apple Developer účtu – jinak podepsaný
// build (Codemagic) selže. CI ho spouští jen pro kontrolní build bez
// podpisu. Bezpečné spustit opakovaně.
//
//   dart run tool/ios_watch.dart
import 'dart:io';

import 'platform/ios_watch.dart';

void main() {
  if (!patchIosWatch(enable: true)) exitCode = 1;
}
