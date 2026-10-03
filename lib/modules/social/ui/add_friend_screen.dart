import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../social_backend.dart';
import '../social_logic.dart';
import '../social_publisher.dart';
import '../social_service.dart';
import 'friends_screen.dart';
import 'social_ui.dart';

/// /friends/add?code=XXXX – potvrzení přidání přítele (z odkazu nebo QR).
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  Future<({String uid, String name})?>? _lookup;
  bool _busy = false;

  String? get _code {
    final n = normalizeFriendCode(widget.code);
    return isValidFriendCode(n) ? n : null;
  }

  Future<({String uid, String name})?> _load() {
    return _lookup ??= SocialService.instance
        .lookupCode(_code!)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final profile = await ref.read(databaseProvider).watchProfile().first;
      final name = await SocialService.instance.addFriend(
        _code!,
        myName: SocialPublisher.displayName(profile),
      );
      if (!mounted) return;
      ref.invalidate(socialFriendProfilesProvider);
      showSocialSnack(context, l10n.socialFriendAdded(name));
      context.go('/friends');
    } on AddFriendException catch (e) {
      if (!mounted) return;
      showSocialSnack(
        context,
        switch (e.error) {
          AddFriendError.notFound => l10n.socialCodeNotFound,
          AddFriendError.self => l10n.socialCodeSelf,
          AddFriendError.alreadyFriend => l10n.socialAlreadyFriend,
          AddFriendError.notSignedIn => l10n.socialProfileSignedOut,
        },
      );
    } catch (e) {
      debugPrint('Social: add friend failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget body;
    if (!ref.watch(socialAvailableProvider)) {
      body = SocialMessage(
        icon: Icons.cloud_off_outlined,
        title: l10n.socialNotSetUp,
        text: l10n.socialNotSetUpHint,
      );
    } else if (_code == null) {
      body = SocialMessage(
        icon: Icons.error_outline,
        title: l10n.socialCodeInvalid,
      );
    } else if (ref.watch(socialUserProvider).valueOrNull == null) {
      // Nejdřív přihlásit, pak pokračovat v přidání.
      body = SocialSignInView(onSignedIn: () => setState(() {}));
    } else {
      body = FutureBuilder(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return SocialMessage(
              icon: Icons.cloud_off_outlined,
              title: l10n.socialOffline,
              action: OutlinedButton(
                onPressed: () => setState(() => _lookup = null),
                child: Text(l10n.socialRetry),
              ),
            );
          }
          final target = snap.data;
          if (target == null) {
            return SocialMessage(
              icon: Icons.person_off_outlined,
              title: l10n.socialCodeNotFound,
            );
          }
          if (target.uid == SocialService.instance.uid) {
            return SocialMessage(
              icon: Icons.person_outline,
              title: l10n.socialCodeSelf,
            );
          }
          return SocialMessage(
            icon: Icons.person_add_alt_1_outlined,
            title: l10n.socialAddConfirm(target.name),
            text: l10n.socialAddConfirmHint,
            action: _busy
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _add,
                    child: Text(l10n.socialAdd),
                  ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialAddFriend)),
      body: body,
    );
  }
}

/// /friends/scan – skenování QR kódu přítele.
class ScanFriendScreen extends StatefulWidget {
  const ScanFriendScreen({super.key});

  @override
  State<ScanFriendScreen> createState() => _ScanFriendScreenState();
}

class _ScanFriendScreenState extends State<ScanFriendScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final code = parseFriendCode(raw);
      if (code != null) {
        _done = true;
        context.pushReplacement('/friends/add?code=$code');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.socialScan),
        actions: [
          IconButton(
            tooltip: l10n.socialEnterCode,
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: () async {
              final text = await showTextInputDialog(
                context,
                title: l10n.socialEnterCode,
                hintText: 'ABCD2345',
              );
              if (text != null && context.mounted) {
                openAddFriend(context, text, replace: true);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => SocialMessage(
              icon: Icons.no_photography_outlined,
              title: l10n.socialCameraError,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.socialScanHint, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
