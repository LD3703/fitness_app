import 'package:fitness_app/modules/calendar/calendar_title.dart';
import 'package:flutter_test/flutter_test.dart';

String _default(String plan) => 'Fitko – $plan';

void main() {
  test('bez vlastního textu výchozí název podle jazyka', () {
    expect(
        calendarEventTitle(
            template: null, plan: 'Push', defaultTitle: _default),
        'Fitko – Push');
    expect(
        calendarEventTitle(
            template: '  ', plan: 'Push', defaultTitle: _default),
        'Fitko – Push');
  });

  test('{plan} se nahradí názvem plánu', () {
    expect(
        calendarEventTitle(
            template: 'Posilovna: {plan} 💪',
            plan: 'Nohy',
            defaultTitle: _default),
        'Posilovna: Nohy 💪');
  });

  test('text bez {plan} se použije, jak je', () {
    expect(
        calendarEventTitle(
            template: 'Trénink', plan: 'Push', defaultTitle: _default),
        'Trénink');
  });
}
