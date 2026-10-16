// Stažení souboru v prohlížeči; v testech (VM) prázdná náhrada.
export 'download_stub.dart' if (dart.library.js_interop) 'download_web.dart';
