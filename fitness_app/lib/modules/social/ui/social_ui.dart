import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/seed/content_i18n.dart';
import '../../../l10n/app_localizations.dart';
import '../../links/deep_links.dart';
import '../social_backend.dart';
import '../social_logic.dart';
import '../social_models.dart';
import '../social_service.dart';

/// „140 kg“ – údaje ze serveru jsou vždy v kg (bez převodu jednotek).
String socialKg(BuildContext context, double kg) {
  final locale = Localizations.localeOf(context).toString();
  return AppLocalizations.of(context)
      .socialKgValue(NumberFormat('0.#', locale).format(kg));
}

String socialNumber(BuildContext context, num value, {String pattern = '0.##'}) =>
    NumberFormat(pattern, Localizations.localeOf(context).toString())
        .format(value);

String socialDateTime(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.MMMEd(locale).format(d)} ${DateFormat.Hm(locale).format(d)}';
}

String socialDate(BuildContext context, DateTime d) =>
    DateFormat.MMMd(Localizations.localeOf(context).toString()).format(d);

/// Název cviku z položky novinek (slug + anglický a český název).
String socialExerciseName(
  BuildContext context, {
  String? slug,
  String? nameEn,
  String? nameCs,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final en = nameEn ?? slug ?? '?';
  return seedText(
    lang,
    en: en,
    cs: nameCs ?? en,
    other: slug == null ? null : (t) => t.exerciseNames[slug],
  );
}

/// Popis výzvy: „Překonej bench press 100 kg“ apod.
String socialChallengeText(
  BuildContext context, {
  required String kind,
  required double target,
  String? exerciseName,
}) {
  final l10n = AppLocalizations.of(context);
  return switch (kind) {
    RemoteChallengeKind.beatRecord =>
      l10n.socialChallengeBeatRecord(exerciseName ?? '?', socialKg(context, target)),
    RemoteChallengeKind.workoutsInMonth =>
      l10n.socialChallengeWorkouts(target.round()),
    RemoteChallengeKind.weeklyWater => l10n.socialChallengeWater,
    _ => kind,
  };
}

String socialFriendAppLink(String code) => '$kAppLinkScheme://friend?code=$code';

String socialFriendWebLink(String code) => '$kWebBaseUrl/friend?code=$code';

Future<void> shareFriendInvite(BuildContext context, String code) async {
  final l10n = AppLocalizations.of(context);
  try {
    await SharePlus.instance.share(ShareParams(
      text: l10n.socialShareText(socialFriendWebLink(code), code),
      subject: l10n.socialShareSubject,
    ));
  } catch (e) {
    debugPrint('Social: share failed: $e');
  }
}

/// Zpráva přes celou plochu (nenastaveno, chyba, prázdný seznam).
class SocialMessage extends StatelessWidget {
  const SocialMessage({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (text != null) ...[
              const SizedBox(height: 8),
              Text(text!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

void showSocialSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// [social:profile] – sekce „Přátelé“ v Profilu.
class SocialProfileSection extends ConsumerWidget {
  const SocialProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = ref.watch(socialAvailableProvider);
    final user = available ? ref.watch(socialUserProvider).valueOrNull : null;
    final unread = user == null ? 0 : ref.watch(socialUnreadCountProvider);
    final subtitle = !available
        ? l10n.socialNotSetUp
        : user == null
            ? l10n.socialProfileSignedOut
            : unread > 0
                ? l10n.socialUnread(unread)
                : l10n.socialProfileSignedIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.socialSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ListTile(
          leading: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.people_outline),
          ),
          title: Text(l10n.socialFriendsTile),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/friends'),
        ),
        const Divider(),
      ],
    );
  }
}

/// Kód přítele z textu/odkazu → obrazovka potvrzení.
void openAddFriend(BuildContext context, String input, {bool replace = false}) {
  final code = parseFriendCode(input);
  if (code == null) {
    showSocialSnack(context, AppLocalizations.of(context).socialCodeInvalid);
    return;
  }
  final location = '/friends/add?code=$code';
  if (replace) {
    context.pushReplacement(location);
  } else {
    context.push(location);
  }
}
