import 'package:fitness_app/l10n/app_localizations.dart';
import 'package:fitness_app/modules/widgets/rest_live_activity.dart';
import 'package:fitness_app/modules/widgets/widget_content.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widgetDayKey pads month and day', () {
    expect(widgetDayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    expect(widgetDayKey(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('formatMl uses locale grouping', () {
    expect(formatMl(1250, 'en'), '1,250');
    expect(formatMl(250, 'en'), '250');
    // Čeština odděluje tisíce (nezlomitelnou) mezerou.
    expect(formatMl(2500, 'cs').replaceAll(' ', ' '), '2 500');
  });

  test('waterPercent is clamped to 0..100', () {
    expect(waterPercent(1250, 2500), 50);
    expect(waterPercent(0, 2500), 0);
    expect(waterPercent(4000, 2500), 100);
    expect(waterPercent(100, 0), 100);
    expect(waterPercent(0, 0), 0);
  });

  test('parseWidgetMl falls back to glass size', () {
    expect(parseWidgetMl(Uri.parse('homewidget://water?ml=330'), 250), 330);
    expect(parseWidgetMl(Uri.parse('homewidget://water'), 250), 250);
    expect(parseWidgetMl(Uri.parse('homewidget://water?ml=abc'), 300), 300);
    expect(parseWidgetMl(Uri.parse('homewidget://water?ml=-5'), 250), 250);
    expect(parseWidgetMl(Uri.parse('homewidget://water?ml=99999'), 250), 250);
  });

  test('widget uri parts', () {
    final uri = Uri.parse('homewidget://water?ml=250&n=1700000000000');
    expect(uri.scheme, kWidgetUriScheme);
    expect(uri.host, kWidgetHostWater);
    expect(Uri.parse('homewidget://open').host, kWidgetHostOpen);
  });

  test('shouldAddWater ignores replayed intents', () {
    expect(shouldAddWater(null, 5), isTrue);
    expect(shouldAddWater(10, null), isTrue);
    expect(shouldAddWater(10, 5), isTrue);
    expect(shouldAddWater(10, 10), isFalse);
    expect(shouldAddWater(4, 10), isFalse);
  });

  group('Live Activity odpočtu pauzy', () {
    final cs = lookupAppLocalizations(const Locale('cs'));
    final start = DateTime(2026, 10, 25, 18, 0, 0);
    final end = start.add(const Duration(seconds: 90));

    test('texty v jazyce aplikace a další cvik', () {
      final a = restLiveActivityArgs(
          l10n: cs, startAt: start, endAt: end, nextExercise: 'Bench press');
      expect(a['title'], cs.calRestOngoingTitle);
      expect(a['doneTitle'], cs.notifRestTitle);
      expect(a['doneBody'], cs.notifRestBody);
      expect(a['detail'], cs.planBNext('Bench press'));
      expect(a['startMs'], start.millisecondsSinceEpoch);
      expect(a['endMs'], end.millisecondsSinceEpoch);
    });

    test('bez dalšího cviku obecný text, konec nikdy před začátkem', () {
      final a = restLiveActivityArgs(
          l10n: cs,
          startAt: start,
          endAt: start.subtract(const Duration(seconds: 5)),
          nextExercise: '  ');
      expect(a['detail'], cs.calRestOngoingBody);
      expect(a['endMs'], start.millisecondsSinceEpoch);
    });
  });
}
