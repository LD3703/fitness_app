import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Přejetí doleva smaže položku – jako v seznamech v iOS. Pod položkou je
/// červené pozadí s košem; místo potvrzovacího dialogu se pak ukáže
/// „Vrátit“ ([showUndoSnackBar]). Rodič musí položku hned po
/// [onDeleted] ze seznamu vyřadit (Dismissible).
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    required super.key,
    required this.child,
    required this.onDeleted,
    this.label,
  });

  final Widget child;
  final VoidCallback onDeleted;

  /// Text vedle koše (výchozí „Smazat“).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      onUpdate: (details) {
        // Haptika ve chvíli, kdy přejetí „zacvakne“ (jako v iOS).
        if (details.reached && !details.previousReached) {
          HapticFeedback.mediumImpact();
        }
      },
      onDismissed: (_) => onDeleted(),
      background: ColoredBox(
        color: scheme.error,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? AppLocalizations.of(context).delete,
                  style: TextStyle(
                    color: scheme.onError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.delete_outline, color: scheme.onError),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Snackbar „Smazáno · Vrátit“. Po klepnutí na Vrátit zavolá [onUndo],
/// jinak (vypršení, nahrazení dalším snackbarem) [onCommit] – mazání
/// v databázi tak proběhne až po uplynutí možnosti vrátit.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  required VoidCallback onCommit,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  controller
      .showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        // Snackbar s akcí by jinak zůstal, dokud ho uživatel nezavře.
        persist: false,
        action: SnackBarAction(label: l10n.undo, onPressed: () {}),
      ))
      .closed
      .then((reason) {
    if (reason == SnackBarClosedReason.action) {
      onUndo();
    } else {
      onCommit();
    }
  });
}
