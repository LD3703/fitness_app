import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../ui/dialogs.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_publisher.dart';
import '../gym/gym_service.dart';
import '../social_backend.dart';
import '../social_logic.dart';
import '../social_publisher.dart';
import '../social_queries.dart';
import '../social_service.dart';
import 'friends_screen.dart' show SocialSignInView;
import 'gym_widgets.dart';
import 'social_ui.dart';

/// Ověří Firebase a přihlášení; jinak ukáže zprávu / přihlášení.
/// [builder] se zavolá jen pro přihlášeného uživatele.
Widget gymGate(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required Widget Function() builder,
}) {
  final l10n = AppLocalizations.of(context);
  Widget scaffold(Widget body) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: body);
  if (!ref.watch(socialAvailableProvider)) {
    return scaffold(SocialMessage(
      icon: Icons.cloud_off_outlined,
      title: l10n.socialNotSetUp,
      text: l10n.socialNotSetUpHint,
    ));
  }
  return ref.watch(socialUserProvider).when(
        loading: () =>
            scaffold(const Center(child: CircularProgressIndicator())),
        error: (e, _) => scaffold(SocialMessage(
          icon: Icons.error_outline,
          title: l10n.errorGeneric,
        )),
        data: (u) => u == null ? scaffold(const SocialSignInView()) : builder(),
      );
}

/// /gym – žebříček mé posilovny, nebo nabídka, jak se k nějaké připojit.
class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return gymGate(
      context,
      ref,
      title: l10n.socialGymTitle,
      builder: () => ref.watch(gymMembershipProvider).when(
            loading: () => Scaffold(
              appBar: AppBar(title: Text(l10n.socialGymTitle)),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              appBar: AppBar(title: Text(l10n.socialGymTitle)),
              body: SocialMessage(
                icon: Icons.cloud_off_outlined,
                title: l10n.socialOffline,
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(gymMembershipProvider),
                  child: Text(l10n.socialRetry),
                ),
              ),
            ),
            data: (m) {
              final gymId = m?.gymId;
              if (m == null || gymId == null) return const _NoGymView();
              return _GymBoardView(
                key: ValueKey(gymId),
                gymId: gymId,
                membership: m,
              );
            },
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bez posilovny
// ---------------------------------------------------------------------------

class _NoGymView extends StatelessWidget {
  const _NoGymView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialGymTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.fitness_center, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.socialGymIntroTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l10n.socialGymIntroText, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/gym/scan?from=gym'),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.socialGymScan),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/gym/find?from=gym'),
            icon: const Icon(Icons.search),
            label: Text(l10n.socialGymFind),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/gym/create?from=gym'),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(l10n.socialGymCreate),
          ),
          const SizedBox(height: 24),
          Text(l10n.socialGymPrivacy, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Žebříček
// ---------------------------------------------------------------------------

enum _MenuAction { profile, leave }

const _medalColors = [
  Color(0xFFFFC107), // zlato
  Color(0xFF9E9E9E), // stříbro
  Color(0xFFCD7F32), // bronz
];

class _GymBoardView extends ConsumerStatefulWidget {
  const _GymBoardView({
    super.key,
    required this.gymId,
    required this.membership,
  });

  final String gymId;
  final GymMembership membership;

  @override
  ConsumerState<_GymBoardView> createState() => _GymBoardViewState();
}

class _GymBoardViewState extends ConsumerState<_GymBoardView> {
  GymCategory _category = GymCategory.benchPress;
  GymGenderFilter _filter = GymGenderFilter.all;
  GymAgeFilter _ageFilter = GymAgeFilter.all;
  bool _monthly = true;

  @override
  void initState() {
    super.initState();
    // Při otevření žebříčku zveřejnit aktuální hodnoty (bez čekání na háček).
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  Future<void> _publish() async {
    final result =
        await GymPublisher.publish(ref.read(databaseProvider), force: true);
    if (!mounted || result == null) return;
    if (result.rejected.isNotEmpty) {
      showSocialSnack(context, AppLocalizations.of(context).socialGymImplausible);
    }
  }

  Future<void> _editProfile() async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final profile = await db.watchProfile().first;
    if (!mounted) return;
    final m = widget.membership;
    final input = await showGymProfileSheet(
      context,
      initial: (
        nickname: m.nickname ?? SocialPublisher.displayName(profile),
        gender: m.gender,
        show: m.show,
        birthYear: profile.birthYear,
      ),
      title: l10n.socialGymMyProfile,
      confirmLabel: l10n.save,
    );
    if (input == null || !mounted) return;
    try {
      await saveGymBirthYear(db, input.birthYear);
      await GymService.instance.updateProfile(widget.gymId, input);
      if (input.show) await GymPublisher.publish(db, force: true);
    } catch (e) {
      debugPrint('Gym: profile update failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _leave(Gym? gym) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.socialGymLeaveTitle(gym?.name ?? l10n.socialGymTitle),
      message: l10n.socialGymLeaveMessage,
      confirmLabel: l10n.socialGymLeave,
      destructive: true,
    );
    if (!ok) return;
    try {
      await GymService.instance.leaveGym();
      GymPublisher.rejected.value = const {};
      messenger.showSnackBar(SnackBar(content: Text(l10n.socialGymLeft)));
    } catch (e) {
      debugPrint('Gym: leave failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.socialOffline)));
    }
  }

  Future<void> _report(GymEntry e) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.socialGymReportTitle(e.nickname),
      message: l10n.socialGymReportMessage,
      confirmLabel: l10n.socialGymReport,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final service = GymService.instance;
      if (await service.hasReported(widget.gymId, e.id)) {
        if (mounted) showSocialSnack(context, l10n.socialGymReportedAlready);
        return;
      }
      await service.report(widget.gymId, e.id);
      if (mounted) showSocialSnack(context, l10n.socialGymReported);
    } catch (err) {
      debugPrint('Gym: report failed: $err');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  /// „Překonej mě“ u lídra → lokální výzva (stejně jako výzvy od přátel).
  Future<void> _beatMe(GymEntry e, double value) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final remoteId = gymChallengeRemoteId(
      gymId: widget.gymId,
      uid: e.uid,
      category: e.category,
      value: value,
    );
    try {
      if (await db.socialChallengeByRemoteId(remoteId) != null) {
        if (mounted) showSocialSnack(context, l10n.socialGymChallengeExists);
        return;
      }
      final now = DateTime.now();
      final slug = e.category.exerciseSlug;
      if (slug != null) {
        final exercise = await db.socialExerciseBySlug(slug);
        await db.socialInsertChallenge(
          remoteId: remoteId,
          kind: ChallengeKind.beatRecord,
          targetValue: value,
          fromName: e.nickname,
          deadline: DateTime(now.year, now.month, now.day + 30, 23, 59),
          exerciseSlug: slug,
          exerciseId: exercise?.id,
        );
      } else {
        // Tréninky: aspoň o jeden víc než lídr, do konce měsíce.
        await db.socialInsertChallenge(
          remoteId: remoteId,
          kind: ChallengeKind.workoutsInMonth,
          targetValue: value.roundToDouble() + 1,
          fromName: e.nickname,
          deadline: endOfMonth(now),
        );
      }
      if (mounted) showSocialSnack(context, l10n.socialGymChallengeAdded);
    } catch (err) {
      debugPrint('Gym: beat-me challenge failed: $err');
      if (mounted) showSocialSnack(context, l10n.errorGeneric);
    }
  }

  String _hint(AppLocalizations l10n) {
    if (!_category.isLift) {
      return _monthly
          ? l10n.socialGymHintWorkoutsMonth
          : l10n.socialGymHintWorkoutsAllTime;
    }
    final hint = l10n.socialGymHintLift(gymMaxReps);
    final note = gymCategoryNote(l10n, _category);
    return note == null ? hint : '$hint $note';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gym = ref.watch(gymProvider(widget.gymId)).valueOrNull;
    final month = monthKey(DateTime.now());
    final board = ref.watch(gymBoardProvider((
      gymId: widget.gymId,
      category: _category,
      monthly: _monthly,
      month: month,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(gym?.name ?? l10n.socialGymTitle),
        actions: [
          IconButton(
            tooltip: l10n.socialGymQr,
            icon: const Icon(Icons.qr_code_2),
            onPressed: gym == null ? null : () => showGymQrSheet(context, gym),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (a) => switch (a) {
              _MenuAction.profile => _editProfile(),
              _MenuAction.leave => _leave(gym),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.profile,
                child: Text(l10n.socialGymMyProfile),
              ),
              PopupMenuItem(
                value: _MenuAction.leave,
                child: Text(l10n.socialGymLeave),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _publish,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (gym != null) _header(context, gym),
            ValueListenableBuilder<Set<GymCategory>>(
              valueListenable: GymPublisher.rejected,
              builder: (context, rejected, _) => rejected.isEmpty
                  ? const SizedBox.shrink()
                  : _notice(
                      context,
                      icon: Icons.report_gmailerrorred_outlined,
                      text: l10n.socialGymImplausibleDetail(
                        rejected.map((c) => gymCategoryLabel(l10n, c)).join(', '),
                      ),
                    ),
            ),
            if (!widget.membership.show)
              _notice(
                context,
                icon: Icons.visibility_off_outlined,
                text: l10n.socialGymHiddenByMe,
                action: TextButton(
                  onPressed: _editProfile,
                  child: Text(l10n.socialGymShowMe),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  for (final c in GymCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(gymCategoryLabel(l10n, c)),
                        tooltip: gymCategoryNote(l10n, c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SegmentedButton<GymGenderFilter>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: GymGenderFilter.all,
                        label: Text(l10n.socialGymFilterAll),
                      ),
                      ButtonSegment(
                        value: GymGenderFilter.men,
                        label: Text(l10n.socialGymFilterMen),
                      ),
                      ButtonSegment(
                        value: GymGenderFilter.women,
                        label: Text(l10n.socialGymFilterWomen),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.socialGymPeriodMonth),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.socialGymPeriodAllTime),
                      ),
                    ],
                    selected: {_monthly},
                    onSelectionChanged: (s) =>
                        setState(() => _monthly = s.first),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  for (final f in GymAgeFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(gymAgeFilterLabel(l10n, f)),
                        selected: _ageFilter == f,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _ageFilter = f),
                      ),
                    ),
                ],
              ),
            ),
            if (_ageFilter != GymAgeFilter.all &&
                ref.watch(profileProvider).valueOrNull?.birthYear == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.socialGymAgeMissing,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _editProfile,
                      child: Text(l10n.socialGymMyProfile),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(_hint(l10n), style: theme.textTheme.bodySmall),
            ),
            ...board.when<List<Widget>>(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SocialMessage(
                  icon: Icons.cloud_off_outlined,
                  title: l10n.socialOffline,
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(gymBoardProvider),
                    child: Text(l10n.socialRetry),
                  ),
                ),
              ],
              data: (entries) => _rows(context, entries, gym, month),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(l10n.socialGymPrivacy, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Gym gym) {
    final l10n = AppLocalizations.of(context);
    final place = [
      if (gym.city.isNotEmpty) gym.city,
      if (gym.address != null && gym.address!.isNotEmpty) gym.address!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ListTile(
        leading: Icon(
          Icons.fitness_center,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(gym.name),
        subtitle: Text(
          [if (place.isNotEmpty) place, l10n.socialGymMembers(gym.memberCount)]
              .join('\n'),
        ),
        trailing: IconButton(
          tooltip: l10n.socialGymSharePoster,
          icon: const Icon(Icons.share_outlined),
          onPressed: () => shareGymPoster(context, gym),
        ),
      ),
    );
  }

  Widget _notice(
    BuildContext context, {
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: scheme.onErrorContainer)),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(
    BuildContext context,
    List<GymEntry> entries,
    Gym? gym,
    String month,
  ) {
    final l10n = AppLocalizations.of(context);
    final me = GymService.instance.uid;
    GymEntry? mine;
    for (final e in entries) {
      if (e.uid == me) mine = e;
    }
    final visible = entries.where(
      (e) =>
          !e.isHidden &&
          gymGenderMatches(_filter, e.gender) &&
          gymAgeMatches(_ageFilter, e.ageGroup),
    );
    final ranked = rankBy<GymEntry>(
      visible,
      (e) => e.valueFor(monthly: _monthly, month: month),
    );
    return [
      if (mine != null && mine.isHidden)
        _notice(
          context,
          icon: Icons.visibility_off_outlined,
          text: mine.hiddenForReports
              ? l10n.socialGymHiddenReports
              : l10n.socialGymHiddenImplausible,
        ),
      if (ranked.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.socialGymBoardEmpty, textAlign: TextAlign.center),
        ),
      for (final r in ranked)
        _tile(context, r, isMe: r.item.uid == me, gym: gym),
    ];
  }

  Widget _tile(
    BuildContext context,
    RankedEntry<GymEntry> r, {
    required bool isMe,
    required Gym? gym,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = r.item;
    final leader = r.rank == 1;
    final canChallenge = leader && !isMe;
    final valueText = gymValueText(context, e.category, r.value);
    return ListTile(
      selected: isMe,
      leading: SizedBox(
        width: 36,
        child: Center(
          child: r.rank <= 3
              ? Icon(Icons.emoji_events, color: _medalColors[r.rank - 1])
              : Text('${r.rank}', style: theme.textTheme.titleMedium),
        ),
      ),
      title: Text(isMe ? l10n.socialBoardYou(e.nickname) : e.nickname),
      subtitle: canChallenge
          ? Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => _beatMe(e, r.value),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(l10n.socialGymBeatMe),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valueText, style: theme.textTheme.titleMedium),
          if (isMe && leader && gym != null)
            IconButton(
              tooltip: l10n.socialGymShareStrongest,
              icon: const Icon(Icons.ios_share),
              onPressed: () => shareGymStrongest(
                context,
                gym: gym,
                category: e.category,
                value: r.value,
                nickname: e.nickname,
                monthly: _monthly,
              ),
            ),
          if (!isMe)
            PopupMenuButton<bool>(
              tooltip: l10n.socialGymReport,
              onSelected: (_) => _report(e),
              itemBuilder: (context) => [
                PopupMenuItem(value: true, child: Text(l10n.socialGymReport)),
              ],
            ),
        ],
      ),
      onLongPress: isMe ? null : () => _report(e),
    );
  }
}

// ---------------------------------------------------------------------------
// Karta na obrazovce Pokrok
// ---------------------------------------------------------------------------

/// [social:progress] – vstup do žebříčku posilovny.
class GymProgressCard extends ConsumerWidget {
  const GymProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(socialAvailableProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gymId = ref.watch(gymMembershipProvider).valueOrNull?.gymId;
    final gym = gymId == null ? null : ref.watch(gymProvider(gymId)).valueOrNull;
    return Card(
      child: ListTile(
        leading: Icon(Icons.leaderboard_outlined,
            color: theme.colorScheme.primary),
        title: Text(l10n.socialGymTitle),
        subtitle: Text(gym == null
            ? l10n.socialGymProgressJoin
            : '${gym.name} · ${l10n.socialGymMembers(gym.memberCount)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/gym'),
      ),
    );
  }
}
