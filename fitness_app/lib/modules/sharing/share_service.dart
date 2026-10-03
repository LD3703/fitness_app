import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import 'share_cards.dart';

// Jak vzniká obrázek: karta se ukáže v náhledu (dialog) uvnitř
// RepaintBoundary a po klepnutí na „Sdílet“ se vyfotí přes
// RenderRepaintBoundary.toImage(). Náhled je nejspolehlivější cesta –
// karta je v tu chvíli jistě rozvržená a vykreslená (off-screen render
// přes vlastní PipelineOwner je křehčí, hlavně kvůli písmům a
// lokalizaci), a uživatel navíc vidí, co sdílí.

/// Obdélník widgetu na obrazovce (kotva nabídky sdílení na iPadu).
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Sdílí jen text (výzva odkazem, splněná výzva).
Future<void> shareText(BuildContext context, String text) async {
  final origin = shareOriginOf(context);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  } catch (e) {
    debugPrint('Share failed: $e');
    messenger?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
  }
}

/// Ukáže náhled karty a po potvrzení ji sdílí jako PNG spolu s textem.
Future<void> showShareCardPreview(
  BuildContext context, {
  required Widget card,
  required String text,
  required String fileName,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _SharePreviewDialog(card: card, text: text, fileName: fileName),
  );
}

class _SharePreviewDialog extends StatefulWidget {
  const _SharePreviewDialog({
    required this.card,
    required this.text,
    required this.fileName,
  });

  final Widget card;
  final String text;
  final String fileName;

  @override
  State<_SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<_SharePreviewDialog> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<File> _renderPng() async {
    // Počkáme na dokončení rozpracovaného snímku, ať je karta vykreslená.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Share card is not rendered');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed');
      final dir = Directory('${(await getTemporaryDirectory()).path}/share');
      await dir.create(recursive: true);
      final file = File('${dir.path}/${widget.fileName}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return file;
    } finally {
      image.dispose();
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final l10n = AppLocalizations.of(context);
    final origin = shareOriginOf(buttonContext);
    setState(() => _busy = true);
    try {
      final file = await _renderPng();
      await SharePlus.instance.share(ShareParams(
        text: widget.text,
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Share card failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.sharePreviewTitle),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: kShareCardSize.width,
        child: FittedBox(
          fit: BoxFit.contain,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            // Snímek se dělá z RepaintBoundary v jeho vlastních
            // souřadnicích – zmenšení přes FittedBox výsledek neovlivní.
            child: RepaintBoundary(
              key: _boundaryKey,
              child: widget.card,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        Builder(
          builder: (buttonContext) => FilledButton.icon(
            onPressed: _busy ? null : () => _share(buttonContext),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(l10n.shareAction),
          ),
        ),
      ],
    );
  }
}
