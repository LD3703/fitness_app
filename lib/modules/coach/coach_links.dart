import '../links/deep_links.dart';

/// Odkaz pro klienta: https://gymbar.app/coach?code=XXXXXX
String coachInviteLink(String code) => '$kWebBaseUrl/coach?code=$code';

/// Odkaz na sdílený plán: https://gymbar.app/plan?id=…
String sharedPlanLink(String id) => '$kWebBaseUrl/plan?id=$id';

/// Web pro trenéry (Flutter web, trainer_web/, docs/coach.md).
const kTrainerWebUrl = '$kWebBaseUrl/trener';
