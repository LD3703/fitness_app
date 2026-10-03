import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/database.dart';
import '../../../data/seed/content_i18n.dart';
import '../../../data/seed/seed_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/format.dart';
import '../../links/deep_links.dart';
import '../../sharing/share_cards.dart';
import '../../sharing/share_service.dart';
import '../gym/gym_logic.dart';
import '../gym/gym_models.dart';
import '../gym/gym_service.dart';
import 'social_ui.dart';

// ---------------------------------------------------------------------------
// Odkazy
// ---------------------------------------------------------------------------

String gymAppLink(String code) => '$kAppLinkScheme://gym?code=$code';

String gymWebLink(String code) => '$kWebBaseUrl/gym?code=$code';

// ---------------------------------------------------------------------------
// Popisky a hodnoty
// ---------------------------------------------------------------------------

final _seedExercisesBySlug = {for (final e in seedExercises) e.slug: e};

/// Název kategorie: u cviků přeložený název vestavěného cviku (stejně jako
/// `exercise.localizedName`), jinak „Tréninky“.
String gymCategoryLabel(AppLocalizations l10n, GymCategory c) {
  final slug = c.exerciseSlug;
  if (slug == null) return l10n.socialGymCatWorkouts;
  final seed = _seedExercisesBySlug[slug];
  if (seed == null) return slug;
  return seedText(
    l10n.localeName.split(RegExp('[_-]')).first,
    en: seed.nameEn,
    cs: seed.nameCs,
    other: (t) => t.exerciseNames[slug],
  );
}

/// Poznámka k hodnotě kategorie („na jednu jednoručku“, „jen přidaná
/// zátěž“), nebo null.
String? gymCategoryNote(AppLocalizations l10n, GymCategory c) {
  if (c.perDumbbell) return l10n.socialGymNotePerDumbbell;
  if (c.addedWeight) return l10n.socialGymNoteAddedWeight;
  return null;
}

String gymAgeFilterLabel(AppLocalizations l10n, GymAgeFilter f) =>
    switch (f.minAge) {
      null => l10n.socialGymFilterAll,
      final int age => l10n.socialGymFilterAgeFrom(age),
    };

String gymGenderLabel(AppLocalizations l10n, GymGender g) => switch (g) {
      GymGender.male => l10n.socialGymGenderMale,
      GymGender.female => l10n.socialGymGenderFemale,
      GymGender.unspecified => l10n.socialGymGenderUnspecified,
    };

/// Hodnota v žebříčku. Kg ze serveru i lokální se převedou na jednotky
/// uživatele ([formatWeightWithUnit]).
String gymValueText(BuildContext context, GymCategory c, double value) {
  if (c.isLift) return formatWeightWithUnit(context, value, rounded: true);
  return AppLocalizations.of(context).socialGymWorkoutsValue(value.round());
}

// ---------------------------------------------------------------------------
// Přezdívka, pohlaví, rok narození, viditelnost
// ---------------------------------------------------------------------------

/// Uloží rok narození z formuláře do lokálního profilu (jen při změně).
/// Prázdné pole rok smaže. Na server jde jen věková skupina.
Future<void> saveGymBirthYear(AppDatabase db, int? birthYear) async {
  final profile = await db.watchProfile().first;
  if (profile.birthYear == birthYear) return;
  await db.updateProfile(UserProfilesCompanion(birthYear: Value(birthYear)));
}

/// Formulář profilu v žebříčku (při vstupu, založení i v nastavení).
Future<GymProfileInput?> showGymProfileSheet(
  BuildContext context, {
  required GymProfileInput initial,
  required String title,
  required String confirmLabel,
  String? note,
}) =>
    showModalBottomSheet<GymProfileInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GymProfileSheet(
        initial: initial,
        title: title,
        confirmLabel: confirmLabel,
        note: note,
      ),
    );

class _GymProfileSheet extends StatefulWidget {
  const _GymProfileSheet({
    required this.initial,
    required this.title,
    required this.confirmLabel,
    this.note,
  });

  final GymProfileInput initial;
  final String title;
  final String confirmLabel;
  final String? note;

  @override
  State<_GymProfileSheet> createState() => _GymProfileSheetState();
}

class _GymProfileSheetState extends State<_GymProfileSheet> {
  late final _nickname = TextEditingController(
    text: sanitizeGymNickname(widget.initial.nickname) == '?'
        ? ''
        : sanitizeGymNickname(widget.initial.nickname),
  );
  late GymGender _gender = widget.initial.gender;
  late bool _show = widget.initial.show;
  late final _birthYear = TextEditingController(
    text: widget.initial.birthYear?.toString() ?? '',
  );

  final _currentYear = DateTime.now().year;

  @override
  void dispose() {
    _nickname.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  /// Prázdné pole = bez roku narození; jinak rok v povoleném rozsahu.
  bool get _birthYearValid {
    final t = _birthYear.text.trim();
    if (t.isEmpty) return true;
    return isValidBirthYear(int.tryParse(t), _currentYear);
  }

  bool get _valid => _nickname.text.trim().isNotEmpty && _birthYearValid;

  /// Chybu ukážeme až u celého (čtyřmístného) roku, ne při psaní.
  bool get _showBirthYearError =>
      _birthYear.text.trim().length >= 4 && !_birthYearValid;

  void _submit() {
    if (!_valid) return;
    final nick = _nickname.text.trim();
    Navigator.of(context).pop<GymProfileInput>((
      nickname: sanitizeGymNickname(nick),
      gender: _gender,
      show: _show,
      birthYear: int.tryParse(_birthYear.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              if (widget.note != null) ...[
                const SizedBox(height: 8),
                Text(widget.note!),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _nickname,
                maxLength: gymNicknameMaxLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.socialGymNickname,
                  helperText: l10n.socialGymNicknameHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(l10n.socialGymGender, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<GymGender>(
                segments: [
                  for (final g in GymGender.values)
                    ButtonSegment(
                      value: g,
                      label: Text(gymGenderLabel(l10n, g)),
                    ),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 4),
              Text(l10n.socialGymGenderHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: _birthYear,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.profileBirthYear,
                  helperText: l10n.socialGymBirthYearHint,
                  helperMaxLines: 3,
                  errorText: !_showBirthYearError
                      ? null
                      : l10n.profileBirthYearInvalid(
                          gymBirthYearMin,
                          gymBirthYearMax(_currentYear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.socialGymShowMe),
                subtitle: Text(l10n.socialGymShowMeHint),
                value: _show,
                onChanged: (v) => setState(() => _show = v),
              ),
              Text(l10n.socialGymPrivacy, style: theme.textTheme.bodySmall),
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
                    onPressed: _valid ? _submit : null,
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
// QR kód posilovny
// ---------------------------------------------------------------------------

/// QR kód posilovny (pro recepci) – kopírování kódu a sdílení plakátu.
Future<void> showGymQrSheet(BuildContext context, Gym gym) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gym.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(l10n.socialGymQrHint, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: gymWebLink(gym.code),
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  gym.code,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: gym.code));
                        if (context.mounted) {
                          showSocialSnack(context, l10n.socialCopied);
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.socialCopy),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => shareGymPoster(context, gym),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.socialGymSharePoster),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

/// Sdílí plakát s QR kódem jako PNG + text s odkazem (náhled → SharePlus).
Future<void> shareGymPoster(BuildContext context, Gym gym) {
  final l10n = AppLocalizations.of(context);
  return showShareCardPreview(
    context,
    card: GymPosterCard(gym: gym),
    text: l10n.socialGymShareText(gym.name, gymWebLink(gym.code), gym.code),
    fileName: 'gym_${gym.code}',
  );
}

/// Plakát pro recepci: název posilovny, QR kód a kód.
class GymPosterCard extends StatelessWidget {
  const GymPosterCard({super.key, required this.gym});

  final Gym gym;

  static const _ink = Color(0xFF0E3B32);
  static const _muted = Color(0xFF4A5A56);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: _ink,
          decoration: TextDecoration.none,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
        child: SizedBox.fromSize(
          size: kShareCardSize,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLogoMark(size: 26),
                      SizedBox(width: 8),
                      Text(
                        kShareAppName,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.socialGymPosterTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gym.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  if (gym.city.isNotEmpty)
                    Text(
                      gym.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  const Spacer(),
                  QrImageView(
                    data: gymWebLink(gym.code),
                    size: 190,
                    backgroundColor: Colors.white,
                  ),
                  const Spacer(),
                  Text(
                    gym.code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.socialGymPosterScan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shareWebHost,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Karta „Nejsilnější v <posilovna>“
// ---------------------------------------------------------------------------

/// Sdílí kartu „Nejsilnější v posilovně“ (jen když jsem první).
Future<void> shareGymStrongest(
  BuildContext context, {
  required Gym gym,
  required GymCategory category,
  required double value,
  required String nickname,
  required bool monthly,
}) {
  final l10n = AppLocalizations.of(context);
  final categoryName = gymCategoryLabel(l10n, category);
  final valueText = gymValueText(context, category, value);
  return showShareCardPreview(
    context,
    card: GymStrongestCard(
      gymName: gym.name,
      categoryName: categoryName,
      valueText: valueText,
      nickname: nickname,
      periodText:
          monthly ? l10n.socialGymPeriodMonth : l10n.socialGymPeriodAllTime,
    ),
    text: l10n.socialGymStrongestShareText(
      categoryName,
      valueText,
      gym.name,
      kWebBaseUrl,
    ),
    fileName: 'gym_strongest_${category.key}',
  );
}

class GymStrongestCard extends StatelessWidget {
  const GymStrongestCard({
    super.key,
    required this.gymName,
    required this.categoryName,
    required this.valueText,
    required this.nickname,
    required this.periodText,
  });

  final String gymName;
  final String categoryName;
  final String valueText;
  final String nickname;
  final String periodText;

  static const _top = Color(0xFF0E3B32);
  static const _bottom = Color(0xFF2E7D6B);
  static const _accent = Color(0xFFFFC857);
  static const _muted = Color(0xCCFFFFFF);
  static const _faint = Color(0x33FFFFFF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.none,
          fontSize: 14,
        ),
        child: SizedBox.fromSize(
          size: kShareCardSize,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_top, _bottom],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      AppLogoMark(size: 34),
                      SizedBox(width: 10),
                      Text(
                        kShareAppName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 18, color: _accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.socialGymStrongestLabel(gymName).toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodText,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                  const Spacer(),
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, color: _muted),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valueText,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(height: 1, color: _faint),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: _muted),
                      const SizedBox(width: 6),
                      Text(
                        shareWebHost,
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
