import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/text_filter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../services/location_service.dart';
import '../../../ui/dialogs.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_publisher.dart';
import '../gym/gym_service.dart';
import '../social_logic.dart';
import '../social_publisher.dart';
import 'gym_screen.dart' show gymGate;
import 'gym_widgets.dart';
import 'moderation_ui.dart';
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
    printable: m?.printable ?? true,
    birthYear: profile.birthYear,
  );
}

// ---------------------------------------------------------------------------
// Vstup do posilovny (kód z QR / odkazu, nebo ID ze seznamu)
// ---------------------------------------------------------------------------

/// /gym/join?code=XXXXXX nebo `/gym/join?id=<gymId>`
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
          appBar: AppBar(
            title: Text(l10n.socialGymJoin),
            actions: [
              PopupMenuButton<bool>(
                onSelected: (_) async {
                  final gym = await _load().catchError((_) => null);
                  if (gym != null && context.mounted) {
                    await reportGymFlow(context, gym);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Text(l10n.moderationReportGym),
                  ),
                ],
              ),
            ],
          ),
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
              final here = LocationService.instance.last;
              final km = here == null
                  ? null
                  : GymService.withDistance([gym], here).first.km;
              final details = [
                if (place.isNotEmpty) place,
                if (km != null) formatGymDistance(context, km),
                l10n.socialGymMembers(gym.memberCount),
                if (current != null && current != gym.id)
                  l10n.socialGymSwitchHint,
              ].join('\n');
              final website = Uri.tryParse(gym.website ?? '');
              return Column(
                children: [
                  Expanded(
                    child: SocialMessage(
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
                    ),
                  ),
                  if (website != null && website.hasScheme)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => launchUrl(website,
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.public),
                        label: Text(l10n.socialGymWebsite),
                      ),
                    ),
                  if (gym.isFromOsm) const OsmAttribution(),
                ],
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

/// /gym/find – adresář posiloven: v okolí (poloha), podle názvu nebo města.
class GymFindScreen extends ConsumerStatefulWidget {
  const GymFindScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<GymFindScreen> createState() => _GymFindScreenState();
}

class _GymFindScreenState extends ConsumerState<GymFindScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  late Future<List<GymWithDistance>> _results = _search('');

  /// Posilovny v okolí (null = poloha ještě nezjištěná).
  Future<List<GymWithDistance>>? _nearby;
  bool _locating = false;
  LocationFailure? _locationFailure;

  GeoPosition? get _here => LocationService.instance.last;

  @override
  void initState() {
    super.initState();
    // Poloha už povolená → okolí hned, bez dotazu. Jinak až po klepnutí.
    final known = _here;
    if (known != null) {
      _nearby = _loadNearby(known);
    } else {
      LocationService.instance.hasPermission().then((ok) {
        if (ok && mounted) _locate();
      });
    }
  }

  Future<List<GymWithDistance>> _search(String q) => GymService.instance
      .search(q, near: _here)
      .timeout(const Duration(seconds: 15));

  Future<List<GymWithDistance>> _loadNearby(GeoPosition p) => GymService
      .instance
      .nearby(p.lat, p.lng)
      .timeout(const Duration(seconds: 20));

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    final result = await LocationService.instance.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationFailure = result.failure;
      final p = result.position;
      if (p != null) {
        _nearby = _loadNearby(p);
        // Výsledky hledání přeřadit podle vzdálenosti.
        _results = _search(_query.text);
      }
    });
  }

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

  void _openGym(Gym g) =>
      _open('/gym/join?id=${Uri.encodeQueryComponent(g.id)}&from=find');

  String _failureText(AppLocalizations l10n, LocationFailure f) => switch (f) {
        LocationFailure.serviceOff => l10n.socialGymLocationOff,
        LocationFailure.denied ||
        LocationFailure.deniedForever =>
          l10n.socialGymLocationDenied,
        LocationFailure.unavailable => l10n.socialGymLocationUnavailable,
      };

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );

  /// Sekce „Posilovny v okolí“ (jen bez hledaného textu).
  List<Widget> _nearbySection(BuildContext context, AppLocalizations l10n) {
    final failure = _locationFailure;
    final nearby = _nearby;
    return [
      _sectionTitle(context, l10n.socialGymNearby),
      if (_locating)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (nearby == null)
        ListTile(
          leading: const Icon(Icons.near_me_outlined),
          title: Text(failure == null
              ? l10n.socialGymNearbyFind
              : _failureText(l10n, failure)),
          subtitle: Text(l10n.socialGymNearbyHint),
          trailing: failure == LocationFailure.deniedForever ||
                  failure == LocationFailure.serviceOff
              ? TextButton(
                  onPressed: () =>
                      LocationService.instance.openSettings(failure!),
                  child: Text(l10n.socialGymLocationSettings),
                )
              : null,
          onTap: _locate,
        )
      else
        FutureBuilder<List<GymWithDistance>>(
          future: nearby,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l10n.socialOffline),
                trailing: TextButton(
                  onPressed: _locate,
                  child: Text(l10n.socialRetry),
                ),
              );
            }
            final list = snap.data ?? const <GymWithDistance>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(l10n.socialGymNearbyEmpty),
              );
            }
            return Column(
              children: [
                for (final g in list)
                  GymListTile(item: g, onTap: () => _openGym(g.gym)),
              ],
            );
          },
        ),
    ];
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
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.socialGymSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (t) {
                  setState(() {}); // přepnout okolí ↔ výsledky
                  _onChanged(t);
                },
                onSubmitted: (t) {
                  _debounce?.cancel();
                  setState(() => _results = _search(t));
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<GymWithDistance>>(
                future: _results,
                builder: (context, snap) {
                  final searching = _query.text.trim().isNotEmpty;
                  final loading =
                      snap.connectionState != ConnectionState.done;
                  final gyms = snap.data ?? const <GymWithDistance>[];
                  return ListView(
                    children: [
                      if (!searching) ..._nearbySection(context, l10n),
                      if (!searching)
                        _sectionTitle(context, l10n.socialGymMostMembers),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snap.hasError)
                        ListTile(
                          leading: const Icon(Icons.cloud_off_outlined),
                          title: Text(l10n.socialOffline),
                          trailing: TextButton(
                            onPressed: () => setState(
                                () => _results = _search(_query.text)),
                            child: Text(l10n.socialRetry),
                          ),
                        )
                      else if (gyms.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.socialGymSearchEmpty,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        for (final g in gyms)
                          GymListTile(item: g, onTap: () => _openGym(g.gym)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: () => _open('/gym/create?from=find'),
                          icon: const Icon(Icons.add_business_outlined),
                          label: Text(l10n.socialGymCreateMissing),
                        ),
                      ),
                      const OsmAttribution(),
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

  /// „Jsem teď v této posilovně“ – uloží polohu posilovny.
  bool _hereNow = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _blocked(TextEditingController c) =>
      containsSevereProfanity(c.text)
          ? AppLocalizations.of(context).textFilterBlocked
          : null;

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _blocked(_name) == null &&
      _blocked(_city) == null &&
      _blocked(_address) == null;

  /// Zeptá se, jestli zakládaná posilovna už neexistuje. Vrací true,
  /// když se má založit nová (uživatel vybral existující → otevře ji).
  Future<bool> _checkDuplicates(GeoPosition? near) async {
    List<GymWithDistance> candidates;
    try {
      candidates = await GymService.instance
          .possibleDuplicates(name: _name.text, city: _city.text, near: near)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Gym: duplicate check failed: $e');
      return true;
    }
    if (candidates.isEmpty || !mounted) return true;
    final l10n = AppLocalizations.of(context);
    final picked = await showDialog<Object>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.socialGymDuplicateTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(l10n.socialGymDuplicateMessage),
              const SizedBox(height: 8),
              for (final c in candidates)
                GymListTile(
                  item: c,
                  onTap: () => Navigator.of(context).pop(c.gym),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.socialGymDuplicateCreateAnyway),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (picked is Gym) {
      context.pushReplacement('/gym/join?id=${Uri.encodeQueryComponent(picked.id)}'
          '${_fromQuery(widget.from)}');
      return false;
    }
    return picked == true;
  }

  Future<void> _create() async {
    if (!_valid) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    GeoPosition? location;
    if (_hereNow) {
      final result = await LocationService.instance.current();
      location = result.position;
      if (location == null && mounted) {
        showSocialSnack(context, l10n.socialGymLocationUnavailable);
      }
    }
    final proceed =
        await _checkDuplicates(location ?? LocationService.instance.last);
    if (mounted) setState(() => _busy = false);
    if (!proceed || !mounted) return;
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
        location: location,
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
              decoration: InputDecoration(
                labelText: l10n.socialGymName,
                errorText: _blocked(_name),
                errorMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _city,
              maxLength: gymNameMaxLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.socialGymCity,
                errorText: _blocked(_city),
                errorMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _address,
              maxLength: gymAddressMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.socialGymAddress,
                helperText: l10n.socialGymAddressHint,
                errorText: _blocked(_address),
                errorMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hereNow,
              onChanged: (v) => setState(() => _hereNow = v),
              title: Text(l10n.socialGymHereNow),
              subtitle: Text(l10n.socialGymHereNowHint),
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
