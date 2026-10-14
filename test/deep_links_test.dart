import 'package:fitness_app/modules/links/link_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDecodableLink', () {
    test('běžné odkazy projdou', () {
      expect(
        isDecodableLink(Uri.parse(
            'gymbar://challenge?e=bench_press&v=100&n=Luk%C3%A1%C5%A1')),
        isTrue,
      );
      expect(
        isDecodableLink(Uri.parse('https://gymbar.app/challenge?x=A+B')),
        isTrue,
      );
      expect(isDecodableLink(Uri.parse('gymbar://friends')), isTrue);
    });

    test('neplatné UTF-8 v parametrech nebo cestě se zahodí', () {
      final query = Uri.parse('gymbar://challenge?e=%FF&v=10');
      // Přesně tohle by jinak spadlo až v builderu obrazovky.
      expect(() => query.queryParameters, throwsFormatException);
      expect(isDecodableLink(query), isFalse);
      expect(
        isDecodableLink(Uri.parse('https://gymbar.app/%C3/challenge?e=1')),
        isFalse,
      );
    });
  });
}
