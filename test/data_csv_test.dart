import 'package:fitness_app/modules/data/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('csvField', () {
    test('null and numbers', () {
      expect(csvField(null), '');
      expect(csvField(42), '42');
      expect(csvField(80.0), '80');
      expect(csvField(82.5), '82.5');
      expect(csvField(double.nan), '');
      expect(csvField(true), 'true');
    });

    test('plain text stays as is', () {
      expect(csvField('Bench press'), 'Bench press');
      expect(csvField(''), '');
    });

    test('text with separator, quotes or new lines is quoted', () {
      expect(csvField('shoulders,back'), '"shoulders,back"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('line 1\nline 2'), '"line 1\nline 2"');
      expect(csvField('a\r\nb'), '"a\r\nb"');
    });

    test('formula-like text is neutralised', () {
      expect(csvField('=SUM(A1)'), "'=SUM(A1)");
      expect(csvField('+1'), "'+1");
      expect(csvField('@x'), "'@x");
      expect(csvField('=A1,B1'), '"\'=A1,B1"');
    });

    test('dates are ISO 8601 without milliseconds', () {
      expect(csvField(DateTime(2026, 9, 3, 7, 5, 9, 123)), '2026-09-03T07:05:09');
      expect(csvDate(DateTime(2026, 1, 2, 23, 59)), '2026-01-02');
    });
  });

  test('csvRow joins with commas', () {
    expect(csvRow([1, 'a,b', null, 2.5]), '1,"a,b",,2.5');
  });

  test('buildCsv adds BOM, header and CRLF line endings', () {
    final csv = buildCsv(['id', 'note'], [
      [1, 'ok'],
      [2, 'x "y"'],
    ]);
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, '﻿id,note\r\n1,ok\r\n2,"x ""y"""\r\n');
  });

  test('buildCsv with no rows has only the header', () {
    expect(buildCsv(['a'], const []), '﻿a\r\n');
  });
}
