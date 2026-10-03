import 'package:fitness_app/ui/format.dart';
import 'package:fitness_app/ui/weekdays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maska dnů', () {
    test('pondělí a pátek', () {
      var mask = 0;
      mask = toggleWeekday(mask, 0); // pondělí
      mask = toggleWeekday(mask, 4); // pátek
      expect(isWeekdayInMask(mask, 0), isTrue);
      expect(isWeekdayInMask(mask, 4), isTrue);
      expect(isWeekdayInMask(mask, 2), isFalse);
      mask = toggleWeekday(mask, 0);
      expect(isWeekdayInMask(mask, 0), isFalse);
    });

    test('index dne z data (25. 9. 2026 je pátek)', () {
      expect(dayIndexOf(DateTime(2026, 9, 25)), 4);
      expect(dayIndexOf(DateTime(2026, 9, 27)), 6); // neděle
    });
  });

  group('formátování', () {
    test('formatDuration', () {
      expect(formatDuration(const Duration(seconds: 75)), '1:15');
      expect(formatDuration(const Duration(seconds: 3725)), '1:02:05');
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('parseDecimal přijímá čárku i tečku', () {
      expect(parseDecimal('82,5'), 82.5);
      expect(parseDecimal(' 80 '), 80);
      expect(parseDecimal(''), isNull);
      expect(parseDecimal('abc'), isNull);
    });
  });
}
