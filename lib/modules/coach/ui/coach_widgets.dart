import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymbar_coach/gymbar_coach.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../sharing/share_service.dart';
import '../../social/social_backend.dart';
import '../../social/social_publisher.dart';
import '../../social/social_service.dart' show socialUserProvider;
import '../../social/ui/social_ui.dart' show showSocialSnack;
import '../coach_links.dart';
import '../coach_queries.dart';
import '../coach_service.dart';

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------

/// [coach:profile] – sekce „Trenér“ v Profilu.
class CoachProfileSection extends ConsumerWidget {
  const CoachProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = ref.watch(socialAvailableProvider);
    final user = available ? ref.watch(socialUserProvider).valueOrNull : null;
    final trainer = user == null ? null : ref.watch(myTrainerProvider).valueOrNull;
    final link = user == null ? null : ref.watch(myCoachLinkProvider).valueOrNull;
    final subtitle = !available
        ? l10n.socialNotSetUp
        : trainer != null
            ? l10n.coachProfileTrainer(trainer.clientCount)
            : link != null
                ? l10n.coachProfileClient(link.trainerName)
                : l10n.coachProfileNone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.coachTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sports),
          title: Text(l10n.coachProfileTile),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/coach'),
        ),
        const Divider(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editor plánu
// ---------------------------------------------------------------------------

/// [coach:plan] – sdílení plánu odkazem a poslání klientovi.
class CoachPlanSection extends ConsumerWidget {
  const CoachPlanSection({super.key, required this.planId});

  final int planId;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    try {
      final plan = await db.coachPlanFromLocal(planId);
      if (plan == null) return;
      final profile = await db.watchProfile().first;
      final id = await CoachService.instance
          .sharePlan(plan, authorName: SocialPublisher.displayName(profile));
      if (!context.mounted) return;
      await shareText(context, l10n.planShareText(plan.name, sharedPlanLink(id)));
    } catch (e) {
      debugPrint('Coach: share plan failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  Future<void> _sendToClient(
    BuildContext context,
    WidgetRef ref,
    TrainerProfile trainer,
    List<CoachLink> clients,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.planSendToClient),
        children: [
          for (final c in clients)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c.clientUid),
              child: Text(c.clientName),
            ),
        ],
      ),
    );
    if (picked == null) return;
    try {
      final plan = await ref.read(databaseProvider).coachPlanFromLocal(planId);
      if (plan == null) return;
      await CoachService.instance.assignPlan(
        picked,
        plan,
        trainerName: trainer.name,
        planId: 'app$planId',
      );
      if (context.mounted) showSocialSnack(context, l10n.coachSendPlanDone);
    } catch (e) {
      debugPrint('Coach: send plan failed: $e');
      if (context.mounted) showSocialSnack(context, l10n.socialOffline);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!ref.watch(socialAvailableProvider)) return const SizedBox.shrink();
    final user = ref.watch(socialUserProvider).valueOrNull;
    final plan = ref.watch(_planProvider(planId)).valueOrNull;
    final trainer = user == null ? null : ref.watch(myTrainerProvider).valueOrNull;
    final clients = trainer == null
        ? const <CoachLink>[]
        : ref.watch(myClientsProvider).valueOrNull ?? const <CoachLink>[];
    final fromTrainer = plan?.remoteId?.startsWith('coach:') ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fromTrainer && plan?.remoteFrom != null)
          ListTile(
            leading: const Icon(Icons.sports),
            title: Text(l10n.planFromTrainer(plan!.remoteFrom!)),
            subtitle: Text(l10n.planFromTrainerHint),
          ),
        ListTile(
          leading: const Icon(Icons.link),
          title: Text(l10n.planShareLink),
          onTap: user == null
              ? () => context.push('/coach')
              : () => _share(context, ref),
        ),
        if (trainer != null && clients.isNotEmpty && !fromTrainer)
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: Text(l10n.planSendToClient),
            onTap: () => _sendToClient(context, ref, trainer, clients),
          ),
      ],
    );
  }
}

final _planProvider = StreamProvider.autoDispose.family<WorkoutPlan?, int>(
  (ref, planId) => ref.watch(databaseProvider).watchPlan(planId),
);

// ---------------------------------------------------------------------------
// Dialog s víceřádkovým textem (komentář trenéra)
// ---------------------------------------------------------------------------

Future<String?> showMultilineInputDialog(
  BuildContext context, {
  required String title,
  int maxLength = coachNoteMax,
}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _MultilineDialog(title: title, maxLength: maxLength),
    );

class _MultilineDialog extends StatefulWidget {
  const _MultilineDialog({required this.title, required this.maxLength});

  final String title;
  final int maxLength;

  @override
  State<_MultilineDialog> createState() => _MultilineDialogState();
}

class _MultilineDialogState extends State<_MultilineDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Graf tréninků po týdnech
// ---------------------------------------------------------------------------

/// Sloupce: počet tréninků v každém z posledních týdnů.
class WeeklyBarsChart extends StatelessWidget {
  const WeeklyBarsChart({super.key, required this.weeks, this.height = 120});

  final List<WeekBucket> weeks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat.Md(Localizations.localeOf(context).toString());
    final labelStyle = theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant) ??
        const TextStyle(fontSize: 11);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _BarsPainter(
              values: [for (final w in weeks) w.workouts],
              color: theme.colorScheme.primary,
              labelStyle: labelStyle,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (weeks.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(weeks.first.start), style: labelStyle),
              Text(fmt.format(weeks.last.start), style: labelStyle),
            ],
          ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.color,
    required this.labelStyle,
  });

  final List<int> values;
  final Color color;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.fold<int>(1, (m, v) => v > m ? v : m);
    final slot = size.width / values.length;
    final barWidth = slot * 0.6;
    const labelSpace = 14.0;
    final paint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final h = (size.height - labelSpace) * v / maxValue;
      final left = i * slot + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, size.height - h, barWidth, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      if (v > 0) canvas.drawRRect(rect, paint);
      final tp = TextPainter(
        text: TextSpan(text: '$v', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(left + (barWidth - tp.width) / 2, size.height - h - tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.color != color;
}
