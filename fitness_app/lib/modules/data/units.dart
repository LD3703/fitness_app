import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/enums.dart';
import '../../providers.dart';
import '../../ui/format.dart';

/// Jednotky zvolené v profilu (kg/ml nebo lb/oz).
///
/// Sleduje se v kořeni aplikace (moduleAppProviders), takže při změně
/// profilu hned přepne globální [unitSystemNotifier], ze kterého čtou
/// formátovací funkce v lib/ui/format.dart. Widgety, které zobrazují váhu
/// nebo objem, ho mohou sledovat (`ref.watch(unitSystemProvider)`),
/// aby se po změně jednotek hned překreslily.
final unitSystemProvider = Provider<UnitSystem>((ref) {
  final unit =
      ref.watch(profileProvider).valueOrNull?.unitSystem ?? unitSystemNotifier.value;
  unitSystemNotifier.value = unit;
  return unit;
});
