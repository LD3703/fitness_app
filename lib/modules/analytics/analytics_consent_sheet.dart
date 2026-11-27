import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'analytics.dart';

/// Jednorázový dotaz na souhlas se statistikami používání. Obě volby
/// jsou stejně snadné (souhlas musí být svobodný); bez odpovědi se nic
/// neodesílá a dotaz se ukáže při dalším spuštění.
Future<void> showAnalyticsConsentSheet(BuildContext context) async {
  final answer = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ConsentSheet(),
  );
  if (answer != null) await Analytics.setConsent(answer);
}

class _ConsentSheet extends StatelessWidget {
  const _ConsentSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.insights_outlined,
                size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.analyticsConsentTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(l10n.analyticsConsentBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              l10n.analyticsConsentLater,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.analyticsConsentDeny),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.analyticsConsentAllow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
