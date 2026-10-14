import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../strings.dart';

/// Max. šířka obsahu na širokém monitoru.
const kContentWidth = 1100.0;

/// Obsah stránky vycentrovaný a omezený na [kContentWidth].
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding = 20});

  final List<Widget> children;
  final double padding;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.symmetric(vertical: padding),
        children: [
          for (final c in children)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: c,
                ),
              ),
            ),
        ],
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Karta s jedním číslem (souhrn klienta).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (warn) ...[
                    Icon(Icons.warning_amber_rounded,
                        size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(value,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<void> copyText(BuildContext context, String text) async {
  final s = S.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, s('copied'));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final s = S.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s('cancel')),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// Víceřádkový text (komentář).
Future<String?> askText(
  BuildContext context, {
  required String title,
  required int maxLength,
  String initial = '',
  int lines = 4,
}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
          title: title, maxLength: maxLength, initial: initial, lines: lines),
    );

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.maxLength,
    required this.initial,
    required this.lines,
  });

  final String title;
  final int maxLength;
  final String initial;
  final int lines;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _c,
          autofocus: true,
          minLines: widget.lines,
          maxLines: widget.lines + 4,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_c.text.trim()),
          child: Text(s('save')),
        ),
      ],
    );
  }
}

/// Chyba při zápisu / čtení – srozumitelná hláška.
String errorText(S s, Object e) {
  final t = '$e';
  if (t.contains('permission-denied')) return s('errorPermission');
  if (t.contains('unavailable') || t.contains('TimeoutException')) {
    return s('errorOffline');
  }
  return s('errorGeneric');
}

// ---------------------------------------------------------------------------
// Formátování
// ---------------------------------------------------------------------------

String fmtKg(double v, String locale) {
  final f = NumberFormat.decimalPattern(locale)
    ..maximumFractionDigits = v.abs() >= 100 ? 0 : 1;
  return f.format(v);
}

String fmtDate(DateTime d, String locale) => DateFormat.yMMMd(locale).format(d);

String fmtDateTime(DateTime d, String locale) =>
    DateFormat.yMMMEd(locale).add_Hm().format(d);

String fmtShort(DateTime d, String locale) => DateFormat.Md(locale).format(d);
