import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/seed/content_i18n.dart';
import '../../data/seed/plan_templates.dart';
import '../../l10n/app_localizations.dart';
import '../../premium/premium.dart';
import '../../providers.dart';
import '../../ui/dialogs.dart';
import '../../ui/weekdays.dart';
import '../workout/start_workout.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // Premium: verze zdarma má nejvýš 3 vlastní plány (plány z hotových
    // programů se nepočítají).
    final plans = ref.read(plansProvider).valueOrNull ?? const [];
    final customCount = countCustomPlans(
      plans.where((p) => !p.isBuiltIn).map((p) => p.name),
    );
    final premium =
        ref.read(premiumProvider).isPremium(PremiumFeature.unlimitedPlans);
    if (!canCreateCustomPlan(customPlanCount: customCount, premium: premium) &&
        !await requirePremium(context, ref, PremiumFeature.unlimitedPlans)) {
      return;
    }
    if (!context.mounted) return;
    final name = await showTextInputDialog(
      context,
      title: l10n.plansNew,
      hintText: l10n.planNameHint,
    );
    if (name == null) return;
    final id = await ref.read(databaseProvider).createPlan(name);
    if (context.mounted) context.go('/plans/$id');
  }

  Future<void> _addTemplate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String name(TemplateProgram p) => seedText(lang,
        en: p.nameEn, cs: p.nameCs, other: (t) => t.programNames[p.slug]);
    String description(TemplateProgram p) => seedText(lang,
        en: p.descriptionEn,
        cs: p.descriptionCs,
        other: (t) => t.programDescriptions[p.slug]);
    final premium =
        ref.read(premiumProvider).isPremium(PremiumFeature.allPrograms);
    final program = await showModalBottomSheet<TemplateProgram>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.templatesTitle,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final (index, p) in templatePrograms.indexed)
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text(name(p)),
                subtitle: Text(description(p)),
                // Premium: zdarma jsou první 2 programy.
                trailing: isProgramLocked(index, premium: premium)
                    ? const PremiumBadge()
                    : null,
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (program == null || !context.mounted) return;
    if (isProgramLocked(templatePrograms.indexOf(program), premium: premium) &&
        !await requirePremium(context, ref, PremiumFeature.allPrograms)) {
      return;
    }
    if (!context.mounted) return;
    // Dny tréninků si uživatel upraví hned při výběru programu.
    final masks = await showDialog<List<int>>(
      context: context,
      builder: (context) => _ProgramDaysDialog(
        program: program,
        title: name(program),
        planName: (p) => seedText(lang,
            en: p.nameEn, cs: p.nameCs, other: (t) => t.planNames[p.nameEn]),
      ),
    );
    if (masks == null || !context.mounted) return;
    await ref
        .read(databaseProvider)
        .addProgram(program, languageCode: lang, weekdayMasks: masks);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.templateAdded(name(program))),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPlans),
        actions: [
          TextButton.icon(
            onPressed: () => _addTemplate(context, ref),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(l10n.templatesButton),
          ),
        ],
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.plansEmpty, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _addTemplate(context, ref),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(l10n.templatesEmptyCta),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final plan = list[i];
              final parts = [
                if (plan.weekdaysMask != 0)
                  describeWeekdays(context, plan.weekdaysMask),
                if (plan.plannedTimeMinutes != null)
                  formatMinutesOfDay(context, plan.plannedTimeMinutes!),
              ];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text(
                  parts.isEmpty ? l10n.planNoSchedule : parts.join(' · '),
                ),
                onTap: () => context.go('/plans/${plan.id}'),
                trailing: IconButton.filledTonal(
                  tooltip: l10n.workoutStart,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => startWorkout(context, ref, planId: plan.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlan(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.plansNew),
      ),
    );
  }
}

/// Výběr dnů pro každý plán hotového programu (předvyplněno z programu).
class _ProgramDaysDialog extends StatefulWidget {
  const _ProgramDaysDialog({
    required this.program,
    required this.title,
    required this.planName,
  });

  final TemplateProgram program;
  final String title;
  final String Function(TemplatePlan plan) planName;

  @override
  State<_ProgramDaysDialog> createState() => _ProgramDaysDialogState();
}

class _ProgramDaysDialogState extends State<_ProgramDaysDialog> {
  late final List<int> _masks = [
    for (final p in widget.program.plans) p.weekdaysMask,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dayNames = shortWeekdayNames(context);
    final plans = widget.program.plans;

    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.templateDaysHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          for (var p = 0; p < plans.length; p++) ...[
            const SizedBox(height: 16),
            Text(widget.planName(plans[p]), style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var d = 0; d < 7; d++)
                  FilterChip(
                    label: Text(dayNames[d]),
                    visualDensity: VisualDensity.compact,
                    selected: isWeekdayInMask(_masks[p], d),
                    onSelected: (_) =>
                        setState(() => _masks[p] = toggleWeekday(_masks[p], d)),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(List<int>.of(_masks)),
          child: Text(l10n.templateDaysConfirm),
        ),
      ],
    );
  }
}
