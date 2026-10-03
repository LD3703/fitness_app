import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'social_backend.dart';

enum SocialSignInMethod { google, apple }

/// Přihlášení se nepovedlo (jiný důvod než zrušení uživatelem).
class SocialAuthException implements Exception {
  SocialAuthException(this.message);

  final String message;

  @override
  String toString() => 'SocialAuthException: $message';
}

/// Přihlášení přes Google a Apple do Firebase Auth.
///
/// google_sign_in 7: `GoogleSignIn.instance.initialize()` se volá jednou,
/// pak `authenticate()`; ID token je v `account.authentication.idToken`.
class SocialAuth {
  SocialAuth._();

  static final instance = SocialAuth._();

  Future<void>? _googleInit;

  /// Kód z posledního přihlášení přes Apple (pro zrušení tokenu při
  /// smazání účtu – vyžaduje App Store).
  String? _appleAuthorizationCode;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get googleSupported => SocialBackend.supportedPlatform;

  /// Apple nabízíme jen na iPhonu (App Store to vyžaduje, když je tam
  /// Google; na Androidu by potřeboval webovou službu).
  bool get appleSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  User? get currentUser =>
      SocialBackend.available ? _auth.currentUser : null;

  Future<void> _ensureGoogle() async {
    final init = _googleInit ??= () async {
      String? clientId;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Na iOS potřebuje Google Sign-In ID klienta (je i v Info.plist
        // jako GIDClientID – viz tool/platform/social.dart).
        clientId = Firebase.app().options.iosClientId;
      }
      await GoogleSignIn.instance.initialize(clientId: clientId);
    }();
    try {
      await init;
    } catch (e) {
      _googleInit = null; // příště zkusit znovu
      throw SocialAuthException('Google Sign-In init failed: $e');
    }
  }

  /// Přihlásí uživatele. Vrací null, když přihlášení zrušil.
  Future<User?> signIn(SocialSignInMethod method) async {
    final result = await _credential(method);
    if (result == null) return null;
    final cred = await _auth.signInWithCredential(result.credential);
    final user = cred.user;
    final name = result.name;
    if (user != null &&
        name != null &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      try {
        await user.updateDisplayName(name);
      } catch (_) {}
    }
    return user;
  }

  /// Znovu ověří přihlášení (Firebase to chce před smazáním účtu).
  /// Vrací false, když to uživatel zrušil.
  Future<bool> reauthenticate() async {
    final user = currentUser;
    if (user == null) return false;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    final method = providers.contains('apple.com')
        ? SocialSignInMethod.apple
        : SocialSignInMethod.google;
    final result = await _credential(method);
    if (result == null) return false;
    await user.reauthenticateWithCredential(result.credential);
    return true;
  }

  Future<({AuthCredential credential, String? name})?> _credential(
    SocialSignInMethod method,
  ) =>
      switch (method) {
        SocialSignInMethod.google => _googleCredential(),
        SocialSignInMethod.apple => _appleCredential(),
      };

  Future<({AuthCredential credential, String? name})?>
      _googleCredential() async {
    await _ensureGoogle();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw SocialAuthException('Google did not return an ID token.');
      }
      return (
        credential: GoogleAuthProvider.credential(idToken: idToken),
        name: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw SocialAuthException('Google: ${e.code.name} ${e.description ?? ''}');
    }
  }

  Future<({AuthCredential credential, String? name})?> _appleCredential() async {
    final rawNonce = _nonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = apple.identityToken;
      if (idToken == null) {
        throw SocialAuthException('Apple did not return an identity token.');
      }
      _appleAuthorizationCode = apple.authorizationCode;
      final credential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
      // Jméno Apple pošle jen při úplně prvním přihlášení.
      final name = [apple.givenName, apple.familyName]
          .whereType<String>()
          .join(' ')
          .trim();
      return (credential: credential, name: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw SocialAuthException('Apple: ${e.code.name} ${e.message}');
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> signOut() async {
    if (!SocialBackend.available) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Social: sign out failed: $e');
    }
    if (_googleInit != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  /// Smaže účet ve Firebase Auth (data na serveru maže volající předem).
  /// U Apple nejdřív zruší token (pravidla App Store).
  Future<void> deleteAuthUser() async {
    final user = currentUser;
    if (user == null) return;
    final isApple = user.providerData.any((p) => p.providerId == 'apple.com');
    final code = _appleAuthorizationCode;
    if (isApple && code != null) {
      try {
        await _auth.revokeTokenWithAuthorizationCode(code);
      } catch (e) {
        debugPrint('Social: Apple token revoke failed: $e');
      }
    }
    await user.delete();
    if (_googleInit != null) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
  }
}
