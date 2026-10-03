import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/dialogs.dart';
import '../../ui/format.dart';
import '../../ui/labels.dart';
import 'data_queries.dart';

/// Popisek typu cviku.
String exerciseTypeLabel(AppLocalizations l10n, ExerciseType t) =>
    switch (t) {
      ExerciseType.weightReps => l10n.dataTypeWeightReps,
      ExerciseType.bodyweightReps => l10n.dataTypeBodyweightReps,
      ExerciseType.duration => l10n.dataTypeDuration,
    };

/// Formulář pro nový vlastní cvik ([exerciseId] == null) nebo úpravu
/// existujícího vlastního cviku. Cesta: /exercise-edit, /exercise-edit?id=5.
class ExerciseEditScreen extends ConsumerStatefulWidget {
  const ExerciseEditScreen({super.key, this.exerciseId});

  final int? exerciseId;

  @override
  ConsumerState<ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends ConsumerState<ExerciseEditScreen> {
  static const _defaultMet = 5.0;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _instructions = TextEditingController();
  final _met = TextEditingController(text: plainNumber(_defaultMet));
  MuscleGroup _group = MuscleGroup.chest;
  Equipment _equipment = Equipment.dumbbell;
  ExerciseType _type = ExerciseType.weightReps;

  bool _loading = true;
  bool _notEditable = false;
  bool _saving = false;

  bool get _isEdit => widget.exerciseId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.exerciseId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final e = await ref.read(databaseProvider).dataExerciseById(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (e == null || !e.isCustom) {
        _notEditable = true;
        return;
      }
      _name.text = e.nameEn;
      _instructions.text = e.instructionsEn ?? '';
      _met.text = plainNumber(e.met);
      _group = e.muscleGroup;
      _equipment = e.equipment;
      _type = e.type;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    _met.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/exercises');
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final instructions = _instructions.text.trim();
    final draft = (
      name: _name.text.trim(),
      muscleGroup: _group,
      equipment: _equipment,
      type: _type,
      instructions: instructions.isEmpty ? null : instructions,
      met: parseDecimal(_met.text) ?? _defaultMet,
    );
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      final id = widget.exerciseId;
      if (id == null) {
        await db.insertCustomExercise(draft);
      } else {
        await db.updateCustomExercise(id, draft);
      }
      if (mounted) _close();
    } catch (e) {
      debugPrint('Saving exercise failed: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).errorGeneric),
        ));
      }
    }
  }

  Future<void> _delete() async {
    final id = widget.exerciseId;
    if (id == null) return;
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final usage = await db.exerciseUsage(id);
    if (!mounted) return;
    if (usage.sets > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.dataExerciseDeleteTitle),
          content: Text(l10n.dataExerciseInUse(usage.sets)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l10n.dataExerciseDeleteTitle,
      message: usage.planItems > 0
          ? l10n.dataExerciseDeleteInPlans(usage.planItems)
          : null,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return;
    final deleted = await db.deleteCustomExercise(id);
    if (!mounted) return;
    if (deleted) {
      // Detail smazaného cviku už nemá co ukázat – zpět na knihovnu.
      context.go('/exercises');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEdit ? l10n.dataExerciseEditTitle : l10n.dataExerciseNewTitle;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_notEditable) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.dataExerciseNotEditable,
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !_isEdit,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.dataExerciseName),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.dataExerciseNameRequired
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownMenu<MuscleGroup>(
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.exerciseMuscleGroup),
              initialSelection: _group,
              dropdownMenuEntries: [
                for (final g in MuscleGroup.values)
                  DropdownMenuEntry(value: g, label: l10n.muscleGroup(g)),
              ],
              onSelected: (g) {
                if (g != null) setState(() => _group = g);
              },
            ),
            const SizedBox(height: 16),
            DropdownMenu<Equipment>(
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.exerciseEquipment),
              initialSelection: _equipment,
              dropdownMenuEntries: [
                for (final e in Equipment.values)
                  DropdownMenuEntry(value: e, label: l10n.equipment(e)),
              ],
              onSelected: (e) {
                if (e != null) setState(() => _equipment = e);
              },
            ),
            const SizedBox(height: 16),
            DropdownMenu<ExerciseType>(
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.dataExerciseType),
              initialSelection: _type,
              dropdownMenuEntries: [
                for (final t in ExerciseType.values)
                  DropdownMenuEntry(
                    value: t,
                    label: exerciseTypeLabel(l10n, t),
                  ),
              ],
              onSelected: (t) {
                if (t != null) setState(() => _type = t);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructions,
              minLines: 3,
              maxLines: 8,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.dataExerciseInstructions,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _met,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.dataExerciseMet,
                helperText: l10n.dataExerciseMetHint,
                helperMaxLines: 3,
              ),
              validator: (v) {
                final met = parseDecimal(v ?? '');
                return met == null || met < 1 || met > 20
                    ? l10n.dataRangeInvalid('1', '20')
                    : null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tlačítko „Upravit“ v detailu cviku – jen u vlastních cviků.
class CustomExerciseEditButton extends StatelessWidget {
  const CustomExerciseEditButton({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    if (!exercise.isCustom) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/exercise-edit?id=${exercise.id}'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.dataExerciseEdit),
        ),
      ),
    );
  }
}
