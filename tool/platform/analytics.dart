import 'dart:io';

/// Nativní nastavení statistik používání (Google Analytics pro Firebase).
/// Bezpečné spustit opakovaně.
///
/// Sběr je ve výchozím stavu vypnutý a všechny druhy souhlasu zamítnuté
/// (Consent Mode). Zapne ho až Analytics.init / setConsent podle
/// odpovědi uživatele (lib/modules/analytics/analytics.dart), takže se
/// nic neodešle dřív, než uživatel souhlasí.
///
/// Reklamní ID se nesbírá nikdy: Android – meta-data
/// `google_analytics_adid_collection_enabled` a odebrané oprávnění
/// `com.google.android.gms.permission.AD_ID` (Firebase ho jinak přidá do
/// manifestu); iOS – aplikace nežádá o App Tracking Transparency, IDFA
/// je proto vždy nulové, a IDFV se pro statistiky nepoužije.
bool patchAnalytics() => _manifest() & _infoPlist();

const _manifestFlags = [
  'firebase_analytics_collection_enabled',
  'google_analytics_adid_collection_enabled',
  'google_analytics_default_allow_analytics_storage',
  'google_analytics_default_allow_ad_storage',
  'google_analytics_default_allow_ad_user_data',
  'google_analytics_default_allow_ad_personalization_signals',
  // Obrazovky posílá aplikace sama (vzor cesty routeru), jedna nativní
  // aktivita by jen přidávala šum.
  'google_analytics_automatic_screen_reporting_enabled',
];

const _plistFlags = [
  'FIREBASE_ANALYTICS_COLLECTION_ENABLED',
  'GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED',
  'GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE',
  'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE',
  'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA',
  'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS',
  'FirebaseAutomaticScreenReportingEnabled',
];

const _toolsNs = 'xmlns:tools="http://schemas.android.com/tools"';
const _adIdPermission = 'com.google.android.gms.permission.AD_ID';

bool _manifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;

  // Jmenný prostor tools (kvůli tools:node="remove").
  if (!s.contains(_toolsNs)) {
    s = s.replaceFirst('<manifest ', '<manifest $_toolsNs\n    ');
  }
  // Odebrat oprávnění reklamního ID, které přidává knihovna Firebase.
  if (!s.contains(_adIdPermission)) {
    final i = s.indexOf('<uses-permission');
    final at = i >= 0 ? i : s.indexOf('<application');
    if (at < 0) {
      stderr.writeln('✗ ${file.path}: <application> nenalezen.');
      return false;
    }
    s = s.replaceRange(
        at,
        at,
        '<uses-permission android:name="$_adIdPermission"\n'
        '        tools:node="remove" />\n    ');
  }
  for (final flag in _manifestFlags) {
    if (s.contains('"$flag"')) continue;
    final i = s.lastIndexOf('</application>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
      return false;
    }
    s = s.replaceRange(
        i,
        i,
        '    <meta-data\n'
        '            android:name="$flag"\n'
        '            android:value="false" />\n    ');
  }
  if (s == original) {
    stdout.writeln('• ${file.path}: statistiky už nastavené.');
  } else {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: statistiky bez souhlasu nesbírají, '
        'bez reklamního ID.');
  }
  return true;
}

bool _infoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final original = s;
  for (final flag in _plistFlags) {
    if (s.contains('<key>$flag</key>')) continue;
    // Poslední </dict> = konec kořenového slovníku.
    final i = s.lastIndexOf('</dict>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, '\t<key>$flag</key>\n\t<false/>\n');
  }
  if (s == original) {
    stdout.writeln('• ${file.path}: statistiky už nastavené.');
  } else {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: statistiky bez souhlasu nesbírají.');
  }
  return true;
}
