import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../../sharing/share_service.dart';
import '../../social/social_publisher.dart';
import '../../social/ui/gym_screen.dart' show gymGate;
import '../../social/ui/social_ui.dart' show showSocialSnack;
import '../coach_links.dart';
import '../coach_service.dart';
import '../coach_sync.dart';

/// /coach – můj trenér (klient) a status trenéra (docs/coach.md).
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: l10n.coachTitle,
      builder: () => Scaffold(
        appBar: AppBar(title: Text(l10n.coachTitle)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: const [
            _MyTrainerSection(),
            Divider(height: 32),
            _TrainerSection(),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );

String _date(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

// ---------------------------------------------------------------------------
// Klient: můj trenér
// ---------------------------------------------------------------------------

class _MyTrainerSection extends ConsumerWidget {
  const _MyTrainerSection();

  Future<void> _enterCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = await showTextInputDialog(
      context,
      title: l10n.coachEnterCode,
      hintText: l10n.coachCodeLabel,
    );
    if (text == null || !context.mounted) return;
    final code = parseCoachCode(text);
    if (code == null) {
      showSocialSnack(context, l10n.coachCodeInvalid);
      return;
    }
    context.push('/coach/connect?code=$code');
  }

  Future<void> _disconnect(BuildContext context, CoachLink link) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.coachDisconnectTitle,
      message: l10n.coachDisconnectMessage,
      confirmLabel: l10n.coachDisconnect,
      destructive: true,
    );
    if (!ok) return;
    try {
      await CoachService.instance.disconnect();
    } catch (e) {
      debugPrint('Coach: disconnect failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _setShareWeight(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await CoachService.instance.setShareWeight(value);
      if (value) {
        final link = await CoachService.instance.myLink();
        if (link != null) {
          await CoachSync.upload(ref.read(databaseProvider), link, days: 1);
        }
      }
    } catch (e) {
      debugPrint('Coach: share weight failed: $e');
      if (context.mounted) {
        showSocialSnack(context, AppLocalizations.of(context).socialOffline);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final link = ref.watch(myCoachLinkProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, l10n.coachMyTrainer),
        if (link == null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.coachNoTrainerText),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _enterCode(context),
              icon: const Icon(Icons.keyboard_outlined),
              label: Text(l10n.coachEnterCode),
            ),
          ),
        ] else ...[
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sports)),
            title: Text(link.trainerName),
            subtitle: link.createdAt == null
                ? null
                : Text(l10n.coachConnectedSince(_date(context, link.createdAt!))),
          ),
          SwitchListTile(
            title: Text(l10n.coachConnectWeight),
            subtitle: Text(l10n.coachConnectWeightHint),
            value: link.shareWeight,
            onChanged: (v) => _setShareWeight(context, ref, v),
          ),
          const _AssignedPlansList(),
          _NotesList(clientUid: link.clientUid),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                onPressed: () => _disconnect(context, link),
                icon: const Icon(Icons.link_off),
                label: Text(l10n.coachDisconnect),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AssignedPlansList extends ConsumerWidget {
  const _AssignedPlansList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plans = ref.watch(myAssignedPlansProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(l10n.coachPlansFromTrainer,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (plans.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l10n.coachPlansNone),
          ),
        for (final p in plans)
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(p.plan.name),
            subtitle: Text(l10n.coachPlanVersion(p.version)),
            trailing: IconButton(
              tooltip: l10n.coachPlanDismiss,
              icon: const Icon(Icons.close),
              onPressed: () async {
                try {
                  await CoachService.instance.dismissAssignedPlan(p.id);
                } catch (e) {
                  debugPrint('Coach: dismiss plan failed: $e');
                }
              },
            ),
            onTap: () async {
              final db = ref.read(databaseProvider);
              await CoachSync.importAssignedPlans(db);
              if (context.mounted) context.go('/plans');
            },
          ),
      ],
    );
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList({required this.clientUid});

  final String clientUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(coachNotesProvider(clientUid)).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(l10n.coachNotes,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l10n.coachNotesNone),
          ),
        for (final n in notes.take(10))
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(n.text),
            subtitle: n.createdAt == null
                ? Text(n.trainerName)
                : Text('${n.trainerName} · ${_date(context, n.createdAt!)}'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trenér
// ---------------------------------------------------------------------------

class _TrainerSection extends ConsumerWidget {
  const _TrainerSection();

  Future<void> _become(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final profile = await ref.read(databaseProvider).watchProfile().first;
    if (!context.mounted) return;
    final input = await showTrainerProfileSheet(
      context,
      initialName: SocialPublisher.displayName(profile),
      title: l10n.coachBecome,
      confirmLabel: l10n.coachBecome,
    );
    if (input == null) return;
    try {
      await CoachService.instance
          .becomeTrainer(name: input.name, bio: input.bio);
    } catch (e) {
      debugPrint('Coach: become trainer failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _edit(BuildContext context, TrainerProfile t) async {
    final l10n = AppLocalizations.of(context);
    final input = await showTrainerProfileSheet(
      context,
      initialName: t.name,
      initialBio: t.bio,
      title: l10n.coachEditProfile,
      confirmLabel: l10n.save,
    );
    if (input == null) return;
    try {
      await CoachService.instance.updateTrainer(name: input.name, bio: input.bio);
    } catch (e) {
      debugPrint('Coach: update trainer failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _stop(BuildContext context, TrainerProfile t) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.coachStopTitle,
      message: l10n.coachStopMessage,
      confirmLabel: l10n.coachStop,
      destructive: true,
    );
    if (!ok) return;
    try {
      await CoachService.instance.stopTrainer(t);
    } catch (e) {
      debugPrint('Coach: stop trainer failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trainer = ref.watch(myTrainerProvider).valueOrNull;
    if (trainer == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, l10n.coachIAmTrainer),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.coachBecomeText),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () => _become(context, ref),
              icon: const Icon(Icons.sports),
              label: Text(l10n.coachBecome),
            ),
          ),
        ],
      );
    }
    final link = coachInviteLink(trainer.code);
    final expires = trainer.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, l10n.coachIAmTrainer),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.sports)),
          title: Text(trainer.name),
          subtitle: Text(l10n.coachClientsCount(trainer.clientCount)),
          trailing: IconButton(
            tooltip: l10n.coachEditProfile,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, trainer),
          ),
        ),
        if (expires != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.coachExpiresWarning(_date(context, expires)),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(data: link, size: 180, backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SelectableText(
            trainer.code,
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
          ),
        ),
        Center(child: Text(l10n.coachYourCode, style: theme.textTheme.bodySmall)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.tonalIcon(
            onPressed: () => shareText(context, l10n.coachInviteText(link)),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.coachShareInvite),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: Text(l10n.coachMyClients),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/coach/clients'),
        ),
        ListTile(
          leading: const Icon(Icons.computer_outlined),
          title: Text(l10n.coachOpenWeb),
          subtitle: Text(l10n.coachWebHint),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => launchUrl(
            Uri.parse(kTrainerWebUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style:
                  TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _stop(context, trainer),
              icon: const Icon(Icons.logout),
              label: Text(l10n.coachStop),
            ),
          ),
        ),
      ],
    );
  }
}

/// Jméno a popis trenéra (založení i úprava).
typedef TrainerProfileInput = ({String name, String? bio});

Future<TrainerProfileInput?> showTrainerProfileSheet(
  BuildContext context, {
  required String initialName,
  String? initialBio,
  required String title,
  required String confirmLabel,
}) =>
    showModalBottomSheet<TrainerProfileInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TrainerProfileSheet(
        initialName: initialName == '?' ? '' : initialName,
        initialBio: initialBio,
        title: title,
        confirmLabel: confirmLabel,
      ),
    );

class _TrainerProfileSheet extends StatefulWidget {
  const _TrainerProfileSheet({
    required this.initialName,
    required this.initialBio,
    required this.title,
    required this.confirmLabel,
  });

  final String initialName;
  final String? initialBio;
  final String title;
  final String confirmLabel;

  @override
  State<_TrainerProfileSheet> createState() => _TrainerProfileSheetState();
}

class _TrainerProfileSheetState extends State<_TrainerProfileSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _bio = TextEditingController(text: widget.initialBio ?? '');

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? _blocked(TextEditingController c) => containsSevereProfanity(c.text)
      ? AppLocalizations.of(context).textFilterBlocked
      : null;

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _blocked(_name) == null &&
      _blocked(_bio) == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.coachBecomeText),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                maxLength: coachNameMax,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.coachNameLabel,
                  errorText: _blocked(_name),
                  errorMaxLines: 3,
                ),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _bio,
                maxLength: coachBioMax,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.coachBio,
                  helperText: l10n.coachBioHint,
                  helperMaxLines: 3,
                  errorText: _blocked(_bio),
                  errorMaxLines: 3,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _valid
                        ? () => Navigator.of(context).pop<TrainerProfileInput>(
                            (name: _name.text.trim(), bio: _bio.text.trim()))
                        : null,
                    child: Text(widget.confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Propojení s trenérem (/coach/connect?code=…)
// ---------------------------------------------------------------------------

class CoachConnectScreen extends ConsumerStatefulWidget {
  const CoachConnectScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<CoachConnectScreen> createState() => _CoachConnectScreenState();
}

class _CoachConnectScreenState extends ConsumerState<CoachConnectScreen> {
  Future<TrainerProfile?>? _lookup;
  bool _shareWeight = false;
  bool _busy = false;

  Future<TrainerProfile?> _load() {
    final code = parseCoachCode(widget.code);
    if (code == null) return Future.value(null);
    return CoachService.instance.lookupTrainer(code);
  }

  Future<void> _connect(TrainerProfile trainer) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    try {
      final profile = await db.watchProfile().first;
      await CoachService.instance.connect(
        trainer,
        clientName: SocialPublisher.displayName(profile),
        shareWeight: _shareWeight,
      );
      await CoachSync.backfill(db);
      if (!mounted) return;
      showSocialSnack(context, l10n.coachConnectDone);
      context.go('/coach');
    } catch (e) {
      debugPrint('Coach: connect failed: $e');
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
      title: l10n.coachConnectTitle,
      builder: () {
        _lookup ??= _load();
        final link = ref.watch(myCoachLinkProvider).valueOrNull;
        final me = CoachService.instance.uid;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.coachConnectTitle)),
          body: FutureBuilder<TrainerProfile?>(
            future: _lookup,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final trainer = snap.data;
              if (snap.hasError || trainer == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snap.hasError ? l10n.socialOffline : l10n.coachNotFound,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (trainer.uid == me) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.coachConnectSelf,
                        textAlign: TextAlign.center),
                  ),
                );
              }
              final theme = Theme.of(context);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Icon(Icons.sports, size: 48),
                  const SizedBox(height: 8),
                  Text(trainer.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                  if (trainer.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(trainer.bio!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  Text(l10n.coachConnectShares(trainer.name),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(l10n.coachConnectShareList),
                  const SizedBox(height: 8),
                  Text(l10n.coachConnectNotShared,
                      style: theme.textTheme.bodySmall),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.coachConnectWeight),
                    subtitle: Text(l10n.coachConnectWeightHint),
                    value: _shareWeight,
                    onChanged: (v) => setState(() => _shareWeight = v),
                  ),
                  if (link != null && link.trainerUid != trainer.uid) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.coachConnectReplace(link.trainerName),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    FilledButton.icon(
                      onPressed: () => _connect(trainer),
                      icon: const Icon(Icons.link),
                      label: Text(l10n.coachConnectButton),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
