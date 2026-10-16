import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Stáhne text jako soubor (např. pozvánku .ics do kalendáře).
void downloadText(String fileName, String text, {String mime = 'text/calendar'}) {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: '$mime;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
