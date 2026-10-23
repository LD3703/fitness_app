// GymBar pro trenéry – web na gymbar.app/trener/ (docs/coach.md).
// Trenér tu vidí klienty, jejich tréninky a grafy, píše komentáře, skládá
// plány a posílá je klientům do aplikace.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'backend.dart';
import 'firebase_options.dart';
import 'strings.dart';
import 'ui/shell.dart';
import 'ui/sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var configured = true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError {
    configured = false;
  }
  runApp(TrainerApp(configured: configured));
}

const _seed = Color(0xFF2E7D6B);

ThemeData _theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: b),
      useMaterial3: true,
      cardTheme: const CardThemeData(elevation: 0),
    );

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key, required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (context) => S.of(context)('appTitle'),
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        supportedLocales: const [Locale('cs'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Čeština pro češtinu a slovenštinu, jinak angličtina.
        localeResolutionCallback: (locale, supported) =>
            const ['cs', 'sk'].contains(locale?.languageCode)
                ? const Locale('cs')
                : const Locale('en'),
        home: configured ? const AuthGate() : const _NotConfigured(),
      );
}

/// Přihlášení → (stát se trenérem) → aplikace.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Zvýší se po „Zkusit znovu“ → nový odběr profilu trenéra.
  int _attempt = 0;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: Backend.instance.authChanges(),
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          final user = auth.data;
          if (user == null) return const SignInPage();
          return StreamBuilder<Trainer?>(
            key: ValueKey('${user.uid}#$_attempt'),
            stream: Backend.instance.watchTrainer(),
            builder: (context, t) {
              // Přihlášený, ale profil se nenačetl (síť, pravidla):
              // přihlašovací stránka by nepomohla – znovu, nebo odhlásit.
              if (t.hasError) {
                return _LoadError(
                  error: '${t.error}',
                  onRetry: () => setState(() => _attempt++),
                );
              }
              if (!t.hasData && t.connectionState != ConnectionState.active) {
                return const _Loading();
              }
              final trainer = t.data;
              if (trainer == null) return BecomeTrainerPage(user: user);
              return Shell(trainer: trainer);
            },
          );
        },
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s('errorGeneric'), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(onPressed: onRetry, child: Text(s('retry'))),
                    OutlinedButton(
                      onPressed: Backend.instance.signOut,
                      child: Text(s('signOut')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s('notConfigured'), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
