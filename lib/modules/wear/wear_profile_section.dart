import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import 'wear_bridge.dart';

/// Sekce „Hodinky“ v Profilu: stav spojení s aplikací v hodinkách
/// (Wear OS) a krátký návod. Jen na Androidu.
class WearProfileSection extends ConsumerStatefulWidget {
  const WearProfileSection({super.key});

  @override
  ConsumerState<WearProfileSection> createState() =>
      _WearProfileSectionState();
}

class _WearProfileSectionState extends ConsumerState<WearProfileSection> {
  bool _checking = false;
  bool _reachable = false;

  @override
  void initState() {
    super.initState();
    if (wearSupported) {
      _checking = true;
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    final bridge = ref.read(wearBridgeProvider);
    if (!_checking) setState(() => _checking = true);
    // Otevřená aplikace v hodinkách odpoví a obnoví „naposledy ve spojení“.
    bridge.ping();
    final devices = await bridge.checkDevices();
    // Chvíli počkat na odpověď hodinek.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _reachable = devices.reachable;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!wearSupported) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Premium (wearOs): bez předplatného místo stavu spojení upoutávka.
    final allowed = ref.watch(
        premiumProvider.select((a) => a.isPremium(PremiumFeature.wearOs)));
    if (!allowed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.wearSectionTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: PremiumLockedPlaceholder(feature: PremiumFeature.wearOs),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.wearHelp,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(),
        ],
      );
    }
    final lastSeen = ref.watch(wearLastSeenProvider);
    final connected = lastSeen != null &&
        DateTime.now().difference(lastSeen) < wearSeenWindow;

    final String status;
    final IconData icon;
    if (connected) {
      status = l10n.wearStatusConnected;
      icon = Icons.watch;
    } else if (_checking) {
      status = l10n.wearStatusChecking;
      icon = Icons.watch_outlined;
    } else if (_reachable) {
      status = l10n.wearStatusWatchNearby;
      icon = Icons.watch_outlined;
    } else {
      status = l10n.wearStatusNoWatch;
      icon = Icons.watch_off;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.wearSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: Icon(icon),
          title: Text(status),
          subtitle: lastSeen == null
              ? null
              : Text(l10n.wearLastSeen(
                  MaterialLocalizations.of(context)
                      .formatTimeOfDay(TimeOfDay.fromDateTime(lastSeen)),
                )),
          trailing: _checking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _check,
                  child: Text(l10n.wearCheckButton),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.wearHelp,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
