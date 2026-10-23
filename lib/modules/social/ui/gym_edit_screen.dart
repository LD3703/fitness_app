// Úprava posilovny zakladatelem (název, město, adresa). Kód a QR zůstávají.
// Smí jen zakladatel posilovny založené v aplikaci (Gym.canEdit, pravidla).
import 'package:flutter/material.dart';

import '../../../core/text_filter.dart';
import '../../../l10n/app_localizations.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_service.dart';
import 'social_ui.dart';

/// Otevře úpravu posilovny; vrátí true, když se uložila.
Future<bool> showGymEditScreen(BuildContext context, Gym gym) async =>
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GymEditScreen(gym: gym)),
    ) ??
    false;

class GymEditScreen extends StatefulWidget {
  const GymEditScreen({super.key, required this.gym});

  final Gym gym;

  @override
  State<GymEditScreen> createState() => _GymEditScreenState();
}

class _GymEditScreenState extends State<GymEditScreen> {
  late final _name = TextEditingController(text: widget.gym.name);
  late final _city = TextEditingController(text: widget.gym.city);
  late final _address = TextEditingController(text: widget.gym.address ?? '');
  bool _busy = false;

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

  Future<void> _save() async {
    if (!_valid) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final address = _address.text.trim();
      await GymService.instance.updateGymInfo(
        widget.gym,
        name: _name.text,
        city: _city.text,
        address: address.isEmpty ? null : address,
      );
      if (!mounted) return;
      showSocialSnack(context, l10n.socialGymEdited);
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Gym: edit failed: $e');
      if (mounted) showSocialSnack(context, l10n.socialOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialGymEdit)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 16),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton.icon(
              onPressed: _valid ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.save),
            ),
        ],
      ),
    );
  }
}
