import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../links/deep_links.dart' show kPrivacyPolicyUrl, kTermsUrl;
import 'crash_reporting.dart';

/// [crash:profile] – sekce „Soukromí“ v Profilu: odkaz na zásady
/// ochrany soukromí a vypínač hlášení o pádech (jen s Firebase).
class PrivacyProfileSection extends ConsumerWidget {
  const PrivacyProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final crashEnabled = ref.watch(crashReportingEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.privacySection,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyPolicy),
          subtitle: Text(l10n.privacyPolicyHint),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => launchUrl(
            Uri.parse(kPrivacyPolicyUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.termsOfUse),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => launchUrl(
            Uri.parse(kTermsUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        if (CrashReporting.available)
          SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.crashReportsTitle),
            subtitle: Text(l10n.crashReportsHint),
            value: crashEnabled,
            onChanged: CrashReporting.setEnabled,
          ),
        const Divider(),
      ],
    );
  }
}
