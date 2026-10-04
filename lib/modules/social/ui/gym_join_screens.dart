import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_publisher.dart';
import '../gym/gym_service.dart';
import '../social_logic.dart';
import '../social_publisher.dart';
import 'gym_screen.dart' show gymGate;
import 'gym_widgets.dart';
import 'social_ui.dart';

// Navigace: když obrazovku otevřel žebříček (/gym) nebo hledání, vrací se
// po úspěchu zpět (pop) – /gym se sám přepne na žebříček. Z odkazu
// (bez „from“) nahradí obrazovku žebříčkem.

void _finish(BuildContext context, String? from) {
  if (from != null && context.canPop()) {
    context.pop(true);
  } else {
    context.pushReplacement('/gym');
  }
}

String _fromQuery(String? from) =>
    from == null ? '' : '&from=${Uri.encodeQueryComponent(from)}';

/// Výchozí profil v žebříčku: uložená přezdívka, jinak jméno pro přátele;
/// rok narození z lokálního profilu.
Future<GymProfileInput> _initialProfile(WidgetRef ref) async {
  final m = ref.read(gymMembershipProvider).valueOrNull;
  final profile = await ref.read(databaseProvider).watchProfile().first;
  return (
    nickname: m?.nickname ?? SocialPublisher.displayName(profile),
    gender: m?.gender ?? GymGender.unspecified,
    show: true,
    birthYear: profile.birthYear,
  );
}

// ---------------------------------------------------------------------------
// Vstup do posilovny (kód z QR / odkazu, nebo ID ze seznamu)
// ---------------------------------------------------------------------------

/// /gym/join?code=XXXXXX nebo /gym/join?id=<gymId>
class GymJoinScreen extends ConsumerStatefulWidget {
  const GymJoinScreen({super.key, this.code, this.gymId, this.from});

  final String? code;
  final String? gymId;
  final String? from;

  @override
  ConsumerState<GymJoinScreen> createState() => _GymJoinScreenState();
}

class _GymJoinScreenState extends ConsumerState<GymJoinScreen> {
  Future<Gym?>? _lookup;
  bool _busy = false;

  String? get _code {
    final c = widget.code;
    if (c == null) return null;
    final n = normalizeFriendCode(c);
    return isValidGymCode(n) ? n : null;
  }

  Future<Gym?> _load() => _lookup ??= () {
        final id = widget.gymId;
        final f = id != null && id.isNotEmpty
            ? GymService.instance.getGym(id)
            : GymService.instance.lookupCode(_code!);
        return f.timeout(const Duration(seconds: 15));
      }();

  Future<void> _join(Gym gym) async {
    final l10n = AppLocalizations.of(context);
    final initial = await _initialProfile(ref);
    if (!mounted) return;
    final input = await showGymProfileSheet(
      context,
      initial: initial,
      title: l10n.socialGymJoinTitle(gym.name),
      confirmLabel: l10n.socialGymJoin,
      note: l10n.socialGymJoinNote,
    );
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await saveGymBirthYear(ref.read(databaseProvider), input.birthYear);
      await GymService.instance.joinGym(gym.id, input);
      unawaited(
          GymPublisher.publish(ref.read(databaseProvider), force: true));
      if (!mounted) return;
      showSocialSnack(context, l10n.socialGymJoined(gym.name));
      _finish(context, widget.from);
    } catch (e) {
      debugPrint('Gym: join failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: l10n.socialGymJoin,
      builder: () {
        final hasId = widget.gymId != null && widget.gymId!.isNotEmpty;
        if (!hasId && _code == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.socialGymJoin)),
            body: SocialMessage(
              icon: Icons.error_outline,
              title: l10n.socialGymCodeInvalid,
            ),
          );
        }
        final membership = ref.watch(gymMembershipProvider).valueOrNull;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.socialGymJoin)),
          body: FutureBuilder<Gym?>(
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
              final gym = snap.data;
              if (gym == null) {
                return SocialMessage(
                  icon: Icons.search_off,
                  title: l10n.socialGymNotFound,
                );
              }
              final current = membership?.gymId;
              final place = [
                if (gym.city.isNotEmpty) gym.city,
                if (gym.address != null && gym.address!.isNotEmpty)
                  gym.address!,
              ].join(' · ');
              final details = [
                if (place.isNotEmpty) place,
                l10n.socialGymMembers(gym.memberCount),
                if (current != null && current != gym.id)
                  l10n.socialGymSwitchHint,
              ].join('\n');
              return SocialMessage(
                icon: Icons.fitness_center,
                title: gym.name,
                text: details,
                action: _busy
                    ? const CircularProgressIndicator()
                    : current == gym.id
                        ? FilledButton(
                            onPressed: () => _finish(context, widget.from),
                            child: Text(l10n.socialGymOpen),
                          )
                        : FilledButton(
                            onPressed: () => _join(gym),
                            child: Text(l10n.socialGymJoin),
                          ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Skenování QR kódu posilovny
// ---------------------------------------------------------------------------

/// /gym/scan – QR kód z recepce (stejně jako skenování kódu přítele).
class GymScanScreen extends StatefulWidget {
  const GymScanScreen({super.key, this.from});

  final String? from;

  @override
  State<GymScanScreen> createState() => _GymScanScreenState();
}

class _GymScanScreenState extends State<GymScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String code) {
    _done = true;
    context.pushReplacement('/gym/join?code=$code${_fromQuery(widget.from)}');
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final code = parseGymCode(raw);
      if (code != null) {
        _open(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.socialGymScan),
        actions: [
          IconButton(
            tooltip: l10n.socialGymEnterCode,
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: () async {
              final text = await showTextInputDialog(
                context,
                title: l10n.socialGymEnterCode,
                hintText: 'ABC234',
              );
              if (text == null || !context.mounted) return;
              final code = parseGymCode(text);
              if (code == null) {
                showSocialSnack(context, l10n.socialGymCodeInvalid);
              } else if (!_done) {
                _open(code);
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
                child:
                    Text(l10n.socialGymScanHint, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hledání posilovny
// ---------------------------------------------------------------------------

/// /gym/find – adresář posiloven (název nebo město).
class GymFindScreen extends ConsumerStatefulWidget {
  const GymFindScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<GymFindScreen> createState() => _GymFindScreenState();
}

class _GymFindScreenState extends ConsumerState<GymFindScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  late Future<List<Gym>> _results = _search('');

  Future<List<Gym>> _search(String q) =>
      GymService.instance.search(q).timeout(const Duration(seconds: 15));

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _results = _search(text));
    });
  }

  Future<void> _open(String location) async {
    final done = await context.push<bool>(location);
    if (done != true || !mounted) return;
    _finish(context, widget.from);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: l10n.socialGymFind,
      builder: () => Scaffold(
        appBar: AppBar(title: Text(l10n.socialGymFind)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.socialGymSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onChanged,
                onSubmitted: (t) {
                  _debounce?.cancel();
                  setState(() => _results = _search(t));
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Gym>>(
                future: _results,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return SocialMessage(
                      icon: Icons.cloud_off_outlined,
                      title: l10n.socialOffline,
                      action: OutlinedButton(
                        onPressed: () => setState(
                            () => _results = _search(_query.text)),
                        child: Text(l10n.socialRetry),
                      ),
                    );
                  }
                  final gyms = snap.data ?? const <Gym>[];
                  return ListView(
                    children: [
                      if (gyms.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.socialGymSearchEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final g in gyms)
                        ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(g.name),
                          subtitle: Text([
                            if (g.city.isNotEmpty) g.city,
                            if (g.address != null && g.address!.isNotEmpty)
                              g.address!,
                          ].join(' · ')),
                          trailing: Text(l10n.socialGymMembers(g.memberCount)),
                          onTap: () => _open(
                            '/gym/join?id=${Uri.encodeQueryComponent(g.id)}'
                            '&from=find',
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: () => _open('/gym/create?from=find'),
                          icon: const Icon(Icons.add_business_outlined),
                          label: Text(l10n.socialGymCreateMissing),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Založení posilovny
// ---------------------------------------------------------------------------

/// /gym/create – nová posilovna (název, město, adresa).
class GymCreateScreen extends ConsumerStatefulWidget {
  const GymCreateScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<GymCreateScreen> createState() => _GymCreateScreenState();
}

class _GymCreateScreenState extends ConsumerState<GymCreateScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _city.text.trim().isNotEmpty;

  Future<void> _create() async {
    if (!_valid) return;
    final l10n = AppLocalizations.of(context);
    final initial = await _initialProfile(ref);
    if (!mounted) return;
    final input = await showGymProfileSheet(
      context,
      initial: initial,
      title: l10n.socialGymJoinTitle(_name.text.trim()),
      confirmLabel: l10n.socialGymCreate,
      note: l10n.socialGymJoinNote,
    );
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await saveGymBirthYear(ref.read(databaseProvider), input.birthYear);
      final address = _address.text.trim();
      await GymService.instance.createGym(
        name: _name.text,
        city: _city.text,
        address: address.isEmpty ? null : address,
        profile: input,
      );
      unawaited(
          GymPublisher.publish(ref.read(databaseProvider), force: true));
      if (!mounted) return;
      showSocialSnack(context, l10n.socialGymCreated);
      _finish(context, widget.from);
    } catch (e) {
      debugPrint('Gym: create failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inGym = ref.watch(gymMembershipProvider).valueOrNull?.gymId != null;
    return gymGate(
      context,
      ref,
      title: l10n.socialGymCreate,
      builder: () => Scaffold(
        appBar: AppBar(title: Text(l10n.socialGymCreate)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.socialGymCreateHint),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: gymNameMaxLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.socialGymName),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _city,
              maxLength: gymNameMaxLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.socialGymCity),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _address,
              maxLength: gymAddressMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.socialGymAddress,
                helperText: l10n.socialGymAddressHint,
              ),
            ),
            if (inGym) ...[
              const SizedBox(height: 8),
              Text(l10n.socialGymSwitchHint),
            ],
            const SizedBox(height: 16),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _valid ? _create : null,
                icon: const Icon(Icons.add_business_outlined),
                label: Text(l10n.socialGymCreate),
              ),
          ],
        ),
      ),
    );
  }
}
