import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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

  // GOOGLE

  Future<UserCredential> signInWithGoogle() async {
    // Web
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      return await _auth.signInWithPopup(googleProvider);
    }

    // Mobile
    await _googleSignIn.initialize(
      serverClientId:'1089004613765-pjk9ct5vb9o92rc7ftekr06p016qi1j9.apps.googleusercontent.com',
    );
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential( idToken: googleAuth.idToken );

    return await _auth.signInWithCredential(credential);
  }

  // SIGN OUT

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
