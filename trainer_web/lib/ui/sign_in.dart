import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymbar_coach/gymbar_coach.dart';

import '../backend.dart';
import '../strings.dart';
import 'common.dart';

/// Úvodní stránka s přihlášením (stejný účet jako v aplikaci).
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.error});

  final String? error;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() signIn) async {
    final s = S.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signIn();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        // zavřel okno – nic
      } else if (e.code == 'popup-blocked') {
        _error = s('signInPopupBlocked');
      } else if (e.code == 'unauthorized-domain') {
        _error = s('signInDomain');
      } else {
        _error = '${s('signInFailed')} (${e.code})';
      }
    } catch (e) {
      _error = s('signInFailed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final error = _error ?? widget.error;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.fitness_center, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(s('appTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(s('signInIntro'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 28),
                if (_busy)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  FilledButton.icon(
                    onPressed: () => _run(Backend.instance.signInWithGoogle),
                    icon: const Icon(Icons.login),
                    label: Text(s('signInGoogle')),
                  ),
                  if (kAppleWebSignIn) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _run(Backend.instance.signInWithApple),
                      icon: const Icon(Icons.apple),
                      label: Text(s('signInApple')),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(s('signInSameAccount'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Přihlášený, ale ještě ne trenér.
class BecomeTrainerPage extends StatefulWidget {
  const BecomeTrainerPage({super.key, required this.user});

  final User user;

  @override
  State<BecomeTrainerPage> createState() => _BecomeTrainerPageState();
}

class _BecomeTrainerPageState extends State<BecomeTrainerPage> {
  late final _name = TextEditingController(text: widget.user.displayName ?? '');
  final _bio = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    if (_name.text.trim().isEmpty) {
      showSnack(context, s('nameRequired'));
      return;
    }
    if (containsSevereProfanity(_name.text) || containsSevereProfanity(_bio.text)) {
      showSnack(context, s('profanity'));
      return;
    }
    setState(() => _busy = true);
    try {
      await Backend.instance.becomeTrainer(name: _name.text, bio: _bio.text);
      // AuthGate přepne na aplikaci sám.
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s('appTitle')),
        actions: [
          TextButton(
            onPressed: Backend.instance.signOut,
            child: Text(s('signOut')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s('becomeTitle'),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(s('becomeIntro')),
                const SizedBox(height: 8),
                Text(s('becomeRules', {'days': coachInactiveDays}),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                TextField(
                  controller: _name,
                  maxLength: coachNameMax,
                  decoration: InputDecoration(
                    labelText: s('trainerName'),
                    helperText: s('trainerNameHint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  maxLength: coachBioMax,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: s('trainerBio'),
                    helperText: s('trainerBioHint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_busy)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(onPressed: _submit, child: Text(s('becomeButton'))),
                const SizedBox(height: 16),
                Text(s('signedInAs', {'email': widget.user.email ?? widget.user.uid}),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
