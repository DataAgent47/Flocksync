import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // EMAIL/PASSWORD

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // GOOGLE

  Future<UserCredential> signInWithGoogle() async {
    // Web
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      return await _auth.signInWithPopup(googleProvider);
    }

    // Mobile
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential( idToken: googleAuth.idToken );

    return await _auth.signInWithCredential(credential);
  }

  // SIGN OUT

  Future<void> signOut() async {
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
