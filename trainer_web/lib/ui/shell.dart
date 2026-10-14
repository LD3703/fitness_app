import 'package:flutter/material.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../backend.dart';
import '../strings.dart';
import 'client_page.dart';
import 'common.dart';
import 'plans_page.dart';

/// Hlavní rozložení: Klienti / Plány / Profil.
class Shell extends StatefulWidget {
  const Shell({super.key, required this.trainer});

  final Trainer trainer;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final pages = [
      ClientsPage(trainer: widget.trainer),
      PlansPage(trainer: widget.trainer),
      ProfilePage(trainer: widget.trainer),
    ];
    final destinations = [
      (Icons.groups_outlined, Icons.groups, s('navClients')),
      (Icons.list_alt_outlined, Icons.list_alt, s('navPlans')),
      (Icons.person_outline, Icons.person, s('navProfile')),
    ];
    final body = IndexedStack(index: _tab, children: pages);
    if (!wide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                  icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Klienti
// ---------------------------------------------------------------------------

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.trainer});

  final Trainer trainer;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  // Stream jednou za život stránky (ne při každém build).
  late final _clients = Backend.instance.watchClients();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final trainer = widget.trainer;
    return Scaffold(
      appBar: AppBar(title: Text(s('navClients'))),
      body: StreamBuilder<List<Client>>(
        stream: _clients,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(errorText(s, snap.error!)));
          }
          final clients = snap.data;
          if (clients == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return PageBody(
            children: [
              if (trainer.expiresAt != null)
                _ExpiryBanner(expiresAt: trainer.expiresAt!),
              if (clients.isEmpty)
                _Invite(trainer: trainer, empty: true)
              else ...[
                for (final c in clients)
                  _ClientTile(
                      key: ValueKey(c.uid), trainer: trainer, client: c),
                const SizedBox(height: 16),
                _Invite(trainer: trainer, empty: false),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
        title: Text(
          s('expiryWarning', {'date': fmtDate(expiresAt, s.locale)}),
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}

/// Jak pozvat klienty: kód a odkaz.
class _Invite extends StatelessWidget {
  const _Invite({required this.trainer, required this.empty});

  final Trainer trainer;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(empty ? s('noClientsTitle') : s('inviteMore'),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(s('inviteHow')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SelectableText(trainer.code,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 4)),
                OutlinedButton.icon(
                  onPressed: () => copyText(context, trainer.code),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(s('copyCode')),
                ),
                OutlinedButton.icon(
                  onPressed: () => copyText(context,
                      s('inviteText', {'name': trainer.name, 'link': trainer.inviteLink})),
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(s('copyInvite')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTile extends StatefulWidget {
  const _ClientTile({super.key, required this.trainer, required this.client});

  final Trainer trainer;
  final Client client;

  @override
  State<_ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<_ClientTile> {
  late final _workouts =
      Backend.instance.watchWorkouts(widget.client.uid, limit: 40);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final client = widget.client;
    return Card(
      child: StreamBuilder<List<CoachWorkout>>(
        stream: _workouts,
        builder: (context, snap) {
          final now = DateTime.now();
          final summary =
              snap.data == null ? null : summarizeClient(snap.data!, now: now);
          final days = summary?.daysSinceLast(now);
          final inactive = summary?.inactive(now) ?? false;
          final subtitle = summary == null
              ? '…'
              : [
                  days == null
                      ? s('noWorkoutsYet')
                      : s('lastWorkoutDays', {'days': days}),
                  s('thisWeekCount', {'n': summary.thisWeek}),
                ].join(' · ');
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: CircleAvatar(
              child: Text(client.name.isEmpty ? '?' : client.name[0].toUpperCase()),
            ),
            title: Text(client.name, style: theme.textTheme.titleMedium),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inactive)
                  Tooltip(
                    message: s('inactiveTooltip'),
                    child: Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.error),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) =>
                  ClientPage(trainer: widget.trainer, client: client),
            )),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.trainer});

  final Trainer trainer;

  Future<void> _edit(BuildContext context) async {
    final s = S.of(context);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _ProfileDialog(trainer: trainer),
    );
    if (result == null || !context.mounted) return;
    if (containsSevereProfanity(result.$1) || containsSevereProfanity(result.$2)) {
      showSnack(context, s('profanity'));
      return;
    }
    try {
      await Backend.instance.updateTrainer(name: result.$1, bio: result.$2);
      if (context.mounted) showSnack(context, s('saved'));
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  Future<void> _stop(BuildContext context) async {
    final s = S.of(context);
    final ok = await confirm(
      context,
      title: s('stopTitle'),
      message: s('stopMessage'),
      action: s('stopButton'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await Backend.instance.stopTrainer(trainer);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final user = Backend.instance.user;
    return Scaffold(
      appBar: AppBar(title: Text(s('navProfile'))),
      body: PageBody(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(trainer.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(s('edit')),
                      ),
                    ],
                  ),
                  if (trainer.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(trainer.bio!),
                  ],
                  const SizedBox(height: 16),
                  Text(s('clientCount', {'n': trainer.clientCount})),
                  const SizedBox(height: 4),
                  Text(s('yourCode', {'code': trainer.code})),
                  if (trainer.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      s('expiryWarning', {'date': fmtDate(trainer.expiresAt!, s.locale)}),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _Invite(trainer: trainer, empty: false),
          SectionTitle(s('account')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user?.email ?? user?.uid ?? ''),
                  subtitle: Text(s('signInSameAccount')),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(s('signOut')),
                  onTap: Backend.instance.signOut,
                ),
                ListTile(
                  leading: Icon(Icons.person_off_outlined,
                      color: theme.colorScheme.error),
                  title: Text(s('stopButton'),
                      style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: Text(s('stopHint')),
                  onTap: () => _stop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.trainer});

  final Trainer trainer;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final _name = TextEditingController(text: widget.trainer.name);
  late final _bio = TextEditingController(text: widget.trainer.bio ?? '');

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s('editProfile')),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              maxLength: coachNameMax,
              decoration: InputDecoration(labelText: s('trainerName')),
            ),
            TextField(
              controller: _bio,
              maxLength: coachBioMax,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                  labelText: s('trainerBio'), helperText: s('trainerBioHint')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.of(context).pop((_name.text, _bio.text));
          },
          child: Text(s('save')),
        ),
      ],
    );
  }
}
