import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Pole pro počet opakování (nebo sekund u cviku na čas). Klepnutí místo
/// klávesnice otevře panel s posuvníkem a rychlými volbami
/// ([showRepsSlider]) – hodnota se mění hned, puštěním posuvníku nebo
/// volbou se panel zavře. „Zadat číslem“ vrátí klávesnici.
class RepsField extends StatefulWidget {
  const RepsField({
    super.key,
    required this.controller,
    required this.isDuration,
    required this.onChanged,
    this.decoration = const InputDecoration(isDense: true),
    this.textAlign = TextAlign.center,
  });

  final TextEditingController controller;

  /// Sekundy (cvik na čas) místo opakování.
  final bool isDuration;
  final VoidCallback onChanged;
  final InputDecoration decoration;
  final TextAlign textAlign;

  @override
  State<RepsField> createState() => _RepsFieldState();
}

class _RepsFieldState extends State<RepsField> {
  final _focus = FocusNode();

  /// Uživatel si vybral psaní na klávesnici (do opuštění pole).
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _typing) setState(() => _typing = false);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _openSlider() async {
    final keyboard = await showRepsSlider(
      context,
      value: int.tryParse(widget.controller.text.trim()),
      isDuration: widget.isDuration,
      onChanged: (v) {
        widget.controller.text = '$v';
        widget.onChanged();
      },
    );
    if (keyboard && mounted) {
      setState(() => _typing = true);
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      readOnly: !_typing,
      showCursor: _typing,
      enableInteractiveSelection: _typing,
      onTap: _typing ? null : _openSlider,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: widget.textAlign,
      decoration: widget.decoration,
      onChanged: (_) => widget.onChanged(),
    );
  }
}

/// Rychlé volby opakování a sekund.
const kRepsPresets = [5, 6, 8, 10, 12, 15, 20];
const kSecondsPresets = [20, 30, 45, 60, 90, 120];

/// Panel s posuvníkem. [onChanged] se volá při každé změně; vrací true,
/// když si uživatel vybral zadání číslem na klávesnici.
Future<bool> showRepsSlider(
  BuildContext context, {
  required int? value,
  required bool isDuration,
  required ValueChanged<int> onChanged,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    // Výška podle obsahu, na malém displeji nebo s velkým písmem se posouvá.
    isScrollControlled: true,
    builder: (context) => _RepsSheet(
      initial: value,
      isDuration: isDuration,
      onChanged: onChanged,
    ),
  );
  return result ?? false;
}

class _RepsSheet extends StatefulWidget {
  const _RepsSheet({
    required this.initial,
    required this.isDuration,
    required this.onChanged,
  });

  final int? initial;
  final bool isDuration;
  final ValueChanged<int> onChanged;

  @override
  State<_RepsSheet> createState() => _RepsSheetState();
}

class _RepsSheetState extends State<_RepsSheet> {
  int get _step => widget.isDuration ? 5 : 1;
  int get _min => widget.isDuration ? 5 : 1;

  /// Rozsah posuvníku: 1–30 opakování (5–180 s), u větší hodnoty víc.
  late final int _max = () {
    final base = widget.isDuration ? 180 : 30;
    final v = widget.initial ?? 0;
    if (v <= base) return base;
    return ((v * 1.5) / _step).ceil() * _step;
  }();

  late int _value =
      (widget.initial ?? (widget.isDuration ? 30 : 10)).clamp(_min, _max);

  void _set(int v, {bool close = false}) {
    final next = v.clamp(_min, _max);
    if (next != _value) {
      HapticFeedback.selectionClick();
      setState(() => _value = next);
      widget.onChanged(next);
    } else if (widget.initial == null) {
      widget.onChanged(next);
    }
    if (close) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final presets = widget.isDuration ? kSecondsPresets : kRepsPresets;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isDuration ? l10n.repsSliderSeconds : l10n.repsSliderTitle,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              widget.isDuration ? '$_value s' : '$_value',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: '−$_step',
                  onPressed: () => _set(_value - _step),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    value: _value.toDouble(),
                    min: _min.toDouble(),
                    max: _max.toDouble(),
                    divisions: (_max - _min) ~/ _step,
                    label: '$_value',
                    onChanged: (v) => _set(v.round()),
                    // Puštění posuvníku = hotovo (méně klepnutí).
                    onChangeEnd: (v) => _set(v.round(), close: true),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '+$_step',
                  onPressed: () => _set(_value + _step),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in presets)
                  ChoiceChip(
                    label: Text(widget.isDuration ? '$p s' : '$p'),
                    selected: p == _value,
                    onSelected: (_) => _set(p, close: true),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.keyboard_outlined),
              label: Text(l10n.repsSliderKeyboard),
            ),
          ],
        ),
      ),
    );
  }
}
