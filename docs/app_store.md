# Vydání v App Store

Postup pro GymBar bez Macu (buildy přes Codemagic, `codemagic.yaml`,
README kapitola 2b). Stav požadavků Applu k říjnu 2026 – před vydáním
zkontroluj developer.apple.com/news (Upcoming requirements).

## Co už je v projektu hotové

| Požadavek | Kde |
| --- | --- |
| Popisy oprávnění v Info.plist (kalendář i pro iOS 15–16, fotky, poloha, fotoaparát, Zdraví), `ITSAppUsesNonExemptEncryption = false` | `dart run tool/setup_platforms.dart` |
| Entitlements: Sign in with Apple, push, HealthKit, Universal Links (`applinks:gymbar.app`) | `tool/platform/social.dart`, `health.dart`, `ios_store.dart` |
| `PrivacyInfo.xcprivacy` (bez trackingu, sbíraná data), zapsaný do Xcode projektu | `tool/platform/ios_store.dart` |
| Jen iPhone (`TARGETED_DEVICE_FAMILY = 1`) – bez screenshotů pro iPad | `tool/platform/ios_store.dart` |
| Smazání účtu v aplikaci vč. odvolání přihlášení přes Apple | `lib/modules/social/social_auth.dart` |
| Obsah od uživatelů (Guideline 1.2): souhlas s podmínkami před přihlášením, filtr hrubých slov, nahlášení, blokování | `docs/web/terms.html`, `lib/core/text_filter.dart`, moderace |
| Zdravotní upozornění (1.4.1) | úvod aplikace, O aplikaci, popis v obchodě |
| Texty obchodu v 16 lokalizacích | `docs/store/app_store/` |
| Build a nahrání do TestFlightu | `codemagic.yaml`, workflow `ios-testflight` |
| Widget „Dnes“ a Live Activity pauzy – připravené, zapnou se po registraci App Group | `docs/ios_widget.md` |
| Aplikace pro Apple Watch – připravená, zapne se po registraci App ID `…watchkitapp` | `docs/apple_watch.md` |

Po každé nové verzi projektu spusť `dart run tool/setup_platforms.dart`
a změněné soubory v `ios/` commitni (Codemagic je bere z gitu).

## 1. Apple Developer Program (99 USD/rok)

1. appleid.apple.com: zákonné jméno, zapnuté dvoufázové ověření.
2. Aplikace **Apple Developer** v iPhonu → Account → Enroll Now
   (nebo developer.apple.com/programs/enroll). Typ **Individual**,
   D-U-N-S netřeba. Schválení obvykle 1–2 dny.
3. V App Store se jako vývojář ukáže tvoje jméno.

## 2. App Store Connect → Business

- **Digital Services Act:** pro bezplatnou aplikaci bez příjmů
  „non-trader“. Až zapneš Premium, přehodnoť (trader = veřejně adresa,
  telefon, e-mail) – předtím účetní/živnost.
- Smlouvy: pro bezplatnou aplikaci stačí ta z registrace. Paid Apps
  Agreement, banka a W-8BEN až s Premium.

## 3. Certificates, IDs & Profiles (před prvním buildem)

1. **Identifiers → + → App IDs:** Bundle ID `cz.dedina.fitnessApp`,
   zaškrtni **Push Notifications, HealthKit, Sign In with Apple,
   Associated Domains**. Bez nich podepisování v Codemagicu selže.
2. **Team ID** (Membership details) si poznamenej.
3. **Keys → + → Apple Push Notifications service** → stáhni `.p8`
   (jen jednou!) → Firebase Console → Project settings → Cloud Messaging
   → Apple app configuration → nahraj klíč, Key ID a Team ID.
4. **Přihlášení přes Apple pro Firebase** (Android a odvolání při
   smazání účtu): Identifiers → Services IDs → `cz.dedina.fitnessApp.signin`,
   Sign In with Apple → Domains `fitness-app-dc5e4.firebaseapp.com`,
   Return URL `https://fitness-app-dc5e4.firebaseapp.com/__/auth/handler`;
   Keys → klíč se Sign in with Apple → Firebase → Authentication →
   Apple: Services ID, Team ID, Key ID, privátní klíč.
5. Certifikáty a profily ručně nevytvářej – udělá je Codemagic.

## 4. Universal Links (odkazy gymbar.app do aplikace)

```powershell
dart run tool/assetlinks.dart --apple-team <Team ID>
firebase deploy --only hosting
```

Kontrola: `https://gymbar.app/.well-known/apple-app-site-association`
vrátí JSON s `<Team ID>.cz.dedina.fitnessApp`.

## 5. Codemagic a TestFlight

1. App Store Connect → Users and Access → Integrations → App Store
   Connect API → Team Keys → **Generate API Key**, role **App Manager**.
   Stáhni `.p8`, poznamenej Key ID a Issuer ID.
2. Codemagic → Integrations → Developer Portal → Connect (klíč).
3. App Store Connect → Apps → **+ New App**: iOS, název GymBar, jazyk
   English (U.S.), Bundle ID `cz.dedina.fitnessApp`, SKU `gymbar-ios`.
4. Číslo **Apple ID** aplikace (App Information) zapiš do
   `APP_STORE_APPLE_ID` v `codemagic.yaml` a do `kAppStoreUrl`
   (`lib/modules/links/deep_links.dart`) a `docs/web/config.js`.
5. Spusť workflow **iOS – TestFlight**. Po zpracování (desítky minut)
   je build v TestFlightu.
6. Testeři: vlastní iPhone (jsi interní tester), kamarádi přes
   **External Testing** a veřejný odkaz (první build každé verze projde
   krátkou kontrolou Applu). Test Information: popis, e-mail
   info@gymbar.app, zásady `https://gymbar.app/privacy`.
7. Po prvním buildu sleduj e-maily od Applu (ITMS-91053, ITMS-91061 =
   chybějící důvody v privacy manifestu – pošli je Claudovi).

## 6. Údaje o aplikaci

- **Texty:** `docs/store/app_store/<jazyk>/` (název, podtitul, popis,
  klíčová slova, promo text, novinky). Support URL `https://gymbar.app`,
  Marketing URL `https://gymbar.app`, Privacy `https://gymbar.app/privacy`.
- **Kategorie:** Health & Fitness (druhá Sports).
- **Screenshoty:** iPhone 1206 × 2622 a 1320 × 2868 (Codemagic simulátor
  nebo iPhone testera), 3–6 kusů se skutečnými obrazovkami a vymyšlenými
  daty. Nezmiňuj Android ani Google Play.
- **Ikona** je v buildu (1024 × 1024 bez průhlednosti).
- **Age Rating** (nový dotazník 4+/9+/13+/16+/18+): obsah od uživatelů
  a komunikace mezi uživateli **ano**, wellness/fitness **ano**, ostatní
  ne. Výsledek nejspíš 13+.
- **Věk podle podmínek:** deník bez účtu pro kohokoli, funkce s účtem od
  16 let (mladší se souhlasem rodiče), děti pod 13 ne. V Google Play
  (Obsah aplikace → Cílová skupina) proto vyber 13–15, 16–17 a 18+, nikdy
  věk pod 13 – jinak platí pravidla pro rodinné aplikace.
- **Regulated Medical Device:** ne.
- **Cena:** zdarma, všechny země.

## 7. App Privacy (štítky soukromí)

Tracking: **ne** (žádná reklama, žádný dotaz na sledování).

| Kategorie | Údaje | Propojené s účtem | Účel |
| --- | --- | --- | --- |
| Contact Info → Name, Email | přihlášení Google/Apple, jméno pro přátele | ano | App Functionality |
| Health & Fitness → Health | tělesná váha (záloha do cloudu) | ano | App Functionality |
| Health & Fitness → Fitness | tréninky (záloha, žebříček) | ano | App Functionality |
| User Content → Other | přezdívka, posilovny, výzvy | ano | App Functionality |
| Identifiers → User ID, Device ID | Firebase UID, token upozornění | ano | App Functionality |
| Diagnostics → Crash Data | Crashlytics | ne | App Functionality |

Poloha se zpracuje jen v telefonu (posilovny v okolí) → nedeklaruje se.
Musí odpovídat `PrivacyInfo.xcprivacy` a zásadám ochrany soukromí.

## 8. Odeslání ke kontrole

**App Review Information → Sign-In Information:** testovací účet Google
s vyplněnými daty (přátelé, posilovna, žebříček). **Notes** (anglicky):

```
GymBar is a gym workout log. The log works without an account; friends,
challenges and the gym leaderboard need Google or Apple sign-in.
Demo account: <e-mail> / <heslo>.
User-generated content (nicknames, gym names): users must accept the
Terms of Use (https://gymbar.app/terms) before signing in, severe
profanity is blocked automatically, any entry, gym or user can be
reported (long-press / menu → Report) and users can be blocked. We act
on reports within 24 hours.
Delete account: Friends → settings → Delete account.
HealthKit: optional, writes workouts and reads/writes body weight.
Calendar: adds planned workouts. Camera: scans gym/friend QR codes
(sample QR attached). Location: shows nearby gyms, used on device only.
Premium subscription is not available in this version.
```

Verze → Build → vyber build z TestFlightu → **Manually release this
version** → Add for Review → Submit. Kontrola trvá obvykle 1–2 dny.
Zamítnutí: odpověz ve zprávě u verze, často stačí vysvětlení.

## 9. Později: Premium

Paid Apps Agreement, banka, W-8BEN, App Store Small Business Program
(provize 15 %), předplatné v Monetization → Subscriptions, RevenueCat
(In-App Purchase Key), DSA trader, živnost – viz README kapitola 5a.
