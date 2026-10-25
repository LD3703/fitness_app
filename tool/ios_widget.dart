// Zapne iOS widget „Dnes“ a Live Activity odpočtu pauzy: přidá cíl
// GymBarWidget do Xcode projektu a nastaví aplikaci (docs/ios_widget.md).
// Spouštěj až po registraci App Group v Apple Developer účtu – jinak
// podepsaný build (Codemagic) selže. CI ho spouští jen pro kontrolní
// build bez podpisu. Bezpečné spustit opakovaně.
//
//   dart run tool/ios_widget.dart
import 'dart:io';

import 'platform/ios_widget.dart';

void main() {
  if (!patchIosWidget(enable: true)) exitCode = 1;
}
