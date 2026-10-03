import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Dialog pro zadání čísla s kontrolou rozsahu.
/// Přijímá desetinnou čárku i tečku. Vrací null, když uživatel zruší.
Future<double?> showNumberInputDialog(
  BuildContext context, {
  required String title,
  required double min,
  required double max,
  required String errorText,
  double? initialValue,
  bool allowDecimals = true,
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _NumberInputDialog(
      title: title,
      min: min,
      max: max,
      errorText: errorText,
      initialValue: initialValue,
      allowDecimals: allowDecimals,
    ),
  );
}

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.min,
    required this.max,
    required this.errorText,
    required this.initialValue,
    required this.allowDecimals,
  });

  final String title;
  final double min;
  final double max;
  final String errorText;
  final double? initialValue;
  final bool allowDecimals;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _controller = TextEditingController(
      text: v == null
          ? ''
          : (widget.allowDecimals ? v.toString() : v.round().toString()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (value == null || value < widget.min || value > widget.max) {
      setState(() => _error = widget.errorText);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType:
            TextInputType.numberWithOptions(decimal: widget.allowDecimals),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(widget.allowDecimals ? r'[0-9.,]' : r'[0-9]'),
          ),
        ],
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
