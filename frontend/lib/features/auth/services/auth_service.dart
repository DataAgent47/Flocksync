import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get requiresPasswordReauth {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    try {
      await credential.user?.sendEmailVerification();
    } finally {
      await _auth.signOut();
    }
  }

  Future<void> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(googleProvider);
    }

    await _googleSignIn.initialize(
      serverClientId:
          '1089004613765-pjk9ct5vb9o92rc7ftekr06p016qi1j9.apps.googleusercontent.com',
    );
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Changing email/password not possible for google auth
  Future<void> changeEmail({
    required String newEmail,
    String? currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No signed-in user found.',
      );
    }

    await _reauthenticate(user: user, currentPassword: currentPassword);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No signed-in user found.',
      );
    }

    await _reauthenticate(user: user, currentPassword: currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> reauthenticate({String? currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No signed-in user found.',
      );
    }
    await _reauthenticate(user: user, currentPassword: currentPassword);
  }

  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No signed-in user found.',
      );
    }
    await user.delete();
  }

  Future<void> _reauthenticate({
    required User user,
    String? currentPassword,
  }) async {


    if (user.providerData.any((info) => info.providerId == 'password')) {
      final email = user.email;
      if (email == null || email.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'No email available for this account.',
        );
      }
      final password = currentPassword?.trim() ?? '';
      if (password.isEmpty) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Current password is required.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }

    await _googleSignIn.initialize(
      serverClientId:
          '1089004613765-pjk9ct5vb9o92rc7ftekr06p016qi1j9.apps.googleusercontent.com',
    );
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }
}
