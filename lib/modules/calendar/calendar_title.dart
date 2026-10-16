/// Název události v kalendáři telefonu (čistý Dart, testy:
/// test/calendar_title_test.dart).
library;

/// Zástupný text v názvu události, nahradí se názvem plánu.
const calendarTitleToken = '{plan}';

/// Ukázkový název plánu pro náhled v Profilu (Push / Pull / Legs se
/// v posilovnách používá ve všech jazycích).
const calendarTitleExamplePlan = 'Push';

/// Název události pro plán [plan]. [template] je vlastní text uživatele
/// (null nebo prázdný = [defaultTitle], výchozí text podle jazyka).
/// Bez „{plan}“ v textu se použije text tak, jak je.
String calendarEventTitle({
  required String? template,
  required String plan,
  required String Function(String plan) defaultTitle,
}) {
  final t = template?.trim() ?? '';
  if (t.isEmpty) return defaultTitle(plan);
  return t.replaceAll(calendarTitleToken, plan);
}
