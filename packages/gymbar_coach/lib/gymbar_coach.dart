/// Společná logika trenér–klient (docs/coach.md). Používá ji aplikace
/// (lib/modules/coach/) i web pro trenéry (trainer_web/). Čistý Dart –
/// testy: test/coach_test.dart v kořeni projektu.
library;

export 'src/codes.dart';
export 'src/json.dart' show CoachFormatException;
export 'src/plan.dart';
export 'src/session.dart';
export 'src/stats.dart';
export 'src/text_filter.dart';
export 'src/workout.dart';
