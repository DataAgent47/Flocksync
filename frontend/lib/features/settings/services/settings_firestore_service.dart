import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/settings_user_profile.dart';

class SettingsFirestoreService {
  final FirebaseFirestore _firestore;

  SettingsFirestoreService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<SettingsUserProfile?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return SettingsUserProfile.fromMap(data);
    });
  }

  Future<SettingsUserProfile?> hydrateProfile(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data == null) {
      return null;
    }
    return SettingsUserProfile.fromMap(data);
  }

  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String contactEmail,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'contact_email': contactEmail.trim(),
      'phone': phone.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateContactEmail({
    required String uid,
    required String contactEmail,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'contact_email': contactEmail.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccountData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    // keep all documents so that we can delete all at once
    final refsToDelete = <DocumentReference>{};

    final role = (userData['role'] as String? ?? '').trim();
    final onboardingState =
        userData['onboarding_state'] as Map<String, dynamic>?;
    final propertyId = (onboardingState?['property_id'] as String? ?? '')
        .trim();

    if (propertyId.isNotEmpty) {
      if (role == 'manager') {
        refsToDelete.add(
          _firestore.collection('managers').doc('${propertyId}_$uid'),
        );
      } else {
        refsToDelete.add(
          _firestore.collection('residents').doc('${propertyId}_$uid'),
        );
      }
    }

    // Also remove any stale memberships in case a user switched role/property.
    final residentsQuery = await _firestore
        .collection('residents')
        .where('resident_id', isEqualTo: uid)
        .get();
    for (final doc in residentsQuery.docs) {
      refsToDelete.add(doc.reference);
    }
    final managersQuery = await _firestore
        .collection('managers')
        .where('manager_id', isEqualTo: uid)
        .get();
    for (final doc in managersQuery.docs) {
      refsToDelete.add(doc.reference);
    }

    refsToDelete.add(userRef);

    final batch = _firestore.batch();
    for (final ref in refsToDelete) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}
