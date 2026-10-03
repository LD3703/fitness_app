import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/labels.dart';

IconData periodIcon(PeriodType t) => switch (t) {
      PeriodType.illness => Icons.sick_outlined,
      PeriodType.injury => Icons.healing_outlined,
      PeriodType.cut => Icons.trending_down,
      PeriodType.bulk => Icons.trending_up,
      PeriodType.maintenance => Icons.balance,
      PeriodType.pause => Icons.beach_access_outlined,
    };

String formatDay(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

/// Seznam období (nemoc, zranění, dieta, nabírání…) s možností
/// přidat, upravit, ukončit a smazat.
class PeriodsScreen extends ConsumerWidget {
  const PeriodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final periods = ref.watch(periodsProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.periodsTitle)),
      body: periods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.periodsEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = list[i];
              final parts = p.injuredGroups;
              final title = parts.isEmpty
                  ? l10n.periodType(p.type)
                  : '${l10n.periodType(p.type)} · '
                      '${parts.map(l10n.muscleGroup).join(', ')}';
              final range = p.endDate == null
                  ? l10n.periodOngoingSince(formatDay(context, p.startDate))
                  : '${formatDay(context, p.startDate)} – '
                      '${formatDay(context, p.endDate!)}';
              return ListTile(
                leading: Icon(periodIcon(p.type)),
                title: Text(title),
                subtitle: Text(
                  p.note == null || p.note!.isEmpty ? range : '$range\n${p.note}',
                ),
                isThreeLine: p.note != null && p.note!.isNotEmpty,
                trailing: p.endDate == null
                    ? TextButton(
                        onPressed: () => db.endPeriod(p.id, DateTime.now()),
                        child: Text(l10n.periodEndToday),
                      )
                    : null,
                onTap: () => editPeriod(context, ref, existing: p),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editPeriod(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.periodAdd),
      ),
    );
  }
}

/// Otevře dialog pro nové nebo existující období a uloží výsledek.
Future<void> editPeriod(
  BuildContext context,
  WidgetRef ref, {
  Period? existing,
  PeriodType? initialType,
}) async {
  final result = await showDialog<_PeriodResult>(
    context: context,
    builder: (context) => _PeriodDialog(
      existing: existing,
      initialType: initialType,
    ),
  );
  if (result == null) return;
  final db = ref.read(databaseProvider);
  if (result.delete && existing != null) {
    await db.deletePeriod(existing.id);
  } else if (existing != null) {
    await db.updatePeriod(
      existing.id,
      type: result.type,
      start: result.start,
      end: result.end,
      note: result.note,
      muscleGroups: result.groups,
    );
  } else {
    await db.addPeriod(
      type: result.type,
      start: result.start,
      end: result.end,
      note: result.note,
      muscleGroups: result.groups,
    );
  }
}

typedef _PeriodResult = ({
  PeriodType type,
  DateTime start,
  DateTime? end,
  String? note,
  Set<MuscleGroup> groups,
  bool delete,
});

class _PeriodDialog extends StatefulWidget {
  const _PeriodDialog({this.existing, this.initialType});

  final Period? existing;
  final PeriodType? initialType;

  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  late PeriodType _type =
      widget.existing?.type ?? widget.initialType ?? PeriodType.illness;
  late DateTime _start = widget.existing?.startDate ?? DateTime.now();
  late DateTime? _end = widget.existing?.endDate;
  late bool _ongoing = widget.existing == null || widget.existing!.endDate == null;
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late final Set<MuscleGroup> _groups = {...?widget.existing?.injuredGroups};
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

  void _submit() {
    final end = _ongoing ? null : (_end ?? DateTime.now());
    if (end != null && end.isBefore(DateTime(_start.year, _start.month, _start.day))) {
      setState(() => _error = AppLocalizations.of(context).periodEndBeforeStart);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop((
      type: _type,
      start: _start,
      end: end,
      note: note.isEmpty ? null : note,
      groups: _type == PeriodType.injury ? _groups : const <MuscleGroup>{},
      delete: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.periodAdd : l10n.periodEdit),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in PeriodType.values)
                ChoiceChip(
                  avatar: Icon(periodIcon(t), size: 18),
                  label: Text(l10n.periodType(t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          if (_type == PeriodType.injury) ...[
            const SizedBox(height: 16),
            Text(l10n.periodInjuryParts,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in MuscleGroup.values)
                  if (g != MuscleGroup.fullBody)
                    FilterChip(
                      label: Text(l10n.muscleGroup(g)),
                      selected: _groups.contains(g),
                      onSelected: (on) => setState(
                        () => on ? _groups.add(g) : _groups.remove(g),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _groups.isEmpty
                  ? l10n.periodInjuryPartsNone
                  : l10n.periodInjuryPartsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l10n.periodStart),
            subtitle: Text(formatDay(context, _start)),
            onTap: () async {
              final d = await _pickDate(_start);
              if (d != null) setState(() => _start = d);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.periodOngoing),
            value: _ongoing,
            onChanged: (v) => setState(() {
              _ongoing = v;
              if (!v) _end ??= DateTime.now();
            }),
          ),
          if (!_ongoing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available),
              title: Text(l10n.periodEnd),
              subtitle: Text(formatDay(context, _end ?? DateTime.now())),
              onTap: () async {
                final d = await _pickDate(_end ?? DateTime.now());
                if (d != null) setState(() => _end = d);
              },
            ),
          TextField(
            controller: _note,
            maxLength: 100,
            decoration: InputDecoration(labelText: l10n.periodNote),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop((
              type: _type,
              start: _start,
              end: _end,
              note: null,
              groups: const <MuscleGroup>{},
              delete: true,
            )),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
