import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../models/settings_user_profile.dart';
import '../services/settings_firestore_service.dart';

class SettingsController extends ChangeNotifier {
  final AuthService _authService;
  final SettingsFirestoreService _firestoreService;

  SettingsController({
    AuthService? authService,
    SettingsFirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? SettingsFirestoreService();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  bool get requiresPasswordReauth => _authService.requiresPasswordReauth;

  Stream<SettingsUserProfile?> profileStream(String uid) {
    return _firestoreService.profileStream(uid);
  }

  Future<SettingsUserProfile?> hydrateProfile(String uid) {
    return _firestoreService.hydrateProfile(uid);
  }

  Future<bool> saveProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String contactEmail,
    required String phone,
  }) async {
    return _runAction(() async {
      await _firestoreService.updateProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        contactEmail: contactEmail,
        phone: phone,
      );
      successMessage = 'Profile updated successfully.';
    });
  }

  Future<bool> changeLoginEmail({
    required String uid,
    required String newEmail,
    String? currentPassword,
  }) async {
    return _runAction(() async {
      await _authService.changeEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      await _firestoreService.updateContactEmail(
        uid: uid,
        contactEmail: newEmail,
      );
      successMessage =
          'Verification email sent. Confirm the new email in your inbox.';
    });
  }

  Future<bool> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    return _runAction(() async {
      await _authService.changePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );
      successMessage = 'Password updated successfully.';
    });
  }

  Future<bool> signOut() async {
    return _runAction(() async {
      await _authService.signOut();
    });
  }

  Future<bool> deleteAccount({String? currentPassword}) async {
    return _runAction(() async {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.deleteAccountData(uid);
      }
      await _authService.deleteUser(currentPassword: currentPassword);
    });
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      errorMessage = _friendlyError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('wrong-password') ||
        normalized.contains('invalid-credential')) {
      return 'Current password is incorrect.';
    }
    if (normalized.contains('requires-recent-login')) {
      return 'Please reauthenticate and try again.';
    }
    if (normalized.contains('email-already-in-use')) {
      return 'That email is already linked to another account.';
    }
    if (normalized.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }
    if (normalized.contains('weak-password')) {
      return 'Use a stronger password with at least 8 characters.';
    }

    return 'Something went wrong. Please try again.';
  }
}
