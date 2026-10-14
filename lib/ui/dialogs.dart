import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Dialog pro zadání krátkého textu (např. název plánu).
/// Vrací oříznutý text, nebo null při zrušení či prázdném vstupu.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? hintText,
  String? Function(String text)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      validator: validator,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String? hintText;

  /// Chybová hláška pro zadaný text, nebo null (text je v pořádku).
  final String? Function(String text)? validator;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _error => widget.validator?.call(_controller.text.trim());

  void _submit() {
    if (_error != null) return;
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.hintText,
          errorText: _error,
          errorMaxLines: 3,
        ),
        onChanged: widget.validator == null ? null : (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _error == null ? _submit : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Potvrzovací dialog. Vrací true, pokud uživatel potvrdil.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Dialog pro víceřádkovou poznámku (např. poznámka ke cviku).
/// Vrací oříznutý text („“ = poznámku smazat), nebo null při zrušení.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? hintText,
  int maxLength = 300,
}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _NoteDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        maxLength: maxLength,
      ),
    );

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final String? hintText;
  final int maxLength;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintMaxLines: 3,
        ),
      ),
      actions: [
        if (widget.initialValue.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
